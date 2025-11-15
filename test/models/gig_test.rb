require 'test_helper'

class GigTest < ActiveSupport::TestCase
  # Associations
  test "should belong to venue" do
    venue = create(:venue)
    gig = create(:gig, venue: venue)

    assert_equal venue, gig.venue
  end

  test "should have many gigsets" do
    gig = create(:gig)
    gigset1 = create(:gigset, gig: gig)
    gigset2 = create(:gigset, gig: gig)

    assert_includes gig.gigsets, gigset1
    assert_includes gig.gigsets, gigset2
    assert_equal 2, gig.gigsets.count
  end

  test "should have many songs through gigsets" do
    gig = create(:gig)
    song1 = create(:song)
    song2 = create(:song)
    create(:gigset, gig: gig, song: song1)
    create(:gigset, gig: gig, song: song2)

    assert_includes gig.songs, song1
    assert_includes gig.songs, song2
    assert_equal 2, gig.songs.count
  end

  test "should have many gigmedia" do
    gig = create(:gig)
    media1 = create(:gig_medium, gig: gig)
    media2 = create(:gig_medium, gig: gig)

    assert_includes gig.gigmedia, media1
    assert_includes gig.gigmedia, media2
    assert_equal 2, gig.gigmedia.count
  end

  test "should order gigsets by Chrono" do
    gig = create(:gig)
    gigset3 = create(:gigset, gig: gig, Chrono: 3)
    gigset1 = create(:gigset, gig: gig, Chrono: 1)
    gigset2 = create(:gigset, gig: gig, Chrono: 2)

    assert_equal [gigset1, gigset2, gigset3], gig.gigsets.to_a
  end

  # Instance methods
  test "get_set should return non-encore songs" do
    gig = create(:gig)
    regular_song = create(:gigset, gig: gig, Encore: false)
    encore_song = create(:gigset, gig: gig, Encore: true)

    set = gig.get_set
    assert_includes set, regular_song
    assert_not_includes set, encore_song
  end

  test "get_set_encore should return only encore songs" do
    gig = create(:gig)
    regular_song = create(:gigset, gig: gig, Encore: false)
    encore_song = create(:gigset, gig: gig, Encore: true)

    encore = gig.get_set_encore
    assert_includes encore, encore_song
    assert_not_includes encore, regular_song
  end

  test "get_reviews should format reviews with line breaks" do
    gig = create(:gig, Reviews: "Great show!\nBest concert ever!\nAmazing setlist")
    formatted = gig.get_reviews

    assert_includes formatted, "<br>"
    assert_equal "Great show!<br>Best concert ever!<br>Amazing setlist", formatted
  end

  test "get_reviews should handle Windows line endings" do
    gig = create(:gig, Reviews: "Line 1\r\nLine 2\r\nLine 3")
    formatted = gig.get_reviews

    assert_equal "Line 1<br>Line 2<br>Line 3", formatted
  end

  test "get_reviews should return nil when no reviews" do
    gig = create(:gig, Reviews: nil)
    assert_nil gig.get_reviews
  end

  # Search functionality
  test "search_by should find gigs by venue name" do
    gig = create(:gig, Venue: "Fillmore")
    create(:gig, Venue: "Other Venue")

    results = Gig.search_by([:venue], "Fillmore")
    assert_includes results, gig
    assert_equal 1, results.count
  end

  test "search_by should find gigs by year" do
    gig2020 = create(:gig, GigYear: "2020")
    gig2021 = create(:gig, GigYear: "2021")

    results = Gig.search_by([:gig_year], "2020")
    assert_includes results, gig2020
    assert_not_includes results, gig2021
  end

  test "search_by should find gigs by venue city" do
    venue_sf = create(:venue, City: "San Francisco")
    venue_ny = create(:venue, City: "New York")
    gig_sf = create(:gig, venue: venue_sf)
    gig_ny = create(:gig, venue: venue_ny)

    results = Gig.search_by([:venue_city], "San Francisco")
    assert_includes results, gig_sf
    assert_not_includes results, gig_ny
  end

  test "search_by should search multiple fields" do
    venue1 = create(:venue, City: "TestCity")
    venue2 = create(:venue, City: "Other")
    gig1 = create(:gig, Venue: "Test Venue", venue: venue2)
    gig2 = create(:gig, Venue: "Other", venue: venue1)
    gig3 = create(:gig, Venue: "Different", GigYear: "Test", venue: venue2)

    results = Gig.search_by([:venue, :gig_year, :venue_city], "Test")
    assert_includes results, gig1
    assert_includes results, gig2
    assert_includes results, gig3
  end

  test "search_by should return all gigs when search is nil" do
    create(:gig)
    create(:gig)
    create(:gig)

    results = Gig.search_by([:venue], nil)
    assert_equal 3, results.count
  end

  test "search_by should filter by gig type when provided" do
    concert = create(:gig, GigType: "Concert")
    radio = create(:gig, GigType: "Radio")

    results = Gig.search_by([:venue], nil, nil, "Concert")
    assert_includes results, concert
    assert_not_includes results, radio
  end

  test "search_by should filter by date range when provided" do
    date = Date.parse("2020-06-15")
    gig_in_range = create(:gig, GigDate: Date.parse("2020-06-20"))
    gig_out_of_range = create(:gig, GigDate: Date.parse("2020-12-25"))

    date_criteria = { date: date, range_type: :months, range: 1 }
    results = Gig.search_by([:venue], nil, date_criteria)

    assert_includes results, gig_in_range
    assert_not_includes results, gig_out_of_range
  end

  # Quick queries
  test "quick_query_gigs_with_setlists should return gigs with setlists" do
    with_setlist = create(:gig, :with_setlist)
    without_setlist = create(:gig)

    results = Gig.quick_query_gigs_with_setlists(nil)
    assert_includes results, with_setlist
    assert_not_includes results, without_setlist
  end

  test "quick_query_gigs_with_setlists with without should return gigs without setlists" do
    with_setlist = create(:gig, :with_setlist)
    without_setlist = create(:gig)

    results = Gig.quick_query_gigs_with_setlists("without")
    assert_includes results, without_setlist
    assert_not_includes results, with_setlist
  end

  test "quick_query_gigs_without_definite_dates should return circa gigs" do
    circa_gig = create(:gig, :circa)
    definite_gig = create(:gig, Circa: false)

    results = Gig.quick_query_gigs_without_definite_dates
    assert_includes results, circa_gig
    assert_not_includes results, definite_gig
  end

  test "quick_query_gigs_with_reviews should return gigs with reviews" do
    with_reviews = create(:gig, :with_reviews)
    without_reviews = create(:gig, Reviews: nil)

    results = Gig.quick_query_gigs_with_reviews(nil)
    assert_includes results, with_reviews
    assert_not_includes results, without_reviews
  end

  test "quick_query_gigs_with_reviews with without should return gigs without reviews" do
    with_reviews = create(:gig, :with_reviews)
    without_reviews = create(:gig, Reviews: nil)

    results = Gig.quick_query_gigs_with_reviews("without")
    assert_includes results, without_reviews
    assert_not_includes results, with_reviews
  end

  test "quick_query_gigs_with_media should return gigs with media" do
    with_media = create(:gig)
    create(:gig_medium, gig: with_media)
    without_media = create(:gig)

    results = Gig.quick_query_gigs_with_media(nil)
    assert_includes results, with_media
    assert_not_includes results, without_media
  end

  test "quick_query_gigs_with_media should include gigs with song media links" do
    gig = create(:gig)
    create(:gigset, gig: gig, MediaLink: "https://youtube.com/watch?v=test")

    results = Gig.quick_query_gigs_with_media(nil)
    assert_includes results, gig
  end

  test "quick_query_gigs_with_media with without should return gigs without any media" do
    with_media = create(:gig)
    create(:gig_medium, gig: with_media)
    without_media = create(:gig)

    results = Gig.quick_query_gigs_with_media("without")
    assert_includes results, without_media
    assert_not_includes results, with_media
  end

  # on_this_day tests
  test "quick_query_gigs_on_this_day should return gigs on today's date in history" do
    today = Date.today
    same_day_last_year = create(:gig, GigDate: Date.new(today.year - 1, today.month, today.day))
    same_day_two_years_ago = create(:gig, GigDate: Date.new(today.year - 2, today.month, today.day))
    different_day = create(:gig, GigDate: Date.new(today.year - 1, (today.month % 12) + 1, 1))

    results = Gig.quick_query_gigs_on_this_day

    assert_includes results, same_day_last_year
    assert_includes results, same_day_two_years_ago
    assert_not_includes results, different_day
  end

  test "quick_query_gigs_on_this_day should accept custom month and day" do
    june_15_2020 = create(:gig, GigDate: Date.parse("2020-06-15"))
    june_15_2019 = create(:gig, GigDate: Date.parse("2019-06-15"))
    june_16_2020 = create(:gig, GigDate: Date.parse("2020-06-16"))

    results = Gig.quick_query_gigs_on_this_day(6, 15)

    assert_includes results, june_15_2020
    assert_includes results, june_15_2019
    assert_not_includes results, june_16_2020
  end

  test "quick_query_gigs_on_this_day should handle leap year dates" do
    feb_29_2020 = create(:gig, GigDate: Date.parse("2020-02-29"))
    feb_28_2020 = create(:gig, GigDate: Date.parse("2020-02-28"))

    results = Gig.quick_query_gigs_on_this_day(2, 29)

    assert_includes results, feb_29_2020
    assert_not_includes results, feb_28_2020
  end

  test "quick_query_gigs_on_this_day can exclude gigs without setlists" do
    today = Date.today
    with_setlist = create(:gig, GigDate: Date.new(today.year - 1, today.month, today.day))
    create(:gigset, gig: with_setlist)
    without_setlist = create(:gig, GigDate: Date.new(today.year - 2, today.month, today.day))

    results = Gig.quick_query_gigs_on_this_day(nil, nil, false)

    assert_includes results, with_setlist
    assert_not_includes results, without_setlist
  end

  # Class method tests
  test "get_gigs_by_venueid should return all gigs at a venue" do
    venue = create(:venue)
    other_venue = create(:venue)
    gig1 = create(:gig, venue: venue)
    gig2 = create(:gig, venue: venue)
    other_gig = create(:gig, venue: other_venue)

    results = Gig.get_gigs_by_venueid(venue.VENUEID)

    assert_includes results, gig1
    assert_includes results, gig2
    assert_not_includes results, other_gig
  end

  test "get_distinct_venue_count should count unique venues" do
    venue1 = create(:venue)
    venue2 = create(:venue)
    create(:gig, venue: venue1)
    create(:gig, venue: venue1)  # Same venue twice
    create(:gig, venue: venue2)

    assert_equal 2, Gig.get_distinct_venue_count
  end

  test "get_gig_count should count all gigs" do
    create(:gig)
    create(:gig)
    create(:gig)

    assert_equal 3, Gig.get_gig_count
  end

  test "get_gigset_count should count all gigsets" do
    gig1 = create(:gig)
    gig2 = create(:gig)
    create(:gigset, gig: gig1)
    create(:gigset, gig: gig1)
    create(:gigset, gig: gig2)

    assert_equal 3, Gig.get_gigset_count
  end

  test "get_distinct_song_performances should count unique songs performed" do
    song1 = create(:song)
    song2 = create(:song)
    gig1 = create(:gig)
    gig2 = create(:gig)

    create(:gigset, song: song1, gig: gig1)
    create(:gigset, song: song1, gig: gig2)  # Same song, different gig
    create(:gigset, song: song2, gig: gig1)

    assert_equal 2, Gig.get_distinct_song_performances
  end

  # Edge cases
  test "should handle gigs with no date" do
    gig = create(:gig, :no_date)
    assert_nil gig.GigDate
    assert_not_nil gig.GigYear
  end

  test "should handle gigs with guests" do
    gig = create(:gig, :with_guests)
    assert_not_nil gig.Guests
  end

  test "should handle various gig types" do
    Gig::GIG_TYPES.each do |type|
      gig = create(:gig, GigType: type)
      assert_equal type, gig.GigType
    end
  end

  test "should sort on_this_day results by date ascending" do
    today = Date.today
    gig2020 = create(:gig, GigDate: Date.new(2020, today.month, today.day))
    gig2019 = create(:gig, GigDate: Date.new(2019, today.month, today.day))
    gig2021 = create(:gig, GigDate: Date.new(2021, today.month, today.day))

    results = Gig.quick_query_gigs_on_this_day.to_a

    assert_equal gig2019, results[0]
    assert_equal gig2020, results[1]
    assert_equal gig2021, results[2]
  end

  test "should handle date range search with different range types" do
    date = Date.parse("2020-06-15")
    gig = create(:gig, GigDate: date)

    # Test with days range
    date_criteria = { date: date, range_type: :days, range: 7 }
    results = Gig.search_by([:venue], nil, date_criteria)
    assert_includes results, gig

    # Test with years range
    date_criteria = { date: date, range_type: :years, range: 1 }
    results = Gig.search_by([:venue], nil, date_criteria)
    assert_includes results, gig
  end
end
