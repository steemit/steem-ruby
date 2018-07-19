$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'

SimpleCov.start
SimpleCov.merge_timeout 3600

require 'steem'
require 'minitest/autorun'
require 'webmock/minitest'
require 'vcr'
require 'yaml'
require 'awesome_print'

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

require 'minitest/hell'
require 'minitest/proveit'

class Minitest::Test
  # See: https://gist.github.com/chrisroos/b5da6c6a37ac8af5fe78
  parallelize_me! unless defined? WebMock
end

# before tests, outside test threads
VCR.insert_cassette('global_cassette', record: :once, match_requests_on: [:method, :uri, :body])
@jsonrpc = Steem::Jsonrpc.new
@jsonrpc.get_api_methods # caches up methods

class Steem::Test < MiniTest::Test
  defined? prove_it! and prove_it!
  
  TEST_NODE = ENV.fetch 'TEST_NODE', Steem::ChainConfig::NETWORKS_STEEM_DEFAULT_NODE
  # TEST_NODE = Steem::ChainConfig::NETWORKS_TEST_DEFAULT_NODE
  
  # Most likely modes: 'once' and 'new_episodes'
  VCR_RECORD_MODE = (ENV['VCR_RECORD_MODE'] || 'new_episodes').to_sym
  
  def vcr_cassette(name, options = {match_requests_on: [:method, :uri, :body]}, &block)
    options[:record] ||= VCR_RECORD_MODE
    
    VCR.use_cassette(name, options) do
      begin
        yield
      rescue Steem::BaseError => e
        skip "Probably just a node acting up: #{e}"
      rescue Psych::SyntaxError => e
        skip 'This happens when we try to get fancy and disable thread-safety.'
      end
    end
  end
end
