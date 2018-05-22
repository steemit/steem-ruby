require 'test_helper'

module Steem
  class ApiTest < Steem::Test
    METHOD_NAMES_1_ARG = %i(get_account_votes get_block get_block_header
      get_blog_authors get_comment_discussions_by_payout
      get_conversion_requests get_discussions_by_active
      get_discussions_by_blog get_discussions_by_cashout
      get_discussions_by_children get_discussions_by_comments
      get_discussions_by_created get_discussions_by_feed
      get_discussions_by_hot get_discussions_by_promoted
      get_discussions_by_trending get_discussions_by_votes
      get_follow_count get_key_references get_open_orders
      get_owner_history get_post_discussions_by_payout
      get_potential_signatures get_recovery_request get_reward_fund
      get_savings_withdraw_from get_savings_withdraw_to get_state
      get_tags_used_by_author get_transaction_hex
      get_witness_by_account verify_authority)
    
    METHOD_NAMES_2_ARGS = %i(get_account_bandwidth get_account_reputations
      get_active_votes get_content get_content_replies get_escrow
      get_expiring_vesting_delegations get_ops_in_block
      get_reblogged_by get_required_signatures get_trending_tags
      get_withdraw_routes get_witnesses_by_vote lookup_accounts
      lookup_witness_accounts verify_account_authority)
    
    METHOD_NAMES_3_ARGS = %i(get_account_history get_blog get_blog_entries
      get_feed get_feed_entries get_market_history get_replies_by_last_update
      get_trade_history get_vesting_delegations)
    
    METHOD_NAMES_4_ARGS = %i(get_discussions_by_author_before_date get_followers
      get_following)
    
    METHOD_NAMES_UNIMPLEMENTED = %i(get_account_references)
    
    METHOD_NAMES_1_ARG_NO_ERROR = %i(get_accounts get_witnesses
      lookup_account_names)
    
    METHOD_NAMES_0_ARGS = %i(get_account_count get_active_witnesses
      get_chain_properties get_config get_current_median_history_price
      get_dynamic_global_properties get_feed_history get_hardfork_version
      get_market_history_buckets get_next_scheduled_hardfork get_order_book
      get_recent_trades get_ticker get_trade_history)
    
    # Plugins not enabled, or similar.
    SKIP_METHOD_NAMES = %i(get_transaction)
    
    ALL_METHOD_NAMES = METHOD_NAMES_1_ARG + METHOD_NAMES_2_ARGS +
      METHOD_NAMES_3_ARGS + METHOD_NAMES_4_ARGS + METHOD_NAMES_UNIMPLEMENTED +
      METHOD_NAMES_1_ARG_NO_ERROR + METHOD_NAMES_0_ARGS + SKIP_METHOD_NAMES
    
    def setup
      @api = Api.new(url: TEST_NODE)
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    end
    
    def test_api_class_name
      assert_equal 'CondenserApi', Api::api_class_name
    end
    
    def test_unknown_api_name
      assert_raises UnknownApiError, 'expect unknown api error' do
        Steem::FakeApi.new
      end
    end
    
    def test_inspect
      assert_equal "#<CondenserApi [@chain=steem, @methods=<85 elements>]>", @api.inspect
    end
    
    def test_inspect_testnet
      vcr_cassette("#{@api.class.api_name}_testnet") do
        api = Api.new(chain: :test)
        assert_equal "#<CondenserApi [@chain=test, @methods=<85 elements>]>", api.inspect
      end
    end
    
    def test_unsupported_chain
      vcr_cassette("#{@api.class.api_name}_unsupported_chain") do
        assert_raises UnsupportedChainError do
          Api.new(chain: :golos)
        end
      end
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

    def test_all_methods
      vcr_cassette("#{@api.class.api_name}_all_methods") do
        @methods.each do |key|
          case key
          when :broadcast_block then
            assert_raises BlockTooOldError, "expect void arguments to raise BlockTooOldError for: #{key}" do
              assert @api.send key, {}
            end
          when :broadcast_transaction then
            assert_raises IncorrectResponseIdError, "expect void arguments to raise IncorrectResponseIdError for: #{key}" do
              assert @api.send key, {}
            end
          when :broadcast_transaction_synchronous then
            assert_raises IncorrectResponseIdError, "expect void arguments to raise IncorrectResponseIdError for: #{key}" do
              assert @api.send key, {}
            end
          when *METHOD_NAMES_1_ARG
          then
            assert_raises Steem::ArgumentError, "expect 1 argument to raise ArgumentError for: #{key}" do
              assert @api.send key, [nil]
            end
          when *METHOD_NAMES_2_ARGS
          then
            assert_raises Steem::ArgumentError, "expect 2 arguments to raise ArgumentError for: #{key}" do
              assert @api.send key, [nil, nil]
            end
          when *METHOD_NAMES_3_ARGS
          then
            assert_raises Steem::ArgumentError, "expect 3 arguments to raise ArgumentError for: #{key}" do
              assert @api.send key, [nil, nil, nil]
            end
          when *METHOD_NAMES_4_ARGS
          then
            assert_raises Steem::ArgumentError, "expect 4 arguments to raise ArgumentError for: #{key}" do
              assert @api.send key, [nil, nil, nil, nil]
            end
          when *METHOD_NAMES_UNIMPLEMENTED then # skip
          when *METHOD_NAMES_1_ARG_NO_ERROR
          then
            assert @api.send(key, [nil]), "expect 1 argument not to raise for: ${key}"
          when *SKIP_METHOD_NAMES then # skip
          else; assert @api.send(key), "expect no arguments not to raise for: ${key}"
          end
        end
      end
    end
    
    def test_get_account_count
      vcr_cassette('condenser_api_get_account_count') do
        @api.get_account_count do |count|
          refute_nil count, 'did not expect nil count'
        end
      end
    end
    
    def test_get_content_wrong_arguments
      vcr_cassette('condenser_api_get_content_wrong_arguments') do
        assert_raises Steem::ArgumentError, 'expect argument error' do
          @api.get_content
        end
        
        assert_raises Steem::ArgumentError, 'expect argument error' do
          @api.get_content(nil)
        end
      end
    end
  end
end
