const globals = require('./globals');

process.setMaxListeners(5000);

const polyline = require('google-polyline');

const geolocation_utils = require('geolocation-utils');

const googleMapsClient = require('@google/maps').createClient({
    key: 'YOUR GOOGLE MAPS API'
});

exports.LatLng = class {
    constructor(arg1, arg2) {
        if (typeof arg1 === "number" && typeof arg2 === "number") {
            this.lat = arg1;
            this.lng = arg2;
        } else if (typeof arg1 === "string" && arguments.length === 1) {
            var splitted = arg1.split(';');
            this.lat = parseFloat(splitted[0]);
            this.lng = parseFloat(splitted[1]);
        }
    }

    toVector() {
        return [this.lat, this.lng];
    }
};

exports.ResultFromDirections = class {
    constructor(rideId, duration, distance, currentDuration, currentDistance, polylineTotal, points, ridersInfo) {
        this.rideId = rideId;
        this.duration = duration;
        this.distance = distance;
        this.currentDuration = currentDuration;
        this.currentDistance = currentDistance;
        this.polylineTotal = polylineTotal;
        this.points = points;
        this.ridersInfo = ridersInfo;
    }

    get error() {
        return this._error;
    }

    set error(e) {
        this._error = e;
    }
};

exports.directions = (rideId, directionObj, currentDuration, currentDistance, riders, whereToDescs) => {
    return new Promise((resolve, reject) => {
        var resp;
        try {
            googleMapsClient.directions(directionObj, (err, response) => {
                if (!err && response.json.status !== "ZERO_RESULTS") {
                    var waypoints = directionObj.waypoints;
                    if (waypoints === undefined)
                        waypoints = [];
                    var r = response.json;
                    var order = r.routes[0].waypoint_order;
                    var duration = 0;
                    var distance = 0;
                    var duration_to_mine_in_order = [];
                    var distance_to_mine_in_order = [];
                    var legs = r.routes[0].legs;
                    var points_to_poly = [];
                    var i = 0;
                    var points = [];
                    var riders_in_order = [];
                    var points_to_me_in_order = [];
                    var polys_to_me_in_order = [];

                    points.push(directionObj.origin);

                    if (waypoints.length !== 0) {
                        order.forEach((e) => {
                            points.push(waypoints[e]);
                            riders_in_order.push([riders[e]]);
                        });
                    }

                    points.push(directionObj.destination);


                    legs.forEach(x => {
                        duration += x.duration.value;
                        distance += x.distance.value;
                        x.steps.forEach((x) => {
                            points_to_poly = points_to_poly.concat(polyline.decode(x.polyline.points));
                        });
                        if (i !== waypoints.length) {
                            points_to_me_in_order.push(points_to_poly);
                            duration_to_mine_in_order.push(duration);
                            distance_to_mine_in_order.push(distance);
                        }
                        i++;
                    });

                    var polylineTotal = polyline.encode(points_to_poly);

                    points_to_me_in_order.forEach((ps) => {
                        polys_to_me_in_order.push(polyline.encode(ps));
                    });

                    var ridersInfo = {};

                    i = 0;

                    waypoints.forEach(() => {
                        var riderInfo = {
                            "polylineToMe": polys_to_me_in_order[i],
                            "durationToMine": duration_to_mine_in_order[i],
                            "distanceToMine": distance_to_mine_in_order[i],
                            "myPointIndex": i,
                            "whereToDesc": whereToDescs[i]
                        };
                        ridersInfo[riders_in_order[i]] = riderInfo;
                        i++;
                    });

                    resp = new exports.ResultFromDirections(rideId, duration, distance, currentDuration, currentDistance, polylineTotal, points, ridersInfo);

                    resolve(resp);
                } else {
                    if (err === null) {
                        err = "ZERO RESULTS";
                    }
                    resp = new exports.ResultFromDirections();
                    resp.error = err;
                    resolve(resp);
                }
            });
        } catch (e) {
            resp = new exports.ResultFromDirections();
            resp.error = e;
            resolve(resp);
        }
    });
};

