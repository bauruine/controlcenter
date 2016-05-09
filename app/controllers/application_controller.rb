class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :require_login

  rescue_from ActiveRecord::RecordNotFound, with: :go_to_index

  def go_to_index
    redirect_to({action: "index"}, notice: 'Entry with the ID ' + params[:id] + ' not found')
  end

  private
  def not_authenticated
    redirect_to login_path, alert: "Please login first"
  end
end
