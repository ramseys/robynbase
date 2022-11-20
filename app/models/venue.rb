# what is NameSearch column for?
# Not used:
#   TaperFriendly
class Venue < ApplicationRecord
  self.table_name = "VENUE"

  has_many :gigs, foreign_key: "VENUEID"

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
  end

  # returns the notes for this venue (if any), formatted to display correctly in html
  def get_notes
    if self.Notes.present?
      self.Notes.gsub(/\r\n/, '<br>')
    end
  end

end