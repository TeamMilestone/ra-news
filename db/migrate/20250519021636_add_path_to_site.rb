class AddPathToSite < ActiveRecord::Migration[8.0]
  def change
    add_column :sites, :path, :string, null: true
  end
end
