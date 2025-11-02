import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["templateSongSelector"]

  connect() {
    this.compositionSongIndex = 100
    this.setupImageGallery()
  }

  setupImageGallery() {
    // Set up album art lightbox using fancybox
    const imageGalleries = this.element.querySelectorAll("a.image-gallery")
    imageGalleries.forEach(gallery => {
      gallery.setAttribute("rel", "gallery")
    })
    
    // Initialize fancybox if available
    if (typeof $.fn.fancybox !== 'undefined') {
      $(this.element).find("a.image-gallery").fancybox({
        helpers: { 
          thumbs: {
            width: 50,
            height: 50
          }
        }
      })
    }
  }

  toggleAlbumBlock(event) {
    const albumHeader = event.target.closest(".album-block-header")
    const compid = albumHeader.dataset.compid
    const albumBlock = document.querySelector(`.album-block-container[data-compid="${compid}"]`)
    
    if (albumBlock) {
      // Toggle visibility
      if (albumBlock.style.display === "none") {
        albumBlock.style.display = "block"
      } else {
        albumBlock.style.display = "none"
      }
      
      // Toggle disclosure arrow
      const disclosure = albumHeader.querySelector(".advanced-options-disclosure")
      if (disclosure) {
        disclosure.classList.toggle("bi-caret-right-fill")
        disclosure.classList.toggle("bi-caret-down-fill")
      }
    }
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

  addTrack(event) {
    const tableId = event.params.tableId
    const bonus = event.params.bonus || false
    this.addCompositionTableRow(tableId, bonus)
  }

  removeTrack(event) {
    const rowId = event.params.rowId
    const tableId = event.params.tableId
    this.removeCompositionTableRow(tableId, rowId)
  }

  addCompositionTableRow(tableId, bonus) {
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
    newRow.dataset.row = this.compositionSongIndex
    newRow.innerHTML = `
      <td>
          <input class="form-control" size="3" type="text" 
                 value="${maxSequence + 1}" 
                 name="composition[tracks_attributes][${this.compositionSongIndex}][Seq]" 
                 id="composition_tracks_attributes_${this.compositionSongIndex}_Seq">
      </td>
      <td></td>
      <td>
          <input class="form-control" type="text" value="" 
                 name="composition[tracks_attributes][${this.compositionSongIndex}][Song]" 
                 id="composition_tracks_attributes_${this.compositionSongIndex}_Song">
      </td>
      <td>
          <input class="form-control" type="text" 
                 name="composition[tracks_attributes][${this.compositionSongIndex}][VersionNotes]" 
                 id="composition_tracks_attributes_${this.compositionSongIndex}_VersionNotes">
          <input type="hidden" 
                 value="${bonus}" 
                 name="composition[tracks_attributes][${this.compositionSongIndex}][bonus]" 
                 id="composition_tracks_attributes_${this.compositionSongIndex}_bonus">
      </td>
      <td> 
          <button type="button" class="btn btn-link" 
                  data-action="click->composition#removeTrack"
                  data-composition-table-id-param="${tableId}"
                  data-composition-row-id-param="${this.compositionSongIndex}">
              Remove
          </button>
      </td>
    `

    table.appendChild(newRow)

    const songSelectorCell = newRow.querySelector("td:nth-child(2)")
    this.addCompositionSongSelector(songSelectorCell, this.compositionSongIndex)

    this.compositionSongIndex++
  }

  addCompositionSongSelector(parent, index) {
    // Grab template song selector and make a copy
    const referenceSelector = this.templateSongSelectorTarget
    const selectorCopy = referenceSelector.cloneNode(true)

    // Configure for the current index
    selectorCopy.name = `composition[tracks_attributes][${index}][SONGID]`
    selectorCopy.id = `composition_tracks_attributes_${index}_SONGID`
    selectorCopy.value = ""
    selectorCopy.removeAttribute("data-composition-target")

    parent.appendChild(selectorCopy)
  }

  removeCompositionTableRow(tableId, rowId) {
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