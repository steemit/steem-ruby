require 'digest'
require 'openssl'
require 'base58'
require 'securerandom'

module Steem
  module Auth
    class Memo
      extend Utils
      
      CYPHER_COMPONENTS = 'AES-256-CBC'.freeze
      
      # @param private_key [String|Bitcoin::Key] wif or Bitcoin::Key
      # @param memo [String] plain text is returned, hash prefix base58 is decrypted
      # @return [String] utf8 decoded string (hash prefix)
      def self.decode(private_key, memo)
        return if memo.nil?
        return memo unless memo[0] == '#'
        
        private_key = case private_key
        when String then Bitcoin::Key.from_base58(private_key)
        else; private_key
        end
        
        decipher = aes(private_key.pub)
        decipher.decrypt # set decipher to be decryption mode
        decipher.update(Base58::base58_to_binary(memo[1..-1].strip, :bitcoin))# + decipher.final
      end
      
      # @param private_key [String|Bitcoin::Key] wif or Bitcoin::Key
      # @param public_key [String|Bitcoin::Key] Recipient public_key
      # @param memo [String] plain text is returned, hash prefix text is encrypted
      # @param nonce [String] for debugging
      # @return [String] base58 decoded string (or plain text)
      def self.encode(private_key, public_key, memo, nonce = nil)
        return memo if private_key.nil? || public_key.nil?
        
        private_key = case private_key
        when String then Bitcoin::Key.from_base58(private_key)
        else; private_key
        end
        
        public_key = case public_key
        when String then Bitcoin::Key.new(nil, public_key)
        else; public_key
        end
        
        cipher = aes(public_key.pub, nonce)
        cipher.encrypt # set cipher to be encryption mode
        encrypted = ''
        encrypted << cipher.update(memo)
        encrypted << cipher.final
        '#' + Base58.binary_to_base58(encrypted, :bitcoin)
      end
    
      # @abstract Subclass is expected to implement Memo#aes.
      # @!method aes
    end
  end
end
