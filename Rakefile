require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'
require 'steem'

Rake::TestTask.new(test: 'clean:vcr') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.ruby_opts << if ENV['HELL_ENABLED']
    '-W2'
  else
    '-W1'
  end
end

namespace :test do
  Rake::TestTask.new(static: 'clean:vcr') do |t|
    t.description = <<-EOD
      Run static tests, which are those that have static request/responses.
      These are tests that are typically read-only and do not require heavy
      matches on the json-rpc request body.  Often, the only difference between
      one execution and another is the json-rpc-id.
    EOD
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = [
      'test/steem/account_by_key_api_test.rb',
      'test/steem/account_history_api_test.rb',
      'test/steem/block_api_test.rb',
      'test/steem/database_api_test.rb',
      'test/steem/follow_api_test.rb',
      'test/steem/jsonrpc_test.rb',
      'test/steem/market_history_api_test.rb',
      'test/steem/tags_api_test.rb',
      'test/steem/witness_api_test.rb'
    ]
    t.ruby_opts << if ENV['HELL_ENABLED']
      '-W2'
    else
      '-W1'
    end
  end
  
  Rake::TestTask.new(broadcast: 'clean:vcr') do |t|
    t.description = <<-EOD
      Run broadcast tests, which are those that only use network_broadcast_api
      and/or database_api.verify_authority (pretend: true).
    EOD
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = [
      'test/steem/broadcast_test.rb',
      'test/steem/transaction_builder_test.rb'
    ]
    t.ruby_opts << if ENV['HELL_ENABLED']
      '-W2'
    else
      '-W1'
    end
  end
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

task default: :test

desc 'Ruby console with steem already required.'
task :console do
  exec 'irb -r steem -I ./lib'
end

namespace :clean do
  desc 'Remove test/fixtures/vcr_cassettes/*.yml so they can be rebuilt fresh.'
  task :vcr do |t|
    cmd = 'echo Cleaned cassettes: $(rm -v test/fixtures/vcr_cassettes/*.yml | wc -l)'
    system cmd
  end
end

namespace :show do
  desc 'Shows known API names.'
  task :apis do
    url = ENV['URL']
    jsonrpc = Steem::Jsonrpc.new(url: url)
    api_methods = jsonrpc.get_api_methods
    puts api_methods.keys
  end

  desc 'Shows known method names for specified API.'
  task :methods, [:api] do |t, args|
    url = ENV['URL']
    jsonrpc = Steem::Jsonrpc.new(url: url)
    api_methods = jsonrpc.get_api_methods
    api_methods[args[:api]].each do |method|
      jsonrpc.get_signature(method: "#{args[:api]}.#{method}") do |signature|
        print "#{method} "
        params = signature.args.map do |k, v|
          if v =~ /\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2]\d|3[0-1])T(2[0-3]|[01]\d):[0-5]\d:[0-5]\d/
            "#{k}: Time"
          elsif v.class == Hashie::Array
            "#{k}: []"
          elsif v.class == Hashie::Mash
            "#{k}: {}"
          else
            "#{k}: #{v.class}"
          end
        end
        puts params.join(', ')
      end
    end
  end
end
