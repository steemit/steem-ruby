require 'test_helper'

module Steem
  class BroadcastTest < Steem::Test
    OPS = %i(account_create account_update account_witness_proxy
      account_witness_vote change_recovery_account comment convert custom
      custom_binary custom_json delete_comment escrow_dispute escrow_transfer
      feed_publish limit_order_cancel limit_order_create new recover_account
      request_account_recovery set_withdraw_vesting_route transfer
      transfer_to_vesting vote withdraw_vesting witness_update)
    
    def setup
      @api = Steem::NetworkBroadcastApi.new
      @jsonrpc = Jsonrpc.new
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
      
      @account_name = 'social'
      @wif = '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC'
      @pretend = true
    end
    
    def test_vote
      options = {
        wif: @wif,
        params: {
          voter: @account_name,
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_vote') do
        Steem::Broadcast.vote(options) do |result|
          assert result.valid
        end
      end
    end
    
    def test_vote_wrong_permlink
      options = {
        wif: @wif,
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
          Steem::Broadcast.vote(options)
        end
      end
    end
    
    def test_vote_wrong_author_permlink
      options = {
        wif: @wif,
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
          Steem::Broadcast.vote(options)
        end
      end
    end
    
    def test_vote_wrong_weight
      options = {
        wif: @wif,
        params: {
          voter: @account_name,
          author: 'steemit',
          permlink: 'firstpost',
          weight: 'WRONG'
        },
        pretend: false
      }
      
      vcr_cassette('broadcast_vote') do
        assert_raises ArgumentError do
          Steem::Broadcast.vote(options)
        end
      end
    end
    
    def test_vote_no_closure
      options = {
        wif: @wif,
        params: {
          voter: @account_name,
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_vote_no_closure') do
        assert Steem::Broadcast.vote(options).valid
      end
    end
    
    def test_comment
      options = {
        wif: @wif,
        params: {
          author: @account_name,
          permlink: 'permlink',
          parent_permlink: 'parent_permlink',
          title: 'title',
          body: 'body'
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_comment') do
        Steem::Broadcast.comment(options) do |result|
          assert result.valid
        end
      end
    end
    
    # def test_comment_long_title
    #   options = {
    #     wif: @wif,
    #     params: {
    #       author: @account_name,
    #       permlink: 'permlink',
    #       parent_permlink: 'parent_permlink',
    #       title: 'X' * 256,
    #       body: 'body'
    #     },
    #     pretend: @pretend
    #   }
    # 
    #   vcr_cassette('broadcast_comment_long_title') do
    #     Steem::Broadcast.comment(options) do |result|
    #       assert result.valid
    #     end
    #   end
    # end
    
    def test_comment_with_options
      options = {
        wif: @wif,
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
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_comment_with_options') do
        assert_raises MissingPostingAuthorityError do
          Steem::Broadcast.comment(options)
        end
      end
    end
    
    def test_delete_comment
      options = {
        wif: @wif,
        params: {
          author: @account_name,
          permlink: 'test'
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_delete_comment') do
        Steem::Broadcast.delete_comment(options) do |result|
          assert result.valid
        end
      end
    end
    
    def test_transfer
      options = {
        wif: @wif,
        params: {
          from: @account_name,
          to: 'alice',
          amount: '0.000 STEEM',
          memo: 'memo'
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_transfer') do
        assert_raises MissingActiveAuthorityError, 'expect to raise missing active authority' do
          Steem::Broadcast.transfer(options)
        end
      end
    end
    
    def test_transfer_to_vesting
      options = {
        wif: @wif,
        params: {
          from: @account_name,
          to: 'null',
          amount: '0.000 STEEM'
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_transfer_to_vesting') do
        assert_raises MissingActiveAuthorityError, 'expect to raise missing active authority' do
          Steem::Broadcast.transfer_to_vesting(options.dup)
        end
      end
    end
    
    def test_withdraw_vesting
      options = {
        wif: @wif,
        params: {
          account: @account_name,
          vesting_shares: '0.000 VESTS'
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_withdraw_vesting') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.withdraw_vesting(options)
        end
      end
    end
    
    def test_limit_order_create
      options = {
        wif: @wif,
        params: {
          owner: @account_name,
          orderid: '1234',
          amount_to_sell: '0.000 STEEM',
          min_to_receive: '0.000 SBD',
          fill_or_kill: false,
          expiration: (Time.now.utc + 300)
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_limit_order_create') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.limit_order_create(options)
        end
      end
    end
    
    def test_limit_order_cancel
      options = {
        wif: @wif,
        params: {
          owner: @account_name,
          orderid: '1234'
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_limit_order_cancel') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.limit_order_cancel(options)
        end
      end
    end
    
    def test_feed_publish
      options = {
        wif: @wif,
        params: {
          publisher: @account_name,
          exchange_rate: {
            base: '0.000 SBD',
            quote: '0.000 STEEM',
          }
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_feed_publish') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.feed_publish(options)
        end
      end
    end
    
    def test_convert
      options = {
        wif: @wif,
        params: {
          owner: @account_name,
          requestid: '1234',
          amount: '0.000 SBD'
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_convert') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.convert(options)
        end
      end
    end
    
    def test_account_create
      options = {
        wif: @wif,
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
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_account_create') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.account_create(options)
        end
      end
    end
    
    def test_account_update
      options = {
        wif: @wif,
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
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_account_update') do
        assert_raises MissingOwnerAuthorityError do
          Steem::Broadcast.account_update(options)
        end
      end
    end
    
    def test_account_update_active
      options = {
        wif: @wif,
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
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_account_update_active') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.account_update(options)
        end
      end
    end
    
    def test_account_update_posting
      options = {
        wif: @wif,
        params: {
          account: @account_name,
          posting: {
            weight_threshold: 1,
            account_auths: [],
            key_auths: [['STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', 1]],
          },
          memo_key: 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG',
          json_metadata: '{}'
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_account_update_posting') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.account_update(options)
        end
      end
    end
    
    def test_account_update_memo
      options = {
        wif: @wif,
        params: {
          account: @account_name,
          memo_key: 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG',
          json_metadata: '{}'
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_account_update_memo') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.account_update(options)
        end
      end
    end
    
    def test_account_update_empty
      options = {
        wif: @wif,
        params: {
          account: @account_name
        },
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_account_update_empty') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.account_update(options)
        end
      end
    end
    
    def test_witness_update
      options = {
        wif: @wif,
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
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_witness_update') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.witness_update(options)
        end
      end
    end
    
    def test_account_witness_vote
      options = {
        wif: @wif,
        params: {
          account: @account_name,
          witness: 'alice',
          approve: true
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_account_witness_vote') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.account_witness_vote(options)
        end
      end
    end
    
    def test_account_witness_proxy
      options = {
        wif: @wif,
        params: {
          account: @account_name,
          proxy: 'alice'
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_account_witness_proxy') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.account_witness_proxy(options)
        end
      end
    end
    
    def test_custom
      options = {
        wif: @wif,
        params: {
          required_auths: [@account_name],
          id: 777,
          data: '0a627974656d617374657207737465656d697402a3d13897d82114466ad87a74b73a53292d8331d1bd1d3082da6bfbcff19ed097029db013797711c88cccca3692407f9ff9b9ce7221aaa2d797f1692be2215d0a5f6d2a8cab6832050078bc5729201e3ea24ea9f7873e6dbdc65a6bd9899053b9acda876dc69f11a13df9ca8b26b6'
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_custom') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.custom(options)
        end
      end
    end
    
    def test_custom_binary
      options = {
        wif: @wif,
        params: {
          id: 777,
          data: '0a627974656d617374657207737465656d697402a3d13897d82114466ad87a74b73a53292d8331d1bd1d3082da6bfbcff19ed097029db013797711c88cccca3692407f9ff9b9ce7221aaa2d797f1692be2215d0a5f6d2a8cab6832050078bc5729201e3ea24ea9f7873e6dbdc65a6bd9899053b9acda876dc69f11a13df9ca8b26b6'
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_custom_binary') do
        assert_raises IrrelevantSignatureError do
          Steem::Broadcast.custom_binary(options)
        end
      end
    end
    
    def test_custom_json
      options = {
        wif: @wif,
        params: {
          required_auths: [],
          required_posting_auths: [@account_name],
          id: 'follow',
          json: '["follow",{"follower":"steemit","following":"alice","what":["blog"]}]'
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_custom_json') do
        Steem::Broadcast.custom_json(options) do |result|
          assert result.valid
        end
      end
    end
    
    def test_set_withdraw_vesting_route
      options = {
        wif: @wif,
        params: {
          from_account: @account_name,
          to_account: 'alice',
          percent: 1,
          auto_vest: true
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_set_withdraw_vesting_route') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.set_withdraw_vesting_route(options)
        end
      end
    end
    
    def test_request_account_recovery
      options = {
        wif: @wif,
        params: {
          recovery_account: @account_name,
          account_to_recover: 'alice',
          new_owner_authority: {
            weight_threshold: 1,
            account_auths: [],
            key_auths:[["STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG",1]]
          },
          extensions: []
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_request_account_recovery') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.request_account_recovery(options)
        end
      end
    end
    
    def test_recover_account
      options = {
        wif: @wif,
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
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_recover_account') do
        assert_raises MissingOtherAuthorityError do
          Steem::Broadcast.recover_account(options)
        end
      end
    end
    
    def test_change_recovery_account
      options = {
        wif: @wif,
        params: {
          account_to_recover: @account_name,
          new_recovery_account: '',
          extensions: []
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_change_recovery_account') do
        assert_raises MissingOwnerAuthorityError do
          Steem::Broadcast.change_recovery_account(options)
        end
      end
    end
    
    def test_escrow_transfer
      options = {
        wif: @wif,
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
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_escrow_transfer') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.escrow_transfer(options)
        end
      end
    end
    
    def test_escrow_dispute
      options = {
        wif: @wif,
        params: {
          from: @account_name,
          to: 'alice',
          agent: 'bob',
          who: 'alice',
          escrow_id: '1234'
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_escrow_dispute') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.escrow_dispute(options)
        end
      end
    end
    
    def test_escrow_release
      options = {
        wif: @wif,
        params: {
          from: @account_name,
          to: 'alice',
          agent: 'bob',
          who: 'alice',
          receiver: 'alice',
          escrow_id: '1234',
          sbd_amount: '0.000 SBD',
          steem_amount: '0.000 STEEM'
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_escrow_release') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.escrow_release(options)
        end
      end
    end
    
    def test_escrow_approve
      options = {
        wif: @wif,
        params: {
          from: @account_name,
          to: 'alice',
          agent: 'bob',
          who: 'alice',
          escrow_id: '1234',
          approve: true
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_escrow_approve') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.escrow_approve(options)
        end
      end
    end
    
    def test_transfer_to_savings
      options = {
        wif: @wif,
        params: {
          from: @account_name,
          to: 'alice',
          amount: '0.000 SBD',
          memo: 'memo'
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_transfer_to_savings') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.transfer_to_savings(options)
        end
      end
    end
    
    def test_transfer_from_savings
      options = {
        wif: @wif,
        params: {
          YYY: @account_name,
          from: 'alice',
          request_id: '1234',
          to: 'bob',
          amount: '0.000 SBD',
          memo: 'memo'
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_transfer_from_savings') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.transfer_from_savings(options)
        end
      end
    end
    
    def test_cancel_transfer_from_savings
      options = {
        wif: @wif,
        params: {
          from: @account_name,
          request_id: '1234'
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_cancel_transfer_from_savings') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.cancel_transfer_from_savings(options)
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
          Steem::Broadcast.decline_voting_rights(options)
        end
      end
    end
    
    def test_delegate_vesting_shares
      options = {
        wif: @wif,
        params: {
          delegator: @account_name,
          delegatee: 'alice',
          vesting_shares: '0.000 VESTS'
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_delegate_vesting_shares') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.delegate_vesting_shares(options)
        end
      end
    end
    
    def test_account_create_with_delegation
      options = {
        wif: @wif,
        params: {
          fee: '0.000 STEEM',
          delegation: '0.000 VESTS',
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
        },
        pretend: @pretend
      }
    
      vcr_cassette('broadcast_account_create_with_delegation') do
        assert_raises MissingActiveAuthorityError do
          Steem::Broadcast.account_create_with_delegation(options)
        end
      end
    end
    
    def test_fake_op
      options = {
        wif: @wif,
        ops: [[:bogus, {}]],
        pretend: @pretend
      }
      
      vcr_cassette('broadcast_fake_op') do
        assert_raises UnknownOperationError do
          Steem::Broadcast.process(options)
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
      
      options = {
        wif: @wif,
        pretend: true # always pretend
      }
      
      random_op = OPS.sample
      options[:params] = fields.map do |field|
        value = [
          field.to_s, 0, Time.now.utc, true, false, [1], {a: :b}, nil,
          ["0", 3, "@@000000021"]
        ].sample
        
        [field, value]
      end.to_h
      
      vcr_cassette('broadcast_random_op') do
        begin
          Steem::Broadcast.send(random_op, options) do |result|
            # :nocov:
            assert result.valid
            # :nocov:
          end
        rescue => e
          if e.class == UnknownError || e.class.superclass != BaseError
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
      assert Steem::Broadcast.send(:backoff)
    end
    
    def test_can_retry
      e = NonCanonicalSignatureError.new("test")
      assert Steem::Broadcast.send(:can_retry?, e)
    end
    
    def test_can_retry_remote_node_error
      e = IncorrectResponseIdError.new("test: The json-rpc id did not match")
      assert Steem::Broadcast.send(:can_retry?, e)
    end
  end
end