class ChangeLatitudeLongitudeToBeDecimalInVenue < ActiveRecord::Migration[7.0]
  def up
    change_column :VENUE, :latitude, :decimal, :precision => 13, :scale => 9
    change_column :VENUE, :longitude, :decimal, :precision => 13, :scale => 9
  end

  def down
    change_column :VENUE, :latitude, :float
    change_column :VENUE, :longitude, :float
  end
end
