require 'test_helper'

class TrackTest < ActiveSupport::TestCase

  test "track with a song id is valid" do
    track = Track.new(COMPID: 1, SONGID: 1, Song: "Madonna of the Wasps", Seq: 10, bonus: false)
    assert track.valid?
  end

  test "track without a song id is valid when a song name is present" do
    track = Track.new(COMPID: 1, Song: "Unknown Track", Seq: 10, bonus: false)
    assert track.valid?
  end

  test "track without a song id and without a song name is invalid" do
    track = Track.new(COMPID: 1, Seq: 10, bonus: false)
    assert_not track.valid?
  end

end
