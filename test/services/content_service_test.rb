# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

class ContentServiceTest < ActiveSupport::TestCase
  # MockResponse 헬퍼 Struct
  MockResponse = Struct.new(:status, :body, :headers, keyword_init: true) do
    def initialize(status:, body: "", headers: {})
      super
    end
  end

  def setup
    @site = sites(:github_repos)
  end

  # HTML 콘텐츠 가져오기 테스트
  test "execute_html은 HTML 콘텐츠를 성공적으로 가져와 Readability로 파싱한다" do
    article = articles(:ruby_article)
    html_content = "<html><body><article><h1>Test Article</h1><p>This is the main content.</p></article></body></html>"
    expected_content = "<div><h1>Test Article</h1><p>This is the main content.</p></div>"

    # Faraday mock 설정 - Object 사용
    mock_response = MockResponse.new(status: 200, body: html_content)

    # Readability mock 설정
    mock_readability = Object.new
    mock_readability.define_singleton_method(:content) { expected_content }

    service = ContentService.new

    Faraday.stub(:get, mock_response) do
      Readability::Document.stub(:new, mock_readability) do
        result = service.call(article)

        assert result.success?
        assert_equal expected_content, result.value!
      end
    end
  end

  test "execute_html은 빈 콘텐츠일 때 Failure를 반환한다" do
    article = articles(:ruby_article)

    # 빈 body 반환하는 mock
    mock_response = MockResponse.new(status: 200, body: "")

    service = ContentService.new

    Faraday.stub(:get, mock_response) do
      result = service.call(article)

      assert result.failure?
      assert_equal :no_content, result.failure
    end
  end

  test "execute_html은 리다이렉트를 처리한다" do
    article = articles(:ruby_article)
    final_html = "<html><body><article><p>Final content</p></article></body></html>"
    parsed_content = "<div><p>Final content</p></div>"

    call_count = 0

    # Faraday.get stub - 첫 번째는 리다이렉트, 두 번째는 최종 응답
    faraday_stub = ->(_url) {
      call_count += 1
      if call_count == 1
        MockResponse.new(status: 302, body: "", headers: { "location" => "https://example.com/redirected" })
      else
        MockResponse.new(status: 200, body: final_html)
      end
    }

    mock_readability = Object.new
    mock_readability.define_singleton_method(:content) { parsed_content }

    service = ContentService.new

    Faraday.stub(:get, faraday_stub) do
      Readability::Document.stub(:new, mock_readability) do
        result = service.call(article)

        assert result.success?
        assert_equal parsed_content, result.value!
      end
    end

    assert_equal 2, call_count
  end

  test "execute_html은 최대 3회까지만 리다이렉트를 따라간다" do
    article = articles(:ruby_article)
    call_count = 0

    # 무한 리다이렉트 시뮬레이션
    faraday_stub = ->(_url) {
      call_count += 1
      MockResponse.new(status: 302, body: "", headers: { "location" => "https://example.com/redirect#{call_count}" })
    }

    service = ContentService.new

    Faraday.stub(:get, faraday_stub) do
      result = service.call(article)

      # 리다이렉트 응답 자체는 빈 body이므로 no_content
      assert result.failure?
      assert_equal :no_content, result.failure
    end

    # 최대 5회 호출 (초기 + 최대 4회 리다이렉트 시도)
    assert call_count <= 5, "리다이렉트 호출 횟수가 예상보다 많음: #{call_count}"
  end

  # YouTube 콘텐츠 테스트
  test "execute_youtube는 YouTube transcript를 성공적으로 가져온다" do
    article = articles(:youtube_ruby_talk)

    service = ContentService.new

    # Yt::Video mock
    mock_caption = Struct.new(:language).new("en")
    mock_video = Object.new
    mock_video.define_singleton_method(:captions) { [ mock_caption ] }

    # Youtube::Transcript mock
    transcript_response = {
      "actions" => [
        {
          "updateEngagementPanelAction" => {
            "content" => {
              "transcriptRenderer" => {
                "content" => {
                  "transcriptSearchPanelRenderer" => {
                    "body" => {
                      "transcriptSegmentListRenderer" => {
                        "initialSegments" => [
                          {
                            "transcriptSegmentRenderer" => {
                              "startTimeText" => { "simpleText" => "00:00" },
                              "snippet" => { "runs" => [ { "text" => "Hello everyone" } ] }
                            }
                          },
                          {
                            "transcriptSegmentRenderer" => {
                              "startTimeText" => { "simpleText" => "00:05" },
                              "snippet" => { "runs" => [ { "text" => "Welcome to RubyConf" } ] }
                            }
                          }
                        ]
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ]
    }

    Yt::Video.stub(:new, mock_video) do
      Youtube::Transcript.stub(:get, transcript_response) do
        result = service.call(article)

        assert result.success?
        assert_includes result.value!, "Hello everyone"
        assert_includes result.value!, "Welcome to RubyConf"
      end
    end
  end

  test "execute_youtube는 YouTube URL이 아닌 경우 Failure를 반환한다" do
    # is_youtube?가 true이지만 URL에서 ID 추출 실패하는 경우
    article = Article.new(
      title: "Invalid YouTube",
      url: "https://invalid-url.com/not-youtube",
      origin_url: "https://invalid-url.com/not-youtube",
      is_youtube: true
    )

    service = ContentService.new
    result = service.call(article)

    assert result.failure?
    assert_equal :not_youtube, result.failure
  end

  test "execute_youtube는 transcript가 없을 때 Failure를 반환한다" do
    article = articles(:youtube_ruby_talk)

    service = ContentService.new

    # Yt::Video mock - 빈 captions
    mock_video = Object.new
    mock_video.define_singleton_method(:captions) { [] }

    # YoutubeRb 백업도 실패
    mock_api = Object.new
    mock_api.define_singleton_method(:fetch) { |_| nil }

    Yt::Video.stub(:new, mock_video) do
      YoutubeRb::Transcript::YouTubeTranscriptApi.stub(:new, mock_api) do
        result = service.call(article)

        assert result.failure?
        assert_equal :no_content, result.failure
      end
    end
  end

  test "execute_youtube는 YoutubeRb 백업을 사용한다" do
    article = articles(:youtube_ruby_talk)
    backup_transcript = "Backup transcript content"

    service = ContentService.new

    # Yt::Video mock - 빈 captions 반환
    mock_video = Object.new
    mock_video.define_singleton_method(:captions) { [] }

    # YoutubeRb 백업 성공
    mock_transcript_data = [ "segment1", "segment2" ]
    mock_api = Object.new
    mock_api.define_singleton_method(:fetch) { |_| mock_transcript_data }

    mock_formatter = Object.new
    mock_formatter.define_singleton_method(:format_transcript) { |_| backup_transcript }

    Yt::Video.stub(:new, mock_video) do
      YoutubeRb::Transcript::YouTubeTranscriptApi.stub(:new, mock_api) do
        YoutubeRb::Formatters::TextFormatter.stub(:new, mock_formatter) do
          result = service.call(article)

          assert result.success?
          assert_equal backup_transcript, result.value!
        end
      end
    end
  end

  test "execute_youtube는 첫 번째 transcript API 오류 시 백업을 시도한다" do
    article = articles(:youtube_ruby_talk)
    backup_transcript = "Fallback transcript"

    service = ContentService.new

    # Yt::Video mock - captions 접근 시 에러
    mock_video = Object.new
    mock_video.define_singleton_method(:captions) { raise StandardError, "API Error" }

    # YoutubeRb 백업 성공
    mock_transcript_data = [ "segment" ]
    mock_api = Object.new
    mock_api.define_singleton_method(:fetch) { |_| mock_transcript_data }

    mock_formatter = Object.new
    mock_formatter.define_singleton_method(:format_transcript) { |_| backup_transcript }

    Yt::Video.stub(:new, mock_video) do
      YoutubeRb::Transcript::YouTubeTranscriptApi.stub(:new, mock_api) do
        YoutubeRb::Formatters::TextFormatter.stub(:new, mock_formatter) do
          result = service.call(article)

          assert result.success?
          assert_equal backup_transcript, result.value!
        end
      end
    end
  end

  # 헬퍼 메서드 테스트
  test "is_youtube? 확인을 통해 올바른 메서드가 호출된다" do
    # 일반 기사
    regular_article = articles(:ruby_article)
    assert_not regular_article.is_youtube?

    # YouTube 기사
    youtube_article = articles(:youtube_ruby_talk)
    assert youtube_article.is_youtube?
  end

  test "Youtube::Transcript 응답에 error가 있으면 다음 언어를 시도한다" do
    article = articles(:youtube_ruby_talk)

    service = ContentService.new

    # Yt::Video mock - 여러 언어의 captions
    mock_captions = [
      Struct.new(:language).new("ko"),
      Struct.new(:language).new("en")
    ]
    mock_video = Object.new
    mock_video.define_singleton_method(:captions) { mock_captions }

    call_count = 0
    # Youtube::Transcript mock - 첫 번째는 에러, 두 번째는 성공
    transcript_stub = ->(_id, **_opts) {
      call_count += 1
      if call_count == 1
        { "error" => "No transcript for this language" }
      else
        {
          "actions" => [
            {
              "updateEngagementPanelAction" => {
                "content" => {
                  "transcriptRenderer" => {
                    "content" => {
                      "transcriptSearchPanelRenderer" => {
                        "body" => {
                          "transcriptSegmentListRenderer" => {
                            "initialSegments" => [
                              {
                                "transcriptSegmentRenderer" => {
                                  "startTimeText" => { "simpleText" => "00:00" },
                                  "snippet" => { "runs" => [ { "text" => "English transcript" } ] }
                                }
                              }
                            ]
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          ]
        }
      end
    }

    Yt::Video.stub(:new, mock_video) do
      Youtube::Transcript.stub(:get, transcript_stub) do
        result = service.call(article)

        assert result.success?
        assert_includes result.value!, "English transcript"
      end
    end

    assert_equal 2, call_count
  end

  # ========== GitHub URL Detection Tests ==========

  test "GitHub 저장소 URL을 올바르게 감지해야 한다" do
    article = Article.new(url: "https://github.com/rails/rails", site: @site)
    service = ContentService.new

    assert service.send(:github_repo_url?, "https://github.com/rails/rails")
    assert service.send(:github_repo_url?, "https://github.com/anthropics/claude-code")
    assert service.send(:github_repo_url?, "https://www.github.com/owner/repo")
  end

  test "GitHub 저장소가 아닌 URL을 올바르게 구분해야 한다" do
    article = Article.new(url: "https://example.com", site: @site)
    service = ContentService.new

    refute service.send(:github_repo_url?, "https://example.com/page")
    refute service.send(:github_repo_url?, "https://github.com")
    refute service.send(:github_repo_url?, "https://github.com/rails")
    refute service.send(:github_repo_url?, "https://gist.github.com/user/123")
  end

  # ========== GitHub Content Fetching Tests ==========

  test "GitHub 저장소 URL에 대해 execute_github을 호출해야 한다" do
    article = Article.new(url: "https://github.com/rails/rails", site: @site)

    mock_repo_info = {
      url: "https://github.com/rails/rails",
      owner: "rails",
      name: "rails",
      documents: [
        { name: "README.md", content: "# Rails\n\nRuby on Rails framework" }
      ],
      structure: [ "README.md", "Gemfile", "lib/", "test/" ],
      config_files: [
        { name: "Gemfile", content: 'source "https://rubygems.org"' }
      ],
      project_type: :rails,
      recent_commits: [
        { hash: "abc1234", message: "Fix bug", author: "DHH", date: "2024-01-01" }
      ]
    }

    mock_client = Minitest::Mock.new
    mock_client.expect :fetch_repo_info, mock_repo_info

    service = ContentService.new

    GitHubRepoClient.stub :new, mock_client do
      result = service.call(article)

      assert result.success?
      body = result.value!
      assert_includes body, "rails/rails"
      assert_includes body, "Project Type:** rails"
      assert_includes body, "README.md"
      assert_includes body, "Ruby on Rails framework"
      assert_includes body, "Directory Structure"
      assert_includes body, "Recent Commits"
    end

    mock_client.verify
  end

  # ========== Body Formatting Tests ==========

  test "format_repo_body가 올바른 형식의 body를 생성해야 한다" do
    service = ContentService.new

    repo_info = {
      url: "https://github.com/test/repo",
      owner: "test",
      name: "repo",
      documents: [
        { name: "README.md", content: "# Test Repo\n\nThis is a test" }
      ],
      structure: [ "README.md", "src/", "test/" ],
      config_files: [
        { name: "package.json", content: '{"name": "test"}' }
      ],
      project_type: :javascript,
      recent_commits: [
        { hash: "def5678", message: "Initial commit", author: "Tester", date: "2024-01-01" }
      ]
    }

    result = service.send(:format_repo_body, repo_info)

    # 프로젝트 기본 정보
    assert_includes result, "# test/repo"
    assert_includes result, "**Project Type:** javascript"
    assert_includes result, "**URL:** https://github.com/test/repo"

    # 문서
    assert_includes result, "## Documents"
    assert_includes result, "### README.md"
    assert_includes result, "This is a test"

    # 디렉토리 구조
    assert_includes result, "## Directory Structure"
    assert_includes result, "src/"

    # 설정 파일
    assert_includes result, "## Configuration Files"
    assert_includes result, "### package.json"

    # 최근 커밋
    assert_includes result, "## Recent Commits"
    assert_includes result, "def5678"
    assert_includes result, "Initial commit"
  end

  test "빈 섹션은 body에 포함하지 않아야 한다" do
    service = ContentService.new

    repo_info = {
      url: "https://github.com/test/repo",
      owner: "test",
      name: "repo",
      documents: [],
      structure: [],
      config_files: [],
      project_type: :unknown,
      recent_commits: []
    }

    result = service.send(:format_repo_body, repo_info)

    refute_includes result, "## Documents"
    refute_includes result, "## Directory Structure"
    refute_includes result, "## Configuration Files"
    refute_includes result, "## Recent Commits"
  end
end
