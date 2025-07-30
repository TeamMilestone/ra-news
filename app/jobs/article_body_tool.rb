# frozen_string_literal: true

# rbs_inline: enabled

class ArticleBodyTool < RubyLLM::Tool
  include ToolHelper

  description "id을 통해 가져온 Article에서 body 콘텐츠를 추출합니다."

  param :id, desc: "Article ID to fetch the body content from the database"

  #: (String url) -> String?
  def execute(id:)
    logger.info "Fetching Article body for ID: #{id}"
    Article.find_by(id: id)&.body
  end
end
