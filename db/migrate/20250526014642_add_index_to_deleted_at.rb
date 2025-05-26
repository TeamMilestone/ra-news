class AddIndexToDeletedAt < ActiveRecord::Migration[8.0]
  def change
    add_index :articles, :deleted_at
  end
end
