import L from "leaflet";

export function createMap(latLong, zoom) {

    const map = L.map('map').setView(latLong, zoom);
    
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 23,
      attribution: '© OpenStreetMap'
    }).addTo(map);

    return map;
}


export function initMap() {

    delete L.Icon.Default.prototype._getIconUrl;

    // explicitly specify which icons to use (something about the bundling process
    // confuses leaflet, so the image paths are off unless we do this)
    L.Icon.Default.mergeOptions({
        iconRetinaUrl: "/images/marker-icon-2x.png",
        iconUrl: "/images/marker-icon.png",
        shadowUrl: "/images/marker-shadow.png",
    });

};

export function addMarker(venue, map, venuePath, gigsPath) {

    const marker = L.marker([venue.latitude, venue.longitude]).addTo(map);

    // we use the presence of venuePath as a signal to render the tooltip and popup
    if (venuePath) {

        let popperText = venuePath ? 
            `<b><a href="${venuePath}/${venue.VENUEID}">${venue.Name}</a></b><br/><br/>` :
            `<b>${venue.Name}</b><br/><br/>`;

        popperText += venue.street_address1 ?`${venue.street_address1}<br/>` : '';
        popperText += venue.street_address2 ? `${venue.street_address2}<br/>` : '';
        popperText += venue.SubCity ? `${venue.SubCity}<br/>` : '';
        popperText += venue.City ? `${venue.City}` : '';
        popperText += venue.State ? `, ${venue.State}` : '';

        if (gigsPath) {
            popperText += `<br/><br/><a href="${gigsPath}?venue_id=${venue.VENUEID}">Show Gigs</a>`;
        }
        
        marker.bindPopup(popperText);

        marker.bindTooltip(venue.Name);

        // these event handlers hide the marker's tooltip when its popup is opened;
        // they do it by setting the opacity because closeTooltip doesn't seem to be
        // working        
        marker.addEventListener('popupclose', (e) => {
            marker.getTooltip().setOpacity(0.9);
        });
        
        marker.addEventListener('popupopen', (e) => {
            marker.getTooltip().setOpacity(0);
        });

    }

}