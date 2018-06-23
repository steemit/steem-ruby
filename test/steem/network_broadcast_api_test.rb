require 'test_helper'

module Steem
  class NetworkBroadcastApiTest < Steem::Test
    def setup
      @api = Steem::NetworkBroadcastApi.new(url: TEST_NODE)
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    end
    def test_api_class_name
      assert_equal 'NetworkBroadcastApi', Steem::NetworkBroadcastApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<NetworkBroadcastApi [@chain=steem, @methods=<3 elements>]>", @api.inspect
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
    
    def test_broadcast_block
      vcr_cassette('broadcast_block') do
        options = {
          block: {
            previous: "0000000000000000000000000000000000000000",
            timestamp: "1970-01-01T00:00:00",
            witness: "",
            transaction_merkle_root: "0000000000000000000000000000000000000000",
            extensions: [],
            witness_signature: "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            transactions: []
          }
        }
        
        assert_raises BlockTooOldError do
          @api.broadcast_block(options)
        end
      end
    end
    
    def test_broadcast_transaction
      vcr_cassette('broadcast_transaction') do
        options = {
          trx: {
            ref_block_num: 0,
            ref_block_prefix: 0,
            expiration: "1970-01-01T00:00:00",
            operations: [],
            extensions: [],
            signatures: []
          },
          max_block_age: -1
        }
        
        assert_raises EmptyTransactionError do
          @api.broadcast_transaction(options)
        end
      end
    end
    
    def test_broadcast_transaction_synchronous
      skip 'work in progress'
      
      vcr_cassette('broadcast_transaction_synchronous') do
        builder = TransactionBuilder.new(wif: '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC')
        
        builder.put(vote: {
          voter: 'social',
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        })
        
        assert 1, builder.operations.size
        
        options = {
          trx: builder.transaction,
          max_block_age: 30
        }
        
        puts @api.broadcast_transaction_synchronous(options)
      end
    end
  end
end