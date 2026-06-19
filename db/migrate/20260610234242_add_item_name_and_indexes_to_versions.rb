# Adds a stable human-readable label stored at write time (populated via the
# `meta: { item_name: :audit_name }` option on each model's has_paper_trail), plus
# the indexes the admin audit UI needs. See
# docs/plans/auditing/3-record-change-tracking-plan.md ("Key Changes").
#
# The `versions` table itself is already utf8mb4 (set in CreateVersions), so no
# charset conversion is needed here.
class AddItemNameAndIndexesToVersions < ActiveRecord::Migration[7.2]
  def change
    add_column :versions, :item_name, :string

    # Per-record history, time-ordered. Supersedes the (item_type, item_id) index
    # added by CreateVersions, which is a prefix of this one.
    remove_index :versions, %i[item_type item_id]
    add_index :versions, %i[item_type item_id created_at]

    # whodunnit -> user filter; created_at -> date-range filter.
    add_index :versions, :whodunnit
    add_index :versions, :created_at
  end
end
