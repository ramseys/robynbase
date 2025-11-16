require 'test_helper'

class SongTest < ActiveSupport::TestCase
  # Associations
  test "should have many gigsets" do
    song = create(:song)
    gigset1 = create(:gigset, song: song)
    gigset2 = create(:gigset, song: song)

    assert_includes song.gigsets, gigset1
    assert_includes song.gigsets, gigset2
    assert_equal 2, song.gigsets.count
  end

  test "should have many gigs through gigsets" do
    song = create(:song)
    gig1 = create(:gig)
    gig2 = create(:gig)
    create(:gigset, song: song, gig: gig1)
    create(:gigset, song: song, gig: gig2)

    assert_includes song.gigs, gig1
    assert_includes song.gigs, gig2
    assert_equal 2, song.gigs.count
  end

  test "should have many tracks" do
    song = create(:song)
    track1 = create(:track, song: song)
    track2 = create(:track, song: song)

    assert_includes song.tracks, track1
    assert_includes song.tracks, track2
    assert_equal 2, song.tracks.count
  end

  test "should have many compositions through tracks" do
    song = create(:song)
    comp1 = create(:composition)
    comp2 = create(:composition)
    create(:track, song: song, composition: comp1)
    create(:track, song: song, composition: comp2)

    assert_includes song.compositions, comp1
    assert_includes song.compositions, comp2
    assert_equal 2, song.compositions.count
  end

  # Search functionality
  test "search_by should find songs by title" do
    song = create(:song, Song: "Madonna")
    create(:song, Song: "Different Song")

    results = Song.search_by([:title], "Madonna")
    assert_includes results, song
    assert_equal 1, results.count
  end

  test "search_by should find songs by partial title match" do
    song1 = create(:song, Song: "Kingdom of Love")
    song2 = create(:song, Song: "Love Poisoning")
    create(:song, Song: "Different Song")

    results = Song.search_by([:title], "Love")
    assert_includes results, song1
    assert_includes results, song2
    assert_equal 2, results.count
  end

  test "search_by should find songs by lyrics" do
    song = create(:song, Song: "Test Song", Lyrics: "Beautiful words in the lyrics")
    create(:song, Song: "Other Song", Lyrics: "Different content")

    results = Song.search_by([:lyrics], "Beautiful")
    assert_includes results, song
    assert_equal 1, results.count
  end

  test "search_by should find songs by author" do
    cover = create(:song, Song: "Cover Song", Author: "The Beatles")
    create(:song, Song: "Original", Author: nil)

    results = Song.search_by([:author], "Beatles")
    assert_includes results, cover
    assert_equal 1, results.count
  end

  test "search_by should search multiple fields" do
    song1 = create(:song, Song: "Test Title")
    song2 = create(:song, Song: "Other", Lyrics: "Test in lyrics")
    song3 = create(:song, Song: "Another", Author: "Test Author")

    results = Song.search_by([:title, :lyrics, :author], "Test")
    assert_includes results, song1
    assert_includes results, song2
    assert_includes results, song3
    assert_equal 3, results.count
  end

  test "search_by should return all songs when search is nil" do
    create(:song)
    create(:song)
    create(:song)

    results = Song.search_by([:title], nil)
    assert_equal 3, results.count
  end

  test "search_by should be case insensitive" do
    song = create(:song, Song: "Madonna")

    results = Song.search_by([:title], "madonna")
    assert_includes results, song
  end

  # Quick queries
  test "get_songs_not_written_by_robyn should return only covers" do
    cover1 = create(:song, Author: "The Beatles")
    cover2 = create(:song, Author: "Bob Dylan")
    original = create(:song, Author: nil)

    results = Song.get_songs_not_written_by_robyn
    assert_includes results, cover1
    assert_includes results, cover2
    assert_not_includes results, original
  end

  test "get_songs_not_written_by_robyn should exclude songs by Hitchcock" do
    cover = create(:song, Author: "The Beatles")
    hitchcock = create(:song, Author: "Robyn Hitchcock")

    results = Song.get_songs_not_written_by_robyn
    assert_includes results, cover
    assert_not_includes results, hitchcock
  end

  test "quick_query_never_released should return songs not on any album" do
    unreleased = create(:song, Song: "Unreleased Song")
    released = create(:song, Song: "Released Song")
    create(:track, song: released)

    results = Song.quick_query_never_released(nil)
    assert_includes results, unreleased
    assert_not_includes results, released
  end

  test "quick_query_never_released with originals should return only originals" do
    unreleased_original = create(:song, Song: "Original", Author: nil)
    unreleased_cover = create(:song, Song: "Cover", Author: "The Beatles")

    results = Song.quick_query_never_released("originals")
    assert_includes results, unreleased_original
    assert_not_includes results, unreleased_cover
  end

  test "quick_query_never_released with covers should return only covers" do
    unreleased_original = create(:song, Song: "Original", Author: nil)
    unreleased_cover = create(:song, Song: "Cover", Author: "The Beatles")

    results = Song.quick_query_never_released("covers")
    assert_includes results, unreleased_cover
    assert_not_includes results, unreleased_original
  end

  test "quick_query_guitar_tabs should return songs with tabs" do
    with_tabs = create(:song, :with_tabs)
    without_tabs = create(:song, Tab: nil)

    results = Song.quick_query_guitar_tabs(nil)
    assert_includes results, with_tabs
    assert_not_includes results, without_tabs
  end

  test "quick_query_guitar_tabs with no_tabs should return songs without tabs" do
    with_tabs = create(:song, :with_tabs)
    without_tabs = create(:song, Tab: nil)

    results = Song.quick_query_guitar_tabs("no_tabs")
    assert_includes results, without_tabs
    assert_not_includes results, with_tabs
  end

  test "quick_query_lyrics should return songs with lyrics" do
    with_lyrics = create(:song, :with_lyrics)
    without_lyrics = create(:song, Lyrics: nil)

    results = Song.quick_query_lyrics(nil)
    assert_includes results, with_lyrics
    assert_not_includes results, without_lyrics
  end

  test "quick_query_lyrics with no_lyrics should return songs without lyrics" do
    with_lyrics = create(:song, :with_lyrics)
    without_lyrics = create(:song, Lyrics: nil)

    results = Song.quick_query_lyrics("no_lyrics")
    assert_includes results, without_lyrics
    assert_not_includes results, with_lyrics
  end

  test "quick_query_improvised should return only improvised songs" do
    improvised = create(:song, :improvised)
    not_improvised = create(:song, Improvised: false)

    results = Song.quick_query_improvised
    assert_includes results, improvised
    assert_not_includes results, not_improvised
  end

  test "quick_query_released_no_live_performances should return songs on albums but never played live" do
    studio_only = create(:song)
    create(:track, song: studio_only)  # On an album
    # No gigsets, so never played live

    played_live = create(:song)
    create(:track, song: played_live)
    create(:gigset, song: played_live)  # Played live

    results = Song.quick_query_released_no_live_performances
    assert_includes results, studio_only
    assert_not_includes results, played_live
  end

  # Instance methods
  test "full_name should return song name without prefix when no prefix" do
    song = create(:song, Song: "Madonna", Prefix: nil)
    assert_equal "Madonna", song.full_name
  end

  test "full_name should return prefix and song name when prefix exists" do
    song = create(:song, Song: "Man Who Invented Himself", Prefix: "The")
    assert_equal "The Man Who Invented Himself", song.full_name
  end

  test "full_name should return empty string for new record" do
    song = Song.new
    assert_equal "", song.full_name
  end

  test "get_comments should format comments with line breaks" do
    song = create(:song, Comments: "Line 1\nLine 2\nLine 3")
    formatted = song.get_comments
    assert_includes formatted, "<br>"
    assert_equal "Line 1<br>Line 2<br>Line 3", formatted
  end

  test "get_comments should handle Windows line endings" do
    song = create(:song, Comments: "Line 1\r\nLine 2\r\nLine 3")
    formatted = song.get_comments
    assert_equal "Line 1<br>Line 2<br>Line 3", formatted
  end

  test "get_comments should return nil when no comments" do
    song = create(:song, Comments: nil)
    assert_nil song.get_comments
  end

  # Performance info tests
  test "performance_info should return total count of performances" do
    song = create(:song)
    gig1 = create(:gig, GigDate: Date.parse("2020-01-01"))
    gig2 = create(:gig, GigDate: Date.parse("2020-06-15"))
    gig3 = create(:gig, GigDate: Date.parse("2021-03-20"))
    create(:gigset, song: song, gig: gig1)
    create(:gigset, song: song, gig: gig2)
    create(:gigset, song: song, gig: gig3)

    info = song.performance_info
    assert_equal 3, info["total"]
  end

  test "performance_info should return first and last performance" do
    song = create(:song)
    gig1 = create(:gig, GigDate: Date.parse("2020-01-01"))
    gig2 = create(:gig, GigDate: Date.parse("2020-06-15"))
    gig3 = create(:gig, GigDate: Date.parse("2021-03-20"))
    create(:gigset, song: song, gig: gig1)
    create(:gigset, song: song, gig: gig2)
    create(:gigset, song: song, gig: gig3)

    info = song.performance_info
    assert_equal gig1, info["first"]
    assert_equal gig3, info["last"]
  end

  test "performance_info should calculate duration between first and last" do
    song = create(:song)
    gig1 = create(:gig, GigDate: Date.parse("2020-01-01"))
    gig2 = create(:gig, GigDate: Date.parse("2021-01-01"))
    create(:gigset, song: song, gig: gig1)
    create(:gigset, song: song, gig: gig2)

    info = song.performance_info
    assert_not_nil info["duration"]
    assert_includes info["duration"], "year"
  end

  test "performance_info should have nil duration for single performance" do
    song = create(:song)
    gig = create(:gig)
    create(:gigset, song: song, gig: gig)

    info = song.performance_info
    assert_nil info["duration"]
  end

  # Class methods
  test "parse_song_name should separate leading article" do
    article, name = Song.parse_song_name("The Man Who Invented Himself")
    assert_equal "The", article
    assert_equal "Man Who Invented Himself", name
  end

  test "parse_song_name should handle 'A' article" do
    article, name = Song.parse_song_name("A Skull A Suitcase And A Long Red Bottle Of Wine")
    assert_equal "A", article
    assert_equal "Skull A Suitcase And A Long Red Bottle Of Wine", name
  end

  test "parse_song_name should handle 'An' article" do
    article, name = Song.parse_song_name("An Ocean Inside A Stone")
    assert_equal "An", article
    assert_equal "Ocean Inside A Stone", name
  end

  test "parse_song_name should handle songs without articles" do
    article, name = Song.parse_song_name("Madonna")
    assert_nil article
    assert_equal "Madonna", name
  end

  test "parse_song_name should be case insensitive for articles" do
    article, name = Song.parse_song_name("the lowercase article")
    assert_equal "the", article
    assert_equal "lowercase article", name
  end

  test "find_full_name should find song by full name with article" do
    song = create(:song, Song: "Man Who Invented Himself", Prefix: "The")
    results = Song.find_full_name("The Man Who Invented Himself")
    assert_includes results, song
  end

  test "find_full_name should find song by name without article" do
    song = create(:song, Song: "Madonna", Prefix: nil)
    results = Song.find_full_name("Madonna")
    assert_includes results, song
  end

  test "make_song_record should create song with separated article" do
    song = Song.make_song_record("The Man Who Invented Himself", "Robyn Hitchcock")
    assert_equal "The", song.Prefix
    assert_equal "Man Who Invented Himself", song.Song
    assert_equal "Robyn Hitchcock", song.Author
  end

  test "make_song_record should create song without article" do
    song = Song.make_song_record("Madonna")
    assert_nil song.Prefix
    assert_equal "Madonna", song.Song
    assert_nil song.Author
  end

  test "make_song_record should not save the record" do
    song = Song.make_song_record("Test Song")
    assert song.new_record?
  end

  # Edge cases
  test "should handle songs with no performances" do
    song = create(:song)
    info = song.performance_info

    assert_equal 0, info["total"]
    assert_nil info["first"]
    assert_nil info["last"]
    assert_nil info["duration"]
  end

  test "should handle songs with very long titles" do
    # Song column is VARCHAR(255), test with 200 chars
    long_title = "A" * 200
    song = create(:song, Song: long_title)
    assert_equal long_title, song.Song
  end

  test "search should handle special SQL characters" do
    song = create(:song, Song: "Song with 'quotes' and %wildcards%")
    # Should not cause SQL errors
    results = Song.search_by([:title], "quotes")
    assert_includes results, song
  end
end
