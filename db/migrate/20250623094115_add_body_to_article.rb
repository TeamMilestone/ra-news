class AddBodyToArticle < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :body, :text, null: true, comment: "The main content of the article"
  end
end
