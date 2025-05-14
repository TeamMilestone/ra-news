class AddEmailToSite < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :deleted_at, :datetime, null: true
    add_column :sites, :email, :string, null: true
  end
end
