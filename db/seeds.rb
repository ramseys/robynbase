# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# ── Venues ──────────────────────────────────────────────────────────────────

venues = Venue.create!([
  {
    Name: "Town and Country Club",
    City: "London",
    Country: "England",
    latitude: 51.5549,
    longitude: -0.1082,
    street_address1: "9-17 Highgate Road"
  },
  {
    Name: "The Fillmore",
    City: "San Francisco",
    State: "CA",
    Country: "USA",
    latitude: 37.7842,
    longitude: -122.4330,
    street_address1: "1805 Geary Blvd"
  },
  {
    Name: "9:30 Club",
    City: "Washington",
    State: "DC",
    Country: "USA",
    latitude: 38.9172,
    longitude: -77.0230,
    street_address1: "815 V St NW"
  },
  {
    Name: "The Troubadour",
    City: "Los Angeles",
    State: "CA",
    Country: "USA",
    latitude: 34.0808,
    longitude: -118.3867,
    street_address1: "9081 Santa Monica Blvd"
  },
  {
    Name: "The Barley Mow",
    City: "London",
    Country: "England",
    Notes: "Intimate venue in Islington, hosted many acoustic sets"
  },
  {
    Name: "Sydney Opera House",
    City: "Sydney",
    State: "NSW",
    Country: "Australia",
    latitude: -33.8568,
    longitude: 151.2153
  }
])

town_country = venues[0]
fillmore     = venues[1]
nine_thirty  = venues[2]
troubadour   = venues[3]
barley_mow   = venues[4]
sydney_oh    = venues[5]

# ── Songs ────────────────────────────────────────────────────────────────────

songs = Song.create!([
  { Song: "Balloon Man",         Prefix: nil,  Author: nil },
  { Song: "So You Think You're in Love", Prefix: nil, Author: nil },
  { Song: "Glass Hotel",         Prefix: nil,  Author: nil },
  { Song: "Cynthia Mask",        Prefix: nil,  Author: nil },
  { Song: "Listening to the Higsons", Prefix: nil, Author: nil },
  { Song: "Madonna of the Wasps", Prefix: nil, Author: nil },
  { Song: "Flesh Number One",    Prefix: nil,  Author: nil, Versions: "Beatle Dennis" },
  { Song: "She Doesn't Exist",   Prefix: nil,  Author: nil },
  { Song: "Vibrating",           Prefix: nil,  Author: nil },
  { Song: "Wading Through Treacle", Prefix: nil, Author: nil },
  { Song: "Chinese Bones",       Prefix: nil,  Author: nil },
  { Song: "Atmosphere",          Prefix: nil,  Author: "Ian Curtis / Joy Division", OrigBand: "Joy Division" },
  { Song: "Psychedelic Warlords", Prefix: "The", Author: "Dave Brock", OrigBand: "Hawkwind" },
  { Song: "Arms of Love",        Prefix: nil,  Author: nil },
  { Song: "Heaven",              Prefix: nil,  Author: "David Byrne / Jerry Harrison / Chris Frantz / Tina Weymouth", OrigBand: "Talking Heads" },
])

balloon_man      = songs[0]
so_you_think     = songs[1]
glass_hotel      = songs[2]
cynthia_mask     = songs[3]
higsons          = songs[4]
madonna          = songs[5]
flesh_number_one = songs[6]
she_doesnt_exist = songs[7]
vibrating        = songs[8]
wading           = songs[9]
chinese_bones    = songs[10]
atmosphere       = songs[11]
warlords         = songs[12]
arms_of_love     = songs[13]
heaven           = songs[14]

# ── Compositions (Releases) ──────────────────────────────────────────────────

comps = Composition.create!([
  {
    Artist: "Robyn Hitchcock and the Egyptians",
    Title:  "Globe of Frogs",
    Year:   1988,
    Type:   "Album",
    Medium: "CD",
    Label:  "A&M Records",
    CatNo:  "AMA 5182"
  },
  {
    Artist: "Robyn Hitchcock and the Egyptians",
    Title:  "Queen Elvis",
    Year:   1989,
    Type:   "Album",
    Medium: "CD",
    Label:  "A&M Records",
    CatNo:  "395 284-2"
  },
  {
    Artist: "Robyn Hitchcock",
    Title:  "Eye",
    Year:   1990,
    Type:   "Album",
    Medium: "CD",
    Label:  "Twin/Tone Records",
    CatNo:  "TTR 89152-2"
  },
  {
    Artist: "Robyn Hitchcock",
    Title:  "Balloon Man",
    Year:   1990,
    Type:   "Single",
    Medium: "7\"",
    Label:  "A&M Records",
    CatNo:  "AM 556"
  },
  {
    Artist: "Robyn Hitchcock and the Egyptians",
    Title:  "Perspex Island",
    Year:   1991,
    Type:   "Album",
    Medium: "CD",
    Label:  "A&M Records",
    CatNo:  "395 351-2"
  }
])

