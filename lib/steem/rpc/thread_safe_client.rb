module Steem
  module RPC
    # {ThreadSafeClient} is the default RPC Client used by `steem-ruby.`  It's
    # perfect for simple requests.  But for higher performance, it's better to
    # override {BaseClient} and implement something other than {Net::HTTP}.
    class ThreadSafeClient < BaseClient
      SEMAPHORE = Mutex.new.freeze
      
      def http_request(request)
        response = SEMAPHORE.synchronize do
          http.request(request)
        end
      end
      
      def rpc_id
        SEMAPHORE.synchronize do
          @rpc_id ||= 0
          @rpc_id += 1
        end
      end
    end
  end
end
