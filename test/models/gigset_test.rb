require 'test_helper'

class GigsetTest < ActiveSupport::TestCase
  # Associations
  test "should belong to gig" do
    gig = create(:gig)
    gigset = create(:gigset, gig: gig)

    assert_equal gig, gigset.gig
  end

  test "should belong to song" do
    song = create(:song)
    gigset = create(:gigset, song: song)

    assert_equal song, gigset.song
  end

  test "song association should be optional" do
    gigset = build(:gigset, song: nil)
    assert gigset.valid? || gigset.save
  end

  # Attributes
  test "should have Chrono attribute for ordering" do
    gigset = create(:gigset, Chrono: 5)
    assert_equal 5, gigset.Chrono
  end

  test "should have Encore attribute" do
    gigset = create(:gigset, :encore)
    assert gigset.Encore
  end

  test "should have Soundcheck attribute" do
    gigset = create(:gigset, :soundcheck)
    assert gigset.Soundcheck
  end

  test "should have Segue attribute" do
    gigset = create(:gigset, :segue)
    assert gigset.Segue
  end

  test "should have VersionNotes attribute" do
    gigset = create(:gigset, :with_version_notes)
    assert_not_nil gigset.VersionNotes
  end

  test "should have MediaLink attribute" do
    gigset = create(:gigset, MediaLink: "https://youtube.com/watch?v=test")
    assert_equal "https://youtube.com/watch?v=test", gigset.MediaLink
  end

  # Behavioral tests
  test "should create setlist item linking gig and song" do
    gig = create(:gig)
    song = create(:song)
    gigset = create(:gigset, gig: gig, song: song)

    assert_includes gig.gigsets, gigset
    assert_includes song.gigsets, gigset
  end

  test "should allow multiple songs in same gig" do
    gig = create(:gig)
    song1 = create(:song)
    song2 = create(:song)

    gigset1 = create(:gigset, gig: gig, song: song1, Chrono: 1)
    gigset2 = create(:gigset, gig: gig, song: song2, Chrono: 2)

    assert_equal 2, gig.gigsets.count
  end

  test "should allow same song at different gigs" do
    gig1 = create(:gig)
    gig2 = create(:gig)
    song = create(:song)

    gigset1 = create(:gigset, gig: gig1, song: song)
    gigset2 = create(:gigset, gig: gig2, song: song)

    assert_equal 2, song.gigsets.count
  end

  test "encore songs should be distinguishable from regular set" do
    gig = create(:gig)
    regular = create(:gigset, gig: gig, Encore: false)
    encore = create(:gigset, gig: gig, Encore: true)

    assert_not regular.Encore
    assert encore.Encore
  end

  test "should handle setlist with specific ordering" do
    gig = create(:gig)
    song1 = create(:gigset, gig: gig, Chrono: 10)
    song2 = create(:gigset, gig: gig, Chrono: 5)
    song3 = create(:gigset, gig: gig, Chrono: 15)

    ordered = gig.gigsets.order(:Chrono).to_a
    assert_equal [song2, song1, song3], ordered
  end

  test "should support version notes for different arrangements" do
    gigset = create(:gigset, VersionNotes: "acoustic version")
    assert_equal "acoustic version", gigset.VersionNotes
  end

  test "should support media links for individual songs" do
    gigset = create(:gigset, MediaLink: "https://archive.org/details/test")
    assert_not_nil gigset.MediaLink
  end

  test "should support soundcheck performances" do
    gig = create(:gig)
    soundcheck = create(:gigset, gig: gig, Soundcheck: true)
    regular = create(:gigset, gig: gig, Soundcheck: false)

    assert soundcheck.Soundcheck
    assert_not regular.Soundcheck
  end

  test "should support segue notation between songs" do
    gigset = create(:gigset, Segue: true)
    assert gigset.Segue
  end

  # Edge cases
  test "should allow gigsets without songs for unlisted performances" do
    gigset = build(:gigset, song: nil, Song: "Unlisted Improvisation")
    assert gigset.save || gigset.valid?
  end

  test "should handle flaw notation" do
    gigset = create(:gigset, Flaw: "tape cut")
    assert_equal "tape cut", gigset.Flaw
  end
end
