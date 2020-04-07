require 'bindata'
require 'base58'

module Steem
  class Marshal
    include Utils
    include ChainConfig
    
    PUBLIC_KEY_DISABLED = '1111111111111111111111111111111114T1Anm'
    
    attr_reader :bytes, :cursor

    def initialize(options = {})
      @bytes = if !!(hex = options[:hex])
        unhexlify hex
      else
        options[:bytes]
      end
      
      @chain = options[:chain] || :steem
      @prefix ||= case @chain
      when :steem then NETWORKS_STEEM_ADDRESS_PREFIX
      when :test then NETWORKS_TEST_ADDRESS_PREFIX
      when :hive then NETWORKS_HIVE_ADDRESS_PREFIX
      else; raise UnsupportedChainError, "Unsupported chain: #{@chain}"
      end
      @cursor = 0
    end
    
    def hex
      hexlify bytes
    end
    
    def rewind!
      @cursor = 0
    end
    
    def step(n = 0)
      @cursor += n
    end
    
    def scan(len)
      bytes.slice(@cursor..(@cursor - 1) + len).tap { |_| @cursor += len }
    end
    
    def operation_type
      Operation::IDS[unsigned_char]
    end
    
    def unsigned_char; BinData::Uint8le.read(scan(1)); end # 8-bit unsigned 
    def uint16; BinData::Uint16le.read(scan(2)); end # 16-bit unsigned, VAX (little-endian) byte order
    def uint32; BinData::Uint32le.read(scan(4)); end # 32-bit unsigned, VAX (little-endian) byte order
    def uint64; BinData::Uint64le.read(scan(8)); end # 64-bit unsigned, little-endian

    def signed_char; BinData::Int8le.read(scan(1)); end # 8-bit signed 
    def int16; BinData::Int16le.read(scan(2)); end # 16-bit signed, little-endian
    def int32; BinData::Int32le.read(scan(4)); end # 32-bit signed, little-endian
    def int64; BinData::Int64le.read(scan(8)); end # 64-bit signed, little-endian

    def boolean; scan(1) == "\x01"; end
    
    def varint
      shift = 0
      result = 0
      bytes = []
      
      while (n = unsigned_char) >> 7 == 1
        bytes << n
      end
      
      bytes << n
      
      bytes.each do |b|
        result += ((b & 0x7f) << shift)
        break unless (b & 0x80)
        shift += 7
      end
      
      result
    end
    
    def string(len = nil); scan(len || varint); end
    
    def raw_bytes(len = nil); scan(len || varint).force_encoding('BINARY'); end
  
    def point_in_time
      if (time = uint32) == 2**32-1
        Time.at -1
      else
        Time.at time
      end.utc
    end
    
    def public_key(prefix = @prefix)
      raw_public_key = raw_bytes(33)
      checksum = OpenSSL::Digest::RIPEMD160.digest(raw_public_key)
      key = Base58.binary_to_base58(raw_public_key + checksum.slice(0, 4), :bitcoin)
      
      prefix + key unless key == PUBLIC_KEY_DISABLED
    end
    
    def amount
      amount = uint64.to_f
      precision = signed_char
      asset = scan(7).strip
      
      amount = "%.#{precision}f #{asset}" % (amount / 10 ** precision)

      Steem::Type::Amount.new(amount, :chain)
    end
    
    def price
      {base: amount, quote: amount}
    end
    
    def authority(options = {optional: false})
      return if !!options[:optional] && unsigned_char == 0
      
      {
        weight_threshold: uint32,
        account_auths: varint.times.map { [string, uint16] },
        key_auths: varint.times.map { [public_key, uint16] }
      }
    end
    
    def optional_authority
      authority(optional: true)
    end
    
    def comment_options_extensions
      if scan(1) == "\x01"
        beneficiaries
      else
        []
      end
    end
    
    def beneficiaries
      if scan(1) == "\x00"
        varint.times.map {{account: string, weight: uint16}}
      end
    end
    
    def chain_properties
      {
        account_creation_fee: amount,
        maximum_block_size: uint32,
        sbd_interest_rate: uint16
      }
    end
    
    def required_auths
      varint.times.map { string }
    end
    
    def witness_properties
      properties = {}
      
      varint.times do
        key = string.to_sym
        properties[key] = case key
                          when :account_creation_fee then Steem::Type::Amount.new(string, :chain)
        when :account_subsidy_budget then scan(3)
        when :account_subsidy_decay, :maximum_block_size then uint32
        when :url then string
        when :sbd_exchange_rate
          JSON[string].tap do |rate|
            rate["base"] = Steem::Type::Amount.new(rate["base"], :chain)
            rate["quote"] = Steem::Type::Amount.new(rate["quote"], :chain)
          end
        when :sbd_interest_rate then uint16
        when :key, :new_signing_key then @prefix + scan(50)
        else; raise "Unknown witness property: #{key}"
        end
      end
      
      properties
    end
    
    def empty_array
      unsigned_char == 0 and [] or raise "Found non-empty array."
    end
    
    def transaction(options = {})
      trx = options[:trx] || Transaction.new
      
      trx.ref_block_num = uint16
      trx.ref_block_prefix = uint32
      trx.expiration = point_in_time
      
      trx.operations = operations
      
      trx
    rescue => e
      raise DeserializationError.new("Transaction failed\nOriginal serialized bytes:\n[#{hex[0..(@cursor * 2) - 1]}]#{hex[((@cursor) * 2)..-1]}", e)
    end

    def operations
      operations_len = signed_char
      operations = []
      
      while operations.size < operations_len do
        begin
          type = operation_type
          break if type.nil?
          
          op_class_name = type.to_s.sub!(/_operation$/, '')
          op_class_name = "Steem::Operation::" + op_class_name.split('_').map(&:capitalize).join
          op_class = Object::const_get(op_class_name)
          op = op_class.new
          
          op_class::serializable_types.each do |k, v|
            begin
              # binding.pry if v == :comment_options_extensions
              op.send("#{k}=", send(v))
            rescue => e
              raise DeserializationError.new("#{type}.#{k} (#{v}) failed", e)
            end
          end
          
          operations << {type: type, value: op}
        rescue => e
          raise DeserializationError.new("#{type} failed", e)
        end
      end
      
      operations
    rescue => e
      raise DeserializationError.new("Operations failed", e)
    end
  end
end
