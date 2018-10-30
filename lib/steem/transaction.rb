module Steem
  class Transaction
    include JSONable
    include Utils
    
    ATTRIBUTES = %i(id ref_block_num ref_block_prefix expiration operations
      extensions signatures)
    
    attr_accessor *ATTRIBUTES
    
    def initialize(options = {})
      if !!(hex = options.delete(:hex))
        marshal = Marshal.new(hex: hex)
        marshal.transaction(trx: self)
      end
      
      options.each do |k, v|
        raise Steem::ArgumentError, "Invalid option specified: #{k}" unless ATTRIBUTES.include?(k.to_sym)

        send("#{k}=", v)
      end
      
      self.operations ||= []
      self.extensions ||= []
      self.signatures ||= []
      
      self.expiration = case @expiration
      when String then Time.parse(@expiration + 'Z')
      else; @expiration
      end
    end
    
    def inspect
      properties = ATTRIBUTES.map do |prop|
        if !!(v = instance_variable_get("@#{prop}"))
          "@#{prop}=#{v}" 
        end
      end.compact.join(', ')
      
      "#<#{self.class.name} [#{properties}]>"
    end
    
    def expiration
      if @expiration.respond_to? :strftime
        @expiration.strftime('%Y-%m-%dT%H:%M:%S')
      else
        @expiration
      end
    end
    
    def expired?
      @expiration.nil? || @expiration < Time.now
    end
    
    def [](key)
      key = key.to_sym
      send(key) if self.class.attributes.include?(key)
    end

    def []=(key, value)
      key = key.to_sym
      send("#{key}=", value) if self.class.attributes.include?(key)
    end
    
    def ==(other_trx)
      begin
        return false if self[:ref_block_num].to_i != other_trx[:ref_block_num].to_i
        return false if self[:ref_block_prefix].to_i != other_trx[:ref_block_prefix].to_i
        return false if self[:expiration].to_i != other_trx[:expiration].to_i
        return false if self[:operations].size != other_trx[:operations].size
        
        vals = self[:operations].sort.map do |k, v|
          v.values.join.gsub(/[^a-zA-Z0-9]/, '')
        end.join

        ovals = other_trx[:operations].sort.map do |k, v|
          v.values.join.gsub(/[^a-zA-Z0-9]/, '')
        end.join
        # binding.pry if vals != ovals
        return vals == ovals
      rescue
        false
      end
    end
  end
end
