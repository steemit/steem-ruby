require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'
require 'steem'

Rake::TestTask.new(test: ['clean:vcr', 'test:threads']) do |t|
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
  
  Rake::TestTask.new(testnet: 'clean:vcr') do |t|
    t.description = <<-EOD
      Run testnet tests, which are those that use network_broadcast_api to do
      actual broadcast operations, on a specified (or default) testnet.
    EOD
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = [
      'test/steem/testnet_test.rb'
    ]
    t.ruby_opts << if ENV['HELL_ENABLED']
      '-W2'
    else
      '-W1'
    end
  end
  
  desc 'Tests the API using multiple threads.'
  task :threads do
    threads = []
    api = Steem::Api.new(url: ENV['TEST_NODE'])
    database_api = Steem::DatabaseApi.new(url: ENV['TEST_NODE'])
    witnesses = {}
    keys = %i(created url total_missed props running_version
      hardfork_version_vote hardfork_time_vote)
    
    if defined? Thread.report_on_exception
      Thread.report_on_exception = true
    end
    
    database_api.get_active_witnesses do |result|
      print "Found #{result.witnesses.size} witnesses ..."
      
      result.witnesses.each do |witness_name|
        threads << Thread.new do
          api.get_witness_by_account(witness_name) do |witness|
            witnesses[witness.owner] = witness.map do |k, v|
              [k, v] if keys.include? k.to_sym
            end.compact.to_h
            
            sbd_exchange_rate = witness[:sbd_exchange_rate]
            base = sbd_exchange_rate[:base].to_f
            
            if (quote = sbd_exchange_rate[:quote].to_f) > 0
              rate = (base / quote).round(3)
              witnesses[witness.owner][:sbd_exchange_rate] = rate
            else
              witnesses[witness.owner][:sbd_exchange_rate] = nil
            end
            
            last_sbd_exchange_update = witness[:last_sbd_exchange_update]
            last_sbd_exchange_update = Time.parse(last_sbd_exchange_update + 'Z')
            last_sbd_exchange_elapsed = '%.2f hours ago' % ((Time.now.utc - last_sbd_exchange_update) / 60)
            witnesses[witness.owner][:last_sbd_exchange_elapsed] = last_sbd_exchange_elapsed
          end
        end
      end
    end
    
    threads.each do |thread|
      print '.'
      thread.join
    end
    
    puts ' done!'
    
    if threads.size != witnesses.size
      puts "Bug: expected #{threads.size} witnesses, only found #{witnesses.size}."
    else
      puts JSON.pretty_generate witnesses rescue puts witnesses
    end
  end
end
  
namespace :stream do
  desc 'Test the ability to stream a block range.'
  task :block_range do
    block_api = Steem::BlockApi.new(url: ENV['TEST_NODE'])
    api = Steem::Api.new(url: ENV['TEST_NODE'])
    last_block_num = nil
    first_block_num = nil
    last_timestamp = nil
    
    loop do
      api.get_dynamic_global_properties do |properties|
        current_block_num = properties.last_irreversible_block_num
        # First pass replays latest a random number of blocks to test chunking.
        first_block_num ||= current_block_num - (rand * 200).to_i
        
        if current_block_num >= first_block_num
          range = first_block_num..current_block_num
          puts "Got block range: #{range.size}"
          block_api.get_blocks(block_range: range) do |block, block_num|
            current_timestamp = Time.parse(block.timestamp + 'Z')
            
            if !!last_timestamp && block_num != last_block_num + 1
              puts "Bug: Last block number was #{last_block_num} then jumped to: #{block_num}"
              exit
            end
            
            if !!last_timestamp && current_timestamp < last_timestamp
              puts "Bug: Went back in time.  Last timestamp was #{last_timestamp}, then jumped back to #{current_timestamp}"
              exit
            end
            
            puts "\t#{block_num} Timestamp: #{current_timestamp}, witness: #{block.witness}"
            last_block_num = block_num
            last_timestamp = current_timestamp
          end
          
          first_block_num = range.max + 1
        end
        
        sleep 3
      end
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
