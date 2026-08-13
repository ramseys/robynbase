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
end
