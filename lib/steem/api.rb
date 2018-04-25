require 'net/https'

module Steem
  class Api
    include ChainConfig
    
    attr_accessor :chain, :jsonrpc, :error_pipe
    
    # @private
    POST_HEADERS = {
      'Content-Type' => 'application/json; charset=utf-8',
      'User-Agent' => Steem::AGENT_ID
    }
    
    attr_accessor :methods
    
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
    
    def initialize(options = {})
      @chain = options[:chain] || :steem
      
      @url = case @chain
      when :steem then options[:url] || NETWORKS_STEEM_DEFAULT_NODE
      when :test then options[:url] || NETWORKS_TEST_DEFAULT_NODE
      else; raise "Unsupported chain: #{@chain}"
      end
      
      @error_pipe = options[:error_pipe] || STDERR
      
      @api_name = self.class.api_name ||= :condenser_api
      
      if @api_name == :jsonrpc
        @jsonrpc = self
      else
        # Note, we have to wait until initialize to check this because we don't
        # have access to instance options until now.
        
        @jsonrpc = Jsonrpc.new(options)
        @methods = @jsonrpc.get_api_methods
        
        unless !!@methods[@api_name]
          raise RemoteNodeError, "Unknown API: #{@api_name} (known APIs: #{@methods.keys.join(' ')})"
        end
        
        @methods = @methods[@api_name]
      end
    end
    
    def inspect
      properties = %w(chain url).map do |prop|
        if !!(v = instance_variable_get("@#{prop}"))
          "@#{prop}=#{v}" 
        end
      end.compact.join(', ')
      
      "#<#{self.class.api_class_name} [#{properties}]>"
    end
  private
    def respond_to_missing?(m, include_private = false)
      methods.nil? ? false : methods.include?(m.to_sym)
    end
    
    def signature(rpc_method_name)
      @@signatures ||= {}
      @@signatures[rpc_method_name] ||= jsonrpc.get_signature(method: rpc_method_name).result
    end
    
    def args_keys_to_s(rpc_method_name)
      args = signature(rpc_method_name).args
      args_keys = JSON[args.to_json]
    end
    
    def method_missing(m, *args, &block)
      super unless respond_to_missing?(m)
      
      rpc_method_name = "#{@api_name}.#{m}"
      rpc_args = case @api_name
      when :condenser_api then args
      when :jsonrpc then args.first
      else
        expected_args = signature(rpc_method_name).args
        expected_args_key_string = if expected_args.size > 0
          " (#{args_keys_to_s(rpc_method_name)})"
        end
        expected_args_size = expected_args.size
        
        begin
          args = args.first.to_h
          args_size = args.size
          
          # Some argument are optional, but if the arguments passed are greater
          # than the expected arguments size, we can warn.
          if args_size > expected_args_size
            error_pipe.puts "Warning #{rpc_method_name} expects arguments: #{expected_args_size}, got: #{args_size}"
          end
        rescue NoMethodError => e
          error = Steem::ArgumentError.new("#{rpc_method_name} expects arguments: #{expected_args_size}", e)
          raise error
        rescue
          raise Steem::ArgumentError, "#{rpc_method_name} expects arguments: #{expected_args_size}"
        end
        
        args
      end
      
      response = rpc_post(@api_name, m, rpc_args)
      
      if defined?(response.error) && !!response.error
        if !!response.error.message
          if response.error.message == 'Invalid Request'
            raise Steem::ArgumentError, "Unexpected arguments: #{rpc_args.inspect}.  Expected: #{rpc_method_name} (#{args_keys_to_s(rpc_method_name)})"
          elsif response.error.message == 'Unable to acquire database lock'
            raise Steem::RemoteNodeError, response.error.message
          elsif response.error.message.include? 'plugin not enabled'
            raise Steem::RemoteNodeError, response.error.message
          elsif response.error.message.include? 'argument'
            raise Steem::ArgumentError, "#{rpc_method_name}: #{response.error.message}"
          elsif response.error.message.start_with? 'Bad Cast:'
            raise Steem::ArgumentError, "#{rpc_method_name}: #{response.error.message}"
          elsif response.error.message.include? 'prefix_len'
            raise Steem::ArgumentError, "#{rpc_method_name}: #{response.error.message}"
          else
            puts response.to_json if ENV['DEBUG']
            raise "#{rpc_method_name}: #{response.error.message}"
          end
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
    
    def rpc_id
      @rpc_id ||= 0
      @rpc_id = @rpc_id + 1
    end
    
    def uri
      @uri ||= URI.parse(@url)
    end
    
    def http
      @http ||= Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = true
        http.keep_alive_timeout = 2 # seconds
        
        # WARNING This method opens a serious security hole. Never use this
        # method in production code.
        # http.set_debug_output(STDOUT) if !!ENV['DEBUG']
      end
    end
    
    def http_post
      @http_post ||= Net::HTTP::Post.new(uri.request_uri, POST_HEADERS)
    end
    
    def put(api_name = @api_name, api_method = nil, options = {})
      current_rpc_id = rpc_id
      rpc_method_name = "#{api_name}.#{api_method}"
      options ||= {}
      request_body = defined?(options.delete) ? options.delete(:request_body) : []
      request_body ||= []
      
      request_body << {
        jsonrpc: '2.0',
        id: current_rpc_id,
        method: rpc_method_name,
        params: options
      }
      
      request_body
    end
    
    def rpc_post(api_name = @api_name, api_method = nil, options = {}, &block)
      request = http_post
      
      request_body = if !!api_name && !!api_method
        put(api_name, api_method, options)
      elsif !!options && defined?(options.delete)
        options.delete(:request_body)
      end
      
      request.body = if request_body.size == 1
        request_body.first.to_json
      else
        request_body.to_json
      end
      
      response = http.request(request)
      
      case response.code
      when '200'
        response = JSON[response.body]
        response = case response
        when Hash then Hashie::Mash.new(response)
        when Array then Hashie::Array.new(response)
        else; response
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
      else
        raise "#{api_name}.#{api_method}: #{response.body}"
      end
    end
  end
end
