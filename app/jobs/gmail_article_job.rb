# frozen_string_literal: true

# rbs_inline: enabled

class GmailArticleJob < ApplicationJob
  #: (id Integer) -> void
  def perform(id = nil)
    if id.nil?
      Site.gmail.map { GmailArticleJob.perform_later(it.id) }
      return
    end

    site = Site.find_by(id: id)
    return if site.nil? || site.email.nil?

    links = site.init_client.fetch_email_links(from: site.email, since: site.last_checked_at - 1.days)
    return if links.empty?

    links.each do |link|
      link = extract_link(link)
      next if link.nil?

      logger.info link

      next if Article.exists?(origin_url: link)

      begin
        Article.create(url: link, origin_url: link, site: site)
        logger.info "Created article for #{link}"
      rescue StandardError => e
        logger.error e
      end
    end

    site.update(last_checked_at: Time.zone.now)
  end

  def extract_link(link)
    target = case URI.parse(link).host
    when "maily.so", "www.libhunt.com"
             extract_params(link)
    when "rubyweekly.com"
             link.start_with?("https://rubyweekly.com/link") ? extract_location(link) : nil
    else
             link
    end
    return nil if target.nil?

    uri = URI.parse(target)
    return nil if uri.path.nil? || uri.path.size < 2 || Article::IGNORE_HOSTS.any? { |pattern| uri.host&.match?(/#{pattern}/i) }

    target
  end

  def extract_params(link)
    uri = URI.parse(link)
    if uri.respond_to?(:query) && uri.query
      # 쿼리 문자열을 해시(맵)으로 변환
      query_params = URI.decode_www_form(uri.query || "").to_h
      query_params["url"].present? ? query_params["url"] : nil
    else
      nil
    end
  end

  def extract_location(link)
    resp = Faraday.get(link)
    return link if resp.status == 200

    if resp.headers["location"].present?
      resp.headers["location"]
    else
      nil
    end
  end
end
