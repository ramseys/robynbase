class Track < ApplicationRecord
  self.table_name = "TRAK"

  belongs_to :composition, foreign_key: "COMPID", inverse_of: :tracks
  belongs_to :song, foreign_key: "SONGID", optional: true

  # using the numericality check because a Track.new will default to 0 if SONGID is not specified
  validates :SONGID, numericality: { greater_than: 0 }, unless: -> { self[:Song].present? }

end
