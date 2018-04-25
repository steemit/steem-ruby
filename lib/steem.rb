# encoding: UTF-8
require 'hashie'
require 'steem/version'
require 'steem/utils'
require 'steem/chain_config'
require 'steem/base_error'
require 'steem/transaction_builder'
require 'steem/api'
require 'steem/jsonrpc'
require 'steem/block_api'
require 'steem/formatter'
require 'steem/broadcast'

require 'json' unless defined?(JSON)

module Steem
  def self.api_classes
    @api_classes ||= {}
  end
  
  def self.const_missing(api_name)
    api = api_classes[api_name]
    api ||= Api.clone(freeze: true)
    api.api_name = api_name
    api_classes[api_name] = api
  end
end

Hashie.logger = Logger.new(ENV['HASHIE_LOGGER'])
