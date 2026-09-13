require 'test_helper'

# Unit-level coverage of SearchNavigable, exercised against real controller
# instances (rather than a stub host) so parse/replay run through the app's actual
# routes, params and url_for - which is where this concern's correctness lives.
#
# SONG fixtures give three records in a known order, so first/middle/last positions
# are all distinguishable: sorted by name asc they are Driving Aloud (3),
# Madonna of the Wasps (1), The Cheese Alarm (2).
class SearchNavigableTest < ActiveSupport::TestCase

  SONG_SEARCH = "/songs/index?search_type=all&search_value=&sort=name&direction=asc".freeze

  # --- build_search_nav: positions within the result set ---

  test "middle record offers both prev and next" do
    nav = song_nav(1)

    assert_equal "/songs/3?search_back=#{CGI.escape(SONG_SEARCH)}", nav.prev_path
    assert_equal "/songs/2?search_back=#{CGI.escape(SONG_SEARCH)}", nav.next_path
  end

  test "first record suppresses prev only" do
    nav = song_nav(3)

    assert_nil nav.prev_path
    assert_equal "/songs/1?search_back=#{CGI.escape(SONG_SEARCH)}", nav.next_path
  end

  test "last record suppresses next only" do
    nav = song_nav(2)

    assert_equal "/songs/1?search_back=#{CGI.escape(SONG_SEARCH)}", nav.prev_path
    assert_nil nav.next_path
  end

  test "back path is the search url the listing published" do
    assert_equal SONG_SEARCH, song_nav(1).back_path
  end

  test "sort direction in search_back reverses prev and next" do
    descending = "/songs/index?search_type=all&search_value=&sort=name&direction=desc"
    nav = song_nav(1, search_back: descending)

    assert_equal "/songs/2?search_back=#{CGI.escape(descending)}", nav.prev_path
    assert_equal "/songs/3?search_back=#{CGI.escape(descending)}", nav.next_path
  end

  test "a record no longer matching the search keeps a working back path" do
    # no song is titled "nonexistent", so the replayed result set is empty
    nav = song_nav(1, search_back: "/songs/index?search_type=title&search_value=nonexistent&sort=name&direction=asc")

    assert_not_nil nav
    assert_equal "/songs/index?search_type=title&search_value=nonexistent&sort=name&direction=asc", nav.back_path
    assert_nil nav.prev_path
    assert_nil nav.next_path
  end

  test "quick query results replay through their own branch" do
    nav = song_nav(1, search_back: "/songs/quick_query?query_id=has_lyrics&sort=name&direction=asc")

    assert_not_nil nav
    assert_equal "/songs/quick_query?query_id=has_lyrics&sort=name&direction=asc", nav.back_path
  end

  # --- parse_search_back: rejecting anything untrustworthy ---

  test "no search_back param yields no nav" do
    assert_nil song_nav(1, search_back: nil)
  end

  test "blank search_back yields no nav" do
    assert_nil song_nav(1, search_back: "")
  end

  test "a search_back with a foreign scheme and host is rejected" do
    assert_nil song_nav(1, search_back: "http://evil.example.com/songs/index?search_type=all&search_value=")
  end

  test "a protocol-relative search_back is rejected" do
    assert_nil song_nav(1, search_back: "//evil.example.com/songs/index?search_type=all&search_value=")
  end

  test "a search_back resolving to a different controller is rejected" do
    assert_nil song_nav(1, search_back: "/gigs/index?search_type=venue&search_value=roundhouse")
  end

  test "a search_back pointing at a nonexistent route does not raise" do
    assert_nil song_nav(1, search_back: "/no/such/route?search_type=all")
  end

  test "an unparseable search_back does not raise" do
    assert_nil song_nav(1, search_back: "http://[")
  end

  test "a search_back naming an action with no replay branch is rejected" do
    assert_nil song_nav(1, search_back: "/songs/infinite_scroll?search_type=all&search_value=")
  end

  # --- replaying a search_back that doesn't describe a real search ---

  test "a search_back with no query string still yields a usable back path" do
    nav = song_nav(1, search_back: "/songs/index")

    assert_equal "/songs/index", nav.back_path
    # with no search terms at all every song matches, so the ordering still stands
    assert_equal "/songs/3?search_back=%2Fsongs%2Findex", nav.prev_path
  end

  test "a quick query search_back naming no query id does not raise" do
    nav = song_nav(1, search_back: "/songs/quick_query")

    assert_not_nil nav
    assert_nil nav.prev_path
    assert_nil nav.next_path
  end

  test "a quick query search_back naming an unknown query id does not raise" do
    nav = song_nav(1, search_back: "/songs/quick_query?query_id=no_such_query&sort=name&direction=asc")

    assert_not_nil nav
    assert_nil nav.prev_path
    assert_nil nav.next_path
  end

  # --- DISTINCT collections cannot be replayed ---

  test "ordered_search_ids rejects a DISTINCT collection rather than silently stripping it" do
    controller = controller_for(SongsController, {})

    error = assert_raises(ArgumentError) do
      controller.send(:ordered_search_ids, Song.all.distinct, {},
                      default_sort_params: SongsController::DEFAULT_SORT_PARAMS)
    end

    assert_match(/DISTINCT/, error.message)
  end

  # Guards the precondition the raise above enforces: every quick query on every
  # resource has to come back as one row per record, so search navigation can replay
  # it. A join that fans out belongs in an EXISTS/NOT EXISTS or GROUP BY instead.
  test "no quick query on any resource returns a DISTINCT collection" do
    [Gig, Song, Venue, Composition].each do |model|
      model.get_quick_queries.each do |quick_query|
        attributes = [nil] + Array(quick_query.secondary_queries).map(&:to_s)

        attributes.each do |attribute|
          collection = model.quick_query(quick_query.id.to_s, attribute)

          assert_not collection.distinct_value,
                     "#{model.name}.quick_query(#{quick_query.id.inspect}, #{attribute.inspect}) is DISTINCT"
        end
      end
    end
  end

  # GIG 1 has two GSET rows, so the pre-EXISTS join form yielded it twice
  test "a fan-out quick query replays to one id per record" do
    controller = controller_for(GigsController, {})

    ids = controller.send(:ordered_search_ids,
                          Gig.quick_query("with_setlists", nil), {},
                          default_sort_params: GigsController::DEFAULT_SORT_PARAMS)

    assert_equal [1], ids
  end

  test "a gig quick query replays through build_search_nav" do
    controller = controller_for(GigsController, id: "1", search_back: "/gigs/quick_query?query_id=with_setlists&sort=date&direction=asc")

    nav = controller.send(:build_search_nav, 1,
                          collection_builders: controller.send(:gig_collection_builders),
                          default_sort_params: GigsController::DEFAULT_SORT_PARAMS)

    assert_equal "/gigs/quick_query?query_id=with_setlists&sort=date&direction=asc", nav.back_path
    assert_nil nav.prev_path
    assert_nil nav.next_path
  end

  test "songs never released replays to the songs with no tracks" do
    controller = controller_for(SongsController, {})

    ids = controller.send(:ordered_search_ids,
                          Song.quick_query("never_released", nil), {},
                          default_sort_params: SongsController::DEFAULT_SORT_PARAMS)

    assert_equal [3], ids
  end

  # --- a partly specified sort resolves the same way on both sides ---
  #
  # Gigs default to date/desc, so a search_back naming only half the sort pair is where
  # the listing and the replay would part company if they resolved defaults separately:
  # the listing takes the defaults whole or not at all, and reads a blank direction as
  # ascending rather than borrowing a default that belongs to another column.

  test "a search_back naming a sort but no direction orders the way the listing did" do
    # a venue the sort can tell apart from the two Roundhouse fixtures
    Gig.create!(VENUEID: 1, Venue: "Abbey Road", GigDate: "2022-01-01 20:00:00",
                GigYear: "2022", BilledAs: "Robyn Hitchcock", GigType: "Concert")

    back = "/gigs/index?search_type=venue&search_value=&sort=venue"

    assert_equal listing_ids(back), replayed_ids(back)
  end

  test "a search_back naming a direction but no sort orders the way the listing did" do
    back = "/gigs/index?search_type=venue&search_value=&direction=asc"

    assert_equal listing_ids(back), replayed_ids(back)
  end

  # --- build_search_back_url: what the listings publish ---

  test "build_search_back_url captures the resolved sort alongside the search params" do
    controller = controller_for(SongsController, search_type: "title", search_value: "wasps", sort: "name", direction: "asc")

    url = controller.send(:build_search_back_url, "/songs/index", SongsController::SEARCH_BACK_INDEX_PARAMS)

    assert_equal "/songs/index?direction=asc&search_type=title&search_value=wasps&sort=name", url
  end

  test "build_search_back_url drops blank params" do
    controller = controller_for(SongsController, search_type: "all", search_value: "", sort: "name", direction: "asc")

    url = controller.send(:build_search_back_url, "/songs/index", SongsController::SEARCH_BACK_INDEX_PARAMS)

    assert_equal "/songs/index?direction=asc&search_type=all&sort=name", url
  end

  test "build_search_back_url round-trips a gig date search" do
    controller = controller_for(GigsController,
                                search_type: "venue", search_value: "roundhouse",
                                gig_date: "2023-06-01", gig_range: "6", gig_range_type: "1",
                                sort: "date", direction: "desc")

    url = controller.send(:build_search_back_url, "/gigs/index", GigsController::SEARCH_BACK_INDEX_PARAMS)
    replayed = Rack::Utils.parse_nested_query(url.split("?").last)

    assert_equal "2023-06-01", replayed["gig_date"]
    assert_equal "6", replayed["gig_range"]
    assert_equal "desc", replayed["direction"]
  end

  test "build_search_back_url round-trips a release type array" do
    controller = controller_for(CompositionsController, search_type: "all", release_type: ["1", "2"], sort: "year", direction: "asc")

    url = controller.send(:build_search_back_url, "/compositions/index", CompositionsController::SEARCH_BACK_INDEX_PARAMS)
    replayed = Rack::Utils.parse_nested_query(url.split("?").last)

    assert_equal ["1", "2"], replayed["release_type"]
  end

  private

    # Nav for a song's show page, as SongsController#show would build it
    def song_nav(song_id, search_back: SONG_SEARCH)
      controller = controller_for(SongsController, id: song_id.to_s, search_back: search_back)

      controller.send(:build_search_nav, song_id,
                      collection_builders: controller.send(:song_collection_builders),
                      default_sort_params: SongsController::DEFAULT_SORT_PARAMS)
    end

    # The ordered ids GigsController#index renders for a URL, through the real listing
    # path rather than a re-statement of it
    def listing_ids(url)
      controller = controller_for(GigsController, Rack::Utils.parse_nested_query(url.split("?").last))
      collection = controller.send(:build_gig_search_collection, controller.params)

      _pagy, records = controller.send(:apply_sorting_and_pagination, collection,
                                       default_sort_params: GigsController::DEFAULT_SORT_PARAMS)

      records.map(&:id)
    end

    # The ordered ids a show page recovers from that same URL as its search_back
    def replayed_ids(url)
      controller = controller_for(GigsController, "search_back" => url)
      search = controller.send(:parse_search_back)
      collection = controller.send(:gig_collection_builders)[search[:action]].call(search[:params])

      controller.send(:ordered_search_ids, collection, search[:params],
                      default_sort_params: GigsController::DEFAULT_SORT_PARAMS)
    end

    # A live controller instance with a request attached, so url_for and
    # controller_path behave exactly as they do in a real action
    def controller_for(klass, params)
      controller = klass.new
      controller.set_request!(ActionDispatch::TestRequest.create)
      controller.set_response!(klass.make_response!(controller.request))
      controller.params = ActionController::Parameters.new(params.stringify_keys)
      controller
    end

end
