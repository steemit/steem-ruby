module Steem
  # This ruby API works with
  # {https://github.com/steemit/steem/releases steemd-0.19.4} and other Appbase
  # compatible upstreams.  To access different API namespaces, use the
  # following:
  #
  #     api = Steem::Api.new
  #     api.get_dynamic_global_properties
  #
  # The above example will make an instance that can access the
  # {https://developers.steem.io/apidefinitions/condenser-api condenser_api}
  # namespace.  Alternatively, you may also create a direct instances with its
  # full name, if you prefer:
  #
  #     api = Steem::CondenserApi.new
  #     api.get_dynamic_global_properties
  #
  # If you know the name of another API that is supported by the remote node,
  # you can create an instance to that instead, for example:
  #
  #     api = Steem::MarketHistoryApi.new
  #     api.get_volume
  #
  # All known API by namespace:
  #
  # * {AccountByKeyApi}
  # * {AccountHistoryApi}
  # * {BlockApi}
  # * {DatabaseApi}
  # * {FollowApi}
  # * {Jsonrpc}
  # * {MarketHistoryApi}
  # * {NetworkBroadcastApi}
  # * {TagsApi}
  # * {WitnessApi}
  #
  # Also see: {https://developers.steem.io/apidefinitions/ Complete API Definitions}
  class Api
    attr_accessor :chain, :methods
    
    # Use this for debugging naive thread handler.
    # DEFAULT_RPC_CLIENT = RPC::BaseClient
    DEFAULT_RPC_CLIENT = RPC::ThreadSafeHttpClient
    
    def self.api_name=(api_name)
      @api_name = api_name.to_s.
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr('-', '_').downcase.to_sym
    end
    
    def self.api_name
      @api_name
    end
    
    def self.api_class_name
      @api_name.to_s.split('_').map(&:capitalize).join
    end
    
    def self.jsonrpc=(jsonrpc)
      @jsonrpc = jsonrpc
    end
    
    def self.jsonrpc
      @jsonrpc
    end
    
    def initialize(options = {})
      @chain = options[:chain] || :steem
      @error_pipe = options[:error_pipe] || STDERR
      @api_name = self.class.api_name ||= :condenser_api
      @rpc_client = options[:rpc_client] || DEFAULT_RPC_CLIENT.new(options.merge(api_name: @api_name))
      
      if @api_name == :jsonrpc
        Api::jsonrpc = self
      else
        # Note, we have to wait until initialize to check this because we don't
        # have access to instance options until now.
        
        Api::jsonrpc = Jsonrpc.new(options)
        @methods = Api::jsonrpc.get_api_methods
        
        unless !!@methods[@api_name]
          raise UnknownApiError, "#{@api_name} (known APIs: #{@methods.keys.join(' ')})"
        end
        
        @methods = @methods[@api_name]
      end
        
      @try_count = 0
    end
    
    def inspect
      properties = %w(chain methods).map do |prop|
        if !!(v = instance_variable_get("@#{prop}"))
          case v
          when Array then "@#{prop}=<#{v.size} #{v.size == 1 ? 'element' : 'elements'}>" 
          else; "@#{prop}=#{v}" 
          end
        end
      end.compact.join(', ')
      
      "#<#{self.class.api_class_name} [#{properties}]>"
    end
  private
    def self.args_keys_to_s(rpc_method_name)
      args = signature(rpc_method_name).args
      args_keys = JSON[args.to_json]
    end
    
    def self.signature(rpc_method_name)
      @@signatures ||= {}
      @@signatures[rpc_method_name] ||= jsonrpc.get_signature(method: rpc_method_name).result
    end
    
    def self.raise_error_response(rpc_method_name, rpc_args, response)
      raise UnknownError, "#{rpc_method_name}: #{response}" if response.error.nil?
      
      error = response.error
      
      if error.message == 'Invalid Request'
        raise Steem::ArgumentError, "Unexpected arguments: #{rpc_args.inspect}.  Expected: #{rpc_method_name} (#{args_keys_to_s(rpc_method_name)})"
      end
      
      BaseError.build_error(error, rpc_method_name)
    end
    
    def respond_to_missing?(m, include_private = false)
      methods.nil? ? false : methods.include?(m.to_sym)
    end
    
    def method_missing(m, *args, &block)
      super unless respond_to_missing?(m)
      
      rpc_method_name = "#{@api_name}.#{m}"
      rpc_args = case @api_name
      when :condenser_api then args
      when :jsonrpc then args.first
      else
        expected_args = Api::signature(rpc_method_name).args || []
        expected_args_key_string = if expected_args.size > 0
          " (#{Api::args_keys_to_s(rpc_method_name)})"
        end
        expected_args_size = expected_args.size
        
        begin
          args = args.first.to_h
          args_size = args.size
          
          # Some argument are optional, but if the arguments passed are greater
          # than the expected arguments size, we can warn.
          if args_size > expected_args_size
            @error_pipe.puts "Warning #{rpc_method_name} expects arguments: #{expected_args_size}, got: #{args_size}"
          end
        rescue NoMethodError => e
          error = Steem::ArgumentError.new("#{rpc_method_name} expects arguments: #{expected_args_size}", e)
          raise error
        rescue => e
          raise UnknownError.new("#{rpc_method_name} unknown error.", e)
        end
        
        args
      end
      
      response = @rpc_client.rpc_execute(@api_name, m, rpc_args)
      
      if defined?(response.error) && !!response.error
        if !!response.error.message
          Api::raise_error_response rpc_method_name, rpc_args, response
        else
          raise Steem::ArgumentError, response.error.inspect
        end
      end
      
      if !!block
        case response
        when Hashie::Mash then yield response.result, response.error, response.id
        when Hashie::Array
          response.each do |r|
            r = Hashie::Mash.new(r)
            yield r.result, r.error, r.id
          end
        else; yield response
        end
      else
        return response
      end
    end
  end
end
