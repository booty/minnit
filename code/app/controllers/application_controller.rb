class ApplicationController < ActionController::Base
  helper_method :current_member

  private

  def current_member
    @current_member ||= Member.find_by(id: session[:member_id]) if session[:member_id]
  end

  def require_login
    redirect_to login_path, notice: "Please log in." unless current_member
  end
end
