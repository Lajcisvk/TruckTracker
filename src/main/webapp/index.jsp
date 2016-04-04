<html>
<head>
    <title>Truck Tracker</title>
    <meta charset="utf-8">
    <link rel="stylesheet" href="https://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.css">
</head>
<body>
<div id="mapid" style="width: 1000px; height: 800px; position: relative;"></div>
<script src="http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.js"></script>
<script>
    var mymap = L.map('mapid').setView([49.21, 16.6], 17);

    L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibGFqY2kiLCJhIjoiY2ltbHJza2gxMDAwbHcwbHcyaDIyNDEybiJ9.nU1OddV3p8C8uWJhFppiIA', {
        maxZoom: 21,
        attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, ' +
        '<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
        'Imagery © <a href="http://mapbox.com">Mapbox</a>',
        id: 'mapbox.streets'
    }).addTo(mymap);
</script>
</body>
</html>