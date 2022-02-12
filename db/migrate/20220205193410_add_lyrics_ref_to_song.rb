class AddLyricsRefToSong < ActiveRecord::Migration[5.2]
  def change
    add_column :song, :lyrics_ref, :string
    add_column :song, :show_lyrics, :boolean, default: false

    Song.where("OrigBand IS NULL and lyrics IS NOT NULL").update_all(show_lyrics: true)
  end
end
