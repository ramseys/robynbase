import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="recent-updates"
export default class extends Controller {
  static targets = ["list", "toggle", "frame"]
  static values = { url: String }

  toggle() {
    const expanded = this.listTarget.classList.toggle("d-none") === false
    this.toggleTarget.textContent = expanded ? "Hide" : "Show"
    this.toggleTarget.setAttribute("aria-expanded", expanded)

    if (expanded) {
      // The feed query is expensive, so the frame ships empty and is only pointed at
      // its endpoint the first time the box is opened. Turbo keeps the loaded content
      // afterwards, so collapsing and re-expanding doesn't refetch.
      if (!this.frameTarget.src) {
        this.frameTarget.src = this.urlValue
      }

      // Scroll only once the frame's rows are in the DOM. Until then the page is barely
      // taller than the viewport, so there is nothing to scroll and the browser clamps
      // the request to 0 — the box never moves. Turbo resolves `loaded` immediately for
      // an already-loaded frame, so this covers the first open and every later one.
      this.frameTarget.loaded.then(() => this.scrollToBox())
    }
  }

  scrollToBox() {
    // Plain scrollIntoView aligns the box's top with the viewport's top edge,
    // which tucks it behind the fixed navbar; offset by the navbar's height instead.
    const nav = document.querySelector(".navbar.fixed-top")
    const offset = (nav ? nav.getBoundingClientRect().height : 0) + 10
    const top = this.element.getBoundingClientRect().top + window.scrollY - offset
    window.scrollTo({ top, behavior: "smooth" })
  }
}
