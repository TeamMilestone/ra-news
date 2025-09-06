# frozen_string_literal: true

# rbs_inline: enabled

class ArticleBatchService < ApplicationService
  attr_reader :created_at #: Time

  #: (?Time created_at) -> ArticleBatchService
  def initialize(created_at = nil)
    @created_at = created_at || Time.zone.now.beginning_of_day
  end

  def call #: void
    Article.kept.where(title_ko: nil, created_at: created_at...).find_each do |article|
      ArticleLmmService.call(article)
      sleep 1
    end
  end
end
