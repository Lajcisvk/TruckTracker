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
        <script src='https://api.mapbox.com/mapbox.js/plugins/leaflet-pip/v0.0.2/leaflet-pip.js'></script>
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
                        <input type="checkbox" id="selectedOnlyCheckbox" onclick="toggleSelectOnly()"> Only selected
                        <span class="sidebar-close"><i class="fa fa-caret-left"></i></span>
                    </h1>
                    <div id="cars-content">                        
                    </div>
                </div>
                <div class="sidebar-pane" id="timetravel">
                    <h1 class="sidebar-header">Time Travel<span class="sidebar-close"><i class="fa fa-caret-left"></i></span></h1>
                    <br>
                    <div style="width: 100%;" class="nstSlider" data-range_min="0" data-range_max="1000" 
                         data-cur_min="0">

                        <div class="leftGrip"></div>
                    </div>
                    <div class="leftLabel"></div>
                    <div>
                        <button onclick="decreaseSlider()">Add 5 minutes</button>
                        <button onclick="increaseSlider()">Remove 5 minutes</button>
                    </div>
                </div>
            </div>
        </div>
        <div id="mapid" class="sidebar-map" style="width: 100%; height: 100%; position: relative;"></div>
        <script>
            var cars;
            var mostRecentDate;
            var states;
            var buffer = 0;
            var selected;
            var selectedOnly;
            var timeText;
            var init = true;
            var redIcon = L.MakiMarkers.icon({icon: "circle", color: "#FF0000", size: "m"});
            var yellowIcon = L.MakiMarkers.icon({icon: "circle", color: "#FFFB00", size: "m"});
            var greenIcon = L.MakiMarkers.icon({icon: "circle", color: "#80FF00", size: "m"});
            var blackIcon = L.MakiMarkers.icon({icon: "circle", color: "#000000", size: "m"});
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
                var data;
                var marker;
                cars.forEach(function (o) {
                    data = o.data[1].pos_gps.replace(/["'()]/g, "").split(",");
                    marker = L.marker(data, {icon: blackIcon});
                    marker.addTo(mymap);
                    o.map_position = data;
                    o.marker = marker;
                    o.start_point = o.data[0];
                    o.end_point = o.data[1];
                    o.marker.show = false;
                    o.onTheRoadLoaded = false;
                    o.initRoutesLoaded = false;
                    o.currentRoutesLoaded = false;
                });
                initSlider();
                displayCars(cars);
                displayCountries();
                mymap.on('moveend', function () {
                    redrawInBoundsCars();
                });
            }

            function redrawInBoundsCars() {
                var inBounds = []
                var bounds = mymap.getBounds();
                for (var i = 0, len = cars.length; i < len; i++) {
                    var marker = cars[i].marker;
                    cars[i].marker.show = false;
                    if (bounds.contains(marker.getLatLng())) {
                        inBounds.push(cars[i]);
                    }
                }
                if (selected != null) {
                    inBounds.push(selected);
                }
                inBounds.forEach(function (car) {
                    if (selectedOnly && selected != null && selected.car_key != car.car_key) {
                        car.marker.show = false;
                    } else {
                        car.marker.show = true;
                    }
                    if (inBounds.length < 100) {
                        if (!car.onTheRoadLoaded) {
                            getIsOnTheRoad(car);
                        }
                        if (!car.initRoutesLoaded) {
                            getInitCarRoute(car);
                        }
                        if (!car.currentRoutesLoaded) {
                            getCurrentCarRoute(car);
                        }
                    }
                });
                refreshCarsDisplay();
                hideOrShowMarkers();
            }

            function removeBrackets(string) {
                return string.replace(/["'()]/g, "")
            }

            function getInitCarRoute(car) {
                $.ajax({
                    url: "/route?point=" + removeBrackets(car.start_point.pos_gps) + "&point=" + removeBrackets(car.end_point.pos_gps),
                    type: "get", //send it through get method
                    success: function (response) {
                        car.total_est_time = response.paths[0].time;
                        car.delay = "Car is in final destination"
                        car.initRoutesLoaded = true;
                        getCurrentCarRoute(car);
                    },
                    error: function (xhr) {
                        car.delay = "Not available"
                        updateCarDisplay(car);
                    }
                });
            }


            function getCurrentCarRoute(car) {
                if (car.total_est_time) {
                    $.ajax({
                        url: "/route?point=" + car.map_position[0] + "," + car.map_position[1] + "&point=" + removeBrackets(car.end_point.pos_gps),
                        type: "get", //send it through get method
                        success: function (response) {
                            car.current_est_time = response.paths[0].time;
                            var delay = calculateDelay(car);
                            car.delay =  (delay < 0 ? '- ': '' ) + moment.utc(delay).format("HH:mm:ss");
                            car.currentRoutesLoaded = true;
                            updateCarDisplay(car);
                        },
                        error: function (xhr) {
                            car.delay = "Not available"
                            updateCarDisplay(car);
                        }
                    });
                }
            }

            function toggleSelectOnly() {
                console.log($('#selectedOnlyCheckbox').is(':checked'));
                if ($('#selectedOnlyCheckbox').is(':checked')) {
                    selectedOnly = true;
                } else {
                    selectedOnly = false;
                }
                redrawInBoundsCars();
            }

            function increaseSlider() {
                $('.nstSlider').nstSlider('set_position', $('.nstSlider').nstSlider('get_current_min_value') + 1);
            }
            
            function decreaseSlider() {
                $('.nstSlider').nstSlider('set_position', $('.nstSlider').nstSlider('get_current_min_value') - 1);
            }

            function calculateDelay(car) {
                var startTime = new Date(car.start_point.time.replace(" ", "T")).getTime();
                var currentTime = new Date(car.data[0].time.replace(" ", "T")).getTime();
                console.log(car,car.data[0],car.data[0].time);
                var totalEndTime = car.total_est_time;
                var currentEndTime = car.current_est_time;
                return ((currentTime - startTime) + currentEndTime) - totalEndTime;
            }


            function displayCars(cars) {
                var html;
                cars.forEach(function (car) {
                    html = '<div class="car_box" id="' + car.car_key + '">' +
                            '<h3>SPZ: <span class="car-spz">' + car.spz + '</span></h2>' +
                            '<h3>Color: <span class="car-color">' + car.color + '</span></h2>' +
                            '<h3>Speed: <span class="car-speed">' + car.data[0].speed + '</span></h2>' +
                            '<h3>Country: <span class="car-country">Loading..</span></h2>' +
                            '<h3>Road status: <span class="car-road-status">Loading..</span></h2>' +
                            '<h3>Coordinates: <span class="car-coordinates">' + car.map_position + '</span></h2>' +
                            '<h3>Delay: <span class="car-delay">Loading..</span></h2>' +
                            '</div>';
                    $("#cars-content").append(html);
                    $("#" + car.car_key).data('car', car);
                    $("#" + car.car_key).click(function () {
                        mymap.panTo($(this).data('car').marker.getLatLng());
                        if (selected != null && selected.car_key !== $(this).data('car')) {
                            $("#" + selected.car_key).removeClass('selected');
                        }
                        $(this).addClass('selected');
                        selected = $(this).data('car');
                    });
                });
            }

            function updateCarDisplay(car) {
                var element = $("#" + car.car_key);
                element.find(".car-speed").html(car.data[0].speed);
                element.find(".car-country").html(car.country);
                element.find(".car-road-status").html(car.roadStatus);
                element.find(".car-coordinates").html(car.map_position[0] + ',' + car.map_position[1]);
                element.find(".car-delay").html(car.delay);
                if (car.marker.show) {
                    element.show();
                } else {
                    element.hide();
                }
            }

            function refreshCarsDisplay() {
                cars.forEach(function (car) {
                    updateCarDisplay(car);
                });
            }

            function getCarDataUpdateCallback(response) {
                var latLng;
                var data;
                cars.forEach(function (car) {
                    car.marker.show = false;
                    car.marker.setIcon(blackIcon);
                    for (var i = 0; i < response.length; i++) {
                        if (car.car_key == response[i].car_key) {
                            data = response[i].data[0].pos_gps.replace(/["'()]/g, "").split(",");
                            latLng = new L.LatLng(data[0], data[1]);
                            car.marker.setLatLng(latLng);
                            car.data = response[i].data;
                            car.map_position = data;
                            car.currentRoutesLoaded = false;
                            car.onTheRoadLoaded = false;
                            car.marker.show = true;
                        }
                    }
                });
                addCountryToCars(cars);
                redrawInBoundsCars();         
                if (selected != null) {
                    mymap.panTo(selected.marker.getLatLng(), 5);
                }
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

            function displayCountries() {
                $.ajax({
                    dataType: 'json',
                    url: "https://raw.githubusercontent.com/myethiopia/NaturalEarth/master/region_un/GeoJson/region_un_Europe_subunits.json",
                    type: "get", //send it through get method
                    success: function (response) {
                        states = L.geoJson().addTo(mymap);
                        states.addData(response);
                        mymap.removeLayer(states);
                        addCountryToCars(cars);
                        redrawInBoundsCars();
                    },
                    error: function (xhr) {

                    }
                });
            }

            function addCountryToCars(cars) {
                var layer;
                cars.forEach(function (car) {
                    layer = leafletPip.pointInLayer(car.marker.getLatLng(), states, true);
                    if (layer.length) {
                        car.country = layer[0].feature.properties.name;
                    }
                    else {
                        car.country = "Not on the map";
                    }
                });
            }

            function getCarData(callback, time) {
                if (buffer > 0)
                    return;
                buffer++;
                $.ajax({
                    url: "/api",
                    data: {in: time},
                    type: "get", //send it through get method
                    success: function (response) {
                        if (buffer > 0)
                            buffer--;
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
                        timeText = moment(time).utc().format("YYYY-MM-DD HH:mm:ss");
                        $(this).parent().find('.leftLabel').text(timeText);
                        if (cause == 'set_position') {
                            getCarData(getCarDataUpdateCallback, timeText);
                        }
                    },
                    "user_mouseup_callback": function (left, right) {
                            getCarData(getCarDataUpdateCallback, timeText);
                    }
                });
            }

            function getIsOnTheRoad(car) {
                var distance;
                var carMarker = car.marker;
                $.ajax({
                    url: "/nearest",
                    type: "get", //send it through get method
                    data: {point: carMarker.getLatLng().lat + "," + carMarker.getLatLng().lng},
                    success: function (response) {
                        distance = response.distance;
                        if (car.data[0].speed === 0) {
                            if (distance < 2) {
                                car.roadStatus = "Is on the road";
                                carMarker.setIcon(redIcon);
                            } else {
                                car.roadStatus = "Is not on the road";
                                carMarker.setIcon(yellowIcon);
                            }
                        } else {
                            car.roadStatus = "Is on the road";
                            carMarker.setIcon(greenIcon);
                        }
                        updateCarDisplay(car);
                        car.onTheRoadLoaded = true;
                    },
                    error: function (xhr) {
                        car.roadStatus = "Not available"
                        updateCarDisplay(car);
                    }
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
                    dates.push(new Date(car.data[1].time.replace(" ", "T")));
                });
                return new Date(Math.max.apply(null, dates));
            }

        </script>
    </body>
</html>