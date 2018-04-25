require 'test_helper'

module Steem
  class TagsApiTest < Steem::Test
    def setup
      @api = Steem::TagsApi.new
      @jsonrpc = Jsonrpc.new
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    end
    def test_api_class_name
      assert_equal 'TagsApi', Steem::TagsApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<TagsApi [@chain=steem, @url=https://api.steemit.com]>", @api.inspect
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
    
    def test_get_active_votes
      vcr_cassette('get_active_votes') do
        options = {
          author: 'steemit',
          permlink: 'firstpost'
        }
        
        @api.get_active_votes(options) do |result|
          assert_equal Hashie::Array, result.votes.class
        end
      end
    end
    
    def test_get_comment_discussions_by_payout
      vcr_cassette('get_comment_discussions_by_payout') do
        options = {
          tag: "",
          limit: 0,
          filter_tags: [],
          select_authors: [],
          select_tags: [],
          truncate_body:0
        }
        
        @api.get_comment_discussions_by_payout(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_content_replies
      vcr_cassette('get_content_replies') do
        options = {
          author: 'steemit',
          permlink: 'firstpost'
        }
        
        @api.get_content_replies(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_discussion
      vcr_cassette('get_discussion') do
        options = {
          author: 'steemit',
          permlink: 'firstpost'
        }
        
        @api.get_discussion(options) do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_discussions_by_active
      vcr_cassette('get_discussions_by_active') do
        options = {
          tag: "",
          limit: 0,
          filter_tags: [],
          select_authors: [],
          select_tags: [],
          truncate_body:0
        }
        
        @api.get_discussions_by_active(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_discussions_by_author_before_date
      vcr_cassette('get_discussions_by_author_before_date') do
        options = {
          author: 'steemit',
          permlink: 'firstpost'
        }
        
        @api.get_discussions_by_author_before_date(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_discussions_by_blog
      vcr_cassette('get_discussions_by_blog') do
        options = {
          tag: 'steemit',
          limit: 0
        }
        
        @api.get_discussions_by_blog(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_discussions_by_cashout
      vcr_cassette('get_discussions_by_cashout') do
        options = {
          tag: 'steem',
          limit: 0
        }
        
        @api.get_discussions_by_cashout(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_discussions_by_children
      vcr_cassette('get_discussions_by_children') do
        options = {
          tag: 'steem',
          limit: 0
        }
        
        @api.get_discussions_by_children(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_discussions_by_comments
      vcr_cassette('get_discussions_by_comments') do
        options = {
          start_author: 'steemit',
          start_permlink: 'firstpost',
          limit: 0
        }
        
        @api.get_discussions_by_comments(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_discussions_by_created
      vcr_cassette('get_discussions_by_created') do
        options = {
          tag: 'steem',
          limit: 0
        }
        
        @api.get_discussions_by_created(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_discussions_by_feed
      vcr_cassette('get_discussions_by_feed') do
        options = {
          tag: 'steem',
          limit: 0
        }
        
        @api.get_discussions_by_feed(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_discussions_by_hot
      vcr_cassette('get_discussions_by_hot') do
        options = {
          tag: 'steem',
          limit: 0
        }
        
        @api.get_discussions_by_hot(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_discussions_by_promoted
      vcr_cassette('get_discussions_by_promoted') do
        options = {
          tag: 'steem',
          limit: 0
        }
        
        @api.get_discussions_by_promoted(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_discussions_by_trending
      vcr_cassette('get_discussions_by_trending') do
        options = {
          tag: 'steem',
          limit: 0
        }
        
        @api.get_discussions_by_trending(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_discussions_by_votes
      vcr_cassette('get_discussions_by_votes') do
        options = {
          tag: 'steem',
          limit: 0
        }
        
        @api.get_discussions_by_votes(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_post_discussions_by_payout
      vcr_cassette('get_post_discussions_by_payout') do
        options = {
          tag: 'steem',
          limit: 0
        }
        
        @api.get_post_discussions_by_payout(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_replies_by_last_update
      vcr_cassette('get_replies_by_last_update') do
        options = {
          start_parent_author: 'steemit',
          start_permlink: 'firstpost',
          limit: 0
        }
        
        @api.get_replies_by_last_update(options) do |result|
          assert_equal Hashie::Array, result.discussions.class
        end
      end
    end
    
    def test_get_tags_used_by_author
      vcr_cassette('get_tags_used_by_author') do
        @api.get_tags_used_by_author(author: 'steemit') do |result|
          assert_equal Hashie::Array, result.tags.class
        end
      end
    end
    
    def test_get_tags_used_by_author_bad_account
      vcr_cassette('get_tags_used_by_author') do
        assert_raises RuntimeError do
          @api.get_tags_used_by_author(author: 'ste emit')
        end
      end
    end
    
    def test_get_trending_tags
      vcr_cassette('get_trending_tags') do
        @api.get_trending_tags(start_tag: '', limit: 0) do |result|
          assert_equal Hashie::Array, result.tags.class
        end
      end
    end
  end
end