# frozen_string_literal: true

class RemoveDuplicateIndexes < ActiveRecord::Migration[8.0]
  def up
    remove_index :sites, name: :index_sites_on_client_and_last_checked if index_exists?(:sites, :index_sites_on_client_and_last_checked)

    remove_index :sites, name: :index_sites_on_last_checked_at if index_exists?(:sites, :index_sites_on_last_checked_at)

    remove_index :taggings, name: :index_taggings_on_context if index_exists?(:taggings, :index_taggings_on_context)

    remove_index :taggings, name: :index_taggings_on_tagger_type_and_tagger_id if index_exists?(:taggings, :index_taggings_on_tagger_type_and_tagger_id)

    remove_index :comments, name: :index_comments_on_article_and_created_at if index_exists?(:comments, :index_comments_on_article_and_created_at)
  end

  def down
  end
end
