// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

import { initMap, createMap, addMarker } from './map_utils.js';

window.loadVenueMap = (venue) => {

  initMap();

  const map = createMap([venue.latitude, venue.longitude], 13)

  addMarker(venue, map);  
      
}