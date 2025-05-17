class AddSlugToArticle < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :slug, :string, null: true
    add_index :articles, :slug, unique: true
  end
end
