import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    const header = event.target.closest(".advanced-options-header")
    const criteriaBlock = header.closest("form").querySelector(".row.advanced-options")

    if (criteriaBlock && criteriaBlock.classList.contains("advanced-options")) {
      criteriaBlock.classList.toggle("expanded")

      const disclosure = header.querySelector(".advanced-options-disclosure")
      if (disclosure) {
        disclosure.classList.toggle("bi-caret-right-fill")
        disclosure.classList.toggle("bi-caret-down-fill")
      }
    }
  }
}
