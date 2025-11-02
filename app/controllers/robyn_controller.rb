class RobynController < ApplicationController

  include Paginated

  def index
    # Main omnisearch page - shows the search box and determines which tables to show
    # The actual table content is loaded via lazy Turbo frames (see omnisearch_* methods below)
    search = params[:search_value]
    logger.info "search: #{search}"

    if search.present?
      # Do lightweight existence checks to determine which frames to render
      @has_gigs = Gig.search_by([:venue], search).exists?
      @has_songs = Song.search_by([:title], search).exists?
      @has_compositions = Composition.search_by([:title], search).exists?
      @has_venues = Venue.search_by([:name], search).exists?
    end
  end

  # Lazy-loaded Turbo frame endpoints for omnisearch results
  # These follow the same pattern as for_resource methods in other controllers

  def omnisearch_gigs
    search = params[:search_value]
    return head :bad_request unless search.present?

    gigs_collection = Gig.search_by([:venue], search)
    @pagy, @gigs = apply_sorting_and_pagination(
      gigs_collection,
      default_sort: "GigDate asc",
      default_sort_params: { sort: 'date', direction: 'desc' },
      items_per_page: 10,
      turbo_frame: "gigs_frame"
    )
    
    @table_id = "gig-omni"

    render partial: 'shared/turbo_gig_table', locals: { frame_name: "gigs_frame" }
  end

  def omnisearch_songs
    search = params[:search_value]
    return head :bad_request unless search.present?

    songs_collection = Song.search_by([:title], search)
    @pagy, @songs = apply_sorting_and_pagination(
      songs_collection,
      default_sort: "SONG.Song asc",
      default_sort_params: { sort: 'name', direction: 'asc' },
      items_per_page: 10,
      turbo_frame: "songs_frame"
    )
      
    @table_id = "song-omni"

    render partial: 'shared/turbo_songs_table', locals: { frame_name: "songs_frame" }
  end

  def omnisearch_compositions
    search = params[:search_value]
    return head :bad_request unless search.present?

    compositions_collection = Composition.search_by([:title], search)
    @pagy, @compositions = apply_sorting_and_pagination(
      compositions_collection,
      default_sort: "COMP.Title asc",
      default_sort_params: { sort: 'title', direction: 'asc' },
      items_per_page: 10,
      turbo_frame: "compositions_frame"
    )
    
    @table_id = "album-omni"

    render partial: 'shared/turbo_releases_table', locals: { frame_name: "compositions_frame" }
  end

  def omnisearch_venues
    search = params[:search_value]
    return head :bad_request unless search.present?

    venues_collection = Venue.search_by([:name], search)
    @pagy, @venues = apply_sorting_and_pagination(
      venues_collection,
      default_sort: "VENUE.Name asc",
      default_sort_params: { sort: 'venue', direction: 'asc' },
      items_per_page: 10,
      turbo_frame: "venues_frame"
    )
    
    @table_id = "venue-omni"

    render partial: 'shared/turbo_venues_table', locals: { frame_name: "venues_frame" }
  end

  def search

    search = params[:search_value] 

    logger.info "song search: #{search}"

    if not search.nil? 
      @songs = Song.search_by [:title], search
    end

    logger.info @songs

    render json: @songs

  end

  def search_gigs

    search = params[:search_value] 

    logger.info "gig search: #{search}"

    if not search.nil? 
      @gigs = Gig.search_by [:venue], search
    end

    logger.info "found gigs: #{@gigs}"

    render json: @gigs

  end

  def search_venues

    search = params[:search_value] 

    logger.info "venue search: #{search}"

    if not search.nil? 
      @venues = Venue.search_by [:name], search
    end

    logger.info "found venues: #{@venues}"

    render json: @venues

  end 

  def search_compositions

    search = params[:search_value]

    logger.info "composition search: #{search}"

    if not search.nil?
      @compositions = Composition.search_by [:title], search
    end

    logger.info "found compositions: #{@compositions}"

    render json: @compositions

  end

  private

  def apply_sorting(collection)
    # Determine which resource type we're sorting based on the action
    resource_type = case action_name
    when 'omnisearch_gigs'
      :gig
    when 'omnisearch_songs'
      :song
    when 'omnisearch_compositions'
      :composition
    when 'omnisearch_venues'
      :venue
    else
      return collection
    end

    ResourceSorter.sort(collection,
                       resource_type: resource_type,
                       sort_column: params[:sort],
                       direction: params[:direction])
  end

end
