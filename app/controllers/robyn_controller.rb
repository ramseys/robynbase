class RobynController < ApplicationController

  def index

    search = params[:search_value] 

    logger.info "search: #{search}"

    if not search.nil? 
      @songs = Song.search_by [:title], search
      @compositions = Composition.search_by [:title], search
      @gigs = Gig.search_by [:venue], search
      @venues = Venue.search_by [:name], search
    end
    
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

end
