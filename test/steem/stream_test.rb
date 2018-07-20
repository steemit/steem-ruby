require 'test_helper'

module Steem
  class StreamTest < Steem::Test
    def setup
      @stream = Steem::Stream.new(url: TEST_NODE, no_warn: true)
      @database_api = Steem::DatabaseApi.new(url: TEST_NODE)
      
      @database_api.get_dynamic_global_properties do |properties|
        @head_block_num = properties.head_block_number
        @last_irreversible_block_num = properties.last_irreversible_block_num
      end
    end
    
    def test_block_headers
      options = {
        until_block_num: @last_irreversible_block_num + 1
      }
    
      vcr_cassette('block_headers') do
        @stream.block_headers(options) do |block_header, block_num|
          assert block_header
          assert block_num
        end
      end
    end
    
    def test_block_headers_mode_head
      stream = Steem::Stream.new(url: TEST_NODE, mode: :head)
      options = {
        until_block_num: @head_block_num + 1
      }
      
      vcr_cassette('block_headers_mode_head') do
        stream.block_headers(options) do |block_header, block_num|
          assert block_header
          assert block_num
        end
      end
    end
    
    def test_block_headers_mode_bogus
      stream = Steem::Stream.new(url: TEST_NODE, mode: :WRONG)
      options = {
        until_block_num: @head_block_num + 1
      }
      
      vcr_cassette('block_headers_mode_bogus') do
        assert_raises Steem::ArgumentError do
          stream.block_headers(options) do |block_header, block_num|
            fail 'should be unreachable'
          end
        end
      end
    end
    
    def test_blocks
      options = {
        until_block_num: @last_irreversible_block_num + 1
      }
      
      vcr_cassette('blocks') do
        @stream.blocks(options) do |block, block_num|
          assert block
          assert block_num
          assert block_num >= @last_irreversible_block_num, "expect block_num: #{block_num} greater than or equal to last_irreversible_block_num: #{@last_irreversible_block_num}"
        end
      end
    end
    
    def test_blocks_by_range
      range = @last_irreversible_block_num..(@last_irreversible_block_num + 1)
      options = {
        block_range: range
      }
      
      vcr_cassette('blocks_by_range') do
        @stream.blocks(options) do |block, block_num|
          assert block
          assert block_num
        end
      end
    end
    
    def test_transactions
      options = {
        until_block_num: @last_irreversible_block_num + 1
      }
      
      vcr_cassette('transactions') do
        @stream.transactions(options) do |trx, trx_id, block_num|
          assert trx
          assert trx_id
          assert block_num
        end
      end
    end
    
    def test_operations
      options = {
        until_block_num: @last_irreversible_block_num + 1
      }
      
      vcr_cassette('operations') do
        @stream.operations(options) do |op, trx_id, block_num|
          assert op
          assert trx_id
          assert block_num
        end
      end
    end
    
    def test_operations_by_type
      options = {
        until_block_num: @last_irreversible_block_num + 1,
        types: :vote_operation
      }
      
      vcr_cassette('operations_by_type') do
        @stream.operations(options) do |op, trx_id, block_num|
          assert op
          assert trx_id
          assert block_num
        end
      end
    end
    
    def test_operations_by_type_args
      skip 'cannot test this because we cannot express until_block_num'
      
      vcr_cassette('operations_by_type_args') do
        @stream.operations(:vote_operation, :comment_operation) do |op, trx_id, block_num|
          assert op
          assert trx_id
          assert block_num
        end
      end
    end
    
    def test_operations_by_deprecated_type
      options = {
        until_block_num: @last_irreversible_block_num + 1,
        types: :vote
      }
      
      vcr_cassette('operations_by_deprecated_type') do
        @stream.operations(options) do |op, trx_id, block_num|
          assert op
          assert trx_id
          assert block_num
        end
      end
    end
    
    def test_only_virtual_operations
      options = {
        until_block_num: @last_irreversible_block_num + 1,
        only_virtual: true
      }
      
      vcr_cassette('only_virtual_operations') do
        @stream.operations(options) do |vop, trx_id, block_num|
          assert vop
          assert trx_id
          assert_equal trx_id, Stream::VOP_TRX_ID
          assert block_num
        end
      end
    end
    
    def test_only_author_reward_operations
      range = 21831360..21831360 # we know where to look, to speed things up
      options = {
        block_range: range,
        types: :author_reward_operation,
        only_virtual: true
      }
      
      vcr_cassette('only_author_reward_operations') do
        @stream.operations(options) do |vop, trx_id, block_num|
          assert vop
          assert_equal vop.type, 'author_reward_operation'
          assert trx_id
          assert_equal trx_id, Stream::VOP_TRX_ID
          assert block_num
        end
      end
    end
  end
end