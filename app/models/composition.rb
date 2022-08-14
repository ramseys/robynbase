class Composition < ApplicationRecord

  self.table_name = "COMP"

  has_many :tracks, foreign_key: "COMPID", dependent: :delete_all
  has_many :songs, through: :tracks, foreign_key: "TRAKID"

  accepts_nested_attributes_for :tracks

  # types of media, and the order in which they should appear
  MEDIA_TYPES = {
    'CD'         => 0,
    'Vinyl LP'   => 1,
    'Vinyl 12"'  => 2,
    'Vinyl 7"'   => 3,
    'Cassette'   => 4,
    'CD 3"'      => 5,
    'CD Single'  => 6,
    'DVD'        => 7,
    'Flexi-disc' => 8,
    'Videotape'  => 9,
    'Other'      => 10
  }

  MEDIA_TYPES.default = 10;

  # types of releases, in the order in which they should appear
  RELEASE_TYPES = {
    'Official Release' => 0,
    'Compilation'      => 1,
    'Promo'            => 2,
    'Radio show'       => 3,
    'Bootleg'          => 4,
    'Internet'         => 5,
    'Fan Club release' => 6,
    'Other'            => 7
  }

  RELEASE_TYPES.default = 7;


  @@quick_queries = [ 
    QuickQuery.new('compositions', :major_cd_releases),
    QuickQuery.new('compositions', :other_bands)
  ]
    
  # returns the songs played in the gig (non-encore)
  def get_tracklist
    self.tracks.includes(:song).where(bonus: false)
  end

  # returns the songs played in the encore
  def get_tracklist_bonus
    self.tracks.includes(:song).where(bonus: true)
  end
  
  def self.search_by(kind, search, media_types = nil, release_types = nil)

    kind = [:title, :year, :label] if kind.nil? or kind.length == 0

    conditions = Array(kind).map do |term|

      case term 
        when :title
          column = "Title"
        when :year
          column = "Year"
        when :label
          column = "Label"
        when :artist
          column = "Artist"
      end

      "#{column} LIKE ?"

    end

    if search.present? or media_types.present? or release_types.present?

      # grab albums according to the given search type/value
      albums = where(conditions.join(" OR "), *Array.new(conditions.length, "%#{search}%"))

      # filter by media type
      if media_types.present?
        albums = albums.where(Medium: MEDIA_TYPES.select {|name, key| media_types.include?(key)}.keys )
      end

      # filter by release type
      if release_types.present?
        albums = albums.where(Type: RELEASE_TYPES.select {|name, key| release_types.include?(key)}.keys )        
      end

    else
      albums = all

    end

    # order by year
    albums = albums.order(:Year => :asc, :COMPID => :asc)

    # remove duplicated albums (ie, albums with multiple editions)
    # TODO: why aren't i just doing this in the query? group by title?
    albums = albums.to_a.uniq { |f| [f.Title ] }

  end 

  # an array of all available quick queries
  def self.get_quick_queries 
    @@quick_queries
  end

  # look up songs based on the given quick query
  def self.quick_query(id, secondary_attribute)

    case id
      when :major_cd_releases.to_s
        albums = quick_query_major_releases
      when :other_bands.to_s
        albums = quick_query_other_bands
    end

    albums

  end


  ## quick queries
  def self.quick_query_major_releases
    where("majrid IS NOT NULL AND majrid <> 0 AND type = 'Authorized' AND medium = 'CD'").order(:year)
  end

  def self.quick_query_other_bands
    where("artist not like '%robyn%'")
  end

end