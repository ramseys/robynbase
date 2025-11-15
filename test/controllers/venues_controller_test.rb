require 'test_helper'

class VenuesControllerTest < ActionDispatch::IntegrationTest
  # Index
  test "should get index" do
    get venues_path
    assert_response :success
  end

  test "should search venues by name" do
    venue = create(:venue, Name: "Fillmore")
    get venues_path, params: { search_type: "name", search_value: "Fillmore" }
    assert_response :success
  end

  test "should search venues by city" do
    venue = create(:venue, City: "San Francisco")
    get venues_path, params: { search_type: "city", search_value: "San Francisco" }
    assert_response :success
  end

  # Show
  test "should show venue" do
    venue = create(:venue)
    get venue_path(venue.VENUEID)
    assert_response :success
  end

  test "should show venue with gigs" do
    venue = create(:venue)
    3.times { create(:gig, venue: venue) }
    get venue_path(venue.VENUEID)
    assert_response :success
  end

  # CRUD (requires auth)
  test "should create venue when logged in" do
    user = create(:user)
    post sessions_path, params: { email: user.email, password: "password123" }

    assert_difference('Venue.count', 1) do
      post venues_path, params: { venue: { Name: "New Venue", City: "City" } }
    end
  end

  test "should update venue when logged in" do
    user = create(:user)
    venue = create(:venue, Name: "Old Name")
    post sessions_path, params: { email: user.email, password: "password123" }

    patch venue_path(venue.VENUEID), params: { venue: { Name: "New Name" } }
    venue.reload
    assert_equal "New Name", venue.Name
  end

  test "should destroy venue when logged in" do
    user = create(:user)
    venue = create(:venue)
    post sessions_path, params: { email: user.email, password: "password123" }

    assert_difference('Venue.count', -1) do
      delete venue_path(venue.VENUEID)
    end
  end

  # Quick queries
  test "should handle with_notes quick query" do
    create(:venue, :with_notes)
    get quick_query_venues_path, params: { query_id: "with_notes" }
    assert_response :success
  end

  test "should handle with_location quick query" do
    create(:venue, :with_location)
    get quick_query_venues_path, params: { query_id: "with_location" }
    assert_response :success
  end
end
