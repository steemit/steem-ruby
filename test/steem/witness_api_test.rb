require 'test_helper'

module Steem
  class WitnessApiTest < Steem::Test
    def setup
      @api = Steem::WitnessApi.new
      @jsonrpc = Jsonrpc.new
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    end
    
    def test_api_class_name
      assert_equal 'WitnessApi', Steem::WitnessApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<WitnessApi [@chain=steem, @methods=<2 elements>]>", @api.inspect
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
    
    def test_get_account_bandwidth
      vcr_cassette('witness_api_get_account_bandwidth', record: :once) do
        options = {
          account: 'steemit',
          type: 'forum'
        }
        
        @api.get_account_bandwidth(options) do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_reserve_ratio
      vcr_cassette('witness_api_get_reserve_ratio', record: :once) do
        @api.get_reserve_ratio do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
  end
end