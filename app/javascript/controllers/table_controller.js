import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frame", "loadingIndicator"]

  connect() {
    this.showContent()
  }

  // Show loading state when Turbo Frame starts loading
  frameLoadingStart(event) {
    // Only show loading if this is an actual fetch request that will navigate
    // Ignore hover events on links that don't actually trigger navigation
    if (event.detail && event.detail.fetchOptions) {
      this.showLoading()
    }
  }

  // Hide loading state when Turbo Frame finishes loading
  frameLoadingEnd() {
    this.showContent()
  }

  showLoading() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.remove("d-none")
    }
    if (this.hasFrameTarget) {
      this.frameTarget.style.opacity = "0.6"
    }
  }

  showContent() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.add("d-none")
    }
    if (this.hasFrameTarget) {
      this.frameTarget.style.opacity = "1"
    }
  }
}