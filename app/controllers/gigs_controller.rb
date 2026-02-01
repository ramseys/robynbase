class GigsController < ApplicationController

  include ImageUtils
  include ImageOrderingConcern
  include Paginated
  include InfiniteScrollConcern

  TABLE_ID = 'gig-main'.freeze
  DEFAULT_SORT_PARAMS = { sort: 'date', direction: 'desc' }.freeze
  
  authorize_resource :only => [:new, :edit, :update, :create, :destroy]

  RANGE_TYPE = {
    :years => 0,
    :months => 1,
    :days => 2
  }

  def index
    if params[:search_type].present?

      search_type = params[:search_type].to_sym

      date_criteria = build_date_criteria_from_params(params)

      # grab gigs that meet *all* the specified criteria
      gigs_collection = Gig.search_by(search_type, params[:search_value], date_criteria, params[:gig_type])
      @pagy, @gigs = apply_sorting_and_pagination(gigs_collection, table_id: TABLE_ID, default_sort_params: DEFAULT_SORT_PARAMS)

    # if we're looking for gigs for a given venue
    elsif params[:venue_id].present?

      gigs_collection = Gig.get_gigs_by_venueid(params[:venue_id])
      @pagy, @gigs = apply_sorting_and_pagination(gigs_collection, table_id: TABLE_ID, default_sort_params: DEFAULT_SORT_PARAMS)

    else
      params[:search_type] = "venue"
      @gigs = nil
      @pagy = nil
    end

  end

  def show
    # Eager load associations to avoid N+1 queries
    @gig = Gig.includes(:venue, :gigmedia, gigsets: :song, images_attachments: :blob).find(params[:id])
  end

  # prepare gig create page
  def new

    @gig = Gig.new

    # get a list of all songs (for the songs selection dropddown)
    @song_list = Song.order(:Song).collect{|s| [s.full_name, s.SONGID]}

    save_referrer

  end


   # prepare gig update page
  def edit

    @gig = Gig.find(params[:id])

    # get a list of all songs (for the songs selection dropddown)
    @song_list = Song.order(:Song).collect{|s| [s.full_name, s.SONGID]}

    save_referrer

  end


  # create a new gig
  def create

    params, setlist_songs, media = prepare_params()

    optimize_images(params)

    @gig = Gig.new(params)

    if @gig.save

      if setlist_songs.present?
        @gig.gigsets.create(setlist_songs)
      end

      if media.present?
        @gig.gigmedia.create(media)
      end

      # assign positions to newly uploaded images
      assign_positions_to_new_images(@gig)

      redirect_to(@gig)

    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new"
    end

  end

  # update existing gig
  def update

    gig = Gig.find(params[:id])

    filtered_params, setlist_songs, media, images = prepare_params(true)

    # purge images marked for removal
    purge_marked_images(params)

    # optimize new images
    optimize_images({ images: images }) if images.present?

    # TODO put all this in a transaction
    gig.gigsets.clear()
    gig.gigmedia.clear()

    # update with latest setlist info
    if setlist_songs.present?
      gig.gigsets.build(setlist_songs)
    end

    if media.present?
      gig.gigmedia.build(media)
    end

    if gig.update(filtered_params) then

      # if there are any image updates, attach them to the gig
      # note: we can't rely on the model to do this for us, because rails
      # will always replace existing images with the new ones; we need to
      # append these to exiting images
      gig.images.attach(images) if images.present?

      # assign positions to newly uploaded images
      assign_positions_to_new_images(gig)

      # update positions for reordered images
      update_image_positions

    end

    redirect_to(gig)

  end

  def destroy
    gig = Gig.find(params[:id])
    gig.destroy

    redirect_back fallback_location: gigs_url

  end

  # Renders embedded table of gigs related to another resource (e.g., all gigs for a venue or song).
  # Provides paginated, sortable lists via Turbo Frames for display within other pages without navigation.
  def for_resource
    resource_type = params[:resource_type]
    resource_id = params[:resource_id]
    @table_id = "gig-#{resource_type}"

    case resource_type
    when 'song'
      @resource = Song.find(resource_id)
      # Use joins to get gigs, but select distinct on the gig ID to avoid duplicates
      gigs_collection = Gig.joins(:gigsets).where(gigsets: { SONGID: @resource.SONGID }).distinct.includes(:venue)
    when 'venue'
      @resource = Venue.find(resource_id)
      gigs_collection = @resource.gigs.includes(:venue)
    when 'composition'
      @resource = Composition.find(resource_id)
      gigs_collection = @resource.gigs.includes(:venue)
    else
      head :not_found
      return
    end

    @pagy, @gigs = apply_sorting_and_pagination(
      gigs_collection,
      table_id: @table_id,
      default_sort_params: DEFAULT_SORT_PARAMS,
      items_per_page: 10,
      turbo_frame: "table_frame"
    )

    render partial: 'shared/turbo_gig_table'
  end

  def quick_query
    gigs_collection = Gig.quick_query(params[:query_id], params[:query_attribute])
    @pagy, @gigs = apply_sorting_and_pagination(gigs_collection, table_id: TABLE_ID, default_sort_params: DEFAULT_SORT_PARAMS)
    render "index"
  end

  def on_this_day
    gigs_collection = Gig.quick_query_gigs_on_this_day(params['date']['month'], params['date']['day'])
    @pagy, @gigs = apply_sorting_and_pagination(gigs_collection, table_id: TABLE_ID, default_sort_params: DEFAULT_SORT_PARAMS)
    render "index"
  end

  private


  def apply_sorting(collection)
    # Clear any existing ordering before applying new sort
    collection = collection.reorder('')

    ResourceSorter.sort(collection,
                       resource_type: :gig,
                       sort_column: params[:sort],
                       direction: params[:direction])
  end

  def return_to_previous_page(gig)
    previous_page = session.delete(:return_to_gig)
    if previous_page.present?
      redirect_to previous_page
    else
      redirect_to gig
    end
  end

  def save_referrer
    session[:return_to_gig] = request.referer
  end

  def infinite_scroll_config
    {
      model: Gig,
      records_name: :gigs,
      partial: 'gig_rows',
      default_sort_params: DEFAULT_SORT_PARAMS,
      additional_search_params: ->(params) { [build_date_criteria_from_params(params), params[:gig_type]] }
    }
  end

  def build_date_criteria_from_params(params)
    return nil unless params[:gig_date].present? && params[:gig_range].present?

    gig_date = DateTime.strptime(params[:gig_date], "%Y-%m-%d")
    range_type = :months
    range = 30

    # Look for the kind of range (day, year, etc) we'll be using for this date
    if params[:gig_range_type].present?
      range_type = RANGE_TYPE.key(params[:gig_range_type].to_i)
    end

    # Look for the amount of time on either side of the given date should be included in the search
    if params[:gig_range].present?
      range = params[:gig_range].to_i
    end

    {
      date: gig_date,
      range_type: range_type,
      range: range
    }
  end

  # Prepare the setlist for save
  #
  # 1. Order songs by giving each the appropriate "Chrono" index
  # 2. Save denormalized song in GigSet table
  def prepare_setlist(setlist_songs, starting_index, encore)

    last_index = starting_index

    # Preload all songs to avoid N+1 queries
    song_ids = setlist_songs.values.map { |s| s["SONGID"].to_i }.compact.uniq
    songs_by_id = Song.where(SONGID: song_ids).index_by(&:SONGID)

    # loop through every song in the setlist in order (non-encore or encore), normalizing their sequence numbers
    setlist_songs.values.select{|val| val["Encore"] == encore.to_s}.sort_by{|a| a["Chrono"].to_i }.each_with_index do |b, i|

      last_index = starting_index + i

      # sequence in 10s
      b["Chrono"] = (last_index * 10).to_s

      # if there's no override song name, add in the real song name
      if b["SONGID"].present? && b["Song"].empty?
        song = songs_by_id[b["SONGID"].to_i]
        b["Song"] = song.full_name if song
      end

      # empty text fields should be null in the database
      b[:MediaLink] = nil if b[:MediaLink].present? && b[:MediaLink].strip.empty?
      b[:VersionNotes] = nil if b[:VersionNotes].present? && b[:VersionNotes].strip.empty?

    end

    last_index + 1

  end

  def prepare_media(media_links)

    # loop through every media item in order, normalizing their sequence numbers
    media_links.values.sort_by{|a| a["Chrono"].to_i }.each_with_index do |b, i|

      # sequence in 10s
      b["Chrono"] = (i * 10).to_s

      # empty text fields should be null in the database
      b[:title] = nil if b[:title].strip.empty?

      # if a full youtube link was provided, extract the id
      if b[:mediatype].to_i === GigMedium::MEDIA_TYPE["YouTube"]
        if b[:mediaid][/watch\?/].present?
          b[:mediaid] = b[:mediaid][/v=([^&?]*)[\?]/, 1]
        elsif b[:mediaid][/youtu\.be/].present?
          b[:mediaid] = b[:mediaid][/youtu\.be\/([^&?]*)/, 1]
        end

      # if a full archive.org "details" link was provided, extract the id
      elsif b[:mediatype].to_i === GigMedium::MEDIA_TYPE["ArchiveOrgVideo"] or
         b[:mediatype].to_i === GigMedium::MEDIA_TYPE["ArchiveOrgPlaylist"] and
         b[:mediaid][/\/details\/.*/].present?

        b[:mediaid] = b[:mediaid][/\/details\/(.*)$/, 1]

      # if a vimeo link was provided, extract the id
      elsif b[:mediatype].to_i === GigMedium::MEDIA_TYPE["Vimeo"] and
            b[:mediaid][/vimeo\.com\//].present?

        b[:mediaid] = b[:mediaid][/vimeo\.com\/([^&]*)/, 1]

      # if a soundcloud embed string is provided, extract the id
      elsif b[:mediatype].to_i === GigMedium::MEDIA_TYPE["Soundcloud"] and
            b[:mediaid][/api\.soundcloud\.com\//].present?

        b[:mediaid] = b[:mediaid][/api\.soundcloud\.com\/tracks\/([^&]*)/, 1]

      end

    end

  end

  # Massage incoming params for saving.
  #
  # 1. Orders the songs in the setlists and encores
  # 2. Save denormalized vendor name in Gig table
  # 3. Save denormalized gig year in Gig table
  # 4. Optionally extracts attaches images into a separate return value
  def prepare_params(extract_images = false)

    new_params = gig_params()

    # loop through all the non-encore songs
    setlist_songs = new_params["gigsets_attributes"]

    # renumber the setlists chronologically (both non-encore and encore)
    if setlist_songs.present?
      start_encore_index = prepare_setlist(setlist_songs, 1, false)
      prepare_setlist(setlist_songs, start_encore_index, true)
    end

    media = new_params["gigmedia_attributes"]

    if media.present?
      prepare_media(media)
    end

    # get rid of now-extraneous setlist params
    new_params.delete("gigsets_attributes")
    new_params.delete("gigmedia_attributes")

    # save the name of the venue
    new_params["Venue"] = Venue.find(new_params["VENUEID"].to_i).Name if new_params["Venue"].strip.empty?

    # extract the year from the date
    new_params["GigYear"] = Date.strptime(params["gig"]["GigDate"], '%Y-%m-%d').year

    # if requested, extract images into a separate variable
    if extract_images then
      images = new_params["images"]
      if (images.present?) then
        new_params.delete("images")
      end
    end

    return [new_params,
            setlist_songs.present? ? setlist_songs.values : nil,
            media.present? ? media.values : nil,
            images]

  end

  def gig_params

    # permit attributes we're saving
    params
      .require(:gig)
      .permit(:VENUEID, :GigDate, :ShortNote, :Reviews, :Guests, :BilledAs, :GigType, :Venue, :Circa, :cancelled, :Favorite, :images,
             images: [],
             deleted_img_ids: [],
             gigsets_attributes: [ :Chrono, :SONGID, :Song, :VersionNotes, :Encore, :MediaLink],
             gigmedia_attributes: [ :Chrono, :title, :mediaid, :mediatype ]).tap do |params|

          # every gig needs at least a venue id and a date
          params.require([:VENUEID, :GigDate])

          # every item in a setlist requires a sequence number
          if params["gigsets_attributes"].present?
            params["gigsets_attributes"].each do |key, params|
              params.require([:Chrono])
            end
          end

          # every item in a media list requires a sequence number and a media identifier
          if params["gigmedia_attributes"].present?
            params["gigmedia_attributes"].each do |key, params|
              params.require([:Chrono])
              params.require([:mediaid])
            end
          end

      end

  end

end
