import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["deletions"]

  removeImage(event) {
    const button = event.currentTarget
    const attachmentId = button.dataset.attachmentId
    const row = button.closest("tr")

    // Remove the row from the table
    row.remove()

    // Add a hidden field to track this deletion
    const hiddenField = document.createElement("input")
    hiddenField.type = "hidden"
    hiddenField.name = "deleted_img_ids[]"
    hiddenField.value = attachmentId
    this.deletionsTarget.appendChild(hiddenField)
  }
}
