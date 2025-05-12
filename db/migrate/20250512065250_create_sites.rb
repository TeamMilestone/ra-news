class CreateSites < ActiveRecord::Migration[8.0]
  def change
    create_table :sites do |t|
      t.string :name, null: false
      t.string :base_uri, null: false
      t.string :client, null: false
      t.datetime :last_checked_at
      t.timestamps
    end
  end
end
