require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'
require 'steem'
require 'awesome_print'
require 'pry'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.ruby_opts << if ENV['HELL_ENABLED']
    '-W2'
  else
    '-W1'
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
    exec 'rm -v test/fixtures/vcr_cassettes/*.yml'
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
