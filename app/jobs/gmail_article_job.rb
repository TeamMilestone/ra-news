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

    links = site.init_client.fetch_email_links(from: site.email)
    return if links.empty?

    logger.debug links
    links.each do |link|
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
end
