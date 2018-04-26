require 'bitcoin'
require 'digest'
require 'time'

module Steem
  class Broadcast
    include Utils
    
    def self.vote(options = {}, &block)
      tx = TransactionBuilder.new(options)
      
      tx.put(:vote, {
          voter: options[:voter],
          author: options[:author],
          permlink: options[:permlink],
          weight: options[:weight]
        }
      )
      
      result = process(options.merge(trx: tx.transaction))
      
      if !!block
        yield result
      else
        return result
      end
    end
    
    def self.comment(options = {}, &block)
      raise 'author: required' if options[:author].nil?
      raise 'body: required' if options[:body].nil?
      raise 'permlink: required' if options[:permlink].nil?
      
      tx = TransactionBuilder.new(options)
      metadata = (options[:json_metadata] rescue nil) || {}
      metadata['app'] ||= Steem::AGENT_ID
      tags = metadata['tags'] || []
      parent_permlink = options[:parent_permlink] || tags.first
      
      raise "parent_permlink: required" if parent_permlink.nil?
      
      tx.put(
        operations: [
          [:comment, {
            parent_author: options[:parent_author] || '',
            parent_permlink: options[:parent_permlink],
            author: options[:author],
            permlink: options[:permlink],
            title: options[:title] || '',
            body: options[:body],
            json_metadata: metadata.to_json
          }
        ]]
      )
      
      result = process(options.merge(trx: tx.transaction))
      
      if !!block
        yield result
      else
        return result
      end
    end
    
    def self.process(options = {}, &block)
      network_broadcast_api = options[:network_broadcast_api] = Steem::NetworkBroadcastApi.new
      trx = options[:trx]
      
      network_broadcast_api.broadcast_transaction_synchronous(trx: trx) do |result, error|
        if !!block
          yield result, error
        else
          return result || error
        end
      end
    end
  end
end
