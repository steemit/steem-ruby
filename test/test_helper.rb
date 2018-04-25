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

class Steem::Test < MiniTest::Test
  defined? prove_it! and prove_it!
  
  # Most likely modes: 'once' and 'new_episodes'
  VCR_RECORD_MODE = (ENV['VCR_RECORD_MODE'] || 'new_episodes').to_sym
  
  def vcr_cassette(name, &block)
    VCR.use_cassette(name, record: VCR_RECORD_MODE, match_requests_on: [:method, :uri, :body]) do
      yield
    end
  end
  
  VCR.use_cassette('global_cassette', record: VCR_RECORD_MODE, match_requests_on: [:method, :uri, :body]) do
    @jsonrpc = Steem::Jsonrpc.new
    @jsonrpc.get_api_methods[Steem::Api.api_name] # caches up methods
  end
end
