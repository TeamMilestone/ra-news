# frozen_string_literal: true

# rbs_inline: enabled

class RssClient < ApplicationClient
  #: (path String) -> RSS::Rss?
  def feed(path)
    response = get(path)
    if response.status.between?(300, 399) && response.headers["location"]
      response = get(response.headers["location"])
    end
    RSS::Parser.parse(response.body)
 end
end
