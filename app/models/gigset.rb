class Gigset < ApplicationRecord
  self.table_name = "GSET"

  belongs_to :gig, foreign_key: "GIGID", inverse_of: :gigsets
  belongs_to :song, foreign_key: "SONGID", optional: true

  validates :SONGID, presence: true

end