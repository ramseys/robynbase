// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(window).on("load", function(e) {

  // set up album art lightbox
  $("a.image-gallery").attr("rel", "gallery").fancybox({helpers : { 
    thumbs : {
      width  : 50,
      height : 50
    }
  }});

  // hide/show album blocks
  $(".album-block-header").on("click", function(e) { 
    const albumHeader = $(e.target).parents(".album-block-header");
    const albumBlock = $(".album-block-container[data-compid=" + albumHeader.data("compid") + "]");
    albumBlock.toggle();
    albumHeader.find(".advanced-options-disclosure").toggleClass("bi-caret-right-fill bi-caret-down-fill");
  });

  // hide show advanced options in list page
  $(".album-list .advanced-options-header").on("click", function(e) {
    console.log("hello!");
    const header = $(e.target).parents(".advanced-options-header");
    const criteriaBlock = header.next();
    criteriaBlock.toggleClass("expanded");
    header.find(".advanced-options-disclosure").toggleClass("bi-caret-right-fill bi-caret-down-fill");
  });

});

// Adds a song selection dropdown, containing all available songs
const addCompositionSongSelector = function(parent, index) {

  // grab another song selector from elsewhere on the page and make a copy
  const referenceSelector = $("#template-song-selector");
  const selectorCopy = referenceSelector.clone();

  // configure for the current index
  selectorCopy.attr("name", `composition[tracks_attributes][${index}][SONGID]`);
  selectorCopy.attr("id", `composition_tracks_attributes_${index}_SONGID`);
  selectorCopy.val("");

  parent.append(selectorCopy);

};


window.removeCompositionTableRow = function(tableId, rowId) {
  const row = $(`#${tableId} tr[data-row=${rowId}]`);
  const identifier = row.next("input");

  row.remove();
  identifier.remove();

};


let compositionSongIndex = 100;

window.addCompositionTableRow = function(tableId, bonus) {

  let maxSequence = 0;

  // find largest order index
  $(`#${tableId} tr`).each(function(index, row) {
    const sequence = $(row).find("td:first input").val();
    if (sequence) { return maxSequence = Math.max(maxSequence, sequence); }
  });
      

  const newRow = $(`\
<tr data-row="${compositionSongIndex}">
    <td>
        <input class="form-control" size="3" type="text" 
               value="${maxSequence + 1}" 
               name="composition[tracks_attributes][${compositionSongIndex}][Seq]" 
               id="composition_tracks_attributes_${compositionSongIndex}_Seq">
    </td>
    <td></td>
    <td>
        <input class="form-control" type="text" value="" 
               name="composition[tracks_attributes][${compositionSongIndex}][Song]" 
               id="composition_tracks_attributes_${compositionSongIndex}_Song">
    </td>
    <td>
        <input class="form-control" type="text" 
               name="composition[tracks_attributes][${compositionSongIndex}][VersionNotes]" 
               id="composition_tracks_attributes_${compositionSongIndex}_VersionNotes">
        <input type="hidden" 
               value="${bonus}" 
               name="composition[tracks_attributes][${compositionSongIndex}][bonus]" 
               id="composition_tracks_attributes_${compositionSongIndex}_bonus">

    </td>
    <td> 
        <button type="button" onclick="removeTableRow('${tableId}', ${compositionSongIndex})">
            Remove
        </button>
    </td>
</tr>\
`);

  $(`#${tableId}`).append(newRow);

  const songSelectorCell = newRow.find("td:nth(1)");

  addCompositionSongSelector(songSelectorCell, compositionSongIndex);

  compositionSongIndex++;

};