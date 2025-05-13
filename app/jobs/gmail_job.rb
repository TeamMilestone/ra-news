# frozen_string_literal: true

# rbs_inline: enabled

class GmailJob < ApplicationJob
  def perform
    links = Gmail.new.fetch_email_links
  end
end
