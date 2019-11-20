/*const events = require("./eventsCore");
const directionsApi = require('./directionsApiCore');
const globals = require('./globals');

process.setMaxListeners(5000);


exports.testemo = async function () {
    var dep = new directionsApi.LatLng(-20.172700, -44.909110);
    var arr = new directionsApi.LatLng(-20.139871, -44.893634);
    var waypoints = [];
    var riders = [];
    var rideId = "hapC0XqFOZcW0Ug6LGxY";
    var ride = await globals.db.collection('rides').doc(rideId).get();
    var sn = await globals.db.collection("rides").doc(rideId).collection("riders").get();

    sn.forEach((d)=>{
        if(d.data().goTo!==null) {
            waypoints.push(new LatLng(d.data().goTo.lat, d.data().goTo.lng));
            riders.push(d.id);
        }
    });
    var ridersId = [];//["PARQUE"];
    var goTos = [];//["-20.174103; -44.919132"];
    var i = 0;
    goTos.forEach(
        (goTo)=> {
            waypoints.push(new LatLng(goTo));
            riders.push(ridersId[i]);
            i++;
        }
    );
    var result = await directionsApi.directions(10,{
        origin: dep,
        destination: arr,
        mode: globals.mode,
        optimize: globals.optimize,
        alternatives: globals.alternatives,
        waypoints: waypoints

    },10,10,riders);

    console.log(result);
};

exports.test =  async function() {
    var js = {
        currentUser: "anal",
        tipo: "Alunos",
        goTo: "-20.127981; -44.881977",
        goFrom: "-20.139835; -44.893715",
        gender: "Homens",
        radius: 1000,
    };
    var currentUser = js.currentUser;
    var tipo = js.tipo;
    var whereWannaGoFrom = new LatLng(js.goFrom);
    var whereWannaGoTo = new LatLng(js.goTo);
    var radius = js.radius;
    var initDate = js.initDate;
    var endDate = js.endDate;
    if (initDate === undefined || initDate === null) {
        initDate = (new Date()).getTime();
    }
    if (endDate === undefined || endDate === null) {
        endDate = Number.POSITIVE_INFINITY;
    }
    var r = await directionsApi.analyseAllRides(whereWannaGoFrom, whereWannaGoTo, radius, tipo, currentUser, initDate, endDate);
    var rs = JSON.parse(r);
    console.log(rs);
};

exports.test2 =  async function() {
    // eslint-disable-next-line promise/catch-or-return
    globals.db.collection('rides').get()
    // eslint-disable-next-line promise/always-return
        .then(async (snapshot) => {
            snapshot.forEach((doc) => {
                events.setRoutingDetailsForRide(doc.id, doc.data());
            });
        });
};

exports.test3 =  async function(){
    var result = await directionsApi.getSingleRideWithMultipleRiders("lx1qRrFdJfQGoxRsZdHP",[],[]);
    console.log(result);
};*/