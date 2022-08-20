class DropMajorTable < ActiveRecord::Migration[7.0]

  def up
    drop_table :MAJR
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

end