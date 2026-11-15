class GigMedium < ApplicationRecord
    include Auditable

    self.table_name = "gigmedia"

    belongs_to :gig, foreign_key: "GIGID", inverse_of: :gigmedia

    # Every media row must identify its media. Checked here rather than in strong params
    # so a blank row re-renders the gig form with the user's input instead of a 400.
    validates :mediaid, presence: true

    audited

    MEDIA_TYPE = {
        "YouTube" => 1,
        "ArchiveOrgVideo" => 2,
        "ArchiveOrgPlaylist" => 3,
        "ArchiveOrgAudio" => 4,
        "Vimeo" => 5,
        "Soundcloud" => 6
    }

    # Concise label within the parent gig's audit detail.
    def audit_name
        "Media: #{self.title.presence || mediaid.presence || "(media)"}"
    end

end
