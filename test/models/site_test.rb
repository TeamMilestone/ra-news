# frozen_string_literal: true

require "test_helper"

class SiteTest < ActiveSupport::TestCase
  # Test validations
  test "should not save site without name" do
    site = Site.new(client: :rss)
    assert_not site.save, "Saved the site without a name"
  end

  test "should not save site without client" do
    site = Site.new(name: "Test Site")
    # Explicitly set client to nil to override the default
    site.client = nil
    assert_not site.save, "Saved the site without a client"
  end

  test "should save site with valid attributes" do
    site = Site.new(
      name: "Test Site",
      client: :rss,
      base_uri: "https://example.com/feed"
    )
    assert site.save, "Could not save the site with valid attributes"
  end

  # Test enum functionality
  test "should have correct client types" do
    assert_includes Site.clients.keys, "rss"
    assert_includes Site.clients.keys, "gmail"
    assert_includes Site.clients.keys, "youtube"
    assert_includes Site.clients.keys, "hacker_news"
  end

  # Test before_create callback
  test "should set last_checked_at on create if blank" do
    site = Site.new(
      name: "Test Site",
      client: :rss,
      base_uri: "https://example.com/feed"
    )
    site.save
    assert_not_nil site.last_checked_at
    assert_equal Time.zone.now.beginning_of_year.to_i, site.last_checked_at.to_i
  end

  test "should not change last_checked_at on create if already set" do
    custom_time = 1.day.ago
    site = Site.new(
      name: "Test Site",
      client: :rss,
      base_uri: "https://example.com/feed",
      last_checked_at: custom_time
    )
    site.save
    assert_equal custom_time.to_i, site.last_checked_at.to_i
  end

  # Test init_client method
  test "init_client should return correct client types" do
    # Test RssClient
    rss_site = sites(:one)
    assert_instance_of RssClient, rss_site.init_client

    # Test Gmail
    gmail_site = Site.new(name: "Gmail Site", client: :gmail)
    assert_instance_of Gmail, gmail_site.init_client

    # Test HackerNews
    hn_site = Site.new(name: "HN Site", client: :hacker_news)
    assert_instance_of HackerNews, hn_site.init_client

    # Test Youtube
    youtube_site = Site.new(name: "YT Site", client: :youtube, channel: "UCxxx")
    assert_instance_of Youtube::Channel, youtube_site.init_client
  end
end
