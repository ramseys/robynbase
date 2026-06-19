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
end
