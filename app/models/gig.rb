# Columns not in use:
#   StartTime  (only 3  records, all invalid dates)
#   Performance
#   Sound
#   Rarity


class Gig < ApplicationRecord

  self.table_name = "GIG"

  has_many :gigsets, -> {order 'Chrono'}, foreign_key: "GIGID", dependent: :delete_all
  has_many :gigmedia, -> {order 'Chrono'}, foreign_key: "GIGID", dependent: :delete_all

  has_many :songs, through: :gigsets, foreign_key: "GIGID"
  belongs_to :venue, foreign_key: "VENUEID"

  accepts_nested_attributes_for :gigsets, :gigmedia

  @@quick_queries = [ 
    QuickQuery.new('gigs', :with_setlists, [:without]),
    QuickQuery.new('gigs', :without_definite_dates),
    QuickQuery.new('gigs', :with_reviews, [:without]),
    QuickQuery.new('gigs', :with_media)
  ]

  # returns the songs played in the gig (non-encore)
  def get_set
    self.gigsets.includes(:song).where(encore: false)
  end

  # returns the songs played in the encore
  def get_set_encore
    self.gigsets.includes(:song).where(encore: true)
  end

  # returns the reviews for this gig (if any), formatted to display correctly in html
  def get_reviews
    if self.Reviews.present?
      self.Reviews.gsub(/\r\n/, '<br>')
    end
  end

  def self.search_by(kind, search, date_criteria = nil)

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

    if search

      gigs = left_outer_joins(:venue).where(conditions.join(" OR "), *Array.new(conditions.length, "%#{search}%"))

      if date_criteria.present?
        date = date_criteria[:date]
        range_type = date_criteria[:range_type]
        range = date_criteria[:range]

        # debugger
        
        gigs = gigs.where(:gigdate => date.advance(range_type => -range) .. date.advance(range_type => range))

      end

      # sort final results by date
      gigs.includes(:venue).sort { |x,y | x.GigDate <=> y.GigDate }

    else
      all
    end

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
        gigs = quick_query_gigs_with_media
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

  def self.quick_query_gigs_with_media

    # look for media in both the gig proper and in setlists
    sets_with_media = joins("LEFT JOIN GSET on GIG.gigid = GSET.gigid").where("GSET.MediaLink IS NOT NULL").distinct
    gigs_with_media = joins("RIGHT OUTER JOIN gigmedia on GIG.gigid = gigmedia.gigid")
    
    sql = Gig.connection.unprepared_statement {
      "((#{sets_with_media.to_sql}) UNION (#{gigs_with_media.to_sql})) AS GIG"
    }

    Gig.from(sql).order(:GigDate)

  end

end