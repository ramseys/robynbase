class VenuesController < ApplicationController
  include Paginated
  include InfiniteScrollConcern
  include ImageUtils
  include ImageOrderingConcern
  include SearchNavigable

  RESOURCE_TYPE = :venue
  TABLE_ID = 'venue-main'.freeze
  DEFAULT_SORT_PARAMS = { sort: 'venue', direction: 'asc' }.freeze

  # Params that define a venue search, for replaying it from a show page
  SEARCH_BACK_INDEX_PARAMS = [:search_type, :search_value].freeze

  authorize_resource :only => [:new, :edit, :update, :create, :destroy]

  def index
    if params[:search_type].present?
      venues_collection = build_venue_search_collection(params)
      @pagy, @venues = apply_sorting_and_pagination(venues_collection, table_id: TABLE_ID, default_sort_params: DEFAULT_SORT_PARAMS)
      @search_back = build_search_back_url(venues_index_path, SEARCH_BACK_INDEX_PARAMS)
    else
      @venues = nil
      @pagy = nil
    end

  end
  
  def show
    # Eager load associations to avoid N+1 queries
    @venue = Venue.includes(:gigs).find(params[:id])

    @search_nav = build_search_nav(@venue.id,
                                   collection_builders: venue_collection_builders,
                                   default_sort_params: DEFAULT_SORT_PARAMS)
  end

  # Prepare venue create page
  def new
    @venue = Venue.new
    save_referrer
  end

  # Prepare venue update page
  def edit 
    @venue = Venue.find(params[:id])
    save_referrer
  end

  # Update existing venue
  def update

    venue = Venue.find(params[:id])

    filtered_params, images = prepare_params

    purge_marked_images(params)
    optimize_images({ images: images }) if images.present?

    if venue.update(filtered_params)
      venue.images.attach(images) if images.present?
      assign_positions_to_new_images(venue)
      update_image_positions
    end

    return_to_previous_page(venue)

  end

  # Create a new venue
  def create

    filtered_params, images = prepare_params

    optimize_images({ images: images }) if images.present?

    @venue = Venue.new(filtered_params)

    if @venue.save
      @venue.images.attach(images) if images.present?
      assign_positions_to_new_images(@venue)
      return_to_previous_page(@venue)
    else
      render "new"
    end

  end

  # Remove venue
  def destroy
    venue = Venue.find(params[:id])
    venue.destroy

    redirect_back fallback_location: venues_url

  end

  def quick_query
    venues_collection = Venue.quick_query(params[:query_id], params[:query_attribute])
    @pagy, @venues = apply_sorting_and_pagination(venues_collection, table_id: TABLE_ID, default_sort_params: DEFAULT_SORT_PARAMS)
    @search_back = build_search_back_url(venues_quick_query_path, SEARCH_BACK_QUICK_QUERY_PARAMS)
    render "index"
  end


  private

    # Builds the venue search collection from either the live params or a search_back
    # hash replayed on a show page, so both go through one code path.
    def build_venue_search_collection(source_params)
      Venue.search_by(search_kind(source_params), source_params[:search_value])
    end

    # Replay branches for search-result navigation, keyed by the action that produced
    # the result set.
    def venue_collection_builders
      {
        "index" => ->(source) { build_venue_search_collection(source) },
        "quick_query" => ->(source) { replayable_quick_query(Venue, source) }
      }
    end

    def infinite_scroll_config
      {
        model: Venue,
        records_name: :venues,
        partial: 'venue_rows',
        default_sort_params: DEFAULT_SORT_PARAMS,
        index_path: venues_index_path,
        quick_query_path: venues_quick_query_path
      }
    end

    def save_referrer
      session[:return_to_venue] = request.referer
    end

    def return_to_previous_page(song)
      previous_page = session.delete(:return_to_venue)
      if previous_page.present?
        redirect_to previous_page
      else
        redirect_to venue
      end
    end

    # Massage incoming params for saving; returns [filtered_params, images]
    def prepare_params

      filtered_params = venue_params

      images = filtered_params.delete(:images)

      filtered_params[:SubCity] = nil if filtered_params[:SubCity].strip.empty?
      filtered_params[:State] = nil   if filtered_params[:State].strip.empty?

      [filtered_params, images]

    end

    def venue_params
      params.require(:venue).
        permit(:Name, :street_address1, :street_address2, :City, :SubCity, :State, :Country, :longitude, :latitude, :Notes, images: [], deleted_img_ids: []).tap do |params|
        params.require([:Name, :City, :Country])
      end
    end

end