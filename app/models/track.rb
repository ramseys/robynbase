class Track < ApplicationRecord
  self.table_name = "TRAK"

  belongs_to :composition, foreign_key: "COMPID", inverse_of: :tracks
  belongs_to :song, foreign_key: "SONGID", optional: true

  validates :SONGID, presence: true

end