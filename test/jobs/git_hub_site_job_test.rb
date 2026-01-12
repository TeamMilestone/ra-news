# frozen_string_literal: true

require "test_helper"

class GitHubSiteJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @github_site = sites(:github_repos)
    @repo_url = "https://github.com/rails/rails"
  end

  # ========== Job Execution Tests ==========

  test "저장소 URL로 Article을 생성해야 한다" do
    assert_difference "Article.count", 1 do
      ArticleJob.stub :perform_later, true do
        GitHubSiteJob.perform_now(@repo_url, site_id: @github_site.id)
      end
    end

    article = Article.last
    assert_equal @repo_url, article.origin_url
    assert_equal "rails/rails", article.title
    assert_equal "github.com", article.host
    assert_equal @github_site, article.site
    assert_nil article.body, "body는 ContentService에서 생성되어야 함"
  end

  test "이미 존재하는 URL에 대해 중복 Article을 생성하지 않아야 한다" do
    # 먼저 Article 생성
    Article.create!(
      url: @repo_url,
      origin_url: @repo_url,
      title: "Existing Article",
      site: @github_site
    )

    assert_no_difference "Article.count" do
      GitHubSiteJob.perform_now(@repo_url, site_id: @github_site.id)
    end
  end

  test "Site와 연결하여 Article을 생성할 수 있어야 한다" do
    site = Site.create!(name: "Custom GitHub Repos", client: :github, base_uri: @repo_url)

    ArticleJob.stub :perform_later, true do
      GitHubSiteJob.perform_now(@repo_url, site_id: site.id)
    end

    article = Article.last
    assert_equal site, article.site
  end

  test "Article 생성 후 ArticleJob을 호출해야 한다" do
    article_job_called = false

    ArticleJob.stub :perform_later, ->(id) { article_job_called = true } do
      GitHubSiteJob.perform_now(@repo_url, site_id: @github_site.id)
    end

    assert article_job_called, "ArticleJob should be called after creating article"
  end

  # ========== URL Normalization Tests ==========

  test "URL을 정규화하여 저장해야 한다" do
    url_with_trailing_slash = "https://github.com/rails/rails/"

    ArticleJob.stub :perform_later, true do
      GitHubSiteJob.perform_now(url_with_trailing_slash, site_id: @github_site.id)
    end

    article = Article.last
    assert_equal "https://github.com/rails/rails", article.origin_url
  end

  test "URL에서 owner/repo를 추출하여 title을 설정해야 한다" do
    ArticleJob.stub :perform_later, true do
      GitHubSiteJob.perform_now("https://github.com/anthropics/claude-code", site_id: @github_site.id)
    end

    article = Article.last
    assert_equal "anthropics/claude-code", article.title
  end

  # ========== Site Creation Tests ==========

  test "site_id가 없으면 기본 GitHub Site를 생성해야 한다" do
    ArticleJob.stub :perform_later, true do
      GitHubSiteJob.perform_now(@repo_url)
    end

    article = Article.last
    assert_equal "GitHub Repositories", article.site.name
    assert_equal "github", article.site.client
  end

  # ========== Error Handling Tests ==========

  test "잘못된 URL에 대해 오류를 발생시켜야 한다" do
    assert_raises(GitHubRepoClient::InvalidUrlError) do
      GitHubSiteJob.perform_now("https://invalid-url.com", site_id: @github_site.id)
    end
  end

  # ========== Queue Configuration Tests ==========

  test "default 큐에서 실행되어야 한다" do
    assert_equal "default", GitHubSiteJob.new.queue_name
  end
end
