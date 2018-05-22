require 'test_helper'

module Steem
  # :nocov:
  class AccountHistoryApiTest < Steem::Test
    def setup
      @api = Steem::AccountHistoryApi.new(url: TEST_NODE)
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    rescue UnknownApiError => e
      skip('AccountHistoryApi is disabled.')
    end
    
    def test_api_class_name
      assert_equal 'AccountHistoryApi', Steem::AccountHistoryApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<AccountHistoryApi [@chain=steem, @methods=<3 elements>]>", @api.inspect
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
    
    def test_get_account_history
      vcr_cassette('account_history_api_get_account_history', record: :once) do
        options = {
          account: 'steemit',
          start: 0,
          limit: 0
        }
        
        @api.get_account_history(options) do |result|
          assert_equal Hashie::Array, result.history.class
        end
      end
    end
    
    def test_get_ops_in_block
      vcr_cassette('account_history_api_get_ops_in_block', record: :once) do
        options = {
          block_num: 0,
          only_virtual: true
        }
        
        @api.get_ops_in_block(options) do |result|
          assert_equal Hashie::Array, result.ops.class
        end
      end
    end
    
    def test_get_transaction
      vcr_cassette('account_history_api_get_transaction', record: :once) do
        options = {
          id: 'ef73d8fadf17e2590c6d96efc1ca868edd7dd613',
        }
        
        @api.get_transaction(options) do |result|
          assert_equal Hashie::Array, result.history.class
        end
      end
    end
  end
  # :nocov:
end
