require 'test_helper'

module Steem
  class TransactionBuilderTest < Steem::Test
    include ChainConfig
    
    def setup
      @wif = '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC'
      @options = {
        app_base: false
      }
    end
    
    def test_transaction_builder_initialize
      assert TransactionBuilder.new
    end
    
    def test_transaction_builder_initialize_testnet
      options = {
        database_api: :bogus_api,
        block_api: :bogus_api,
        chain: :test
      }
      
      assert TransactionBuilder.new(@options.merge options)
    end
    
    def test_transaction_builder_initialize_unsupported_chain
      options = {
        database_api: :bogus_api,
        block_api: :bogus_api,
        chain: :bogus
      }
      assert_raises UnsupportedChainError do
        TransactionBuilder.new(@options.merge options)
      end
    end
    
    def test_transaction_builder_initialize_bad_mainnet_injection
      options = {
        database_api: :bogus_api,
        block_api: :bogus_api,
        testnet: true,
        chain_id: NETWORKS_STEEM_CHAIN_ID
      }
      assert_raises UnsupportedChainError do
        TransactionBuilder.new(@options.merge options)
      end
    end
    
    def test_reset
      assert TransactionBuilder.new(@options).reset
    end
    
    def test_inspect
      assert TransactionBuilder.new(@options).inspect
    end
    
    
    def test_valid
      builder = TransactionBuilder.new(@options.merge wif: @wif)
      
      vcr_cassette 'transaction_builder_valid' do
        builder.put(vote: {
          voter: 'social',
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        })
        
        assert !!builder.valid?
      end
    end
    
    def test_valid_irrelevant
      builder = TransactionBuilder.new(@options.merge wif: @wif)
      
      vcr_cassette 'transaction_builder_valid_irrelevant' do
        assert_raises IrrelevantSignatureError, "did not expect valid transaction: #{builder.inspect}" do
          builder.valid?
        end
      
        builder.put(vote: {
          voter: 'social',
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        })
        
        assert_raises MissingPostingAuthorityError, "did not expect valid transaction: #{builder.inspect}" do
          builder.valid?
        end
      end
    end
      
    def test_sign
      builder = TransactionBuilder.new(@options.merge wif: @wif)
      
      vcr_cassette 'transaction_builder_sign' do
        builder.put(vote: {
          voter: 'social',
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        })
        
        assert builder.sign
      end
    end
    
    # Just like: https://github.com/steemit/steem-js/blob/1a0f872b81399cd98c1a86bed2f67e7cf8a279da/examples/multisig.js
    def test_sign_multisig
      wifs = [
        '5K2LA2ucS8b1GuFvVgZK6itKNE6fFMbDMX4GDtNHiczJESLGRd8',
        '5JRaypasxMx1L97ZUX7YuC5Psb5EAbF821kkAGtBj7xCJFQcbLg'
      ]
      builder = TransactionBuilder.new(@options.merge wif: wifs)
      
      vcr_cassette 'transaction_builder_sign_multisig' do
        builder.put(vote: {
          voter: 'sisilafamille',
          author: 'siol',
          permlink: 'test',
          weight: 1000
        })
        
        assert builder.sign
        signatures = builder.transaction.signatures
        assert_equal 2, signatures.size
        refute_equal *signatures
      end
    end
    
    def test_sign_multisig_deferred
      initial_wif = '5K2LA2ucS8b1GuFvVgZK6itKNE6fFMbDMX4GDtNHiczJESLGRd8'
      deferred_wif = '5JRaypasxMx1L97ZUX7YuC5Psb5EAbF821kkAGtBj7xCJFQcbLg'
      builder = TransactionBuilder.new(@options.merge wif: initial_wif)
      transaction = nil
      
      vcr_cassette 'transaction_builder_sign_multisig_deferred' do
        builder.put(vote: {
          voter: 'sisilafamille',
          author: 'siol',
          permlink: 'test',
          weight: 1000
        })
        
        transaction = builder.sign
        signatures = builder.transaction.signatures
        assert_equal 1, signatures.size
      end
      
      builder = TransactionBuilder.new(@options.merge wif: deferred_wif, trx: transaction.to_json)
      assert builder.sign
      signatures = builder.transaction.signatures
      assert_equal 2, signatures.size
      refute_equal *signatures
    end
    
    def test_put
      builder = TransactionBuilder.new(@options)
      
      vcr_cassette 'transaction_builder_put' do
        builder.put(vote: {
          voter: 'social',
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        })
      end
      
      assert 1, builder.operations.size
    end
    
    def test_put_array
      builder = TransactionBuilder.new(@options)
      
      vcr_cassette 'transaction_builder_put_array' do
        builder.put([:vote, {
          voter: 'social',
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        }])
      end
      
      assert 1, builder.operations.size
    end
    
    def test_put_symbol
      builder = TransactionBuilder.new(@options)
      
      vcr_cassette 'transaction_builder_put_symbol' do
        builder.put(:vote, {
          voter: 'social',
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        })
      end
      
      assert 1, builder.operations.size
    end
    
    def test_put_string
      builder = TransactionBuilder.new(@options)
      
      vcr_cassette 'transaction_builder_put_string' do
        builder.put('vote', {
          voter: 'social',
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        })
      end
      
      assert 1, builder.operations.size
    end
    
    def test_potential_signatures
      builder = TransactionBuilder.new(@options.merge wif: @wif)
      
      vcr_cassette 'transaction_builder_sign' do
        builder.put(vote: {
          voter: 'social',
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        })
        
        assert !!builder.potential_signatures
      end
    end
    
    def test_required_signatures
      builder = TransactionBuilder.new(@options.merge wif: @wif)
      
      vcr_cassette 'transaction_builder_sign' do
        builder.put(vote: {
          voter: 'social',
          author: 'steemit',
          permlink: 'firstpost',
          weight: 10000
        })
        
        assert !!builder.required_signatures
      end
    end
  end
end
