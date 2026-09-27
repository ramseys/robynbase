class SongsController < ApplicationController
  include Paginated
  include InfiniteScrollConcern
  include SearchNavigable

  RESOURCE_TYPE = :song
  TABLE_ID = 'song-main'.freeze
  DEFAULT_SORT_PARAMS = { sort: 'name', direction: 'asc' }.freeze

  # Params that define a song search, for replaying it from a show page
  SEARCH_BACK_INDEX_PARAMS = [:search_type, :search_value].freeze
  
  authorize_resource :only => [:new, :edit, :update, :create, :destroy]

  def index
    if params[:search_type].present?
      songs_collection = build_song_search_collection(params)
      @pagy, @songs = apply_sorting_and_pagination(songs_collection, table_id: TABLE_ID, default_sort_params: DEFAULT_SORT_PARAMS)
      @search_back = build_search_back_url(songs_index_path, SEARCH_BACK_INDEX_PARAMS)
    else
      @songs = nil
      @pagy = nil
    end

    @show_lyrics = (params[:search_type] == "lyrics")

  end

  def quick_query
    songs_collection = Song.quick_query(params[:query_id], params[:query_attribute])
    @pagy, @songs = apply_sorting_and_pagination(songs_collection, table_id: TABLE_ID, default_sort_params: DEFAULT_SORT_PARAMS)
    @search_back = build_search_back_url(songs_quick_query_path, SEARCH_BACK_QUICK_QUERY_PARAMS)
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

    @search_nav = build_search_nav(@song.id,
                                   collection_builders: song_collection_builders,
                                   default_sort_params: DEFAULT_SORT_PARAMS)
  end

  
  private

    # Builds the song search collection from either the live params or a search_back
    # hash replayed on a show page, so both go through one code path.
    def build_song_search_collection(source_params)
      Song.search_by(search_kind(source_params), source_params[:search_value])
    end

    # Replay branches for search-result navigation, keyed by the action that produced
    # the result set.
    def song_collection_builders
      {
        "index" => ->(source) { build_song_search_collection(source) },
        "quick_query" => ->(source) { replayable_quick_query(Song, source) }
      }
    end

    def infinite_scroll_config
      {
        model: Song,
        records_name: :songs,
        partial: 'song_rows',
        default_sort_params: DEFAULT_SORT_PARAMS,
        index_path: songs_index_path,
        quick_query_path: songs_quick_query_path,
        additional_locals: {
          show_lyrics: (params[:search_type] == "lyrics"),
          show_lyrics_snippet: params[:search_type] == "lyrics" ? params[:search_value] : nil }
      }
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