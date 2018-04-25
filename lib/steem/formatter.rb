module Steem
  class Formatter
    def self.reputation(raw)
      raw = raw.to_i
      neg = raw < 0
      level = Math.log10(raw.abs)
      level = [level - 9, 0].max
      level = (neg ? -1 : 1) * level
      level = (level * 9) + 25
      
      level.round(1)
    end
  end
end
