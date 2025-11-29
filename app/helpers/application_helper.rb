module ApplicationHelper
    include Pagy::Frontend

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

    # Renders a sortable column header.
    
    #  1. Up/down icons to indicate sort direction
    #  2, Clicking on the header sends a sort directive to the server
    def sortable_column_header(column, title, current_sort = nil, current_direction = nil, turbo_frame = "table_frame")
        direction = (current_sort == column && current_direction == 'asc') ? 'desc' : 'asc'

        sort_params = request.query_parameters.merge(sort: column, direction: direction)

        css_class = "sortable-header"
        css_class += " sorted-#{current_direction}" if current_sort == column

        icon = if current_sort == column
            current_direction == 'asc' ? 'bi-caret-up-fill' : 'bi-caret-down-fill'
        else
            'bi-caret-up-down'
        end

        # Build URL that preserves current path and parameters
        sort_url = url_for(sort_params.merge(only_path: true))

        # Disable Turbo prefetch on sort links to prevent unwanted cookie saves on hover
        # Sort links reload the same page with different data, so prefetching provides no benefit
        # and causes the controller to run (and potentially save sort cookies) on mere hover
        link_to(sort_url,
               class: css_class,
               data: { turbo_frame: turbo_frame, turbo_prefetch: false }) do
            "#{title} <i class='#{icon}' aria-hidden='true'></i>".html_safe
        end
    end
    
end
