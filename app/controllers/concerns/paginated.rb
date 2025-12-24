module Paginated
  extend ActiveSupport::Concern
  include SortPersistence

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
  def apply_sorting_and_pagination(collection, table_id: nil, default_sort_params: nil, items_per_page: 20, turbo_frame: "table_frame")

    # Apply saved sort preferences from cookies if table_id provided
    apply_saved_sort(table_id) if table_id.present?

    # Remove any existing ordering before applying our sort
    collection = collection.reorder('')

    # Set default sort parameters if none provided and defaults given
    if params[:sort].blank? && default_sort_params.present?
      params[:sort] = default_sort_params[:sort]
      params[:direction] = default_sort_params[:direction]
    end

    # Apply sorting based on parameters
    collection = apply_sorting(collection)

    # Add primary key as tiebreaker for deterministic pagination
    collection = add_primary_key_tiebreaker(collection)

    # Apply pagination
    paginate_collection(collection, items_per_page: items_per_page, turbo_frame: turbo_frame)
  end

  # Adds the primary key as a final sort column to ensure deterministic ordering.
  # This prevents pagination bugs where tied rows appear in random order across pages.
  def add_primary_key_tiebreaker(collection)
    # Only add tiebreaker if there's already some ordering
    return collection if collection.order_values.empty?

    # Get model information and add primary key as final tiebreaker
    model = collection.model
    primary_key = model.primary_key
    table_name = model.table_name

    collection.order("#{table_name}.#{primary_key} ASC")
  end
end
