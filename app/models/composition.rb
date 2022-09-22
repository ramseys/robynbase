class Composition < ApplicationRecord

  self.table_name = "COMP"

  has_many :tracks, -> {order 'Seq'}, foreign_key: "COMPID", dependent: :delete_all
  has_many :songs, through: :tracks, foreign_key: "TRAKID"
  has_many_attached :images, :dependent => :destroy

  accepts_nested_attributes_for :tracks

  # types of releases, in the order in which they should appear
  RELEASE_TYPES = {
    'Album'            => 0,
    'Single'           => 1,
    'EP'               => 2, 
    'Compilation'      => 3,
    'Promo'            => 4,
    'Radio show'       => 5,
    'Bootleg'          => 6,
    'Internet'         => 7,
    'Fan Club release' => 8,
    'Video'            => 10,
    'Other'            => 9
  }

  @@quick_queries = [ 
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
  
  def self.search_by(kind, search, release_types = nil)

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

    if search.present? or release_types.present?

      # grab albums according to the given search type/value
      releases = where(conditions.join(" OR "), *Array.new(conditions.length, "%#{search}%"))

      # filter by release type
      if release_types.present?
        releases = releases.where(Type: RELEASE_TYPES.select {|name, key| release_types.include?(key)}.keys )        
      end

    else
      releases = all

    end

    # order by year
    releases = releases.order(:Year => :asc, :COMPID => :asc)

    # remove duplicated releases (ie, releases with multiple editions)
    # TODO: why aren't i just doing this in the query? group by title?
    releases = releases.to_a.uniq { |f| [f.Title ] }

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
  def self.quick_query_other_bands
    where("artist not like '%robyn%'")
  end

end