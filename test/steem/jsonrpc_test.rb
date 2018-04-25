require 'test_helper'

module Steem
  class JsonrpcTest < Steem::Test
    def setup
      @jsonrpc = Jsonrpc.new
    end
    
    def test_reset_api_methods
      assert_nil Jsonrpc::reset_api_methods, 'expect nil result'
    end
    
    def test_get_api_methods
      vcr_cassette('get_methods') do
        apis = @jsonrpc.get_api_methods
        assert_equal Hashie::Mash, apis.class
      end
    end
    
    def test_get_signature
      vcr_cassette('get_signature') do
        signature = @jsonrpc.get_signature(method: 'database_api.get_active_witnesses')
        assert_equal Hashie::Mash, signature.class
      end
    end
    
    def test_get_all_signatures
      vcr_cassette('get_all_signatures') do
        refute_nil @jsonrpc.get_methods
        
        @jsonrpc.get_all_signatures do |api, methods|
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
    
    def test_get_all_signatures_no_closure
      vcr_cassette('get_all_signatures') do
        assert @jsonrpc.get_all_signatures, 'expect signatures'
      end
    end
    
    def test_get_methods_bad_node
      vcr_cassette('get_methods_bad_node') do
        assert_raises SocketError do
          jsonrpc = Steem::Jsonrpc.new(url: 'https://bad.node')
          jsonrpc.get_methods
        end
      end
    end
    
    def test_get_methods_non_api_endpoint
      vcr_cassette('get_methods_non_api_endpoint') do
        assert_raises RuntimeError do
          jsonrpc = Steem::Jsonrpc.new(url: 'https://test.com')
          jsonrpc.get_methods
        end
      end
    end
    
    # def test_get_methods_non_appbase
    #   vcr_cassette('get_methods_non_appbase') do
    #     assert_raises JSON::ParserError do
    #       jsonrpc = Steem::Jsonrpc.new(url: 'https://rpc.steemviz.com')
    #       jsonrpc.get_methods
    #     end
    #   end
    # end
    
    # def test_get_methods_bad_uri
    #   vcr_cassette('get_methods_bad_uri') do
    #     assert_raises JSON::ParserError do
    #       jsonrpc = Steem::Jsonrpc.new(url: 'https://rpc.steemviz.com/health')
    #       jsonrpc.get_methods
    #     end
    #   end
    # end
  end
end
