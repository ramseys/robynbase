require 'test_helper'

class AuditEventsHelperTest < ActionView::TestCase
  test "links a non-destroy primary item to its show page (polymorphic)" do
    gig = AuditEvent.new(primary_item_type: "Gig", primary_item_id: 11,
                         item_name: "The Ritz - 1990-01-01", event: "update")
    html = audit_item_link(gig)
    assert_includes html, %(href="#{gig_path(11)}")
    assert_includes html, "The Ritz - 1990-01-01"

    comp = AuditEvent.new(primary_item_type: "Composition", primary_item_id: 7,
                          item_name: "Album (2000)", event: "create")
    assert_includes audit_item_link(comp), %(href="#{composition_path(7)}")
  end

  # The homepage feed renders these links inside the recent_updates_frame, and the
  # target page has no such frame — without the breakout Turbo replaces the feed with
  # a "content missing" message instead of navigating. Asserted explicitly so that
  # dropping the attribute fails here rather than only in the browser.
  test "links break out of the enclosing turbo frame" do
    event = AuditEvent.new(primary_item_type: "Gig", primary_item_id: 11,
                           item_name: "The Ritz - 1990-01-01", event: "update")
    assert_includes audit_item_link(event), %(data-turbo-frame="_top")
  end

  test "does not link a destroy" do
    event = AuditEvent.new(primary_item_type: "Gig", primary_item_id: 11,
                           item_name: "The Ritz - 1990-01-01", event: "destroy")
    assert_equal "The Ritz - 1990-01-01", audit_item_link(event)
  end

  test "does not link a type without a show route" do
    event = AuditEvent.new(primary_item_type: "Gigset", primary_item_id: 5,
                           item_name: "Setlist: X", event: "update")
    assert_equal "Setlist: X", audit_item_link(event)
  end

  test "recent_update_item reports added for a create and updated for anything else" do
    created = AuditEvent.new(primary_item_type: "Gig", primary_item_id: 11,
                             item_name: "The Ritz - 1990-01-01", event: "create")
    assert_includes recent_update_item(created), "added"

    updated = AuditEvent.new(primary_item_type: "Venue", primary_item_id: 3,
                             item_name: "The Ritz", event: "update")
    assert_includes recent_update_item(updated), "updated"

    destroyed = AuditEvent.new(primary_item_type: "Venue", primary_item_id: 3,
                               item_name: "The Ritz", event: "destroy")
    assert_includes recent_update_item(destroyed), "updated"
  end

  test "recent_update_item uses the category-page name for the item type" do
    event = AuditEvent.new(primary_item_type: "Composition", primary_item_id: 7,
                           item_name: "Album (2000)", event: "create")
    assert_recent_update_row "Release", composition_path(7), "Album (2000)", "added",
                             recent_update_item(event)
  end

  test "recent_update_item falls back to the class name for unmapped types" do
    event = AuditEvent.new(primary_item_type: "Gig", primary_item_id: 11,
                           item_name: "The Ritz - 1990-01-01", event: "update")
    assert_recent_update_row "Gig", gig_path(11), "The Ritz - 1990-01-01", "updated",
                             recent_update_item(event)
  end

  test "recent_update_item renders an unlinkable item as plain text" do
    event = AuditEvent.new(primary_item_type: "Gig", primary_item_id: 11,
                           item_name: "The Ritz - 1990-01-01", event: "destroy")
    assert_equal "Gig The Ritz - 1990-01-01 updated", recent_update_item(event)
  end

  # AuditEvent.for_recent_updates excludes destroys, so these two exercise the
  # helper's unlinkable branch in isolation; a destroy is just the easiest way to
  # reach it, not something the homepage feed actually renders.
  test "recent_update_item escapes an unlinkable item name" do
    event = AuditEvent.new(primary_item_type: "Venue", primary_item_id: 3,
                           item_name: "Bar & Grill <script>alert(1)</script>", event: "destroy")
    assert_equal "Venue Bar &amp; Grill &lt;script&gt;alert(1)&lt;/script&gt; updated",
                 recent_update_item(event)
  end

  test "recent_update_item escapes a linked item name" do
    event = AuditEvent.new(primary_item_type: "Venue", primary_item_id: 3,
                           item_name: "Bar & Grill <script>alert(1)</script>", event: "update")
    html = recent_update_item(event)
    assert_includes html, "Bar &amp; Grill &lt;script&gt;alert(1)&lt;/script&gt;"
    assert_not_includes html, "<script>"
  end

  test "recent_update_item returns markup the view can render unescaped" do
    event = AuditEvent.new(primary_item_type: "Gig", primary_item_id: 11,
                           item_name: "The Ritz - 1990-01-01", event: "update")
    assert_predicate recent_update_item(event), :html_safe?
  end

  private

  # Asserts a feed row's whole wording and structure — "<category> <link> <action>" —
  # without pinning the anchor's attribute list, so adding a data attribute to the link
  # doesn't break tests that are really about the row's assembly.
  def assert_recent_update_row(category, path, name, action, html)
    assert_match %r{\A#{category} <a [^>]*href="#{Regexp.escape(path)}"[^>]*>#{Regexp.escape(name)}</a> #{action}\z},
                 html
  end

end
