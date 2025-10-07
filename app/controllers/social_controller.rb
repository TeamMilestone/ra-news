# frozen_string_literal: true

# rbs_inline: enabled

class SocialController < ApplicationController
  # provider OAuth2 인증 시작
  def provider_authorize #: () -> void
    oauth_config = Preference.get_value("#{provider}_oauth")

    client = OAuth2::Client.new(
      oauth_config["client_id"],
      oauth_config["client_secret"],
      site: oauth_config["site"] || "https://api.x.com",
      authorize_url: authorize_url,
      token_url: token_url
    )

    redirect_uri = social_provider_callback_url(provider: provider)

    # PKCE 사용 (X.com OAuth2.0 요구사항)
    code_verifier = SecureRandom.urlsafe_base64(32)
    code_challenge = Base64.urlsafe_encode64(
      Digest::SHA256.digest(code_verifier),
      padding: false
    )

    session["#{provider}_code_verifier"] = code_verifier

    authorize_url = client.auth_code.authorize_url(
      redirect_uri: redirect_uri,
      scope: "tweet.write offline.access",
      code_challenge: code_challenge,
      code_challenge_method: "S256",
      state: SecureRandom.hex(16)
    )

    session["#{provider}_state"] = authorize_url.match(/state=([^&]+)/)[1]

    redirect_to authorize_url, allow_other_host: true
  end

  # provider OAuth2 콜백 처리
  def provider_callback #: () -> void
    # State 검증
    if params[:state] != session["#{provider}_state".to_sym]
      redirect_to madmin_social_index_path, alert: "OAuth state 불일치 에러"
      nil
    end

    oauth_config = Preference.get_value("#{provider}_oauth")

    client = OAuth2::Client.new(
      oauth_config["client_id"],
      oauth_config["client_secret"],
      site: oauth_config["site"] || "https://api.x.com",
      authorize_url: authorize_url,
      token_url: token_url
    )

    begin
        token = client.auth_code.get_token(
          params[:code],
          redirect_uri: social_provider_callback_url(provider: provider),
          code_verifier: session["#{provider}_code_verifier"]
        )

        # Access token을 기존 oauth preference에 저장
        oauth_preference = Preference.find_by(name: "#{provider}_oauth")
        current_config = oauth_preference.value || {}

        oauth_preference.value = current_config.merge(
          access_token: token.token,
          refresh_token: token.refresh_token,
          expires_at: token.expires_at,
          token_created_at: Time.current.to_i
        )
      oauth_preference.save!

      session.delete("#{provider}_code_verifier")
      session.delete("#{provider}_oauth_state")

      redirect_to madmin_social_index_path, notice: "OAuth 인증 성공! Access token이 저장되었습니다."
    rescue OAuth2::Error => e
      redirect_to madmin_social_index_path, alert: "OAuth 에러: #{e.message}"
    end
  end

  private

  def provider
    params[:provider].presence || "xcom"
  end

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
