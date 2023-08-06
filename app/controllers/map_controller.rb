class MapController < ApplicationController
  def index
    @venues = Venue.get_venues_with_location
  end
end
