module ApplicationHelper

    def song_details(song_info)

        out = ""
        
        if song_info.song.present?

            if song_info.song.Improvised?
                out += "<span class='improvised'> <small>Improvised</small> </span>"
            end

            # original band
            if song_info.song.OrigBand.present? 
                out += "<span class='subsidiary-info'> <small>#{song_info.song.OrigBand}</small> </span>"

            # author (if not robyn)  
            elsif song_info.song.Author.present? 
                out += "<span class='subsidiary-info'> <small>#{song_info.song.Author}</small> </span>"
            end
            
        end

        # includes segue marker
        if song_info.VersionNotes.present?
            out += "<span class='song-version-notes text-success'> <small>#{song_info.VersionNotes}</small> </span>"
        end

        out.html_safe
    
    end
    
end
