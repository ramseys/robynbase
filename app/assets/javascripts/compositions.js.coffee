# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(window).on("load", (e) ->

  # set up album art lightbox
  $("a.image-gallery").attr("rel", "gallery").fancybox({helpers : { 
    thumbs : {
      width  : 50,
      height : 50
    }
  }})

  # hide/show album blocks
  $(".album-block-header").on("click", (e) -> 
    albumHeader = $(e.target).parents(".album-block-header");
    albumBlock = $(".album-block-container[data-compid=" + albumHeader.data("compid") + "]")
    albumBlock.toggle()
    albumHeader.find(".glyphicon").toggleClass("glyphicon-triangle-right glyphicon-triangle-bottom")
  )

  # hide show advanced options in list page
  $(".album-list .advanced-options-header").on("click", (e) ->
    header = $(e.target).parents(".advanced-options-header")
    criteriaBlock = header.next();
    criteriaBlock.toggleClass("expanded");
    header.find(".glyphicon").toggleClass("glyphicon-triangle-right glyphicon-triangle-bottom")
  )

)

# Adds a song selection dropdown, containing all available songs
addSongSelector = (parent, index) ->

  # grab another song selector from elsewhere on the page and make a copy
  referenceSelector = $("#template-song-selector")
  selectorCopy = referenceSelector.clone()

  # configure for the current index
  selectorCopy.attr("name", "composition[tracks_attributes][#{index}][SONGID]")
  selectorCopy.attr("id", "composition_tracks_attributes_#{index}_SONGID")
  selectorCopy.val("")

  parent.append(selectorCopy)


window.removeCompositionTableRow = (tableId, rowId) ->
  row = $("##{tableId} tr[data-row=#{rowId}]");
  identifier = row.next("input")

  row.remove()
  identifier.remove()


songIndex = 100

window.addCompositionTableRow = (tableId, bonus) ->

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
                   name="composition[tracks_attributes][#{songIndex}][Seq]" 
                   id="composition_tracks_attributes_#{songIndex}_Seq">
        </td>
        <td></td>
        <td>
            <input class="form-control" type="text" value="" 
                   name="composition[tracks_attributes][#{songIndex}][Song]" 
                   id="composition_tracks_attributes_#{songIndex}_Song">
        </td>
        <td>
            <input class="form-control" type="text" 
                   name="composition[tracks_attributes][#{songIndex}][VersionNotes]" 
                   id="composition_tracks_attributes_#{songIndex}_VersionNotes">
            <input type="hidden" 
                   value="#{bonus}" 
                   name="composition[tracks_attributes][#{songIndex}][bonus]" 
                   id="composition_tracks_attributes_#{songIndex}_bonus">

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