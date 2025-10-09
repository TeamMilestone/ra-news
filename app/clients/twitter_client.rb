# frozen_string_literal: true

# rbs_inline: enabled

class TwitterClient
  attr_reader :client

  def initialize
    token = OauthClientService.call("xcom")
    @client = Faraday.new(url: "https://api.x.com/2/") do |faraday|
      faraday.headers["Authorization"] = "Bearer #{token.token}"
      faraday.response :logger, nil, { bodies: true, log_level: :info }
      faraday.request :json
      faraday.response :json
    end
  end

  def post(text)
    response = client.post("tweets", { text: text }.to_json)
    response
  end
end
