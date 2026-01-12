# frozen_string_literal: true

# rbs_inline: enabled

class Site < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  has_many :articles, dependent: :destroy

  validates :name, :client, presence: true

  before_create do
    self.last_checked_at = 6.months.ago if last_checked_at.blank?
  end

  enum :client, [ :rss, :gmail, :youtube, :hacker_news, :rss_page, :github ], default: :rss

  def init_client #: Object
    case client
    when "rss", "rss_page"
      RssClient.new(base_uri: base_uri)
    when "gmail"
      Gmail.new
    when "hacker_news"
      HackerNews.new
    when "youtube"
        return nil if channel.blank?
        Youtube::Channel.new(id: channel)
    # GitHub은 개별 저장소 URL을 받아 처리하므로 init_client 패턴에 맞지 않음
    # GitHubSiteJob에서 직접 클라이언트를 생성함
    when "github"
      raise ArgumentError, "GitHub client should be initialized directly with repo_url in GitHubSiteJob"
    else
      raise ArgumentError, "Unsupported client type: #{client}"
    end
  end
end
