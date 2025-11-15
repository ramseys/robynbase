require 'test_helper'

class SongBrowsingTest < ActionDispatch::IntegrationTest
  test "user can browse and search songs" do
    # Create test data
    song1 = create(:song, Song: "Madonna")
    song2 = create(:song, Song: "Kingdom of Love")
    song3 = create(:song, Song: "Different Song")

    # Visit songs index
    get songs_path
    assert_response :success

    # Perform search
    get songs_path, params: { search_type: "title", search_value: "Madonna" }
    assert_response :success
    assert_match /Madonna/, response.body

    # View song details
    get song_path(song1.SONGID)
    assert_response :success
    assert_match /Madonna/, response.body
  end

  test "user can use quick queries" do
    cover = create(:song, :cover, Author: "The Beatles")
    original = create(:song, Author: nil)

    # Use not_written_by_robyn query
    get quick_query_songs_path, params: { query_id: "not_written_by_robyn" }
    assert_response :success
  end

  test "user can view song performance history" do
    song = create(:song)
    gig1 = create(:gig, GigDate: Date.parse("2020-01-01"))
    gig2 = create(:gig, GigDate: Date.parse("2021-06-15"))
    create(:gigset, song: song, gig: gig1)
    create(:gigset, song: song, gig: gig2)

    get song_path(song.SONGID)
    assert_response :success
  end

  test "authenticated user can create and edit songs" do
    user = create(:user)

    # Login
    post sessions_path, params: { email: user.email, password: "password123" }
    assert_redirected_to root_url
    follow_redirect!

    # Create song
    get new_song_path
    assert_response :success

    post songs_path, params: {
      song: { full_name: "The Man Who Invented Himself" }
    }

    song = Song.last
    assert_equal "The", song.Prefix
    assert_equal "Man Who Invented Himself", song.Song

    # Edit song
    get edit_song_path(song.SONGID)
    assert_response :success

    patch song_path(song.SONGID), params: {
      song: { full_name: "Updated Song Title" }
    }

    song.reload
    assert_equal "Updated Song Title", song.Song
  end
end
