require 'test_helper'

class GigManagementTest < ActionDispatch::IntegrationTest
  test "user can browse gigs and view details" do
    venue = create(:venue, Name: "Fillmore", City: "San Francisco")
    gig = create(:gig, venue: venue, GigDate: Date.parse("2020-06-15"))
    song1 = create(:song, Song: "Madonna")
    song2 = create(:song, Song: "Kingdom of Love")
    create(:gigset, gig: gig, song: song1, Chrono: 1)
    create(:gigset, gig: gig, song: song2, Chrono: 2)

    # Browse gigs
    get gigs_path
    assert_response :success

    # Search by venue
    get gigs_path, params: { search_type: "venue", search_value: "Fillmore" }
    assert_response :success

    # View gig details
    get gig_path(gig.GIGID)
    assert_response :success
  end

  test "user can view on_this_day gigs" do
    today = Date.today
    gig_today = create(:gig, GigDate: Date.new(today.year - 1, today.month, today.day))
    gig_other = create(:gig, GigDate: Date.new(today.year - 1, (today.month % 12) + 1, 1))

    get on_this_day_gigs_path
    assert_response :success
  end

  test "authenticated user can manage gigs" do
    user = create(:user)
    venue = create(:venue)

    # Login
    post sessions_path, params: { email: user.email, password: "password123" }

    # Create gig
    post gigs_path, params: {
      gig: {
        VENUEID: venue.VENUEID,
        Venue: venue.Name,
        GigDate: Date.today.strftime('%Y-%m-%d'),
        BilledAs: "Robyn Hitchcock"
      }
    }

    gig = Gig.last
    assert_not_nil gig

    # Update gig
    patch gig_path(gig.GIGID), params: {
      gig: { BilledAs: "Robyn Hitchcock & The Egyptians" }
    }

    gig.reload
    assert_equal "Robyn Hitchcock & The Egyptians", gig.BilledAs

    # Delete gig
    assert_difference('Gig.count', -1) do
      delete gig_path(gig.GIGID)
    end
  end
end
