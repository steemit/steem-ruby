module Steem
  module Retriable
    # @private
    MAX_RETRY_COUNT = 100
    
    # @private
    MAX_BACKOFF = 30
    
    MAX_RETRY_ELAPSE = 300
    
    RETRYABLE_EXCEPTIONS = [
      NonCanonicalSignatureError, IncorrectRequestIdError,
      IncorrectResponseIdError, RemoteDatabaseLockError
    ]
    
    # Expontential backoff.
    #
    # @private
    def backoff
      @backoff ||= 0.1
      @backoff *= 2
      if @backoff > MAX_BACKOFF
        @backoff = 0.1
        
        if Time.now.utc - @first_retry_at > MAX_RETRY_ELAPSE
          @retry_count = nil
          @first_retry_at = nil
        end
      end
      
      sleep @backoff
    end
    
    def can_retry?(e = nil)
      @retry_count ||= 0
      @first_retry_at ||= Time.now.utc
      
      return false if @retry_count >= MAX_RETRY_COUNT
      
      @retry_count += 1
      
      can_retry = case e
      when *RETRYABLE_EXCEPTIONS then true
      else; false
      end
      
      backoff if can_retry
      
      can_retry
    end
  end
end
