class SongsController < ApplicationController
  include Paginated
  include InfiniteScrollConcern

  TABLE_ID = 'song-main'.freeze
  DEFAULT_SORT_PARAMS = { sort: 'name', direction: 'asc' }.freeze
  
  authorize_resource :only => [:new, :edit, :update, :create, :destroy]

  def index
    if params[:search_type].present?
      songs_collection = Song.search_by(params[:search_type] ? params[:search_type].to_sym : nil, params[:search_value])
      @pagy, @songs = apply_sorting_and_pagination(songs_collection, table_id: TABLE_ID, default_sort_params: DEFAULT_SORT_PARAMS)
    else 
      params[:search_type] = "title"
      @songs = nil
      @pagy = nil
    end

    @show_lyrics = (params[:search_type] == "lyrics")

  end

  def quick_query
    songs_collection = Song.quick_query(params[:query_id], params[:query_attribute])
    @pagy, @songs = apply_sorting_and_pagination(songs_collection, table_id: TABLE_ID, default_sort_params: DEFAULT_SORT_PARAMS)
    render "index"
  end

  # Prepare song create page
  def new
    @song = Song.new
    save_referrer
  end

  # Prepare song update page
  def edit 
    @song = Song.find(params[:id])
    save_referrer
  end
    
  # Update existing song
  def update 
    
    song = Song.find(params[:id])
    
    filtered_params = prepare_params
    
    # extract the article prefix (if any) from song name
    (prefix, song_name) = Song.parse_song_name(filtered_params[:full_name])
    
    # store prefix and the rest of the song name separately
    filtered_params[:Song] = song_name
    filtered_params[:Prefix] = prefix
    filtered_params.delete(:full_name)
    
    song.update!(filtered_params)
    
    return_to_previous_page(song)
    
  end

  # Create a new song
  def create

    filtered_params = prepare_params
        
    # extract the article prefix (if any) from song name
    (prefix, song_name) = Song.parse_song_name(filtered_params[:full_name])

    # store prefix and the rest of the song name separately
    filtered_params[:Song] = song_name
    filtered_params[:Prefix] = prefix
    filtered_params.delete(:full_name)

    @song = Song.new(filtered_params)

    if @song.save
      return_to_previous_page(@song)
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new"
    end

  end

  # Remove song
  def destroy
    song = Song.find(params[:id])
    song.destroy

    redirect_back fallback_location: songs_url

  end
  
  def show
    # Eager load associations to avoid N+1 queries
    @song = Song.includes(:gigs, :compositions).find(params[:id])

    @gigs_present = @song.gigs.present?
    @albums_present = @song.compositions.present?
  end

  
  private
  
    def infinite_scroll_config
      {
        model: Song,
        records_name: :songs,
        partial: 'song_rows',
        default_sort_params: DEFAULT_SORT_PARAMS,
        additional_locals: {
          show_lyrics: (params[:search_type] == "lyrics"),
          show_lyrics_snippet: params[:search_type] == "lyrics" ? params[:search_value] : nil }
      }
    end
    
    def apply_sorting(collection)
      ResourceSorter.sort(
        collection,
        resource_type: :song,
        sort_column: params[:sort],
        direction: params[:direction]
      )
    end
    
    def return_to_previous_page(song)
      previous_page = session.delete(:return_to_song)
      if previous_page.present?
        redirect_to previous_page
      else
        redirect_to song
      end
    end

    def save_referrer
      session[:return_to_song] = request.referer
    end
    
    # Massage incoming params for saving
    def prepare_params

      filtered_params = song_params

      # if no value specified, store a null
      filtered_params[:OrigBand] = nil   if filtered_params[:OrigBand].strip.empty?
      filtered_params[:Author] = nil     if filtered_params[:Author].strip.empty?
      filtered_params[:Lyrics] = nil     if filtered_params[:Lyrics].strip.empty?
      filtered_params[:lyrics_ref] = nil if filtered_params[:lyrics_ref].strip.empty?
      filtered_params[:Comments] = nil   if filtered_params[:Comments].strip.empty?

      filtered_params

    end

    def song_params
      params.require(:song).permit(:full_name, :Author, :OrigBand, :Improvised, :lyrics_ref, :show_lyrics, :Lyrics, :Comments).tap do |params|
        params.require(:full_name)
      end
    end

end