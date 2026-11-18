require 'test_helper'

class ApplicationFormBuilderTest < ActionView::TestCase

  setup do
    @gig = Gig.new
  end

  test "a field with an error gets is-invalid, keeping its own class" do
    @gig.errors.add(:BilledAs, :blank)

    field = rendered(builder.text_field(:BilledAs, class: "form-control")).at_css("input")

    assert_equal "form-control is-invalid", field["class"]
  end

  test "a field without an error is left as it is" do
    @gig.errors.add(:GigDate, :blank)

    field = rendered(builder.text_field(:BilledAs, class: "form-control")).at_css("input")

    assert_equal "form-control", field["class"]
  end

  test "an array class is kept as well" do
    @gig.errors.add(:Reviews, :blank)

    field = rendered(builder.text_area(:Reviews, class: ["form-control", "tall"])).at_css("textarea")

    assert_equal "form-control tall is-invalid", field["class"]
  end

  test "a checkbox is flagged on its visible input, not the hidden one before it" do
    @gig.errors.add(:Circa, :blank)

    html = rendered(builder.check_box(:Circa, class: "form-check-input"))

    assert_equal "form-check-input is-invalid", html.at_css("input[type=checkbox]")["class"]
    assert_nil html.at_css("input[type=hidden]")["class"]
  end

  test "a select is flagged through its html options" do
    @gig.errors.add(:GigType, :blank)

    field = rendered(builder.select(:GigType, ["Concert"], { include_blank: true }, { class: "form-control" })).at_css("select")

    assert_equal "form-control is-invalid", field["class"]
  end

  test "errors_from flags a field whose error is under another attribute, and isn't rendered" do
    @gig.errors.add(:venue, :blank)

    field = rendered(builder.select(:VENUEID, [["The Roundhouse", 1]], {}, { class: "form-control", errors_from: :venue })).at_css("select")

    assert_equal "form-control is-invalid", field["class"]
    assert_nil field["errors_from"]
  end

  test "errored fields aren't wrapped in field_with_errors" do
    @gig.errors.add(:GigDate, :blank)

    html = rendered(builder.label(:GigDate) + builder.date_field(:GigDate, class: "form-control"))

    assert_empty html.css(".field_with_errors")
    assert_equal "form-control is-invalid", html.at_css("input")["class"]
  end

  test "a form with no record renders its fields unflagged" do
    field = rendered(ApplicationFormBuilder.new(:search, nil, self, {}).text_field(:q, class: "form-control")).at_css("input")

    assert_equal "form-control", field["class"]
  end

  private

  def builder
    ApplicationFormBuilder.new(:gig, @gig, self, {})
  end

  def rendered(html)
    Nokogiri::HTML5.fragment(html)
  end

end
