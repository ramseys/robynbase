class CompositionsController < ApplicationController

  include ImageUtils
  include ImageOrderingConcern
  include Paginated
  include InfiniteScrollConcern
  include SearchNavigable

  RESOURCE_TYPE = :composition
  TABLE_ID = 'album-main'.freeze
  DEFAULT_SORT_PARAMS = { sort: 'year', direction: 'asc' }.freeze

  # Params that define a release search, for replaying it from a show page
  SEARCH_BACK_INDEX_PARAMS = [:search_type, :search_value, { release_type: [] }].freeze

  authorize_resource :only => [:new, :edit, :update, :create, :destroy]

  def index
    # if the user entered any search terms at all
    if params[:search_type].present? || params[:release_type].present?

      compositions_collection = build_composition_search_collection(params)
      @pagy, @compositions = apply_sorting_and_pagination(
        compositions_collection,
        table_id: TABLE_ID,
        default_sort_params: DEFAULT_SORT_PARAMS
      )

      @search_back = build_search_back_url(compositions_index_path, SEARCH_BACK_INDEX_PARAMS)

    else
      @compositions = nil
      @pagy = nil
    end

  end

  def show
    # get the requested album - eager load tracks and songs to avoid N+1 queries
    @comp = Composition.includes(tracks: :song, images_attachments: :blob).find(params[:id])

    # get album art (if any)
    @associated_images = get_associated_images(@comp.Title)

    @search_nav = build_search_nav(@comp.id,
                                   collection_builders: composition_collection_builders,
                                   default_sort_params: DEFAULT_SORT_PARAMS)
  end

  def get_associated_images(title)
    Dir["public/images/album-art/*"].entries.select { |name| name.index(/#{title}/i) }.sort.map{ |name| name.sub("public/", "").sub("[", "%5B").sub("]", "%5D")}
  end


  # prepare composition create page
  def new

    @comp = Composition.new

    # get a list of all songs (for the songs selection dropdown)
    @song_list = Song.order(:Song).collect{|s| [s.full_name, s.SONGID]}

    save_referrer

  end


  # prepare composition update page
  def edit

    @comp = Composition.find(params[:id])

    # get a list of all songs (for the songs selection dropddown)
    @song_list = Song.order(:Song).collect{|s| [s.full_name, s.SONGID]}

    save_referrer

  end

  # create a new composition
  def create

    filtered_params, _images = prepare_params()

    optimize_images(filtered_params)

    @comp = Composition.new(filtered_params)

    ActiveRecord::Base.transaction do
      if @comp.save

        # assign positions to newly uploaded images
        assign_positions_to_new_images(@comp)

        redirect_to(@comp)

      else
        # This line overrides the default rendering behavior, which
        # would have been to render the "create" view.
        render "new"
      end
    end

  end

  # update existing composition
  def update

    comp = Composition.find(params[:id])

    filtered_params, images = prepare_params(true)

    # purge images marked for removal
    purge_marked_images(params)

    # optimize new images
    optimize_images({ images: images }) if images.present?

    ActiveRecord::Base.transaction do
      if comp.update(filtered_params)

        # if there are any image updates, attach them to the composition
        # note: we can't rely on the model to do this for us, because rails
        # will always replace existing images with the new ones; we need to
        # append these to existing images
        comp.images.attach(images) if images.present?

        # assign positions to newly uploaded images
        assign_positions_to_new_images(comp)

        # update positions for reordered images
        update_image_positions

        redirect_to(comp)
      else
        render "edit"
      end
    end

  end

  def destroy
    gig = Composition.find(params[:id])
    gig.destroy

    redirect_back fallback_location: gigs_url

  end

  def return_to_previous_page(composition)
    previous_page = session.delete(:return_to_composition)
    if previous_page.present?
      redirect_to previous_page
    else
      redirect_to composition
    end
  end

  def save_referrer
    session[:return_to_composition] = request.referer
  end

  # Prepare the track list for save
  #
  # 1. Order songs by giving each the appropriate "Seq" index
  # 2. Save denormalized song in Trak table
  def prepare_tracks(tracks, starting_index, bonus)

    last_index = starting_index

    # Preload all songs to avoid N+1 queries
    song_ids = tracks.values.map { |t| t["SONGID"].to_i }.compact.uniq
    songs_by_id = Song.where(SONGID: song_ids).index_by(&:SONGID)

    # loop through every song in the track list in order, normalizing their sequence numbers
    tracks.values.select{|val| !val["_destroy"].present? && val["bonus"] == bonus.to_s}.sort_by{ |a| a["Seq"].to_i }.each_with_index do |b, i|

      last_index = starting_index + i

      # sequence in 10s
      b["Seq"] = (last_index * 10).to_s

      # if there's no override song name, add in the real song name
      if b["SONGID"].present? && b["Song"].empty?
        song = songs_by_id[b["SONGID"].to_i]
        b["Song"] = song.full_name if song
      end

      b[:VersionNotes] = nil if b[:VersionNotes].present? && b[:VersionNotes].strip.empty?

    end

    starting_index

  end

  def prepare_params(extract_images = false)

    new_params = comp_params()

    # loop through all the non-encore songs
    tracks = new_params["tracks_attributes"]

    # renumber the tracks chronologically (official and additonal)
    if tracks.present?
      start_bonus_index = prepare_tracks(tracks, 1, false)
      prepare_tracks(tracks, start_bonus_index, true)
    end

    # empty comments are stored as nil
    new_params[:Comments] = nil  if new_params[:Comments].strip.empty?

    # if requested, extract images into a separate variable
    if extract_images
      images = new_params["images"]
      new_params.delete("images") if images.present?
    end

    [new_params, images]

  end

  def comp_params

    # permit attributes we're saving
    params
      .require(:composition)
      .permit(:Title, :Artist, :Year, :Label, :discogs_url, :Comments, :Type, :images,
              images: [],
              tracks_attributes: [ :id, :_destroy, :Seq, :SONGID, :Song, :VersionNotes, :bonus ]).tap do |params|

          # every gig needs at least a title and artist
          params.require([:Title, :Artist])

          # every item in a track list requires a sequence number (skip destroy-only entries)
          if params["tracks_attributes"].present?
            params["tracks_attributes"].each do |key, params|
              next if params["_destroy"].present?
              params.require([:Seq])
            end
          end

      end


  end

  # Renders embedded table of compositions related to another resource (e.g., all compositions for a song).
  # Provides paginated, sortable lists via Turbo Frames for display within other pages without navigation.
  def for_resource
    resource_type = params[:resource_type]
    resource_id = params[:resource_id]
    @table_id = "releases-#{resource_type}"

    case resource_type
    when 'song'
      @resource = Song.find(resource_id)
      releases = @resource.compositions.distinct
      # Use a subquery to keep only the record with smallest COMPID for each title
      min_compids = releases.select("Title, MIN(COMP.COMPID) as min_compid").group("Title")
      compositions_collection = releases.joins("INNER JOIN (#{min_compids.to_sql}) earliest ON COMP.Title = earliest.Title AND COMP.COMPID = earliest.min_compid")
    else
      head :not_found
      return
    end

    @pagy, @compositions = apply_sorting_and_pagination(
      compositions_collection,
      table_id: @table_id,
      default_sort_params: DEFAULT_SORT_PARAMS,
      items_per_page: 10,
      turbo_frame: "releases_frame"
    )

    render partial: 'shared/turbo_releases_table'
  end

  def quick_query
    if params[:query_id].to_sym == :major_cd_releases
      @initial_sort = { :column_index => 4, :direction => 'asc' }
    end

    compositions_collection = Composition.quick_query(params[:query_id], params[:query_attribute])
    @pagy, @compositions = apply_sorting_and_pagination(compositions_collection, table_id: TABLE_ID, default_sort_params: DEFAULT_SORT_PARAMS)
    @search_back = build_search_back_url(compositions_quick_query_path, SEARCH_BACK_QUICK_QUERY_PARAMS)
    render "index"

  end

  private

  # Builds the release search collection from either the live params or a search_back
  # hash replayed on a show page, so both go through one code path. The search_type
  # normalization has to live here too, so replay treats a release-type-only search
  # identically to the way index does.
  def build_composition_search_collection(source_params)
    # ensure a concrete search_type is echoed back to the view/infinite-scroll JS,
    # even when entering search mode via release_type alone (e.g. a bookmarked filter link)
    source_params[:search_type] = "all" if source_params[:search_type].blank?

    # grab the albums, based on the given search criteria ("all" searches across all fields)
    Composition.search_by(search_kind(source_params), source_params[:search_value], build_release_types_from_params(source_params))
  end

  # Replay branches for search-result navigation, keyed by the action that produced
  # the result set.
  def composition_collection_builders
    {
      "index" => ->(source) { build_composition_search_collection(source) },
      "quick_query" => ->(source) { replayable_quick_query(Composition, source) }
    }
  end

  def build_release_types_from_params(params)
    release_type_param = params[:release_type]

    if release_type_param.present?
      release_type_param.map {|type| type.to_i} if release_type_param.present?
    end

  end

  def infinite_scroll_config
    {
      model: Composition,
      records_name: :albums,
      partial: 'composition_rows',
      default_sort_params: DEFAULT_SORT_PARAMS,
      index_path: compositions_index_path,
      quick_query_path: compositions_quick_query_path,
      additional_search_params: ->(params) { [build_release_types_from_params(params)] }
    }
  end

end
