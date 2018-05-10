module Steem
  # {BlockApi} is used to query values related to the block plugin.  It can also
  # be used to access a range of multiple blocks by using
  # {http://www.jsonrpc.org/specification#batch JSON-RPC 2.0 batch} requests.
  #
  # Also see: {https://developers.steem.io/apidefinitions/block-api Block API Definitions}
  class BlockApi < Api
    MAX_RANGE_SIZE = 3000
    
    def initialize(options = {})
      self.class.api_name = :block_api
      super
    end
    
    # Uses a batched requst on a range of blocks.
    #
    # @param options [Hash] The attributes to get a block range with.
    # @option options [Range] :block_range starting on one block number and ending on an higher block number.
    def get_blocks(options = {block_range: [0..0]}, &block)
      block_range = options[:block_range] || [0..0]
      
      if block_range.size > MAX_RANGE_SIZE
        raise Steem::ArgumentError, "Too many blocks requested: #{block_range.size}; maximum request size: #{MAX_RANGE_SIZE}."
      end
      
      request_body = []
      
      for i in block_range do
        @rpc_client.put(self.class.api_name, :get_block, block_num: i, request_body: request_body)
      end
      
      if !!block
        @rpc_client.rpc_post(nil, nil, request_body: request_body) do |result, error, id|
          yield result.nil? ? nil : result.block, error, id
        end
      else
        blocks = []
        
        @rpc_client.rpc_post(nil, nil, request_body: request_body) do |result, error, id|
          blocks << result
        end
      end
    end
  end
end
