class ApplicationController < ActionController::Base
  include Pagy::Backend

  protect_from_forgery

  helper_method :current_user

  # Handle CanCan authorization failures
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to new_session_path, alert: "You must be logged in to access this page."
  end

  def current_user
    if session[:user_id]
      @current_user ||= User.find(session[:user_id])
    else
      @current_user = nil
    end
  end

end
