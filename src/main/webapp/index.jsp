<html>
    <head>
        <title>Truck Tracker</title>
        <meta charset="utf-8">
        <link rel="stylesheet" href="css/leaflet.css">
        <link rel="stylesheet" href="css/jquery.nstSlider.min.css">
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.0/jquery.min.js"></script>
        <script src="js/leaflet.js"></script>
        <script src="js/moment.js"></script>
        <script src="js/jquery.nstSlider.min.js"></script>
        <script src="js/Leaflet.MakiMarkers.js"></script>

    </head>
    <body>
        <div style="width: 100%" class="nstSlider" data-range_min="0" data-range_max="1000" 
             data-cur_min="0">

            <div class="leftGrip"></div>
        </div>
        <div class="leftLabel"></div>
        <div id="mapid" style="width: 100%; height: 90%; position: relative;"></div>
        <script>
            var cars;
            var mostRecentDate;
            var buffer = 0;
            var mymap = L.map('mapid').setView([49.21, 16.6], 6);
            L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibGFqY2kiLCJhIjoiY2ltbHJza2gxMDAwbHcwbHcyaDIyNDEybiJ9.nU1OddV3p8C8uWJhFppiIA', {
                maxZoom: 21,
                attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, ' +
                        '<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
                        'Imagery © <a href="http://mapbox.com">Mapbox</a>',
                id: 'mapbox.streets'
            }).addTo(mymap);

            $(document).ready(function () {
                getCarData(getCarDataInitCallback);
            });

            function getCarDataInitCallback(response) {
                cars = response;
                mostRecentDate = getMostRecentDate(cars);
                cars.forEach(function (o) {
                    var data = o.data[0].pos_gps.replace(/["'()]/g, "").split(",");
                    var icon = L.MakiMarkers.icon({icon: "circle", color: "#80FF00", size: "m"});
                    var marker = L.marker(data, {icon: icon});
                    marker.addTo(mymap);
                    o.map_position = data;
                    o.marker = marker;
                });
                initSlider();
                if (buffer > 0)
                    buffer--;
                getIsOnTheRoad(cars);
            }
            
            function getCarDataUpdateCallback(response) {
                cars.forEach(function (car) {
                    response.forEach(function (o) {
                        if (car.car_key == o.car_key && car.data[0].pos_gps != o.data[0].pos_gps) {
                            var data = o.data[0].pos_gps.replace(/["'()]/g, "").split(",");
                            var latLng = new L.LatLng(data[0], data[1]);
                            car.marker.setLatLng(latLng);
                            car.map_position = data;
                        }
                    });
                });
                if (buffer > 0)
                    buffer--;
                getIsOnTheRoad(cars);
            }

            function getCarData(callback, since, until) {
                if (buffer > 5)
                    return;
                buffer++;
                $.ajax({
                    url: "http://lit-mountain-38735.herokuapp.com/api",
                    data: {since: since, until: until},
                    type: "get", //send it through get method
                    success: function (response) {
                        callback(response);
                    },
                    error: function (xhr) {
                       if(buffer > 0) buffer --;
                    }
                });
            }

            function initSlider() {
                $('.nstSlider').nstSlider({
                    "left_grip_selector": ".leftGrip",
                    "value_changed_callback": function (cause, leftValue, rightValue) {
                        var until = new Date(mostRecentDate - leftValue * 60000 * 5);
                        var since = new Date(until - 60000 * 5);
                        var sinceText = moment(since).utc().format("YYYY-MM-DD hh:mm:ss") + ":00";
                        var untilText = moment(until).utc().format("YYYY-MM-DD hh:mm:ss") + ":00";
                        $(this).parent().find('.leftLabel').text(since.toGMTString());
                        getCarData(getCarDataUpdateCallback, sinceText, untilText);
                    }
                });
            }

            function getIsOnTheRoad(cars) {
                if (buffer != 0)
                    return;
                var redIcon = L.MakiMarkers.icon({icon: "circle", color: "#FF0000", size: "m"});
                var yellowIcon = L.MakiMarkers.icon({icon: "circle", color: "#FFFB00", size: "m"});
                var greenIcon = L.MakiMarkers.icon({icon: "circle", color: "#80FF00", size: "m"});
                cars.forEach(function (car) {
                    var carMarker = car.marker;
                    $.ajax({
                        url: "http://router.project-osrm.org/nearest",
                        type: "get", //send it through get method
                        data: {loc: carMarker.getLatLng().lat + "," + carMarker.getLatLng().lng},
                        success: function (response) {
                            var marker = L.marker(response.mapped_coordinate);
                            var distance = marker.getLatLng().distanceTo(carMarker.getLatLng());
                            if (distance < 5) {
                                var message = "<b>You are on the road</b><br>position: " + car.map_position
                                setPopup(carMarker, message);
                                if (car.data[0].speed === 0) {
                                    carMarker.setIcon(redIcon);
                                } else {
                                    carMarker.setIcon(greenIcon);
                                }
                            } else {
                                var message = "<b>You are not on the road</b><br>position: " + car.map_position
                                carMarker.setIcon(yellowIcon);
                                setPopup(carMarker, message);
                            }
                        },
                        error: function (xhr) {
                            //Do Something to handle error
                        }
                    });
                });
            }

            function setPopup(carMarker, message) {
                if (carMarker._popup == null) {
                    carMarker.bindPopup(message);
                } else {
                    carMarker._popup.setContent(message);
                }
            }

            function getMostRecentDate(cars) {
                var dates = [];
                cars.forEach(function (car) {
                    dates.push(new Date(car.data[0].time.replace(" ", "T")));
                });
                return new Date(Math.max.apply(null, dates));
            }

            function formatDate(date) {
                var moment = moment(date);
                return moment.format("YYYY-MM-DD hh:mm:ss") + ":00"
            }
        </script>
    </body>
</html>