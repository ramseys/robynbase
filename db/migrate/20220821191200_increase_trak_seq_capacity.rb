class IncreaseTrakSeqCapacity < ActiveRecord::Migration[7.0]

  def up
    change_column :TRAK, :Seq, :integer, :limit => nil
  end

  def down
    change_column :TRAK, :Seq, :integer, :limit => 1
  end

end
