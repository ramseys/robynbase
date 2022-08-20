class RemoveCompCommentsLimit < ActiveRecord::Migration[7.0]

  def up
    change_column :COMP, :Comments, :text
  end

  def down
    change_column :COMP, :Comments, :string, :limit => 128
  end

end