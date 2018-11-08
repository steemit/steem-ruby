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
        unless (value = self.public_send attribute).nil?
          serialized[attribute] = if value.respond_to? :strftime
            value.strftime('%Y-%m-%dT%H:%M:%S')
          else
            value
          end
        end
      end
      
      serialized
    end

    def to_json *a
      as_json.to_json *a
    end
  end
end
