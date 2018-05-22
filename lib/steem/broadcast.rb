require 'bitcoin'
require 'digest'
require 'time'

module Steem
  
  # These class methods make it simple to do things like broacast a {Broadcast#vote}
  # or {Broadcast#comment} operation.  They accept all of the fields expected by
  # the blockchain plus the following additional options:
  # 
  #     * wif
  #     * url (optional)
  #     * database_api (optional)
  #     * block_api (optional)
  #     * network_broadcast_api (optional)
  #     * pretend (optional)
  # 
  # These options are not sent in the broadcast.  The `wif` authorities can be
  # posting, active, and owner.
  # 
  # Setting `url` will allow you to specify a different node instead of taking
  # the default: ({ChainConfig::NETWORKS_STEEM_DEFAULT_NODE}).
  # 
  # Setting `database_api`, `block_api`, and `network_broadcast_api` is
  # optional, doing so will allow you to override the default node and/or the
  # RPC Client.
  # 
  # When passing the `pretend` field, if it is set to {::True}, nothing is
  # broadcasted, but the `wif` is checked for the proper authority.
  # 
  # For details on what to pass to these methods, check out the {https://developers.steem.io/apidefinitions/broadcast-ops Steem Developer Portal Broadcast Operations} page.
  class Broadcast
    extend Retriable
    
    DEFAULT_MAX_ACCEPTED_PAYOUT = Type::Amount.new(["1000000000", 3, "@@000000013"])
    
    # This operation is used to cast a vote on a post/comment.
    # 
    #     options = {
    #       wif: wif,
    #       params: {
    #         voter: voter,
    #         author: author,
    #         permlink: permlink,
    #         weight: weight
    #       }
    #     }
    #     
    #     Steem::Broadcast.vote(options) do |result|
    #       puts result
    #     end
    #
    # @param options [Hash] options
    # @option options [String] :wif Posting wif
    # @option options [Hash] :params
    #   * :voter (String)
    #   * :author (String)
    #   * :permlink (String)
    #   * :weight (Number)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_vote
    def self.vote(options, &block)
      required_fields = %i(voter author permlink weight)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      ops = [[:vote, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # Creates a post/comment.  This method simplifies content creation by
    # combining `comment` and `comment_options` into one transaction.
    #
    #     options = {
    #       wif: wif,
    #       params: {
    #         author: author,
    #         title: 'This is my fancy post title.',
    #         body: 'This is my fancy post body.',
    #         metadata: {
    #           tags: %w(these are my fancy tags)
    #         } 
    #       }
    #     }
    #     
    #     Steem::Broadcast.comment(options)
    #
    #     options = {
    #       wif: wif,
    #       params: {
    #         author: author,
    #         title: 'This is my fancy post title.',
    #         body: 'This is my fancy post body.',
    #         metadata: {
    #           tags: %w(these are my fancy tags)
    #         },
    #         beneficiaries: [
    #           {account: "david", weight: 500},
    #           {account: "erin", weight: 500},
    #           {account: "faythe", weight: 1000},
    #           {account: "frank", weight: 500}
    #         ]
    #       }
    #     }
    #     
    #     Steem::Broadcast.comment(options)
    # 
    # In addition to the above denormalized `comment_options` fields, the author
    # can also vote for the content in the same transaction by setting `author_vote_weight`:
    # 
    #     options = {
    #       wif: wif,
    #       params: {
    #         author: author,
    #         title: 'This is my fancy post title.',
    #         body: 'This is my fancy post body.',
    #         metadata: {
    #           tags: %w(these are my fancy tags)
    #         },
    #         author_vote_weight: 10000
    #       }
    #     }
    #     
    #     Steem::Broadcast.comment(options)
    #
    # @param options [Hash] options
    # @option options [String] :wif Posting wif
    # @option options [Hash] :params
    #   * :author (String)
    #   * :title (String) Title of the content.
    #   * :body (String) Body of the content.
    #   * :metadata (Hash) Metadata of the content, becomes `json_metadata`.
    #   * :json_metadata (String) String version of `metadata` (use one or the other).
    #   * :permlink (String) (automatic) Permlink of the content, defaults to formatted title.
    #   * :parent_permlink (String) (automatic) Parent permlink of the content, defaults to first tag.
    #   * :parent_author (String) (optional) Parent author of the content (only used if reply).
    #   * :max_accepted_payout (String) (1000000.000 SBD) Maximum accepted payout, set to '0.000 SBD' to deline payout
    #   * :percent_steem_dollars (Numeric) (5000) Percent STEEM Dollars is used to set 50/50 or 100% STEEM Power
    #   * :allow_votes (Numeric) (true) Allow votes for this content.
    #   * :allow_curation_rewards (Numeric) (true) Allow curation rewards for this content.
    #   * :beneficiaries (Array<Hash>) Sets the beneficiaries of this content.
    #   * :author_vote_weight (Number) (optional) Cast a vote by the author in the same transaction.
    #   * :pretend (Boolean) Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_comment
    def self.comment(options, &block)
      required_fields = %i(author body permlink parent_permlink)
      params = options[:params]
      
      if !!params[:metadata] && !!params[:json_metadata]
        raise Steem::ArgumentError, 'Assign either metadata or json_metadata, not both.'
      end
      
      metadata = params[:metadata] || {}
      metadata ||= (JSON[params[:json_metadata]] || nil) || {}
      metadata['app'] ||= Steem::AGENT_ID
      tags = metadata['tags'] || []
      params[:parent_permlink] ||= tags.first
      
      if !!params[:title]
        params[:permlink] ||= params[:title].downcase.gsub(/[^a-z0-9\-]+/, '-')
      end
      
      check_required_fields(params, *required_fields)
      
      ops = [[:comment, {
        parent_author: params[:parent_author] || '',
        parent_permlink: params[:parent_permlink],
        author: params[:author],
        permlink: params[:permlink],
        title: params[:title] || '',
        body: params[:body],
        json_metadata: metadata.to_json
      }]]
      
      max_accepted_payout = if params.keys.include? :max_accepted_payout
        Type::Amount.to_nia(params[:max_accepted_payout])
      else
        DEFAULT_MAX_ACCEPTED_PAYOUT.to_nia
      end
      
      allow_votes = if params.keys.include? :allow_votes
        !!params[:allow_votes]
      else
        true
      end
      
      allow_curation_rewards = if params.keys.include? :allow_curation_rewards
        !!params[:allow_curation_rewards]
      else
        true
      end
      
      comment_options = {
        author: params[:author],
        permlink: params[:permlink],
        max_accepted_payout: max_accepted_payout,
        percent_steem_dollars: params[:percent_steem_dollars] || 10000,
        allow_votes: allow_votes,
        allow_curation_rewards: allow_curation_rewards,
        extensions: []
      }
      
      if !!params[:beneficiaries]
        comment_options[:extensions] << [0, {beneficiaries: params[:beneficiaries]}]
      end
      
      ops << [:comment_options, comment_options]
      
      if !!params[:author_vote_weight]
        author_vote = {
          voter: params[:author],
          author: params[:author],
          permlink: params[:permlink],
          weight: params[:author_vote_weight]
        }
        
        ops << [:vote, author_vote]
      end
      
      process(options.merge(ops: ops), &block)
    end
    
    # Deletes a post/comment.
    # 
    #     Steem::Broadcast.delete_comment(wif: wif, params: {author: author, permlink: permlink}) do |result|
    #       puts result
    #     end
    # 
    # @param options [Hash] options
    # @option options [String] :wif Posting wif
    # @option options [Hash] :params
    #   * :author (String)
    #   * :permlink (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_delete_comment
    def self.delete_comment(options, &block)
      required_fields = %i(author permlink)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      ops = [[:delete_comment, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # Transfers asset from one account to another.
    # 
    #     options = {
    #       wif: wif,
    #       params: {
    #         from: from,
    #         to: to,
    #         amount: amount,
    #         memo: memo
    #       }
    #     }
    #     
    #     Steem::Broadcast.transfer(options) do |result|
    #       puts result
    #     end
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :from (String)
    #   * :to (String)
    #   * :amount (String)
    #   * :memo (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_transfer
    def self.transfer(options, &block)
      required_fields = %i(from to amount memo)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      params[:amount] = Type::Amount.to_nia(params[:amount])
      
      ops = [[:transfer, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # This operation converts STEEM into VFS (Vesting Fund Shares) at the
    # current exchange rate.
    # 
    #     options = {
    #       wif: wif,
    #       params: {
    #         from: from,
    #         to: to,
    #         amount: amount,
    #       }
    #     }
    #     
    #     Steem::Broadcast.transfer_to_vesting(options) do |result|
    #       puts result
    #     end
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :from (String)
    #   * :to (String)
    #   * :amount (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_transfer_to_vesting
    def self.transfer_to_vesting(options, &block)
      required_fields = %i(from to amount)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      params[:amount] = Type::Amount.to_nia(params[:amount])
      
      ops = [[:transfer_to_vesting, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # At any given point in time an account can be withdrawing from their
    # vesting shares.
    # 
    #     Steem::Broadcast.withdraw_vesting(wif: wif, params: {account: account, vesting_shares: vesting_shares}) do |result|
    #       puts result
    #     end
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :account (String)
    #   * :vesting_shares (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_withdraw_vesting
    def self.withdraw_vesting(options, &block)
      required_fields = %i(account vesting_shares)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      params[:vesting_shares] = Type::Amount.to_nia(params[:vesting_shares])
      
      ops = [[:withdraw_vesting, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # This operation creates a limit order and matches it against existing open
    # orders.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :owner (String)
    #   * :orderid (String)
    #   * :amount_to_sell (String)
    #   * :min_to_receive (String)
    #   * :fill_or_kill (Boolean)
    #   * :expiration (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_limit_order_create
    def self.limit_order_create(options, &block)
      required_fields = %i(owner orderid amount_to_sell min_to_receive
        fill_or_kill)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      params[:amount_to_sell] = Type::Amount.to_nia(params[:amount_to_sell])
      params[:min_to_receive] = Type::Amount.to_nia(params[:min_to_receive])
      
      if !!params[:expiration]
        params[:expiration] = Time.parse(params[:expiration].to_s)
        params[:expiration] = params[:expiration].strftime('%Y-%m-%dT%H:%M:%S')
      end
      
      ops = [[:limit_order_create, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # Cancels an order and returns the balance to owner.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :owner (String)
    #   * :orderid (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_limit_order_cancel
    def self.limit_order_cancel(options, &block)
      required_fields = %i(owner orderid)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      ops = [[:limit_order_cancel, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # Feeds can only be published by the top N witnesses which are included in
    # every round and are used to define the exchange rate between steem and the
    # dollar.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :publisher (String)
    #   * :exchange_rate (Hash)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_feed_publish
    def self.feed_publish(options, &block)
      required_fields = %i(publisher exchange_rate)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      exchange_rate = params[:exchange_rate] rescue nil || {}
      base = exchange_rate[:base]
      quote = exchange_rate[:quote]
      params[:exchange_rate][:base] = Type::Amount.to_nia(base)
      params[:exchange_rate][:quote] = Type::Amount.to_nia(quote)
      
      ops = [[:feed_publish, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # This operation instructs the blockchain to start a conversion between
    # STEEM and SBD, the funds are deposited after 3.5 days.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :owner (String)
    #   * :requestid (String)
    #   * :amount (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_convert
    def self.convert(options, &block)
      required_fields = %i(owner requestid amount)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      params[:amount] = Type::Amount.to_nia(params[:amount])
      
      ops = [[:convert, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # Create an account.
    #     options = {
    #       wif: wif,
    #       params: {
    #         fee: '1.000 STEEM',
    #         creator: creator_account_name,
    #         new_account_name: new_account_name,
    #         owner: {
    #           weight_threshold: 1,
    #           account_auths: [],
    #           key_auths: [[owner_public_key, 1]],
    #         },
    #         active: {
    #           weight_threshold: 1,
    #           account_auths: [],
    #           key_auths: [[active_public_key, 1]],
    #         },
    #         posting: {
    #           weight_threshold: 1,
    #           account_auths: [],
    #           key_auths: [[posting_public_key, 1]],
    #         },
    #         memo_key: memo_public_key,
    #         json_metadata: '{}'
    #       }
    #     }
    # 
    #     Steem::Broadcast.account_create(options)
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :fee (String)
    #   * :creator (String)
    #   * :new_account_name (String)
    #   * :owner (Hash)
    #   * :active (Hash)
    #   * :posting (Hash)
    #   * :memo_key (String)
    #   * :metadata (Hash) Metadata of the account, becomes `json_metadata`.
    #   * :json_metadata (String) String version of `metadata` (use one or the other).
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_account_create
    def self.account_create(options, &block)
      required_fields = %i(fee creator new_account_name owner active posting memo_key json_metadata)
      params = options[:params]
      
      if !!params[:metadata] && !!params[:json_metadata]
        raise Steem::ArgumentError, 'Assign either metadata or json_metadata, not both.'
      end
      
      metadata = params.delete(:metadata) || {}
      metadata ||= (JSON[params[:json_metadata]] || nil) || {}
      params[:json_metadata] = metadata.to_json
      
      check_required_fields(params, *required_fields)
      
      params[:fee] = Type::Amount.to_nia(params[:fee])
      
      ops = [[:account_create, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # Update an account.
    #     options = {
    #       wif: wif,
    #       params: {
    #         account: new_account_name,
    #         owner: {
    #           weight_threshold: 1,
    #           account_auths: [],
    #           key_auths: [[owner_public_key, 1]],
    #         },
    #          active: {
    #           weight_threshold: 1,
    #           account_auths: [],
    #            key_auths: [[active_public_key, 1]],
    #         },
    #         posting: {
    #           weight_threshold: 1,
    #           account_auths: [],
    #           key_auths: [[posting_public_key, 1]],
    #         },
    #         memo_key: memo_public_key,
    #         json_metadata: '{}'
    #       }
    #     }
    # 
    #     Steem::Broadcast.account_update(options)
    #
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :account (String)
    #   * :owner (Hash) (optional)
    #   * :active (Hash) (optional)
    #   * :posting (Hash) (optional)
    #   * :memo_key (String) (optional)
    #   * :metadata (Hash) Metadata of the account, becomes `json_metadata`.
    #   * :json_metadata (String) String version of `metadata` (use one or the other).
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_account_update
    def self.account_update(options, &block)
      required_fields = %i(account)
      params = options[:params]
      
      if !!params[:metadata] && !!params[:json_metadata]
        raise Steem::ArgumentError, 'Assign either metadata or json_metadata, not both.'
      end
      
      metadata = params.delete(:metadata) || {}
      metadata ||= (JSON[params[:json_metadata]] || nil) || {}
      params[:json_metadata] = metadata.to_json
      
      check_required_fields(params, *required_fields)
      
      ops = [[:account_update, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # Users who wish to become a witness must pay a fee acceptable to the
    # current witnesses to apply for the position and allow voting to begin.
    #
    #     options = {
    #       wif: wif,
    #       params: {
    #         owner: witness_account_name,
    #         url: '',
    #         block_signing_key: 'STM8ZSyzjPm48GmUuMSRufkVYkwYbZzbxeMysAVp7KFQwbTf98TcG',
    #         props: {
    #           account_creation_fee: '0.000 STEEM',
    #           maximum_block_size: 131072,
    #           sbd_interest_rate:1000
    #         },
    #         fee: '0.000 STEEM',
    #       }
    #     }
    # 
    #     Steem::Broadcast.witness_update(options)
    #
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :owner (String)
    #   * :url (String) (optional)
    #   * :block_signing_key (String)
    #   * :props (String)
    #   * :fee (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_witness_update
    def self.witness_update(options, &block)
      required_fields = %i(owner block_signing_key props fee)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      account_creation_fee = params[:props][:account_creation_fee] rescue nil
      params[:props][:account_creation_fee] = Type::Amount.to_nia(account_creation_fee)
      params[:fee] = Type::Amount.to_nia(params[:fee])
      
      ops = [[:witness_update, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # All accounts with a VFS (Vesting Fund Shares) can vote for or against any
    # witness.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :account (String)
    #   * :witness (String)
    #   * :approve (Boolean)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_account_witness_vote
    def self.account_witness_vote(options, &block)
      required_fields = %i(account witness approve)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      ops = [[:account_witness_vote, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :account (String)
    #   * :proxy (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_account_witness_proxy
    def self.account_witness_proxy(options, &block)
      required_fields = %i(account proxy)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      ops = [[:account_witness_proxy, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # Provides a generic way to add higher level protocols on top of witness
    # consensus.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :required_auths (Array<String>)
    #   * :id (String)
    #   * :data (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_custom
    def self.custom(options, &block)
      required_fields = %i(required_auths id data)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      ops = [[:custom, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # The semmantics for this operation are the same as the {Broadcast#custom_json}
    # operation, but with a binary payload.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Posting wif
    # @option options [Hash] :params
    #   * :id (String)
    #   * :data (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_custom_binary
    def self.custom_binary(options, &block)
      required_fields = %i(id data)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      ops = [[:custom_binary, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # Serves the same purpose as {Broadcast#custom} but also supports required
    # posting authorities.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Posting wif
    # @option options [Hash] :params
    #   * :required_auths (Array<String>)
    #   * :required_posting_auths (Arrat<String>)
    #   * :id (String)
    #   * :data (Hash) Data of the custom json, becomes `json`.
    #   * :json (String) String version of `data` (use one or the other).
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_custom_json
    def self.custom_json(options, &block)
      required_fields = %i(id)
      params = options[:params]
      
      if !!params[:data] && !!params[:json]
        raise Steem::ArgumentError, 'Assign either data or json, not both.'
      end
      
      data = params.delete(:data) || {}
      data ||= (JSON[params[:json]] || nil) || {}
      params[:json] = data.to_json
      
      check_required_fields(params, *required_fields)
      
      params[:required_auths] ||= []
      params[:required_posting_auths] ||= []
      ops = [[:custom_json, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # Allows an account to setup a vesting withdraw but with the additional
    # request for the funds to be transferred directly to another account’s
    # balance rather than the withdrawing account.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :from_account (String)
    #   * :to_account (String)
    #   * :percent (Numeric)
    #   * :auto_vest (Boolean)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_set_withdraw_vesting_route
    def self.set_withdraw_vesting_route(options, &block)
      required_fields = %i(from_account to_account percent auto_vest)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      ops = [[:set_withdraw_vesting_route, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # All account recovery requests come from a listed recovery account.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :recovery_account (String)
    #   * :account_to_recover (String)
    #   * :new_owner_authority (Hash)
    #   * :extensions (Array) (optional)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_request_account_recovery
    def self.request_account_recovery(options, &block)
      required_fields = %i(recovery_account account_to_recover new_owner_authority)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      params[:extensions] ||= []
      ops = [[:request_account_recovery, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :account_to_recover (String)
    #   * :new_owner_authority (Hash)
    #   * :recent_owner_authority (Hash)
    #   * :extensions (Array) (optional)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_recover_account
    def self.recover_account(options, &block)
      required_fields = %i(account_to_recover new_owner_authority recent_owner_authority)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      params[:extensions] ||= []
      ops = [[:recover_account, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # Each account lists another account as their recovery account.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Posting wif
    # @option options [Hash] :params
    #   * :account_to_recover (String)
    #   * :new_recovery_account (String)
    #   * :extensions (Array) (optional)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_change_recovery_account
    def self.change_recovery_account(options, &block)
      required_fields = %i(account_to_recover)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      params[:new_recovery_account] ||= ''
      params[:extensions] ||= []
      ops = [[:change_recovery_account, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # The purpose of this operation is to enable someone to send money
    # contingently to another individual.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :from (String)
    #   * :to (String)
    #   * :agent (String)
    #   * :escrow_id (String)
    #   * :sbd_amount (String)
    #   * :steem_amount (String)
    #   * :fee (String)
    #   * :ratification_deadline (String)
    #   * :escrow_expiration (String)
    #   * :meta (Hash) Meta of the escrow transfer, becomes `json_meta`.
    #   * :json_meta (String) String version of `metadata` (use one or the other).
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_escrow_transfer
    def self.escrow_transfer(options, &block)
      required_fields = %i(from to agent escrow_id fee ratification_deadline)
      params = options[:params]
      
      if !!params[:meta] && !!params[:json_meta]
        raise Steem::ArgumentError, 'Assign either meta or json_meta, not both.'
      end
      
      meta = params.delete(:meta) || {}
      meta ||= (JSON[params[:json_meta]] || nil) || {}
      params[:json_meta] = meta.to_json
      
      check_required_fields(params, *required_fields)
      
      params[:sbd_amount] = Type::Amount.to_nia(params[:sbd_amount])
      params[:steem_amount] = Type::Amount.to_nia(params[:steem_amount])
      params[:fee] = Type::Amount.to_nia(params[:fee])
      
      params[:ratification_deadline] = Time.parse(params[:ratification_deadline].to_s)
      params[:ratification_deadline] = params[:ratification_deadline].strftime('%Y-%m-%dT%H:%M:%S')
      
      if !!params[:escrow_expiration]
        params[:escrow_expiration] = Time.parse(params[:escrow_expiration].to_s)
        params[:escrow_expiration] = params[:escrow_expiration].strftime('%Y-%m-%dT%H:%M:%S')
      end

      ops = [[:escrow_transfer, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # If either the sender or receiver of an escrow payment has an issue, they
    # can raise it for dispute.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :from (String)
    #   * :to (String)
    #   * :agent (String)
    #   * :who (String)
    #   * :escrow_id (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_escrow_dispute
    def self.escrow_dispute(options, &block)
      required_fields = %i(from to agent who escrow_id)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      ops = [[:escrow_dispute, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # This operation can be used by anyone associated with the escrow transfer
    # to release funds if they have permission.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :from (String)
    #   * :to (String)
    #   * :agent (String)
    #   * :who (String)
    #   * :receiver (String)
    #   * :escrow_id (String)
    #   * :sbd_amount (String)
    #   * :steem_amount (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_escrow_release
    def self.escrow_release(options, &block)
      required_fields = %i(from to agent who receiver escrow_id)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      params[:sbd_amount] = Type::Amount.to_nia(params[:sbd_amount])
      params[:steem_amount] = Type::Amount.to_nia(params[:steem_amount])

      ops = [[:escrow_release, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # The agent and to accounts must approve an escrow transaction for it to be
    # valid on the blockchain.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :from (String)
    #   * :to (String)
    #   * :agent (String)
    #   * :who (String)
    #   * :escrow_id (String)
    #   * :approve (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_escrow_approve
    def self.escrow_approve(options, &block)
      required_fields = %i(from to agent who escrow_id approve)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      ops = [[:escrow_approve, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # For time locked savings accounts.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :from (String)
    #   * :to (String)
    #   * :amount (String)
    #   * :memo (String) (optional)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_transfer_to_savings
    def self.transfer_to_savings(options, &block)
      required_fields = %i(from to amount)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      params[:memo] ||= ''
      params[:amount] = Type::Amount.to_nia(params[:amount])

      ops = [[:transfer_to_savings, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :from (String)
    #   * :request_id (String)
    #   * :to (String)
    #   * :amount (String)
    #   * :memo (String) (optional)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_transfer_from_savings
    def self.transfer_from_savings(options, &block)
      required_fields = %i(from request_id to amount)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      params[:memo] ||= ''
      params[:amount] = Type::Amount.to_nia(params[:amount])

      ops = [[:transfer_from_savings, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :from (String)
    #   * :request_id (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_cancel_transfer_from_savings
    def self.cancel_transfer_from_savings(options, &block)
      required_fields = %i(from request_id)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      ops = [[:cancel_transfer_from_savings, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # An account can chose to decline their voting rights after a 30 day delay.
    # This includes voting on content and witnesses. **The voting rights cannot
    # be acquired again once they have been declined.** This is only to
    # formalize a smart contract between certain accounts and the community that
    # currently only exists as a social contract.
    #
    # @param options [Hash] options
    # @option options [String] :wif Owner wif
    # @option options [Hash] :params
    #   * :account (String)
    #   * :decline (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_decline_voting_rights
    def self.decline_voting_rights(options, &block)
      required_fields = %i(account decline)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      ops = [[:decline_voting_rights, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # Delegate vesting shares from one account to the other.
    # 
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :delegator (String)
    #   * :delegatee (String)
    #   * :vesting_shares (String)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_delegate_vesting_shares
    def self.delegate_vesting_shares(options, &block)
      required_fields = %i(delegator delegatee vesting_shares)
      params = options[:params]
      check_required_fields(params, *required_fields)
      
      params[:vesting_shares] = Type::Amount.to_nia(params[:vesting_shares])
      ops = [[:delegate_vesting_shares, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # @param options [Hash] options
    # @option options [String] :wif Active wif
    # @option options [Hash] :params
    #   * :fee (String)
    #   * :delegation (String)
    #   * :creator (String)
    #   * :new_account_name (String)
    #   * :owner (String)
    #   * :active (String)
    #   * :posting (String)
    #   * :memo_key (String)
    #   * :metadata (Hash) Metadata of the account, becomes `json_metadata`.
    #   * :json_metadata (String) String version of `metadata` (use one or the other).
    #   * :extensions (Array)
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    # @see https://developers.steem.io/apidefinitions/broadcast-ops#broadcast_ops_account_create_with_delegation
    def self.account_create_with_delegation(options, &block)
      required_fields = %i(fee delegation creator new_account_name owner active posting memo_key)
      params = options[:params]
      
      if !!params[:metadata] && !!params[:json_metadata]
        raise Steem::ArgumentError, 'Assign either metadata or json_metadata, not both.'
      end
      
      metadata = params.delete(:metadata) || {}
      metadata ||= (JSON[params[:json_metadata]] || nil) || {}
      params[:json_metadata] = metadata.to_json
      
      check_required_fields(params, *required_fields)
      
      params[:fee] = Type::Amount.to_nia(params[:fee])
      params[:delegation] = Type::Amount.to_nia(params[:delegation])
      params[:extensions] ||= []
      
      ops = [[:account_create_with_delegation, params]]
      
      process(options.merge(ops: ops), &block)
    end
    
    # @param options [Hash] options
    # @option options [Array<Array<Hash>] :ops Operations to process.
    # @option options [Boolean] :pretend Just validate, do not broadcast.
    def self.process(options, &block)
      ops = options[:ops]
      tx = TransactionBuilder.new(options)
      response = nil
      
      loop do; begin
        tx.operations = ops
        trx = tx.transaction
        
        response = if !!options[:pretend]
          database_api(options).verify_authority(trx: trx)
        else
          network_broadcast_api(options).broadcast_transaction_synchronous(trx: trx)
        end
        
        break
      rescue => e
        if can_retry? e
          tx.expiration = nil
          redo
        end
        
        raise e
      end; end
      
      if !!block
        block.call response.result
      else
        return response.result
      end
    end
  private
    # @private
    def self.database_api(options)
      options[:database_api] ||= Steem::DatabaseApi.new(options)
    end
    
    # @private
    def self.network_broadcast_api(options)
      options[:network_broadcast_api] ||= Steem::NetworkBroadcastApi.new(options)
    end
    
    # @private
    def self.check_required_fields(hash, *fields)
      fields.each do |field|
        value = hash[field]
        
        raise Steem::ArgumentError, "#{field}: required" if value.nil?
        
        case value
        when String, Array, Hash
          raise Steem::ArgumentError, "#{field}: required" if value.empty?
        end
      end
    end
  end
end
