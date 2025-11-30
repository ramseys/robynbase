module SortPersistence
  extend ActiveSupport::Concern

  SORT_COOKIE_PREFIX = "askingtree_table_sort_".freeze

  def clear_all_sort_cookies
    cookies.each do |key, value|
      if key.to_s.start_with?(SORT_COOKIE_PREFIX)
        cookies.delete(key.to_sym)
      end
    end
  end

  private

  def apply_saved_sort(table_id)
    cookie_key = "#{SORT_COOKIE_PREFIX}#{table_id}".to_sym

    # Check if user explicitly provided sort params (clicked a column header)
    user_explicitly_sorted = params[:sort].present? && params[:direction].present?

    # If no sort params in URL, check cookies
    unless user_explicitly_sorted
      if cookies[cookie_key].present?
        begin
          saved = JSON.parse(cookies[cookie_key])
          params[:sort] = saved['column']
          params[:direction] = saved['direction']
        rescue JSON::ParserError
          # Invalid cookie, ignore
        end
      end
    end

    # ONLY save to cookie if user explicitly sorted (clicked a column header)
    if user_explicitly_sorted
      cookies[cookie_key] = {
        value: { column: params[:sort], direction: params[:direction] }.to_json,
        expires: 1.year.from_now
      }
    end

  end
end
