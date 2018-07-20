module Steem
  # Steem::Stream allows a live view of the STEEM blockchain.
  # 
  # Example streaming blocks:
  # 
  #     stream = Steem::Stream.new
  #     
  #     stream.blocks do |block, block_num|
  #       puts "#{block_num} :: #{block.witness}"
  #     end
  # 
  # Example streaming transactions:
  # 
  #     stream = Steem::Stream.new
  #     
  #     stream.transactions do |trx, trx_id, block_num|
  #       puts "#{block_num} :: #{trx_id} :: operations: #{trx.operations.size}"
  #     end
  # 
  # Example streaming operations:
  # 
  #     stream = Steem::Stream.new
  #    
  #     stream.operations do |op, trx_id, block_num|
  #       puts "#{block_num} :: #{trx_id} :: #{op.type}: #{op.value.to_json}"
  #     end
  # 
  # Allows streaming of block headers, full blocks, transactions, operations and
  # virtual operations.
  class Stream
    attr_reader :database_api, :block_api, :account_history_api, :mode
    
    BLOCK_INTERVAL = 3
    MAX_BACKOFF_BLOCK_INTERVAL = 30
    MAX_RETRY_COUNT = 10
    
    VOP_TRX_ID = ('0' * 40).freeze

    # @param options [Hash] additional options
    # @option options [Steem::DatabaseApi] :database_api
    # @option options [Steem::BlockApi] :block_api
    # @option options [Steem::AccountHistoryApi || Steem::CondenserApi] :account_history_api
    # @option options [Symbol] :mode we have the choice between
    #   * :head the last block
    #   * :irreversible the block that is confirmed by 2/3 of all block producers and is thus irreversible!
    # @option options [Boolean] :no_warn do not generate warnings
    def initialize(options = {mode: :irreversible})
      @instance_options = options
      @database_api = options[:database_api] || Steem::DatabaseApi.new(options)
      @block_api = options[:block_api] || Steem::BlockApi.new(options)
      @account_history_api = options[:account_history_api]
      @mode = options[:mode] || :irreversible
      @no_warn = !!options[:no_warn]
    end
    
    # Use this method to stream block numbers.  This is significantly faster
    # than requesting full blocks and even block headers.  Basically, the only
    # thing this method does is call {Steem::Database#get_dynamic_global_properties} at 3 second
    # intervals.
    #
    # @param options [Hash] additional options
    # @option options [Integer] :at_block_num Starts the stream at the given block number.  Default: nil.
    # @option options [Integer] :until_block_num Ends the stream at the given block number.  Default: nil.
    def block_numbers(options = {}, &block)
      block_objects(options.merge(object: :block_numbers), block)
    end
    
    # Use this method to stream block headers.  This is quite a bit faster than
    # requesting full blocks.
    #
    # @param options [Hash] additional options
    # @option options [Integer] :at_block_num Starts the stream at the given block number.  Default: nil.
    # @option options [Integer] :until_block_num Ends the stream at the given block number.  Default: nil.
    def block_headers(options = {}, &block)
      block_objects(options.merge(object: :block_headers), block)
    end
    
    # Use this method to stream full blocks.
    #
    # @param options [Hash] additional options
    # @option options [Integer] :at_block_num Starts the stream at the given block number.  Default: nil.
    # @option options [Integer] :until_block_num Ends the stream at the given block number.  Default: nil.
    def blocks(options = {}, &block)
      block_objects(options.merge(object: :blocks), block)
    end
    
    # Use this method to stream each transaction.
    #
    # @param options [Hash] additional options
    # @option options [Integer] :at_block_num Starts the stream at the given block number.  Default: nil.
    # @option options [Integer] :until_block_num Ends the stream at the given block number.  Default: nil.
    def transactions(options = {}, &block)
      blocks(options) do |block, block_num|
        block.transactions.each_with_index do |transaction, index|
          trx_id = block.transaction_ids[index]
          
          yield transaction, trx_id, block_num
        end
      end
    end
    
    # Returns the latest operations from the blockchain.
    #
    #   stream = Steem::Stream.new
    #   stream.operations do |op|
    #     puts op.to_json
    #   end
    # 
    # If symbol are passed to `types` option, then only that operation is
    # returned.  Expected symbols are:
    #
    #   account_create_operation
    #   account_create_with_delegation_operation
    #   account_update_operation
    #   account_witness_proxy_operation
    #   account_witness_vote_operation
    #   cancel_transfer_from_savings_operation
    #   change_recovery_account_operation
    #   claim_reward_balance_operation
    #   comment_operation
    #   comment_options_operation
    #   convert_operation
    #   custom_operation
    #   custom_json_operation
    #   decline_voting_rights_operation
    #   delegate_vesting_shares_operation
    #   delete_comment_operation
    #   escrow_approve_operation
    #   escrow_dispute_operation
    #   escrow_release_operation
    #   escrow_transfer_operation
    #   feed_publish_operation
    #   limit_order_cancel_operation
    #   limit_order_create_operation
    #   limit_order_create2_operation
    #   pow_operation
    #   pow2_operation
    #   recover_account_operation
    #   request_account_recovery_operation
    #   set_withdraw_vesting_route_operation
    #   transfer_operation
    #   transfer_from_savings_operation
    #   transfer_to_savings_operation
    #   transfer_to_vesting_operation
    #   vote_operation
    #   withdraw_vesting_operation
    #   witness_update_operation
    #
    # For example, to stream only votes:
    #
    #   stream = Steem::Stream.new
    #   stream.operations(types: :vote_operation) do |vote|
    #     puts vote.to_json
    #   end
    # 
    # ... Or ...
    # 
    #   stream = Steem::Stream.new
    #   stream.operations(:vote_operation) do |vote|
    #     puts vote.to_json
    #   end
    #
    # You can also stream virtual operations:
    #
    #   stream = Steem::Stream.new
    #   stream.operations(types: :author_reward_operation, only_virtual: true) do |vop|
    #     v = vop.value
    #     puts "#{v.author} got paid for #{v.permlink}: #{[v.sbd_payout, v.steem_payout, v.vesting_payout]}"
    #   end
    #
    # ... or multiple virtual operation types;
    #
    #   stream = Steem::Stream.new
    #   stream.operations(types: [:producer_reward_operation, :author_reward_operation], only_virtual: true) do |vop|
    #     puts vop.to_json
    #   end
    #
    # ... or all types, including virtual operation types from the head block number:
    #
    #   stream = Steem::Stream.new(mode: :head)
    #   stream.operations(include_virtual: true) do |op|
    #     puts op.to_json
    #   end
    #
    # Expected virtual operation types:
    #
    #   producer_reward_operation
    #   author_reward_operation
    #   curation_reward_operation
    #   fill_convert_request_operation
    #   fill_order_operation
    #   fill_vesting_withdraw_operation
    #   interest_operation
    #   shutdown_witness_operation
    #
    # @param args [Symbol || Array<Symbol> || Hash] the type(s) of operation or hash of expanded options, optional.
    # @option args [Integer] :at_block_num Starts the stream at the given block number.  Default: nil.
    # @option args [Integer] :until_block_num Ends the stream at the given block number.  Default: nil.
    # @option args [Symbol || Array<Symbol>] :types the type(s) of operation, optional.
    # @option args [Boolean] :only_virtual Only stream virtual options.  Setting this true will improve performance because the stream only needs block numbers to then retrieve virtual operations.  Default: false.
    # @option args [Boolean] :include_virtual Also stream virtual options.  Setting this true will impact performance.  Default: false.
    # @param block the block to execute for each result.  Yields: |op, trx_id, block_num|
    def operations(*args, &block)
      options = {}
      types = []
      only_virtual = false
      include_virtual = false
      last_block_num = nil
      
      case args.first
      when Hash
        options = args.first
        types = transform_types(options[:types])
        only_virtual = !!options[:only_virtual] || false
        include_virtual = !!options[:include_virtual] || only_virtual || false
      when Symbol, Array then types = transform_types(args)
      end
      
      if only_virtual
        block_numbers(options) do |block_num|
          get_virtual_ops(types, block_num, block)
        end
      else
        transactions(options) do |transaction, trx_id, block_num|
          transaction.operations.each do |op|
            yield op, trx_id, block_num if types.none? || types.include?(op.type)
            
            next unless last_block_num != block_num
            
            last_block_num = block_num
            
            get_virtual_ops(types, block_num, block) if include_virtual
          end
        end
      end
    end
    
    def account_history_api
      @account_history_api ||= begin
        Steem::AccountHistoryApi.new(@instance_options)
      rescue Steem::UnknownApiError => e
        warn "#{e.inspect}, falling back to Steem::CondenserApi." unless @no_warn
        Steem::CondenserApi.new(@instance_options)
      end
    end
  private
    # @private
    def block_objects(options = {}, block)
      object = options[:object]
      object_method = "get_#{object}".to_sym
      block_interval = BLOCK_INTERVAL
      
      at_block_num, until_block_num = if !!block_range = options[:block_range]
        [block_range.first, block_range.last]
      else
        [options[:at_block_num], options[:until_block_num]]
      end
      
      loop do
        break if !!until_block_num && !!at_block_num && until_block_num < at_block_num
        
        database_api.get_dynamic_global_properties do |properties|
          current_block_num = find_block_number(properties)
          current_block_num = [current_block_num, until_block_num].compact.min
          at_block_num ||= current_block_num
          
          if current_block_num >= at_block_num
            range = at_block_num..current_block_num
            
            if object == :block_numbers
              range.each do |n|
                block.call n
                block_interval = BLOCK_INTERVAL
              end
            else
              block_api.send(object_method, block_range: range) do |b, n|
                block.call b, n
                block_interval = BLOCK_INTERVAL
              end
            end
            
            at_block_num = range.max + 1
          else
            # The stream has stalled, so let's back off and let the node sync
            # up.  We'll catch up with a bigger batch in the next cycle.
            block_interval = [block_interval * 2, MAX_BACKOFF_BLOCK_INTERVAL].min
          end
        end
        
        sleep block_interval
      end
    end
    
    # @private
    def find_block_number(properties)
      block_num = case mode
      when :head then properties.head_block_number
      when :irreversible then properties.last_irreversible_block_num
      else; raise Steem::ArgumentError, "Unknown mode: #{mode}"
      end
      
      block_num
    end
    
    # @private
    def transform_types(types)
      [types].compact.flatten.map do |type|
        type = type.to_s
        
        unless type.end_with? '_operation'
          warn "Op type #{type} is deprecated.  Use #{type}_operation instead." unless @no_warn
          type += '_operation'
        end
        
        type
      end
    end
    
    # @private
    def get_virtual_ops(types, block_num, block)
      retries = 0
      
      loop do
        get_ops_in_block_options = case account_history_api
        when Steem::CondenserApi
          [block_num, true]
        when Steem::AccountHistoryApi
          {
            block_num: block_num,
            only_virtual: true
          }
        end
        
        response = account_history_api.get_ops_in_block(*get_ops_in_block_options)
        result = response.result
        
        if result.nil?
          if retries < MAX_RETRY_COUNT
            warn "Retrying get_ops_in_block on block #{block_num}" unless @no_warn
            retries = retries + 1
            sleep 9
            redo
          else
            raise TooManyRetriesError, "unable to get valid result while finding virtual operations for block: #{block_num}"
          end
        end
        
        ops = case account_history_api
        when Steem::CondenserApi
          result.map do |trx|
            op = {type: trx.op[0] + '_operation', value: trx.op[1]}
            op = Hashie::Mash.new(op)
          end
        when Steem::AccountHistoryApi then result.ops.map { |trx| trx.op }
        end
        
        if ops.empty?
          if retries < MAX_RETRY_COUNT
            sleep 3
            retries = retries + 1
            redo
          else
            raise TooManyRetriesError, "unable to find virtual operations for block: #{block_num}"
          end
        end
        
        ops.each do |op|
          next if types.any? && !types.include?(op.type)
          
          block.call op, VOP_TRX_ID, block_num
        end
        
        break
      end
    end
  end
end