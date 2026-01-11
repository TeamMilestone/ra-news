# frozen_string_literal: true

# rbs_inline: enabled

class SocialDeleteJob < ApplicationJob
  queue_as :default

  #: (Integer id) -> void
  def perform(id)
    return unless Rails.env.production?

    article = Article.kept.find_by(id: id)
    TwitterService.call(article, command: :delete)
    MastodonService.call(article, command: :delete)
  end
end
