require 'test_helper'

module Steem
  class RcApiTest < Steem::Test
    def setup
      @api = Steem::RcApi.new(url: TEST_NODE)
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    end
    
    def test_api_class_name
      assert_equal 'RcApi', Steem::RcApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<RcApi [@chain=steem, @methods=<3 elements>]>", @api.inspect
    end
    
    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end
    
    def test_all_respond_to
      @methods.each do |key|
        assert @api.respond_to?(key), "expect rpc respond to #{key}"
      end
    end
    
    def test_find_rc_accounts
      vcr_cassette('rc_api_find_rc_accounts', record: :once) do
        options = {
          accounts: ['steem']
        }
        
        @api.find_rc_accounts(options) do |result|
          assert_equal Hashie::Array, result.rc_accounts.class
        end
      end
    end
    
    def test_get_resource_params
      vcr_cassette('rc_api_get_resource_params', record: :once) do
        @api.get_resource_params do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_resource_pool
      vcr_cassette('rc_api_get_resource_pool', record: :once) do
        @api.get_resource_pool do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
  end
end
