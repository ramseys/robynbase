require 'test_helper'

class CompositionTest < ActiveSupport::TestCase
  # Associations
  test "should have many tracks" do
    comp = create(:composition)
    track1 = create(:track, composition: comp)
    track2 = create(:track, composition: comp)

    assert_includes comp.tracks, track1
    assert_includes comp.tracks, track2
    assert_equal 2, comp.tracks.count
  end

  test "should have many songs through tracks" do
    comp = create(:composition)
    song1 = create(:song)
    song2 = create(:song)
    create(:track, composition: comp, song: song1)
    create(:track, composition: comp, song: song2)

    assert_includes comp.songs, song1
    assert_includes comp.songs, song2
    assert_equal 2, comp.songs.count
  end

  test "should order tracks by Seq" do
    comp = create(:composition)
    track3 = create(:track, composition: comp, Seq: 3)
    track1 = create(:track, composition: comp, Seq: 1)
    track2 = create(:track, composition: comp, Seq: 2)

    assert_equal [track1, track2, track3], comp.tracks.to_a
  end

  # Instance methods
  test "get_tracklist should return non-bonus tracks" do
    comp = create(:composition)
    regular_track = create(:track, composition: comp, bonus: false)
    bonus_track = create(:track, composition: comp, bonus: true)

    tracklist = comp.get_tracklist

    assert_includes tracklist, regular_track
    assert_not_includes tracklist, bonus_track
  end

  test "get_tracklist_bonus should return only bonus tracks" do
    comp = create(:composition)
    regular_track = create(:track, composition: comp, bonus: false)
    bonus_track = create(:track, composition: comp, bonus: true)

    bonus_tracklist = comp.get_tracklist_bonus

    assert_includes bonus_tracklist, bonus_track
    assert_not_includes bonus_tracklist, regular_track
  end

  # Search functionality
  test "search_by should find compositions by title" do
    comp = create(:composition, Title: "I Often Dream of Trains")
    create(:composition, Title: "Different Album")

    results = Composition.search_by([:title], "Trains")
    assert_includes results, comp
    assert_equal 1, results.count
  end

  test "search_by should find compositions by year" do
    comp1984 = create(:composition, Year: 1984)
    comp1985 = create(:composition, Year: 1985)

    results = Composition.search_by([:year], "1984")
    assert_includes results, comp1984
    assert_not_includes results, comp1985
  end

  test "search_by should find compositions by label" do
    comp = create(:composition, Label: "Midnight Music")
    create(:composition, Label: "Different Label")

    results = Composition.search_by([:label], "Midnight")
    assert_includes results, comp
    assert_equal 1, results.count
  end

  test "search_by should find compositions by artist" do
    robyn = create(:composition, Artist: "Robyn Hitchcock")
    other = create(:composition, Artist: "Other Artist")

    results = Composition.search_by([:artist], "Hitchcock")
    assert_includes results, robyn
    assert_not_includes results, other
  end

  test "search_by should search multiple fields" do
    comp1 = create(:composition, Title: "Test Title")
    comp2 = create(:composition, Year: 2023, Title: "Other")
    comp3 = create(:composition, Label: "Test Label", Title: "Another", Year: 2020)

    results = Composition.search_by([:title, :year, :label], "Test")
    assert_includes results, comp1
    assert_includes results, comp3
    assert_not_includes results, comp2
  end

  test "search_by should return all compositions when search is nil" do
    create(:composition)
    create(:composition)
    create(:composition)

    results = Composition.search_by([:title], nil)
    assert_equal 3, results.count
  end

  test "search_by should filter by release type" do
    album = create(:composition, :album)
    single = create(:composition, :single)
    ep = create(:composition, :ep)

    # Filter for albums only (type 0)
    results = Composition.search_by([:title], nil, [0])
    assert_includes results, album
    assert_not_includes results, single
    assert_not_includes results, ep
  end

  test "search_by should filter by multiple release types" do
    album = create(:composition, :album)
    single = create(:composition, :single)
    ep = create(:composition, :ep)
    compilation = create(:composition, :compilation)

    # Filter for albums (0) and EPs (2)
    results = Composition.search_by([:title], nil, [0, 2])
    assert_includes results, album
    assert_includes results, ep
    assert_not_includes results, single
    assert_not_includes results, compilation
  end

  test "search_by should deduplicate compositions with same title" do
    # Create two editions of the same album
    cd_edition = create(:composition, Title: "I Often Dream of Trains")
    vinyl_edition = create(:composition, Title: "I Often Dream of Trains")

    results = Composition.search_by([:title], "Trains")

    # Should only return one (the one with smaller COMPID)
    assert_equal 1, results.count
    assert_equal [cd_edition, vinyl_edition].min_by(&:COMPID), results.first
  end

  test "search_by should order by year ascending" do
    comp1985 = create(:composition, Year: 1985, Title: "Fegmania!")
    comp1981 = create(:composition, Year: 1981, Title: "Black Snake Diamond Role")
    comp1984 = create(:composition, Year: 1984, Title: "I Often Dream of Trains")

    results = Composition.search_by([:title], nil).to_a

    assert_equal comp1981, results[0]
    assert_equal comp1984, results[1]
    assert_equal comp1985, results[2]
  end

  test "search_by should order by COMPID when years are equal" do
    comp1 = create(:composition, Year: 1984, Title: "Album A")
    comp2 = create(:composition, Year: 1984, Title: "Album B")

    results = Composition.search_by([:title], nil).to_a

    # Should be ordered by COMPID when years match
    assert_equal [comp1, comp2].sort_by(&:COMPID), results
  end

  # Quick queries
  test "quick_query_other_bands should return compositions not by Robyn" do
    robyn = create(:composition, Artist: "Robyn Hitchcock")
    other = create(:composition, Artist: "The Beatles")

    results = Composition.quick_query_other_bands

    assert_includes results, other
    assert_not_includes results, robyn
  end

  test "quick_query_other_bands should exclude variations of Robyn's name" do
    robyn1 = create(:composition, Artist: "Robyn Hitchcock")
    robyn2 = create(:composition, Artist: "Robyn Hitchcock & The Egyptians")
    other = create(:composition, Artist: "The Soft Boys")

    results = Composition.quick_query_other_bands

    assert_includes results, other
    assert_not_includes results, robyn1
    assert_not_includes results, robyn2
  end

  # Release types
  test "should have defined release types" do
    assert_not_nil Composition::RELEASE_TYPES
    assert Composition::RELEASE_TYPES.is_a?(Hash)
    assert_includes Composition::RELEASE_TYPES.keys, 'Album'
    assert_includes Composition::RELEASE_TYPES.keys, 'Single'
    assert_includes Composition::RELEASE_TYPES.keys, 'EP'
  end

  test "should support all release types" do
    Composition::RELEASE_TYPES.each do |type_name, type_value|
      comp = create(:composition, Type: type_name)
      assert_equal type_name, comp.Type
    end
  end

  # Edge cases
  test "should handle compositions with no tracks" do
    comp = create(:composition)
    assert_equal 0, comp.tracks.count
    assert_equal [], comp.get_tracklist.to_a
  end

  test "should handle compositions with many tracks" do
    comp = create(:composition, :with_tracks, tracks_count: 20)
    assert_equal 20, comp.tracks.count
  end

  test "should handle compositions with both regular and bonus tracks" do
    comp = create(:composition)
    create(:track, composition: comp, bonus: false, Seq: 1)
    create(:track, composition: comp, bonus: false, Seq: 2)
    create(:track, composition: comp, bonus: true, Seq: 3)
    create(:track, composition: comp, bonus: true, Seq: 4)

    assert_equal 2, comp.get_tracklist.count
    assert_equal 2, comp.get_tracklist_bonus.count
  end

  test "should handle multi-disc albums" do
    comp = create(:composition)
    create(:track, composition: comp, Disc: 1, Seq: 1)
    create(:track, composition: comp, Disc: 1, Seq: 2)
    create(:track, composition: comp, Disc: 2, Seq: 1)
    create(:track, composition: comp, Disc: 2, Seq: 2)

    assert_equal 4, comp.tracks.count
  end

  test "should handle compositions with very long titles" do
    long_title = "A Very Long Album Title That Goes On And On " * 5
    comp = create(:composition, Title: long_title)
    assert_equal long_title, comp.Title
  end

  test "should handle compositions with special characters in title" do
    comp = create(:composition, Title: "I Often Dream of Trains: In New York")
    results = Composition.search_by([:title], "Trains")
    assert_includes results, comp
  end

  test "should handle compositions from various decades" do
    comp1970s = create(:composition, Year: 1977)
    comp1980s = create(:composition, Year: 1984)
    comp1990s = create(:composition, Year: 1996)
    comp2000s = create(:composition, Year: 2002)
    comp2010s = create(:composition, Year: 2014)
    comp2020s = create(:composition, Year: 2021)

    assert_equal 6, Composition.count
  end

  test "search_by should be case insensitive" do
    comp = create(:composition, Title: "I Often Dream of Trains")

    results = Composition.search_by([:title], "trains")
    assert_includes results, comp
  end

  test "should handle catalog numbers" do
    comp = create(:composition)
    comp.update(CatNo: "FIEND-CD-23")
    assert_equal "FIEND-CD-23", comp.CatNo
  end

  test "should handle comments" do
    comp = create(:composition, :with_comments)
    assert_not_nil comp.Comments
  end

  test "should handle cover images" do
    comp = create(:composition, :with_cover_image)
    assert_not_nil comp.CoverImage
  end

  test "search with release type filter should work with search term" do
    album1 = create(:composition, :album, Title: "Test Album")
    album2 = create(:composition, :album, Title: "Other Album")
    single = create(:composition, :single, Title: "Test Single")

    results = Composition.search_by([:title], "Test", [0])  # Albums only

    assert_includes results, album1
    assert_not_includes results, album2
    assert_not_includes results, single
  end
end
