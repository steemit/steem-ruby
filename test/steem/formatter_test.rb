require 'test_helper'

module Steem
  class FormatterTest < Steem::Test
    def test_reputation
      assert_equal 25.0, Formatter.reputation(0)
      assert_equal 70.9, Formatter.reputation(124729459033169)
    end
  end
end