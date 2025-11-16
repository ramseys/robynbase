require 'test_helper'

class GigMediumTest < ActiveSupport::TestCase
  # Associations
  test "should belong to gig" do
    gig = create(:gig)
    media = create(:gig_medium, gig: gig)

    assert_equal gig, media.gig
  end

  # Media type constants
  test "should have defined media types" do
    assert_not_nil GigMedium::MEDIA_TYPE
    assert GigMedium::MEDIA_TYPE.is_a?(Hash)
  end

  test "should support YouTube media type" do
    assert_equal 1, GigMedium::MEDIA_TYPE["YouTube"]
    media = create(:gig_medium, :youtube)
    assert_equal 1, media.mediatype
  end

  test "should support Archive.org video media type" do
    assert_equal 2, GigMedium::MEDIA_TYPE["ArchiveOrgVideo"]
    media = create(:gig_medium, :archive_org_video)
    assert_equal 2, media.mediatype
  end

  test "should support Archive.org playlist media type" do
    assert_equal 3, GigMedium::MEDIA_TYPE["ArchiveOrgPlaylist"]
    media = create(:gig_medium, mediatype: 3)
    assert_equal 3, media.mediatype
  end

  test "should support Archive.org audio media type" do
    assert_equal 4, GigMedium::MEDIA_TYPE["ArchiveOrgAudio"]
    media = create(:gig_medium, :archive_org_audio)
    assert_equal 4, media.mediatype
  end

  test "should support Vimeo media type" do
    assert_equal 5, GigMedium::MEDIA_TYPE["Vimeo"]
    media = create(:gig_medium, :vimeo)
    assert_equal 5, media.mediatype
  end

  test "should support Soundcloud media type" do
    assert_equal 6, GigMedium::MEDIA_TYPE["Soundcloud"]
    media = create(:gig_medium, :soundcloud)
    assert_equal 6, media.mediatype
  end

  # Attributes
  test "should have title attribute" do
    media = create(:gig_medium, title: "Concert Recording")
    assert_equal "Concert Recording", media.title
  end

  test "should have mediaid attribute" do
    media = create(:gig_medium, mediaid: "abc123xyz")
    assert_equal "abc123xyz", media.mediaid
  end

  test "should have Chrono attribute for ordering" do
    media = create(:gig_medium, Chrono: 5)
    assert_equal 5, media.Chrono
  end

  test "should have showplaylist attribute" do
    media = create(:gig_medium, :with_playlist)
    assert_equal 1, media.showplaylist
  end

  # Behavioral tests
  test "should allow multiple media items for same gig" do
    gig = create(:gig)
    media1 = create(:gig_medium, gig: gig, mediatype: 1)  # YouTube
    media2 = create(:gig_medium, gig: gig, mediatype: 4)  # Archive.org

    assert_equal 2, gig.gigmedia.count
  end

  test "should order media by Chrono" do
    gig = create(:gig)
    media3 = create(:gig_medium, gig: gig, Chrono: 3)
    media1 = create(:gig_medium, gig: gig, Chrono: 1)
    media2 = create(:gig_medium, gig: gig, Chrono: 2)

    ordered = gig.gigmedia.to_a
    assert_equal [media1, media2, media3], ordered
  end

  test "YouTube media should have 11-character mediaid" do
    media = create(:gig_medium, :youtube)
    assert_equal 11, media.mediaid.length
  end

  test "should support various video platforms" do
    gig = create(:gig)
    youtube = create(:gig_medium, :youtube, gig: gig)
    vimeo = create(:gig_medium, :vimeo, gig: gig)
    archive = create(:gig_medium, :archive_org_video, gig: gig)

    assert_equal 3, gig.gigmedia.count
    assert_equal 1, youtube.mediatype
    assert_equal 5, vimeo.mediatype
    assert_equal 2, archive.mediatype
  end

  test "should support audio-only platforms" do
    gig = create(:gig)
    soundcloud = create(:gig_medium, :soundcloud, gig: gig)
    archive_audio = create(:gig_medium, :archive_org_audio, gig: gig)

    assert_equal 2, gig.gigmedia.count
    assert_equal 6, soundcloud.mediatype
    assert_equal 4, archive_audio.mediatype
  end

  # Edge cases
  test "should handle gig with no media" do
    gig = create(:gig)
    assert_equal 0, gig.gigmedia.count
  end

  test "should handle very long titles" do
    long_title = "A Very Long Title " * 20
    media = create(:gig_medium, title: long_title)
    assert_equal long_title, media.title
  end

  test "should handle various mediaid formats" do
    # YouTube style (alphanumeric, 11 chars)
    yt = create(:gig_medium, :youtube)
    assert_not_nil yt.mediaid

    # Vimeo style (numeric)
    vimeo = create(:gig_medium, :vimeo)
    assert_not_nil vimeo.mediaid

    # Archive.org style
    archive = create(:gig_medium, :archive_org_video, mediaid: "RobynHitchcock2020-01-15")
    assert_equal "RobynHitchcock2020-01-15", archive.mediaid
  end

  test "should support playlist display flag" do
    regular = create(:gig_medium, showplaylist: 0)
    with_playlist = create(:gig_medium, showplaylist: 1)

    assert_equal 0, regular.showplaylist
    assert_equal 1, with_playlist.showplaylist
  end

  test "should have timestamps" do
    media = create(:gig_medium)
    assert_not_nil media.created_at
    assert_not_nil media.updated_at
  end

  test "should link media to specific gig" do
    gig1 = create(:gig)
    gig2 = create(:gig)
    media1 = create(:gig_medium, gig: gig1)
    media2 = create(:gig_medium, gig: gig2)

    assert_includes gig1.gigmedia, media1
    assert_not_includes gig1.gigmedia, media2
    assert_includes gig2.gigmedia, media2
    assert_not_includes gig2.gigmedia, media1
  end

  test "should support all defined media types" do
    gig = create(:gig)

    GigMedium::MEDIA_TYPE.each do |name, type_id|
      media = create(:gig_medium, gig: gig, mediatype: type_id, title: name)
      assert_equal type_id, media.mediatype
      assert_equal name, media.title
    end

    assert_equal GigMedium::MEDIA_TYPE.count, gig.gigmedia.count
  end
end
