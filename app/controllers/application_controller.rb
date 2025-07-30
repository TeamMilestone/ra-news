# frozen_string_literal: true

# rbs_inline: enabled

class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: { ie: false }

  before_action :redirect_old_domain

   before_action do
    Honeybadger.context({
      user_id: Current&.user&.id
    })
  end


  private

  def redirect_old_domain #: () -> void
    if request.host == "news.stadiasphere.xyz"
      redirect_to "https://ruby-news.kr#{request.fullpath}", status: 301, allow_other_host: true
    end
  end
end
