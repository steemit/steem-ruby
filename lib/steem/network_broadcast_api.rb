module Steem
  class NetworkBroadcastApi < Api
    SECONDS_PER_BLOCK = 3
    
    def initialize(options = {})
      self.class.api_name = :network_broadcast_api
      @database_api = Steem::DatabaseApi.new(options)
      @block_api = BlockApi.new(options)
      super
    end
    
    def broadcast_transaction_synchronous(options)
      expiration = Time.parse(options[:trx][:expiration] + 'Z')
      now = Time.now
      options[:max_block_age] ||= now - expiration
      signatures = options[:trx][:signatures]
      response = broadcast_transaction(options)
      block_time = nil
      included = false
      trx_block_num = nil
      trx_id = nil
      trx_num = nil
      blocks_checked = []
      
      until !!block_time && block_time > expiration do
        break if included
        
        @database_api.get_dynamic_global_properties do |properties|
          block_time = Time.parse(properties.time + 'Z')
          block_num = properties.head_block_number
          backfill = (options[:max_block_age] / SECONDS_PER_BLOCK) + SECONDS_PER_BLOCK
          start_block_num = block_num - backfill
          block_range = start_block_num..block_num
          block_range = block_range.to_a - blocks_checked if blocks_checked.any?
          
          @block_api.get_blocks(block_range: block_range) do |b, n|
            blocks_checked << n
            transactions = b.transactions
            next unless transactions.any?
            
            transactions.each_with_index do |trx, index|
              if (signatures & trx.signatures).any?
                included = true
                trx_block_num = n
                trx_num = index
                trx_id = b.transaction_ids[index]
                break
              end
            end
          end
        end
        
        sleep SECONDS_PER_BLOCK
      end
      
      unless included
        raise "Could not find transaction with signatures: #{signatures}"
      end
      
      response.result[:block_num] = trx_block_num
      response.result[:expired] = false
      response.result[:id] = trx_id
      response.result[:trx_num] = trx_num
      
      response
    end
  end
end
