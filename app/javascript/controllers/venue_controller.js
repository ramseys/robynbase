import { Controller } from "@hotwired/stimulus";
import { initMap, createMap, addMarker } from "../map_utils.js";

export default class extends Controller {
  static values = { venue: Object };
  static targets = ["mapContainer", "photosContainer", "mapTab", "photosTab"];

  connect() {
    if (this.hasVenueValue || this.venueValue.latitude) {
      if (this.hasPhotosContainerTarget) {
        // Toggle mode: photos are default, hide map until Map tab is clicked
        this.mapContainerTarget.style.display = "none";
      } else {
        this.loadVenueMap(this.venueValue);
      }
    }
  }

  showMap() {
    this.switchTo(this.mapContainerTarget, this.photosContainerTarget, this.mapTabTarget, this.photosTabTarget);

    if (!this.map) {
      this.loadVenueMap(this.venueValue);
    } else {
      // Leaflet can't measure a hidden container, so tiles don't render correctly
      // until we tell it to recalculate the container dimensions.
      this.map.invalidateSize();
    }
  }

  showPhotos() {
    this.switchTo(this.photosContainerTarget, this.mapContainerTarget, this.photosTabTarget, this.mapTabTarget);
  }

  switchTo(showContainer, hideContainer, activeTab, inactiveTab) {
    hideContainer.style.display = "none";
    showContainer.style.display = "block";
    activeTab.classList.add("active");
    inactiveTab.classList.remove("active");
  }

  loadVenueMap(venue) {
    initMap();
    this.map = createMap([venue.latitude, venue.longitude], 13);
    addMarker(venue, this.map);
  }
}
