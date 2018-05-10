require 'test_helper'

module Steem
  class TransactionBuilderTest < Steem::Test
    def setup
      @wif = '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC'
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
      
      assert TransactionBuilder.new(options)
    end
    
    def test_transaction_builder_initialize_unsupported_chain
      options = {
        database_api: :bogus_api,
        block_api: :bogus_api,
        chain: :bogus
      }
      assert_raises UnsupportedChainError do
        TransactionBuilder.new(options)
      end
    end
    
    def test_reset
      assert TransactionBuilder.new.reset
    end
    
    def test_inspect
      assert TransactionBuilder.new.inspect
    end
    
    
    def test_valid
      builder = TransactionBuilder.new(wif: @wif)
      
      vcr_cassette 'transaction_builder_sign' do
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
      builder = TransactionBuilder.new(wif: @wif)
      
      vcr_cassette 'transaction_builder_valid' do
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
      builder = TransactionBuilder.new(wif: @wif)
      
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
    
    def test_put
      builder = TransactionBuilder.new
      
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
      builder = TransactionBuilder.new
      
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
      builder = TransactionBuilder.new
      
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
      builder = TransactionBuilder.new
      
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
      builder = TransactionBuilder.new(wif: @wif)
      
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
      builder = TransactionBuilder.new(wif: @wif)
      
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