exports.analyseAllRides = (whereWannaGoFrom, whereWannaGoTo, radius, tipo, currentUser, initDate, endDate, gender) => {
    return new Promise(async resolve => {
        var responseObj = {
            results: [],
            errors: []
        };
        var promises = [];

        var ids = [];

        try {
            var snapshot = await globals.db.collection('users').doc(currentUser).collection('appliedRides').get();

            snapshot.forEach((doc) => {
                ids.push(doc.id);
            });

        } catch (e) {
            responseObj.errors.push('Error getting applied rides');
            console.error(e);
            resolve(JSON.stringify(responseObj));
        }

        var typeDenied = tipo === "Servidores" ? "Alunos" : "Servidores";
        var genderDenied = gender === "Homens" ? "Mulheres" : "Homens";


        globals.db.collection('rides').where("status", "==", 0).where('date', ">=", initDate)
            .where('date', "<=", endDate).get()
            .then(async (snapshot) => {
                for (var doc of snapshot.docs) {
                    // eslint-disable-next-line no-await-in-loop
                    var ridersDoc = (await globals.db.collection('rides').doc(doc.id).collection('riders').get());
                    var usedSeats = ridersDoc.docs.length;
                    if (!ids.includes(doc.id.toString()) &&
                        (usedSeats < doc.data().limit) &&
                        (doc.data().typeAccepted !== typeDenied) &&
                        (doc.data().genderAccepted !== genderDenied) &&
                        (doc.data().motorista !== currentUser)) {
                        var departure = new exports.LatLng(doc.data().depLat, doc.data().depLon);
                        if (geolocation_utils.insideCircle(whereWannaGoFrom, departure, radius)) {
                            //console.log(doc.id, '=>', doc.data());
                            var currentDuration = doc.data().currentDuration;
                            var currentDistance = doc.data().currentDistance;
                            if (currentDuration !== undefined && currentDistance !== undefined) {
                                var waypoints = [];
                                var riders = [];
                                var whereToDescs = [];
                                var arrival = new exports.LatLng(doc.data().arrLat, doc.data().arrLon);
                                try {
                                    // eslint-disable-next-line no-await-in-loop
                                    ridersDoc.forEach((d) => {
                                        if (d.data().goTo !== null) {
                                            waypoints.push(new exports.LatLng(d.data().goTo.lat, d.data().goTo.lng));
                                            riders.push(d.id);
                                            whereToDescs.push(d.data().whereToDesc);
                                        }
                                    });
                                    waypoints.push(whereWannaGoTo);
                                    riders.push(currentUser);
                                    whereToDescs.push(null);
                                    promises.push(
                                        exports.directions(
                                            doc.id,
                                            {
                                                origin: departure,
                                                destination: arrival,
                                                mode: globals.mode,
                                                waypoints: waypoints,
                                                alternatives: globals.alternatives,
                                                optimize: globals.optimize
                                            }, currentDuration,
                                            currentDistance,
                                            riders,
                                            whereToDescs
                                        ));
                                } catch (e) {
                                    console.error(e);
                                    console.error("Error getting already riders");
                                }
                            }
                        }
                    }
                }
                resolve((await exports.processPromises(promises)));
                return null;
            })
            .catch((err) => {
                responseObj.errors.push('Error getting documents');
                console.error(err);
                resolve(JSON.stringify(responseObj));
            });
    });
};


exports.processPromises = (promises) => {
    return new Promise((async resolve => {
        var responseObj = {
            results: [],
            errors: []
        };

        var results = await Promise.all(promises).catch((e) => {
            responseObj.errors.push("Error processing promises");
            console.log(e);
            resolve(JSON.stringify(responseObj));
            return;
        });

        if (results !== undefined && results.length !== 0) {
            var results_filtered = results.filter(x => {
                return x.error === undefined;
            });
            var results_error = results.filter((el) => !results_filtered.includes(el));

            //results_filtered = results_filtered.sort(compare_byBestRideCriteriaDistance);

            if (results_filtered.length !== 0) {
                responseObj.results = results_filtered;
                if (results_error.length !== 0) {
                    console.error(results_error);
                }
                resolve(JSON.stringify(responseObj));
            } else {
                responseObj.errors.push("No rides found");
                console.error(results_error);
                resolve(JSON.stringify(responseObj));
            }

        } else {
            responseObj.errors.push("No rides found");
            resolve(JSON.stringify(responseObj));
        }
    }));
};

exports.getSingleRide = async function (rideId, goTo, riderId) {
    var ride = await globals.db.collection('rides').doc(rideId).get();
    ride = ride.data();
    var dep = new exports.LatLng(ride.depLat, ride.depLon);
    var arr = new exports.LatLng(ride.arrLat, ride.arrLon);
    var whereTo = new exports.LatLng(goTo);
    var waypoints = [];
    var riders = [];
    var whereToDescs = [];
    var sn = await globals.db.collection("rides").doc(rideId).collection("riders").get();
    sn.forEach((d) => {
        if (d.data().goTo !== null) {
            waypoints.push(new exports.LatLng(d.data().goTo.lat, d.data().goTo.lng));
            riders.push(d.id);
            whereToDescs.push(d.data().whereToDesc);
        }
    });
    waypoints.push(whereTo);
    riders.push(riderId);
    whereToDescs.push(null);
    var result = await exports.directions(rideId, {
        origin: dep,
        destination: arr,
        mode: globals.mode,
        alternatives: globals.alternatives,
        optimize: globals.optimize,
        waypoints: waypoints

    }, ride.currentDuration, ride.currentDistance, riders, whereToDescs);

    return result;
};

exports.getSingleRideWithMultipleRiders = async function (rideId, goTos, ridersId) {
    var ride = await globals.db.collection('rides').doc(rideId).get();
    ride = ride.data();
    var dep = new exports.LatLng(ride.depLat, ride.depLon);
    var arr = new exports.LatLng(ride.arrLat, ride.arrLon);
    var waypoints = [];
    var riders = [];
    var sn = await globals.db.collection("rides").doc(rideId).collection("riders").get();
    var whereToDescs = [];
    sn.forEach((d) => {
        if (d.data().goTo !== null) {
            waypoints.push(new exports.LatLng(d.data().goTo.lat, d.data().goTo.lng));
            riders.push(d.id);
            whereToDescs.push(d.data().whereToDesc);
        }
    });
    var i = 0;
    goTos.forEach(
        (goTo) => {
            waypoints.push(new exports.LatLng(goTo));
            riders.push(ridersId[i]);
            whereToDescs.push(null);
            i++;
        }
    );
    var result = await exports.directions(rideId, {
        origin: dep,
        destination: arr,
        mode: globals.mode,
        optimize: globals.optimize,
        alternatives: globals.alternatives,
        waypoints: waypoints

    }, ride.currentDuration, ride.currentDistance, riders, whereToDescs);

    return result;
};