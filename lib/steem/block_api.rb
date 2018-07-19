module Steem
  # {BlockApi} is used to query values related to the block plugin.  It can also
  # be used to access a range of multiple blocks by using
  # {http://www.jsonrpc.org/specification#batch JSON-RPC 2.0 batch} requests.
  #
  # Also see: {https://developers.steem.io/apidefinitions/block-api Block API Definitions}
  class BlockApi < Api
    MAX_RANGE_SIZE = 50
    
    def initialize(options = {})
      self.class.api_name = :block_api
      super
    end
    
    # Uses a batched requst on a range of block headers.
    #
    # @param options [Hash] The attributes to get a block range with.
    # @option options [Range] :block_range starting on one block number and ending on an higher block number.
    def get_block_headers(options = {block_range: (0..0)}, &block)
      get_block_objects(options.merge(object: :block_header), block)
    end
    
    # Uses a batched requst on a range of blocks.
    #
    # @param options [Hash] The attributes to get a block range with.
    # @option options [Range] :block_range starting on one block number and ending on an higher block number.
    def get_blocks(options = {block_range: (0..0)}, &block)
      get_block_objects(options.merge(object: :block), block)
    end
  private
    def get_block_objects(options = {block_range: (0..0)}, block = nil)
      object = options[:object]
      object_method = "get_#{object}".to_sym
      block_range = options[:block_range] || (0..0)
      
      if (start = block_range.first) < 1
        raise Steem::ArgumentError, "Invalid starting block: #{start}"
      end
      
      chunks = if block_range.size > MAX_RANGE_SIZE
        block_range.each_slice(MAX_RANGE_SIZE)
      else
        [block_range]
      end
      
      for sub_range in chunks do
        request_object = []
        
        for i in sub_range do
          @rpc_client.put(self.class.api_name, object_method, block_num: i, request_object: request_object)
        end
        
        if !!block
          index = 0
          @rpc_client.rpc_batch_execute(request_object: request_object) do |result, error, id|
            block_num = sub_range.to_a[index]
            index = index + 1
            
            case object
            when :block_header
              block.call(result.nil? ? nil : result[:header], block_num)
            else
              block.call(result.nil? ? nil : result[object], block_num)
            end
          end
        else
          blocks = []
          
          @rpc_client.rpc_batch_execute(request_object: request_object) do |result, error, id|
            blocks << result
          end
        end
      end
      
      blocks
    end
  end
end
