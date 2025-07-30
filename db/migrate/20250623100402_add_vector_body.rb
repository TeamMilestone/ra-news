class AddVectorBody < ActiveRecord::Migration[8.0]
  def up
    enable_extension "vector" unless Rails.env.test?
    execute "ALTER TABLE articles ADD COLUMN embedding vector(768);" unless Rails.env.test?
  end

  def down
    remove_column :articles, :embedding, :vector unless Rails.env.test?
  end
end
