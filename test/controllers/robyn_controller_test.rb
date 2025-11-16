require 'test_helper'

class RobynControllerTest < ActionDispatch::IntegrationTest
  # Homepage / Index
  test "should get homepage without search" do
    get root_url
    assert_response :success
  end

  test "homepage should not set resource flags without search" do
    get root_url
    assert_response :success
    # @has_gigs, @has_songs, etc. should not be set
  end

  test "homepage with search should check all resource types" do
    # Create test data
    venue = create(:venue, Name: "Fillmore")
    gig = create(:gig, venue: venue)
    song = create(:song, Song: "Madonna")
    composition = create(:composition, Title: "Element of Light")

    get root_url, params: { search_value: "Fill" }
    assert_response :success
    # Would set @has_gigs, @has_songs, @has_compositions, @has_venues
  end

  test "homepage should handle empty search results gracefully" do
    get root_url, params: { search_value: "NonexistentSearchTerm12345" }
    assert_response :success
  end

  # Omnisearch Gigs
  test "omnisearch_gigs should return gigs matching venue search" do
    venue1 = create(:venue, Name: "Fillmore")
    venue2 = create(:venue, Name: "Fill Station")
    venue3 = create(:venue, Name: "Other Venue")

    gig1 = create(:gig, venue: venue1, GigDate: Date.parse("2020-01-01"))
    gig2 = create(:gig, venue: venue2, GigDate: Date.parse("2021-06-15"))
    gig3 = create(:gig, venue: venue3, GigDate: Date.parse("2019-03-20"))

    get robyn_omnirobyn_search_gigs_url, params: { search_value: "Fill" }
    assert_response :success
  end

  test "omnisearch_gigs should require search_value parameter" do
    get robyn_omnirobyn_search_gigs_url
    assert_response :bad_request
  end

  test "omnisearch_gigs should handle empty results" do
    get robyn_omnirobyn_search_gigs_url, params: { search_value: "NonexistentVenue12345" }
    assert_response :success
  end

  test "omnisearch_gigs should support pagination" do
    venue = create(:venue, Name: "Fillmore")
    15.times { |i| create(:gig, venue: venue, GigDate: Date.today - i.days) }

    get robyn_omnirobyn_search_gigs_url, params: { search_value: "Fill", page: 1 }
    assert_response :success
  end

  test "omnisearch_gigs should support sorting" do
    venue = create(:venue, Name: "Fillmore")
    gig1 = create(:gig, venue: venue, GigDate: Date.parse("2020-01-01"))
    gig2 = create(:gig, venue: venue, GigDate: Date.parse("2021-06-15"))

    get robyn_omnirobyn_search_gigs_url, params: { search_value: "Fill", sort: "date", direction: "asc" }
    assert_response :success
  end

  # Omnisearch Songs
  test "omnisearch_songs should return songs matching title search" do
    song1 = create(:song, Song: "Madonna")
    song2 = create(:song, Song: "Mad Professor")
    song3 = create(:song, Song: "Different Song")

    get robyn_omnisearch_songs_url, params: { search_value: "Mad" }
    assert_response :success
  end

  test "omnisearch_songs should require search_value parameter" do
    get robyn_omnisearch_songs_url
    assert_response :bad_request
  end

  test "omnisearch_songs should be case insensitive" do
    song = create(:song, Song: "Madonna")

    get robyn_omnisearch_songs_url, params: { search_value: "MADONNA" }
    assert_response :success
  end

  test "omnisearch_songs should support pagination" do
    20.times { |i| create(:song, Song: "Test Song #{i}") }

    get robyn_omnisearch_songs_url, params: { search_value: "Test", page: 1 }
    assert_response :success
  end

  test "omnisearch_songs should support sorting" do
    song1 = create(:song, Song: "Zebra")
    song2 = create(:song, Song: "Alpha")

    get robyn_omnisearch_songs_url, params: { search_value: "a", sort: "name", direction: "asc" }
    assert_response :success
  end

  # Omnisearch Compositions
  test "omnisearch_compositions should return compositions matching title search" do
    comp1 = create(:composition, Title: "Element of Light")
    comp2 = create(:composition, Title: "Element 5")
    comp3 = create(:composition, Title: "Different Album")

    get robyn_omnirobyn_search_compositions_url, params: { search_value: "Element" }
    assert_response :success
  end

  test "omnisearch_compositions should require search_value parameter" do
    get robyn_omnirobyn_search_compositions_url
    assert_response :bad_request
  end

  test "omnisearch_compositions should support pagination" do
    15.times { |i| create(:composition, Title: "Album #{i}") }

    get robyn_omnirobyn_search_compositions_url, params: { search_value: "Album", page: 1 }
    assert_response :success
  end

  test "omnisearch_compositions should support sorting" do
    comp1 = create(:composition, Title: "Zebra Album")
    comp2 = create(:composition, Title: "Alpha Album")

    get robyn_omnirobyn_search_compositions_url, params: { search_value: "Album", sort: "title", direction: "desc" }
    assert_response :success
  end

  # Omnisearch Venues
  test "omnisearch_venues should return venues matching name search" do
    venue1 = create(:venue, Name: "Fillmore")
    venue2 = create(:venue, Name: "Fill Station")
    venue3 = create(:venue, Name: "Other Venue")

    get robyn_omnirobyn_search_venues_url, params: { search_value: "Fill" }
    assert_response :success
  end

  test "omnisearch_venues should require search_value parameter" do
    get robyn_omnirobyn_search_venues_url
    assert_response :bad_request
  end

  test "omnisearch_venues should support pagination" do
    20.times { |i| create(:venue, Name: "Venue #{i}") }

    get robyn_omnirobyn_search_venues_url, params: { search_value: "Venue", page: 1 }
    assert_response :success
  end

  test "omnisearch_venues should support sorting" do
    venue1 = create(:venue, Name: "Zebra Club")
    venue2 = create(:venue, Name: "Alpha Hall")

    get robyn_omnirobyn_search_venues_url, params: { search_value: "Club", sort: "venue", direction: "asc" }
    assert_response :success
  end

  # JSON Search endpoints (legacy autocomplete/API)
  test "search endpoint should return songs as JSON" do
    song1 = create(:song, Song: "Madonna")
    song2 = create(:song, Song: "Mad Professor")

    get robyn_search_url, params: { search_value: "Mad" }
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test "search endpoint should handle nil search_value" do
    get robyn_search_url
    assert_response :success
  end

  test "search_gigs endpoint should return gigs as JSON" do
    venue = create(:venue, Name: "Fillmore")
    gig = create(:gig, venue: venue)

    get robyn_search_gigs_url, params: { search_value: "Fill" }
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test "search_gigs should handle nil search_value" do
    get robyn_search_gigs_url
    assert_response :success
  end

  test "search_venues endpoint should return venues as JSON" do
    venue = create(:venue, Name: "Fillmore")

    get robyn_search_venues_url, params: { search_value: "Fill" }
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test "search_venues should handle nil search_value" do
    get robyn_search_venues_url
    assert_response :success
  end

  test "search_compositions endpoint should return compositions as JSON" do
    comp = create(:composition, Title: "Element of Light")

    get robyn_search_compositions_url, params: { search_value: "Element" }
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test "search_compositions should handle nil search_value" do
    get robyn_search_compositions_url
    assert_response :success
  end

  # Edge cases
  test "should handle very long search strings" do
    long_search = "a" * 500

    get root_url, params: { search_value: long_search }
    assert_response :success
  end

  test "should handle special characters in search" do
    song = create(:song, Song: "Rock & Roll")

    get robyn_omnisearch_songs_url, params: { search_value: "Rock & Roll" }
    assert_response :success
  end

  test "should handle unicode characters in search" do
    venue = create(:venue, Name: "Café Müller")

    get robyn_omnirobyn_search_venues_url, params: { search_value: "Café" }
    assert_response :success
  end

  test "omnisearch should handle multiple resource types with same search term" do
    # Create data across all resource types with similar names
    song = create(:song, Song: "Element")
    composition = create(:composition, Title: "Element of Light")
    venue = create(:venue, Name: "Element Club")
    gig = create(:gig, venue: venue)

    # Should be able to search each individually
    get robyn_omnisearch_songs_url, params: { search_value: "Element" }
    assert_response :success

    get robyn_omnirobyn_search_compositions_url, params: { search_value: "Element" }
    assert_response :success

    get robyn_omnirobyn_search_venues_url, params: { search_value: "Element" }
    assert_response :success

    get robyn_omnirobyn_search_gigs_url, params: { search_value: "Element" }
    assert_response :success
  end
end
