module Steem
  module Utils
    def hexlify(s)
      a = []
      if s.respond_to? :each_byte
        s.each_byte { |b| a << sprintf('%02X', b) }
      else
        s.each { |b| a << sprintf('%02X', b) }
      end
      a.join.downcase
    end
    
    def unhexlify(s)
      s.split.pack('H*')
    end
  end
end
