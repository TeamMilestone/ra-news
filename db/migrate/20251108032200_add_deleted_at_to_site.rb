class AddDeletedAtToSite < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :deleted_at, :datetime, null: true
  end
end
