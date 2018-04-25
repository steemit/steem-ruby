require 'test_helper'

module Steem
  class BlockApiTest < Steem::Test
    def setup
      @block_api = BlockApi.new
    end
    
    def test_get_blocks
      vcr_cassette('get_blocks') do
        @block_api.get_blocks(block_range: 9001..9010) do |blocks|
          assert_equal Hashie::Mash, blocks.class
        end
      end
    end
    
    def test_get_blocks_no_closure
      vcr_cassette('get_blocks') do
        blocks = @block_api.get_blocks(block_range: 9001..9010)
        assert_equal Hashie::Array, blocks.class
      end
    end
    
    def test_get_blocks_too_many
      assert_raises RuntimeError, 'expect runtime error' do
        @block_api.get_blocks(block_range: 9001..19010)
      end
    end
    
    def test_get_block
      vcr_cassette('get_block') do
        @block_api.get_block(block_num: 12345678) do |block|
          assert_equal Hashie::Mash, block.class
        end
      end
    end
    
    def test_get_block_no_closure
      vcr_cassette('get_block') do
        result = @block_api.get_block(block_num: 12345678)
        assert_equal Hashie::Mash, result.class
      end
    end
    
    def test_get_block_header
      vcr_cassette('get_block_header') do
        @block_api.get_block_header(block_num: 12345678) do |block|
          assert_equal Hashie::Mash, block.class
        end
      end
    end
    
    def test_block_header_wrong_arguments
      vcr_cassette('get_block_header_wrong_arguments') do
        stderr = STDERR.clone
        stderr.reopen File.new('/dev/null', 'w')
        test_block_api = BlockApi.new(error_pipe: stderr)
        test_block_api.get_block_header(block_num: 12345678, foo: :bar) do |block|
          assert_equal Hashie::Mash, block.class
        end
        
        begin
          test_block_api.get_block_header(false)
          # :nocov:
          fail 'please review this test'
          # :nocov:
        rescue Steem::ArgumentError => e
          assert e.to_s, 'expect string from argument error'
        end
        
        begin
          monkey = {}
          monkey.define_singleton_method(:to_h) { raise 'Weird Monkey' }
          test_block_api.get_block_header(monkey)
          # :nocov:
          fail 'please review this test'
          # :nocov:
        rescue Steem::ArgumentError => e
          assert e.to_s, 'expect string from argument error'
        end
      end
    end
  end
end
