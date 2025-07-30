module ToolHelper
  extend ActiveSupport::Concern

  protected

  def logger
    Rails.logger
  end
end
