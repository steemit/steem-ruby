require 'test_helper'

module Steem
  class BroadcastTest < Steem::Test
    OPS = %i(account_create account_update account_witness_proxy
      account_witness_vote change_recovery_account comment convert custom
      custom_binary custom_json delete_comment escrow_dispute escrow_transfer
      feed_publish limit_order_cancel limit_order_create recover_account
      request_account_recovery set_withdraw_vesting_route transfer
      transfer_to_vesting vote withdraw_vesting witness_update)
    
    def setup
      app_base = false # TODO: Randomly set true or false to test differences.
      
      if app_base
        @database_api = Steem::DatabaseApi.new(url: TEST_NODE)
        @block_api = Steem::BlockApi.new(url: TEST_NODE)
        @network_broadcast_api = Steem::NetworkBroadcastApi.new(url: TEST_NODE)
      else
        @database_api = @block_api = @network_broadcast_api = Steem::CondenserApi.new(url: TEST_NODE)
      end
      
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      @account_name = ENV.fetch('TEST_ACCOUNT_NAME', 'social')
      @wif = ENV.fetch('TEST_WIF', '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC')
      @pretend = true
      
      @broadcast_options = {
        app_base: app_base,
        database_api: @database_api,
        block_api: @block_api,
        network_broadcast_api: @network_broadcast_api,
        wif: @wif,
        pretend: @pretend
      }
      
      fail 'Are you nuts?' if OPS.include? :decline_voting_rights
    end
    
    def test_vote
      options = {
        params: {
          voter: @account_name,
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        }
      }
      
      vcr_cassette('broadcast_vote') do
        Broadcast.vote(@broadcast_options.merge(options)) do |result|
          if result.respond_to? :valid
            assert result.valid
          else
            assert result
          end
        end
      end
    end
    
    # Originally tested this without setting `pretend: true` and got this, so
    # we know it works:
    # https://steemd.com/tx/1ab30d6fef305121ee82e53b04605a641a79459d
    def test_vote_multisig
      options = {
        wif: [
          '5K2LA2ucS8b1GuFvVgZK6itKNE6fFMbDMX4GDtNHiczJESLGRd8',
          '5JRaypasxMx1L97ZUX7YuC5Psb5EAbF821kkAGtBj7xCJFQcbLg'
        ],
        params: {
          voter: 'sisilafamille',
          author: 'siol',
          permlink: 'test',
          weight: 1000
        }
      }
      
      vcr_cassette('broadcast_vote_multisig') do
        Broadcast.vote(@broadcast_options.merge(options)) do |result|
          if result.respond_to? :valid
            assert result.valid
          else
            assert result
          end
        end
      end
    end
    
    def test_vote_wrong_permlink
      options = {
        params: {
          voter: @account_name,
          author: 'steemit',
          permlink: 'WRONG',
          weight: 10000
        },
        pretend: false
      }
      
      vcr_cassette('broadcast_vote') do
        assert_raises ArgumentError do
          Broadcast.vote(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_vote_wrong_author_permlink
      options = {
        params: {
          voter: @account_name,
          author: 'WRONG',
          permlink: 'WRONG',
          weight: 10000
        },
        pretend: false
      }
      
      vcr_cassette('broadcast_vote') do
        assert_raises InvalidAccountError do
          Broadcast.vote(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_vote_wrong_weight
      options = {
        params: {
          voter: @account_name,
          author: 'steemit',
          permlink: 'firstpost',
          weight: 'WRONG'
        }
      }
      
      vcr_cassette('broadcast_vote') do
        assert_raises ArgumentError do
          Broadcast.vote(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_vote_no_closure
      options = {
        params: {
          voter: @account_name,
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        }
      }
      
      vcr_cassette('broadcast_vote_no_closure') do
        result = Broadcast.vote(@broadcast_options.merge(options))
        if result.respond_to? :valid
          assert result.valid
        else
          assert result
        end
      end
    end
    
    def test_comment
      options = {
        params: {
          author: @account_name,
          permlink: 'permlink',
          parent_permlink: 'parent_permlink',
          title: 'title',
          body: 'body'
        }
      }
      
      vcr_cassette('broadcast_comment') do
        Broadcast.comment(@broadcast_options.merge(options)) do |result|
          if result.respond_to? :valid
            assert result.valid
          else
            assert result
          end
        end
      end
    end
    
    def test_comment_with_author_vote_weight
      options = {
        params: {
          author: @account_name,
          permlink: 'permlink',
          parent_permlink: 'parent_permlink',
          title: 'title',
          body: 'body',
          author_vote_weight: 10000
        }
      }
      
      vcr_cassette('broadcast_comment_with_author_vote_weight') do
        Broadcast.comment(@broadcast_options.merge(options)) do |result|
          if result.respond_to? :valid
            assert result.valid
          else
            assert result
          end
        end
      end
    end
    
    def test_comment_one_metadata
      options = {
        params: {
          author: @account_name,
          permlink: 'permlink',
          parent_permlink: 'parent_permlink',
          title: 'title',
          body: 'body',
          metadata: {tags: [:tag]}
        }
      }
      
      vcr_cassette('broadcast_comment') do
        Broadcast.comment(@broadcast_options.merge(options)) do |result|
          if result.respond_to? :valid
            assert result.valid
          else
            assert result
          end
        end
      end
    end
    
    def test_comment_both_metadata
      options = {
        params: {
          author: @account_name,
          permlink: 'permlink',
          parent_permlink: 'parent_permlink',
          title: 'title',
          body: 'body',
          metadata: {tags: [:tag]},
          json_metadata: '{"tags":["tag"]}'
        }
      }
      
      assert_raises Steem::ArgumentError do
        Broadcast.comment(@broadcast_options.merge(options))
      end
    end
    
    # def test_comment_long_title
    #   options = {
    #     params: {
    #       author: @account_name,
    #       permlink: 'permlink',
    #       parent_permlink: 'parent_permlink',
    #       title: 'X' * 256,
    #       body: 'body'
    #     }
    #   }
    # 
    #   vcr_cassette('broadcast_comment_long_title') do
    #     Broadcast.comment(@broadcast_options.merge(options)) do |result|
    #       assert result.valid
    #     end
    #   end
    # end
    
    def test_comment_with_options
      options = {
        params: {
          author: @account_name,
          permlink: 'permlink',
          parent_permlink: 'parent_permlink',
          title: 'title',
          body: 'body',
          max_accepted_payout: '0.000 SBD',
          allow_votes: false,
          allow_curation_rewards: false,
          beneficiaries: [
            {'alice': 1000},
            {'bob': 1000}
          ]
        }
      }
      
      vcr_cassette('broadcast_comment_with_options') do
        assert_raises MissingPostingAuthorityError do
          Broadcast.comment(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_delete_comment
      options = {
        params: {
          author: @account_name,
          permlink: 'test'
        }
      }
      
      vcr_cassette('broadcast_delete_comment') do
        Broadcast.delete_comment(@broadcast_options.merge(options)) do |result|
          if result.respond_to? :valid
            assert result.valid
          else
            assert result
          end
        end
      end
    end
    
    def test_transfer
      options = {
        params: {
          from: @account_name,
          to: 'alice',
          amount: '0.000 STEEM',
          memo: 'memo'
        }
      }
      
      vcr_cassette('broadcast_transfer') do
        assert_raises MissingActiveAuthorityError, 'expect to raise missing active authority' do
          Broadcast.transfer(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_transfer_to_vesting
      options = {
        params: {
          from: @account_name,
          to: 'null',
          amount: '0.000 STEEM'
        }
      }
      
      vcr_cassette('broadcast_transfer_to_vesting') do
        assert_raises MissingActiveAuthorityError, 'expect to raise missing active authority' do
          Broadcast.transfer_to_vesting(@broadcast_options.merge(options).dup)
        end
      end
    end
    
    def test_withdraw_vesting
      options = {
        params: {
          account: @account_name,
          vesting_shares: '0.000000 VESTS'
        }
      }
      
      vcr_cassette('broadcast_withdraw_vesting') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.withdraw_vesting(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_limit_order_create
      options = {
        params: {
          owner: @account_name,
          orderid: '1234',
          amount_to_sell: '0.000 STEEM',
          min_to_receive: '0.000 SBD',
          fill_or_kill: false,
          expiration: (Time.now.utc + 300)
        }
      }
    
      vcr_cassette('broadcast_limit_order_create') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.limit_order_create(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_limit_order_cancel
      options = {
        params: {
          owner: @account_name,
          orderid: '1234'
        }
      }
    
      vcr_cassette('broadcast_limit_order_cancel') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.limit_order_cancel(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_feed_publish
      options = {
        params: {
          publisher: @account_name,
          exchange_rate: {
            base: '0.000 SBD',
            quote: '0.000 STEEM',
          }
        }
      }
    
      vcr_cassette('broadcast_feed_publish') do
        assert_raises Steem::ArgumentError do
          Broadcast.feed_publish(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_convert
      options = {
        params: {
          owner: @account_name,
          requestid: '1234',
          amount: '0.000 SBD'
        }
      }
    
      vcr_cassette('broadcast_convert') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.convert(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_account_create
      options = {
        params: {
          fee: '0.000 STEEM',
          creator: @account_name,
          new_account_name: 'alice',
          owner: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          active: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          posting: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          memo_key: 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG',
          json_metadata: '{}'
        }
      }
      
      vcr_cassette('broadcast_account_create') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.account_create(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_account_create_both_metadata
      options = {
        params: {
          metadata: {},
          json_metadata: '{}'
        }
      }
      
      assert_raises Steem::ArgumentError do
        Broadcast.account_create(@broadcast_options.merge(options))
      end
    end
    
    def test_account_update
      options = {
        params: {
          account: @account_name,
          owner: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          active: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          posting: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          memo_key: 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG',
          json_metadata: '{}'
        }
      }
      
      vcr_cassette('broadcast_account_update') do
        assert_raises MissingOwnerAuthorityError do
          Broadcast.account_update(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_account_update_both_metadata
      options = {
        params: {
          metadata: {},
          json_metadata: '{}'
        }
      }
      
      assert_raises Steem::ArgumentError do
        Broadcast.account_update(@broadcast_options.merge(options))
      end
    end
    
    def test_account_update_active
      options = {
        params: {
          account: @account_name,
          active: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          posting: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          memo_key: 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG',
          json_metadata: '{}'
        }
      }
      
      vcr_cassette('broadcast_account_update_active') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.account_update(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_account_update_posting
      options = {
        params: {
          account: @account_name,
          posting: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          memo_key: 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG',
          json_metadata: '{}'
        }
      }
      
      vcr_cassette('broadcast_account_update_posting') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.account_update(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_account_update_memo
      options = {
        params: {
          account: @account_name,
          memo_key: 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG',
          json_metadata: '{}'
        }
      }
      
      vcr_cassette('broadcast_account_update_memo') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.account_update(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_account_update_empty
      options = {
        params: {
          account: @account_name
        }
      }
      
      vcr_cassette('broadcast_account_update_empty') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.account_update(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_witness_update
      options = {
        params: {
          owner: @account_name,
          url: '',
          block_signing_key: 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG',
          props: {
            account_creation_fee: '0.000 STEEM',
            maximum_block_size: 131072,
            sbd_interest_rate:1000
          },
          fee: '0.000 STEEM'
        }
      }
    
      vcr_cassette('broadcast_witness_update') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.witness_update(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_account_witness_vote
      options = {
        params: {
          account: @account_name,
          witness: 'alice',
          approve: true
        }
      }
    
      vcr_cassette('broadcast_account_witness_vote') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.account_witness_vote(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_account_witness_proxy
      options = {
        params: {
          account: @account_name,
          proxy: 'alice'
        }
      }
    
      vcr_cassette('broadcast_account_witness_proxy') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.account_witness_proxy(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_custom
      options = {
        params: {
          required_auths: [@account_name],
          id: 777,
          data: '0a627974656d617374657207737465656d697402a3d13897d82114466ad87a74b73a53292d8331d1bd1d3082da6bfbcff19ed097029db013797711c88cccca3692407f9ff9b9ce7221aaa2d797f1692be2215d0a5f6d2a8cab6832050078bc5729201e3ea24ea9f7873e6dbdc65a6bd9899053b9acda876dc69f11a13df9ca8b26b6'
        }
      }
    
      vcr_cassette('broadcast_custom') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.custom(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_custom_binary
      options = {
        params: {
          id: 777,
          data: '0a627974656d617374657207737465656d697402a3d13897d82114466ad87a74b73a53292d8331d1bd1d3082da6bfbcff19ed097029db013797711c88cccca3692407f9ff9b9ce7221aaa2d797f1692be2215d0a5f6d2a8cab6832050078bc5729201e3ea24ea9f7873e6dbdc65a6bd9899053b9acda876dc69f11a13df9ca8b26b6'
        }
      }
    
      vcr_cassette('broadcast_custom_binary') do
        assert_raises IrrelevantSignatureError do
          Broadcast.custom_binary(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_custom_json
      options = {
        params: {
          required_auths: [],
          required_posting_auths: [@account_name],
          id: 'follow',
          json: '["follow",{"follower":"steemit","following":"alice","what":["blog"]}]'
        }
      }
    
      vcr_cassette('broadcast_custom_json') do
        Broadcast.custom_json(@broadcast_options.merge(options)) do |result|
          if result.respond_to? :valid
            assert result.valid
          else
            assert result
          end
        end
      end
    end
    
    def test_custom_json_both_data
      options = {
        params: {
          required_auths: [],
          required_posting_auths: [@account_name],
          id: 'follow',
          data: ["follow",{"follower":"steemit","following":"alice","what":["blog"]}],
          json: '["follow",{"follower":"steemit","following":"alice","what":["blog"]}]'
        }
      }
      
      assert_raises Steem::ArgumentError do
        Broadcast.custom_json(@broadcast_options.merge(options))
      end
    end
    
    def test_set_withdraw_vesting_route
      options = {
        params: {
          from_account: @account_name,
          to_account: 'alice',
          percent: 1,
          auto_vest: true
        }
      }
    
      vcr_cassette('broadcast_set_withdraw_vesting_route') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.set_withdraw_vesting_route(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_request_account_recovery
      options = {
        params: {
          recovery_account: @account_name,
          account_to_recover: 'alice',
          new_owner_authority: {
            weight_threshold: 1,
            account_auths: [],
            key_auths:[["STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG",1]]
          },
          extensions: []
        }
      }
    
      vcr_cassette('broadcast_request_account_recovery') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.request_account_recovery(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_recover_account
      options = {
        params: {
          account_to_recover: 'alice',
          new_owner_authority: {
            weight_threshold: 1,
            account_auths: [],
            key_auths:[["STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG",1]]
          },
          recent_owner_authority: {
            weight_threshold: 1,
            account_auths: [],
            key_auths:[["STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG",1]]
          },
          extensions: []
        }
      }
    
      vcr_cassette('broadcast_recover_account') do
        assert_raises MissingOtherAuthorityError do
          Broadcast.recover_account(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_change_recovery_account
      options = {
        params: {
          account_to_recover: @account_name,
          new_recovery_account: '',
          extensions: []
        }
      }
    
      vcr_cassette('broadcast_change_recovery_account') do
        assert_raises MissingOwnerAuthorityError do
          Broadcast.change_recovery_account(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_escrow_transfer
      options = {
        params: {
          from: @account_name,
          to: 'alice',
          agent: 'bob',
          escrow_id: '1234',
          sbd_amount: '0.000 SBD',
          steem_amount: '0.000 STEEM',
          fee: '0.000 STEEM',
          ratification_deadline: (Time.now.utc + 300),
          escrow_expiration: (Time.now.utc + 3000),
          json_meta: '{}'
        }
      }
    
      vcr_cassette('broadcast_escrow_transfer') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.escrow_transfer(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_escrow_transfer_both_meta
      options = {
        params: {
          from: @account_name,
          meta: {},
          json_meta: '{}'
        }
      }
    
      assert_raises Steem::ArgumentError do
        Broadcast.escrow_transfer(@broadcast_options.merge(options))
      end
    end
    
    def test_escrow_dispute
      options = {
        params: {
          from: @account_name,
          to: 'alice',
          agent: 'bob',
          who: 'alice',
          escrow_id: '1234'
        }
      }
    
      vcr_cassette('broadcast_escrow_dispute') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.escrow_dispute(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_escrow_release
      options = {
        params: {
          from: @account_name,
          to: 'alice',
          agent: 'bob',
          who: 'alice',
          receiver: 'alice',
          escrow_id: '1234',
          sbd_amount: '0.000 SBD',
          steem_amount: '0.000 STEEM'
        }
      }
    
      vcr_cassette('broadcast_escrow_release') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.escrow_release(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_escrow_approve
      options = {
        params: {
          from: @account_name,
          to: 'alice',
          agent: 'bob',
          who: 'alice',
          escrow_id: '1234',
          approve: true
        }
      }
    
      vcr_cassette('broadcast_escrow_approve') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.escrow_approve(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_transfer_to_savings
      options = {
        params: {
          from: @account_name,
          to: 'alice',
          amount: '0.000 SBD',
          memo: 'memo'
        }
      }
    
      vcr_cassette('broadcast_transfer_to_savings') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.transfer_to_savings(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_transfer_from_savings
      options = {
        params: {
          YYY: @account_name,
          from: 'alice',
          request_id: '1234',
          to: 'bob',
          amount: '0.000 SBD',
          memo: 'memo'
        }
      }
    
      vcr_cassette('broadcast_transfer_from_savings') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.transfer_from_savings(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_cancel_transfer_from_savings
      options = {
        params: {
          from: @account_name,
          request_id: '1234'
        }
      }
    
      vcr_cassette('broadcast_cancel_transfer_from_savings') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.cancel_transfer_from_savings(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_decline_voting_rights
      options = {
        wif: @wif,
        params: {
          account: @account_name,
          decline: true
        },
        pretend: false # NEVER broadcast this
      }
    
      vcr_cassette('broadcast_decline_voting_rights') do
        assert_raises MissingOwnerAuthorityError do
          Broadcast.decline_voting_rights(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_delegate_vesting_shares
      options = {
        params: {
          delegator: @account_name,
          delegatee: 'alice',
          vesting_shares: '0.000000 VESTS'
        }
      }
    
      vcr_cassette('broadcast_delegate_vesting_shares') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.delegate_vesting_shares(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_account_create_with_delegation
      options = {
        params: {
          fee: '0.000 STEEM',
          delegation: '0.000000 VESTS',
          creator: @account_name,
          new_account_name: 'alice',
          owner: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          active: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          posting: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          memo_key: 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG',
          json_metadata: '{}',
          extensions: []
        }
      }
    
      vcr_cassette('broadcast_account_create_with_delegation') do
        assert_raises MissingActiveAuthorityError do
          Broadcast.account_create_with_delegation(@broadcast_options.merge(options))
        end
      end
    end
    
    def test_account_create_with_delegation_both_metadata
      options = {
        params: {
          metadata: {},
          json_metadata: '{}'
        }
      }
    
      assert_raises Steem::ArgumentError do
        Broadcast.account_create_with_delegation(@broadcast_options.merge(options))
      end
    end
    
    def test_fake_op
      options = {
        ops: [[:bogus, {}]]
      }
      
      vcr_cassette('broadcast_fake_op') do
        assert_raises UnknownOperationError do
          Steem::Broadcast.process(@broadcast_options.merge(options))
        end
      end
    end
    
    # This test picks a random op to try.
    def test_random_op
      fields = %i(account account_to_recover active agent allow_curation_rewards
        allow_votes amount amount_to_sell approve author auto_vest beneficiaries
        block_signing_key body creator data escrow_expiration escrow_id
        exchange_rate expiration extensions fee fill_or_kill from from_account
        id json json_meta json_metadata max_accepted_payout memo memo_key
        min_to_receive new_account_name new_owner_authority new_recovery_account
        orderid owner parent_permlink percent permlink posting props proxy
        publisher ratification_deadline recent_owner_authority recovery_account
        requestid required_auths required_posting_auths sbd_amount steem_amount
        title to to_account url vesting_shares voter weight who witness)
      
      options = {}
      
      random_op = OPS.sample
      options[:params] = fields.map do |field|
        value = [
          field.to_s, 0, Time.now.utc, true, false, [1], {a: :b}, nil,
          {amount: '0', precision: 3, nai: '@@000000021'}
        ].sample
        
        [field, value]
      end.to_h
      
      vcr_cassette('broadcast_random_op') do
        begin
          Broadcast.send(random_op, @broadcast_options.merge(options)) do |result|
            # :nocov:
            if result.respond_to? :valid
              assert result.valid
            else
              assert result
            end
            # :nocov:
          end
        rescue => e
          if e.class == UnknownError || !e.class.ancestors.include?(BaseError)
            # :nocov:
            puts "Random op: #{random_op}"
            fail "Need to handle error: #{e} - #{e.backtrace.join("\n")}"
            # :nocov:
          end
          
          assert true # success
        end
      end
    end
    
    def test_backoff
      assert Broadcast.send(:backoff)
    end
    
    def test_can_retry
      e = NonCanonicalSignatureError.new("test")
      
      refute_nil Broadcast.send(:first_retry_at)
      assert Broadcast.send(:can_retry?, e) unless Broadcast.send :retry_reset?
    end
    
    def test_can_retry_remote_node_error
      e = IncorrectResponseIdError.new("test: The json-rpc id did not match")
      
      refute_nil Broadcast.send(:first_retry_at)
      assert Broadcast.send(:can_retry?, e) unless Broadcast.send :retry_reset?
    end
  end
end