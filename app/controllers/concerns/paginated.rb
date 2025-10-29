module Paginated
  extend ActiveSupport::Concern

  private

  # Helper method to paginate collections with preserved search parameters
  def paginate_collection(collection, items_per_page: 20, turbo_frame: "table_frame")
    Rails.logger.debug "Paginating with #{items_per_page} items per page"
    pagy(collection, items: items_per_page, limit: items_per_page, link_extra: "data-turbo-frame=\"#{turbo_frame}\"")
  end

  # Helper to preserve search parameters in pagination links
  def pagination_params
    request.query_parameters.except(:page)
  end

  # Combined method to apply sorting and pagination
  def apply_sorting_and_pagination(collection, default_sort: nil, default_sort_params: nil, items_per_page: 20, turbo_frame: "table_frame")

    # Remove any existing ordering before applying our sort
    collection = collection.reorder('')

    # Set default sort parameters if none provided and defaults given
    if params[:sort].blank? && default_sort_params.present?
      params[:sort] = default_sort_params[:sort]
      params[:direction] = default_sort_params[:direction]
    end

    # Apply sorting based on parameters
    collection = apply_sorting(collection)

    # Apply default sorting if no sort specified and default provided
    if params[:sort].blank? && default_sort.present?
      collection = collection.order(default_sort)
    end

    # Apply pagination
    paginate_collection(collection, items_per_page: items_per_page, turbo_frame: turbo_frame)
  end
end
