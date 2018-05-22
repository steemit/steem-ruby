# encoding: UTF-8
require 'json' unless defined?(JSON)
require 'net/https'

require 'hashie'
require 'steem/version'
require 'steem/utils'
require 'steem/base_error'
require 'steem/mixins/retriable'
require 'steem/chain_config'
require 'steem/type/base_type'
require 'steem/type/amount'
require 'steem/transaction_builder'
require 'steem/rpc/base_client'
require 'steem/rpc/http_client'
require 'steem/rpc/thread_safe_http_client'
require 'steem/api'
require 'steem/jsonrpc'
require 'steem/block_api'
require 'steem/formatter'
require 'steem/broadcast'

module Steem
  def self.api_classes
    @api_classes ||= {}
  end
  
  def self.const_missing(api_name)
    api = api_classes[api_name]
    api ||= Api.clone(freeze: true) rescue Api.clone
    api.api_name = api_name
    api_classes[api_name] = api
  end
end

Hashie.logger = Logger.new(ENV['HASHIE_LOGGER'])
