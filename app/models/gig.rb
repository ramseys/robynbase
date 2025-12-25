# Columns not in use:
#   StartTime  (only 3  records, all invalid dates)
#   Performance
#   Sound
#   Rarity


class Gig < ApplicationRecord
  include SanitizableText

  self.table_name = "GIG"

  GIG_TYPES = ["Concert", "Online", "Radio", "Televison", "In-Store", "Promotional", "Podcast"]

  has_many :gigsets, -> {order 'Chrono'}, foreign_key: "GIGID", dependent: :delete_all
  has_many :gigmedia, -> {order 'Chrono'}, foreign_key: "GIGID", dependent: :delete_all, class_name: 'GigMedium'
  has_many :songs, through: :gigsets, foreign_key: "GIGID"
  has_many_attached :images, :dependent => :destroy

  belongs_to :venue, foreign_key: "VENUEID"

  accepts_nested_attributes_for :gigsets, :gigmedia

  # Configure which fields to sanitize on save
  sanitize_fields :Reviews, :ShortNote

  @@quick_queries = [
    QuickQuery.new('gigs', :with_setlists, [:without]),
    QuickQuery.new('gigs', :without_definite_dates),
    QuickQuery.new('gigs', :with_reviews, [:without]),
    QuickQuery.new('gigs', :with_media, [:without]),
    QuickQuery.new('gigs', :cancelled),
    QuickQuery.new('gigs', :with_images),
    QuickQuery.new('gigs', :favorites),
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

  # returns the reviews for this gig (if any)
  def get_reviews
    add_linebreaks(self.Reviews)
  end

  # returns the short note for this gig (if any)
  def get_short_note
    add_linebreaks(self.ShortNote)
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

    # Return without additional sorting - let the controller handle sort order
    gigs

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
      when :cancelled.to_s
        gigs = quick_query_gigs_cancelled(secondary_attribute)
      when :favorites.to_s
        gigs = quick_query_gigs_favorites
    end

    gigs = gigs.where.not(:venue => nil)

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
    query = joins("LEFT OUTER JOIN GSET on GIG.gigid = GSET.gigid")
    if secondary_attribute.nil?
      query.where("GSET.SETID IS NOT NULL").distinct
    else
      query.where("GSET.SETID IS NULL").distinct
    end
  end

  def self.quick_query_gigs_without_definite_dates
    where(:circa => 1)
  end

  def self.quick_query_gigs_with_reviews(no_reviews)
    if (no_reviews.nil?)
      where("Reviews IS NOT NULL AND Reviews <> ''")
    else 
      where("Reviews IS NULL OR Reviews = ''")
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

      Gig.from(sql)

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
      Gig.where(gigid: no_media_both.map(&:GIGID))

    end
    
  end

  def self.quick_query_gigs_with_images
    joins("JOIN active_storage_attachments asa").where("asa.record_type = 'Gig' and asa.record_id = GIG.GIGID").distinct
  end

  # returns all gigs that occured on the given day (ie, the give day/month, ignoring year).
  # gigs without setlists are excluded
  def self.quick_query_gigs_on_this_day(month = nil, day = nil, allow_empty_sets = true)

    # if no date was provided, use today
    if month.nil?
      today = Date.today
      day = today.day
      month = today.month
    end

    if allow_empty_sets
      gigs = Gig.where("extract(month from GigDate) = ? and extract(day from GigDate) = ?", month, day)
    else
      gigs = Gig.where("extract(month from GigDate) = ? and extract(day from GigDate) = ? and EXISTS (SELECT 1 from GSET where GIG.GIGID = GSET.GIGID)", month, day)
    end

  end

  def self.quick_query_gigs_cancelled(secondary_attribute)
    if secondary_attribute.nil?
      where(cancelled: true)
    else
      where(cancelled: false)
    end
  end

  def self.quick_query_gigs_favorites
    where(Favorite: true)
  end

end