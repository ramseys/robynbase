# Columns not in use:
#   StartTime  (only 3  records, all invalid dates)
#   Performance
#   Sound
#   Rarity


class Gig < ApplicationRecord

  self.table_name = "GIG"

  GIG_TYPES = ["Concert", "Online", "Radio", "Televison", "In-Store", "Promotional"]

  has_many :gigsets, -> {order 'Chrono'}, foreign_key: "GIGID", dependent: :delete_all
  has_many :gigmedia, -> {order 'Chrono'}, foreign_key: "GIGID", dependent: :delete_all, class_name: 'GigMedium'
  has_many :songs, through: :gigsets, foreign_key: "GIGID"
  has_many_attached :images, :dependent => :destroy

  belongs_to :venue, foreign_key: "VENUEID"

  accepts_nested_attributes_for :gigsets, :gigmedia

  @@quick_queries = [ 
    QuickQuery.new('gigs', :with_setlists, [:without]),
    QuickQuery.new('gigs', :without_definite_dates),
    QuickQuery.new('gigs', :with_reviews, [:without]),
    QuickQuery.new('gigs', :with_media, [:without]),
    QuickQuery.new('gigs', :with_images),
    QuickQuery.new('gigs', :on_this_day)
  ]

  # returns the songs played in the gig (non-encore)
  def get_set
    self.gigsets.includes(:song).where(encore: false)
  end

  # returns the songs played in the encore
  def get_set_encore
    self.gigsets.includes(:song).where(encore: true)
  end

  def self.get_gigs_by_venueid(venueid)
    where(:venueid => venueid)
  end

  # returns the reviews for this gig (if any), formatted to display correctly in html
  def get_reviews
    if self.Reviews.present?
      self.Reviews.gsub(/\r\n/, '<br>')
    end
  end

  def self.search_by(kind, search, date_criteria = nil, type = nil)

    logger.info ("::::::::::: gigs: #{search}")

    kind = [:venue, :gig_year, :venue_city] if kind.nil? or kind.length == 0

    # add conditions for the gig table columns
    conditions = Array(kind).map do |term|

      case term
        when :venue
          column = "Venue"
        when :gig_year
          column = "GigYear"
        when :venue_city
          column = "VENUE.City"
        when :venue_state
          column = "VENUE.State"
        when :venue_country
          column = "VENUE.Country"
        else
          return false
      end

      "#{column} LIKE ?"

    end

    if search.present?

      gigs = left_outer_joins(:venue).where(conditions.join(" OR "), *Array.new(conditions.length, "%#{search}%"))

    else
      gigs = all.includes(:venue)
      
    end

    # if advanced date criteria were provided, narrow the search to the requested data range
    if date_criteria.present?
      date = date_criteria[:date]
      range_type = date_criteria[:range_type]
      range = date_criteria[:range]

      gigs = gigs.where(:gigdate => date.advance(range_type => -range) .. date.advance(range_type => range))

    end

    if type.present?
      gigs = gigs.where(:gigType => type)
    end

    # sort final results by date
    gigs.order(GigDate: :asc)

  end


  # an array of all available quick queries
  def self.get_quick_queries 
    @@quick_queries
  end

  # look up songs based on the given quick query
  def self.quick_query(id, secondary_attribute)

    case id
      when :with_setlists.to_s
        gigs = quick_query_gigs_with_setlists(secondary_attribute)
      when :without_definite_dates.to_s
        gigs = quick_query_gigs_without_definite_dates
      when :with_reviews.to_s
        gigs = quick_query_gigs_with_reviews(secondary_attribute)
      when :with_media.to_s
        gigs = quick_query_gigs_with_media(secondary_attribute)
      when :with_images.to_s
        gigs = quick_query_gigs_with_images
      when :on_this_day.to_s
        gigs = quick_query_gigs_on_this_day
    end

    gigs.where.not(:venue => nil)

  end

  # get the number of venues gigs have been performed at
  def self.get_distinct_venue_count
    Gig.select(:venueid).distinct.count
  end

  # get the total number of gigs
  def self.get_gig_count
    Gig.count
  end

  def self.get_gigset_count
    Gigset.count
  end

  # get the number of songs that have been performed at gigs
  def self.get_distinct_song_performances
    return Gigset.select(:songid).where("SONGID is NOT NULL and SONGID > 0").distinct.count
  end

  ## quick queries

  def self.quick_query_gigs_with_setlists(secondary_attribute)
    joins("LEFT OUTER JOIN GSET on GIG.gigid = GSET.gigid").where("GSET.setid IS #{secondary_attribute.nil? ? 'NOT' : ''} NULL").distinct.order(:GigDate)
  end

  def self.quick_query_gigs_without_definite_dates
    where(:circa => 1).order(:GigDate)
  end

  def self.quick_query_gigs_with_reviews(no_reviews)
    if (no_reviews.nil?)
      where("Reviews IS NOT NULL AND Reviews <> ''").order(:GigDate)
    else 
      where("Reviews IS NULL OR Reviews = ''").order(:GigDate)
    end
  end

  def self.quick_query_gigs_with_media(no_media)

    # gigs with media
    if (no_media.nil?)

      sets_with_media = joins("LEFT JOIN GSET on GIG.gigid = GSET.gigid").where("GSET.MediaLink IS NOT NULL").distinct
      gigs_with_media = joins("RIGHT OUTER JOIN gigmedia on GIG.gigid = gigmedia.gigid")

      sql = Gig.connection.unprepared_statement {
        "((#{sets_with_media.to_sql}) UNION (#{gigs_with_media.to_sql})) AS GIG"
      }

      Gig.from(sql).order(:GigDate)

    # gigs with no media
    else

      # gigs that have no direct media
      no_gig_media = joins("LEFT JOIN gigmedia on GIG.gigid = gigmedia.gigid").where("gigmedia.gigid IS NULL").to_a
      
      # gigs whose gigsets have no media
      no_song_media = Gig.find_by_sql(
        "SELECT * 
        FROM GIG 
        where NOT EXISTS (SELECT 1 FROM GSET WHERE GSET.gigid = GIG.gigid and GSET.MediaLink IS NOT NULL)"
      )

      # get the intersection of the two, to determine which gig entries have no media
      no_media_both = no_gig_media & no_song_media

      # convert the array of the intersection of no gig media and no song (gigset) media back into a relation
      Gig.where(gigid: no_media_both.map(&:GIGID)).order(:GigDate)

    end
    
  end

  def self.quick_query_gigs_with_images
    joins("JOIN active_storage_attachments asa").where("asa.record_type = 'Gig' and asa.record_id = GIG.GIGID").distinct.order(:GigDate)
  end

  # returns all gigs that occured on the given day (ie, the give day/month, ignoring year).
  # gigs without setlists are excluded
  def self.quick_query_gigs_on_this_day(day = Date.today, allow_empty_sets = true)

    if allow_empty_sets 
      Gig.where("extract(month from GigDate) = #{day.month} and extract(day from GigDate) = #{day.day}")
    else
      Gig.where("extract(month from GigDate) = #{day.month} and extract(day from GigDate) = #{day.day} and EXISTS (SELECT 1 from GSET where GIG.GIGID = GSET.GIGID)")
    end

  end

end