globe_of_frogs  = comps[0]
queen_elvis     = comps[1]
eye_album       = comps[2]
balloon_single  = comps[3]
perspex_island  = comps[4]

# ── Tracks ───────────────────────────────────────────────────────────────────

Track.create!([
  # Globe of Frogs
  { COMPID: globe_of_frogs.COMPID, SONGID: balloon_man.SONGID,      Song: balloon_man.Song,      Seq: 1,  Disc: 0, Side: "A" },
  { COMPID: globe_of_frogs.COMPID, SONGID: so_you_think.SONGID,     Song: so_you_think.Song,     Seq: 2,  Disc: 0, Side: "A" },
  { COMPID: globe_of_frogs.COMPID, SONGID: glass_hotel.SONGID,      Song: glass_hotel.Song,      Seq: 3,  Disc: 0, Side: "A" },
  { COMPID: globe_of_frogs.COMPID, SONGID: flesh_number_one.SONGID, Song: flesh_number_one.Song, Seq: 4,  Disc: 0, Side: "A" },
  { COMPID: globe_of_frogs.COMPID, SONGID: madonna.SONGID,          Song: madonna.Song,          Seq: 5,  Disc: 0, Side: "B" },
  { COMPID: globe_of_frogs.COMPID, SONGID: chinese_bones.SONGID,    Song: chinese_bones.Song,    Seq: 6,  Disc: 0, Side: "B" },

  # Queen Elvis
  { COMPID: queen_elvis.COMPID, SONGID: cynthia_mask.SONGID,     Song: cynthia_mask.Song,     Seq: 1, Disc: 0, Side: "A" },
  { COMPID: queen_elvis.COMPID, SONGID: she_doesnt_exist.SONGID, Song: she_doesnt_exist.Song, Seq: 2, Disc: 0, Side: "A" },
  { COMPID: queen_elvis.COMPID, SONGID: vibrating.SONGID,        Song: vibrating.Song,        Seq: 3, Disc: 0, Side: "A" },
  { COMPID: queen_elvis.COMPID, SONGID: arms_of_love.SONGID,     Song: arms_of_love.Song,     Seq: 4, Disc: 0, Side: "B" },

  # Eye
  { COMPID: eye_album.COMPID, SONGID: wading.SONGID,    Song: wading.Song,    Seq: 1, Disc: 0, Side: "A" },
  { COMPID: eye_album.COMPID, SONGID: higsons.SONGID,   Song: higsons.Song,   Seq: 2, Disc: 0, Side: "A" },
  { COMPID: eye_album.COMPID, SONGID: atmosphere.SONGID, Song: atmosphere.Song, Seq: 3, Disc: 0, Side: "B" },

  # Balloon Man single
  { COMPID: balloon_single.COMPID, SONGID: balloon_man.SONGID, Song: balloon_man.Song, Seq: 1, Disc: 0, Side: "A" },
  { COMPID: balloon_single.COMPID, SONGID: warlords.SONGID,    Song: warlords.Song,    Seq: 2, Disc: 0, Side: "B" },

  # Perspex Island
  { COMPID: perspex_island.COMPID, SONGID: so_you_think.SONGID, Song: so_you_think.Song, Seq: 1, Disc: 0, Side: "A" },
  { COMPID: perspex_island.COMPID, SONGID: madonna.SONGID,      Song: madonna.Song,      Seq: 2, Disc: 0, Side: "A" },
  { COMPID: perspex_island.COMPID, SONGID: heaven.SONGID,       Song: heaven.Song,       Seq: 3, Disc: 0, Side: "B", bonus: true },
])

# ── Gigs ─────────────────────────────────────────────────────────────────────

