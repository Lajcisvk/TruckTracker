<html>
    <head>
        <title>Truck Tracker</title>
        <meta charset="utf-8">
        <link href="https://maxcdn.bootstrapcdn.com/font-awesome/4.6.1/css/font-awesome.min.css" rel="stylesheet">
        <link rel="stylesheet" href="css/leaflet.css">
        <link rel="stylesheet" href="css/leaflet-sidebar.min.css">
        <link rel="stylesheet" href="css/style.css">
        <link rel="stylesheet" href="css/jquery.nstSlider.min.css">
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.0/jquery.min.js"></script>
        <script src="js/leaflet.js"></script>
        <script src="js/moment.js"></script>
        <script src="js/jquery.nstSlider.min.js"></script>
        <script src="js/Leaflet.MakiMarkers.js"></script>
        <script src="js/leaflet-sidebar.min.js"></script>

    </head>
    <body>
        <div id="sidebar" class="sidebar collapsed">
            <!-- Nav tabs -->
            <div class="sidebar-tabs">
                <ul role="tablist">
                    <li><a href="#cars" role="tab"><i class="fa fa-car"></i></a></li>
                    <li><a href="#timetravel" role="tab"><i class="fa fa-clock-o"></i></a></li>
                </ul>
            </div>

            <!-- Tab panes -->
            <div class="sidebar-content">
                <div class="sidebar-pane" id="cars">
                    <h1 class="sidebar-header">
                        Cars
                        <span class="sidebar-close"><i class="fa fa-caret-left"></i></span>
                    </h1>
                    <div id="cars-content">                        
                    </div>
                </div>

                <div class="sidebar-pane" id="timetravel">
                    <h1 class="sidebar-header">Time Travel<span class="sidebar-close"><i class="fa fa-caret-left"></i></span></h1>
                    <br>
                    <div style="width: 100%;" class="nstSlider" data-range_min="1" data-range_max="1000" 
                         data-cur_min="1">

                        <div class="leftGrip"></div>
                    </div>
                    <div class="leftLabel"></div>
                </div>
            </div>
        </div>
        <div id="mapid" class="sidebar-map" style="width: 100%; height: 100%; position: relative;"></div>
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
            var sidebar = L.control.sidebar('sidebar').addTo(mymap);
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
                    o.marker.show = true;
                });
                initSlider();
                displayCars();
                if (buffer > 0)
                    buffer--;
                getIsOnTheRoad(cars);
            }
            
            function displayCars(){
                cars.forEach(function (car){
                    var html =  '<div class="car_box" id="'+car.spz+'">' +
                                '<h3>SPZ: <span class="car-spz">'+car.spz+'</span></h2>' +
                                '<h3>Color: <span class="car-color">'+car.color+'</span></h2>' +
                                '<h3>Speed: <span class="car-speed">'+car.data[0].speed+'</span></h2>' +
                                '</div>';
                    $( "#cars-content" ).append(html);
                    $("#"+car.spz).data('car',car);
                    $("#"+car.spz).click(function(){
                        mymap.panTo($(this).data('car').marker.getLatLng());
                    });
                });
            }
            
            function updateCarDisplay(car){
                var element = $("#"+car.spz);
                element.find(".car-speed").html(car.data[0].speed);
                if(car.marker.show){
                    element.show();
                }else{
                    element.hide();
                }
            }

            function getCarDataUpdateCallback(response) {
                cars.forEach(function (car) {
                    var found = false;
                    response.forEach(function (o) {
                        if (car.car_key == o.car_key) {
                            var data = o.data[0].pos_gps.replace(/["'()]/g, "").split(",");
                            var latLng = new L.LatLng(data[0], data[1]);
                            car.marker.setLatLng(latLng);
                            car.data = o.data;
                            car.map_position = data;
                            car.marker.show = true;
                            found = true;
                        }
                    });
                    if (!found) {
                        car.marker.show = false;
                    }
                    updateCarDisplay(car);
                });
                hideOrShowMarkers();
                if (buffer > 0)
                    buffer--;
                getIsOnTheRoad(cars);
            }


            function hideOrShowMarkers() {
                cars.forEach(function (car) {
                    if (!mymap.hasLayer(car.marker)) {
                        mymap.addLayer(car.marker);
                    }
                    if (!car.marker.show) {
                        mymap.removeLayer(car.marker);
                    }
                });
            }

            function getCarData(callback, time) {
                if (buffer > 5)
                    return;
                buffer++;
                $.ajax({
                    url: "http://lit-mountain-38735.herokuapp.com/api",
                    data: {in: time},
                    type: "get", //send it through get method
                    success: function (response) {
                        callback(response);
                    },
                    error: function (xhr) {
                        if (buffer > 0)
                            buffer--;
                    }
                });
            }

            function initSlider() {
                $('.nstSlider').nstSlider({
                    "left_grip_selector": ".leftGrip",
                    "value_changed_callback": function (cause, leftValue, rightValue) {
                        var time = new Date(mostRecentDate - leftValue * 60000 * 5);
                        var timeText = moment(time).utc().format("YYYY-MM-DD HH:mm:ss");
                        $(this).parent().find('.leftLabel').text(timeText);
                        getCarData(getCarDataUpdateCallback, timeText);
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

        </script>
    </body>
</html>