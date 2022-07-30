require 'test_helper'

module Steem
  class TagsApiTest < Steem::Test
    def setup
      skip 'tags_api not supported'

      @api = Steem::TagsApi.new(url: TEST_NODE)
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    end
    def test_api_class_name
      assert_equal 'TagsApi', Steem::TagsApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<TagsApi [@chain=steem, @methods=<20 elements>]>", @api.inspect
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
      vcr_cassette('tags_api_get_active_votes', record: :once) do
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
      vcr_cassette('tags_api_get_comment_discussions_by_payout', record: :once) do
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
      vcr_cassette('tags_api_get_content_replies', record: :once) do
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
      vcr_cassette('tags_api_get_discussion', record: :once) do
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
      vcr_cassette('tags_api_get_discussions_by_active', record: :once) do
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
      vcr_cassette('tags_api_get_discussions_by_author_before_date', record: :once) do
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
      vcr_cassette('tags_api_get_discussions_by_blog', record: :once) do
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
      vcr_cassette('tags_api_get_discussions_by_cashout', record: :once) do
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
      vcr_cassette('tags_api_get_discussions_by_children', record: :once) do
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
      vcr_cassette('tags_api_get_discussions_by_comments', record: :once) do
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
      vcr_cassette('tags_api_get_discussions_by_created', record: :once) do
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
      vcr_cassette('tags_api_get_discussions_by_feed', record: :once) do
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
      vcr_cassette('tags_api_get_discussions_by_hot', record: :once) do
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
      vcr_cassette('tags_api_get_discussions_by_promoted', record: :once) do
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
      vcr_cassette('tags_api_get_discussions_by_trending', record: :once) do
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
      vcr_cassette('tags_api_get_discussions_by_votes', record: :once) do
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
      vcr_cassette('tags_api_get_post_discussions_by_payout', record: :once) do
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
      vcr_cassette('tags_api_get_replies_by_last_update', record: :once) do
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
      vcr_cassette('tags_api_get_tags_used_by_author', record: :once) do
        @api.get_tags_used_by_author(author: 'steemit') do |result|
          assert_equal Hashie::Array, result.tags.class
        end
      end
    end
    
    def test_get_tags_used_by_author_bad_account
      vcr_cassette('tags_api_get_tags_used_by_author_bad_account', record: :once) do
        assert_raises AuthorNotFoundError do
          @api.get_tags_used_by_author(author: 'ste emit')
        end
      end
    end
    
    def test_get_trending_tags
      vcr_cassette('tags_api_get_trending_tags', record: :once) do
        @api.get_trending_tags(start_tag: '', limit: 0) do |result|
          assert_equal Hashie::Array, result.tags.class
        end
      end
    end
  end
end
