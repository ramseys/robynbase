module GigHelper

  def gig_set_has_media(gig_set) 
    gig_set.any? { |gig_song| gig_song.MediaLink.present? }
  end

  def gig_media_embed_height(gig_medium)

    case gig_medium.mediatype
      
      when GigMedium::MEDIA_TYPE["ArchiveOrgPlaylist"]
        380
        
      when GigMedium::MEDIA_TYPE["ArchiveOrgVideo"]
        480
        
      else
        480
      
    end

  end

end
