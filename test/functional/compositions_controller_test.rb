require 'test_helper'

class CompositionsControllerTest < ActionController::TestCase
  tests CompositionsController

  fixtures :COMP, :TRAK, :SONG, :users

  setup do
    session[:user_id] = users(:one).id
  end

  # --- create ---

  test "create persists composition with tracks" do
    assert_difference ['Composition.count', 'Track.count'], 1 do
      post :create, params: comp_create_params(
        tracks: { "0" => { Seq: "10", SONGID: "1", Song: "", VersionNotes: "", bonus: "false" } }
      )
    end
    assert_redirected_to composition_path(Composition.last)
  end

  test "create with no tracks still saves the composition" do
    assert_difference 'Composition.count', 1 do
      assert_no_difference 'Track.count' do
        post :create, params: comp_create_params
      end
    end
    assert_redirected_to composition_path(Composition.last)
  end

  test "create with a validation failure does not persist tracks" do
    # Strong params require Title/Artist so we can't blank them to trigger model failure.
    # Instead stub Composition.new to return a record whose save returns false, verifying
    # the controller only creates tracks after a successful parent save.
    @controller.instance_variable_set(:@song_list, [])
    failing_comp = Composition.new(Title: "Stub", Artist: "Stub")
    failing_comp.define_singleton_method(:save) { false }
    Composition.stub(:new, failing_comp) do
      assert_no_difference 'Track.count' do
        post :create, params: comp_create_params(
          tracks: { "0" => { Seq: "10", SONGID: "1", Song: "", VersionNotes: "", bonus: "false" } }
        )
      end
    end
    assert_response :success
  end

  # --- update ---

  test "update with changed parent field persists the change" do
    patch :update, params: comp_update_params(1, overrides: { Year: "1995" })
    assert_equal 1995, Composition.find(1).Year
    assert_redirected_to composition_path(Composition.find(1))
  end

  test "update replaces tracklist with new tracks and correct Seq values" do
    patch :update, params: comp_update_params(1,
      tracks: {
        "0" => { "id" => "1", "_destroy" => "1", Seq: "10", SONGID: "1", Song: "Madonna of the Wasps", VersionNotes: "", bonus: "false" },
        "1" => { "id" => "2", "_destroy" => "1", Seq: "20", SONGID: "2", Song: "The Cheese Alarm",     VersionNotes: "", bonus: "false" },
        "2" => { Seq: "10", SONGID: "3", Song: "", VersionNotes: "", bonus: "false" },
        "3" => { Seq: "20", SONGID: "2", Song: "", VersionNotes: "", bonus: "false" }
      }
    )
    tracks = Composition.find(1).tracks.order(:Seq)
    assert_equal 2, tracks.count
    assert_equal 3, tracks.first.SONGID
    assert_equal 10, tracks.first.Seq
  end

  test "update with no tracks removes all existing track rows" do
    assert_equal 2, Composition.find(1).tracks.count
    patch :update, params: comp_update_params(1,
      tracks: {
        "0" => { "id" => "1", "_destroy" => "1", Seq: "10", SONGID: "1", Song: "Madonna of the Wasps", VersionNotes: "", bonus: "false" },
        "1" => { "id" => "2", "_destroy" => "1", Seq: "20", SONGID: "2", Song: "The Cheese Alarm",     VersionNotes: "", bonus: "false" }
      }
    )
    assert_equal 0, Composition.find(1).tracks.count
  end

  # --- destroy ---

  test "destroy removes composition and its tracks" do
    assert_difference 'Composition.count', -1 do
      assert_difference 'Track.count', -2 do
        delete :destroy, params: { id: 1 }
      end
    end
  end

  # --- transaction rollback ---

  test "failed parent update does not leave orphaned tracks" do
    @controller.instance_variable_set(:@comp, Composition.find(1))
    @controller.instance_variable_set(:@song_list, [])
    comp = Composition.find(1)
    comp.define_singleton_method(:valid?) { |*| false }
    Composition.stub(:find, comp) do
      assert_no_difference 'Track.count' do
        patch :update, params: comp_update_params(1,
          overrides: { Year: "2099" },
          tracks: {
            "0" => { "id" => "1", "_destroy" => "1", Seq: "10", SONGID: "1", Song: "Madonna of the Wasps", VersionNotes: "", bonus: "false" },
            "1" => { "id" => "2", "_destroy" => "1", Seq: "20", SONGID: "2", Song: "The Cheese Alarm",     VersionNotes: "", bonus: "false" },
            "2" => { Seq: "10", SONGID: "3", Song: "", VersionNotes: "", bonus: "false" }
          }
        )
      end
    end
    assert_equal 2, Composition.find(1).tracks.count
  end

  test "failed track save rolls back parent update" do
    @controller.instance_variable_set(:@comp, Composition.find(1))
    @controller.instance_variable_set(:@song_list, [])
    original_year = Composition.find(1).Year
    assert_no_difference 'Track.count' do
      patch :update, params: comp_update_params(1,
        overrides: { Year: "2099" },
        tracks: { "0" => { Seq: "10", SONGID: "", Song: "", VersionNotes: "", bonus: "false" } }
      )
    end
    assert_equal original_year, Composition.find(1).Year
  end

  private

  def comp_create_params(tracks: nil, overrides: {})
    base = {
      Title: "New Album",
      Artist: "Robyn Hitchcock",
      Year: "2024",
      Type: "Album",
      Comments: ""
    }.merge(overrides)

    base[:tracks_attributes] = tracks if tracks

    { composition: base }
  end

  def comp_update_params(id, tracks: nil, overrides: {})
    params = comp_create_params(tracks: tracks, overrides: overrides)
    params[:id] = id
    params
  end
end
