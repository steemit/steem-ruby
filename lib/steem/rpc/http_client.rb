module Steem
  module RPC
    # {HttpClient} is intended for single-threaded applications.  For
    # multi-threaded apps, use {ThreadSafeHttpClient}.
    class HttpClient < BaseClient
      # Timeouts are lower level errors, related in that retrying them is
      # trivial, unlike, for example TransactionExpiredError, that *requires*
      # the client to do something before retrying.
      # 
      # These situations are hopefully momentary interruptions or rate limiting
      # but they might indicate a bigger problem with the node, so they are not
      # retried forever, only up to MAX_TIMEOUT_RETRY_COUNT and then we give up.
      # 
      # *Note:* {JSON::ParserError} is included in this list because under
      # certain timeout conditions, a web server may respond with a generic
      # http status code of 200 and HTML page.
      # 
      # @private
      TIMEOUT_ERRORS = [Net::OpenTimeout, JSON::ParserError, Net::ReadTimeout,
        Errno::EBADF, IOError, Errno::ENETDOWN, Steem::RemoteDatabaseLockError]
      
      # @private
      POST_HEADERS = {
        'Content-Type' => 'application/json; charset=utf-8',
        'User-Agent' => Steem::AGENT_ID
      }
      
      JSON_RPC_BATCH_SIZE_MAXIMUM = 50
      
      def http
        @http ||= Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = true if uri.to_s =~ /^https/i
          http.keep_alive_timeout = 150 # seconds
          
          # WARNING This method opens a serious security hole. Never use this
          # method in production code.
          # http.set_debug_output(STDOUT) if !!ENV['DEBUG']
        end
      end
      
      def http_post
        @http_post ||= Net::HTTP::Post.new(uri.request_uri, POST_HEADERS)
      end
      
      def http_request(request)
        http.request(request)
      end
      
      # This is the main method used by API instances to actually fetch data
      # from the remote node.  It abstracts the api namespace, method name, and
      # parameters so that the API instance can be decoupled from the protocol.
      # 
      # @param api_name [String] API namespace of the method being called.
      # @param api_method [String] API method name being called.
      # @param options [Hash] options
      # @option options [Object] :request_object Hash or Array to become json in request body.
      def rpc_execute(api_name = @api_name, api_method = nil, options = {}, &block)
        reset_timeout
        
        catch :tota_cera_pila do; begin
          request = http_post
          
          request_object = if !!api_name && !!api_method
            put(api_name, api_method, options)
          elsif !!options && defined?(options.delete)
            options.delete(:request_object)
          end
          
          if request_object.size > JSON_RPC_BATCH_SIZE_MAXIMUM
            raise JsonRpcBatchMaximumSizeExceededError, "Maximum json-rpc-batch is #{JSON_RPC_BATCH_SIZE_MAXIMUM} elements."
          end
          
          request.body = if request_object.class == Hash
            request_object
          elsif request_object.size == 1
            request_object.first
          else
            request_object
          end.to_json
          
          response = catch :http_request do; begin; http_request(request)
          rescue *TIMEOUT_ERRORS => e
            throw retry_timeout(:http_request, e)
          end; end
          
          if response.nil?
            throw retry_timeout(:tota_cera_pila, 'response was nil')
          end
          
          case response.code
          when '200'
            response = catch :parse_json do; begin; JSON[response.body]
            rescue *TIMEOUT_ERRORS => e
              throw retry_timeout(:parse_json, e)
            end; end
            
            response = case response
            when Hash
              Hashie::Mash.new(response).tap do |r|
                evaluate_id(request: request_object.first, response: r, api_method: api_method)
              end
            when Array
              Hashie::Array.new(response).tap do |r|
                request_object.each_with_index do |req, index|
                  evaluate_id(request: req, response: r[index], api_method: api_method)
                end
              end
            else; response
            end
            
            [response].flatten.each_with_index do |r, i|
              error = if defined?(r.error) && !!r.error
                r.error
              elsif defined?(r.result.error) && !!r.result.error
                r.result.error
              end
              
              if !!error
                if !!error.message
                  begin
                    rpc_method_name = "#{api_name}.#{api_method}"
                    rpc_args = [request_object].flatten[i]
                    raise_error_response rpc_method_name, rpc_args, r
                  rescue *TIMEOUT_ERRORS => e
                    throw retry_timeout(:tota_cera_pila, e)
                  end
                else
                  raise Steem::ArgumentError, error.inspect
                end
              end
            end
            
            yield_response response, &block
          when '504' # Gateway Timeout
            throw retry_timeout(:tota_cera_pila, response.body)
          when '502' # Bad Gateway
            throw retry_timeout(:tota_cera_pila, response.body)
          else
            raise UnknownError, "#{api_name}.#{api_method}: #{response.body}"
          end
        end; end
      end
      
      def rpc_batch_execute(options = {}, &block)
        yield_response rpc_execute(nil, nil, options), &block
      end
    end
  end
end