gigs = Gig.create!([
  {
    BilledAs: "Robyn Hitchcock and the Egyptians",
    VENUEID:  town_country.VENUEID,
    Venue:    town_country.Name,
    GigDate:  "1988-04-15",
    GigYear:  "1988",
    GigType:  "Concert"
  },
  {
    BilledAs: "Robyn Hitchcock and the Egyptians",
    VENUEID:  fillmore.VENUEID,
    Venue:    fillmore.Name,
    GigDate:  "1988-06-22",
    GigYear:  "1988",
    GigType:  "Concert",
    Reviews:  "A spellbinding evening at the Fillmore. Hitchcock was in fine form, his between-song banter as entertaining as the songs themselves."
  },
  {
    BilledAs: "Robyn Hitchcock and the Egyptians",
    VENUEID:  nine_thirty.VENUEID,
    Venue:    nine_thirty.Name,
    GigDate:  "1989-09-08",
    GigYear:  "1989",
    GigType:  "Concert"
  },
  {
    BilledAs: "Robyn Hitchcock",
    VENUEID:  barley_mow.VENUEID,
    Venue:    barley_mow.Name,
    GigDate:  "1990-03-12",
    GigYear:  "1990",
    GigType:  "Concert",
    ShortNote: "Solo acoustic show",
    Reviews:   "An intimate solo performance — just Robyn and his guitar in a small room. Stunning versions of Balloon Man and Chinese Bones."
  },
  {
    BilledAs: "Robyn Hitchcock and the Egyptians",
    VENUEID:  troubadour.VENUEID,
    Venue:    troubadour.Name,
    GigDate:  "1991-07-04",
    GigYear:  "1991",
    GigType:  "Concert",
    Guests:   "Peter Buck (R.E.M.)"
  },
  {
    BilledAs: "Robyn Hitchcock",
    VENUEID:  sydney_oh.VENUEID,
    Venue:    sydney_oh.Name,
    GigDate:  "1992-02-20",
    GigYear:  "1992",
    GigType:  "Concert",
    Circa:    false
  },
  {
    BilledAs: "Robyn Hitchcock",
    VENUEID:  nine_thirty.VENUEID,
    Venue:    nine_thirty.Name,
    GigDate:  "1993-11-05",
    GigYear:  "1993",
    GigType:  "Concert",
    cancelled: true,
    ShortNote: "Cancelled due to illness"
  }
])

london_88     = gigs[0]
fillmore_88   = gigs[1]
dc_89         = gigs[2]
barley_90     = gigs[3]
troubadour_91 = gigs[4]
sydney_92     = gigs[5]
dc_93         = gigs[6]  # cancelled

# ── Setlists (Gigsets) ───────────────────────────────────────────────────────

