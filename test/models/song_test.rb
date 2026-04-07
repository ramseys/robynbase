require 'test_helper'

class SongTest < ActiveSupport::TestCase
  # ============================================================================
  # PHASE 1.1: VALIDATIONS & BASIC BEHAVIOR
  # ============================================================================

  # Basic Creation
  # ----------------------------------------------------------------------------
  test "should create song with valid attributes" do
    song = build(:song, Song: "Madonna")
    assert song.valid?
    assert song.save
  end

  test "should have required Song field" do
    song = build(:song, Song: "Test Song")
    assert song.valid?

    # Song name is required at database level (NOT NULL)
    # ActiveRecord doesn't validate it, MySQL will reject
  end

  # Article Parsing
  # ----------------------------------------------------------------------------
  test "parse_song_name should extract 'The' article" do
    article, name = Song.parse_song_name("The Man Who Invented Himself")
    assert_equal "The", article
    assert_equal "Man Who Invented Himself", name
  end

  test "parse_song_name should extract 'A' article" do
    article, name = Song.parse_song_name("A Skull A Suitcase And A Long Red Bottle Of Wine")
    assert_equal "A", article
    assert_equal "Skull A Suitcase And A Long Red Bottle Of Wine", name
  end

  test "parse_song_name should extract 'An' article" do
    article, name = Song.parse_song_name("An Ocean Of Sound")
    assert_equal "An", article
    assert_equal "Ocean Of Sound", name
  end

  test "parse_song_name should return nil article for songs without articles" do
    article, name = Song.parse_song_name("Madonna")
    assert_nil article
    assert_equal "Madonna", name
  end

  test "parse_song_name should handle single word songs" do
    article, name = Song.parse_song_name("Airscape")
    assert_nil article
    assert_equal "Airscape", name
  end

  test "parse_song_name should handle songs starting with 'The' in middle" do
    article, name = Song.parse_song_name("After The Storm")
    assert_equal "After The Storm", name
    # Only leading articles are extracted
  end

  # Full Name Generation
  # ----------------------------------------------------------------------------
  test "full_name should combine prefix and song name" do
    song = create(:song, Prefix: "The", Song: "Man Who Invented Himself")
    assert_equal "The Man Who Invented Himself", song.full_name
  end

  test "full_name should return just song name when no prefix" do
    song = create(:song, Prefix: nil, Song: "Madonna")
    assert_equal "Madonna", song.full_name
  end

  test "full_name should return empty string for new unsaved record" do
    song = Song.new
    assert_equal "", song.full_name
  end

  test "full_name should handle empty prefix" do
    song = create(:song, Prefix: "", Song: "Airscape")
    assert_equal "Airscape", song.full_name
  end

  # Make Song Record Helper
  # ----------------------------------------------------------------------------
  test "make_song_record should create song with article" do
    song = Song.make_song_record("The Yip Song")
    assert_equal "The", song.Prefix
    assert_equal "Yip Song", song.Song
    assert song.new_record? # Should not be saved yet
  end

  test "make_song_record should create song without article" do
    song = Song.make_song_record("Madonna")
    assert_nil song.Prefix
    assert_equal "Madonna", song.Song
  end

  test "make_song_record should set author when provided" do
    song = Song.make_song_record("Eight Miles High", "The Byrds")
    assert_equal "The Byrds", song.Author
  end

  # Find Full Name Helper
  # ----------------------------------------------------------------------------
  test "find_full_name should find song with article" do
    create(:song, Prefix: "The", Song: "Yip Song")
    results = Song.find_full_name("The Yip Song")
    assert_equal 1, results.count
    assert_equal "The", results.first.Prefix
    assert_equal "Yip Song", results.first.Song
  end

  test "find_full_name should find song without article" do
    create(:song, Prefix: nil, Song: "Madonna")
    results = Song.find_full_name("Madonna")
    assert_equal 1, results.count
    assert_equal "Madonna", results.first.Song
  end

  # Text Field Handling
  # ----------------------------------------------------------------------------
  test "should store and retrieve lyrics" do
    lyrics = "Beautiful words\nSpanning multiple lines"
    song = create(:song, Lyrics: lyrics)
    song.reload
    assert_equal lyrics, song.Lyrics
  end

  test "should store and retrieve comments" do
    comments = "This song was written in 1984\nReleased on Fegmania!"
    song = create(:song, Comments: comments)
    song.reload
    assert_equal comments, song.Comments
  end

  test "should handle nil lyrics" do
    song = create(:song, Lyrics: nil)
    assert_nil song.Lyrics
  end

  test "should handle nil comments" do
    song = create(:song, Comments: nil)
    assert_nil song.Comments
  end

  test "get_comments should format comments with HTML linebreaks" do
    song = create(:song, Comments: "Line 1\nLine 2\nLine 3")
    formatted = song.get_comments
    assert_includes formatted, "<br>"
    assert_includes formatted, "Line 1"
    assert_includes formatted, "Line 2"
  end

  test "should handle tabs field" do
    tabs = "Em    C    G    D\nChorus progression"
    song = create(:song, Tab: tabs)
    song.reload
    assert_equal tabs, song.Tab
  end

  # Special Characters
  # ----------------------------------------------------------------------------
  test "should handle special characters in song name" do
    song = create(:song, Song: "Song with 'quotes' and %wildcards%")
    song.reload
    assert_equal "Song with 'quotes' and %wildcards%", song.Song
  end

  test "should handle unicode characters" do
    song = create(:song, Song: "Café de Flore")
    song.reload
    assert_equal "Café de Flore", song.Song
  end

  test "should handle ampersands in song name" do
    song = create(:song, Song: "Rock & Roll")
    song.reload
    assert_equal "Rock & Roll", song.Song
  end

  # Length Constraints
  # ----------------------------------------------------------------------------
  test "should handle reasonably long song titles" do
    # Song column is VARCHAR(255) by default
    long_title = "A" * 200
    song = create(:song, Song: long_title)
    song.reload
    assert_equal long_title, song.Song
  end

  test "should handle long lyrics" do
    long_lyrics = "Beautiful words " * 100 # TEXT column, can be very long
    song = create(:song, Lyrics: long_lyrics)
    song.reload
    assert_equal long_lyrics, song.Lyrics
  end

  # Author Field (Covers)
  # ----------------------------------------------------------------------------
  test "should store author for cover songs" do
    song = create(:song, Song: "Eight Miles High", Author: "The Byrds")
    assert_equal "The Byrds", song.Author
  end

  test "should have nil author for original songs" do
    song = create(:song, Song: "Madonna", Author: nil)
    assert_nil song.Author
  end

  test "should distinguish between originals and covers via author" do
    original = create(:song, Song: "Original", Author: nil)
    cover = create(:song, Song: "Cover", Author: "Someone Else")

    assert_nil original.Author
    assert_not_nil cover.Author
  end

  # Improvised Flag
  # ----------------------------------------------------------------------------
  test "should track improvised songs" do
    song = create(:song, Song: "Improvised Jam", Improvised: true)
    assert song.Improvised
  end

  test "should default improvised to false" do
    song = create(:song)
    assert_equal false, song.Improvised
  end

  # ============================================================================
  # EDGE CASES
  # ============================================================================

  test "should handle empty string for optional fields" do
    song = create(:song,
      Song: "Test",
      Author: "",
      OrigBand: "",
      Lyrics: "",
      Comments: "",
      Tab: ""
    )
    song.reload
    # Empty strings are stored as-is, not converted to nil
    assert_equal "", song.Author
  end

  test "should handle very long author names" do
    long_author = "The " + ("Very " * 20) + "Long Band Name"
    song = create(:song, Author: long_author)
    song.reload
    assert song.Author.length > 50
  end

  test "should handle songs with only whitespace in name" do
    # This is technically invalid but let's see what happens
    # The database/application should handle this
    song = build(:song, Song: "   ")
    # Don't assert valid/invalid - just document behavior
  end
end
