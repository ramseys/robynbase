class DropPerformanceTable < ActiveRecord::Migration[5.2]

  def change

    drop_table "performances", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
      t.integer "performanceid"
      t.string "url"
      t.string "name"
      t.string "venue"
      t.integer "host"
      t.integer "medium"
      t.integer "performance_type"
      t.date "performance_date"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    remove_index :song_performances, name: "index_song_performances_on_performance_id"
    remove_index :song_performances, name: "index_song_performances_on_song_id"

    drop_table "song_performances", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
      t.integer "song_id"
      t.integer "performance_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["performance_id"], name: "index_song_performances_on_performance_id"
      t.index ["song_id"], name: "index_song_performances_on_song_id"
    end

  end

end
