module AuditEventsHelper

  # Category-page name for a top-level audited type, where it differs from the
  # class name (Composition's public-facing name is "Release").
  RECENT_UPDATE_TYPE_NAMES = {
    "Composition" => "Release"
  }.freeze

  # A homepage "Recent Updates" row, e.g. "Release <link> added". Built with
  # safe_join rather than interpolation + html_safe so that an unlinkable
  # item_name is escaped instead of riding along inside a safe string.
  def recent_update_item(event)
    item_type = event.primary_item_type
    item_category = RECENT_UPDATE_TYPE_NAMES.fetch(item_type, item_type)
    action = event.event == "create" ? "added" : "updated"

    safe_join([item_category, audit_item_link(event), action], " ")
  end
  
  # Bootstrap badge class for a primary event / child-row kind.
  AUDIT_BADGE_CLASS = {
    "create"    => "bg-success",
    "update"    => "bg-primary",
    "destroy"   => "bg-danger",
    "added"     => "bg-success",
    "removed"   => "bg-danger",
    "changed"   => "bg-primary",
    "reordered" => "bg-secondary"
  }.freeze

  def audit_badge(label)
    css = AUDIT_BADGE_CLASS.fetch(label.to_s, "bg-secondary")
    content_tag(:span, label.to_s.humanize, class: "badge #{css}")
  end

  # Renders a single old/new value from an object_changes diff for display.
  def format_audit_value(value)
    return content_tag(:em, "(empty)", class: "text-muted") if value.nil? || value == ""
    truncate(value.to_s, length: 120)
  end

  # The item column: a link to the primary record's page, or just its name when it
  # can't be linked — a destroy (the record is gone) or a type with no show route
  # (e.g. an unelevated child row). Builds the path from type + id (no record load),
  # so it adds no query per row; the path helper is derived polymorphically, e.g.
  # "Gig" -> gig_path, "Composition" -> composition_path.
  def audit_item_link(event)
    path_helper = "#{event.primary_item_type.to_s.underscore}_path" if event.primary_item_type.present?
    if event.event != "destroy" && event.primary_item_id.present? && path_helper && respond_to?(path_helper)
      link_to event.item_name, public_send(path_helper, event.primary_item_id)
    else
      event.item_name
    end
  end
end
