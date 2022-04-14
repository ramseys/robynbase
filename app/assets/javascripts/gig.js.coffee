# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


$(window).on("DOMContentLoaded", (e) ->

  # hide show advanced options in list page
  $(".gig-list .advanced-options-header").on("click", (e) ->
    header = $(e.target).parents(".advanced-options-header")
    criteriaBlock = header.next();
    criteriaBlock.toggleClass("expanded");
    header.find(".glyphicon").toggleClass("glyphicon-triangle-right glyphicon-triangle-bottom")
  )

  # set up gig images lightbox
  $("a.gig-images").attr("rel", "gallery").fancybox({helpers : { 
    thumbs : {
      width  : 50,
      height : 50
    }
  }})

)


# Adds a song selection dropdown, containing all available songs
addSongSelector = (parent, index) ->

  # grab another song selector from elsewhere on the page and make a copy
  referenceSelector = $("#template-song-selector")
  selectorCopy = referenceSelector.clone()

  # configure for the current index
  selectorCopy.attr("name", "gig[gigsets_attributes][#{index}][SONGID]")
  selectorCopy.attr("id", "gig_gigsets_attributes_#{index}_SONGID")
  selectorCopy.val("")

  parent.append(selectorCopy)


window.removeTableRow = (tableId, rowId) ->
  row = $("##{tableId} tr[data-row=#{rowId}]");
  identifier = row.next("input")

  row.remove()
  identifier.remove()


songIndex = 100

window.addTableRow = (tableId, encore) ->

  maxSequence = 0;

  # find largest order index
  $("##{tableId} tr").each((index, row) ->
    sequence = $(row).find("td:first input").val();
    maxSequence = Math.max(maxSequence, sequence) if sequence
  )
      

  newRow = $("""
    <tr data-row="#{songIndex}">
        <td>
            <input class="form-control" size="3" type="text" 
                   value="#{maxSequence + 1}" 
                   name="gig[gigsets_attributes][#{songIndex}][Chrono]" 
                   id="gig_gigsets_attributes_#{songIndex}_Chrono">
        </td>
        <td></td>
        <td>
            <input class="form-control" type="text" value="" 
                   name="gig[gigsets_attributes][#{songIndex}][Song]" 
                   id="gig_gigsets_attributes_#{songIndex}_Song">
        </td>
        <td>
            <input class="form-control" type="text" 
                   name="gig[gigsets_attributes][#{songIndex}][VersionNotes]" 
                   id="gig_gigsets_attributes_#{songIndex}_VersionNotes">
            <input type="hidden" 
                   value="#{encore}" 
                   name="gig[gigsets_attributes][#{songIndex}][Encore]" 
                   id="gig_gigsets_attributes_#{songIndex}_Encore">
        </td>
        <td>
            <input class="form-control" type="text" value="" 
                   name="gig[gigsets_attributes][#{songIndex}][MediaLink]" 
                   id="gig_gigsets_attributes_#{songIndex}_MediaLink">
        </td>

        <td> 
            <button type="button" onclick="removeTableRow('#{tableId}', #{songIndex})">
                Remove
            </button>
        </td>
    </tr>
  """)

  $("##{tableId}").append(newRow)

  songSelectorCell = newRow.find("td:nth(1)")

  addSongSelector(songSelectorCell, songIndex)

  songIndex++


mediaIndex = 100

window.addMediaTableRow = (tableId) ->

  maxSequence = 0;

  # find largest order index
  $("##{tableId} tr").each((index, row) ->
    sequence = $(row).find("td:first input").val();
    maxSequence = Math.max(maxSequence, sequence) if sequence
  )
      

  newRow = $("""
    <tr data-row="#{mediaIndex}">
        <td>
            <input class="form-control" size="3" type="text" 
                   value="#{maxSequence + 1}" 
                   name="gig[gigmedia_attributes][#{mediaIndex}][Chrono]" 
                   id="gig_gigmedia_attributes_#{mediaIndex}_Chrono">
        </td>
        <td>
            <input class="form-control" type="text" 
                   name="gig[gigmedia_attributes][#{mediaIndex}][title]" 
                   id="gig_gigmedia_attributes_#{mediaIndex}_title">
        </td>
        <td>
            <input class="form-control" type="text" 
                   name="gig[gigmedia_attributes][#{mediaIndex}][mediaid]" 
                   id="gig_gigmedia_attributes_#{mediaIndex}_mediaid">
        </td>

        <td>
          <select class="form-control song-selector"
                  id="gig_gigmedia_attributes_#{mediaIndex}_mediatype" 
                  name="gig[gigmedia_attributes][#{mediaIndex}][mediatype]">              
              <option value="1">YouTube</option>
              <option value="2">Archive.org Video</option>
              <option value="4">Archive.org Audio</option>
              <option value="3">Archive.org Playlist</option>
              <option value="5">Vimeo</option>
              <option value="6">Soundcloud</option>
          </select>
        </td>

        <td> 
            <button type="button" onclick="removeTableRow('#{tableId}', #{mediaIndex})">
                Remove
            </button>
        </td>
    </tr>
  """)

  $("##{tableId}").append(newRow)

  mediaIndex++