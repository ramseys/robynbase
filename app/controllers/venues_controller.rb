class VenuesController < ApplicationController
  include Paginated
  include InfiniteScrollConcern

  authorize_resource :only => [:new, :edit, :update, :create, :destroy]
  
  def index
    if params[:search_type].present?
      venues_collection = Venue.search_by(params[:search_type].to_sym, params[:search_value])
      @pagy, @venues = apply_sorting_and_pagination(venues_collection, default_sort: "VENUE.Name asc", default_sort_params: { sort: 'venue', direction: 'asc' })
    else 
      params[:search_type] = "name"
      @venues = nil
      @pagy = nil
    end

  end
  
  def show
    @venue = Venue.find(params[:id])
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
    
    filtered_params = prepare_params
        
    venue.update!(filtered_params)
    
    return_to_previous_page(venue)
    
  end

  # Create a new venue
  def create

    filtered_params = prepare_params
        
    @venue = Venue.new(filtered_params)

    if @venue.save
      return_to_previous_page(@venue)
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
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
    @pagy, @venues = apply_sorting_and_pagination(venues_collection, default_sort: "VENUE.Name asc", default_sort_params: { sort: 'venue', direction: 'asc' })
    render "index"
  end


  private

    def infinite_scroll_config
      {
        model: Venue,
        records_name: :venues,
        partial: 'venue_rows',
        default_sort: "VENUE.Name asc",
        default_sort_params: { sort: 'venue', direction: 'asc' }
      }
    end
  
    def apply_sorting(collection)
      return collection unless params[:sort].present?
      
      sort_column = params[:sort]
      direction = params[:direction] == 'desc' ? 'desc' : 'asc'
      
      case sort_column
      when 'venue'
        collection.order("VENUE.Name #{direction}")
      when 'city'
        collection.order("VENUE.City #{direction}")
      when 'subcity'
        collection.order("VENUE.SubCity #{direction}")
      when 'state'
        collection.order("VENUE.State #{direction}")
      when 'country'
        collection.order("VENUE.Country #{direction}")
      when 'performances'
        # Count of related gigs
        collection.left_joins(:gigs).group("VENUE.VENUEID").order("COUNT(GIG.GIGID) #{direction}")
      else
        collection.order("VENUE.Name asc") # default sort
      end
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

    # Massage incoming params for saving
    def prepare_params

      filtered_params = venue_params

      # if no value is specified for these fields, store a null
      filtered_params[:SubCity] = nil if filtered_params[:SubCity].strip.empty?
      filtered_params[:State] = nil   if filtered_params[:State].strip.empty?

      filtered_params

    end

    def venue_params
      params.require(:venue).
        permit(:Name, :street_address1, :street_address2, :City, :SubCity, :State, :Country, :longitude, :latitude, :Notes).tap do |params|
        params.require([:Name, :City, :Country])
      end
    end

end