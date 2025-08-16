# frozen_string_literal: true

class AddMissingIndexes < ActiveRecord::Migration[8.0]
  def change
    # Performance indexes for Article model
    add_index :articles, :published_at, name: "index_articles_on_published_at"
    add_index :articles, [ :site_id, :published_at ], name: "index_articles_on_site_and_published_at"
    add_index :articles, [ :is_related, :published_at ], name: "index_articles_on_related_and_published_at"
    add_index :articles, :host, name: "index_articles_on_host"

    # Performance indexes for comments
    add_index :comments, [ :article_id, :created_at ], name: "index_comments_on_article_and_created_at"

    # Performance indexes for sites
    add_index :sites, :last_checked_at, name: "index_sites_on_last_checked_at"
    add_index :sites, [ :client, :last_checked_at ], name: "index_sites_on_client_and_last_checked"
  end
end
