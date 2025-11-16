class Track < ApplicationRecord
  self.table_name = "TRAK"

  belongs_to :composition, foreign_key: "COMPID", counter_cache: true
  belongs_to :song, foreign_key: "SONGID", optional: true

end