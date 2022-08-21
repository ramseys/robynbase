class Track < ApplicationRecord
  self.table_name = "TRAK"

  belongs_to :composition, foreign_key: "COMPID"
  belongs_to :song, foreign_key: "SONGID", optional: true

end