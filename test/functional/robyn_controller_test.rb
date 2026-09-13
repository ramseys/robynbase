require 'test_helper'

class RobynControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "index renders the recent updates box as an empty frame, without running the feed query" do
    AuditEvent.create!(transaction_id: 900_101, primary_item_type: "Gig", primary_item_id: 1,
      item_name: "Kept Gig Zzyzx", event: "create", created_at: 1.hour.ago)

    get :index

    assert_includes response.body, "Recent Updates", "the box's header is server-rendered"
    assert_includes response.body, %(id="recent_updates_frame"), "the frame is present but unloaded"
    assert_not_includes response.body, "Kept Gig Zzyzx",
                        "the feed content must not be rendered until the box is expanded"
  end

  test "index renders the recent updates box even when there is no activity" do
    # The box is deliberately unconditional: hiding it on an empty result would make a
    # broken feed indistinguishable from a quiet one.
    get :index

    assert_includes response.body, "Recent Updates"
  end

  test "index does not render recent updates when a search is active" do
    get :index, params: { search_value: "anything" }

    assert_not_includes response.body, "Recent Updates"
  end

  test "recent_updates renders the feed, excluding destroys" do
    AuditEvent.create!(transaction_id: 900_101, primary_item_type: "Gig", primary_item_id: 1,
      item_name: "Kept Gig Zzyzx", event: "create", created_at: 1.hour.ago)
    AuditEvent.create!(transaction_id: 900_102, primary_item_type: "Venue", primary_item_id: 2,
      item_name: "Deleted Venue Zzyzx", event: "destroy", created_at: 1.hour.ago)

    get :recent_updates

    assert_response :success
    assert_includes response.body, "Kept Gig Zzyzx"
    assert_not_includes response.body, "Deleted Venue Zzyzx"
  end

  test "recent_updates says so when there is nothing to show" do
    get :recent_updates

    assert_response :success
    assert_includes response.body, "No recent activity."
  end

  # --- omnisearch ---
  #
  # Omnisearch renders one lazy turbo frame per resource, and each frame sorts through
  # Paginated#apply_ordering. RobynController is the one host that cannot use a
  # RESOURCE_TYPE constant - it serves all four resources - so it overrides
  # #resource_type per action; these cover that the override reaches the sorter.

  test "omnisearch frames render for every resource" do
    {
      omnisearch_gigs: "Roundhouse",
      omnisearch_songs: "Wasps",
      omnisearch_compositions: "Robyn",
      omnisearch_venues: "Roundhouse"
    }.each do |action, search|
      get action, params: { search_value: search }

      assert_response :success, "#{action} did not render"
    end
  end

  # Every SONG fixture title contains an "a", so all three come back and the sort is
  # the only thing deciding their order
  test "omnisearch honours an explicit sort in both directions" do
    assert_equal ["Driving Aloud", "Madonna of the Wasps", "The Cheese Alarm"],
                 omnisearch_song_order("asc")

    assert_equal ["The Cheese Alarm", "Madonna of the Wasps", "Driving Aloud"],
                 omnisearch_song_order("desc")
  end

  test "omnisearch without a search value is a bad request" do
    get :omnisearch_gigs

    assert_response :bad_request
  end

  private

    # The song titles in the order the rendered frame lists them
    def omnisearch_song_order(direction)
      get :omnisearch_songs, params: { search_value: "a", sort: "name", direction: direction }
      assert_response :success

      titles = Song.pluck(:Song)

      titles.sort_by { |title| response.body.index(title) || titles.size }
    end
end
