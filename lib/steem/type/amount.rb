require 'steem/chain_config'

module Steem
  module Type
    # See: https://github.com/xeroc/piston-lib/blob/34a7525cee119ec9b24a99577ede2d54466fca0e/steembase/operations.py
    class Amount < BaseType
      
      ##
      # information on a single coins available.
      #
      class Coin_Info
        attr_reader :symbol, :nai, :precision

        def initialize(symbol, nai, precision)
          @symbol    = symbol
          @nai       = nai
          @precision = precision
        end
      end

      ##
      # information on the coins of a one chain
      #
      class Chain_Info
        attr_reader :core, :debt, :vest

        def initialize(core, debt, vest)
          @core = core
          @debt = debt
          @vest = vest
        end
      end

      attr_reader :amount, :precision, :nai, :asset, :chain
      private_constant :Coin_Info
      private_constant :Chain_Info

      def initialize(value, chain)
        super(:amount, value)

        _chain_info = @@chain_infos[chain]

        raise ArgumentError, "Chain info for chain «" + chain.to_s + "» not found." if _chain_info == nil

        case value
        when Array
          @chain = chain
          @amount, @precision, @nai = value
          @asset = case @nai
          when _chain_info.core.nai then _chain_info.core.symbol
          when _chain_info.debt.nai then _chain_info.debt.symbol
          when _chain_info.vest.nai then _chain_info.vest.symbol
          else; raise TypeError, "Asset #{@nai} unknown."
          end

          @amount = "%.#{@precision}f" % (@amount.to_f / 10 ** @precision)
        when Hash
          @chain = chain
          @amount, @precision, @nai = value.map do |k, v|
            v if %i(amount precision nai).include? k.to_sym
          end.compact
          @asset = case @nai
          when _chain_info.core.nai then _chain_info.core.symbol
          when _chain_info.debt.nai then _chain_info.debt.symbol
          when _chain_info.vest.nai then _chain_info.vest.symbol
          else; raise TypeError, "Asset #{@nai} unknown."
          end

          @amount = "%.#{@precision}f" % (@amount.to_f / 10 ** @precision)
        when Amount
          @chain = value.chain
          @precision = value.precision
          @nai = value.nai
          @asset = value.asset
          @amount = value.amount
        else
          @chain = chain
          @amount, @asset = value.strip.split(' ') rescue ['', '']
          @precision , @nai = case @asset
          when _chain_info.core.symbol then [_chain_info.core.precision, _chain_info.core.nai]
          when _chain_info.debt.symbol then [_chain_info.debt.precision, _chain_info.debt.nai]
          when _chain_info.vest.symbol then [_chain_info.vest.precision, _chain_info.vest.nai]
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
        _chain_info = @@chain_infos[chain]

        case @asset
        when _chain_info.core.symbol then [
          (@amount.to_f * 10 ** _chain_info.core.precision).to_i.to_s,
          _chain_info.core.precision,
          _chain_info.core.nai
        ]
        when _chain_info.debt.symbol then [
          (@amount.to_f * 10 ** _chain_info.debt.precision).to_i.to_s,
          _chain_info.debt.precision,
          _chain_info.debt.nai
        ]
        when _chain_info.vest.symbol then [
          (@amount.to_f * 10 ** _chain_info.vest.precision).to_i.to_s,
          _chain_info.vest.precision,
          _chain_info.vest.nai
        ]
        else; raise TypeError, "Asset #{@asset} unknown."
        end
      end

      def to_h
        _chain_info = @@chain_infos[chain]

        case @asset
        when _chain_info.core.symbol then {
          amount:    (@amount.to_f * 10 ** _chain_info.core.precision).to_i.to_s,
          precision: _chain_info.core.precision,
          nai:       _chain_info.core.nai
        }
        when _chain_info.debt.symbol then {
          amount:    (@amount.to_f * 10 ** _chain_info.debt.precision).to_i.to_s,
          precision: _chain_info.debt.precision,
          nai:       _chain_info.debt.nai
        }
        when _chain_info.vest.symbol then {
          amount:    (@amount.to_f * 10 ** _chain_info.vest.precision).to_i.to_s,
          precision: _chain_info.vest.precision,
          nai:       _chain_info.vest.nai
        }
        else; raise TypeError, "Asset #{@asset} unknown."
        end
      end

      def to_s
        "#{@amount} #{@asset}"
      end

      ##
      # return amount as float to be used for calculations
      #
      # @return [Float]
      #     actual amount as float
      #
      def to_f
        return @amount.to_f
      end

      class << self
        ##
        # information on all coins of all chain.
        #
        @@chain_infos = {
           steem: Chain_Info.new(
              core = Coin_Info.new(
                 symbol    = Steem::ChainConfig::NETWORKS_STEEM_CORE_SYMBOL,
                 nai       = Steem::ChainConfig::NETWORKS_STEEM_CORE_ASSET[2],
                 precision = Steem::ChainConfig::NETWORKS_STEEM_CORE_ASSET[1]
              ),
              debt = Coin_Info.new(
                 symbol    = Steem::ChainConfig::NETWORKS_STEEM_DEBT_SYMBOL,
                 nai       = Steem::ChainConfig::NETWORKS_STEEM_DEBT_ASSET[2],
                 precision = Steem::ChainConfig::NETWORKS_STEEM_DEBT_ASSET[1]
              ),
              vest = Coin_Info.new(
                 symbol    = Steem::ChainConfig::NETWORKS_STEEM_VEST_SYMBOL,
                 nai       = Steem::ChainConfig::NETWORKS_STEEM_VEST_ASSET[2],
                 precision = Steem::ChainConfig::NETWORKS_STEEM_VEST_ASSET[1]
              )
           ),
           test: Chain_Info.new(
              core = Coin_Info.new(
                 symbol    = Steem::ChainConfig::NETWORKS_TEST_CORE_SYMBOL,
                 nai       = Steem::ChainConfig::NETWORKS_TEST_CORE_ASSET[2],
                 precision = Steem::ChainConfig::NETWORKS_TEST_CORE_ASSET[1]
              ),
              debt = Coin_Info.new(
                 symbol    = Steem::ChainConfig::NETWORKS_TEST_DEBT_SYMBOL,
                 nai       = Steem::ChainConfig::NETWORKS_TEST_DEBT_ASSET[2],
                 precision = Steem::ChainConfig::NETWORKS_TEST_DEBT_ASSET[1]
              ),
              vest = Coin_Info.new(
                 symbol    = Steem::ChainConfig::NETWORKS_TEST_VEST_SYMBOL,
                 nai       = Steem::ChainConfig::NETWORKS_TEST_VEST_ASSET[2],
                 precision = Steem::ChainConfig::NETWORKS_TEST_VEST_ASSET[1]
              )
           ),
           hive: Chain_Info.new(
              core = Coin_Info.new(
                 symbol    = Steem::ChainConfig::NETWORKS_HIVE_CORE_SYMBOL,
                 nai       = Steem::ChainConfig::NETWORKS_HIVE_CORE_ASSET[2],
                 precision = Steem::ChainConfig::NETWORKS_HIVE_CORE_ASSET[1]
              ),
              debt = Coin_Info.new(
                 symbol    = Steem::ChainConfig::NETWORKS_HIVE_DEBT_SYMBOL,
                 nai       = Steem::ChainConfig::NETWORKS_HIVE_DEBT_ASSET[2],
                 precision = Steem::ChainConfig::NETWORKS_HIVE_DEBT_ASSET[1]
              ),
              vest = Coin_Info.new(
                 symbol    = Steem::ChainConfig::NETWORKS_HIVE_VEST_SYMBOL,
                 nai       = Steem::ChainConfig::NETWORKS_HIVE_VEST_ASSET[2],
                 precision = Steem::ChainConfig::NETWORKS_HIVE_VEST_ASSET[1]
              )
           )
        }

        def to_h(amount, chain)
          new(amount, chain).to_h
        end

        def to_s(amount, chain)
          new(amount, chain).to_s
        end

        def to_bytes(amount, chain)
          new(amount, chain).to_bytes
        end
      end
    end
  end
end
