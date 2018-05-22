module Steem
  class BaseError < StandardError
    def initialize(error, cause = nil)
      @error = error
      @cause = cause
    end
    
    def to_s
      if !!@cause
        JSON[error: @error, cause: @cause] rescue {error: @error, cause: @cause}.to_s
      else
        JSON[@error] rescue @error.to_s
      end
    end
    
    def self.build_error(error, context)
      if error.message == 'Unable to acquire database lock'
        raise Steem::RemoteDatabaseLockError, error.message, JSON.pretty_generate(error)
      end
      
      if error.message.include? 'Internal Error'
        raise Steem::RemoteNodeError.new, error.message, JSON.pretty_generate(error)
      end
      
      if error.message.include? 'plugin not enabled'
        raise Steem::PluginNotEnabledError, error.message, JSON.pretty_generate(error)
      end
      
      if error.message.include? 'argument'
        raise Steem::ArgumentError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.start_with? 'Bad Cast:'
        raise Steem::ArgumentError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'prefix_len'
        raise Steem::ArgumentError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'Parse Error'
        raise Steem::ArgumentError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'unknown key'
        raise Steem::ArgumentError, "#{context}: #{error.message} (or content has been deleted)", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'Comment is not in account\'s comments'
        raise Steem::ArgumentError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'Could not find comment'
        raise Steem::ArgumentError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'unable to convert ISO-formatted string to fc::time_point_sec'
        raise Steem::ArgumentError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'Input data have to treated as object.'
        raise Steem::ArgumentError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'blk->transactions.size() > itr->trx_in_block'
        raise Steem::VirtualOperationsNotAllowedError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'A transaction must have at least one operation'
        raise Steem::EmptyTransactionError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'transaction expiration exception'
        raise Steem::TransactionExpiredError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'Duplicate transaction check failed'
        raise Steem::DuplicateTransactionError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'signature is not canonical'
        raise Steem::NonCanonicalSignatureError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'attempting to push a block that is too old'
        raise Steem::BlockTooOldError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'irrelevant signature'
        raise Steem::IrrelevantSignatureError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'missing required posting authority'
        raise Steem::MissingPostingAuthorityError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'missing required active authority'
        raise Steem::MissingActiveAuthorityError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'missing required owner authority'
        raise Steem::MissingOwnerAuthorityError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'missing required other authority'
        raise Steem::MissingOtherAuthorityError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'operator has disabled operation indexing by transaction_id'
        raise Steem::TransactionIndexDisabledError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'is_valid_account_name'
        raise Steem::InvalidAccountError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'Invalid operation name'
        raise Steem::UnknownOperationError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'Author not found'
        raise Steem::AuthorNotFoundError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? ' != fc::time_point_sec::maximum()'
        raise Steem::ReachedMaximumTimeError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'Cannot transfer a negative amount (aka: stealing)'
        raise Steem::TheftError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'Must transfer a nonzero amount'
        raise Steem::NonZeroRequiredError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      if error.message.include? 'is_asset_type'
        raise Steem::UnexpectedAssetError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      puts JSON.pretty_generate(error) if ENV['DEBUG']
      raise UnknownError, "#{context}: #{error.message}", JSON.pretty_generate(error)
    end
  end
  
  class UnsupportedChainError < BaseError; end
  class ArgumentError < BaseError; end
  class RemoteNodeError < BaseError; end
  class RemoteDatabaseLockError < RemoteNodeError; end
  class PluginNotEnabledError < RemoteNodeError; end
  class TypeError < BaseError; end
  class EmptyTransactionError < ArgumentError; end
  class InvalidAccountError < ArgumentError; end
  class AuthorNotFoundError < ArgumentError; end
  class ReachedMaximumTimeError < ArgumentError; end
  class VirtualOperationsNotAllowedError < ArgumentError; end
  class TheftError < ArgumentError; end
  class NonZeroRequiredError < ArgumentError; end
  class UnexpectedAssetError < ArgumentError; end
  class TransactionExpiredError < BaseError; end
  class DuplicateTransactionError < TransactionExpiredError; end
  class NonCanonicalSignatureError < TransactionExpiredError; end
  class BlockTooOldError < BaseError; end
  class IrrelevantSignatureError < BaseError; end
  class MissingAuthorityError < BaseError; end
  class MissingPostingAuthorityError < MissingAuthorityError; end
  class MissingActiveAuthorityError < MissingAuthorityError; end
  class MissingOwnerAuthorityError < MissingAuthorityError; end
  class MissingOtherAuthorityError < MissingAuthorityError; end
  class IncorrectRequestIdError < BaseError; end
  class IncorrectResponseIdError < BaseError; end
  class TransactionIndexDisabledError < BaseError; end
  class NotAppBaseError < BaseError; end
  class UnknownApiError < BaseError; end
  class UnknownOperationError < BaseError; end
  class JsonRpcBatchMaximumSizeExceededError < BaseError; end
  class TooManyTimeoutsError < BaseError; end
  class UnknownError < BaseError; end
end
