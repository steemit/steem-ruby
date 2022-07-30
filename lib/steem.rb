# encoding: UTF-8
require 'json' unless defined?(JSON)
require 'net/https'

require 'hashie'
require 'steem/version'
require 'steem/utils'
require 'steem/base_error'
require 'steem/mixins/serializable'
require 'steem/mixins/jsonable'
require 'steem/mixins/retriable'
require 'steem/chain_config'
require 'steem/type/base_type'
require 'steem/type/amount'
require 'steem/operation'
require 'steem/operation/account_create.rb'
require 'steem/operation/account_create_with_delegation.rb'
require 'steem/operation/account_update.rb'
require 'steem/operation/account_witness_proxy.rb'
require 'steem/operation/account_witness_vote.rb'
require 'steem/operation/cancel_transfer_from_savings.rb'
require 'steem/operation/challenge_authority.rb'
require 'steem/operation/change_recovery_account.rb'
require 'steem/operation/claim_account.rb'
require 'steem/operation/claim_reward_balance.rb'
require 'steem/operation/comment.rb'
require 'steem/operation/comment_options.rb'
require 'steem/operation/convert.rb'
require 'steem/operation/create_claimed_account.rb'
require 'steem/operation/custom.rb'
require 'steem/operation/custom_binary.rb'
require 'steem/operation/custom_json.rb'
require 'steem/operation/decline_voting_rights.rb'
require 'steem/operation/delegate_vesting_shares.rb'
require 'steem/operation/delete_comment.rb'
require 'steem/operation/escrow_approve.rb'
require 'steem/operation/escrow_dispute.rb'
require 'steem/operation/escrow_release.rb'
require 'steem/operation/escrow_transfer.rb'
require 'steem/operation/feed_publish.rb'
require 'steem/operation/limit_order_cancel.rb'
require 'steem/operation/limit_order_create.rb'
require 'steem/operation/limit_order_create2.rb'
require 'steem/operation/prove_authority.rb'
require 'steem/operation/recover_account.rb'
require 'steem/operation/report_over_production.rb'
require 'steem/operation/request_account_recovery.rb'
require 'steem/operation/reset_account.rb'
require 'steem/operation/set_reset_account.rb'
require 'steem/operation/set_withdraw_vesting_route.rb'
require 'steem/operation/transfer.rb'
require 'steem/operation/transfer_from_savings.rb'
require 'steem/operation/transfer_to_savings.rb'
require 'steem/operation/transfer_to_vesting.rb'
require 'steem/operation/vote.rb'
require 'steem/operation/withdraw_vesting.rb'
require 'steem/operation/witness_update.rb'
require 'steem/operation/witness_set_properties.rb'
require 'steem/marshal'
require 'steem/transaction'
require 'steem/transaction_builder'
require 'steem/rpc/base_client'
require 'steem/rpc/http_client'
require 'steem/rpc/thread_safe_http_client'
require 'steem/api'
require 'steem/jsonrpc'
require 'steem/block_api'
require 'steem/formatter'
require 'steem/broadcast'
require 'steem/stream'

module Steem
  def self.api_classes
    @api_classes ||= {}
  end
  
  def self.const_missing(api_name)
    api = api_classes[api_name]
    api ||= Api.clone(freeze: false) rescue Api.clone
    api.api_name = api_name
    api_classes[api_name] = api
  end
end

Hashie.logger = Logger.new(ENV['HASHIE_LOGGER'])
