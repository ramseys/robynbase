class CompositionsController < ApplicationController

  authorize_resource :only => [:new, :edit, :update, :create, :destroy]

  def index

    search_type_param  = params[:search_type]
    media_type_param   = params[:media_type]
    release_type_param = params[:release_type]

    if search_type_param.nil?
      params[:search_type] = "title"
    end

    # if the user entered any search terms at all    
    if search_type_param.present? || media_type_param.present? || release_type_param.present?

      # textual search
      search_type = search_type_param.present? ? search_type_param.to_sym : nil

      # media types
    media_types = media_type_param.map {|type| type.to_i} if media_type_param.present?

      # release types
      release_types = release_type_param.map {|type| type.to_i} if release_type_param.present?

      # grab the albums, based on the given search criteria
      @compositions = Composition.search_by(search_type, params[:album_search_value], media_types, release_types)

    end

  end

  def show

    # get the requested album
    @comp = Composition.find(params[:id])

    # get album art (if any)
    @associated_images = get_associated_images(@comp.Title)

  end

  def get_associated_images(title)
    Dir["public/images/album-art/*"].entries.select { |name| name.index(/#{title}/i) }.sort.map{ |name| name.sub("public/", "").sub("[", "%5B").sub("]", "%5D")}
  end


  # prepare composition create page
  def new

    @comp = Composition.new

    # get a list of all songs (for the songs selection dropddown)
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
    
    params, tracks = prepare_params()
  
    # optimize_images(params)
      
    @comp = Composition.new(params)
    
    if @comp.save

      if tracks.present?
        @comp.tracks.create(tracks)
      end
      
      redirect_to(@comp)
      
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new"
    end

  end

  # update existing composition
  def update 
  
    comp = Composition.find(params[:id])

    filtered_params, tracks = prepare_params()

    # purse images marked for removal
    # attachments = ActiveStorage::Attachment.where(id: params[:deleted_img_ids])
    # attachments.map(&:purge)

    # optimize new images
    # optimize_images(filtered_params)

    # TODO put all this in a transaction
    comp.tracks.clear()

    # update with latest setlist info
    if tracks.present?
      comp.tracks.build(tracks)
    end

    comp.update(filtered_params)
    
    redirect_to(comp)
    
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

    # loop through every song in the track list in order, normalizing their sequence numbers
    tracks.values.select{|val| val["bonus"] == bonus.to_s}.sort_by{ |a| a["Seq"].to_i }.each_with_index do |b, i|

      last_index = starting_index + i

      # sequence in 10s
      b["Seq"] = (last_index * 10).to_s  

      # if there's no override song name, add in the real song name
      if b["SONGID"].present? 
        b["Song"] = Song.find(b["SONGID"].to_i).full_name if b["Song"].empty?
      end

      b[:VersionNotes] = nil if b[:VersionNotes].strip.empty?
      
    end

    starting_index

  end

  def prepare_params

    new_params = comp_params()
            
    # loop through all the non-encore songs
    tracks = new_params["tracks_attributes"]

    # renumber the tracks chronologically (official and additonal)
    if tracks.present?      
      start_bonus_index = prepare_tracks(tracks, 1, false)
      prepare_tracks(tracks, start_bonus_index, true)
    end

    # get rid of now-extraneous track list params
    new_params.delete("tracks_attributes")

    return [new_params, tracks.present? ? tracks.values : nil]

  end


  def comp_params

    # permit attributes we're saving
    params
      .require(:composition)
      .permit(:Title, :Artist, :Year, :Label, :discogs_url, :Comments, :Type,
              tracks_attributes: [ :Seq, :SONGID, :Song, :VersionNotes, :bonus, :id ]).tap do |params|
          
          # byebug

          # every gig needs at least a title and artist
          params.require([:Title, :Artist])

          # every item in a track list requires a sequence number
          if params["tracks_attributes"].present? 
            params["tracks_attributes"].each do |key, params|
              params.require([:Seq])
            end
          end

      end
              
          
  end

  def quick_query
    
    if params[:query_id].to_sym == :major_cd_releases 
      @initial_sort = { :column_index => 4, :direction => 'asc' }
    end

    @compositions = Composition.quick_query(params[:query_id], params[:query_attribute])
    render "index"

  end

end
