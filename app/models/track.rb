class Track < ApplicationRecord
  include Auditable

  self.table_name = "TRAK"

  belongs_to :composition, foreign_key: "COMPID", inverse_of: :tracks
  belongs_to :song, foreign_key: "SONGID", optional: true

  audited

  # using the numericality check because a Track.new will default to 0 if SONGID is not specified
  validates :SONGID, numericality: { greater_than: 0 }, unless: -> { self[:Song].present? }

  # Concise label within the parent composition's audit detail.
  def audit_name
    "Track: #{self.Song.presence || song&.full_name || "(unknown song)"}"
  end

end
