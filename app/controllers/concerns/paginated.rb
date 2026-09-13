module Paginated
  extend ActiveSupport::Concern
  include SortPersistence

  private

  # Helper method to paginate collections with preserved search parameters
  def paginate_collection(collection, items_per_page: 40, turbo_frame: "table_frame")
    Rails.logger.debug "Paginating with #{items_per_page} items per page"
    pagy(collection, items: items_per_page, limit: items_per_page, link_extra: "data-turbo-frame=\"#{turbo_frame}\"")
  end

  # Helper to preserve search parameters in pagination links
  def pagination_params
    request.query_parameters.except(:page)
  end

  # Combined method to apply sorting and pagination
  def apply_sorting_and_pagination(collection, table_id: nil, default_sort_params: nil, items_per_page: 40, turbo_frame: "table_frame")

    # Apply saved sort preferences from cookies if table_id provided
    apply_saved_sort(table_id) if table_id.present?

    # Resolve the sort, then write it back into params on purpose: build_search_back_url
    # reads it from there afterwards to publish the sort the listing actually used.
    resolved = resolve_sort_params(params, default_sort_params)
    params[:sort] = resolved[:sort]
    params[:direction] = resolved[:direction]

    collection = apply_ordering(collection, **resolved)

    # Apply pagination
    paginate_collection(collection, items_per_page: items_per_page, turbo_frame: turbo_frame)
  end

  # The resource being sorted. Controllers that serve a single resource declare it
  # as a constant; RobynController's omnisearch overrides this to vary it per action.
  def resource_type
    self.class::RESOURCE_TYPE
  end

  # The sort a listing - or any replay of it - runs with.
  #
  # The pair moves together: the defaults are taken whole, or not at all. A sort column
  # with no direction keeps its blank direction, which ResourceSorter reads as
  # ascending, rather than borrowing the default's - that direction belongs to a
  # different column, and pairing the two would silently reverse the order.
  #
  # Shared with SearchNavigable's replay, so a recovered result set orders identically
  # to the listing that produced it even when the URL only names half the pair.
  def resolve_sort_params(source_params, default_sort_params)
    if source_params[:sort].blank? && default_sort_params.present?
      { sort: default_sort_params[:sort], direction: default_sort_params[:direction] }
    else
      { sort: source_params[:sort], direction: source_params[:direction] }
    end
  end

  # The one ordering pipeline: clear any inherited order, apply the resource's sort,
  # then the primary key tiebreaker so tied rows never shuffle between pages.
  #
  # Both the paginated listings and SearchNavigable's replay come through here, on a
  # pair already resolved by resolve_sort_params above, which is what makes a replayed
  # position line up with the page the user was looking at. Resolution stays a separate
  # step because the listing also has to *publish* the pair it resolved, into params for
  # build_search_back_url; the replay only reads.
  def apply_ordering(collection, sort:, direction:)
    sorted = ResourceSorter.sort(
      collection.reorder(''),
      resource_type: resource_type,
      sort_column: sort,
      direction: direction
    )

    add_primary_key_tiebreaker(sorted)
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
