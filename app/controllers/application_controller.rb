class ApplicationController < ActionController::Base
  include Pagy::Backend

  protect_from_forgery

  helper_method :current_user
  
  def current_user
    if session[:user_id]
      @current_user ||= User.find(session[:user_id])
    else
      @current_user = nil
    end
  end

  # Returns IDs of any nested-attribute hashes that include an existing :id.
  # New rows submitted without an id are omitted; those are handled by accepts_nested_attributes_for.
  def extract_submitted_ids(attrs_hash)
    return [] if attrs_hash.blank?
    attrs_hash.values.map { |a| a["id"] }.compact.map(&:to_i)
  end

end
