require 'test_helper'

class CompositionsControllerTest < ActionDispatch::IntegrationTest
  # Index
  test "should get index" do
    get compositions_path
    assert_response :success
  end

  test "should search by title" do
    comp = create(:composition, Title: "I Often Dream of Trains")
    get compositions_path, params: { search_type: "title", search_value: "Trains" }
    assert_response :success
  end

  test "should search by year" do
    comp = create(:composition, Year: 1984)
    get compositions_path, params: { search_type: "year", search_value: "1984" }
    assert_response :success
  end

  test "should filter by release type" do
    album = create(:composition, :album)
    single = create(:composition, :single)

    get compositions_path, params: { release_types: [0] }  # Albums only
    assert_response :success
  end

  # Show
  test "should show composition" do
    comp = create(:composition)
    get composition_path(comp.COMPID)
    assert_response :success
  end

  test "should show composition with tracks" do
    comp = create(:composition, :with_tracks, tracks_count: 12)
    get composition_path(comp.COMPID)
    assert_response :success
  end

  # CRUD (requires auth)
  test "should create composition when logged in" do
    user = create(:user)
    post sessions_path, params: { email: user.email, password: "password123" }

    assert_difference('Composition.count', 1) do
      post compositions_path, params: {
        composition: {
          Title: "New Album",
          Artist: "Robyn Hitchcock",
          Year: 2023,
          Type: "Album"
        }
      }
    end
  end

  test "should update composition when logged in" do
    user = create(:user)
    comp = create(:composition, Title: "Old Title")
    post sessions_path, params: { email: user.email, password: "password123" }

    patch composition_path(comp.COMPID), params: { composition: { Title: "New Title" } }
    comp.reload
    assert_equal "New Title", comp.Title
  end

  test "should destroy composition when logged in" do
    user = create(:user)
    comp = create(:composition)
    post sessions_path, params: { email: user.email, password: "password123" }

    assert_difference('Composition.count', -1) do
      delete composition_path(comp.COMPID)
    end
  end

  # Quick queries
  test "should handle other_bands quick query" do
    create(:composition, Artist: "The Beatles")
    get compositions_quick_query_path, params: { query_id: "other_bands" }
    assert_response :success
  end
end
