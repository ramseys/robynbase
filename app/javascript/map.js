// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

import { initMap, createMap, addMarker } from './map_utils.js';


window.loadVenueOmniMap = (venues, venuePath, gigsPath) => {
        
    initMap();

    const map = createMap([30, 0], 2);

    venues.forEach(venue => {
        addMarker(venue, map, venuePath, gigsPath);
    });

}
