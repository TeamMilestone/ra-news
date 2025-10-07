# frozen_string_literal: true

# rbs_inline: enabled

class Preference < ApplicationRecord
  after_initialize :define_dynamic_accessors, if: -> { persisted? && name.present? }

  after_save do
    Rails.cache.delete(name)
  end

  def value=(val)
    super(val.is_a?(String) ? JSON.parse(val) : val)
  rescue JSON::ParserError
    super({})
  end

  #: (String name) -> Hash[String, untyped] || Array[untyped]
  def self.get_value(name)
    Rails.cache.fetch(name) {
      Preference.find_by(name:)&.value
    }
  end

  def self.ignore_hosts #: Array[String]
    get_value("ignore_hosts")
  end

  # OAuth 클라이언트 생성 (provider 이름으로 preference를 조회)
  #: (String provider) -> OAuth2::Client
  def self.oauth_client(provider)
    oauth_config = get_value("#{provider}_oauth")
    raise ArgumentError, "OAuth 설정이 비어있습니다: #{provider}_oauth" if oauth_config.blank?

    OAuth2::Client.new(
      oauth_config["client_id"],
      oauth_config["client_secret"],
      site: oauth_config["site"] || default_oauth_site(provider),
      authorize_url: authorize_url(provider),
      token_url: token_url(provider)
    )
  end

  private

  def self.default_oauth_site(provider)
    case provider
    when "xcom"
      "https://api.x.com"
    when "google"
      "https://accounts.google.com"
    else
      "https://#{provider}.com"
    end
  end

  def self.authorize_url(provider)
    case provider
    when "xcom"
      "https://x.com/i/oauth2/authorize"
    when "google"
      "https://accounts.google.com/o/oauth2/v2/auth"
    else
      "https://#{provider}.com/oauth2/authorize"
    end
  end

  def self.token_url(provider)
    case provider
    when "xcom"
      "https://api.x.com/2/oauth2/token"
    when "google"
      "https://oauth2.googleapis.com/token"
    else
      "https://#{provider}.com/oauth2/token"
    end
  end

  def define_dynamic_accessors
    # This is an example configuration.
    # You should adjust this case statement to your needs.
    accessors = case name
    when "ignore_hosts" # Example name
                  [ :hosts ]
    # Add other cases for other preference names
    when /_oauth$/
      # Common keys for OAuth preferences
      [ :site, :client_id, :client_secret, :access_token, :refresh_token, :expires_at, :token_created_at ]
    else
                  []
    end

    accessors.each do |key|
      # Define getter
      define_singleton_method(key) do
        value.is_a?(Hash) ? value&.[](key.to_s) : value
      end

      # Define setter
      define_singleton_method("#{key}=") do |new_value|
        self.value = value.is_a?(Hash) ? (value || {}).merge(key.to_s => new_value) : value
      end
    end
  end
end
