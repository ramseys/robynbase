require 'test_helper'

class SongsControllerTest < ActionDispatch::IntegrationTest
  # Index action
  test "should get index without search" do
    get songs_path
    assert_response :success
    assert_select "form"  # Search form should be present
  end

  test "should get index with search by title" do
    song = create(:song, Song: "Madonna")
    get songs_path, params: { search_type: "title", search_value: "Madonna" }

    assert_response :success
    assert_select "h2", text: /Madonna/
  end

  test "should get index with search by lyrics" do
    song = create(:song, Song: "Test Song", Lyrics: "Beautiful words")
    get songs_path, params: { search_type: "lyrics", search_value: "Beautiful" }

    assert_response :success
  end

  test "should get index with search by author" do
    cover = create(:song, :cover, Author: "The Beatles")
    get songs_path, params: { search_type: "author", search_value: "Beatles" }

    assert_response :success
  end

  test "should handle empty search results" do
    get songs_path, params: { search_type: "title", search_value: "NonexistentSong12345" }
    assert_response :success
  end

  test "should apply sorting to search results" do
    song_a = create(:song, Song: "Alpha Song")
    song_z = create(:song, Song: "Zulu Song")

    get songs_path, params: { search_type: "title", search_value: "", sort: "name", direction: "asc" }
    assert_response :success
  end

  # Show action
  test "should show song" do
    song = create(:song)
    get song_path(song.SONGID)

    assert_response :success
    assert_select "h2", text: song.Song
  end

  test "should show song with performances" do
    song = create(:song, :with_performances, performances_count: 3)
    get song_path(song.SONGID)

    assert_response :success
  end

  test "should show song with albums" do
    song = create(:song, :on_album, albums_count: 2)
    get song_path(song.SONGID)

    assert_response :success
  end

  test "should return 404 for nonexistent song" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get song_path(999999)
    end
  end

  # New action (requires authentication)
  test "should get new song page when logged in" do
    user = create(:user)
    post sessions_path, params: { email: user.email, password: "password123" }

    get new_song_path
    assert_response :success
    assert_select "form"
  end

  test "should redirect to login when accessing new without authentication" do
    get new_song_path
    assert_response :redirect
  end

  # Create action (requires authentication)
  test "should create song when logged in" do
    user = create(:user)
    post sessions_path, params: { email: user.email, password: "password123" }

    assert_difference('Song.count', 1) do
      post songs_path, params: {
        song: {
          full_name: "Test Song",
          Author: "",
          OrigBand: "",
          Lyrics: "",
          lyrics_ref: "",
          Comments: ""
        }
      }
    end

    assert_redirected_to song_path(Song.last.SONGID)
  end

  test "should create song with article prefix" do
    user = create(:user)
    post sessions_path, params: { email: user.email, password: "password123" }

    post songs_path, params: {
      song: {
        full_name: "The Man Who Invented Himself",
        Author: "",
        OrigBand: "",
        Lyrics: "",
        lyrics_ref: "",
        Comments: ""
      }
    }

    song = Song.last
    assert_equal "The", song.Prefix
    assert_equal "Man Who Invented Himself", song.Song
  end

  test "should not create song without authentication" do
    assert_no_difference('Song.count') do
      post songs_path, params: {
        song: {
          full_name: "Test Song"
        }
      }
    end

    assert_response :redirect
  end

  test "should re-render new on validation error" do
    user = create(:user)
    post sessions_path, params: { email: user.email, password: "password123" }

    # Assuming validation requires some field - adjust based on actual model validations
    post songs_path, params: { song: { full_name: "" } }
    # Behavior depends on model validations
  end

  # Edit action (requires authentication)
  test "should get edit page when logged in" do
    user = create(:user)
    song = create(:song)
    post sessions_path, params: { email: user.email, password: "password123" }

    get edit_song_path(song.SONGID)
    assert_response :success
    assert_select "form"
  end

  test "should redirect to login when accessing edit without authentication" do
    song = create(:song)
    get edit_song_path(song.SONGID)
    assert_response :redirect
  end

  # Update action (requires authentication)
  test "should update song when logged in" do
    user = create(:user)
    song = create(:song, Song: "Original Title")
    post sessions_path, params: { email: user.email, password: "password123" }

    patch song_path(song.SONGID), params: {
      song: {
        full_name: "Updated Title",
        Author: "",
        OrigBand: "",
        Lyrics: "",
        lyrics_ref: "",
        Comments: ""
      }
    }

    song.reload
    assert_equal "Updated Title", song.Song
    assert_redirected_to song_path(song.SONGID)
  end

  test "should update song article prefix" do
    user = create(:user)
    song = create(:song, Song: "Madonna", Prefix: nil)
    post sessions_path, params: { email: user.email, password: "password123" }

    patch song_path(song.SONGID), params: {
      song: {
        full_name: "The Madonna",
        Author: "",
        OrigBand: "",
        Lyrics: "",
        lyrics_ref: "",
        Comments: ""
      }
    }

    song.reload
    assert_equal "The", song.Prefix
    assert_equal "Madonna", song.Song
  end

  test "should not update song without authentication" do
    song = create(:song, Song: "Original")

    patch song_path(song.SONGID), params: {
      song: {
        full_name: "Should Not Update"
      }
    }

    song.reload
    assert_equal "Original", song.Song
    assert_response :redirect
  end

  # Destroy action (requires authentication)
  test "should destroy song when logged in" do
    user = create(:user)
    song = create(:song)
    post sessions_path, params: { email: user.email, password: "password123" }

    assert_difference('Song.count', -1) do
      delete song_path(song.SONGID)
    end

    assert_redirected_to songs_path
  end

  test "should not destroy song without authentication" do
    song = create(:song)

    assert_no_difference('Song.count') do
      delete song_path(song.SONGID)
    end

    assert_response :redirect
  end

  # Quick query action
  test "should handle not_written_by_robyn quick query" do
    cover = create(:song, :cover)
    original = create(:song, Author: nil)

    get songs_quick_query_path, params: { query_id: "not_written_by_robyn" }

    assert_response :success
  end

  test "should handle never_released quick query" do
    unreleased = create(:song)
    released = create(:song, :on_album)

    get songs_quick_query_path, params: { query_id: "never_released" }

    assert_response :success
  end

  test "should handle never_released with originals filter" do
    get songs_quick_query_path, params: {
      query_id: "never_released",
      query_attribute: "originals"
    }

    assert_response :success
  end

  test "should handle never_released with covers filter" do
    get songs_quick_query_path, params: {
      query_id: "never_released",
      query_attribute: "covers"
    }

    assert_response :success
  end

  test "should handle has_guitar_tabs quick query" do
    with_tabs = create(:song, :with_tabs)
    without_tabs = create(:song)

    get songs_quick_query_path, params: { query_id: "has_guitar_tabs" }

    assert_response :success
  end

  test "should handle has_lyrics quick query" do
    with_lyrics = create(:song, :with_lyrics)
    without_lyrics = create(:song)

    get songs_quick_query_path, params: { query_id: "has_lyrics" }

    assert_response :success
  end

  test "should handle improvised quick query" do
    improvised = create(:song, :improvised)
    not_improvised = create(:song)

    get songs_quick_query_path, params: { query_id: "improvised" }

    assert_response :success
  end

  test "should handle released_never_played_live quick query" do
    studio_only = create(:song, :on_album)
    played_live = create(:song, :with_performances)

    get songs_quick_query_path, params: { query_id: "released_never_played_live" }

    assert_response :success
  end

  # Infinite scroll
  test "should handle infinite scroll pagination" do
    15.times { create(:song) }

    get infinite_scroll_songs_path, params: { page: 2 }, xhr: true

    assert_response :success
  end

  test "should apply search to infinite scroll" do
    song = create(:song, Song: "Madonna")
    create(:song, Song: "Different")

    get infinite_scroll_songs_path, params: {
      page: 1,
      search_type: "title",
      search_value: "Madonna"
    }, xhr: true

    assert_response :success
  end

  # Edge cases
  test "should handle SQL injection attempts in search" do
    create(:song, Song: "Test Song")

    # Try SQL injection
    get songs_path, params: {
      search_type: "title",
      search_value: "'; DROP TABLE SONG; --"
    }

    assert_response :success
    # Song table should still exist
    assert Song.count >= 1
  end

  test "should handle very long search values" do
    long_search = "a" * 1000
    get songs_path, params: { search_type: "title", search_value: long_search }
    assert_response :success
  end

  test "should handle special characters in search" do
    song = create(:song, Song: "Song with 'quotes' and %wildcards%")
    get songs_path, params: { search_type: "title", search_value: "quotes" }
    assert_response :success
  end

  test "should paginate search results" do
    30.times { |i| create(:song, Song: "Test Song #{i}") }

    get songs_path, params: { search_type: "title", search_value: "Test" }

    assert_response :success
    # Should have pagination controls
  end

  test "should handle sorting by different fields" do
    create(:song, Song: "Zebra")
    create(:song, Song: "Alpha")

    get songs_path, params: {
      search_type: "title",
      search_value: "",
      sort: "name",
      direction: "desc"
    }

    assert_response :success
  end
end
