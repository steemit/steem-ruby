require 'test_helper'

module Steem
  class JsonrpcTest < Steem::Test
    def setup
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
    end
    
    def test_reset_api_methods
      assert_nil Jsonrpc::reset_api_methods, 'expect nil result'
    end
    
    def test_get_api_methods
      vcr_cassette('jsonrpc_get_methods', record: :once) do
        apis = @jsonrpc.get_api_methods
        assert_equal Hashie::Mash, apis.class
      end
    end
    
    def test_get_signature
      vcr_cassette('jsonrpc_get_signature', record: :once) do
        signature = @jsonrpc.get_signature(method: 'database_api.get_active_witnesses')
        assert_equal Hashie::Mash, signature.class
      end
    end
    
    def test_get_all_signatures
      vcr_cassette('jsonrpc_get_all_signatures') do
        refute_nil @jsonrpc.get_methods
        all_signatures = @jsonrpc.get_all_signatures
        
        refute_equal 1, all_signatures.size, "did not expect only one api: #{all_signatures.keys.first}"
        refute_equal 50, all_signatures.values.map{ |v| v.keys }.flatten.size, "did not expect 50 signatures (batch problem?)"
        
        all_signatures.each do |api, methods|
          assert_equal Symbol, api.class, "did not expect: #{api.inspect}"
          assert_equal Hash, methods.class, "did not expect: #{methods.inspect}"
          methods.each do |method, signature|
            assert_equal Symbol, method.class, "did not expect: #{method.inspect}"
            assert_equal Hashie::Mash, signature.class, "did not expect: #{signature.inspect}"
            refute_nil signature.args, "did not expect #{api}.#{method} to have nil args"
            
            if api == :condenser_api
              if %i(
                get_account_bandwidth get_block get_block_header get_escrow
                get_witness_by_account get_recovery_request
              ).include? method
                assert_nil signature.ret, "expect #{api}.#{method} to have nil ret"
              else
                refute_nil signature.ret, "did not expect #{api}.#{method} to have nil ret"
              end
            else
              refute_nil signature.ret, "did not expect #{api}.#{method} to have nil ret"
            end
          end
        end
      end
    end
    
    def test_get_all_signatures_with_closure
      vcr_cassette('jsonrpc_get_all_signatures_no_closure', record: :once) do
        @jsonrpc.get_all_signatures do |result|
          assert result, 'expect signatures'
        end
      end
    end
    
    def test_get_methods_bad_node
      vcr_cassette('jsonrpc_get_methods_bad_node', record: :once) do
        assert_raises SocketError, Errno::ECONNREFUSED do
          jsonrpc = Jsonrpc.new(url: 'https://bad.node')
          jsonrpc.get_methods
        end
      end
    end
    
    def test_get_methods_non_api_endpoint
      vcr_cassette('jsonrpc_get_methods_non_api_endpoint', record: :once) do
        assert_raises UnknownError do # FIXME
          jsonrpc = Jsonrpc.new(url: 'https://test.com')
          jsonrpc.get_methods
        end
      end
    end
    
    # def test_get_methods_non_appbase
    #   vcr_cassette('jsonrpc_get_methods_non_appbase', record: :once) do
    #     assert_raises JSON::ParserError do
    #       jsonrpc = Jsonrpc.new(url: 'https://rpc.steemviz.com')
    #       jsonrpc.get_methods
    #     end
    #   end
    # end
    
    # def test_get_methods_bad_uri
    #   vcr_cassette('jsonrpc_get_methods_bad_uri', record: :once) do
    #     assert_raises JSON::ParserError do
    #       jsonrpc = Jsonrpc.new(url: 'https://rpc.steemviz.com/health')
    #       jsonrpc.get_methods
    #     end
    #   end
    # end
  end
end
