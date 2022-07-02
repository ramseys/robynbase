module GigHelper

  def gig_song_details(gig_song)

    out = ""
    
    if gig_song.song.present?

      # original band
      if gig_song.song.OrigBand.present? 
        out += "<span class='subsidiary-info'> <small>#{gig_song.song.OrigBand}</small> </span>"

      # author (if not robyn)  
      elsif gig_song.song.Author.present? 
        out += "<span class='subsidiary-info'> <small>#{gig_song.song.Author}</small> </span>"
      end
      
    end

    # includes segue marker
    if gig_song.VersionNotes.present?
      out += "<span class='gig-song-version-notes text-success'> <small>#{gig_song.VersionNotes}</small> </span>"
    end

    out.html_safe

  end 

  def gig_set_has_media(gig_set) 
    gig_set.any? { |gig_song| gig_song.MediaLink.present? }
  end

  def gig_media_embed_height(gig_medium)

    case gig_medium.mediatype
      
      when GigMedium::MEDIA_TYPE["ArchiveOrgPlaylist"]
        230
        
      when GigMedium::MEDIA_TYPE["ArchiveOrgVideo"]
        480
        
      else
        480
      
    end

  end

end
