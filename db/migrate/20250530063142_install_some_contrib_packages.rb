class InstallSomeContribPackages < ActiveRecord::Migration[8.0]
  def up
    execute "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;" unless Rails.env.test?
    execute "CREATE EXTENSION IF NOT EXISTS pg_bigm;" unless Rails.env.test?
  end

  def down
    execute "DROP EXTENSION IF EXISTS fuzzystrmatch;" unless Rails.env.test?
    execute "DROP EXTENSION IF EXISTS pg_bigm;" unless Rails.env.test?
  end
end
