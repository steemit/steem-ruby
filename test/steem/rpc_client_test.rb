require 'test_helper'

module Steem
  class RpcClientTest < Steem::Test
    def setup
      @rpc_client = RPC::HttpClient.new(url: TEST_NODE)
    end
    
    def test_http_request
      request = @rpc_client.http_post
      assert @rpc_client.http_request request
    end
    
    def test_evalidate_id
      stderr = STDERR.clone
      stderr.reopen File.new('/dev/null', 'w')
      
      rpc_client = RPC::BaseClient.new(error_pipe: stderr)
      options = {
        debug: true,
        request: Hashie::Mash.new({'id' => 1}),
        response: Hashie::Mash.new({
          'id' => 1,
          'error' => {'message' => 'error message'}
        }),
        api_method: 'generic_method'
      }
      
      refute rpc_client.send(:evaluate_id, options)
    end
    
    def test_evalidate_id_wrong
      stderr = STDERR.clone
      stderr.reopen File.new('/dev/null', 'w')
      
      rpc_client = RPC::ThreadSafeHttpClient.new(error_pipe: stderr)
      options = {
        debug: true,
        request: Hashie::Mash.new({'id' => 1}),
        response: Hashie::Mash.new({
          'id' => 2,
          'error' => {'message' => 'error message'}
        }),
        api_method: 'generic_method'
      }
      
      assert_raises IncorrectResponseIdError do
        rpc_client.send(:evaluate_id, options)
      end
    end
    
    def test_rpc_id
      id1 = @rpc_client.rpc_id
      id2 = @rpc_client.rpc_id
      
      refute_equal id1, id2
    end
  end
end