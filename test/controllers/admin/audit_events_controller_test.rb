require 'test_helper'

class Admin::AuditEventsControllerTest < ActionController::TestCase
  tests Admin::AuditEventsController

  fixtures :users

  test "requires login" do
    get :index
    assert_redirected_to login_path
  end

  test "index renders for a logged-in user" do
    session[:user_id] = users(:one).id
    get :index
    assert_response :success
  end

  test "index filters by item type without error" do
    session[:user_id] = users(:one).id
    get :index, params: { item_type: "Gig", event_type: "update" }
    assert_response :success
  end

  test "show renders a grouped activity" do
    session[:user_id] = users(:one).id
    txid = nil
    with_versioning do
      comp = Composition.create!(Title: "ZZ Controller Album",
               tracks_attributes: [{ Song: "A", Seq: 1 }])
      txid = comp.versions.last.transaction_id
    end

    get :show, params: { id: txid }
    assert_response :success
  end

  test "show redirects when the activity does not exist" do
    session[:user_id] = users(:one).id
    get :show, params: { id: 0 }
    assert_redirected_to admin_audit_events_path
  end
end
