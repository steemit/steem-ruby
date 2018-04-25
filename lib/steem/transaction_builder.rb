module Steem
  class TransactionBuilder
    include ChainConfig
    include Utils
    
    attr_accessor :database_api, :block_api, :wif, :operations
    
    def initialize(options = {})
      @database_api = options[:database_api] || Steem::DatabaseApi.new(options)
      @block_api = options[:block_api] || Steem::BlockApi.new(options)
      @wif = options[:wif]
      @ref_block_num = options[:ref_block_num]
      @ref_block_prefix = options[:ref_block_prefix]
      @expiration = nil
      @operations = options[:operations] || []
      @extensions = []
      @signatures = []
      @chain = options[:chain] || :steem
      @chain_id = case @chain
      when :steem then NETWORKS_STEEM_CHAIN_ID
      when :test then NETWORKS_TEST_CHAIN_ID
      else; raise "Unsupported chain: #{@chain}"
      end
    end
    
    def inspect
      properties = %w(
        ref_block_num ref_block_prefix expiration operations
        extensions signatures
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
      
      self
    end
    
    def expired?
      @expiration.nil? || @expiration < Time.now
    end
    
    def prepare
      if expired?
        @database_api.get_dynamic_global_properties do |properties|
          block_number = properties.last_irreversible_block_num
          
          @block_api.get_block_header(block_num: block_number) do |result, error|
            raise "Unable to prepare transaction: #{error}" if !!error
            
            header = result.header
            @ref_block_num = (block_number - 1) & 0xFFFF
            @ref_block_prefix = unhexlify(header.previous[8..-1]).unpack('V*')[0]
            @expiration = (Time.parse(properties.time + 'Z') + EXPIRE_IN_SECS).utc
          end
        end
      end
      
      self
    end
    
    def put(type, op = nil)
      @expiration = nil
      
      case type
      when Symbol then @operations << [type, op]
      when String then @operations << [type.to_sym, op]
      when Hash then @operations << [type.keys.first.to_sym, type.values.first]
      when Array then @operations << type
      else
        # don't know what to do with it, skipped
      end
      
      prepare
      
      self
    end
    
    def transaction
      prepare
      sign
    end
    
    def sign
      return self unless !!@wif
      
      trx = {
        ref_block_num: @ref_block_num,
        ref_block_prefix: @ref_block_prefix, 
        expiration: @expiration.strftime('%Y-%m-%dT%H:%M:%S'),
        extensions: @extensions,
        operations: @operations,
        signatures: @signatures
      }
      
      @database_api.get_transaction_hex(trx: trx) do |result|
        hex = @chain_id + result.hex[0..-4] # Why do we have to chop the last two bytes?
        digest = unhexlify(hex)
        digest_hex = Digest::SHA256.digest(digest)
        private_key = Bitcoin::Key.from_base58 @wif
        public_key_hex = private_key.pub
        ec = Bitcoin::OpenSSL_EC
        count = 0
        sig = nil
        
        loop do
          count += 1
          STDERR.puts "#{count} attempts to find canonical signature" if count % 40 == 0
          sig = ec.sign_compact(digest_hex, private_key.priv, public_key_hex, false)
          
          next if public_key_hex != ec.recover_compact(digest_hex, sig)
          break if canonical? sig
        end
        
        trx[:signatures] = @signatures = [hexlify(sig)]
      end
      
      trx
    end
    
    def potential_signatures
      @database_api.get_potential_signatures(trx: transaction) do |result|
        result[:keys]
      end
    end
    
    def required_signatures
      @database_api.get_required_signatures(trx: transaction) do |result|
        result[:keys]
      end
    end
    
    def valid?
      @database_api.verify_authority(trx: transaction) do |result|
        result.valid
      end
    end
  private
    # See: https://github.com/steemit/steem/issues/1944
    def canonical?(sig)
      sig = sig.unpack('C*')
      
      !(
        ((sig[0] & 0x80 ) != 0) || ( sig[0] == 0 ) ||
        ((sig[1] & 0x80 ) != 0) ||
        ((sig[32] & 0x80 ) != 0) || ( sig[32] == 0 ) ||
        ((sig[33] & 0x80 ) != 0)
      )
    end
  end
end
