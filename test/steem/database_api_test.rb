require 'test_helper'

module Steem
  class DatabaseApiTest < Steem::Test
    def setup
      @api = Steem::DatabaseApi.new
      @jsonrpc = Jsonrpc.new
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    end
    def test_api_class_name
      assert_equal 'DatabaseApi', Steem::DatabaseApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<DatabaseApi [@chain=steem, @url=https://api.steemit.com]>", @api.inspect
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
    
    def test_find_account_recovery_requests
      vcr_cassette('find_account_recovery_requests') do
        @api.find_account_recovery_requests(accounts: ['steemit']) do |result|
          assert_equal Hashie::Array, result.requests.class
        end
      end
    end
    
    def test_find_accounts
      vcr_cassette('find_accounts') do
        @api.find_accounts(accounts: ['steemit']) do |result|
          assert_equal Hashie::Array, result.accounts.class
        end
      end
    end
    
    def test_find_change_recovery_account_requests
      vcr_cassette('find_change_recovery_account_requests') do
        @api.find_change_recovery_account_requests(accounts: ['steemit']) do |result|
          assert_equal Hashie::Array, result.requests.class
        end
      end
    end
    
    def test_find_comments
      vcr_cassette('find_comments') do
        @api.find_comments(comments: [['steemit', 'firstpost']]) do |result|
          assert_equal Hashie::Array, result.comments.class
        end
      end
    end
    
    def test_find_decline_voting_rights_requests
      vcr_cassette('find_decline_voting_rights_requests') do
        @api.find_decline_voting_rights_requests(accounts: ['steemit']) do |result|
          assert_equal Hashie::Array, result.requests.class
        end
      end
    end
    
    def test_find_escrows
      vcr_cassette('find_escrows') do
        @api.find_escrows(from: 'steemit') do |result|
          assert_equal Hashie::Array, result.escrows.class
        end
      end
    end
    
    def test_find_limit_orders
      vcr_cassette('find_limit_orders') do
        @api.find_limit_orders(account: 'steemit') do |result|
          assert_equal Hashie::Array, result.orders.class
        end
      end
    end
    
    def test_find_owner_histories
      vcr_cassette('find_owner_histories') do
        @api.find_owner_histories(owner: 'steemit') do |result|
          assert_equal Hashie::Array, result.owner_auths.class
        end
      end
    end
    
    def test_find_savings_withdrawals
      vcr_cassette('find_savings_withdrawals') do
        @api.find_savings_withdrawals(account: 'steemit') do |result|
          assert_equal Hashie::Array, result.withdrawals.class
        end
      end
    end
    
    def test_find_sbd_conversion_requests
      vcr_cassette('find_sbd_conversion_requests') do
        @api.find_sbd_conversion_requests(account: 'steemit') do |result|
          assert_equal Hashie::Array, result.requests.class
        end
      end
    end
    
    def test_find_vesting_delegation_expirations
      vcr_cassette('find_vesting_delegation_expirations') do
        @api.find_vesting_delegation_expirations(account: 'steemit') do |result|
          assert_equal Hashie::Array, result.delegations.class
        end
      end
    end
    
    def test_find_vesting_delegations
      vcr_cassette('find_vesting_delegations') do
        @api.find_vesting_delegations(account: 'steemit') do |result|
          assert_equal Hashie::Array, result.delegations.class
        end
      end
    end
    
    def test_find_votes
      vcr_cassette('find_votes') do
        @api.find_votes(author: 'steemit', permlink: 'firstpost') do |result|
          assert_equal Hashie::Array, result.votes.class
        end
      end
    end
    
    def test_find_withdraw_vesting_routes
      vcr_cassette('find_withdraw_vesting_routes') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L607
        options = {
          account: 'steemit',
          order: 'by_withdraw_route'
        }
        
        @api.find_withdraw_vesting_routes(options) do |result|
          assert_equal Hashie::Array, result.routes.class
        end
      end
    end
    
    def test_find_witnesses
      vcr_cassette('find_witnesses') do
        @api.find_witnesses(owners: ['steemit']) do |result|
          assert_equal Hashie::Array, result.witnesses.class
        end
      end
    end
    
    def test_get_active_witnesses
      vcr_cassette('get_active_witnesses') do
        @api.get_active_witnesses do |result|
          assert_equal Hashie::Array, result.witnesses.class
        end
      end
    end
    
    def test_get_config
      vcr_cassette('get_config') do
        @api.get_config do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_current_price_feed
      vcr_cassette('get_current_price_feed') do
        @api.get_current_price_feed do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_dynamic_global_properties
      vcr_cassette('get_dynamic_global_properties') do
        @api.get_dynamic_global_properties do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_feed_history
      vcr_cassette('get_feed_history') do
        @api.get_feed_history do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_hardfork_properties
      vcr_cassette('get_hardfork_properties') do
        @api.get_hardfork_properties do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_order_book
      vcr_cassette('get_order_book') do
        @api.get_order_book do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_potential_signatures
      vcr_cassette('get_potential_signatures') do
        options = {
          trx:{
            ref_block_num: 0,
            ref_block_prefix: 0,
            expiration: "1970-01-01T00:00:00",
            operations: [],
            extensions: [],
            signatures: []
          }
        }
        
        @api.get_potential_signatures(options) do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_required_signatures
      vcr_cassette('get_required_signatures') do
        options = {
          trx:{
            ref_block_num: 0,
            ref_block_prefix: 0,
            expiration: "1970-01-01T00:00:00",
            operations: [],
            extensions: [],
            signatures: []
          }
        }
        
        @api.get_required_signatures(options) do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_reward_funds
      vcr_cassette('get_reward_funds') do
        @api.get_reward_funds do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_transaction_hex
      vcr_cassette('get_transaction_hex') do
        trx = {
          ref_block_num: 0,
          ref_block_prefix: 0,
          expiration: "1970-01-01T00:00:00",
          operations: [],
          extensions: [],
          signatures: []
        }
        
        @api.get_transaction_hex(trx: trx) do |result|
          assert_equal Hashie::Mash, result.class
          assert_equal '00000000000000000000000000', result.hex
        end
      end
    end
    
    def test_get_transaction_hex_account_create
      vcr_cassette('get_transaction_hex') do
        trx = {
          ref_block_num: 19297,
          ref_block_prefix: 1608085982,
          expiration: "2016-03-23T22:41:21",
          operations: [
            [:account_create, {
              fee: ['0', 3, '@@000000021'], # 0.000 STEEM
              creator: "initminer",
              new_account_name: "scott",
              owner: {
                weight_threshold: 1,
                account_auths: [],
                key_auths: [["STM7DTS62msowgpAZJBNRMStMUt5bfRA4hc9j5wjwU4vKhi3KFkKb", 1]]
              },
              active: {
                weight_threshold: 1,
                account_auths: [],
                key_auths: [["STM8k1f8fvHxLrCTqMdRUJcK2rCE3y7SQBb8PremyadWvVWMeedZy", 1]]
              },
              posting: {
                weight_threshold: 1,
                account_auths: [],
                key_auths: [["STM6DgpKJqoVGg7o6J1jdiP45xxbgoUg5VGzs96YBxX42NZu2bZea", 1]]
              },
              memo_key: "STM6ppNVEFmvBW4jEkzxXnGKuKuwYjMUrhz2WX1kHeGSchGdWJEDQ",
              json_metadata: ""
            }
          ]],
          extensions: [],
          signatures: []
        }
        
        expected_hex = '614bde71d95f911bf3560109000000000000000003535445454d0' +
        '00009696e69746d696e65720573636f7474010000000001033275' +
        '7668fa45c2bc21447a2ff1dc2bbed9d9dda1616fd7b700255bd28' +
        'e9d674a010001000000000103fb8900a262d51b908846be54fcf0' +
        '4b3a80d12ee749b9446f976b58b220ba4eed01000100000000010' +
        '2af4963d0f034043f4b4b0c99220e6a4b5d8b9cc71e5cd7d110f7' +
        '602f3a0a11d1010002ff0de11ef55b998daf88047f1a00a60ed5d' +
        'ffb0c23c3279f8bd42a733845c5da000000'
        
        @api.get_transaction_hex(trx: trx) do |result|
          assert_equal Hashie::Mash, result.class
          assert_equal expected_hex, result.hex
          assert result.hex.include?('535445454d'), 'expect hex to include "STEEM"'
          assert result.hex.include?('73636f7474'), 'expect hex to include "scott"'
        end
      end
    end
    
    def test_get_witness_schedule
      vcr_cassette('get_witness_schedule') do
        @api.get_witness_schedule do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_list_account_recovery_requests
      vcr_cassette('list_account_recovery_requests') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L406
        options = {
          start: nil,
          limit: 0,
          order: 'by_account'
        }
        
        @api.list_account_recovery_requests(options) do |result|
          assert_equal Hashie::Array, result.requests.class
        end
      end
    end
    
    def test_list_accounts
      vcr_cassette('list_accounts') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L307
        options = {
          start: nil,
          limit: 0,
          order: 'by_name'
        }
        
        @api.list_accounts(options) do |result|
          assert_equal Hashie::Array, result.accounts.class
        end
      end
    end
    
    def test_list_change_recovery_account_requests
      vcr_cassette('list_change_recovery_account_requests') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L460
        options = {
          start: nil,
          limit: 0,
          order: 'by_account'
        }
        
        @api.list_change_recovery_account_requests(options) do |result|
          assert_equal Hashie::Array, result.requests.class
        end
      end
    end
    
    def test_list_comments
      vcr_cassette('list_comments') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L941
        options = {
          start: ['2016-03-24T16:00:00', 'steemit', 'firstpost'],
          limit: 0,
          order: 'by_cashout_time'
        }
        
        @api.list_comments(options) do |result|
          assert_equal Hashie::Array, result.comments.class
        end
      end
    end
    
    def test_list_decline_voting_rights_requests
      vcr_cassette('list_decline_voting_rights_requests') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L867
        options = {
          start: nil,
          limit: 0,
          order: 'by_account'
        }
        
        @api.list_decline_voting_rights_requests(options) do |result|
          assert_equal Hashie::Array, result.requests.class
        end
      end
    end
    
    def test_list_escrows
      vcr_cassette('list_escrows') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L515
        options = {
          start: ['steemit'],
          limit: 0,
          order: 'by_from_id'
        }
        
        @api.list_escrows(options) do |result|
          assert_equal Hashie::Array, result.escrows.class
        end
      end
    end
    
    def test_list_limit_orders
      vcr_cassette('list_limit_orders') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L1278
        options = {
          start: [],
          limit: 0,
          order: 'by_price'
        }
        
        @api.list_limit_orders(options) do |result|
          assert_equal Hashie::Array, result.orders.class
        end
      end
    end
    
    def test_list_owner_histories
      vcr_cassette('list_owner_histories') do
        @api.list_owner_histories(start: [], limit: 0) do |result|
          assert_equal Hashie::Array, result.owner_auths.class
        end
      end
    end
    
    def test_list_sbd_conversion_requests
      vcr_cassette('list_sbd_conversion_requests') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L814
        options = {
          start: [],
          limit: 0,
          order: 'by_conversion_date'
        }
        
        @api.list_sbd_conversion_requests(options) do |result|
          assert_equal Hashie::Array, result.requests.class
        end
      end
    end
    
    def test_list_vesting_delegation_expirations
      vcr_cassette('list_vesting_delegation_expirations') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L759
        options = {
          start: [],
          limit: 0,
          order: 'by_expiration'
        }
        
        @api.list_vesting_delegation_expirations(options) do |result|
          assert_equal Hashie::Array, result.delegations.class
        end
      end
    end
    
    def test_list_vesting_delegations
      vcr_cassette('list_vesting_delegations') do
        # by_delegation is the only known order types:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L705
        options = {
          start: [],
          limit: 0,
          order: 'by_delegation'
        }
        
        @api.list_vesting_delegations(options) do |result|
          assert_equal Hashie::Array, result.delegations.class
        end
      end
    end
    
    def test_list_votes
      vcr_cassette('list_votes') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L1125
        options = {
          start: [nil, nil, nil],
          limit: 0,
          order: 'by_voter_comment'
        }
        
        @api.list_votes(options) do |result|
          assert_equal Hashie::Array, result.votes.class
        end
      end
    end
    
    def test_list_withdraw_vesting_routes
      vcr_cassette('list_withdraw_vesting_routes') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L759
        options = {
          start: [],
          limit: 0,
          order: 'by_withdraw_route'
        }
        
        @api.list_withdraw_vesting_routes(options) do |result|
          assert_equal Hashie::Array, result.routes.class
        end
      end
    end
    
    def test_list_witness_votes
      vcr_cassette('list_witness_votes') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L252
        options = {
          start: [],
          limit: 0,
          order: 'by_account_witness'
        }
        
        @api.list_witness_votes(options) do |result|
          assert_equal Hashie::Array, result.votes.class
        end
      end
    end
    
    def test_list_witnesses
      vcr_cassette('list_witnesses') do
        # Other order types are listed here:
        # https://github.com/steemit/steem/blob/1cfdf8101ec415156b155c9ec90b0a4d439a039f/libraries/plugins/apis/database_api/database_api.cpp#L188
        options = {
          start: 'steemit',
          limit: 0,
          order: 'by_name'
        }
        
        @api.list_witnesses(options) do |result|
          assert_equal Hashie::Array, result.witnesses.class
        end
      end
    end
    
    def test_verify_account_authority
      vcr_cassette('verify_account_authority') do
        options = {
          account: 'steemit',
          signers: ['STM7Q2rLBqzPzFeteQZewv9Lu3NLE69fZoLeL6YK59t7UmssCBNTU']
        }
        
        assert_raises RuntimeError do
          @api.verify_account_authority(options)
        end
      end
    end
    
    def test_verify_authority
      vcr_cassette('verify_authority') do
        options = {
          trx:{
            ref_block_num: 0,
            ref_block_prefix: 0,
            expiration: "1970-01-01T00:00:00",
            operations: [],
            extensions: [],
            signatures: []
          }
        }
        
        @api.verify_authority(options) do |result|
          assert_equal TrueClass, result.valid.class
        end
      end
    end
    
    def test_verify_signatures
      vcr_cassette('verify_signatures') do
        options = {
          hash: "0000000000000000000000000000000000000000000000000000000000000000",
          signatures: [],
          required_owner: [],
          required_active: [],
          required_posting: [],
          required_other: []
        }
        
        @api.verify_signatures(options) do |result|
          assert_equal TrueClass, result.valid.class
        end
      end
    end
  end
end