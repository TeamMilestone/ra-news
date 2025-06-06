class AddIsConfirmedToTag < ActiveRecord::Migration[8.0]
  def change
    add_column :tags, :is_confirmed, :boolean, default: false, null: false
  end
end
