# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_02_05_193410) do

  create_table "COMP", primary_key: "COMPID", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "Artist", limit: 64
    t.string "Title", limit: 64
    t.float "Year", limit: 53
    t.string "Medium", limit: 16
    t.string "MCODE", limit: 1
    t.string "Label", limit: 64
    t.string "CatNo", limit: 16
    t.string "Type", limit: 16
    t.boolean "Single", default: false
    t.string "Desc", limit: 64
    t.string "Comments", limit: 128
    t.integer "MAJRID", default: 0
    t.string "CoverImage", limit: 32
    t.string "Field9", limit: 2
    t.string "Field11", limit: 2
    t.index ["Desc"], name: "Desc"
    t.index ["MAJRID"], name: "MAJRID"
    t.index ["MCODE"], name: "MCODE"
    t.index ["Medium"], name: "Medium"
    t.index ["Title"], name: "Title"
    t.index ["Type"], name: "Type"
  end

  create_table "FEG", primary_key: "FEGID", id: :string, limit: 50, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "Lastname", limit: 20
    t.string "Firstname", limit: 20
    t.string "Street", limit: 35
    t.string "City", limit: 25
    t.string "State", limit: 2
    t.string "Zip", limit: 11
    t.string "Country", limit: 20
    t.text "EMail", limit: 4294967295
    t.text "URL", limit: 4294967295
    t.index ["FEGID"], name: "FEGID", unique: true
  end

  create_table "FEGNAME", primary_key: ["FIRST", "LAST"], options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "FIRST", limit: 24, null: false
    t.string "LAST", limit: 32, null: false
    t.string "FEGNAME", limit: 128
  end

  create_table "FEGWORD", primary_key: "WORDID", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "WORDTYPE", limit: 1, default: 0, null: false
    t.string "WORDIS", limit: 32, null: false
    t.string "CONNECTOR", limit: 8
    t.boolean "NICE", default: false
    t.index ["WORDTYPE"], name: "WORDTYPE"
  end

  create_table "GIG", primary_key: "GIGID", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "BilledAs", limit: 75, default: "Robyn Hitchcock"
    t.string "Venue", limit: 128
    t.integer "VENUEID", default: 0
    t.string "GigType", limit: 16
    t.datetime "GigDate"
    t.string "GigYear", limit: 4
    t.boolean "Circa", default: false
    t.integer "SetNum", limit: 1, default: 0
    t.datetime "StartTime"
    t.integer "Length", default: 0
    t.string "Guests", limit: 512
    t.text "ShortNote"
    t.string "Shirts", limit: 24
    t.text "Reviews", limit: 4294967295
    t.boolean "TapeExists", default: false
    t.string "Performance", limit: 1
    t.string "Sound", limit: 1
    t.string "Rarity", limit: 1
    t.string "Format", limit: 32
    t.string "Genealogy", limit: 32
    t.string "Flaws", limit: 32
    t.boolean "Favorite", default: false
    t.string "Master", limit: 32
    t.string "Type", limit: 32, default: "aud"
    t.text "Archived", limit: 4294967295
    t.integer "FEGID", default: 0
    t.timestamp "ModifyDate", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["BilledAs"], name: "BilledAs"
    t.index ["GigDate"], name: "GigDate"
    t.index ["VENUEID"], name: "VENUEID"
  end

  create_table "GSET", primary_key: "SETID", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "GIGID", default: 0
    t.integer "SONGID", default: 0
    t.integer "Chrono", default: 10
    t.string "Song"
    t.string "VersionNotes"
    t.boolean "Encore", default: false
    t.boolean "Segue", default: false
    t.boolean "Soundcheck", default: false
    t.string "Flaw", limit: 32
    t.string "MP3Site", limit: 4
    t.string "MP3File", limit: 64
    t.string "MediaLink"
    t.index ["GIGID"], name: "GIGID"
    t.index ["SETID"], name: "SETID"
    t.index ["SONGID"], name: "SONGID"
  end

  create_table "MAJR", primary_key: "MAJRID", id: :integer, default: 0, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "AlbumTitles", limit: 64
    t.string "RecordedBy", limit: 64
    t.float "ReleaseYear", limit: 53
    t.integer "COMPID", default: 0
    t.string "AltVersion", limit: 128
    t.integer "COMPID2", default: 0
    t.string "FrontImage", limit: 32
    t.string "BackImage", limit: 32
    t.string "CoverDesigner", limit: 128
    t.text "ProductionCredits", limit: 4294967295
    t.text "Notes", limit: 4294967295
    t.index ["AlbumTitles"], name: "AlbumTitles"
    t.index ["COMPID"], name: "COMPID"
    t.index ["RecordedBy"], name: "RecordedBy"
  end

  create_table "MEDIA", primary_key: "MCODE", id: :string, limit: 1, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "Medium", limit: 16
    t.string "Media", limit: 16
    t.string "Caption", limit: 24
    t.string "Abbrev", limit: 16
    t.index ["MCODE"], name: "MCODE", unique: true
  end

  create_table "MUSO", primary_key: "MUSOID", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "Name", limit: 50
    t.boolean "Author", default: false
    t.boolean "Performer", default: false
    t.boolean "Guest", default: false
    t.text "Notes", limit: 4294967295
  end

  create_table "Paste Errors", id: false, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "Song"
    t.integer "Disc", limit: 1
    t.string "Side"
    t.integer "Seq", limit: 1
    t.string "Time"
  end

  create_table "SITE", primary_key: "SITEID", id: :string, limit: 4, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "SiteType", limit: 16
    t.boolean "FriendliesOnly", default: false
    t.string "Description", limit: 64
    t.string "FTPbase", limit: 128
    t.string "HTTPbase", limit: 128
    t.index ["SITEID"], name: "SITEID"
  end

  create_table "TRAK", primary_key: "TRAKID", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "COMPID"
    t.integer "SONGID"
    t.string "Song"
    t.integer "Disc", limit: 1, default: 0
    t.string "Side", limit: 1
    t.integer "Seq", limit: 1, default: 0
    t.string "Time", limit: 6
    t.string "VersionNotes", limit: 64
    t.boolean "Hidden", default: false
    t.index ["Disc"], name: "Disc"
    t.index ["SONGID"], name: "SONGID"
    t.index ["Seq"], name: "Seq"
    t.index ["Side"], name: "Side"
  end

  create_table "VENUE", primary_key: "VENUEID", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "Name", limit: 48
    t.string "City", limit: 50
    t.string "State", limit: 50
    t.string "Country", limit: 50
    t.boolean "TaperFriendly", default: false
    t.boolean "Radio", default: false
    t.string "NameSearch", limit: 48
    t.string "SubCity"
    t.text "Notes"
    t.index ["Name"], name: "Name"
    t.index ["NameSearch"], name: "NameSearch"
  end

  create_table "XREF", primary_key: "XREFID", id: :string, limit: 12, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "XLINK", limit: 32
    t.string "XTEXT"
    t.index ["XREFID"], name: "XREFID"
  end

  create_table "gigmedia", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "GIGID"
    t.string "title"
    t.string "mediaid"
    t.integer "mediatype", limit: 2
    t.integer "showplaylist", limit: 1, default: 0
    t.integer "Chrono", default: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "performances", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
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

  create_table "song", primary_key: "SONGID", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "Song", null: false
    t.string "Prefix", limit: 16
    t.string "Versions", limit: 50
    t.string "Band", limit: 32
    t.integer "MUSOID", default: 0
    t.integer "GIGID", default: 0
    t.string "Author"
    t.string "OrigBand", limit: 128
    t.string "AltTitles", limit: 64
    t.boolean "Improvised", default: false
    t.integer "MAJRID", default: 0
    t.datetime "ApproxDate"
    t.text "Lyrics", limit: 4294967295
    t.text "Tab", limit: 4294967295
    t.text "Comments", limit: 4294967295
    t.text "RHComments", limit: 4294967295
    t.string "CoveredBy", limit: 32
    t.string "Instrumentation", limit: 32
    t.integer "SongLookup", default: 0
    t.string "MP3Site", limit: 4
    t.string "MP3File", limit: 64
    t.string "lyrics_ref"
    t.boolean "show_lyrics", default: false
    t.index ["MAJRID"], name: "MAJRID"
    t.index ["MUSOID"], name: "MUSOID"
    t.index ["Song"], name: "Song"
  end

  create_table "song_performances", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "song_id"
    t.integer "performance_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["performance_id"], name: "index_song_performances_on_performance_id"
    t.index ["song_id"], name: "index_song_performances_on_song_id"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
