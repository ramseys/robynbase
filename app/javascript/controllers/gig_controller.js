import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["templateSongSelector"]

  connect() {
    this.gigSongIndex = 100
    this.mediaIndex = 100
  }

  toggleAdvancedOptions(event) {
    const header = event.target.closest(".advanced-options-header")
    const criteriaBlock = header.nextElementSibling
    if (criteriaBlock && criteriaBlock.classList.contains("advanced-options")) {
      criteriaBlock.classList.toggle("expanded")
      
      const disclosure = header.querySelector(".advanced-options-disclosure")
      if (disclosure) {
        disclosure.classList.toggle("bi-caret-right-fill")
        disclosure.classList.toggle("bi-caret-down-fill")
      }
    }
  }

  addSong(event) {
    const tableId = event.params.tableId
    const encore = event.params.encore || false
    this.addTableRow(tableId, encore)
  }

  addMedia(event) {
    const tableId = event.params.tableId
    this.addMediaTableRow(tableId)
  }

  removeRow(event) {
    const rowId = event.params.rowId
    const tableId = event.params.tableId
    this.removeTableRow(tableId, rowId)
  }

  addTableRow(tableId, encore) {
    let maxSequence = 0
    const table = document.getElementById(tableId)
    
    // Find largest order index
    table.querySelectorAll("tr").forEach(row => {
      const sequenceInput = row.querySelector("td:first-child input")
      if (sequenceInput && sequenceInput.value) {
        maxSequence = Math.max(maxSequence, parseInt(sequenceInput.value))
      }
    })

    const newRow = document.createElement("tr")
    newRow.dataset.row = this.gigSongIndex
    newRow.innerHTML = `
      <td>
          <input class="form-control" size="3" type="text" 
                value="${maxSequence + 1}" 
                name="gig[gigsets_attributes][${this.gigSongIndex}][Chrono]" 
                id="gig_gigsets_attributes_${this.gigSongIndex}_Chrono">
      </td>
      <td></td>
      <td>
          <input class="form-control" type="text" value="" 
                name="gig[gigsets_attributes][${this.gigSongIndex}][Song]" 
                id="gig_gigsets_attributes_${this.gigSongIndex}_Song">
      </td>
      <td>
          <input class="form-control" type="text" 
                name="gig[gigsets_attributes][${this.gigSongIndex}][VersionNotes]" 
                id="gig_gigsets_attributes_${this.gigSongIndex}_VersionNotes">
          <input type="hidden" 
                value="${encore}" 
                name="gig[gigsets_attributes][${this.gigSongIndex}][Encore]" 
                id="gig_gigsets_attributes_${this.gigSongIndex}_Encore">
      </td>
      <td>
          <input class="form-control" type="text" value="" 
                name="gig[gigsets_attributes][${this.gigSongIndex}][MediaLink]" 
                id="gig_gigsets_attributes_${this.gigSongIndex}_MediaLink">
      </td>
      <td> 
          <button class="btn btn-link" type="button" 
                  data-action="click->gig#removeRow"
                  data-gig-table-id-param="${tableId}"
                  data-gig-row-id-param="${this.gigSongIndex}">
              Remove
          </button>
      </td>
    `

    table.appendChild(newRow)

    const songSelectorCell = newRow.querySelector("td:nth-child(2)")
    this.addGigSongSelector(songSelectorCell, this.gigSongIndex)

    this.gigSongIndex++
  }

  addMediaTableRow(tableId) {
    let maxSequence = 0
    const table = document.getElementById(tableId)
    
    // Find largest order index
    table.querySelectorAll("tr").forEach(row => {
      const sequenceInput = row.querySelector("td:first-child input")
      if (sequenceInput && sequenceInput.value) {
        maxSequence = Math.max(maxSequence, parseInt(sequenceInput.value))
      }
    })

    const newRow = document.createElement("tr")
    newRow.dataset.row = this.mediaIndex
    newRow.innerHTML = `
      <td>
          <input class="form-control" size="3" type="text" 
                value="${maxSequence + 1}" 
                name="gig[gigmedia_attributes][${this.mediaIndex}][Chrono]" 
                id="gig_gigmedia_attributes_${this.mediaIndex}_Chrono">
      </td>
      <td>
          <input class="form-control" type="text" 
                name="gig[gigmedia_attributes][${this.mediaIndex}][title]" 
                id="gig_gigmedia_attributes_${this.mediaIndex}_title">
      </td>
      <td>
          <input class="form-control" type="text" 
                name="gig[gigmedia_attributes][${this.mediaIndex}][mediaid]" 
                id="gig_gigmedia_attributes_${this.mediaIndex}_mediaid">
      </td>
      <td>
        <select class="form-control song-selector"
                id="gig_gigmedia_attributes_${this.mediaIndex}_mediatype" 
                name="gig[gigmedia_attributes][${this.mediaIndex}][mediatype]">              
            <option value="1">YouTube</option>
            <option value="2">Archive.org Video</option>
            <option value="4">Archive.org Audio</option>
            <option selected="selected" value="3">Archive.org Playlist</option>
            <option value="5">Vimeo</option>
            <option value="6">Soundcloud</option>
        </select>
      </td>
      <td> 
          <button type="button" class="btn btn-link" 
                  data-action="click->gig#removeRow"
                  data-gig-table-id-param="${tableId}"
                  data-gig-row-id-param="${this.mediaIndex}">
              Remove
          </button>
      </td>
    `

    table.appendChild(newRow)
    this.mediaIndex++
  }

  addGigSongSelector(parent, index) {
    // Grab template song selector and make a copy
    const referenceSelector = this.templateSongSelectorTarget
    const selectorCopy = referenceSelector.cloneNode(true)

    // Configure for the current index
    selectorCopy.name = `gig[gigsets_attributes][${index}][SONGID]`
    selectorCopy.id = `gig_gigsets_attributes_${index}_SONGID`
    selectorCopy.value = ""
    selectorCopy.removeAttribute("data-gig-target")

    parent.appendChild(selectorCopy)
  }

  removeTableRow(tableId, rowId) {
    const table = document.getElementById(tableId)
    const row = table.querySelector(`tr[data-row="${rowId}"]`)
    
    if (row) {
      const identifier = row.nextElementSibling
      if (identifier && identifier.tagName === "INPUT") {
        identifier.remove()
      }
      row.remove()
    }
  }
}