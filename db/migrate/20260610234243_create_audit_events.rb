# A denormalized one-row-per-transaction summary of audited activity, maintained
# from PaperTrail::Version after_create (see AuditEvent / Auditable). The admin
# activity list paginates and filters this table directly rather than grouping the
# fast-growing `versions` table by transaction_id. See
# docs/plans/auditing/3-record-change-tracking-plan.md ("Pagination caveat").
class CreateAuditEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_events, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci" do |t|
      t.bigint  :transaction_id, null: false
      t.string  :primary_item_type
      t.bigint  :primary_item_id
      t.string  :item_name
      t.string  :event             # action of the primary item: create / update / destroy
      t.string  :whodunnit
      t.boolean :primary_elevated, default: false, null: false  # headline stands in for a child-only edit's owning parent
      t.integer :version_count, default: 0, null: false
      t.json    :summary           # child-row counts, e.g. {"Gigset"=>{"create"=>2}}

      t.timestamps
    end

    add_index :audit_events, :transaction_id, unique: true
    add_index :audit_events, :created_at
    add_index :audit_events, :whodunnit
    add_index :audit_events, :primary_item_type
    add_index :audit_events, :event
  end
end
