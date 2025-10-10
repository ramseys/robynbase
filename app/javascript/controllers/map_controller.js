import { Controller } from "@hotwired/stimulus"
import { initMap, createMap, addMarker } from '../map_utils.js'

export default class extends Controller {
  static values = {
    venues: Array,
    venuePath: String,
    gigsPath: String
  }

  connect() {
    console.log('Map controller connected')
    this.loadVenueOmniMap()
  }

  loadVenueOmniMap() {
    initMap()

    const map = createMap([30, 0], 2)

    this.venuesValue.forEach(venue => {
      addMarker(venue, map, this.venuePathValue, this.gigsPathValue)
    })
  }
}