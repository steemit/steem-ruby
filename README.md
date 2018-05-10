# `steem-ruby`

Steem-ruby the Ruby API for Steem blockchain.

Full documentation: http://www.rubydoc.info/gems/steem-ruby

## Getting Started

The steem-ruby gem is compatible with Ruby 2.2.5 or later.

### Install the gem for your project

*(Assuming that [Ruby is installed](https://www.ruby-lang.org/en/downloads/) on your computer, as well as [RubyGems](http://rubygems.org/pages/download))*

To install the gem on your computer, run in shell:

```bash
gem install steem-ruby
```

... then add in your code:

```ruby
require 'steem'
```

To add the gem as a dependency to your project with [Bundler](http://bundler.io/), you can add this line in your Gemfile:

```ruby
gem 'steem-ruby', require: 'steem'
```

## Examples

### Broadcast Vote

```ruby
params = {
  voter: voter,
  author: author,
  permlink: permlink,
  weight: weight
}

Steem::Broadcast.vote(wif: wif, params: params) do |result|
  puts result
end
```

### Get Accounts

```ruby
api = Steem::DatabaseApi.new

api.find_accounts(accounts: ['steemit', 'alice']) do |result|
  puts result.accounts
end
```

### Reputation Formatter

```ruby
rep = Steem::Formatter.reputation(account.reputation)
puts rep
```

## Contributions

Patches are welcome! Contributors are listed in the `steem-ruby.gemspec` file. Please run the tests (`rake test`) before opening a pull request and make sure that you are passing all of them. If you would like to contribute, but don't know what to work on, check the issues list.

## Issues

When you find issues, please report them!

## License

MIT
