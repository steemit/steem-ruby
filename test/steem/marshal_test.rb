require 'test_helper'

module Steem
  class MarshalTest < Steem::Test
    include Utils
    def setup
      @database_api = Steem::DatabaseApi.new
    end
    
    def test_trx_example_1
      # block: 2997469, trx_id: 677040fdb081c1e67928ccc1320b51e57df1b86a
      
      trx = {
        "ref_block_num": 48262,
        "ref_block_prefix": 4209344763,
        "expiration": "2016-07-07T19:18:15",
        "operations": [
          {
            "type": "limit_order_create_operation",
            "value": {
              "owner": "gavvet",
              "orderid": 1467919074,
              "amount_to_sell": {"amount": "19477", "precision": 3, "nai": "@@000000013"},
              "min_to_receive": {"amount": "67164", "precision": 3, "nai": "@@000000021"},
              "fill_or_kill": false,
              "expiration": "1969-12-31T23:59:59"
            }
          }
        ]
      }
      
      hex = @database_api.get_transaction_hex(trx: trx) do |result|
        result.hex
      end

      marshal = Marshal.new(hex: hex)
      
      assert_equal 48262, marshal.uint16, 'expect ref_block_num: 48262'
      assert_equal 4209344763, marshal.uint32, 'expect ref_block_prefix: 4209344763'
      assert_equal Time.parse('2016-07-07T19:18:15Z'), marshal.point_in_time, 'expect expiration: 2016-07-07T19:18:15Z'
      
      assert_equal 1, marshal.signed_char, 'expect operations: 1'

      assert_equal :limit_order_create_operation, marshal.operation_type, 'expect operation type: limit_order_create_operation'
      assert_equal 'gavvet', marshal.string, 'expect owner: gavvet'
      assert_equal 1467919074, marshal.uint32, 'expect order_id: 1467919074'
      assert_equal Type::Amount.new('19.477 SBD').to_s, marshal.amount.to_s, 'expect amount_to_sell: 19.477 SBD'
      assert_equal Type::Amount.new('67.164 STEEM').to_s, marshal.amount.to_s, 'expect min_to_receive: 67.164 STEEM'
      assert_equal false, marshal.boolean, 'expect fill_or_kill: false'
      assert_equal Time.parse('1969-12-31T23:59:59Z'), marshal.point_in_time, 'expect expiration: 1969-12-31T23:59:59Z'
    end
    
    def test_trx_example_2
      # block: 20000000, trx_id: 8ae2c3e1561462b2c7ed4c9128058e53ba9ca54f
      
      trx = {
        "ref_block_num": 11501,
        "ref_block_prefix": 655107659,
        "expiration": "2018-02-19T07:26:45",
        "operations": [
          {
            "type": "claim_reward_balance_operation",
            "value": {
              "account": "teacherpearline",
              "reward_steem": {"amount": "0", "precision": 3, "nai": "@@000000021"},
              "reward_sbd": {"amount": "845", "precision": 3, "nai": "@@000000013"},
              "reward_vests": {"amount": "404731593", "precision": 6, "nai": "@@000000037"}
            }
          }
        ]
      }
      
      hex = @database_api.get_transaction_hex(trx: trx) do |result|
        result.hex
      end

      marshal = Marshal.new(hex: hex)
      
      assert_equal 11501, marshal.uint16, 'expect ref_block_num: 11501'
      assert_equal 655107659, marshal.uint32, 'expect ref_block_prefix: 655107659'
      assert_equal Time.parse('2018-02-19T07:26:45Z'), marshal.point_in_time, 'expect expiration: 2018-02-19T07:26:45Z'
      
      assert_equal 1, marshal.signed_char, 'expect operations: 1'
      
      assert_equal :claim_reward_balance_operation, marshal.operation_type, 'expect operation type: claim_reward_balance_operation'
      assert_equal 'teacherpearline', marshal.string, 'expect account: teacherpearline'
      assert_equal Type::Amount.new('0.000 STEEM').to_s, marshal.amount.to_s, 'expect amount: 0.000 STEEM'
      assert_equal Type::Amount.new('0.845 SBD').to_s, marshal.amount.to_s, 'expect amount: 0.845 SBD'
      assert_equal Type::Amount.new('404.731593 VESTS').to_s, marshal.amount.to_s, 'expect amount: 0.000 VESTS'
    end
    
    def test_trx_ad_hoc_1
      builder = Steem::TransactionBuilder.new
      
      builder.put(account_update_operation: {
        account: 'social',
        memo_key: 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG',
        json_metadata: '{}'
      })
      
      marshal = Marshal.new(hex: builder.transaction_hex)
      
      assert marshal.uint16, 'expect ref_block_num'
      assert marshal.uint32, 'expect ref_block_prefix'
      assert marshal.point_in_time, 'expect expiration'
      
      assert_equal 1, marshal.signed_char, 'expect operations: 1'
      assert_equal :account_update_operation, marshal.operation_type, 'expect operation type: account_update_operation'
      assert_equal 'social', marshal.string, 'expect account: social'
      assert 0, marshal.authority(optional: true)
      assert 0, marshal.authority(optional: true)
      assert 0, marshal.authority(optional: true)
      assert_equal 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', marshal.public_key, 'expect memo_key: STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG'
      assert_equal '{}', marshal.string, 'expect json_metadata: {}'
    end
    
    def test_trx_ad_hoc_2
      builder = Steem::TransactionBuilder.new
      
      builder.put(comment_operation: {
        "parent_author": "",
        "parent_permlink": "dlive",
        "author": "zaku",
        "permlink": "98bb0d05-9e15-11e8-b733-0242ac110003",
        "title": "MODERN COMBAT 5 [BLACK OUT] : DAILY GAMEPLAY #11-August-2018",
        "body": "[![Thumbnail](https:\/\/images.dlive.io\/4a85e837-9e18-11e8-9a43-0242ac110002)](https:\/\/dlive.io\/video\/zaku\/98bb0d05-9e15-11e8-b733-0242ac110003)\n\n\n# MC5: MODERN COMBAT 5 Videos Upload:\n\n![flower-squiggle-2s.png](https:\/\/cdn.steemitimages.com\/DQmcFuQRq8xwnjitZ1VPK7JvyCjAP6DJ1W4xqUSdvAugWiV\/flower-squiggle-2s.png)\n\n* [MODERN COMBAT 5 (BLACKOUT) : Multiplayer Fight + COMBAT PACK Unlock + Level up to 5](https:\/\/steemit.com\/games\/@zaku\/modern-combat-5-blackout-multiplayer-fight-combat-pack-unlock-level-up-to-5)\n\n* [MODERN COMBAT 5 (BLACK OUT) : Multiplayer Fight ( Free-For-All + VIP ) + Reward Redeem + GOLDEN BOSK Purchase](https:\/\/steemit.com\/dlive\/@zaku\/768946c6-98a6-11e8-8af8-0242ac110003)\n\n* [MODERN COMBAT GAMEPLAY : Multiplayer fights](https:\/\/dlive.io\/video\/zaku\/c2fb655a-9a5c-11e8-9e1e-0242ac110003)\n\n* [MODERN COMBAT 5 (BLACK OUT) : Multiplayer Fight ( Free-For-All + VIP ) + Reward Redeem + GOLDEN BOSK Purchase](https:\/\/steemit.com\/dlive\/@zaku\/768946c6-98a6-11e8-8af8-0242ac110003)\n\n* [MODERN COMBAT GAMEPLAY : Multiplayer fights](https:\/\/steemit.com\/dlive\/@zaku\/c2fb655a-9a5c-11e8-9e1e-0242ac110003)\n\n* [MODERN COMBAT 5 [BLACK OUT] : GAMEPLAY #08-Aug-2018](https:\/\/steemit.com\/dlive\/@zaku\/8fb4c940-9bb9-11e8-9a98-0242ac110003)\n\n# MODERN COMBAT VERSUS Videos Upload:\n\n![flower-squiggle-2s.png](https:\/\/cdn.steemitimages.com\/DQmcFuQRq8xwnjitZ1VPK7JvyCjAP6DJ1W4xqUSdvAugWiV\/flower-squiggle-2s.png)\n\n* [MODERN COMBAT VERSUS : Kult Unlock (POISON BOSS)](https:\/\/steemit.com\/dlive\/@zaku\/acefa790-870a-11e8-adb2-bf4283a63cb9)\n\n* [MODERN COMBAT VERSUS : Ultimate Kult Agent + Multiplayer Fight & Agent Upgrade [480p]](https:\/\/steemit.com\/dlive\/@zaku\/e7f2eaa0-8809-11e8-adb2-bf4283a63cb9)\n\n* [MODERN COMBAT VERSUS : LEAGUE PROMOTION TO GOLD LEAGUE](https:\/\/steemit.com\/dlive\/@zaku\/c76a52e0-882d-11e8-adb2-bf4283a63cb9)\n\n* [MODERN COMBAT VERSUS : League Promotion + Reward Collect + Multiplayer Fight](https:\/\/steemit.com\/dlive\/@zaku\/0da0ccf0-8a57-11e8-b2de-f7be8f055a16)\n\n* [Modern Combat Versus : 20$ Worth Pack buy using xbox gift cards + Kult Ultimate Upgrade + Beast mode](https:\/\/steemit.com\/dlive\/@zaku\/2306b3c0-8e80-11e8-b2de-f7be8f055a16)\n\n* [Modern Combat Versus: Turrent vs Enemy ](https:\/\/steemit.com\/dlive\/@zaku\/321eb460-917e-11e8-b2de-f7be8f055a16)\n\n* [MODERN COMBAT VERSUS : Multiplayer Game play + New Agent + Reward Redeem](https:\/\/steemit.com\/dlive\/@zaku\/1a46d3ae-989c-11e8-9e1e-0242ac110003)\n\n*[MODERN COMBAT VERSUS : Multiplayer Fight's + Loot Open + Reward Redeem](https:\/\/steemit.com\/dlive\/@zaku\/199e4a06-996d-11e8-9e1e-0242ac110003)\n\n* [MODERN COMBAT VERSUS : Daily Gameplay #07-Aug-2018](https:\/\/steemit.com\/dlive\/@zaku\/e5b61976-9a70-11e8-a04f-0242ac110003)\n\n* [MODERN COMBAT VERSUS : GAMEPLAY #8-Aug-2018](https:\/\/steemit.com\/dlive\/@zaku\/b0da8459-9bd1-11e8-a04f-0242ac110003)\n\nhttps:\/\/steemitimages.com\/0x0\/https:\/\/cdn.steemitimages.com\/DQmaKdWkztaw7QsWpgFLiWYma491XfZPBCitb1oo9gYMn7V\/DLive_br.gif\n\n# Some Important Post that might help you:\n\n![stars.png](https:\/\/cdn.steemitimages.com\/DQmYfAmraAMmuMvGM7UGxMpSS6jiPTimaGbGbFAcjU36E1r\/stars.png)\n\n* [Introducing Instant Voting Bot - @bdvoter with guaranteed profit for Buyer and Delegator](https:\/\/steemit.com\/bdvoter\/@bdvoter\/introducing-instant-voting-bot-bdvoter-with-granteed-profit-for-buyer-and-delegator)\n\n\n* [STEEMIT \u098f \u09b8\u09a0\u09bf\u0995 \u09ad\u09be\u09ac\u09c7 \u0989\u09aa\u09be\u09b0\u09cd\u099c\u09a8 \u0995\u09b0\u09be\u09b0 \u09a8\u09bf\u09df\u09ae \u0993 \u09ac\u09bf\u09a1 \u09ac\u09cb\u099f\u09c7\u09b0 \u09ac\u09bf\u09b8\u09cd\u09a4\u09be\u09b0\u09bf\u09a4 \u09b8\u09ae\u09cd\u09aa\u09b0\u09cd\u0995\u09c7 \u0986\u09b2\u09cb\u099a\u09a8\u09be](https:\/\/steemit.com\/bidbot\/@zaku\/steemit)\n\n* [Minnowbooster \u098f\u09b0 \u09b8\u0995\u09b2 \u09b8\u09be\u09b0\u09cd\u09ad\u09bf\u09b8 \u09a8\u09bf\u09df\u09c7 \u09ac\u09be\u0982\u09b2\u09be \u0986\u09b2\u09cb\u099a\u09a8\u09be \u0964 ( Part - 1 )](https:\/\/steemit.com\/minnowbooster\/@zaku\/minnowbooster)\n\n* [MinnowBooster \u098f\u09b0 \u09b8\u0995\u09b2 \u09b8\u09be\u09b0\u09cd\u09ad\u09bf\u09b8 \u09a8\u09bf\u09df\u09c7 \u09ac\u09be\u0982\u09b2\u09be \u0986\u09b2\u09cb\u099a\u09a8\u09be \u0964 ( Part - 2 )](https:\/\/steemit.com\/minnowbooster\/@zaku\/minnowbooster-part-2)\n\n* [\u09ae\u09bf\u09a8\u09cb\u09ac\u09c1\u09b8\u09cd\u099f\u09be\u09b0 \u098f\u09b0 \u09b8\u09a0\u09bf\u0995 \u09ac\u09cd\u09af\u09ac\u09b9\u09be\u09b0 \u0993 \u09ac\u09cd\u09b2\u0995\u09b2\u09bf\u09b8\u09cd\u099f \u09a5\u09c7\u0995\u09c7 \u09aa\u09b0\u09bf\u09a4\u09cd\u09b0\u09be\u09a8 \u098f\u09b0 \u099c\u09a8\u09cd\u09af \u0995\u09b0\u09a8\u09c0\u09df \u09aa\u09a6\u0995\u09cd\u09b7\u09c7\u09aa](https:\/\/steemit.com\/minnowbooster\/@zaku\/569dxc)\n\n\n* [\u09af\u09c7\u09ad\u09be\u09ac\u09c7 @steemitbd \u09ac\u09be\u0982\u09b2\u09be\u09a6\u09c7\u09b6\u09c0 \u0987\u0989\u099c\u09be\u09b0\u09a6\u09c7\u09b0 \u09b8\u09b9\u09af\u09cb\u0997\u09bf\u09a4\u09be\u09df \u098f\u0997\u09bf\u09df\u09c7 \u0986\u09b8\u099b\u09c7\u0964](https:\/\/steemit.com\/steemitbd\/@zaku\/steemitbd) \n\n* [Why @steemitbd is the best communication for Bangladeshi Newbie Users. (Find Out Here)](https:\/\/steemit.com\/community\/@zaku\/why-steemitbd-is-the-best-communication-for-bangladeshi-newbie-users-find-out-here)\n\n* [ANNOUNCED: STEEMITBD PROMOTION CONTEST](https:\/\/steemit.com\/promo-steemitbd\/@zaku\/announced-steemitbd-promotion-contest)\n\nhttps:\/\/steemitimages.com\/0x0\/https:\/\/cdn.steemitimages.com\/DQmaKdWkztaw7QsWpgFLiWYma491XfZPBCitb1oo9gYMn7V\/DLive_br.gif\n\n\n\n# Gaming Youtube Channels:\n\n![9.gif](https:\/\/cdn.steemitimages.com\/DQmRU6fYkhsKC4CkjVS7zXDW4994rqoDmoyKJXZnxTSfpdU\/9.gif)\n\n* [MC5 Official Youtube Channel](https:\/\/www.youtube.com\/channel\/UCF1C_Ptm9Pdtpbo1n0C42LQ)\n\n* [Jwae - Modern Combat 5](https:\/\/www.youtube.com\/user\/fskjwae)\n\n* [Hybrid Gamer](https:\/\/www.youtube.com\/channel\/UCl8cWr8TFvNwiQKVoLwwUyw)\n\n* [Techzamazing](https:\/\/www.youtube.com\/user\/Techzamazing)\n\n* [GameRiot](https:\/\/www.youtube.com\/user\/GameRiotArmy)\n\n<sub>***INFORMATION TAKEN FROM MC5 WEBSITE***<\/sub>\n\n[![zakucustomfooter2.gif](https:\/\/cdn.steemitimages.com\/DQmcdJWyg3fYukURPqrwb4nqoRPvEQVd6d1RqkUopxTtBPR\/zakucustomfooter2.gif)](https:\/\/discord.gg\/Z3P6bbt)<\/center>\n\n\nMy video is at [DLive](https:\/\/dlive.io\/video\/zaku\/98bb0d05-9e15-11e8-b733-0242ac110003)",
        "json_metadata": "{\"tags\":[\"dlive\",\"dlive-video\",\"Gaming\",\"steemgamingcommunity\",\"games\",\"dailygames\",\"mc5\",\"moderncombat5blackout\"],\"app\":\"dlive\/0.1\",\"format\":\"markdown\",\"language\":\"English\",\"thumbnail\":\"https:\/\/images.dlive.io\/4a85e837-9e18-11e8-9a43-0242ac110002\"}"
      })
      
      marshal = Marshal.new(hex: builder.transaction_hex)
      
      assert marshal.uint16, 'expect ref_block_num'
      assert marshal.uint32, 'expect ref_block_prefix'
      assert marshal.point_in_time, 'expect expiration'
      
      assert_equal 1, marshal.signed_char, 'expect operations: 1'
      assert_equal :comment_operation, marshal.operation_type, 'expect operation type: comment_operation'
      assert_equal '', marshal.string, 'expect parent_author: <empty>'
      assert_equal 'dlive', marshal.string, 'expect parent_permlink: dlive'
      assert_equal 'zaku', marshal.string, 'expect author: zaku'
      assert_equal '98bb0d05-9e15-11e8-b733-0242ac110003', marshal.string, 'expect permlink: 98bb0d05-9e15-11e8-b733-0242ac110003'
      assert_equal 'MODERN COMBAT 5 [BLACK OUT] : DAILY GAMEPLAY #11-August-2018', marshal.string, 'expect title: MODERN COMBAT 5 [BLACK OUT] : DAILY GAMEPLAY #11-August-2018'
      assert_equal 5588, marshal.string.size, 'expect body length: 5588'
      assert_equal "{\"tags\":[\"dlive\",\"dlive-video\",\"Gaming\",\"steemgamingcommunity\",\"games\",\"dailygames\",\"mc5\",\"moderncombat5blackout\"],\"app\":\"dlive\/0.1\",\"format\":\"markdown\",\"language\":\"English\",\"thumbnail\":\"https:\/\/images.dlive.io\/4a85e837-9e18-11e8-9a43-0242ac110002\"}", marshal.string, 'expect json_metadata: {...}'
    end
    
    def test_trx_ad_hoc_3
      builder = Steem::TransactionBuilder.new
      
      builder.put(account_update_operation: {
        account: 'social',
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
      })
      
      marshal = Marshal.new(hex: builder.transaction_hex)
      
      assert marshal.uint16, 'expect ref_block_num'
      assert marshal.uint32, 'expect ref_block_prefix'
      assert marshal.point_in_time, 'expect expiration'
      
      assert_equal 1, marshal.signed_char, 'expect operations: 1'
      assert_equal :account_update_operation, marshal.operation_type, 'expect operation type: account_update_operation'
      assert_equal 'social', marshal.string, 'expect account: social'
      
      marshal.authority(optional: true).tap do |owner|
        assert_equal 1, owner[:weight_threshold], 'expect owner authority weight_threshold: 1'
        assert_equal [], owner[:account_auths], 'expect owner authority account_auths: []'
        assert_equal [["STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG", 1]], owner[:key_auths], 'expect owner authority key_auths: [["STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG", 1]]'
      end

      marshal.authority(optional: true).tap do |active|
        assert_equal 1, active[:weight_threshold], 'expect active authority weight_threshold: 1'
        assert_equal [], active[:account_auths], 'expect active authority account_auths: []'
        assert_equal [["STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG", 1]], active[:key_auths], 'expect active authority key_auths: [["STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG", 1]]'
      end

      marshal.authority(optional: true).tap do |posting|
        assert_equal 1, posting[:weight_threshold], 'expect posting authority weight_threshold: 1'
        assert_equal [], posting[:account_auths], 'expect posting authority account_auths: []'
        assert_equal [["STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG", 1]], posting[:key_auths], 'expect posting authority key_auths: [["STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG", 1]]'
      end
      
      assert_equal 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG', marshal.public_key, 'expect memo_key: STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG'
      assert_equal '{}', marshal.string, 'expect json_metadata: {}'
    end
    
    def test_trx_ad_hoc_4
      builder = Steem::TransactionBuilder.new
      
      builder.put(escrow_transfer: { # FIXME Why do we have to use escrow_transfer and not :escrow_transfer_operation here?
        from: 'social',
        to: 'alice',
        agent: 'bob',
        escrow_id: 1234,
        sbd_amount: '0.000 SBD',
        steem_amount: '0.000 STEEM',
        fee: '0.000 STEEM',
        ratification_deadline: '2018-10-15T19:52:09',
        escrow_expiration: '2018-10-15T19:52:09',
        json_meta: '{}'
      })
      
      marshal = Marshal.new(hex: builder.transaction_hex)
      
      assert marshal.uint16, 'expect ref_block_num'
      assert marshal.uint32, 'expect ref_block_prefix'
      assert marshal.point_in_time, 'expect expiration'
      
      assert_equal 1, marshal.signed_char, 'expect operations: 1'
      assert_equal :escrow_transfer_operation, marshal.operation_type, 'expect operation type: escrow_transfer_operation'
      assert_equal 'social', marshal.string, 'expect from: social'
      assert_equal 'alice', marshal.string, 'expect to: alice'
      assert_equal '0.000 SBD', marshal.amount.to_s, 'expect sbd_amount: 0.000 SBD'
      assert_equal '0.000 STEEM', marshal.amount.to_s, 'expect steem_amount: 0.000 STEEM'
      assert_equal 1234, marshal.uint32, 'expect escrow_id: 1234'
      assert_equal 'bob', marshal.string, 'expect agent: bob'
      assert_equal '0.000 STEEM', marshal.amount.to_s, 'expect fee: 0.000 STEEM'
      assert_equal '{}', marshal.string, 'expect json_meta: {}'
      assert_equal Time.parse('2018-10-15 12:52:09 -0700'), marshal.point_in_time, 'expect escrow_expiration: 2018-10-15 12:52:09 -0700'
      assert_equal Time.parse('2018-10-15 12:52:09 -0700'), marshal.point_in_time, 'expect escrow_expiration: 2018-10-15 12:52:09 -0700'
    end
    
    def test_trx_ad_hoc_5
      builder = Steem::TransactionBuilder.new
      
      builder.put(change_recovery_account_operation: {
        account_to_recover: 'alice',
        new_recovery_account: 'bob',
        extensions: []
      })
      
      marshal = Marshal.new(hex: builder.transaction_hex)
      
      assert marshal.uint16, 'expect ref_block_num'
      assert marshal.uint32, 'expect ref_block_prefix'
      assert marshal.point_in_time, 'expect expiration'
      
      assert_equal 1, marshal.signed_char, 'expect operations: 1'
      assert_equal :change_recovery_account_operation, marshal.operation_type, 'expect operation type: change_recovery_account_operation'
      assert_equal 'alice', marshal.string, 'expect account_to_recover: alice'
      assert_equal 'bob', marshal.string, 'expect new_recovery_account: bob'
    end
    
    def test_trx_ad_hoc_6
      builder = Steem::TransactionBuilder.new
      
      builder.put(comment_operation: {
        author: 'alice',
        permlink: 'permlink',
        parent_permlink: 'parent_permlink',
        title: 'title',
        body: 'body'
      })

      builder.put(comment_options: { # FIXME Why do we have to use comment_options and not :comment_options_operation here?
        author: 'alice',
        permlink: 'permlink',
        max_accepted_payout: '1000000.000 SBD',
        percent_steem_dollars: 10000,
        allow_votes: true,
        allow_curation_rewards: true,
        extensions: []
      })
      
      builder.put(vote_operation: {
        voter: 'alice',
        author: 'alice',
        permlink: 'permlink',
        weight: 10000
      })
      
      marshal = Marshal.new(hex: builder.transaction_hex)
      
      assert marshal.uint16, 'expect ref_block_num'
      assert marshal.uint32, 'expect ref_block_prefix'
      assert marshal.point_in_time, 'expect expiration'
      
      assert_equal 3, marshal.signed_char, 'expect operations: 3'
      
      assert_equal :comment_operation, marshal.operation_type, 'expect operation type: comment_operation'
      assert_equal '', marshal.string, 'expect parent_author: <empty>'
      assert_equal 'parent_permlink', marshal.string, 'expect parent_permlink: parent_permlink'
      assert_equal 'alice', marshal.string, 'expect author: alice'
      assert_equal 'permlink', marshal.string, 'expect permlink: permlink'
      assert_equal 'title', marshal.string, 'expect title: title'
      assert_equal 'body', marshal.string, 'expect body: body'
      assert_equal '', marshal.string, 'expect json_metadata: <empty>'

      assert_equal :comment_options_operation, marshal.operation_type, 'expect operation type: comment_options_operation'
      assert_equal 'alice', marshal.string, 'expect author: alice'
      assert_equal 'permlink', marshal.string, 'expect permlink: permlink'
      assert_equal '1000000.000 SBD', marshal.amount.to_s, 'expect max_accepted_payout: 1000000.000 SBD'
      assert_equal 10000, marshal.uint16, 'expect percent_steem_dollars: 10000'
      assert_equal false, marshal.boolean, 'expect allow_replies: false'
      assert_equal false, marshal.boolean, 'expect allow_votes: false'
      assert_equal false, marshal.boolean, 'expect allow_curation_rewards: false'
      
      assert_equal :vote_operation, marshal.operation_type, 'expect operation type: vote_operation'
      assert_equal 'alice', marshal.string, 'expect voter: alice'
      assert_equal 'alice', marshal.string, 'expect author: alice'
      assert_equal 'permlink', marshal.string, 'expect permlink: permlink'
      assert_equal 10000, marshal.int16, 'expect weight: 10000'
    end
    
    def test_trx_ad_hoc_9
      # Example transaction:
      #
      # ref_block_num: 20,
      # ref_block_prefix: 2890012981,
      # expiration: '2018-10-15T19:52:09',
      # operations: [{type: :account_create_operation, value: {
      #   fee: Type::Amount.new('0.000 TESTS'),
      #   creator: 'porter',
      #   new_account_name: 'a2i-06e13981',
      #   owner: {weight_threshold: 1, account_auths: [['porter', 1]], key_auths: []},
      #   active: {weight_threshold: 1, account_auths: [['porter', 1]], key_auths: []},
      #   posting: {weight_threshold: 1, account_auths: [['porter', 1]], key_auths: []},
      #   memo_key: 'TST77yiRp7pgK52V7BPgq8mEYtyi9XLHKxCH6TDgKA86inFRYgWju',
      #   json_metadata: ''
      # }}, {type: :transfer_to_vesting_operation, value: {
      #   from: 'porter',
      #   to: 'a2i-06e13981',
      #   amount: Type::Amount.new('8.204 TESTS')
      # }}]

      marshal = Marshal.new(chain: :test, hex: '1400351942ace9efc45b02090000000000000000035445535453000006706f727465720c6132692d3036653133393831010000000106706f72746572010000010000000106706f72746572010000010000000106706f7274657201000003260545a135c05a8adec1ad4676d046cd1312f16f41b2fb1c01cb2276cf2536e8000306706f727465720c6132692d30366531333938310c2000000000000003544553545300000000')
      
      assert_equal 20, marshal.uint16, 'expect ref_block_num: 20'
      assert_equal 2890012981, marshal.uint32, 'expect ref_block_prefix: 2890012981'
      assert_equal Time.parse('2018-10-15 12:52:09 -0700'), marshal.point_in_time, 'expect expiration: 2018-10-15 12:52:09 -0700'
      
      assert_equal 2, marshal.signed_char, 'expect operations: 2'
      
      assert_equal :account_create_operation, marshal.operation_type, 'expect operation type: account_create_operation'
      assert_equal Type::Amount.new('0.000 TESTS').to_s, marshal.amount.to_s, 'expect amount: 0.000 TESTS'
      assert_equal 'porter', marshal.string, 'expect creator: porter'
      assert_equal 'a2i-06e13981', marshal.string, 'expect new_account_name: a2i-06e13981'

      marshal.authority.tap do |owner|
        assert_equal 1, owner[:weight_threshold], 'expect owner authority weight_threshold: 1'
        assert_equal [["porter", 1]], owner[:account_auths], 'expect owner authority account_auths: [["porter", 1]]'
        assert_equal [], owner[:key_auths], 'expect owner authority key_auths: []'
      end
      
      marshal.authority.tap do |active|
        assert_equal 1, active[:weight_threshold], 'expect active authority weight_threshold: 1'
        assert_equal [["porter", 1]], active[:account_auths], 'expect active authority account_auths: [["porter", 1]]'
        assert_equal [], active[:key_auths], 'expect active authority key_auths: []'
      end
      
      marshal.authority.tap do |posting|
        assert_equal 1, posting[:weight_threshold], 'expect posting authority weight_threshold: 1'
        assert_equal [["porter", 1]], posting[:account_auths], 'expect posting authority account_auths: [["porter", 1]]'
        assert_equal [], posting[:key_auths], 'expect posting authority key_auths: []'
      end
      
      assert_equal 'TST77yiRp7pgK52V7BPgq8mEYtyi9XLHKxCH6TDgKA86inFRYgWju', marshal.public_key, 'expect memo_key: TST77yiRp7pgK52V7BPgq8mEYtyi9XLHKxCH6TDgKA86inFRYgWju'
      assert_equal '', marshal.string, 'expect empty json_metata'
    end
  end
end
