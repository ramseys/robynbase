class AddCounterCaches < ActiveRecord::Migration[7.2]
  def up
    # Add counter cache for venues to track number of gigs
    add_column :VENUE, :gigs_count, :integer, default: 0, null: false

    # Add counter cache for songs to track number of performances (gigsets)
    add_column :SONG, :gigsets_count, :integer, default: 0, null: false

    # Add counter cache for compositions to track number of tracks
    add_column :COMP, :tracks_count, :integer, default: 0, null: false

    # Backfill existing counts
    # This may take a while on large datasets, but ensures data integrity
    puts "Backfilling venue gigs counts..."
    Venue.find_each do |venue|
      Venue.reset_counters(venue.VENUEID, :gigs)
    end

    puts "Backfilling song gigsets counts..."
    Song.find_each do |song|
      Song.reset_counters(song.SONGID, :gigsets)
    end

    puts "Backfilling composition tracks counts..."
    Composition.find_each do |comp|
      Composition.reset_counters(comp.COMPID, :tracks)
    end

    puts "Counter cache backfill complete!"
  end

  def down
    remove_column :VENUE, :gigs_count
    remove_column :SONG, :gigsets_count
    remove_column :COMP, :tracks_count
  end
end
