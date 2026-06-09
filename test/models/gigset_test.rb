require 'test_helper'

class GigsetTest < ActiveSupport::TestCase

  test "gigset with a song id is valid" do
    gigset = Gigset.new(GIGID: 1, SONGID: 1, Song: "Madonna of the Wasps", Chrono: 10, Encore: false)
    assert gigset.valid?
  end

  test "gigset without a song id is valid when a song name is present" do
    gigset = Gigset.new(GIGID: 1, Song: "Unknown Improvisation", Chrono: 10, Encore: false)
    assert gigset.valid?
  end

  test "gigset without a song id and without a song name is invalid" do
    gigset = Gigset.new(GIGID: 1, Chrono: 10, Encore: false)
    assert_not gigset.valid?
  end

end
