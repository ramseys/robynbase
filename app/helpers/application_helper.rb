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

    # Tags a link to a show page with the search that produced it, so the show page
    # can offer Prev/Next/Back through that result set. A blank search_back (the
    # `for_resource` embedded tables, which are not searches) leaves the path alone.
    def with_search_back(path, search_back)
        search_back.present? ? "#{path}?search_back=#{CGI.escape(search_back)}" : path
    end

    # Carries the search an edit page was reached from through the form submission,
    # so update can return to the show page with its Prev/Next/Back intact. Renders
    # nothing when the edit page wasn't reached from a search.
    def search_back_field
        hidden_field_tag(:search_back, params[:search_back]) if params[:search_back].present?
    end

    # Bootstrap's is-invalid class for a form field whose validation error is recorded
    # under a different attribute than the one the field edits, so field_error_proc
    # (config/initializers/field_error_proc.rb) can't flag it: e.g. the gig's VENUEID
    # select (error on the :venue association) or the song's full_name field (error on
    # :Song). Fields whose names match their errors need nothing extra.
    def invalid_class_for(record, attribute)
        "is-invalid" if record.errors.include?(attribute)
    end

    # Opening <tr> for a nested row (setlist, track or media) in the gig/release forms.
    # A row the user removed before a failed save comes back hidden and still marked
    # with _destroy, as the Stimulus removeTableRow leaves it, so the removal is kept
    # when the re-rendered form is submitted again.
    def nested_form_row_tag(row_fields, sequence_index, &block)
        removed = row_fields.object.marked_for_destruction?
        content_tag(:tr, data: { row: sequence_index }, style: ("display: none" if removed)) do
            safe_join([(row_fields.hidden_field(:_destroy, value: "1") if removed), capture(&block)])
        end
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