Gigset.create!([
  # London, Town and Country, 1988
  { GIGID: london_88.GIGID, SONGID: balloon_man.SONGID,      Song: balloon_man.Song,      Chrono: 10, Encore: false },
  { GIGID: london_88.GIGID, SONGID: so_you_think.SONGID,     Song: so_you_think.Song,     Chrono: 20, Encore: false },
  { GIGID: london_88.GIGID, SONGID: glass_hotel.SONGID,      Song: glass_hotel.Song,      Chrono: 30, Encore: false },
  { GIGID: london_88.GIGID, SONGID: flesh_number_one.SONGID, Song: flesh_number_one.Song, Chrono: 40, Encore: false },
  { GIGID: london_88.GIGID, SONGID: madonna.SONGID,          Song: madonna.Song,          Chrono: 50, Encore: false },
  { GIGID: london_88.GIGID, SONGID: chinese_bones.SONGID,    Song: chinese_bones.Song,    Chrono: 60, Encore: true  },
  { GIGID: london_88.GIGID, SONGID: warlords.SONGID,         Song: warlords.Song,         Chrono: 70, Encore: true  },

  # Fillmore, 1988
  { GIGID: fillmore_88.GIGID, SONGID: cynthia_mask.SONGID,     Song: cynthia_mask.Song,     Chrono: 10, Encore: false },
  { GIGID: fillmore_88.GIGID, SONGID: balloon_man.SONGID,      Song: balloon_man.Song,      Chrono: 20, Encore: false },
  { GIGID: fillmore_88.GIGID, SONGID: flesh_number_one.SONGID, Song: flesh_number_one.Song, Chrono: 30, Encore: false },
  { GIGID: fillmore_88.GIGID, SONGID: glass_hotel.SONGID,      Song: glass_hotel.Song,      Chrono: 40, Encore: false },
  { GIGID: fillmore_88.GIGID, SONGID: higsons.SONGID,          Song: higsons.Song,          Chrono: 50, Encore: false },
  { GIGID: fillmore_88.GIGID, SONGID: chinese_bones.SONGID,    Song: chinese_bones.Song,    Chrono: 60, Encore: true  },

  # DC, 9:30 Club, 1989
  { GIGID: dc_89.GIGID, SONGID: cynthia_mask.SONGID,     Song: cynthia_mask.Song,     Chrono: 10, Encore: false },
  { GIGID: dc_89.GIGID, SONGID: she_doesnt_exist.SONGID, Song: she_doesnt_exist.Song, Chrono: 20, Encore: false },
  { GIGID: dc_89.GIGID, SONGID: vibrating.SONGID,        Song: vibrating.Song,        Chrono: 30, Encore: false },
  { GIGID: dc_89.GIGID, SONGID: arms_of_love.SONGID,     Song: arms_of_love.Song,     Chrono: 40, Encore: false },
  { GIGID: dc_89.GIGID, SONGID: balloon_man.SONGID,      Song: balloon_man.Song,      Chrono: 50, Encore: false },
  { GIGID: dc_89.GIGID, SONGID: madonna.SONGID,          Song: madonna.Song,          Chrono: 60, Encore: true  },
  { GIGID: dc_89.GIGID, SONGID: atmosphere.SONGID,       Song: atmosphere.Song,       Chrono: 70, Encore: true  },

  # Barley Mow, 1990 (solo acoustic)
  { GIGID: barley_90.GIGID, SONGID: balloon_man.SONGID,   Song: balloon_man.Song,   Chrono: 10, Encore: false },
  { GIGID: barley_90.GIGID, SONGID: chinese_bones.SONGID, Song: chinese_bones.Song, Chrono: 20, Encore: false },
  { GIGID: barley_90.GIGID, SONGID: madonna.SONGID,       Song: madonna.Song,       Chrono: 30, Encore: false },
  { GIGID: barley_90.GIGID, SONGID: wading.SONGID,        Song: wading.Song,        Chrono: 40, Encore: false },
  { GIGID: barley_90.GIGID, SONGID: glass_hotel.SONGID,   Song: glass_hotel.Song,   Chrono: 50, Encore: true  },

  # Troubadour, 1991 (w/ Peter Buck)
  { GIGID: troubadour_91.GIGID, SONGID: so_you_think.SONGID,  Song: so_you_think.Song,  Chrono: 10, Encore: false },
  { GIGID: troubadour_91.GIGID, SONGID: madonna.SONGID,       Song: madonna.Song,       Chrono: 20, Encore: false },
  { GIGID: troubadour_91.GIGID, SONGID: arms_of_love.SONGID,  Song: arms_of_love.Song,  Chrono: 30, Encore: false },
  { GIGID: troubadour_91.GIGID, SONGID: balloon_man.SONGID,   Song: balloon_man.Song,   Chrono: 40, Encore: false },
  { GIGID: troubadour_91.GIGID, SONGID: heaven.SONGID,        Song: heaven.Song,        Chrono: 50, Encore: true  },

  # Sydney, 1992
  { GIGID: sydney_92.GIGID, SONGID: balloon_man.SONGID,      Song: balloon_man.Song,      Chrono: 10, Encore: false },
  { GIGID: sydney_92.GIGID, SONGID: cynthia_mask.SONGID,     Song: cynthia_mask.Song,     Chrono: 20, Encore: false },
  { GIGID: sydney_92.GIGID, SONGID: vibrating.SONGID,        Song: vibrating.Song,        Chrono: 30, Encore: false },
  { GIGID: sydney_92.GIGID, SONGID: flesh_number_one.SONGID, Song: flesh_number_one.Song, Chrono: 40, Encore: false },
  { GIGID: sydney_92.GIGID, SONGID: she_doesnt_exist.SONGID, Song: she_doesnt_exist.Song, Chrono: 50, Encore: true  },
  { GIGID: sydney_92.GIGID, SONGID: warlords.SONGID,         Song: warlords.Song,         Chrono: 60, Encore: true  },
])

puts "Seeded:"
puts "  #{Venue.count} venues"
puts "  #{Song.count} songs"
puts "  #{Composition.count} compositions"
puts "  #{Track.count} tracks"
puts "  #{Gig.count} gigs"
puts "  #{Gigset.count} gigset entries"
