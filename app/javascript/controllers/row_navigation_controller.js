import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Row navigation controller connected")
  }

  // Handle click events on table rows
  rowClicked(event) {
    console.log("Row clicked!", event.currentTarget)
    
    // Don't navigate if click is on a link or button
    if (event.target && (event.target.nodeName === "A" || event.target.nodeName === "BUTTON")) {
      console.log("Ignoring click on link/button")
      return;
    }

    const row = event.currentTarget;
    const path = row.dataset.path;
    
    console.log("Navigating to:", path)
    
    if (path) {
      window.location = path;
    } else {
      console.log("No path found on row")
    }
  }
}