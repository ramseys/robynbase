require 'test_helper'

class RobynControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "index renders recent updates excluding destroys when there is no search" do
    AuditEvent.create!(transaction_id: 900_101, primary_item_type: "Gig", primary_item_id: 1,
      item_name: "Kept Gig Zzyzx", event: "create", created_at: 1.hour.ago)
    AuditEvent.create!(transaction_id: 900_102, primary_item_type: "Venue", primary_item_id: 2,
      item_name: "Deleted Venue Zzyzx", event: "destroy", created_at: 1.hour.ago)

    get :index

    assert_includes response.body, "Kept Gig Zzyzx"
    assert_not_includes response.body, "Deleted Venue Zzyzx"
  end

  test "index does not render recent updates when a search is active" do
    AuditEvent.create!(transaction_id: 900_103, primary_item_type: "Gig", primary_item_id: 1,
      item_name: "Kept Gig Zzyzx", event: "create", created_at: 1.hour.ago)

    get :index, params: { search_value: "anything" }

    assert_not_includes response.body, "Kept Gig Zzyzx"
  end
end
