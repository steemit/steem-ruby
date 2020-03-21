module Steem
  module RPC
    class BaseClient
      include ChainConfig
      
      attr_accessor :url, :chain, :error_pipe
      
      # @private
      MAX_TIMEOUT_RETRY_COUNT = 100
      
      # @private
      MAX_TIMEOUT_BACKOFF = 30
      
      # @private
      TIMEOUT_ERRORS = [Net::ReadTimeout, Errno::EBADF, IOError]
      
      def initialize(options = {})
        @chain = options[:chain] || :steem
        @error_pipe = options[:error_pipe] || STDERR
        @api_name = options[:api_name]
        @url = case @chain
        when :steem then options[:url] || NETWORKS_STEEM_DEFAULT_NODE
        when :test then options[:url] || NETWORKS_TEST_DEFAULT_NODE
        when :hive then options[:url] || NETWORKS_HIVE_DEFAULT_NODE
        else; raise UnsupportedChainError, "Unsupported chain: #{@chain}"
        end
      end
      
      def uri
        @uri ||= URI.parse(url)
      end
      
      # Adds a request object to the stack.  Usually, this method is called
      # internally by {BaseClient#rpc_execute}.  If you want to create a batched
      # request, use this method to add to the batch then execute {BaseClient#rpc_batch_execute}.
      def put(api_name = @api_name, api_method = nil, options = {})
        current_rpc_id = rpc_id
        rpc_method_name = "#{api_name}.#{api_method}"
        options ||= {}
        request_object = defined?(options.delete) ? options.delete(:request_object) : []
        request_object ||= []
        
        request_object << {
          jsonrpc: '2.0',
          id: current_rpc_id,
          method: rpc_method_name,
          params: options
        }
        
        request_object
      end
      
      # @abstract Subclass is expected to implement #rpc_execute.
      # @!method rpc_execute
      
      # @abstract Subclass is expected to implement #rpc_batch_execute.
      # @!method rpc_batch_execute
      
      # To be called by {BaseClient#rpc_execute} and {BaseClient#rpc_batch_execute}
      # when a response has been consructed.
      def yield_response(response, &block)
        if !!block
          case response
          when Hashie::Mash then yield response.result, response.error, response.id
          when Hashie::Array
            response.each do |r|
              r = Hashie::Mash.new(r)
              block.call r.result, r.error, r.id
            end
          else; block.call response
          end
        end
        
        response
      end
      
      # Checks json-rpc request/response for corrilated id.  If they do not
      # match, {IncorrectResponseIdError} is thrown.  This is usually caused by
      # the client, involving thread safety.  It can also be caused by the node
      # responding without an id.
      # 
      # To avoid {IncorrectResponseIdError}, make sure you implement your client
      # correctly.
      # 
      # Setting DEBUG=true in the envrionment will cause this method to output
      # both the request and response json.
      # 
      # @param options [Hash] options
      # @option options [Boolean] :debug Enable or disable debug output.
      # @option options [Hash] :request to compare id
      # @option options [Hash] :response to compare id
      # @option options [String] :api_method
      # @see {ThreadSafeHttpClient}
      def evaluate_id(options = {})
        debug = options[:debug] || ENV['DEBUG'] == 'true'
        request = options[:request]
        response = options[:response]
        api_method = options[:api_method]
        req_id = request[:id].to_i
        res_id = !!response['id'] ? response['id'].to_i : nil
        method = [@api_name, api_method].join('.')
        
        if debug
          req = JSON.pretty_generate(request)
          res = JSON.parse(response) rescue response
          res = JSON.pretty_generate(response) rescue response
          
          error_pipe.puts '=' * 80
          error_pipe.puts "Request:"
          error_pipe.puts req
          error_pipe.puts '=' * 80
          error_pipe.puts "Response:"
          error_pipe.puts res
          error_pipe.puts '=' * 80
          error_pipe.puts Thread.current.backtrace.join("\n")
        end
        
        error = response['error'].to_json if !!response['error']
              
        if req_id != res_id
          raise IncorrectResponseIdError, "#{method}: The json-rpc id did not match.  Request was: #{req_id}, got: #{res_id.inspect}", BaseError.send(:build_backtrace, error)
        end
      end
      
      # Current json-rpc id used for a request.  This version auto-increments
      # for each call.  Subclasses can use their own strategy.
      def rpc_id
        @rpc_id ||= 0
        @rpc_id += 1
      end
    private
      # @private
      def reset_timeout
        @timeout_retry_count = 0
        @back_off = 0.1
      end
      
      # @private
      def retry_timeout(context, cause = nil)
        @timeout_retry_count += 1
        
        if @timeout_retry_count > MAX_TIMEOUT_RETRY_COUNT
          raise TooManyTimeoutsError.new("Too many timeouts for: #{context}", cause)
        elsif @timeout_retry_count % 10 == 0
          msg = "#{@timeout_retry_count} retry attempts for: #{context}"
          msg += "; cause: #{cause}" if !!cause
          error_pipe.puts msg
        end
        
        backoff_timeout
        
        context
      end
      
      # Expontential backoff.
      #
      # @private
      def backoff_timeout
        @backoff ||= 0.1
        @backoff *= 2
        @backoff = 0.1 if @backoff > MAX_TIMEOUT_BACKOFF
        
        sleep @backoff
      end
      
      # @private
      def raise_error_response(rpc_method_name, rpc_args, response)
        raise UnknownError, "#{rpc_method_name}: #{response}" if response.error.nil?
        
        error = response.error
        
        if error.message == 'Invalid Request'
          raise Steem::ArgumentError, "Unexpected arguments: #{rpc_args.inspect}.  Expected: #{rpc_method_name} (#{args_keys_to_s(rpc_method_name)})"
        end
        
        BaseError.build_error(error, rpc_method_name)
      end
    end
  end
end
