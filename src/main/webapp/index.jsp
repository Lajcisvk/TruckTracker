<html>
    <head>
        <title>Truck Tracker</title>
        <meta charset="utf-8">
        <link rel="stylesheet" href="http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.css">
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.0/jquery.min.js"></script>
        <script src="js/leaflet.js"></script>
        <script src="js/Leaflet.MakiMarkers.js"></script>

    </head>
    <body>
        <div id="mapid" style="width: 1000px; height: 800px; position: relative;"></div>
        <script>
            var cars = new Array();
            var mymap = L.map('mapid').setView([49.21, 16.6], 6);
            L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibGFqY2kiLCJhIjoiY2ltbHJza2gxMDAwbHcwbHcyaDIyNDEybiJ9.nU1OddV3p8C8uWJhFppiIA', {
                maxZoom: 21,
                attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, ' +
                        '<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
                        'Imagery © <a href="http://mapbox.com">Mapbox</a>',
                id: 'mapbox.streets'
            }).addTo(mymap);
            $.ajax({
                url: "http://lit-mountain-38735.herokuapp.com/api",
                type: "get", //send it through get method
                success: function (response) {
                    cars = response;
                    cars.forEach(function (o) {
                        var data = o.data[0].pos_gps.replace(/\(|\)/, "").split(",");
                        var icon = L.MakiMarkers.icon({icon: "circle", color: "#80FF00", size: "m"});
                        var marker = L.marker(data,{icon: icon});
                        marker.addTo(mymap);
                        o.marker = marker;
                    });
                    getIsOnTheRoad(cars);
                },
                error: function (xhr) {
                    //Do Something to handle error
                }
            });

            function getIsOnTheRoad(cars) {
                var redIcon = L.MakiMarkers.icon({icon: "circle", color: "#FF0000", size: "m"});
                cars.forEach(function (car) {
                    var carMarker = car.marker;
                    $.ajax({
                        url: "http://router.project-osrm.org/nearest",
                        type: "get", //send it through get method
                        data: {loc: carMarker.getLatLng().lat + "," + carMarker.getLatLng().lng},
                        success: function (response) {
                            var marker = L.marker(response.mapped_coordinate);
                            var distance = marker.getLatLng().distanceTo(carMarker.getLatLng());
                            if (distance < 3) {
                                carMarker.bindPopup("<b>You are on the road</b>");
                            } else {
                                carMarker.bindPopup("<b>You are not on the road</b>");
                                carMarker.setIcon(redIcon);
                            }
                        },
                        error: function (xhr) {
                            //Do Something to handle error
                        }
                    });
                });
            }

        </script>
    </body>
</html>