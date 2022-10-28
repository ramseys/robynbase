module RobynHelper

    def on_this_day_blurb(gigs_on_this_day)

        selected_gig = gigs_on_this_day[rand(gigs_on_this_day.length)]

        venue = selected_gig.venue;
        location = ""

        location += venue.City            unless not venue.City.present? 
        location += ", #{venue.State}"    unless not venue.State.present? 

        if venue.Country.present?
            if location.empty?
                country = venue.Country
            else
                country = "(#{venue.Country})"
            end

            location += " #{country}"
        end

        setlist = selected_gig.get_set
        first_song = setlist.first;
        last_song = setlist.last;

        encore = selected_gig.get_set_encore

        text = %Q%<p>On this day in #{selected_gig.GigDate.year}, Robyn performed at 
               <b><a href="#{venue_url(venue.id)}">#{venue.Name}</a></b>, 
               #{location.empty? ? "" : "in #{location}"}.</p>%
    
        if setlist.present?

            if setlist.length > 1
                text = text + %Q%<p>He started the show with #{get_song_name(first_song)}, and ended with #{get_song_name(last_song)}.%
            else 
                text = text + %Q%<p>He played #{get_song_name(first_song)}.%
            end

            if encore.present? 
                text = text + " He also did an encore."
            end

            text += "</p>"

        end

        if selected_gig.Guests.present? and selected_gig.BilledAs == "Robyn Hitchcock"
            text += %Q%<p>He was joined by #{selected_gig.Guests}.</p>%
        end

        text = text + %Q%<p><a href="#{gig_url(selected_gig)}">More details here.</a></p>%

        text = text + %Q%<p><a href="#{gigs_url()}/quick_query?query_id=on_this_day">See all gigs on this day.</a></p>%

        text.html_safe

    end

    private

    def get_song_name(set_song) 
        if (set_song.song.present?) 
            %Q%<b><a href="#{song_url(set_song.song)}">#{set_song.Song}</a></b>%
        else
            "<b>#{set_song.Song}</b>"
        end
    end

end
