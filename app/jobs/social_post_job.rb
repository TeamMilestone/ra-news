# frozen_string_literal: true

# rbs_inline: enabled

class SocialPostJob < ApplicationJob
  queue_as :default

  #: (Integer id) -> void
  def perform(id)
    return unless Rails.env.production?

    article = Article.kept.find_by(id: id)
    logger.info "TwitterPostJob started for article id: #{id}"

    unless article
      logger.error "Article with id #{id} not found or has been discarded."
      retturn nil
    end

    TwitterService.call(article)
  end
end
