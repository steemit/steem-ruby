module Steem
  module Type
    
    # See: https://github.com/xeroc/piston-lib/blob/34a7525cee119ec9b24a99577ede2d54466fca0e/steembase/operations.py
    class Amount < BaseType
      attr_reader :amount, :precision, :nai, :asset
      
      def self.to_h(amount)
        new(amount).to_h
      end
      
      def self.to_s(amount)
        new(amount).to_s
      end
      
      def initialize(value)
        super(:amount, value)
        
        case value
        when Array
          @amount, @precision, @nai = value
          @asset = case @nai
          when '@@000000013' then 'SBD'
          when '@@000000021' then 'STEEM'
          when '@@000000037' then 'VESTS'
          else; raise TypeError, "Asset #{@nai} unknown."
          end
          
          @amount = "%.#{@precision}f" % (@amount.to_f / 10 ** @precision)
        when Hash
          @amount, @precision, @nai = value.map do |k, v|
            v if %i(amount precision nai).include? k.to_sym
          end.compact
          
          @asset = case @nai
          when '@@000000013' then 'SBD'
          when '@@000000021' then 'STEEM'
          when '@@000000037' then 'VESTS'
          else; raise TypeError, "Asset #{@nai} unknown."
          end
          
          @amount = "%.#{@precision}f" % (@amount.to_f / 10 ** @precision)
        when Amount
          @precision = value.precision
          @nai = value.nai
          @asset = value.asset
          @amount = value.amount
        else
          @amount, @asset = value.strip.split(' ') rescue ['', '']
          @precision = case @asset
          when 'STEEM' then 3
          when 'VESTS' then 6
          when 'SBD' then 3
          else; raise TypeError, "Asset #{@asset} unknown."
          end
        end
      end
      
      def to_bytes
        asset = @asset.ljust(7, "\x00")
        amount = (@amount.to_f * 10 ** @precision).round
        
        [amount].pack('q') +
        [@precision].pack('c') +
        asset
      end
      
      def to_a
        case @asset
        when 'STEEM' then [(@amount.to_f * 1000).to_i.to_s, 3, '@@000000021']
        when 'VESTS' then [(@amount.to_f * 1000000).to_i.to_s, 6, '@@000000037']
        when 'SBD' then [(@amount.to_f * 1000).to_i.to_s, 3, '@@000000013']
        end
      end
      
      def to_h
        case @asset
        when 'STEEM' then {
          amount: (@amount.to_f * 1000).to_i.to_s,
          precision: 3,
          nai: '@@000000021'
        }
        when 'VESTS' then {
          amount: (@amount.to_f * 1000000).to_i.to_s,
          precision: 6,
          nai: '@@000000037'
        }
        when 'SBD' then {
          amount: (@amount.to_f * 1000).to_i.to_s,
          precision: 3,
          nai: '@@000000013'
        }
        end
      end
      
      def to_s
        "#{@amount} #{@asset}"
      end
    end
  end
end
