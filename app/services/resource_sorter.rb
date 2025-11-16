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
    direction_sym = direction.to_sym

    case sort_column
    when 'venue'
      collection.order(Venue: direction_sym)
    when 'billed_as'
      collection.order(BilledAs: direction_sym)
    when 'city'
      collection.joins(:venue).order('VENUE.City' => direction_sym)
    when 'state'
      collection.joins(:venue).order('VENUE.State' => direction_sym)
    when 'country'
      collection.joins(:venue).order('VENUE.Country' => direction_sym)
    when 'date'
      collection.order(GigDate: direction_sym)
    else
      collection.order(GigDate: :desc)
    end
  end

  def self.sort_songs(collection, sort_column, direction)
    direction_sym = direction.to_sym

    case sort_column
    when 'name'
      collection.order('SONG.Song' => direction_sym)
    when 'original_band'
      collection.order('SONG.OrigBand' => direction_sym)
    when 'author'
      collection.order('SONG.Author' => direction_sym)
    when 'performances'
      # Use counter cache instead of JOIN/COUNT for much better performance
      collection.order(gigsets_count: direction_sym)
    else
      collection.order('SONG.Song' => :asc)
    end
  end

  def self.sort_compositions(collection, sort_column, direction)
    direction_sym = direction.to_sym

    case sort_column
    when 'title'
      collection.order('COMP.Title' => direction_sym)
    when 'artist'
      collection.order('COMP.Artist' => direction_sym)
    when 'year'
      collection.order('COMP.Year' => direction_sym)
    when 'label'
      collection.order('COMP.Label' => direction_sym)
    when 'type'
      collection.order('COMP.Type' => direction_sym)
    else
      collection.order('COMP.Title' => :asc)
    end
  end

  def self.sort_venues(collection, sort_column, direction)
    direction_sym = direction.to_sym

    case sort_column
    when 'venue'
      collection.order('VENUE.Name' => direction_sym)
    when 'city'
      collection.order('VENUE.City' => direction_sym)
    when 'subcity'
      collection.order('VENUE.SubCity' => direction_sym)
    when 'state'
      collection.order('VENUE.State' => direction_sym)
    when 'country'
      collection.order('VENUE.Country' => direction_sym)
    when 'performances'
      # Use counter cache instead of JOIN/COUNT for much better performance
      collection.order(gigs_count: direction_sym)
    else
      collection.order('VENUE.Name' => :asc)
    end
  end
end
