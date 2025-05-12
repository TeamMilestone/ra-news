class Site < ApplicationRecord
  def client
    self[:client].constantize.new(base_uri: base_uri)
  end
end
