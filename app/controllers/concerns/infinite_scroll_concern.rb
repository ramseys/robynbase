module InfiniteScrollConcern
  extend ActiveSupport::Concern

  def infinite_scroll
    Rails.logger.debug "Infinite scroll params: #{params.inspect}"
    
    collection = build_collection_from_params
    return if performed? # In case build_collection_from_params rendered a response

    config = infinite_scroll_config
    @pagy, records = apply_sorting_and_pagination(collection,
      default_sort_params: config[:default_sort_params]
    )
    Rails.logger.debug "Found #{records.length} records on page #{@pagy.page}"

    # Set instance variable for the records (e.g., @songs, @venues)
    instance_variable_set("@#{config[:records_name]}", records)

    # Build locals hash for the partial
    locals = { config[:records_name] => records }
    locals.merge!(config[:additional_locals]) if config[:additional_locals]
    
    render json: {
      html: render_to_string(partial: config[:partial], 
      locals: locals, 
      formats: [:html]),
      has_next_page: @pagy.next.present?,
      current_page: @pagy.page,
      current_sort: params[:sort],
      current_direction: params[:direction],
      search_type: params[:search_type],
      search_value: params[:search_value],
      query_type: params[:query_type],
      query_id: params[:query_id],
      query_attribute: params[:query_attribute]
    }
  end

  private

  def build_collection_from_params
    config = infinite_scroll_config
    
    case params[:query_type]
    when 'quick_query'
      if params[:query_id].present?
        collection = config[:model].quick_query(params[:query_id], params[:query_attribute])
        Rails.logger.debug "Quick query #{params[:query_id]} executed"
        collection
      else
        Rails.logger.debug "No query_id found for quick_query, returning empty"
        render json: { html: '', has_next_page: false }
        nil
      end
    else
      if params[:search_type].present?
        # Get additional search arguments from the config
        search_args = [params[:search_type].to_sym, params[:search_value]]
        
        if config[:additional_search_params]
          additional_params = config[:additional_search_params].call(params)
          search_args.concat(additional_params)
        end
        
        collection = config[:model].search_by(*search_args)
        Rails.logger.debug "Search query executed with args: #{search_args.inspect}"
        collection
      else
        Rails.logger.debug "No search_type found, returning empty"
        render json: { html: '', has_next_page: false }
        nil
      end
    end
  end

  # Subclasses must implement this method to configure infinite scroll behavior
  #
  # Returns a hash with the following required keys:
  #   :model - The ActiveRecord model class (e.g., Song, Venue)
  #   :records_name - Symbol for the collection variable name (e.g., :songs, :venues)
  #   :partial - String path to the table rows partial (e.g., 'song_rows', 'venue_rows')
  #   :default_sort_params - Hash with :sort and :direction for UI state (e.g., { sort: 'name', direction: 'asc' })
  #
  # Optional keys:
  #   :additional_locals - Hash of extra local variables to pass to the partial
  #   :additional_search_params - Proc that takes params and returns array of additional arguments for search_by
  #
  # Example:
  #   def infinite_scroll_config
  #     {
  #       model: Song,
  #       records_name: :songs,
  #       partial: 'song_rows',
  #       default_sort_params: { sort: 'name', direction: 'asc' },
  #       additional_locals: { show_lyrics: (params[:search_type] == "lyrics") },
  #       additional_search_params: ->(params) { [build_date_criteria(params), params[:gig_type]] }
  #     }
  #   end
  def infinite_scroll_config
    raise NotImplementedError, "Define infinite_scroll_config in #{self.class.name}"
  end
end