# what is NameSearch column for?
# Not used:
#   TaperFriendly
class Venue < ApplicationRecord
  self.table_name = "VENUE"

  has_many :gigs, -> { order('GIG.GigDate ASC') }, foreign_key: "VENUEID"

  def self.get_venues_with_location
    where.not(:latitude => nil)
  end

  @@quick_queries = [ 
    QuickQuery.new('venues', :with_notes, [:without]),
    QuickQuery.new('venues', :with_location, [:without]),
  ]

  def self.search_by(kind, search)

    kind = [:name, :city, :country] if kind.nil? or kind.length == 0

    conditions = Array(kind).map do |term|

      case term
        when :name
          column = "Name"
        when :city
          column = "City"
        when :country
          column = "Country"
        when :state
          column = "State"
        when :subcity
          column = "SubCity"
        else
          column = "Name"
      end

      "#{column} LIKE ?"

    end

    if search
      venues = where(conditions.join(" OR "), *Array.new(conditions.length, "%#{search}%"))
    else
      venues = all
    end

    venues.order(:Name => :asc)

    self.prepare_query(venues)

  end

  def self.prepare_query(songs)
    songs.left_outer_joins(:gigs)
      .select('VENUE.*, COUNT(GIG.VENUEID) AS gig_count')
      .group('VENUE.VENUEID')
      .order('VENUE.Name ASC')
  end

  # returns the notes for this venue (if any), formatted to display correctly in html
  def get_notes
    if self.Notes.present?
      # Handle both Unix (\n) and Windows (\r\n) line endings
      self.Notes.gsub(/\r\n|\n/, '<br>')
    end
  end


  ## quick queries

  # an array of all available quick queries
  def self.get_quick_queries 
    @@quick_queries
  end


  # look up venues based on the given quick query
  def self.quick_query(id, secondary_attribute)

    case id
      when :with_notes.to_s
        venues = quick_query_venues_with_notes(secondary_attribute)
      when :with_location.to_s
        venues = quick_query_venues_with_location(secondary_attribute)
    end

    venues

  end
  

  def self.quick_query_venues_with_notes(secondary_attribute)

    venues = secondary_attribute.nil? ?
      where.not(Notes: [nil, '']) :
      where(Notes: [nil, ''])

    self.prepare_query(venues)

  end

  def self.quick_query_venues_with_location(secondary_attribute)

    venues = secondary_attribute.nil? ?
      where.not(latitude: nil) :
      where(latitude: nil)

    self.prepare_query(venues)

  end

end