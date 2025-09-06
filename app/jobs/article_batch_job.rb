# frozen_string_literal: true

# rbs_inline: enabled

class ArticleBatchJob < ApplicationJob
  queue_as :default

  def perform #: void
    ArticleBatchService.call
  end
end
