module Steem
  module Retriable
    # @private
    MAX_RETRY_COUNT = 30
    
    MAX_RETRY_ELAPSE = 60
    
    # @private
    MAX_BACKOFF = MAX_RETRY_ELAPSE / 4
    
    RETRYABLE_EXCEPTIONS = [
      NonCanonicalSignatureError, IncorrectRequestIdError,
      IncorrectResponseIdError, RemoteDatabaseLockError
    ]
    
    def can_retry?(e = nil)
      @retry_count ||= 0
      
      return false if @retry_count >= MAX_RETRY_COUNT
      
      @retry_count = if retry_reset?
        @first_retry_at = nil
      else
        @retry_count + 1
      end
      
      can_retry = case e
      when *RETRYABLE_EXCEPTIONS then true
      else; false
      end
      
      backoff if can_retry
      
      can_retry
    end
  private
    # @private
    def first_retry_at
      @first_retry_at ||= Time.now.utc
    end
    
    # @private
    def retry_reset?
      Time.now.utc - first_retry_at > MAX_RETRY_ELAPSE
    end
    
    # Expontential backoff.
    #
    # @private
    def backoff
      @backoff ||= 0.1
      @backoff *= 2
      @backoff = 0.1 if @backoff > MAX_BACKOFF
      
      sleep @backoff
    end
  end
end
