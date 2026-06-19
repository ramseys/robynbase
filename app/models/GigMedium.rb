class GigMedium < ApplicationRecord
    include Auditable

    self.table_name = "gigmedia"

    belongs_to :gig, foreign_key: "GIGID", inverse_of: :gigmedia

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
