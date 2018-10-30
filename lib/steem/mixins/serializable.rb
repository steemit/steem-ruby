module Steem
  module Serializable
    KNOWN_TYPES = %i(unsigned_char uint16 uint32 uint64 signed_char int16 int32
      int64 boolean varint string raw_bytes point_in_time public_key amount
      price authority optional_authority comment_options_extensions
      beneficiaries chain_properties required_auths witness_properties
      empty_array lambda)
    
    module ClassMethods
      def def_attr key_pair
        name = key_pair.keys.first
        type = key_pair.values.first
        
        self.attributes ||= []
        self.attributes << name
        
        attr_accessor *attributes
        add_type name, type
      end
      
      def add_type name, type
        raise "Unknown type: #{type}" unless KNOWN_TYPES.include? type
        
        @serializable_types ||= {}
        @serializable_types[name] = type
      end
      
      def serializable_types
        @serializable_types
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
