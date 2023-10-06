// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.


window.$(window).on("DOMContentLoaded", function(e) {

  // hide show advanced options in list page
  $(".gig-list .advanced-options-header").on("click", function(e) {
    const header = $(e.target).parents(".advanced-options-header");
    const criteriaBlock = header.next();
    criteriaBlock.toggleClass("expanded");
    return header.find(".advanced-options-disclosure").toggleClass("bi-caret-right-fill bi-caret-down-fill");
  });

  // debugger

  // set up gig images lightbox
  // $("a.gig-images").attr("rel", "gallery").fancybox();

  $().fancybox({
    selector : 'a.gig-images',
    loop: true
  });


  // Adds a song selection dropdown, containing all available songs
  const addGigSongSelector = function(parent, index) {

    // grab another song selector from elsewhere on the page and make a copy
    const referenceSelector = $("#template-song-selector");
    const selectorCopy = referenceSelector.clone();

    // configure for the current index
    selectorCopy.attr("name", `gig[gigsets_attributes][${index}][SONGID]`);
    selectorCopy.attr("id", `gig_gigsets_attributes_${index}_SONGID`);
    selectorCopy.val("");

    parent.append(selectorCopy);

  };


  window.removeTableRow = function(tableId, rowId) {
    const row = $(`#${tableId} tr[data-row=${rowId}]`);
    const identifier = row.next("input");

    row.remove();
    identifier.remove();

  };


  let gigSongIndex = 100;

  window.addTableRow = function(tableId, encore) {

    let maxSequence = 0;

    // find largest order index
    $(`#${tableId} tr`).each(function(index, row) {
      const sequence = $(row).find("td:first input").val();
      if (sequence) { return maxSequence = Math.max(maxSequence, sequence); }
    });
        

    const newRow = $(`\
  <tr data-row="${gigSongIndex}">
      <td>
          <input class="form-control" size="3" type="text" 
                value="${maxSequence + 1}" 
                name="gig[gigsets_attributes][${gigSongIndex}][Chrono]" 
                id="gig_gigsets_attributes_${gigSongIndex}_Chrono">
      </td>
      <td></td>
      <td>
          <input class="form-control" type="text" value="" 
                name="gig[gigsets_attributes][${gigSongIndex}][Song]" 
                id="gig_gigsets_attributes_${gigSongIndex}_Song">
      </td>
      <td>
          <input class="form-control" type="text" 
                name="gig[gigsets_attributes][${gigSongIndex}][VersionNotes]" 
                id="gig_gigsets_attributes_${gigSongIndex}_VersionNotes">
          <input type="hidden" 
                value="${encore}" 
                name="gig[gigsets_attributes][${gigSongIndex}][Encore]" 
                id="gig_gigsets_attributes_${gigSongIndex}_Encore">
      </td>
      <td>
          <input class="form-control" type="text" value="" 
                name="gig[gigsets_attributes][${gigSongIndex}][MediaLink]" 
                id="gig_gigsets_attributes_${gigSongIndex}_MediaLink">
      </td>

      <td> 
          <button class="btn btn-link" type="button" onclick="removeTableRow('${tableId}', ${gigSongIndex})">
              Remove
          </button>
      </td>
  </tr>\
  `);

    $(`#${tableId}`).append(newRow);

    const songSelectorCell = newRow.find("td:nth(1)");

    addGigSongSelector(songSelectorCell, gigSongIndex);

    gigSongIndex++;

  };


  let mediaIndex = 100;

  window.addMediaTableRow = function(tableId) {

    let maxSequence = 0;

    // find largest order index
    $(`#${tableId} tr`).each(function(index, row) {
      const sequence = $(row).find("td:first input").val();
      if (sequence) { return maxSequence = Math.max(maxSequence, sequence); }
    });
        

    const newRow = $(`\
  <tr data-row="${mediaIndex}">
      <td>
          <input class="form-control" size="3" type="text" 
                value="${maxSequence + 1}" 
                name="gig[gigmedia_attributes][${mediaIndex}][Chrono]" 
                id="gig_gigmedia_attributes_${mediaIndex}_Chrono">
      </td>
      <td>
          <input class="form-control" type="text" 
                name="gig[gigmedia_attributes][${mediaIndex}][title]" 
                id="gig_gigmedia_attributes_${mediaIndex}_title">
      </td>
      <td>
          <input class="form-control" type="text" 
                name="gig[gigmedia_attributes][${mediaIndex}][mediaid]" 
                id="gig_gigmedia_attributes_${mediaIndex}_mediaid">
      </td>

      <td>
        <select class="form-control song-selector"
                id="gig_gigmedia_attributes_${mediaIndex}_mediatype" 
                name="gig[gigmedia_attributes][${mediaIndex}][mediatype]">              
            <option value="1">YouTube</option>
            <option value="2">Archive.org Video</option>
            <option value="4">Archive.org Audio</option>
            <option selected="selected" value="3">Archive.org Playlist</option>
            <option value="5">Vimeo</option>
            <option value="6">Soundcloud</option>
        </select>
      </td>

      <td> 
          <button type="button" class="btn btn-link" onclick="removeTableRow('${tableId}', ${mediaIndex})">
              Remove
          </button>
      </td>
  </tr>\
  `);

    $(`#${tableId}`).append(newRow);

    mediaIndex++;

  };

});