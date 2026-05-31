require 'test_helper'

class SanitizableTextTest < ActiveSupport::TestCase
  # Use Song as a concrete host for the concern — avoids stubbing ActiveRecord
  setup do
    @model = Song.new
  end

  # --- sanitize_html ---

  test "sanitize_html returns nil for nil input" do
    assert_nil @model.sanitize_html(nil)
  end

  test "sanitize_html returns nil for blank string" do
    assert_nil @model.sanitize_html('')
  end

  test "sanitize_html strips disallowed tags" do
    result = @model.sanitize_html('<script>alert("xss")</script><p>Safe</p>')
    assert_not_includes result, '<script>'
    assert_includes result, 'Safe'
  end

  test "sanitize_html allows permitted formatting tags" do
    html = '<p>Hello <strong>world</strong></p>'
    assert_includes @model.sanitize_html(html), '<p>Hello <strong>world</strong></p>'
  end

  test "sanitize_html strips disallowed attributes" do
    result = @model.sanitize_html('<p onclick="evil()">Click me</p>')
    assert_not_includes result, 'onclick'
  end

  test "sanitize_html preserves allowed href attribute" do
    html = '<a href="https://example.com">link</a>'
    assert_includes @model.sanitize_html(html), 'href="https://example.com"'
  end

  test "sanitize_html allows iframe tag" do
    result = @model.sanitize_html('<iframe src="https://example.com"></iframe>')
    assert_includes result, '<iframe'
  end

  test "sanitize_html enforces sandbox on iframes" do
    result = @model.sanitize_html('<iframe src="https://example.com"></iframe>')
    assert_includes result, 'sandbox="allow-scripts allow-same-origin"'
  end

  test "sanitize_html strips user-submitted sandbox attribute" do
    result = @model.sanitize_html('<iframe src="https://example.com" sandbox="allow-forms allow-top-navigation"></iframe>')
    assert_not_includes result, 'allow-forms'
    assert_not_includes result, 'allow-top-navigation'
    assert_includes result, 'sandbox="allow-scripts allow-same-origin"'
  end

  test "sanitize_html strips allow attribute" do
    result = @model.sanitize_html('<iframe src="https://example.com" allow="camera; microphone"></iframe>')
    assert_not_includes result, 'allow='
  end

  test "sanitize_html strips allowfullscreen attribute" do
    result = @model.sanitize_html('<iframe src="https://example.com" allowfullscreen></iframe>')
    assert_not_includes result, 'allowfullscreen'
  end

  # --- enforce_iframe_sandbox ---

  test "enforce_iframe_sandbox returns nil for nil input" do
    assert_nil @model.enforce_iframe_sandbox(nil)
  end

  test "enforce_iframe_sandbox returns blank string unchanged" do
    assert_equal '', @model.enforce_iframe_sandbox('')
  end

  test "enforce_iframe_sandbox adds sandbox when attribute is absent" do
    result = @model.enforce_iframe_sandbox('<iframe src="https://example.com"></iframe>')
    assert_includes result, 'sandbox="allow-scripts allow-same-origin"'
  end

  test "enforce_iframe_sandbox applies sandbox to every iframe in the string" do
    html = '<iframe src="https://one.com"></iframe><iframe src="https://two.com"></iframe>'
    result = @model.enforce_iframe_sandbox(html)
    assert_equal 2, result.scan('sandbox="allow-scripts allow-same-origin"').length
  end

  test "enforce_iframe_sandbox leaves html without iframes unchanged" do
    html = '<p>Hello <strong>world</strong></p>'
    assert_includes @model.enforce_iframe_sandbox(html), '<p>Hello <strong>world</strong></p>'
  end
end
