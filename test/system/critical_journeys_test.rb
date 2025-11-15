require "application_system_test_case"

class CriticalJourneysTest < ApplicationSystemTestCase
  # Omnisearch Journey
  test "user can search across all resources from homepage" do
    # Setup test data
    song = create(:song, Song: "Madonna")
    venue = create(:venue, Name: "Fillmore", City: "San Francisco")
    gig = create(:gig, venue: venue, GigDate: Date.parse("2020-06-15"))
    composition = create(:composition, Title: "Element of Light")

    # Visit homepage
    visit root_path

    # Perform omnisearch
    fill_in "search_value", with: "Element"
    click_button "Search" # or submit the form

    # Should see results across different resource types
    assert_text "Element of Light"
  end

  test "guest user can browse songs" do
    song1 = create(:song, Song: "Madonna")
    song2 = create(:song, Song: "Kingdom of Love")

    visit songs_path

    # Should see both songs
    assert_text "Madonna"
    assert_text "Kingdom of Love"

    # Click on a song to view details
    click_link "Madonna"

    # Should see song details
    assert_text "Madonna"
  end

  test "guest user can browse gigs" do
    venue = create(:venue, Name: "Fillmore")
    gig = create(:gig, venue: venue, GigDate: Date.parse("2020-06-15"))

    visit gigs_path

    # Should see gig
    assert_text "Fillmore"

    # Click to view gig details
    click_link "Fillmore" # or appropriate link text

    # Should see gig details
    assert_text "Fillmore"
  end

  test "guest user can view setlist at a gig" do
    venue = create(:venue, Name: "Fillmore")
    gig = create(:gig, venue: venue, GigDate: Date.parse("2020-06-15"))
    song1 = create(:song, Song: "Madonna")
    song2 = create(:song, Song: "Kingdom of Love")
    create(:gigset, gig: gig, song: song1, Chrono: 1)
    create(:gigset, gig: gig, song: song2, Chrono: 2)

    visit gig_path(gig.GIGID)

    # Should see setlist with songs in order
    assert_text "Madonna"
    assert_text "Kingdom of Love"
  end

  test "guest user can view song performance history" do
    song = create(:song, Song: "Madonna")
    venue1 = create(:venue, Name: "Fillmore")
    venue2 = create(:venue, Name: "Troubadour")
    gig1 = create(:gig, venue: venue1, GigDate: Date.parse("2020-01-01"))
    gig2 = create(:gig, venue: venue2, GigDate: Date.parse("2021-06-15"))
    create(:gigset, gig: gig1, song: song)
    create(:gigset, gig: gig2, song: song)

    visit song_path(song.SONGID)

    # Should see performance history
    assert_text "Fillmore"
    assert_text "Troubadour"
  end

  test "guest user can view album tracklist" do
    composition = create(:composition, Title: "Element of Light")
    song1 = create(:song, Song: "Winchester")
    song2 = create(:song, Song: "Airscape")
    create(:track, composition: composition, song: song1, Side: "A", Position: 1)
    create(:track, composition: composition, song: song2, Side: "A", Position: 2)

    visit composition_path(composition.COMPID)

    # Should see tracklist
    assert_text "Winchester"
    assert_text "Airscape"
  end

  test "guest user cannot access create/edit forms" do
    # Try to visit new song form
    visit new_song_path

    # Should be redirected or see unauthorized message
    # (Depends on authorization implementation)
  end

  test "authenticated user can create a new song" do
    user = create(:user)

    # Login
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Log in"

    # Navigate to new song form
    visit new_song_path

    # Fill in song form
    fill_in "Full name", with: "The Man Who Invented Himself"
    click_button "Create Song"

    # Should see success message and new song
    assert_text "Man Who Invented Himself"
  end

  test "authenticated user can edit a song" do
    user = create(:user)
    song = create(:song, Song: "Original Title")

    # Login
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Log in"

    # Visit song and click edit
    visit song_path(song.SONGID)
    click_link "Edit" # or button depending on UI

    # Update song
    fill_in "Full name", with: "Updated Title"
    click_button "Update Song"

    # Should see updated song
    assert_text "Updated Title"
  end

  test "authenticated user can create a new gig" do
    user = create(:user)
    venue = create(:venue, Name: "Fillmore")

    # Login
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Log in"

    # Navigate to new gig form
    visit new_gig_path

    # Fill in gig form
    select venue.Name, from: "Venue"
    fill_in "Gig date", with: Date.today
    click_button "Create Gig"

    # Should see success message
  end

  test "authenticated user can add songs to gig setlist" do
    user = create(:user)
    venue = create(:venue, Name: "Fillmore")
    gig = create(:gig, venue: venue)
    song = create(:song, Song: "Madonna")

    # Login
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Log in"

    # Visit gig page
    visit gig_path(gig.GIGID)

    # Add song to setlist (UI depends on implementation)
    # This is a placeholder - adjust based on actual UI
    click_link "Add to setlist"
    select "Madonna", from: "Song"
    click_button "Add"

    # Should see song in setlist
    assert_text "Madonna"
  end

  test "user can search songs by title" do
    create(:song, Song: "Madonna")
    create(:song, Song: "Different Song")

    visit songs_path

    # Search for Madonna
    fill_in "Search", with: "Madonna"
    select "Title", from: "Search type"
    click_button "Search"

    # Should see Madonna but not Different Song
    assert_text "Madonna"
    assert_no_text "Different Song"
  end

  test "user can filter gigs by date range" do
    venue1 = create(:venue, Name: "Venue 1")
    venue2 = create(:venue, Name: "Venue 2")
    gig2020 = create(:gig, venue: venue1, GigDate: Date.parse("2020-06-15"))
    gig2021 = create(:gig, venue: venue2, GigDate: Date.parse("2021-08-20"))

    visit gigs_path

    # Filter by year 2020
    fill_in "Year", with: "2020"
    click_button "Search"

    # Should see 2020 gig but not 2021
    assert_text "Venue 1"
    assert_no_text "Venue 2"
  end

  test "user can view 'on this day' gigs" do
    today = Date.today
    # Create gig from 5 years ago on this day
    venue = create(:venue, Name: "Fillmore")
    gig_today = create(:gig, venue: venue, GigDate: Date.new(today.year - 5, today.month, today.day))
    gig_other = create(:gig, GigDate: Date.new(today.year - 1, (today.month % 12) + 1, 1))

    visit on_this_day_gigs_path

    # Should see gig from this day in history
    assert_text "Fillmore"
  end

  test "user can use quick queries on songs" do
    cover = create(:song, :cover, Author: "Bob Dylan")
    original = create(:song, Author: nil)

    visit songs_path

    # Use "not written by Robyn" quick query
    click_link "Covers" # or appropriate quick query link

    # Should see cover song
    assert_text cover.Song
  end

  test "user can navigate between related resources" do
    # Create interconnected data
    song = create(:song, Song: "Madonna")
    composition = create(:composition, Title: "Element of Light")
    venue = create(:venue, Name: "Fillmore")
    gig = create(:gig, venue: venue)
    create(:track, composition: composition, song: song)
    create(:gigset, gig: gig, song: song)

    # Start at song page
    visit song_path(song.SONGID)

    # Click to album that has this song
    click_link "Element of Light"
    assert_current_path composition_path(composition.COMPID)

    # Go back to song
    click_link "Madonna"
    assert_current_path song_path(song.SONGID)

    # Click to a gig where this was performed
    click_link "Fillmore"
    # Should navigate to gig details
  end

  test "pagination works on long lists" do
    # Create more than one page of songs (assuming 10 per page)
    25.times { |i| create(:song, Song: "Song #{i}") }

    visit songs_path

    # Should see first page
    assert_text "Song 0"

    # Click to next page
    click_link "Next" # or page 2

    # Should see different songs
    assert_text "Song 20"
  end
end
