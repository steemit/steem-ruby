require 'test_helper'

module Steem
  class ReputationApiTest < Steem::Test
    def setup
      @api = Steem::ReputationApi.new(url: TEST_NODE)
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    end
    
    def test_api_class_name
      assert_equal 'ReputationApi', Steem::ReputationApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<ReputationApi [@chain=steem, @methods=<1 element>]>", @api.inspect
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
    
    def test_get_account_reputations
      vcr_cassette('reputation_api_get_account_reputations', record: :once) do
        options = {
          account_lower_bound: 'alice',
          limit: 1
        }
        
        @api.get_account_reputations(options) do |result|
          assert_equal Hashie::Array, result.reputations.class
          assert_equal 'alice', result.reputations.first.account
          assert_equal 0, result.reputations.first.reputation
        end
      end
    end
  end
end
