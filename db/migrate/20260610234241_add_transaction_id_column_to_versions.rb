# This migration and CreateVersionAssociations provide the necessary
# schema for tracking associations.
class AddTransactionIdColumnToVersions < ActiveRecord::Migration[7.2]
  def self.up
    # bigint to match versions.id, which is what transaction_id is populated from.
    add_column :versions, :transaction_id, :bigint
    add_index :versions, [:transaction_id]
  end

  def self.down
    remove_index :versions, [:transaction_id]
    remove_column :versions, :transaction_id
  end
end
