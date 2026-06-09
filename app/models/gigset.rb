class Gigset < ApplicationRecord
  self.table_name = "GSET"

  belongs_to :gig, foreign_key: "GIGID", inverse_of: :gigsets
  belongs_to :song, foreign_key: "SONGID", optional: true

  # using the numericality check because a Gigset.new will default to 0 if SONGID is not specified
  validates :SONGID, numericality: { greater_than: 0 }, unless: -> { self[:Song].present? }

end
