import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="recent-updates"
export default class extends Controller {
  static targets = ["list", "toggle"]

  toggle() {
    const expanded = this.listTarget.classList.toggle("d-none") === false
    this.toggleTarget.textContent = expanded ? "Hide" : "Show"
    this.toggleTarget.setAttribute("aria-expanded", expanded)

    if (expanded) {
      // Plain scrollIntoView aligns the box's top with the viewport's top edge,
      // which tucks it behind the fixed navbar; offset by the navbar's height instead.
      const nav = document.querySelector(".navbar.fixed-top")
      const offset = (nav ? nav.getBoundingClientRect().height : 0) + 10
      const top = this.element.getBoundingClientRect().top + window.scrollY - offset
      window.scrollTo({ top, behavior: "smooth" })
    }
  }
}
