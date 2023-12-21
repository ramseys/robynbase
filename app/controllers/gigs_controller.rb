class GigsController < ApplicationController
  
  include ImageUtils

  authorize_resource :only => [:new, :edit, :update, :create, :destroy]

  RANGE_TYPE = {
    :years => 0,
    :months => 1,
    :days => 2
  }

  def index

    if params[:search_type].present?

      search_type = params[:search_type].to_sym

      date_criteria = nil

      # if the user specified a gig date as one of the criteria, prepare all the other data
      # that goes along with doing a date query
      if params[:gig_date].present? and params[:gig_range].present?

        gig_date = DateTime.strptime(params[:gig_date], "%Y-%m-%d")
        range_type = :months
        range = 30


        # look for the kind of range (day, year, etc) we'll be using for this date
        if params[:gig_range_type].present?
          range_type = RANGE_TYPE.key(params[:gig_range_type].to_i)
        else
          params[:gig_range_type] = RANGE_TYPE[range_type]
        end

        # look for the amount of time on either side of the given date should be included in the search
        if params[:gig_range].present?
          range = params[:gig_range].to_i
        else
          params[:gig_range] = range
        end

        date_criteria = {
          :date       => gig_date,
          :range_type => range_type,
          :range      => range
        }

      end

      # grab gigs that meet *all* the secified criteria
      @gigs = Gig.search_by(search_type, params[:gig_search_value], date_criteria)

    # if we're looking for gigs for a given venue
    elsif params[:venue_id].present?

      @gigs = Gig.get_gigs_by_venueid(params[:venue_id])
      
    else
      params[:search_type] = "venue"
    end

  end

  def show
    @gig = Gig.find(params[:id])
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

    filtered_params, setlist_songs, media = prepare_params()

    # purge images marked for removal
    purge_marked_images(params)

    # optimize new images
    optimize_images(filtered_params)

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

    gig.update(filtered_params)
    
    redirect_to(gig)
    
  end

  def destroy
    gig = Gig.find(params[:id])
    gig.destroy

    redirect_back fallback_location: gigs_url

  end

  def quick_query
    @gigs = Gig.quick_query(params[:query_id], params[:query_attribute])
    render "index"
  end

  def on_this_day
    # date = Time.new(1983, params['date']['month'], params['date']['day']);
    @gigs = Gig.quick_query_gigs_on_this_day(params['date']['month'], params['date']['day'])
    render "index"
  end

  private
  
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

  # Prepare the setlist for save
  #
  # 1. Order songs by giving each the appropriate "Chrono" index
  # 2. Save denormalized song in GigSet table
  def prepare_setlist(setlist_songs, starting_index, encore)
    
    last_index = starting_index

    # loop through every song in the setlist in order (non-encore or encore), normalizing their sequence numbers
    setlist_songs.values.select{|val| val["Encore"] == encore.to_s}.sort_by{|a| a["Chrono"].to_i }.each_with_index do |b, i|

      last_index = starting_index + i

      # sequence in 10s
      b["Chrono"] = (last_index * 10).to_s

      # if there's no override song name, add in the real song name
      if b["SONGID"].present? 
        b["Song"] = Song.find(b["SONGID"].to_i).full_name if b["Song"].empty?
      end

      # empty text fields should be null in the database
      b[:MediaLink] = nil if b[:MediaLink].strip.empty?
      b[:VersionNotes] = nil if b[:VersionNotes].strip.empty?

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
          b[:mediaid] = b[:mediaid][/v=([^&]*)/, 1]
        elsif b[:mediaid][/youtu\.be/].present?
          b[:mediaid] = b[:mediaid][/youtu\.be\/([^&]*)/, 1]
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
  def prepare_params

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
    new_params["GigYear"] = Time.new(params["gig"]["GigDate"]).year

    return [new_params, 
            setlist_songs.present? ? setlist_songs.values : nil, 
            media.present? ? media.values : nil]

  end

  def gig_params

    # permit attributes we're saving
    params
      .require(:gig)
      .permit(:VENUEID, :GigDate, :ShortNote, :Reviews, :Guests, :BilledAs, :GigType, :Venue, :Circa, :images,
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
