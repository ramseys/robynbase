class ResourceSorter
  def self.sort(collection, resource_type:, sort_column: nil, direction: nil)
    return collection if sort_column.blank?

    direction = direction == 'desc' ? 'desc' : 'asc'

    case resource_type
    when :gig
      sort_gigs(collection, sort_column, direction)
    when :song
      sort_songs(collection, sort_column, direction)
    when :composition
      sort_compositions(collection, sort_column, direction)
    when :venue
      sort_venues(collection, sort_column, direction)
    else
      collection
    end
  end

  private

  def self.sort_gigs(collection, sort_column, direction)
    case sort_column
    when 'venue'
      collection.order("Venue #{direction}")
    when 'billed_as'
      collection.order("BilledAs #{direction}")
    when 'city'
      collection.joins(:venue).order("VENUE.City #{direction}")
    when 'state'
      collection.joins(:venue).order("VENUE.State #{direction}")
    when 'country'
      collection.joins(:venue).order("VENUE.Country #{direction}")
    when 'date'
      collection.order("GigDate #{direction}")
    else
      collection.order("GigDate desc")
    end
  end

  def self.sort_songs(collection, sort_column, direction)
    case sort_column
    when 'name'
      collection.order("SONG.Song #{direction}")
    when 'original_band'
      collection.order("SONG.OrigBand #{direction}")
    when 'author'
      collection.order("SONG.Author #{direction}")
    when 'performances'
      collection.left_joins(:gigs).group("SONG.SONGID").order("COUNT(GIG.GIGID) #{direction}")
    else
      collection.order("SONG.Song asc")
    end
  end

  def self.sort_compositions(collection, sort_column, direction)
    case sort_column
    when 'title'
      collection.order("COMP.Title #{direction}")
    when 'artist'
      collection.order("COMP.Artist #{direction}")
    when 'year'
      collection.order("COMP.Year #{direction}")
    when 'label'
      collection.order("COMP.Label #{direction}")
    when 'type'
      collection.order("COMP.Type #{direction}")
    else
      collection.order("COMP.Title asc")
    end
  end

  def self.sort_venues(collection, sort_column, direction)
    case sort_column
    when 'venue'
      collection.order("VENUE.Name #{direction}")
    when 'city'
      collection.order("VENUE.City #{direction}")
    when 'subcity'
      collection.order("VENUE.SubCity #{direction}")
    when 'state'
      collection.order("VENUE.State #{direction}")
    when 'country'
      collection.order("VENUE.Country #{direction}")
    when 'performances'
      collection.left_joins(:gigs).group("VENUE.VENUEID").order("COUNT(GIG.GIGID) #{direction}")
    else
      collection.order("VENUE.Name asc")
    end
  end
end
