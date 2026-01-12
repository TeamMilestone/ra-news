# frozen_string_literal: true

# rbs_inline: enabled

class GitHubSiteJob < ApplicationJob
  queue_as :default

  # GitHub 저장소 URL을 받아 Article을 생성
  #: (String repo_url, ?site_id: Integer?) -> void
  def perform(repo_url, site_id: nil)
    # URL 정규화 및 유효성 검증
    normalized_url = GitHubRepoClient.normalize_url(repo_url)
    validate_github_url!(normalized_url)

    logger.info "GitHubSiteJob: 저장소 처리 시작 - #{normalized_url}"

    if Article.exists?(origin_url: normalized_url)
      logger.info "GitHubSiteJob: 이미 존재하는 저장소, 스킵 - #{normalized_url}"
      return
    end

    site = find_or_create_site(site_id)
    article = create_article_from_repo(normalized_url, site)

    logger.info "GitHubSiteJob: Article 생성 완료 - ID: #{article.id}, #{normalized_url}"

    # AI 요약 생성을 위해 ArticleJob 호출 (ContentService에서 body 생성)
    ArticleJob.perform_later(article.id)
  end

  private

  DEFAULT_GITHUB_SITE_NAME = "GitHub Repositories".freeze

  #: (Integer? site_id) -> Site
  def find_or_create_site(site_id)
    return Site.find(site_id) if site_id

    Site.find_or_create_by!(name: DEFAULT_GITHUB_SITE_NAME, client: :github) do |site|
      site.base_uri = "https://github.com"
    end
  end

  #: (String normalized_url, Site site) -> Article
  def create_article_from_repo(normalized_url, site)
    # URL에서 owner/repo 추출하여 title 생성
    title = extract_repo_title(normalized_url)

    # body는 ContentService에서 생성 (ArticleJob 호출 시)
    Article.create!(
      url: normalized_url,
      origin_url: normalized_url,
      title: title,
      host: "github.com",
      site: site,
      published_at: Time.zone.now
    )
  end

  #: (String url) -> String
  def extract_repo_title(url)
    match = url.match(%r{github\.com/([^/]+)/([^/]+)})
    return url unless match

    "#{match[1]}/#{match[2]}"
  end

  #: (String url) -> void
  def validate_github_url!(url)
    uri = URI.parse(url)
    unless uri.host == "github.com" || uri.host == "www.github.com"
      raise GitHubRepoClient::InvalidUrlError, "Invalid GitHub URL: #{url}"
    end

    path_parts = uri.path.to_s.split("/").reject(&:empty?)
    unless path_parts.length >= 2
      raise GitHubRepoClient::InvalidUrlError, "Invalid GitHub repository URL: #{url}"
    end
  end
end
