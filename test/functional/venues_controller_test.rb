require 'test_helper'

class VenuesControllerTest < ActionController::TestCase

  # --- search-result navigation ---

  SEARCH_BACK = "/venues/index?direction=asc&search_type=city&search_value=london&sort=venue".freeze

  test "index search results link to show pages carrying the search" do
    london_venue("Brixton Academy")

    get :index, params: { search_type: "city", search_value: "london" }

    backs = search_backs_in_rows
    assert_equal 2, backs.size
    assert_equal [SEARCH_BACK], backs.uniq
  end

  test "show walks prev and next through the search result set" do
    other = london_venue("Brixton Academy")

    # sorted by name asc: Brixton Academy, then The Roundhouse (venue 1)
    get :show, params: { id: other.id, search_back: SEARCH_BACK }
    nav = rendered_search_nav

    assert_nil nav[:prev]
    assert_equal SEARCH_BACK, nav[:back]
    assert_equal "/venues/1?search_back=#{CGI.escape(SEARCH_BACK)}", nav[:next]

    get :show, params: { id: 1, search_back: SEARCH_BACK }
    nav = rendered_search_nav

    assert_equal "/venues/#{other.id}?search_back=#{CGI.escape(SEARCH_BACK)}", nav[:prev]
    assert_nil nav[:next]
  end

  test "show reached without a search renders no navigation bar" do
    get :show, params: { id: 1 }

    assert_nil rendered_search_nav
  end

  test "a search_back for another controller is ignored" do
    get :show, params: { id: 1, search_back: "/gigs/index?search_type=venue&search_value=roundhouse&sort=date&direction=desc" }

    assert_nil rendered_search_nav
  end

  test "appended rows carry the same search as the listing" do
    assert_appended_rows_carry_the_listing_search(:index, search_type: "city", search_value: "london")
  end

  # --- returning to the search after an edit ---

  test "an edit from a search returns to the show page carrying it" do
    session[:user_id] = users(:one).id

    assert_edit_round_trip_carries_search("/venues/1", SEARCH_BACK, venue_update_params(1))
  end

  test "an edit without a search returns to the show page" do
    session[:user_id] = users(:one).id

    assert_edit_round_trip_without_search("/venues/1", venue_update_params(1))
  end

  # --- create ---

  test "create goes to the new venue's show page" do
    session[:user_id] = users(:one).id

    post :create, params: { venue: { Name: "The Half Moon", City: "London", Country: "UK", SubCity: "", State: "" } }

    assert_redirected_to venue_path(Venue.last)
  end

  # --- failed saves re-render the form with the user's input ---

  test "create with a blank required field re-renders the form with the entered values" do
    session[:user_id] = users(:one).id

    assert_no_difference 'Venue.count' do
      post :create, params: { venue: { Name: "The Half Moon", City: "London", Country: "", SubCity: "", State: "" } }
    end

    assert_response :unprocessable_content
    assert_select "input[name='venue[Name]'][value=?]", "The Half Moon"
    assert_select ".alert-danger li", "Country can't be blank"
  end

  test "update with a blank required field re-renders the form instead of redirecting" do
    session[:user_id] = users(:one).id
    original_city = Venue.find(1).City

    patch :update, params: venue_update_params(1).deep_merge(venue: { Name: "Renamed Venue", City: "" })

    assert_response :unprocessable_content
    assert_select "input[name='venue[Name]'][value=?]", "Renamed Venue"
    assert_select ".alert-danger li", "City can't be blank"
    assert_equal original_city, Venue.find(1).City
  end

  test "a failed update keeps images the user marked for removal" do
    session[:user_id] = users(:one).id
    attachment_id = attach_test_image(Venue.find(1))

    patch :update, params: venue_update_params(1).deep_merge(venue: { City: "" }).merge(deleted_img_ids: [attachment_id])

    assert_response :unprocessable_content
    assert ActiveStorage::Attachment.exists?(attachment_id)
  end

  test "a successful update purges images the user marked for removal" do
    session[:user_id] = users(:one).id
    attachment_id = attach_test_image(Venue.find(1))

    patch :update, params: venue_update_params(1).merge(deleted_img_ids: [attachment_id])

    assert_redirected_to venue_path(1)
    assert_not ActiveStorage::Attachment.exists?(attachment_id)
  end

  test "a failed create doesn't optimize the uploaded images" do
    session[:user_id] = users(:one).id

    @controller.stub(:optimize_images, ->(_images) { flunk "images were optimized for a save that failed" }) do
      post :create, params: { venue: { Name: "The Half Moon", City: "London", Country: "", SubCity: "", State: "", images: [test_upload] } }
    end

    assert_response :unprocessable_content
  end

  test "a successful create optimizes and attaches the uploaded images" do
    session[:user_id] = users(:one).id
    optimized = []

    @controller.stub(:optimize_images, ->(images) { optimized.concat(images) }) do
      post :create, params: { venue: { Name: "The Half Moon", City: "London", Country: "UK", SubCity: "", State: "", images: [test_upload] } }
    end

    venue = Venue.find_by!(Name: "The Half Moon")
    assert_redirected_to venue_path(venue)
    assert_equal 1, optimized.size
    assert_equal ["hall.jpg"], venue.images.map { |image| image.filename.to_s }
  end

  test "an update ignores marked images that belong to another record" do
    session[:user_id] = users(:one).id
    other_venue = Venue.create!(Name: "The Half Moon", City: "London", Country: "UK")
    attachment_id = attach_test_image(other_venue)

    patch :update, params: venue_update_params(1).merge(deleted_img_ids: [attachment_id])

    assert_redirected_to venue_path(1)
    assert ActiveStorage::Attachment.exists?(attachment_id)
  end

  private

    # a stand-in upload; optimize_images is stubbed wherever it's used, so the bytes
    # don't have to be a real image
    def test_upload
      Rack::Test::UploadedFile.new(StringIO.new("not really a jpeg"), "image/jpeg", original_filename: "hall.jpg")
    end

    def attach_test_image(venue)
      venue.images.attach(io: StringIO.new("not really a jpeg"), filename: "hall.jpg", content_type: "image/jpeg")
      venue.images.last.id
    end

    def venue_update_params(id)
      venue = Venue.find(id)

      { id: id, venue: { Name: venue.Name, City: venue.City, Country: venue.Country, SubCity: "", State: "" } }
    end

    # A second London venue, so a city search has a result set with an order to walk.
    # Created per test rather than in setup: only two of these tests want it, and the
    # others should not have to reason about an extra row they never asked for.
    def london_venue(name)
      Venue.create!(Name: name, City: "London", Country: "UK")
    end

end
