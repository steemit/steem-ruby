require 'test_helper'

module Steem
  class AmountTest < Steem::Test
    def setup
      @amount = Steem::Type::Amount.new('0.000 STEEM')
    end
    
    def test_to_s
      assert_equal '0.000 SBD', Steem::Type::Amount.to_s(['0', 3, '@@000000013'])
      assert_equal '0.000 STEEM', Steem::Type::Amount.to_s(['0', 3, '@@000000021'])
      assert_equal '0.000000 VESTS', Steem::Type::Amount.to_s(['0', 6, '@@000000037'])
      
      assert_raises TypeError do
        Steem::Type::Amount.to_s(['0', 3, '@@00000000'])
      end
    end
    
    def test_to_nia
      assert_equal ['0', 3, '@@000000013'], Steem::Type::Amount.to_nia('0.000 SBD')
      assert_equal ['0', 3, '@@000000021'], Steem::Type::Amount.to_nia('0.000 STEEM')
      assert_equal ['0', 6, '@@000000037'], Steem::Type::Amount.to_nia('0.000 VESTS')
      
      assert_raises TypeError do
        Steem::Type::Amount.to_nia('0.000 BOGUS')
      end
    end
    
    def test_to_bytes
      assert @amount.to_bytes
    end
  end
end