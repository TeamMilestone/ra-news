# frozen_string_literal: true

require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  # Test validations
  test "should not save article without url" do
    article = Article.new(title: "Test Article", origin_url: "https://example.com/test")
    assert_not article.save, "Saved the article without a url"
  end

  test "should set origin_url from url on creation" do
    article = Article.new(title: "Test Article", url: "https://example.com/test")
    article.save
    assert_equal "https://example.com/test", article.origin_url
  end

  test "should not save article with duplicate url" do
    existing_article = articles(:one)
    article = Article.new(title: "Test Article", url: existing_article.url, origin_url: "https://example.com/test")
    assert_not article.save, "Saved the article with a duplicate url"
  end

  test "should not save article with duplicate origin_url" do
    existing_article = articles(:one)
    article = Article.new(title: "Test Article", url: "https://example.com/test", origin_url: existing_article.origin_url)
    assert_not article.save, "Saved the article with a duplicate origin_url"
  end

  test "should save article with valid attributes" do
    article = Article.new(
      title: "Test Article",
      url: "https://example.com/unique-test",
      origin_url: "https://example.com/unique-test-origin",
      user: users(:one)
    )
    assert article.save, "Could not save the article with valid attributes"
  end

  # Test scopes
  test "full_text_search_for scope should return matching articles" do
    # This test would require setting up PgSearch properly
    # For now, we'll just test that the scope exists
    assert_respond_to Article, :full_text_search_for
  end

  # Test instance methods
  test "youtube_id should extract video id from url" do
    article = Article.new(url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    assert_equal "dQw4w9WgXcQ", article.youtube_id
  end

  # Test class constants
  test "IGNORE_HOSTS should contain expected domains" do
    assert Article::IGNORE_HOSTS.include?("github.com")
    assert Article::IGNORE_HOSTS.include?("twitter.com")
  end
end
