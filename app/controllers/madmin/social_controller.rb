# frozen_string_literal: true

# rbs_inline: enabled

module Madmin
  class SocialController < Madmin::ApplicationController
    # X.com OAuth2 인증 시작
    def xcom_authorize #: () -> void
      oauth_config = Preference.get_value("xcom_oauth")

      client = OAuth2::Client.new(
        oauth_config["client_id"],
        oauth_config["client_secret"],
        site: oauth_config["site"] || "https://api.x.com",
        authorize_url: "https://x.com/i/oauth2/authorize",
        token_url: "https://api.x.com/2/oauth2/token"
      )

      redirect_uri = madmin_social_xcom_callback_url

      # PKCE 사용 (X.com OAuth2.0 요구사항)
      code_verifier = SecureRandom.urlsafe_base64(32)
      code_challenge = Base64.urlsafe_encode64(
        Digest::SHA256.digest(code_verifier),
        padding: false
      )

      session[:xcom_code_verifier] = code_verifier

      authorize_url = client.auth_code.authorize_url(
        redirect_uri: redirect_uri,
        scope: "tweet.write offline.access",
        code_challenge: code_challenge,
        code_challenge_method: "S256",
        state: SecureRandom.hex(16)
      )

      session[:xcom_oauth_state] = authorize_url.match(/state=([^&]+)/)[1]

      redirect_to authorize_url, allow_other_host: true
    end

    # X.com OAuth2 콜백 처리
    def xcom_callback #: () -> void
      # State 검증
      if params[:state] != session[:xcom_oauth_state]
        redirect_to madmin_social_index_path, alert: "OAuth state 불일치 에러"
        nil
      end

      oauth_config = Preference.get_value("xcom_oauth")

      client = OAuth2::Client.new(
        oauth_config["client_id"],
        oauth_config["client_secret"],
        site: oauth_config["site"] || "https://api.x.com",
        authorize_url: "https://x.com/i/oauth2/authorize",
        token_url: "https://api.x.com/2/oauth2/token"
      )

      begin
          token = client.auth_code.get_token(
            params[:code],
            redirect_uri: madmin_social_xcom_callback_url,
            code_verifier: session[:xcom_code_verifier]
          )

          # Access token을 기존 xcom_oauth preference에 저장
          xcom_oauth_preference = Preference.find_by(name: "xcom_oauth")
          current_config = xcom_oauth_preference.value || {}

          xcom_oauth_preference.value = current_config.merge(
            access_token: token.token,
            refresh_token: token.refresh_token,
            expires_at: token.expires_at,
            token_created_at: Time.current.to_i
          )
        xcom_oauth_preference.save!

        session.delete(:xcom_code_verifier)
        session.delete(:xcom_oauth_state)

        redirect_to madmin_social_index_path, notice: "X.com OAuth 인증 성공! Access token이 저장되었습니다."
      rescue OAuth2::Error => e
        redirect_to madmin_social_index_path, alert: "OAuth 에러: #{e.message}"
      end
    end

    # Social 메뉴 메인 페이지
    def index #: () -> void
      @xcom_oauth = Preference.find_by(name: "xcom_oauth")
    end
  end
end
