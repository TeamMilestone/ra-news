class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @articles = Article.kept.limit(9).order(created_at: :desc)
  end
end
