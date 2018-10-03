require 'test_helper'

module Steem
  class DatabaseApiTest < Steem::Test
    def setup
      @api = Steem::DatabaseApi.new(url: TEST_NODE)
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    end
    def test_api_class_name
      assert_equal 'DatabaseApi', Steem::DatabaseApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<DatabaseApi [@chain=steem, @methods=<47 elements>]>", @api.inspect
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
      vcr_cassette('database_api_find_account_recovery_requests', record: :once) do
        @api.find_account_recovery_requests(accounts: ['steemit']) do |result|
          assert_equal Hashie::Array, result.requests.class
        end
      end
    end
    
    def test_find_accounts
      vcr_cassette('database_api_find_accounts', record: :once) do
        @api.find_accounts(accounts: ['steemit']) do |result|
          assert_equal Hashie::Array, result.accounts.class
        end
      end
    end
    
    def test_find_change_recovery_account_requests
      vcr_cassette('database_api_find_change_recovery_account_requests', record: :once) do
        @api.find_change_recovery_account_requests(accounts: ['steemit']) do |result|
          assert_equal Hashie::Array, result.requests.class
        end
      end
    end
    
    def test_find_comments
      vcr_cassette('database_api_find_comments', record: :once) do
        @api.find_comments(comments: [['steemit', 'firstpost']]) do |result|
          assert_equal Hashie::Array, result.comments.class
        end
      end
    end
    
    def test_find_decline_voting_rights_requests
      vcr_cassette('database_api_find_decline_voting_rights_requests', record: :once) do
        @api.find_decline_voting_rights_requests(accounts: ['steemit']) do |result|
          assert_equal Hashie::Array, result.requests.class
        end
      end
    end
    
    def test_find_escrows
      vcr_cassette('database_api_find_escrows', record: :once) do
        @api.find_escrows(from: 'steemit') do |result|
          assert_equal Hashie::Array, result.escrows.class
        end
      end
    end
    
    def test_find_limit_orders
      vcr_cassette('database_api_find_limit_orders', record: :once) do
        @api.find_limit_orders(account: 'steemit') do |result|
          assert_equal Hashie::Array, result.orders.class
        end
      end
    end
    
    def test_find_owner_histories
      vcr_cassette('database_api_find_owner_histories', record: :once) do
        @api.find_owner_histories(owner: 'steemit') do |result|
          assert_equal Hashie::Array, result.owner_auths.class
        end
      end
    end
    
    def test_find_savings_withdrawals
      vcr_cassette('database_api_find_savings_withdrawals', record: :once) do
        @api.find_savings_withdrawals(account: 'steemit') do |result|
          assert_equal Hashie::Array, result.withdrawals.class
        end
      end
    end
    
    def test_find_sbd_conversion_requests
      vcr_cassette('database_api_find_sbd_conversion_requests', record: :once) do
        @api.find_sbd_conversion_requests(account: 'steemit') do |result|
          assert_equal Hashie::Array, result.requests.class
        end
      end
    end
    
    def test_find_vesting_delegation_expirations
      vcr_cassette('database_api_find_vesting_delegation_expirations', record: :once) do
        @api.find_vesting_delegation_expirations(account: 'steemit') do |result|
          assert_equal Hashie::Array, result.delegations.class
        end
      end
    end
    
    def test_find_vesting_delegations
      vcr_cassette('database_api_find_vesting_delegations', record: :once) do
        @api.find_vesting_delegations(account: 'steemit') do |result|
          assert_equal Hashie::Array, result.delegations.class
        end
      end
    end
    
    def test_find_votes
      vcr_cassette('database_api_find_votes', record: :once) do
        @api.find_votes(author: 'steemit', permlink: 'firstpost') do |result|
          assert_equal Hashie::Array, result.votes.class
        end
      end
    end
    
    def test_find_withdraw_vesting_routes
      vcr_cassette('database_api_find_withdraw_vesting_routes', record: :once) do
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
      vcr_cassette('database_api_find_witnesses', record: :once) do
        @api.find_witnesses(owners: ['steemit']) do |result|
          assert_equal Hashie::Array, result.witnesses.class
        end
      end
    end
    
    def test_get_active_witnesses
      vcr_cassette('database_api_get_active_witnesses', record: :once) do
        @api.get_active_witnesses do |result|
          assert_equal Hashie::Array, result.witnesses.class
        end
      end
    end
    
    def test_get_config
      vcr_cassette('database_api_get_config', record: :once) do
        @api.get_config do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_current_price_feed
      vcr_cassette('database_api_get_current_price_feed', record: :once) do
        @api.get_current_price_feed do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_dynamic_global_properties
      vcr_cassette('database_api_get_dynamic_global_properties', record: :once) do
        @api.get_dynamic_global_properties do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_feed_history
      vcr_cassette('database_api_get_feed_history', record: :once) do
        @api.get_feed_history do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_hardfork_properties
      vcr_cassette('database_api_get_hardfork_properties', record: :once) do
        @api.get_hardfork_properties do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_order_book
      vcr_cassette('database_api_get_order_book', record: :once) do
        @api.get_order_book do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_potential_signatures
      vcr_cassette('database_api_get_potential_signatures', record: :once) do
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
      vcr_cassette('database_api_get_required_signatures', record: :once) do
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
      vcr_cassette('database_api_get_reward_funds', record: :once) do
        @api.get_reward_funds do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_transaction_hex
      vcr_cassette('database_api_get_transaction_hex', record: :once) do
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
      vcr_cassette('database_api_get_transaction_hex_account_create', record: :once) do
        trx = {
          ref_block_num: 19297,
          ref_block_prefix: 1608085982,
          expiration: "2016-03-23T22:41:21",
          operations: [{
            type: :account_create_operation, value: {
              fee: {amount: '0', precision: 3, nai: '@@000000021'}, # 0.000 STEEM
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
          }],
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
      vcr_cassette('database_api_get_witness_schedule', record: :once) do
        @api.get_witness_schedule do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_list_account_recovery_requests
      vcr_cassette('database_api_list_account_recovery_requests', record: :once) do
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
      vcr_cassette('database_api_list_accounts', record: :once) do
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
      vcr_cassette('database_api_list_change_recovery_account_requests', record: :once) do
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
      vcr_cassette('database_api_list_comments', record: :once) do
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
      vcr_cassette('database_api_list_decline_voting_rights_requests', record: :once) do
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
      vcr_cassette('database_api_list_escrows', record: :once) do
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
      vcr_cassette('database_api_list_limit_orders', record: :once) do
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
      vcr_cassette('database_api_list_owner_histories', record: :once) do
        @api.list_owner_histories(start: [], limit: 0) do |result|
          assert_equal Hashie::Array, result.owner_auths.class
        end
      end
    end
    
    def test_list_sbd_conversion_requests
      vcr_cassette('database_api_list_sbd_conversion_requests', record: :once) do
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
      vcr_cassette('database_api_list_vesting_delegation_expirations', record: :once) do
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
      vcr_cassette('database_api_list_vesting_delegations', record: :once) do
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
      vcr_cassette('database_api_list_votes', record: :once) do
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
      vcr_cassette('database_api_list_withdraw_vesting_routes', record: :once) do
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
      vcr_cassette('database_api_list_witness_votes', record: :once) do
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
      vcr_cassette('database_api_list_witnesses', record: :once) do
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
      vcr_cassette('database_api_verify_account_authority', record: :once) do
        @api.get_config do |config|
          prefix = config.STEEM_ADDRESS_PREFIX
          options = {
            account: 'steemit',
            signers: ["#{prefix}7Q2rLBqzPzFeteQZewv9Lu3NLE69fZoLeL6YK59t7UmssCBNTU"]
          }
          
          assert_raises MissingActiveAuthorityError do
            @api.verify_account_authority(options)
          end
        end
      end
    end
    
    def test_verify_authority
      vcr_cassette('database_api_verify_authority', record: :once) do
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
      vcr_cassette('database_api_verify_signatures', record: :once) do
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
    
    def test_version
      @api.get_hardfork_properties do |hf_properties|
        case hf_properties.current_hardfork_version
        when '0.19.0'
          assert_raises NoMethodError do
            @api.get_version
          end
        when '0.20.0'
          @api.get_version do |version|
            assert version.chain_id
          end
        else; fail("Unknown hardfork: #{hf_properties.current_hardfork_version}")
        end
      end
    end
  end
end
