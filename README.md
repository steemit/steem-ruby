[![Gem Version](https://badge.fury.io/rb/steem-ruby.svg)](https://badge.fury.io/rb/steem-ruby)
[![Inline docs](http://inch-ci.org/github/steemit/steem-ruby.svg?branch=master&style=shields)](http://inch-ci.org/github/steemit/steem-ruby)

# `steem-ruby`

Steem-ruby the Ruby API for Steem blockchain.

Full documentation: http://www.rubydoc.info/gems/steem-ruby

## `radiator` vs. `steem-ruby`

The `steem-ruby` gem was written from the ground up by `@inertia`, who is also the author of [`radiator`](https://github.com/inertia186/radiator).

> "I intend to continue work on `radiator` indefinitely. But in `radiator-0.5`, I intend to refactor `radiator` so that is uses `steem-ruby` as its core. This means that some features of `radiator` like Serialization will become redundant. I think it's still useful for radiator to do its own serialzation because it reduces the number of API requests." - @inertia

| `radiator` | `steem-ruby` |
|-|-|
| Has internal failover logic | Can have failover delegated externally |
| Passes `error` responses to the caller | Handles `error` responses and raises exceptions |
| Supports tx signing, does its own serialization | Also supports tx signing, but delegates serialization to `database_api.get_transaction_hex` |
| All apis and methods are hardcoded | Asks `jsonrpc` what apis and methods are available from the node |
| (`radiator-0.4.x`) Only supports AppBase but relies on `condenser_api` | Only supports AppBase but does not rely on `condenser_api` **(WIP)**
| Small list of helper methods for select ops (in addition to build your own transaction) | Complete implementation of helper methods for every op (in addition to build your own transaction) |
| Does not (yet) support `json-rpc-batch` requests | Supports `json-rpc-batch` requests |

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

*See: [Broadcast](https://www.rubydoc.info/gems/steem-ruby/Steem/Broadcast)*

### Get Accounts

```ruby
api = Steem::DatabaseApi.new

api.find_accounts(accounts: ['steemit', 'alice']) do |result|
  puts result.accounts
end
```

*See: [Api](https://www.rubydoc.info/gems/steem-ruby/Steem/Api)*

### Reputation Formatter

```ruby
rep = Steem::Formatter.reputation(account.reputation)
puts rep
```

### Tests

* Clone the client repository into a directory of your choice:
  * `git clone https://github.com/steemit/steem-ruby.git`
* Navigate into the new folder
  * `cd steem-ruby`
* All tests can be invoked as follows:
  * `bundle exec rake test`
* To run `static` tests:
  * `bundle exec rake test:static`
* To run `broadcast` tests (broadcast is simulated, only `verify` is actually used):
  * `bundle exec rake test:broadcast`
* To run `threads` tests (which quickly verifies thread safety):
  * `bundle exec rake test:threads`
* To run `testnet` tests (which does actual broadcasts)
  * `TEST_NODE=https://testnet.steemitdev.com bundle exec rake test:testnet`

You can also run other tests that are not part of the above `test` execution:

* To run `block_range`, which streams blocks (using `json-rpc-batch`)
  * `bundle exec rake stream:block_range`


If you want to point to any node for tests, instead of letting the test suite pick the default, set the environment variable to `TEST_NODE`, e.g.:

```bash
$ TEST_NODE=https://api.steemitdev.com bundle exec rake test
```

## Contributions

Patches are welcome! Contributors are listed in the `steem-ruby.gemspec` file. Please run the tests (`rake test`) before opening a pull request and make sure that you are passing all of them. If you would like to contribute, but don't know what to work on, check the issues list.

## Issues

When you find issues, please report them!

## License

MIT
