class ChangeClientEnumFromSite < ActiveRecord::Migration[8.0]
  def change
    if Rails.env.test?
      change_column :sites, :client, :integer, default: 0, null: false
    else
      change_column :sites, :client, :integer, using: 'client::integer', default: 0, null: false
    end
  end
end
