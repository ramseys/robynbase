import { Controller } from "@hotwired/stimulus"
import { initMap, createMap, addMarker } from '../map_utils.js'

export default class extends Controller {
  static values = { venue: Object }

  connect() {
    if (this.hasVenueValue && this.venueValue.latitude) {
      this.loadVenueMap(this.venueValue)
    }
  }

  loadVenueMap(venue) {
    initMap()
    
    const map = createMap([venue.latitude, venue.longitude], 13)
    
    addMarker(venue, map)
  }
}