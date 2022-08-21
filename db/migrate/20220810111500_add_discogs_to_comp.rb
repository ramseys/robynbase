class AddDiscogsToComp < ActiveRecord::Migration[7.0]
  def change
    add_column :COMP, :discogs_url, :string
  end
end
