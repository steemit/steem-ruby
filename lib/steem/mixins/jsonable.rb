module Steem
  module JSONable
    module ClassMethods
      attr_accessor :attributes

      def attr_accessor *attrs
        self.attributes = Array attrs
        
        super
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def as_json options = {}
      serialized = Hash.new
      
      self.class.attributes.each do |attribute|
        if !!(value = self.public_send attribute)
          serialized[attribute] = value
        end
      end
      
      serialized
    end

    def to_json *a
      as_json.to_json *a
    end
  end
end
