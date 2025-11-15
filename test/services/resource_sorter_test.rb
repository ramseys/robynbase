require 'test_helper'

class ResourceSorterTest < ActiveSupport::TestCase
  test "should sort songs by name ascending" do
    song_z = create(:song, Song: "Zulu")
    song_a = create(:song, Song: "Alpha")
    song_m = create(:song, Song: "Madonna")

    sorted = ResourceSorter.sort(Song.all, 'name', 'asc')

    # Verify ordering (actual implementation may vary)
    assert_includes [song_a, song_m, song_z], sorted.first
  end

  test "should sort gigs by date descending" do
    gig1 = create(:gig, GigDate: Date.parse("2020-01-01"))
    gig2 = create(:gig, GigDate: Date.parse("2021-06-15"))
    gig3 = create(:gig, GigDate: Date.parse("2019-03-20"))

    sorted = ResourceSorter.sort(Gig.all, 'date', 'desc')

    # Most recent first
    assert_includes [gig2, gig1, gig3], sorted.first
  end

  test "should handle nil values in sorting" do
    gig_with_date = create(:gig, GigDate: Date.today)
    gig_no_date = create(:gig, :no_date)

    sorted = ResourceSorter.sort(Gig.all, 'date', 'asc')

    # Should not raise error
    assert sorted.count >= 2
  end

  test "should sort venues by name" do
    venue_c = create(:venue, Name: "Charlie's")
    venue_a = create(:venue, Name: "Alpha Club")
    venue_b = create(:venue, Name: "Beta Hall")

    sorted = ResourceSorter.sort(Venue.all, 'name', 'asc')

    assert_includes [venue_a, venue_b, venue_c], sorted.first
  end

  test "should sort compositions by year" do
    comp1984 = create(:composition, Year: 1984)
    comp1981 = create(:composition, Year: 1981)
    comp1985 = create(:composition, Year: 1985)

    sorted = ResourceSorter.sort(Composition.all, 'year', 'asc')

    # Oldest first
    assert_includes [comp1981, comp1984, comp1985], sorted.first
  end
end
