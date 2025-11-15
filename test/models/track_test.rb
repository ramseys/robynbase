require 'test_helper'

class TrackTest < ActiveSupport::TestCase
  # Associations
  test "should belong to composition" do
    comp = create(:composition)
    track = create(:track, composition: comp)

    assert_equal comp, track.composition
  end

  test "should belong to song" do
    song = create(:song)
    track = create(:track, song: song)

    assert_equal song, track.song
  end

  test "song association should be optional" do
    track = build(:track, song: nil)
    assert track.valid? || track.save
  end

  # Attributes
  test "should have Seq attribute for track number" do
    track = create(:track, Seq: 5)
    assert_equal 5, track.Seq
  end

  test "should have Disc attribute for multi-disc albums" do
    track = create(:track, Disc: 2)
    assert_equal 2, track.Disc
  end

  test "should have Time attribute for track duration" do
    track = create(:track, Time: "3:45")
    assert_equal "3:45", track.Time
  end

  test "should have bonus attribute for bonus tracks" do
    track = create(:track, :bonus)
    assert track.bonus
  end

  test "should have Hidden attribute" do
    track = create(:track, :hidden)
    assert track.Hidden
  end

  test "should have VersionNotes attribute" do
    track = create(:track, :with_version_notes)
    assert_not_nil track.VersionNotes
  end

  test "should have Side attribute for vinyl records" do
    track = create(:track, Side: "A")
    assert_equal "A", track.Side
  end

  # Behavioral tests
  test "should create track linking composition and song" do
    comp = create(:composition)
    song = create(:song)
    track = create(:track, composition: comp, song: song)

    assert_includes comp.tracks, track
    assert_includes song.tracks, track
  end

  test "should allow multiple tracks in same composition" do
    comp = create(:composition)
    song1 = create(:song)
    song2 = create(:song)

    track1 = create(:track, composition: comp, song: song1, Seq: 1)
    track2 = create(:track, composition: comp, song: song2, Seq: 2)

    assert_equal 2, comp.tracks.count
  end

  test "should allow same song on different albums" do
    comp1 = create(:composition)
    comp2 = create(:composition)
    song = create(:song)

    track1 = create(:track, composition: comp1, song: song)
    track2 = create(:track, composition: comp2, song: song)

    assert_equal 2, song.tracks.count
  end

  test "should order tracks by Seq within composition" do
    comp = create(:composition)
    track3 = create(:track, composition: comp, Seq: 3)
    track1 = create(:track, composition: comp, Seq: 1)
    track2 = create(:track, composition: comp, Seq: 2)

    ordered = comp.tracks.to_a
    assert_equal [track1, track2, track3], ordered
  end

  test "bonus tracks should be distinguishable from regular tracks" do
    comp = create(:composition)
    regular = create(:track, composition: comp, bonus: false)
    bonus = create(:track, composition: comp, bonus: true)

    assert_not regular.bonus
    assert bonus.bonus
  end

  test "should support multi-disc albums" do
    comp = create(:composition)
    disc1_track1 = create(:track, composition: comp, Disc: 1, Seq: 1)
    disc1_track2 = create(:track, composition: comp, Disc: 1, Seq: 2)
    disc2_track1 = create(:track, composition: comp, Disc: 2, Seq: 1)
    disc2_track2 = create(:track, composition: comp, Disc: 2, Seq: 2)

    assert_equal 4, comp.tracks.count
    assert_equal 1, disc1_track1.Disc
    assert_equal 2, disc2_track1.Disc
  end

  test "should support vinyl sides" do
    comp = create(:composition)
    side_a = create(:track, composition: comp, Side: "A", Seq: 1)
    side_b = create(:track, composition: comp, Side: "B", Seq: 1)

    assert_equal "A", side_a.Side
    assert_equal "B", side_b.Side
  end

  test "should support hidden tracks" do
    comp = create(:composition)
    visible = create(:track, composition: comp, Hidden: false)
    hidden = create(:track, composition: comp, Hidden: true)

    assert_not visible.Hidden
    assert hidden.Hidden
  end

  test "should support track duration" do
    track = create(:track, Time: "4:23")
    assert_equal "4:23", track.Time
  end

  test "should support various track duration formats" do
    formats = ["3:45", "10:23", "1:05", "23:15"]
    formats.each do |duration|
      track = create(:track, Time: duration)
      assert_equal duration, track.Time
    end
  end

  test "should support version notes for different takes" do
    track = create(:track, VersionNotes: "demo version")
    assert_equal "demo version", track.VersionNotes
  end

  # Edge cases
  test "should allow tracks without songs for unlisted tracks" do
    track = build(:track, song: nil, Song: "Unlisted Instrumental")
    assert track.save || track.valid?
  end

  test "should handle very long track lists" do
    comp = create(:composition)
    30.times do |i|
      create(:track, composition: comp, Seq: i + 1)
    end

    assert_equal 30, comp.tracks.count
  end

  test "should handle compilation albums with varied artists" do
    comp = create(:composition, :compilation)
    song1 = create(:song, Author: nil)  # Robyn
    song2 = create(:song, Author: "Other Artist")

    track1 = create(:track, composition: comp, song: song1)
    track2 = create(:track, composition: comp, song: song2)

    assert_equal 2, comp.tracks.count
  end

  test "should handle tracks with multiple discs and bonus content" do
    comp = create(:composition)

    # Regular disc 1
    create(:track, composition: comp, Disc: 1, Seq: 1, bonus: false)
    create(:track, composition: comp, Disc: 1, Seq: 2, bonus: false)

    # Regular disc 2
    create(:track, composition: comp, Disc: 2, Seq: 1, bonus: false)

    # Bonus tracks
    create(:track, composition: comp, Disc: 2, Seq: 2, bonus: true)
    create(:track, composition: comp, Disc: 2, Seq: 3, bonus: true)

    assert_equal 5, comp.tracks.count
    assert_equal 3, comp.get_tracklist.count
    assert_equal 2, comp.get_tracklist_bonus.count
  end
end
