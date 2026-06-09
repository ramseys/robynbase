class Gigset < ApplicationRecord
  self.table_name = "GSET"

  belongs_to :gig, foreign_key: "GIGID", inverse_of: :gigsets
  belongs_to :song, foreign_key: "SONGID", optional: true

  validates :SONGID, numericality: { greater_than: 0 }, unless: -> { self[:Song].present? }

end
