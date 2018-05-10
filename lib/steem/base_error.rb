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
        raise Steem::RemoteNodeError, error.message, JSON.pretty_generate(error)
      end
      
      if error.message.include? 'Internal Error'
        raise Steem::RemoteNodeError.new, error.message, JSON.pretty_generate(error)
      end
      
      if error.message.include? 'plugin not enabled'
        raise Steem::RemoteNodeError, error.message, JSON.pretty_generate(error)
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
        raise Steem::ArgumentError, "#{context}: #{error.message}", JSON.pretty_generate(error)
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
      
      if error.message.include? 'unable to convert ISO-formatted string to fc::time_point_sec'
        raise Steem::ArgumentError, "#{context}: #{error.message}", JSON.pretty_generate(error)
      end
      
      puts JSON.pretty_generate(error) if ENV['DEBUG']
      raise UnknownError, "#{context}: #{error.message}", JSON.pretty_generate(error)
    end
  end
  
  class UnsupportedChainError < BaseError; end
  class ArgumentError < BaseError; end
  class RemoteNodeError < BaseError; end
  class TypeError < BaseError; end
  class EmptyTransactionError < BaseError; end
  class TransactionExpiredError < BaseError; end
  class DuplicateTransactionError < BaseError; end
  class NonCanonicalSignatureError < BaseError; end
  class BlockTooOldError < BaseError; end
  class IrrelevantSignatureError < BaseError; end
  class MissingPostingAuthorityError < BaseError; end
  class MissingActiveAuthorityError < BaseError; end
  class MissingOwnerAuthorityError < BaseError; end
  class MissingOtherAuthorityError < BaseError; end
  class InvalidAccountError < BaseError; end
  class AuthorNotFoundError < BaseError; end
  class ReachedMaximumTimeError < BaseError; end
  class TheftError < BaseError; end
  class NonZeroRequiredError < BaseError; end
  class UnexpectedAssetError < BaseError; end
  class IncorrectRequestIdError < BaseError; end
  class IncorrectResponseIdError < BaseError; end
  class UnknownApiError < BaseError; end
  class UnknownOperationError < BaseError; end
  class UnknownError < BaseError; end
end
