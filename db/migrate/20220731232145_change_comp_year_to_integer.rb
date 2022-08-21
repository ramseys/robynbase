class ChangeCompYearToInteger < ActiveRecord::Migration[7.0]
  def up
    change_column :COMP, :Year, :integer
  end
  
  def down
    change_column :COMP, :Year, :float
  end
end