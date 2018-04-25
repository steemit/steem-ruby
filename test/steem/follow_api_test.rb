require 'test_helper'

module Steem
  class FollowApiTest < Steem::Test
    def setup
      @api = Steem::FollowApi.new
      @jsonrpc = Jsonrpc.new
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    end
    def test_api_class_name
      assert_equal 'FollowApi', Steem::FollowApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<FollowApi [@chain=steem, @url=https://api.steemit.com]>", @api.inspect
    end
    
    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end
    
    def test_all_respond_to
      @methods.each do |key|
        assert @api.respond_to?(key), "expect rpc respond to #{key}"
      end
    end
    
    def test_get_account_reputations
      vcr_cassette('get_account_reputations') do
        options = {
          account_lower_bound: 'steemit',
          limit: 0
        }
        
        @api.get_account_reputations(options) do |result|
          assert_equal Hashie::Array, result.reputations.class
        end
      end
    end
    
    def test_get_blog
      vcr_cassette('get_blog') do
        options = {
          account: 'steemit',
          start_entry_id: 0,
          limit: 0
        }
        
        @api.get_blog(options) do |result|
          assert_equal Hashie::Array, result.blog.class
        end
      end
    end
    
    def test_get_blog_authors
      vcr_cassette('get_blog_authors') do
        options = {
          blog_account: 'steemit'
        }
        
        @api.get_blog_authors(options) do |result|
          assert_equal Hashie::Array, result.blog_authors.class
        end
      end
    end
    
    def test_get_blog_entries
      vcr_cassette('get_blog_entries') do
        options = {
          account: 'steemit',
          start_entry_id: 0,
          limit: 0
        }
        
        @api.get_blog_entries(options) do |result|
          assert_equal Hashie::Array, result.blog.class
        end
      end
    end
    
    def test_get_feed
      vcr_cassette('get_feed') do
        options = {
          account: 'steemit',
          start_entry_id: 0,
          limit: 0
        }
        
        @api.get_feed(options) do |result|
          assert_equal Hashie::Array, result.feed.class
        end
      end
    end
    
    def test_get_feed_entries
      vcr_cassette('get_feed_entries') do
        options = {
          account: 'steemit',
          start_entry_id: 0,
          limit: 0
        }
        
        @api.get_feed_entries(options) do |result|
          assert_equal Hashie::Array, result.feed.class
        end
      end
    end
    
    def test_get_follow_count
      vcr_cassette('get_follow_count') do
        options = {
          account: 'steemit'
        }
        
        @api.get_follow_count(options) do |result|
          assert_equal Hashie::Mash, result.class
          assert_equal 'steemit', result.account
          assert_equal Integer, result.follower_count.class
          assert_equal Integer, result.following_count.class
        end
      end
    end
    
    def test_get_followers
      vcr_cassette('get_followers') do
        options = {
          account: 'steemit',
          start: nil,
          type: 'blog',
          limit: 0
        }
        
        @api.get_followers(options) do |result|
          assert_equal Hashie::Array, result.followers.class
        end
      end
    end
    
    def test_get_following
      vcr_cassette('get_following') do
        options = {
          account: 'steemit',
          start: nil,
          type: 'blog',
          limit: 0
        }
        
        @api.get_following(options) do |result|
          assert_equal Hashie::Array, result.following.class
        end
      end
    end
    
    def test_get_reblogged_by
      vcr_cassette('get_reblogged_by') do
        options = {
          author: 'steemit',
          permlink: 'firstpost'
        }
        
        @api.get_reblogged_by(options) do |result|
          assert_equal Hashie::Array, result.accounts.class
        end
      end
    end
  end
end