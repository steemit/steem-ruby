module Steem
  # Steem::Jsonrpc allows you to inspect the available methods offered by a
  # node.  If a node runs a plugin you want, then all of the API methods it
  # can exposes will automatically be available.  This API is used internally to
  # determine which APIs and methods are available on the node you specify.
  #
  # In theory, if a new plugin is created and enabled by the node, it will be
  # available by this library without needing an update to its code.
  class Jsonrpc < Api
    API_METHODS = %i(get_signature get_methods)
    
    def self.api_methods
      @api_methods ||= {}
    end
    
    # Might help diagnose a cluster that has asymmetric plugin definitions.
    def self.reset_api_methods
      @api_methods = nil
    end
    
    def initialize(options = {})
      self.class.api_name = :jsonrpc
      @methods = API_METHODS
      super
    end
    
    def get_api_methods(&block)
      api_methods = self.class.api_methods[uri.to_s]
      
      if api_methods.nil?
        get_methods do |result, error, rpc_id|
          methods = result.map do |method|
            method.split('.').map(&:to_sym)
          end
          
          api_methods = Hashie::Mash.new
          
          methods.each do |api, method|
            api_methods[api] ||= []
            api_methods[api] << method
          end
          
          self.class.api_methods[uri.to_s] = api_methods
        end
      end
      
      if !!block
        api_methods.each do |api, methods|
          yield api, methods
        end
      else
        return api_methods
      end
    end
    
    def get_all_signatures(&block)
      request_body = []
      method_names = []
      method_map = {}
      signatures = {}
      
      get_api_methods do |api, methods|
        request_body += methods.map do |method|
          method_name = "#{api}.#{method}"
          method_names << method_name
          current_rpc_id = rpc_id
          method_map[current_rpc_id] = [api, method]
          
          {
            jsonrpc: '2.0',
            id: current_rpc_id,
            method: 'jsonrpc.get_signature',
            params: {method: method_name}
          }
        end
      end
      
      rpc_post(nil, nil, {request_body: request_body}) do |result, error, id|
        api, method = method_map[id]
        api = api.to_sym
        method = method.to_sym
        
        signatures[api] ||= {}
        signatures[api][method] = result
      end
      
      if !!block
        signatures.each do |api, methods|
          yield api, methods
        end
      else
        return signatures
      end
    end
  end
end
