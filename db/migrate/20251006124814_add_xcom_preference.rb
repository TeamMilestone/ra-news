class AddXcomPreference < ActiveRecord::Migration[8.0]
  def up
    Preference.create(name: 'xcom_oauth',
      value: { client_id: 'client_id', client_secret: 'client_secret',
        site: 'https://api.x.com' }
    )
  end

  def down
    Preference.destroy_all(name: 'xcom')
  end
end
