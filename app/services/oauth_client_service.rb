# frozen_string_literal: true

# rbs_inline: enabled

# OAuth 클라이언트 생성 및 관리 서비스
class OauthClientService < ApplicationService
  attr_reader :provider #: String

  OAUTH_CONFIG = {
    xcom: {
      default_site: "https://api.x.com/2/",
      authorize_url: "https://x.com/i/oauth2/authorize",
      token_url: "https://api.x.com/2/oauth2/token"
    },
    mastodon: {
      default_site: "https://mastodon.social",
      authorize_url: "https://mastodon.social/oauth/authorize",
      token_url: "https://mastodon.social/oauth/token"
    }
  }.freeze #: Hash<String, Hash<String, String>>

  #: (String provider) -> OauthClientService
  def initialize(provider)
    @provider = provider
  end

  # OAuth 클라이언트 생성
  def call #: OAuth2::AccessToken
    oauth_config = Preference.get_object("#{provider}_oauth")
    raise ArgumentError, "OAuth 설정이 비어있습니다: #{provider}_oauth" if oauth_config.blank?

    OAUTH_CONFIG[provider.to_sym][:default_site]
    client = OAuth2::Client.new(
      oauth_config.client_id,
      oauth_config.client_secret,
      site: oauth_config.site || OAUTH_CONFIG[provider.to_sym][:default_site],
      authorize_url: OAUTH_CONFIG[provider.to_sym][:authorize_url],
      token_url: OAUTH_CONFIG[provider.to_sym][:token_url]
    )

    client
  end
end
