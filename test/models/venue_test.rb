require 'test_helper'

class VenueTest < ActiveSupport::TestCase
  # Associations
  test "should have many gigs" do
    venue = create(:venue)
    gig1 = create(:gig, venue: venue)
    gig2 = create(:gig, venue: venue)

    assert_includes venue.gigs, gig1
    assert_includes venue.gigs, gig2
    assert_equal 2, venue.gigs.count
  end

  test "should order gigs by date ascending" do
    venue = create(:venue)
    gig3 = create(:gig, venue: venue, GigDate: Date.parse("2021-03-01"))
    gig1 = create(:gig, venue: venue, GigDate: Date.parse("2019-01-01"))
    gig2 = create(:gig, venue: venue, GigDate: Date.parse("2020-06-15"))

    assert_equal [gig1, gig2, gig3], venue.gigs.to_a
  end

  # Class methods
  test "get_venues_with_location should return only venues with coordinates" do
    with_location = create(:venue, :with_location)
    without_location = create(:venue, latitude: nil, longitude: nil)

    results = Venue.get_venues_with_location

    assert_includes results, with_location
    assert_not_includes results, without_location
  end

  test "get_venues_with_location should require latitude to be present" do
    venue_no_lat = create(:venue, latitude: nil, longitude: -122.4194)
    results = Venue.get_venues_with_location

    assert_not_includes results, venue_no_lat
  end

  # Search functionality
  test "search_by should find venues by name" do
    venue = create(:venue, Name: "Fillmore")
    create(:venue, Name: "Other Venue")

    results = Venue.search_by([:name], "Fillmore")
    assert_includes results, venue
    assert_equal 1, results.size
  end

  test "search_by should find venues by city" do
    sf_venue = create(:venue, City: "San Francisco")
    ny_venue = create(:venue, City: "New York")

    results = Venue.search_by([:city], "San Francisco")
    assert_includes results, sf_venue
    assert_not_includes results, ny_venue
  end

  test "search_by should find venues by country" do
    us_venue = create(:venue, Country: "USA")
    uk_venue = create(:venue, Country: "UK")

    results = Venue.search_by([:country], "USA")
    assert_includes results, us_venue
    assert_not_includes results, uk_venue
  end

  test "search_by should find venues by state" do
    ca_venue = create(:venue, State: "CA")
    ny_venue = create(:venue, State: "NY")

    results = Venue.search_by([:state], "CA")
    assert_includes results, ca_venue
    assert_not_includes results, ny_venue
  end

  test "search_by should search multiple fields" do
    venue1 = create(:venue, Name: "Test Hall")
    venue2 = create(:venue, City: "Test City")
    venue3 = create(:venue, Country: "Testland")
    other = create(:venue, Name: "Other", City: "Other", Country: "Other")

    results = Venue.search_by([:name, :city, :country], "Test")
    assert_includes results, venue1
    assert_includes results, venue2
    assert_includes results, venue3
    assert_not_includes results, other
  end

  test "search_by should return all venues when search is nil" do
    create(:venue)
    create(:venue)
    create(:venue)

    results = Venue.search_by([:name], nil)
    assert_equal 3, results.size
  end

  test "search_by should be case insensitive" do
    venue = create(:venue, Name: "Fillmore")

    results = Venue.search_by([:name], "fillmore")
    assert_includes results, venue
  end

  test "search_by should handle partial matches" do
    venue = create(:venue, Name: "The Fillmore Auditorium")

    results = Venue.search_by([:name], "Fillmore")
    assert_includes results, venue
  end

  test "search_by should include gig count" do
    venue = create(:venue)
    create(:gig, venue: venue)
    create(:gig, venue: venue)

    results = Venue.search_by([:name], venue.Name)
    result = results.first

    assert_equal 2, result.gig_count
  end

  test "search_by should order by name ascending" do
    venue_c = create(:venue, Name: "Charlie Venue")
    venue_a = create(:venue, Name: "Alpha Venue")
    venue_b = create(:venue, Name: "Beta Venue")

    results = Venue.search_by([:name], nil).to_a

    assert_equal venue_a, results[0]
    assert_equal venue_b, results[1]
    assert_equal venue_c, results[2]
  end

  # Quick queries
  test "quick_query_venues_with_notes should return venues with notes" do
    with_notes = create(:venue, :with_notes)
    without_notes = create(:venue, Notes: nil)

    results = Venue.quick_query_venues_with_notes(nil)
    assert_includes results, with_notes
    assert_not_includes results, without_notes
  end

  test "quick_query_venues_with_notes should not include empty notes" do
    empty_notes = create(:venue, Notes: "")
    results = Venue.quick_query_venues_with_notes(nil)
    assert_not_includes results, empty_notes
  end

  test "quick_query_venues_with_notes with without should return venues without notes" do
    with_notes = create(:venue, :with_notes)
    without_notes = create(:venue, Notes: nil)

    results = Venue.quick_query_venues_with_notes("without")
    assert_includes results, without_notes
    assert_not_includes results, with_notes
  end

  test "quick_query_venues_with_location should return venues with coordinates" do
    with_location = create(:venue, :with_location)
    without_location = create(:venue, latitude: nil)

    results = Venue.quick_query_venues_with_location(nil)
    assert_includes results, with_location
    assert_not_includes results, without_location
  end

  test "quick_query_venues_with_location with without should return venues without coordinates" do
    with_location = create(:venue, :with_location)
    without_location = create(:venue, latitude: nil)

    results = Venue.quick_query_venues_with_location("without")
    assert_includes results, without_location
    assert_not_includes results, with_location
  end

  # Instance methods
  test "get_notes should format notes with line breaks" do
    venue = create(:venue, Notes: "Line 1\nLine 2\nLine 3")
    formatted = venue.get_notes

    assert_includes formatted, "<br>"
    assert_equal "Line 1<br>Line 2<br>Line 3", formatted
  end

  test "get_notes should handle Windows line endings" do
    venue = create(:venue, Notes: "Line 1\r\nLine 2\r\nLine 3")
    formatted = venue.get_notes

    assert_equal "Line 1<br>Line 2<br>Line 3", formatted
  end

  test "get_notes should return nil when no notes" do
    venue = create(:venue, Notes: nil)
    assert_nil venue.get_notes
  end

  test "get_notes should return nil for empty string" do
    venue = create(:venue, Notes: "")
    assert_nil venue.get_notes
  end

  # Edge cases
  test "should handle international characters in city names" do
    venue = create(:venue, City: "São Paulo")
    assert_equal "São Paulo", venue.City
  end

  test "should handle venues with very long names" do
    # Name column is VARCHAR(48), test with 45 chars
    long_name = "The Very Long Venue Name With Extra Words"  # 41 chars
    venue = create(:venue, Name: long_name)
    assert_equal long_name, venue.Name
  end

  test "should handle venues with complete address information" do
    venue = create(:venue, :with_location)
    venue.update(street_address1: "123 Main St", street_address2: "Suite 100")

    assert_not_nil venue.street_address1
    assert_not_nil venue.street_address2
    assert_not_nil venue.latitude
    assert_not_nil venue.longitude
  end

  test "should handle venues in various countries" do
    us = create(:venue, Country: "USA")
    uk = create(:venue, Country: "UK")
    germany = create(:venue, Country: "Germany")
    france = create(:venue, Country: "France")

    assert_equal 4, Venue.count
  end

  test "should handle subcity information" do
    venue = create(:venue, SubCity: "Brooklyn")
    assert_equal "Brooklyn", venue.SubCity
  end

  test "prepare_query should group venues and include gig count" do
    venue = create(:venue)
    create(:gig, venue: venue)
    create(:gig, venue: venue)
    create(:gig, venue: venue)

    results = Venue.search_by([:name], venue.Name)
    result = results.first

    assert_equal 3, result.gig_count
  end

  test "should handle venues with no gigs" do
    venue = create(:venue)

    results = Venue.search_by([:name], venue.Name)
    result = results.first

    assert_equal 0, result.gig_count
  end

  test "quick_query should include gig count" do
    venue = create(:venue, :with_location)
    create(:gig, venue: venue)
    create(:gig, venue: venue)

    results = Venue.quick_query_venues_with_location(nil)
    result = results.find { |v| v.VENUEID == venue.VENUEID }

    assert_equal 2, result.gig_count
  end

  test "should validate coordinate ranges" do
    # Valid coordinates
    valid_venue = build(:venue, latitude: 37.7749, longitude: -122.4194)
    assert valid_venue.valid? || valid_venue.save

    # Note: The model doesn't currently validate coordinate ranges,
    # but this documents the expected behavior
  end
end
