# Columns not in use:
#   GIGID

class Song < ApplicationRecord

  self.table_name = "SONG"

  has_many :gigsets, foreign_key: "SONGID"
  has_many :gigs, through: :gigsets, foreign_key: "SONGID"

  has_many :tracks, foreign_key: "SONGID"
  has_many :compositions, through: :tracks, foreign_key: "SONGID"
 
  belongs_to :album, foreign_key: "MAJRID", optional: true
  
  # set up the many-many relationship with the performance table
  has_many :song_performances
  has_many :performances, :through => :song_performances

  @@quick_queries = [ 
    QuickQuery.new('songs', :not_written_by_robyn),
    QuickQuery.new('songs', :never_released, [:originals, :covers]),
    QuickQuery.new('songs', :has_guitar_tabs, [:no_tabs]),
    QuickQuery.new('songs', :has_lyrics, [:no_lyrics]),
    QuickQuery.new('songs', :released_never_played_live)
  ]

  Articles = ["A", "AN", "THE"]

  def self.search_by(kind, search)

    kind = [:title, :lyrics, :author, :song] if kind.nil? or kind.length == 0

    conditions = Array(kind).map do |term|

      case term
        when :title
          column = "Song"
        when :lyrics
          column = "Lyrics"
        when :author
          column = "Author"
        when :originalband
          column = "OrigBand"
        else
          column = "Song"
      end

      "#{column} LIKE ?"

      # used for exact word search
      # "#{column} regexp ?"   

    end

    if search
      songs = where(conditions.join(" OR "), *Array.new(conditions.length, "%#{search}%"))

      # used for exact word search
      #songs = where(conditions.join(" OR "), *Array.new(conditions.length, "(^|[[:space:]])#{search}([[:space:]]|$)"))

    else
      songs = all
    end

    songs.order(:Song => :asc)

  end

  def get_albums
    compositions = self.compositions.order('Year')
    compositions.to_a.uniq { |f| [f.Title ] }    
  end

  def get_comments
    if self.Comments.present?
      self.Comments.gsub(/\r\n/, '<br>')
    end
  end

  def full_name
    if self.new_record?
      ""
    else
      (self.Prefix.present? ? "#{self.Prefix} " : "") + self.Song
    end
  end


  def self.parse_song_name(name)
    
    words = name.split(/\s+/)
    article = nil

    # separate leading articles (a/an/the) from the rest of the song name
    if words.length > 1 and Articles.include? words.first.upcase
      article = words.shift
      song_name = words.join(' ')
    else
      song_name = name
    end
    
    return [article, song_name]
    
  end
  
  def self.find_full_name(name)

    words = name.split(/\s+/)

    if words.length > 1 and Articles.include? words.first.upcase

      article = words.shift
      rest = words.join(' ')

      where(["SONG = ? and PREFIX = ?", rest, article])

    else
      where (["SONG = ?", name])
    end
    
  end

  # create a song record with the given name & author
  def self.make_song_record(name, author = nil)

    words = name.split(/\s+/)
    article = nil

    # separate leading articles (a/an/the) into their own column
    if words.length > 1 and Articles.include? words.first.upcase
      article = words.shift
      song_name = words.join(' ')
    else
      song_name = name
    end

    Song.new do |s| 
      s.Prefix = article
      s.Song = song_name
      s.Author = author
    end

  end


  # returns an array of all available quick queries
  def self.get_quick_queries 
    @@quick_queries
  end

  # look up songs based on the given quick query
  def self.quick_query(id, secondary_attribute)

    case id
      when :not_written_by_robyn.to_s
        songs = get_songs_not_written_by_robyn()
      when :never_released.to_s        
        songs = quick_query_never_released(secondary_attribute)
      when :has_guitar_tabs.to_s
        songs = quick_query_guitar_tabs(secondary_attribute)
      when :has_lyrics.to_s
        songs = quick_query_lyrics(secondary_attribute)
      when :released_never_played_live.to_s
        songs = quick_query_released_no_live_performances
    end

    songs

  end


  ## ------ quick queries

  def self.get_songs_not_written_by_robyn 
    where("Author IS NOT NULL AND Author NOT LIKE '%Hitchcock%'")
  end

  def self.quick_query_never_released(secondary_attribute)

    # songs = joins(:compositions).distinct
    songs = Song.joins("LEFT OUTER JOIN TRAK ON SONG.songid = TRAK.songid").where("TRAK.songid IS NULL").distinct

    case secondary_attribute
      when "originals"
        songs = songs.where(:author => nil)
      when "covers"
        songs = songs.where.not(:author => nil)
    end

    songs

  end

  def self.quick_query_guitar_tabs(has_tabs)
    where("tab IS #{has_tabs.nil? ? 'NOT': ''} NULL")

  end

  def self.quick_query_lyrics(has_lyrics)
    where("lyrics IS #{has_lyrics.nil? ? 'NOT': ''} NULL")
  end

  def self.quick_query_released_no_live_performances
    joins("INNER JOIN TRAK ON SONG.songid = TRAK.songid").joins("LEFT OUTER JOIN GSET ON SONG.songid = GSET.songid").where("GSET.songid IS NULL").distinct
  end

end   