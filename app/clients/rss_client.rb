# frozen_string_literal: true

# rbs_inline: enabled

class RssClient < ApplicationClient
  #: (path String) -> RSS::Rss?
  def feed(path)
    RSS::Parser.parse(get(path).body)
  end
end
