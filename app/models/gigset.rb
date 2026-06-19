class Gigset < ApplicationRecord
  include Auditable

  self.table_name = "GSET"

  belongs_to :gig, foreign_key: "GIGID", inverse_of: :gigsets
  belongs_to :song, foreign_key: "SONGID", optional: true

  audited

  # using the numericality check because a Gigset.new will default to 0 if SONGID is not specified
  validates :SONGID, numericality: { greater_than: 0 }, unless: -> { self[:Song].present? }

  # Concise label within the parent gig's audit detail.
  def audit_name
    "Setlist: #{self.Song.presence || song&.full_name || "(unknown song)"}"
  end

end
