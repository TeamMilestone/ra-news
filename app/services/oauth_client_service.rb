# frozen_string_literal: true

# rbs_inline: enabled

# OAuth 클라이언트 생성 및 관리 서비스
class OauthClientService < ApplicationService
  attr_reader :provider #: String

  #: (String provider) -> OauthClientService
  def initialize(provider)
    @provider = provider
  end

  # OAuth 클라이언트 생성
  def call #: OAuth2::Client
    oauth_config = Preference.get_object("#{provider}_oauth")
    raise ArgumentError, "OAuth 설정이 비어있습니다: #{provider}_oauth" if oauth_config.blank?

    client = OAuth2::Client.new(
      oauth_config.client_id,
      oauth_config.client_secret,
      site: oauth_config.site|| default_site,
      authorize_url: authorize_url,
      token_url: token_url
    )

    check_token(client, oauth_config)
  end

  private

  def check_token(client, config)
    token = OAuth2::AccessToken.from_hash(client,
      {
        access_token: config.access_token,
        refresh_token: config.refresh_token,
        expires_at: config.expires_at
      }
    )

    if token.expired?
      token = token.refresh!
      config.update(access_token: token.token,
        refresh_token: token.refresh_token,
        expires_at: token.expires_at
      )
    end
    token
  end

  # OAuth 기본 사이트 URL
  #: (String provider) -> String
  def default_site
    case provider
    when "xcom"
      "https://api.x.com/2/"
    when "google"
      "https://accounts.google.com"
    else
      "https://#{provider}.com"
    end
  end

  # OAuth 인증 URL
  #: (String provider) -> String
  def authorize_url
    case provider
    when "xcom"
      "https://x.com/i/oauth2/authorize"
    when "google"
      "https://accounts.google.com/o/oauth2/v2/auth"
    else
      "https://#{provider}.com/oauth2/authorize"
    end
  end

  # OAuth 토큰 URL
  #: (String provider) -> String
  def token_url
    case provider
    when "xcom"
      "https://api.x.com/2/oauth2/token"
    when "google"
      "https://oauth2.googleapis.com/token"
    else
      "https://#{provider}.com/oauth2/token"
    end
  end
end
