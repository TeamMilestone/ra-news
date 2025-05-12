class AddUniqUrl < ActiveRecord::Migration[8.0]
  def change
    add_index :articles, :url, unique: true
  end
end
