# frozen_string_literal: true

# rbs_inline: enabled

class ContentService < Dry::Operation
  include LinkHelper

  def call(article)
    if article.is_youtube?
      # YouTube URL인 경우
      step execute_youtube(article.url)
    else
      # YouTube URL이 아닌 경우
      step execute_html(article.url)
    end
  end

  protected

  #: (url: String) -> String?
  def execute_html(url)
    # GitHub 저장소 URL인 경우 별도 처리
    if github_repo_url?(url)
      return execute_github(url)
    end

    logger.info "Fetching HTML content from: #{url}"
    html_content = handle_redirection(url).body
    return Failure(:no_content) if html_content.blank?

    # Readability를 사용하여 주요 콘텐츠 HTML 추출. Readability::Document는 전체 HTML 문자열을 인자로 받습니다.
    Success(Readability::Document.new(html_content).content)
  end

  #: (url: String) -> String?
  def execute_github(url)
    logger.info "Fetching GitHub repo content from: #{url}"

    client = GitHubRepoClient.new(repo_url: url)
    repo_info = client.fetch_repo_info
    logger.debug "GitHubRepoClient: 저장소 정보 수집 완료 - 프로젝트 타입: #{repo_info[:project_type]}"

    Success(format_repo_body(repo_info))
  end

  #: (String) -> bool
  def github_repo_url?(url)
    uri = URI.parse(url)
    # github.com 또는 www.github.com만 허용 (gist.github.com 등 제외)
    return false unless uri.host == "github.com" || uri.host == "www.github.com"

    # GitHub 저장소 URL 패턴: github.com/owner/repo
    path_parts = uri.path.to_s.split("/").reject(&:empty?)
    path_parts.length >= 2
  rescue URI::InvalidURIError
    false
  end

  def format_repo_body(repo_info)
    sections = []

    # 프로젝트 기본 정보
    sections << "# #{repo_info[:owner]}/#{repo_info[:name]}"
    sections << ""
    sections << "**Project Type:** #{repo_info[:project_type]}"
    sections << "**URL:** #{repo_info[:url]}"
    sections << ""

    # 문서 파일들
    if repo_info[:documents].any?
      sections << "## Documents"
      sections << ""
      repo_info[:documents].each do |doc|
        sections << "### #{doc[:name]}"
        sections << ""
        sections << doc[:content]
        sections << ""
      end
    end

    # 디렉토리 구조
    if repo_info[:structure].any?
      sections << "## Directory Structure"
      sections << ""
      sections << "```"
      sections << repo_info[:structure].join("\n")
      sections << "```"
      sections << ""
    end

    # 설정 파일들
    if repo_info[:config_files].any?
      sections << "## Configuration Files"
      sections << ""
      repo_info[:config_files].each do |config|
        sections << "### #{config[:name]}"
        sections << ""
        sections << "```"
        sections << config[:content]
        sections << "```"
        sections << ""
      end
    end

    # 최근 커밋
    if repo_info[:recent_commits].any?
      sections << "## Recent Commits"
      sections << ""
      repo_info[:recent_commits].each do |commit|
        sections << "- #{commit[:hash]} #{commit[:message]} (#{commit[:author]}, #{commit[:date]})"
      end
      sections << ""
    end

    sections.join("\n")
  end

  #: (url: String) -> String?
  def execute_youtube(url)
    logger.info "Fetching Youtube content from: #{url}"
    youtube_id = youtube_id(url)
    logger.info "Youtube ID: #{youtube_id}"
    return Failure(:not_youtube) unless youtube_id

    transcript = nil
    video = Yt::Video.new id: youtube_id
    begin
      video.captions.map(&:language).each do |lang|
        rc = Youtube::Transcript.get(youtube_id, lang: lang)
        next if rc["error"].present?

        transcript = format_transcript(rc.dig("actions"))
        break if transcript.present?
      end
    rescue StandardError => e
      logger.error "Error fetching Youtube transcript: #{e.message}"
    end

    if transcript.blank?
      begin
        fetched_transcript = YoutubeRb::Transcript::YouTubeTranscriptApi.new.fetch(youtube_id)
        transcript = YoutubeRb::Formatters::TextFormatter.new.format_transcript(fetched_transcript) if fetched_transcript.present?
      rescue StandardError => e
        logger.error "Error fetching Youtube transcript: #{e.message}"
      end
    end

    return Failure(:no_content) if transcript.blank?

    Success(transcript)
  end

  private

  #: (String url, ?Integer? count) -> Faraday::Response
  def handle_redirection(url, count = 0)
    response = Faraday.get(url)
    logger.debug "#{response.status} #{url}"
    return response unless response.status.between?(300, 399) && response.headers["location"]
    return response if count > 3

    logger.debug response.headers["location"]
    # 3xx 응답인 경우 리다이렉트된 URL을 사용
    redirect_url = response.headers["location"]
    url = if redirect_url.start_with?("http")
            redirect_url
    else
            URI.join(url, redirect_url).to_s
    end
    logger.debug "Redirecting to: #{url}"

    handle_redirection(url, count + 1)
  end

  def format_transcript(actions)
    tsr = actions&.first&.dig("updateEngagementPanelAction", "content", "transcriptRenderer", "content", "transcriptSearchPanelRenderer", "body", "transcriptSegmentListRenderer", "initialSegments")
    return nil if tsr.nil? || tsr.empty?

    tsr.map { |it| "#{it.dig("transcriptSegmentRenderer", "startTimeText", "simpleText")} - #{it.dig("transcriptSegmentRenderer", "snippet", "runs")&.map { |run| run.dig("text") }&.join(" ")}" }.join("\n") # Use string interpolation for clarity
  end

  def logger
    Rails.logger
  end
end
