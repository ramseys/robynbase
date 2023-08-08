class AddLatLongToVenues < ActiveRecord::Migration[7.0]
  def change
    add_column :VENUE, :latitude, :float
    add_column :VENUE, :longitude, :float
    add_column :VENUE, :street_address1, :string
    add_column :VENUE, :street_address2, :string
  end
end
