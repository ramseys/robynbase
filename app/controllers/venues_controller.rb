class VenuesController < ApplicationController

  authorize_resource :only => [:new, :edit, :update, :create, :destroy]
  
  def index
    if params[:search_type].present?
      @venues = Venue.search_by(params[:search_type].to_sym, params[:venue_search_value])
    else 
      params[:search_type] = "name"
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


  private
    
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