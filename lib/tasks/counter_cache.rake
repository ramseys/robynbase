namespace :counter_cache do
  desc "Reset all counter caches"
  task reset_all: :environment do
    puts "Resetting all counter caches..."
    puts ""

    Rake::Task['counter_cache:reset_venues'].invoke
    Rake::Task['counter_cache:reset_songs'].invoke
    Rake::Task['counter_cache:reset_compositions'].invoke

    puts ""
    puts "✅ All counter caches reset successfully!"
  end

  desc "Reset venue gigs_count counter cache"
  task reset_venues: :environment do
    print "Resetting venue gigs_count..."

    count = 0
    Venue.find_each do |venue|
      Venue.reset_counters(venue.VENUEID, :gigs)
      count += 1
      print "\rResetting venue gigs_count... #{count} venues processed"
    end

    puts "\r✅ Venue gigs_count reset complete (#{count} venues)"
  end

  desc "Reset song gigsets_count counter cache"
  task reset_songs: :environment do
    print "Resetting song gigsets_count..."

    count = 0
    Song.find_each do |song|
      Song.reset_counters(song.SONGID, :gigsets)
      count += 1
      print "\rResetting song gigsets_count... #{count} songs processed"
    end

    puts "\r✅ Song gigsets_count reset complete (#{count} songs)"
  end

  desc "Reset composition tracks_count counter cache"
  task reset_compositions: :environment do
    print "Resetting composition tracks_count..."

    count = 0
    Composition.find_each do |comp|
      Composition.reset_counters(comp.COMPID, :tracks)
      count += 1
      print "\rResetting composition tracks_count... #{count} compositions processed"
    end

    puts "\r✅ Composition tracks_count reset complete (#{count} compositions)"
  end

  desc "Verify counter cache accuracy"
  task verify: :environment do
    puts "Verifying counter cache accuracy..."
    puts ""

    errors = []

    # Check venues
    print "Checking venues..."
    Venue.find_each do |venue|
      actual_count = venue.gigs.count
      cached_count = venue.gigs_count
      if actual_count != cached_count
        errors << "Venue #{venue.VENUEID} (#{venue.Name}): cached=#{cached_count}, actual=#{actual_count}"
      end
    end
    puts " done"

    # Check songs
    print "Checking songs..."
    Song.find_each do |song|
      actual_count = song.gigsets.count
      cached_count = song.gigsets_count
      if actual_count != cached_count
        errors << "Song #{song.SONGID} (#{song.full_name}): cached=#{cached_count}, actual=#{actual_count}"
      end
    end
    puts " done"

    # Check compositions
    print "Checking compositions..."
    Composition.find_each do |comp|
      actual_count = comp.tracks.count
      cached_count = comp.tracks_count
      if actual_count != cached_count
        errors << "Composition #{comp.COMPID} (#{comp.Title}): cached=#{cached_count}, actual=#{actual_count}"
      end
    end
    puts " done"

    puts ""
    if errors.empty?
      puts "✅ All counter caches are accurate!"
    else
      puts "⚠️  Found #{errors.length} counter cache discrepancies:"
      errors.each { |error| puts "  - #{error}" }
      puts ""
      puts "Run 'rake counter_cache:reset_all' to fix these issues."
    end
  end
end
