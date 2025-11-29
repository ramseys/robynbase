class AdminController < ApplicationController
  before_action :require_login

  def index
    @sort_cookies = []
    cookies.each do |key, value|
      if key.to_s.start_with?(SortPersistence::SORT_COOKIE_PREFIX)
        table_id = key.to_s.sub(SortPersistence::SORT_COOKIE_PREFIX, '')
        begin
          sort_data = JSON.parse(value)
          @sort_cookies << {
            table_id: table_id,
            column: sort_data['column'],
            direction: sort_data['direction']
          }
        rescue JSON::ParserError
          # Skip invalid cookies
        end
      end
    end

    @sort_cookies.sort_by! { |cookie| cookie[:table_id] }
  end

  def clear_sort_cookies
    clear_all_sort_cookies
    redirect_to admin_path, notice: "All table sort preferences have been cleared."
  end

  private

  def require_login
    unless current_user
      redirect_to login_path, alert: "You must be logged in to access this page."
    end
  end
end
