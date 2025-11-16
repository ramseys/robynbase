class AddMissingIndexes < ActiveRecord::Migration[7.2]
  def change
    # Foreign keys that aren't indexed - critical for query performance
    add_index :gigmedia, :GIGID, name: 'index_gigmedia_on_gigid' unless index_exists?(:gigmedia, :GIGID)
    add_index :TRAK, :COMPID, name: 'index_trak_on_compid' unless index_exists?(:TRAK, :COMPID)

    # Commonly queried columns for searches
    add_index :GIG, :GigYear, name: 'index_gig_on_gigyear' unless index_exists?(:GIG, :GigYear)
    add_index :SONG, :Author, name: 'index_song_on_author' unless index_exists?(:SONG, :Author)
    add_index :COMP, :Artist, name: 'index_comp_on_artist' unless index_exists?(:COMP, :Artist)

    # Composite index for map queries
    add_index :VENUE, [:latitude, :longitude], name: 'index_venue_on_lat_lng' unless index_exists?(:VENUE, [:latitude, :longitude])

    # Additional indexes for commonly filtered columns
    add_index :GIG, :Circa, name: 'index_gig_on_circa' unless index_exists?(:GIG, :Circa)
    add_index :SONG, :Improvised, name: 'index_song_on_improvised' unless index_exists?(:SONG, :Improvised)
  end
end
