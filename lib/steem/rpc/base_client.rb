module Steem
  module RPC
    class BaseClient
      include ChainConfig
      
      attr_accessor :chain, :error_pipe
      
      # @private
      POST_HEADERS = {
        'Content-Type' => 'application/json; charset=utf-8',
        'User-Agent' => Steem::AGENT_ID
      }
      
      def initialize(options = {})
        @chain = options[:chain] || :steem
        @error_pipe = options[:error_pipe] || STDERR
        @api_name = options[:api_name]
        @url = case @chain
        when :steem then options[:url] || NETWORKS_STEEM_DEFAULT_NODE
        when :test then options[:url] || NETWORKS_TEST_DEFAULT_NODE
        else; raise UnsupportedChainError, "Unsupported chain: #{@chain}"
        end
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
          raise IncorrectResponseIdError, "#{method}: The json-rpc id did not match.  Request was: #{req_id}, got: #{res_id.inspect}", error.nil? ? nil : error.to_json
        end
      end
      
      def http_request(request)
        http.request(request)
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
        
        response = http_request(request)
        
        case response.code
        when '200'
          response = JSON[response.body]
          response = case response
          when Hash
            Hashie::Mash.new(response).tap do |r|
              evaluate_id(request: request_body.first, response: r, api_method: api_method)
            end
          when Array
            Hashie::Array.new(response).tap do |r|
              request_body.each_with_index do |req, index|
                evaluate_id(request: req, response: r[index], api_method: api_method)
              end
            end
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
          raise UnknownError, "#{api_name}.#{api_method}: #{response.body}"
        end
      end
      
      def rpc_id
        @rpc_id ||= 0
        @rpc_id += 1
      end
    end
  end
end
