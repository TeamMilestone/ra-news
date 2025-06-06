# frozen_string_literal: true

# rbs_inline: enabled

class HackerNewsSiteJob < ApplicationJob
  def perform
    # Fetch top stories from Hacker News
    client = HackerNews.new
    top_story_ids = client.top_stories

    # Process each story ID
    top_story_ids.each do |id|
      item = client.item(id)

      next if item.nil? || item["type"] != "story"

      url = item["url"]
      parsed_url = URI.parse(url)
      next if parsed_url.path.nil? || parsed_url.path.size < 2 || Article::IGNORE_HOSTS.any? { |pattern| parsed_url.host&.match?(/#{pattern}/i) }

      logger.debug url

      logger.debug item["title"]

      logger.debug item["text"]

      tag_ids = ActsAsTaggableOn::Tagging.group(:tag_id).count.sort_by { |_tag_id, count| -count }.select { it.last > 5 }.map { it.first }
      tags = Tag.where(id: tag_ids, is_confirmed: true).map(&:name)


      # Skip if the item is not valid or already exists
      next if Article.exists?(origin_url: item["url"])

      # # Create a new article with the fetched data
      # Article.create(
      #   title: item["title"],
      #   url: item["url"],
      #   origin_url: item["url"],
      #   published_at: Time.at(item["time"]),
      #   created_at: Time.zone.now,
      #   updated_at: Time.zone.now
      # )
    end
  end
end
