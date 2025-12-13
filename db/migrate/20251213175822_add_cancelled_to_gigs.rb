class AddCancelledToGigs < ActiveRecord::Migration[7.2]
  def change
    add_column :GIG, :cancelled, :boolean, default: false
    add_index :GIG, :cancelled
  end
end
