require 'test_helper'

module Steem
  class MemoTest < Steem::Test
    def setup
      @wif = '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC'
      @private_key = Bitcoin::Key.from_base58 @wif
      @public_key = @private_key.pub
      
      skip 'not implemented' unless defined? Auth::Memo.aes
    end
    
    def test_plain_text
      plain_text_1 = Auth::Memo.encode(nil, nil, 'memo')
      assert_equal 'memo', plain_text_1
      plain_text_2 = Auth::Memo.decode(nil, plain_text_1)
      assert_equal 'memo', plain_text_2
    end
    
    def test_encryption_object_params
      cypher_text = Auth::Memo.encode(@private_key, @private_key, '#memo')
      plain_text = Auth::Memo.decode(@private_key, cypher_text)
      assert_equal 'memo', plain_text
    end
    
    def test_encryption_string_params
      cypher_text = Auth::Memo.encode(@wif, @private_key, '#memo2')
      plain_text = Auth::Memo.decode(@wif, cypher_text)
      assert_equal 'memo2', plain_text
    end
    
    def test_known_encryption
      base58 = '#HU6pdQ4Hh8cFrDVooekRPVZu4BdrhAe9RxrWrei2CwfAApAPdM4PT5mSV9cV3tTuWKotYQF6suyM4JHFBZz4pcwyezPzuZ2na7uwhRcLqFoqCam1VU3eCLjVNqcgUNbH3'
      nonce = 1462976530069648
      text = '#爱'
      cypher_text = Auth::Memo.encode(@private_key, @public_key, text, nonce)
      plain_text = Auth::Memo.decode(@private_key, cypher_text)
      
      assert_equal base58, cypher_text
      assert_equal text[1..-1], plain_text
    end
  end
end
