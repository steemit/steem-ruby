module Steem
  # Steem::BlockApi
  class BlockApi < Api
    MAX_RANGE_SIZE = 3000
    
    def initialize(options = {})
      self.class.api_name = :block_api
      super
    end
    
    # Uses a batched requst on `block_range`.
    def get_blocks(options = {block_range: [0..0]}, &block)
      block_range = options[:block_range] || [0..0]
      
      if block_range.size > MAX_RANGE_SIZE
        raise "Too many blocks requested: #{block_range.size}; maximum request size: #{MAX_RANGE_SIZE}."
      end
      
      request_body = []
      
      for i in block_range do
        put(self.class.api_name, :get_block, block_num: i, request_body: request_body)
      end
      
      if !!block
        rpc_post(nil, nil, request_body: request_body) do |result, error, id|
          yield result.nil? ? nil : result.block, error, id
        end
      else
        blocks = []
        
        rpc_post(nil, nil, request_body: request_body) do |result, error, id|
          blocks << result
        end
      end
    end
  end
end
