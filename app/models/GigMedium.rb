class GigMedium < ApplicationRecord

    self.table_name = "gigmedia"

    belongs_to :gig, foreign_key: "GIGID"

    MEDIA_TYPE = {
        "YouTube" => 1,
        "ArchiveOrgVideo" => 2,
        "ArchiveOrgPlaylist" => 3,
        "ArchiveOrgAudio" => 4,
        "Vimeo" => 5,
        "Soundcloud" => 6
    }

end
