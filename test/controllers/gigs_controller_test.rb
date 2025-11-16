require 'test_helper'

class GigsControllerTest < ActionDispatch::IntegrationTest
  # Index action
  test "should get index without search" do
    get gigs_path
    assert_response :success
  end

  test "should get index with search by venue" do
    venue = create(:venue, Name: "Fillmore")
    gig = create(:gig, venue: venue, Venue: "Fillmore")

    get gigs_path, params: { search_type: "venue", search_value: "Fillmore" }
    assert_response :success
  end

  test "should get index with search by year" do
    gig = create(:gig, GigYear: "2020")
    get gigs_path, params: { search_type: "gig_year", search_value: "2020" }
    assert_response :success
  end

  test "should get index with search by city" do
    venue = create(:venue, City: "San Francisco")
    gig = create(:gig, venue: venue)

    get gigs_path, params: { search_type: "venue_city", search_value: "San Francisco" }
    assert_response :success
  end

  # Show action
  test "should show gig" do
    gig = create(:gig)
    get gig_path(gig.GIGID)
    assert_response :success
  end

  test "should show gig with setlist" do
    gig = create(:gig, :with_setlist, songs_count: 10)
    get gig_path(gig.GIGID)
    assert_response :success
  end

  test "should show gig with media" do
    gig = create(:gig, :with_media)
    get gig_path(gig.GIGID)
    assert_response :success
  end

  # New action (requires authentication)
  test "should get new gig page when logged in" do
    user = create(:user)
    post sessions_path, params: { email: user.email, password: "password123" }

    get new_gig_path
    assert_response :success
  end

  test "should redirect to login when accessing new without authentication" do
    get new_gig_path
    assert_response :redirect
  end

  # Create action (requires authentication)
  test "should create gig when logged in" do
    user = create(:user)
    venue = create(:venue)
    post sessions_path, params: { email: user.email, password: "password123" }

    assert_difference('Gig.count', 1) do
      post gigs_path, params: {
        gig: {
          VENUEID: venue.VENUEID,
          GigDate: Date.today,
          BilledAs: "Robyn Hitchcock"
        }
      }
    end
  end

  test "should not create gig without authentication" do
    venue = create(:venue)

    assert_no_difference('Gig.count') do
      post gigs_path, params: {
        gig: {
          VENUEID: venue.VENUEID,
          GigDate: Date.today
        }
      }
    end

    assert_response :redirect
  end

  # Edit action (requires authentication)
  test "should get edit page when logged in" do
    user = create(:user)
    gig = create(:gig)
    post sessions_path, params: { email: user.email, password: "password123" }

    get edit_gig_path(gig.GIGID)
    assert_response :success
  end

  test "should redirect to login when accessing edit without authentication" do
    gig = create(:gig)
    get edit_gig_path(gig.GIGID)
    assert_response :redirect
  end

  # Update action (requires authentication)
  test "should update gig when logged in" do
    user = create(:user)
    gig = create(:gig, BilledAs: "Original Name")
    post sessions_path, params: { email: user.email, password: "password123" }

    patch gig_path(gig.GIGID), params: {
      gig: {
        BilledAs: "Updated Name"
      }
    }

    gig.reload
    assert_equal "Updated Name", gig.BilledAs
  end

  test "should not update gig without authentication" do
    gig = create(:gig, BilledAs: "Original")

    patch gig_path(gig.GIGID), params: {
      gig: {
        BilledAs: "Should Not Update"
      }
    }

    gig.reload
    assert_equal "Original", gig.BilledAs
    assert_response :redirect
  end

  # Destroy action (requires authentication)
  test "should destroy gig when logged in" do
    user = create(:user)
    gig = create(:gig)
    post sessions_path, params: { email: user.email, password: "password123" }

    assert_difference('Gig.count', -1) do
      delete gig_path(gig.GIGID)
    end
  end

  test "should not destroy gig without authentication" do
    gig = create(:gig)

    assert_no_difference('Gig.count') do
      delete gig_path(gig.GIGID)
    end

    assert_response :redirect
  end

  # Quick queries
  test "should handle with_setlists quick query" do
    with_setlist = create(:gig, :with_setlist)
    without_setlist = create(:gig)

    get gigs_quick_query_path, params: { query_id: "with_setlists" }
    assert_response :success
  end

  test "should handle without_definite_dates quick query" do
    circa_gig = create(:gig, :circa)
    definite_gig = create(:gig)

    get gigs_quick_query_path, params: { query_id: "without_definite_dates" }
    assert_response :success
  end

  test "should handle with_reviews quick query" do
    with_reviews = create(:gig, :with_reviews)
    without_reviews = create(:gig)

    get gigs_quick_query_path, params: { query_id: "with_reviews" }
    assert_response :success
  end

  test "should handle with_media quick query" do
    with_media = create(:gig, :with_media)
    without_media = create(:gig)

    get gigs_quick_query_path, params: { query_id: "with_media" }
    assert_response :success
  end

  # On this day
  test "should get on_this_day gigs" do
    today = Date.today
    gig_this_day = create(:gig, GigDate: Date.new(today.year - 1, today.month, today.day))
    gig_other_day = create(:gig, GigDate: Date.new(today.year - 1, (today.month % 12) + 1, 1))

    get gigs_on_this_day_path
    assert_response :success
  end

  # For resource (gigs for specific song or composition)
  test "should get gigs for specific song" do
    song = create(:song)
    gig = create(:gig)
    create(:gigset, gig: gig, song: song)

    get for_resource_gigs_path, params: { resource_type: "song", resource_id: song.SONGID }
    assert_response :success
  end

  test "should get gigs for specific composition" do
    comp = create(:composition)
    song = create(:song)
    create(:track, composition: comp, song: song)
    gig = create(:gig)
    create(:gigset, gig: gig, song: song)

    get for_resource_gigs_path, params: { resource_type: "composition", resource_id: comp.COMPID }
    assert_response :success
  end

  # Infinite scroll
  test "should handle infinite scroll pagination" do
    15.times { create(:gig) }

    get infinite_scroll_gigs_path, params: { page: 2 }, xhr: true
    assert_response :success
  end

  # Sorting
  test "should sort gigs by date ascending" do
    get gigs_path, params: {
      search_type: "venue",
      search_value: "",
      sort: "date",
      direction: "asc"
    }
    assert_response :success
  end

  test "should sort gigs by date descending" do
    get gigs_path, params: {
      search_type: "venue",
      search_value: "",
      sort: "date",
      direction: "desc"
    }
    assert_response :success
  end

  # Type filtering
  test "should filter by gig type" do
    concert = create(:gig, GigType: "Concert")
    radio = create(:gig, GigType: "Radio")

    get gigs_path, params: {
      search_type: "venue",
      search_value: "",
      type: "Concert"
    }
    assert_response :success
  end

  # Edge cases
  test "should handle gigs with missing dates" do
    gig = create(:gig, :no_date)
    get gig_path(gig.GIGID)
    assert_response :success
  end

  test "should handle gigs with special characters in venue name" do
    venue = create(:venue, Name: "O'Malley's Pub & Grill")
    gig = create(:gig, venue: venue, Venue: "O'Malley's Pub & Grill")

    get gigs_path, params: { search_type: "venue", search_value: "O'Malley" }
    assert_response :success
  end
end
