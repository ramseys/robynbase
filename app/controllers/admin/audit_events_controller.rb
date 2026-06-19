class Admin::AuditEventsController < AdminController

  # Paginated activity list with date / user / event / item-type filters.
  def index
    @pagy, @audit_events = pagy(filtered_events, limit: 40)

    @event_types = %w[create update destroy]
    @item_types  = AuditEvent.distinct.where.not(primary_item_type: nil).pluck(:primary_item_type).sort
    @actors      = AuditEvent.distinct.where.not(whodunnit: nil).pluck(:whodunnit).sort
  end

  # Grouped detail for one activity, keyed by transaction_id.
  def show
    @activity = AuditActivity.new(params[:id])
    redirect_to admin_audit_events_path, alert: "Activity not found." unless @activity.exists?
  end

  private

  # Compose the model's filter scopes from the request params; each is a no-op
  # when its param is blank.
  def filtered_events
    AuditEvent.order(created_at: :desc)
              .of_item_type(params[:item_type])
              .of_event(params[:event_type])
              .by_actor(params[:whodunnit])
              .created_on_or_after(params[:start_date])
              .created_on_or_before(params[:end_date])
  end
end
