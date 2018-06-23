module Steem
  # {TransactionBuilder} can be used to create a transaction that the
  # {NetworkBroadcastApi} can broadcast to the rest of the platform.  The main
  # feature of this class is the ability to cryptographically sign the
  # transaction so that it conforms to the consensus rules that are required by
  # the blockchain.
  #
  #     wif = '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC'
  #     builder = Steem::TransactionBuilder.new(wif: wif)
  #     builder.put(vote: {
  #       voter: 'alice',
  #       author: 'bob',
  #       permlink: 'my-burgers',
  #       weight: 10000
  #     })
  #     
  #     trx = builder.transaction
  #     network_broadcast_api = Steem::NetworkBroadcastApi.new
  #     network_broadcast_api.broadcast_transaction_synchronous(trx: trx)
  #
  #
  # The `wif` value may also be an array, when signing with multiple signatures
  # (multisig).
  class TransactionBuilder
    include Retriable
    include ChainConfig
    include Utils
    
    attr_accessor :app_base, :database_api, :block_api, :expiration, :operations
    attr_writer :wif
    attr_reader :signed
    
    alias app_base? app_base
    
    def initialize(options = {})
      @app_base = !!options[:app_base] # default false
      @database_api = options[:database_api]
      @block_api = options[:block_api]
      
      if app_base?
        @database_api ||= Steem::DatabaseApi.new(options)
        @block_api ||= Steem::BlockApi.new(options)
      else
        @database_api ||= Steem::CondenserApi.new(options)
        @block_api ||= Steem::CondenserApi.new(options)
      end
      
      @wif = [options[:wif]].flatten
      @signed = false
      
      if !!(trx = options[:trx])
        trx = case trx
        when String then JSON[trx]
        else; trx
        end
        
        trx_options = {
          ref_block_num: trx['ref_block_num'],
          ref_block_prefix: trx['ref_block_prefix'],
          extensions: (trx['extensions']),
          operations: trx['operations'],
          signatures: (trx['signatures']),
        }
        
        trx_options[:expiration] = case trx['expiration']
        when String then Time.parse(trx['expiration'] + 'Z')
        else; trx['expiration']
        end
        
        options = options.merge(trx_options)
      end
      
      @ref_block_num = options[:ref_block_num]
      @ref_block_prefix = options[:ref_block_prefix]
      @operations = options[:operations] || []
      @expiration = options[:expiration]
      @extensions = options[:extensions] || []
      @signatures = options[:signatures] || []
      @chain = options[:chain] || :steem
      @error_pipe = options[:error_pipe] || STDERR
      @chain_id = case @chain
      when :steem then NETWORKS_STEEM_CHAIN_ID
      when :test then NETWORKS_TEST_CHAIN_ID
      else; raise UnsupportedChainError, "Unsupported chain: #{@chain}"
      end
    end
    
    def inspect
      properties = %w(
        ref_block_num ref_block_prefix expiration operations extensions
        signatures
      ).map do |prop|
        if !!(v = instance_variable_get("@#{prop}"))
          "@#{prop}=#{v}" 
        end
      end.compact.join(', ')
      
      "#<#{self.class.name} [#{properties}]>"
    end
    
    def reset
      @ref_block_num = nil
      @ref_block_prefix = nil
      @expiration = nil
      @operations = []
      @extensions = []
      @signatures = []
      @signed = false
      
      self
    end
    
    def expired?
      @expiration.nil? || @expiration < Time.now
    end
    
    # If the transaction can be prepared, this method will do so and set the
    # expiration.  Once the expiration is set, it will not re-prepare.  If you
    # call {#put}, the expiration is set {::Nil} so that it can be re-prepared.
    #
    # Usually, this method is called automatically by {#put} and/or {#transaction}.
    #
    # @return {TransactionBuilder}
    def prepare
      if expired?
        catch :prepare_header do; begin
          @database_api.get_dynamic_global_properties do |properties|
            block_number = properties.last_irreversible_block_num
            block_header_args = if app_base?
              {block_num: block_number}
            else
              block_number
            end
          
            @block_api.get_block_header(block_header_args) do |result|
              header = if app_base?
                result.header
              else
                result
              end
              
              @ref_block_num = (block_number - 1) & 0xFFFF
              @ref_block_prefix = unhexlify(header.previous[8..-1]).unpack('V*')[0]
              @expiration ||= (Time.parse(properties.time + 'Z') + EXPIRE_IN_SECS).utc
            end
          end
        rescue => e
          if can_retry? e
            @error_pipe.puts "#{e} ... retrying."
            throw :prepare_header
          else
            raise e
          end
        end; end
      end
      
      self
    end
    
    # Sets operations all at once, then prepares.
    def operations=(operations)
      @operations = operations.map{ |op| normalize_operation(op) }
      prepare
      @operations
    end
    
    # A quick and flexible way to append a new operation to the transaction.
    # This method uses ducktyping to figure out how to form the operation.
    #
    # There are three main ways you can call this method.  These assume that
    # `op_type` is a {::Symbol} (or {::String}) representing the type of operation and `op` is the
    # operation {::Hash}.
    #
    #     put(op_type, op)
    #
    # ... or ...
    #
    #     put(op_type => op)
    #
    # ... or ...
    #
    #     put([op_type, op])
    #
    # You can also chain multiple operations:
    #
    #     builder = Steem::TransactionBuilder.new
    #     builder.put(vote: vote1).put(vote: vote2)
    # @return {TransactionBuilder}
    def put(type, op = nil)
      @expiration = nil
      @operations << normalize_operation(type, op)
      prepare
      self
    end
    
    # If all of the required values are set, this returns a fully formed
    # transaction that is ready to broadcast.
    # 
    # @return
    #     {
    #            :ref_block_num => 18912,
    #         :ref_block_prefix => 575781536,
    #               :expiration => "2018-04-26T15:26:12",
    #               :extensions => [],
    #               :operations => [[:vote, {
    #                    :voter => "alice",
    #                   :author => "bob",
    #                 :permlink => "my-burgers",
    #                   :weight => 10000
    #                 }
    #             ]],
    #               :signatures => ["1c45b65740b4b2c17c4bcf6bcc3f8d90ddab827d50532729fc3b8f163f2c465a532b0112ae4bf388ccc97b7c2e0bc570caadda78af48cf3c261037e65eefcd941e"]
    #     }
    def transaction
      prepare
      sign
    end
    
    # Appends to the `signatures` array of the transaction, built from a
    # serialized digest.
    #
    # @return {Hash | TransactionBuilder} The fully signed transaction if a `wif` is provided or the instance of the {TransactionBuilder} if a `wif` has not yet been provided.
    def sign
      return self if @wif.empty?
      return self if expired?
      
      trx = {
        ref_block_num: @ref_block_num,
        ref_block_prefix: @ref_block_prefix, 
        expiration: @expiration.strftime('%Y-%m-%dT%H:%M:%S'),
        operations: @operations,
        extensions: @extensions,
        signatures: @signatures
      }
      
      unless @signed
        catch :serialize do; begin
          transaction_hex_args = if app_base?
            {trx: trx}
          else
            trx
          end
          
          @database_api.get_transaction_hex(transaction_hex_args) do |result|
            hex = if app_base?
              result.hex
            else
              result
            end
            
            hex = @chain_id + hex[0..-4] # Why do we have to chop the last two bytes?
            digest = unhexlify(hex)
            digest_hex = Digest::SHA256.digest(digest)
            private_keys = @wif.map{ |wif| Bitcoin::Key.from_base58 wif }
            ec = Bitcoin::OpenSSL_EC
            count = 0
            sigs = []
            
            private_keys.each do |private_key|
              sig = nil
              
              loop do
                count += 1
                @error_pipe.puts "#{count} attempts to find canonical signature" if count % 40 == 0
                public_key_hex = private_key.pub
                sig = ec.sign_compact(digest_hex, private_key.priv, public_key_hex, false)
                
                next if public_key_hex != ec.recover_compact(digest_hex, sig)
                break if canonical? sig
              end
              
              @signatures << hexlify(sig)
            end
            
            @signed = true
            trx[:signatures] = @signatures
          end
        rescue => e
          if can_retry? e
            @error_pipe.puts "#{e} ... retrying."
            throw :serialize
          else
            raise e
          end
        end; end
      end
        
      Hashie::Mash.new trx
    end
    
    # @return [Array] All public keys that could possibly sign for a given transaction.
    def potential_signatures
      potential_signatures_args = if app_base?
        {trx: transaction}
      else
        transaction
      end
      
      @database_api.get_potential_signatures(potential_signatures_args) do |result|
        if app_base?
          result[:keys]
        else
          result
        end
      end
    end
    
    # This API will take a partially signed transaction and a set of public keys
    # that the owner has the ability to sign for and return the minimal subset
    # of public keys that should add signatures to the transaction.
    #
    # @return [Array] The minimal subset of public keys that should add signatures to the transaction.
    def required_signatures
      required_signatures_args = if app_base?
        {trx: transaction}
      else
        [transaction, []]
      end
      
      @database_api.get_required_signatures(*required_signatures_args) do |result|
        if app_base?
          result[:keys]
        else
          result
        end
      end
    end
    
    # @return [Boolean] True if the transaction has all of the required signatures.
    def valid?
      verify_authority_args = if app_base?
        {trx: transaction}
      else
        transaction
      end
      
      @database_api.verify_authority(verify_authority_args) do |result|
        if app_base?
          result.valid
        else
          result
        end
      end
    end
  private
    # See: https://github.com/steemit/steem/pull/2500
    # @private
    def canonical?(sig)
      sig = sig.unpack('C*')
      
      !(
        ((sig[0] & 0x80 ) != 0) || ( sig[0] == 0 ) ||
        ((sig[1] & 0x80 ) != 0) ||
        ((sig[32] & 0x80 ) != 0) || ( sig[32] == 0 ) ||
        ((sig[33] & 0x80 ) != 0)
      )
    end
    
    def normalize_operation(type, op = nil)
      if app_base?
        case type
        when Symbol, String
          type_value = "#{type}_operation"
          {type: type_value, value: op}
        when Hash
          type_value = "#{type.keys.first}_operation"
          {type: type_value, value: type.values.first}
        when Array
          type_value = "#{type[0]}_operation"
          {type: type_value, value: type[1]}
        else
          raise Steem::ArgumentError, "Don't know what to do with operation type #{type.class}: #{type} (#{op})"
        end
      else
        case type
        when Symbol then [type, op]
        when String then [type.to_sym, op]
        when Hash then [type.keys.first.to_sym, type.values.first]
        when Array then type
        else
          raise Steem::ArgumentError, "Don't know what to do with operation type #{type.class}: #{type} (#{op})"
        end
      end
    end
  end
end
