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
        
        expected_apis = {
          account_by_key_api: [
            "get_key_references"
          ],
          block_api: [
            "get_block",
            "get_block_header"
          ],
          condenser_api: [
            "broadcast_block",
            "broadcast_transaction",
            "broadcast_transaction_synchronous",
            "get_account_count",
            "get_account_history",
            "get_account_references",
            "get_account_reputations",
            "get_account_votes",
            "get_accounts",
            "get_active_votes",
            "get_active_witnesses",
            "get_block",
            "get_block_header",
            "get_blog",
            "get_blog_authors",
            "get_blog_entries",
            "get_chain_properties",
            "get_comment_discussions_by_payout",
            "get_config",
            "get_content",
            "get_content_replies",
            "get_conversion_requests",
            "get_current_median_history_price",
            "get_discussions_by_active",
            "get_discussions_by_author_before_date",
            "get_discussions_by_blog",
            "get_discussions_by_cashout",
            "get_discussions_by_children",
            "get_discussions_by_comments",
            "get_discussions_by_created",
            "get_discussions_by_feed",
            "get_discussions_by_hot",
            "get_discussions_by_promoted",
            "get_discussions_by_trending",
            "get_discussions_by_votes",
            "get_dynamic_global_properties",
            "get_escrow",
            "get_expiring_vesting_delegations",
            "get_feed",
            "get_feed_entries",
            "get_feed_history",
            "get_follow_count",
            "get_followers",
            "get_following",
            "get_hardfork_version",
            "get_key_references",
            "get_market_history",
            "get_market_history_buckets",
            "get_next_scheduled_hardfork",
            "get_open_orders",
            "get_ops_in_block",
            "get_order_book",
            "get_owner_history",
            "get_post_discussions_by_payout",
            "get_potential_signatures",
            "get_reblogged_by",
            "get_recent_trades",
            "get_recovery_request",
            "get_replies_by_last_update",
            "get_required_signatures",
            "get_reward_fund",
            "get_savings_withdraw_from",
            "get_savings_withdraw_to",
            "get_state",
            "get_tags_used_by_author",
            "get_ticker",
            "get_trade_history",
            "get_transaction",
            "get_transaction_hex",
            "get_trending_tags",
            "get_version",
            "get_vesting_delegations",
            "get_volume",
            "get_withdraw_routes",
            "get_witness_by_account",
            "get_witness_count",
            "get_witness_schedule",
            "get_witnesses",
            "get_witnesses_by_vote",
            "lookup_account_names",
            "lookup_accounts",
            "lookup_witness_accounts",
            "verify_account_authority",
            "verify_authority"
          ],
          database_api: [
            "find_account_recovery_requests",
            "find_accounts",
            "find_change_recovery_account_requests",
            "find_comments",
            "find_decline_voting_rights_requests",
            "find_escrows",
            "find_limit_orders",
            "find_owner_histories",
            "find_savings_withdrawals",
            "find_sbd_conversion_requests",
            "find_vesting_delegation_expirations",
            "find_vesting_delegations",
            "find_votes",
            "find_withdraw_vesting_routes",
            "find_witnesses",
            "get_active_witnesses",
            "get_config",
            "get_current_price_feed",
            "get_dynamic_global_properties",
            "get_feed_history",
            "get_hardfork_properties",
            "get_order_book",
            "get_potential_signatures",
            "get_required_signatures",
            "get_reward_funds",
            "get_transaction_hex",
            "get_version",
            "get_witness_schedule",
            "list_account_recovery_requests",
            "list_accounts",
            "list_change_recovery_account_requests",
            "list_comments",
            "list_decline_voting_rights_requests",
            "list_escrows",
            "list_limit_orders",
            "list_owner_histories",
            "list_savings_withdrawals",
            "list_sbd_conversion_requests",
            "list_vesting_delegation_expirations",
            "list_vesting_delegations",
            "list_votes",
            "list_withdraw_vesting_routes",
            "list_witness_votes",
            "list_witnesses",
            "verify_account_authority",
            "verify_authority",
            "verify_signatures"
          ],
          follow_api: [
            "get_account_reputations",
            "get_blog",
            "get_blog_authors",
            "get_blog_entries",
            "get_feed",
            "get_feed_entries",
            "get_follow_count",
            "get_followers",
            "get_following",
            "get_reblogged_by"
          ],
          jsonrpc: [
            "get_methods",
            "get_signature"
          ],
          market_history_api: [
            "get_market_history",
            "get_market_history_buckets",
            "get_order_book",
            "get_recent_trades",
            "get_ticker",
            "get_trade_history",
            "get_volume"
          ],
          network_broadcast_api: [
            "broadcast_block",
            "broadcast_transaction"
          ],
          rc_api: [
            "find_rc_accounts",
            "get_resource_params",
            "get_resource_pool"
          ],
          tags_api: [
            "get_active_votes",
            "get_comment_discussions_by_payout",
            "get_content_replies",
            "get_discussion",
            "get_discussions_by_active",
            "get_discussions_by_author_before_date",
            "get_discussions_by_blog",
            "get_discussions_by_cashout",
            "get_discussions_by_children",
            "get_discussions_by_comments",
            "get_discussions_by_created",
            "get_discussions_by_feed",
            "get_discussions_by_hot",
            "get_discussions_by_promoted",
            "get_discussions_by_trending",
            "get_discussions_by_votes",
            "get_post_discussions_by_payout",
            "get_replies_by_last_update",
            "get_tags_used_by_author",
            "get_trending_tags"
          ]
        }
        
        api_names = expected_apis.keys.map(&:to_s)
        unexpected_apis = (api_names + apis.keys).uniq - api_names
        missing_apis = (api_names + apis.keys).uniq - apis.keys
        assert_equal [], unexpected_apis, "found unexpected apis"
        assert_equal [], missing_apis, "missing expected apis"
        
        assert_equal expected_apis.size, apis.size, "expected #{expected_apis.size} apis, found: #{apis.size}"
        
        expected_apis.each do |api, methods|
          method_names = apis[api].map(&:to_s)
          unexpected_methods = (methods + method_names).uniq - methods
          missing_methods = (methods + method_names).uniq - method_names
          
          assert_equal [], unexpected_methods, "found unexpected methods for api: #{api}"
          assert_equal [], missing_methods, "missing expected methods for api: #{api}"
          assert_equal expected_apis[api].size, apis[api].size, "expected #{expected_apis[api].size} methods for #{api}, found: #{apis[api].size}"
        end
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
                get_block get_block_header get_escrow
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
          fail 'regression detected, SocketError or Errno::ECONNREFUSED expected'
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
