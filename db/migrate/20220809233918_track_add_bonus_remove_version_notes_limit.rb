class TrackAddBonusRemoveVersionNotesLimit < ActiveRecord::Migration[7.0]

  def up
    add_column :TRAK, :bonus, :boolean, :default => false
    change_column :TRAK, :VersionNotes, :string, :limit => nil
  end

  def down
    remove_column :TRAK, :bonus
    change_column :TRAK, :VersionNotes, :string, :limit => 64
  end

end
