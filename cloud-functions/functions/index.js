const events = require("./eventsCore");
const directionsApi = require('./directionsApiCore');
const globals = require('./globals');
const notifications = require('./notificationsCore');
const geolocation_utils = require('geolocation-utils');

const functions = require('firebase-functions');

process.setMaxListeners(5000);


exports.getSingleRide = functions.https.onRequest(async (request, response) => {
    try {
        var rideId = request.query.rideId;
        var goTo = request.query.goTo;
        var riderId = request.query.riderId;
        var result = await directionsApi.getSingleRide(rideId, goTo, riderId);
        if (result.erro === undefined) {
            response.send(JSON.stringify(result));
        } else {
            response.send("ERROR");
            console.error(result.erro);
        }
    } catch (e) {
        response.send("ERROR");
        console.error(e);
    }
});

exports.onChangeRideRequests = functions.firestore.document('/users/{driverId}/rides/{rideId}/requests/{requesterId}').onCreate(async change => {
    var doc = change;
    var riderId = doc.id;
    var rideId = doc.ref.parent.parent.id;
    var driverId = doc.ref.parent.parent.parent.parent.id;

    var requesterDoc = await globals.db.collection('users').doc(riderId).get();
    var requesterName = requesterDoc.data().name;
    var iconUrl = requesterDoc.data().picUrl;

    let not = notifications.createNewRequestNotification(requesterName, rideId, riderId, iconUrl);

    notifications.sendNotificationByUserId(driverId, not);

});

exports.onNewDriverRequest = functions.firestore.document("/users/{user}/license/myLicense").onWrite( change =>{
    if(change.type !== "removed"){
        let userId = change.after.ref.parent.parent.id;
        let docData = change.after.data();
        globals.db.collection("driverRequests").doc(userId).set({
            date: new Date().getTime(),
            userId: userId,
            cnhNumber: docData.cnhNumber,
            cnhValidate: docData.cnhValidate,
            cpfUser: docData.cpfUser,
            backUrl: docData.backUrl,
            frontUrl: docData.frontUrl,
            selfieUrl: docData.selfieUrl
        });
    }
});

exports.onChangeRideRequest = functions.firestore.document('/users/{userId}/appliedRides/{rideId}').onUpdate(async change => {
    var doc = change.after;
    var requesterId = doc.ref.parent.parent.id;
    var docBefore = change.before.data();
    var rideId = doc.id;
    var driverId = doc.data().motorista;
    if (doc.data().status !== docBefore.status) {
        if (doc.data().status === true && doc.data().rejected === undefined) {
            let date = globals.dateFormatted(new Date(doc.data().rideDate));
            let iconUrl = (await globals.db.collection('users').doc(driverId).get()).data().picUrl;
            let not = notifications.createRequestAcceptedNotification(date, rideId, iconUrl);
            notifications.sendNotificationByUserId(requesterId, not);
        }
    }

    if (doc.data().rejected !== docBefore.rejected) {
        if (doc.data().rejected === true && doc.data().dropped !== true && doc.data().droppedBf !== true) {
            var rideDoc = await globals.db.collection('rides').doc(rideId).get();
            if (rideDoc.exists && rideDoc.data().status === 0) {
                let date = globals.dateFormatted(new Date(doc.data().rideDate));
                let iconUrl = (await globals.db.collection('users').doc(driverId).get()).data().picUrl;
                let not = notifications.createRemovedNotification(date, iconUrl, rideId);
                notifications.sendNotificationByUserId(requesterId, not);
            }
        }

    }
    if (doc.data().dropped !== docBefore.dropped) {
        if (doc.data().dropped === true) {
            var requesterDoc = await globals.db.collection('users').doc(requesterId).get();
            var requesterName = requesterDoc.data().name;
            let iconUrl = requesterDoc.data().picUrl;
            let not = notifications.createRequestDropNotification(requesterName, rideId, iconUrl);
            notifications.sendNotificationByUserId(driverId, not);
        }
    }
});

exports.onNewMessage = functions.firestore.document('/rides/{rideId}/riders/{riderId}/chat/{messageId}').onCreate(async change => {
    var doc = change;
    var rideId = doc.ref.parent.parent.parent.parent.id;
    var from = doc.data().from;
    var content = doc.data().text;
    var to = doc.data().to;
    var senderDoc = await globals.db.collection('users').doc(from).get();
    var rideDoc = await  globals.db.collection('rides').doc(rideId).get();
    var senderName = senderDoc.data().name;
    var iconUrl = senderDoc.data().picUrl;
    var driverId = rideDoc.data().motorista;
    var riderId = doc.ref.parent.parent.id;
    var not = notifications.createChatNotification(senderName, content, rideId, from, iconUrl, driverId, riderId);
    notifications.sendNotificationByUserId(to, not);
});


exports.getSingleRideWithMultipleRiders = functions.https.onRequest(async (request, response) => {
    try {
        var js = request.query.js;
        js = JSON.parse(js);
        var rideId = js.rideId;
        var goTos = js.goTos;
        var ridersId = js.ridersId;
        var result = await directionsApi.getSingleRideWithMultipleRiders(rideId, goTos, ridersId);
        if (result.erro === undefined) {
            response.send(JSON.stringify(result));
        } else {
            response.send("ERROR");
            console.error(result.erro);
        }
    } catch (e) {
        response.send("ERROR");
        console.error(e);
    }
});

exports.getInitialRoutingDetailsForRide = functions.https.onRequest((request, response) => {
    try {
        var dep = new directionsApi.LatLng(request.query.dep);
        var arr = new directionsApi.LatLng(request.query.arr);
        if (dep === null || arr === null) {
            response.send("ERROR");
            console.error("INVALID ARGS");
            return;
        }
        directionsApi.directions('', {
            origin: dep,
            destination: arr,
            optimize: globals.optimize,
            mode: globals.mode,
            alternatives: globals.alternatives,
        }, 0, 0, [], []).then(r => {
            if (r.error === undefined) {
                response.send(JSON.stringify(r));
            } else {
                response.send("ERROR");
                console.error(r.erro);
            }
            return null;
        }).catch(e => {
            response.send("ERROR");
            console.error(e);
        });
    }catch (e) {
        console.error(e);
        response.send("ERROR");
    }
});

exports.getBestRides = functions.https.onRequest(async (request, response) => {
    try {
        var js = request.query.js;
        js = JSON.parse(js);
        var currentUser = js.currentUser;
        var whereWannaGoFrom = new directionsApi.LatLng(js.goFrom);
        var whereWannaGoTo = new directionsApi.LatLng(js.goTo);
        var radius = js.radius;
        var initDate = js.initDate;
        var tipo = js.tipo;
        var gender = js.gender;
        var endDate = js.endDate;
        if (initDate === undefined || initDate === null) {
            initDate = (new Date()).getTime();
        }
        if (endDate === undefined || endDate === null) {
            endDate = Number.POSITIVE_INFINITY;
        }
    } catch (e) {
        var resultObj = {
            results: [],
            errors: []
        };
        resultObj.errors.push("Invalid arguments");
        response.send(JSON.stringify(resultObj));
        return;
    }
    var r = await directionsApi.analyseAllRides(whereWannaGoFrom, whereWannaGoTo, radius, tipo, currentUser, initDate, endDate,gender);
    response.send(r);
});

exports.onCreateRide = functions.firestore.document('rides/{rideId}').onCreate(async (change, context) => {
    var picUrl = null;
    var rideData = change.data();
    const today = new Date().getTime();
    const rideDep = new directionsApi.LatLng(rideData.depLat,rideData.depLon);
    var snapshot = globals.db.collection("frequentSearches").where("paused",'==',false);
    if(rideData.typeAccepted === "Alunos"){
        snapshot = snapshot.where("tipo", '==','Alunos');
    }
    if(rideData.typeAccepted === "Servidores"){
        snapshot = snapshot.where("tipo", '==','Servidores');
    }
    if(rideData.genderAccepted === "Homens"){
        snapshot = snapshot.where("gender", '==','Homens');
    }
    if(rideData.genderAccepted === "Mulheres"){
        snapshot = snapshot.where("gender", '==','Mulheres');
    }

    var sn = await snapshot.get();
    for(let doc of sn.docs){
        let localData = doc.data();
        let initDate = localData.initDate;
        let endDate = localData.endDate;
        let rideDate = new Date(rideData.date);
        let rideWeekDay = rideDate.getDay();
        if((initDate===null || (initDate<= rideData.date && endDate>= rideData.date)) && rideData.motorista !== localData.author){
            if(localData.daysOfWeek[rideWeekDay]){
                let whereIWannaGoFrom = new directionsApi.LatLng(localData.goFrom[0],localData.goFrom[1]);
                if(geolocation_utils.insideCircle(whereIWannaGoFrom, rideDep, localData.radius)){
                    if(picUrl === null){
                        // eslint-disable-next-line no-await-in-loop
                        picUrl = (await globals.db.collection('users').doc(rideData.motorista).get()).data().picUrl;
                    }
                    let obj = {
                        radius: localData.radius,
                        dep: localData.goFrom,
                        depDesc: localData.goFromDesc,
                        arr: localData.goTo,
                        arrDesc: localData.goToDesc,
                    };
                    let not = notifications.createFrequentSearch(obj,picUrl,localData.standard);
                    notifications.sendNotificationByUserId(localData.author,not);
                    console.log(not);
                }
            }
        }
        if(endDate!==null && endDate < today){
            doc.ref.delete();
        }
    }
});

exports.onUserChange = functions.firestore.document('/users/{userId}').onUpdate( change => {
    let before = change.before.data();
    let after = change.after.data();

    if(before.onGoingRequest === true && after.onGoingRequest === false){
        if(after.tipo === 2){
            let not = notifications.createDriverRequestNotification(true);
            notifications.sendNotificationByUserId(change.after.id, not);
        }else{
            let not = notifications.createDriverRequestNotification(false);
            notifications.sendNotificationByUserId(change.after.id, not);
        }
    }
});

exports.onChangeRide = functions.firestore.document('/rides/{rideId}').onUpdate(async change => {
    if (change.after.data().status === 2) {
        var riders = await globals.db.collection('rides').doc(change.after.id).collection('riders').get();
        globals.db.collection('rides').doc(change.after.id).delete();
        events.afterDeleteRide(change.after.id, change.after.data(), true);
        var iconUrl = (await globals.db.collection('users').doc(change.after.data().motorista).get()).data().picUrl;
        if (riders.docs.length > 0) {
            let date = globals.dateFormatted(new Date(change.after.data().date));
            let not = notifications.createRideDeletedNotification(date, iconUrl,change.before.id);
            riders.docs.forEach((doc) => {
                notifications.sendNotificationByUserId(doc.id, not);
            });
        }
    }
    else if(change.after.data().status === 1){
        let riders = await globals.db.collection('rides').doc(change.after.id).collection('riders').get();
        let rideId = change.after.id;
        let driverId = change.after.data().motorista;
        let iconUrl = (await globals.db.collection('users').doc(driverId).get()).data().picUrl;
        let date = globals.dateFormatted(new Date(change.after.data().date));
        let not = notifications.createInitRideNotification(rideId,date,true,iconUrl);
        notifications.sendNotificationByUserId(driverId,not);
        if (riders.docs.length > 0) {
            let not = notifications.createInitRideNotification(rideId,date,false,iconUrl);
            riders.docs.forEach((doc) => {
                notifications.sendNotificationByUserId(doc.id, not);
            });
        }
    }
    else if(change.after.data().status === 3){
        let riders = await globals.db.collection('rides').doc(change.after.id).collection('riders').get();
        let rideId = change.after.id;
        let driverId = change.after.data().motorista;
        let driverDoc = await globals.db.collection("users").doc(driverId).get();
        let driverName = driverDoc.data().name;
        let picUrl = driverDoc.data().picUrl;
        let date = globals.dateFormatted(new Date(change.after.data().date));
        let notToRiders = notifications.createRateDriver(rideId,driverId,driverName,date,picUrl);
        var ridersInfo = [];
        globals.db.collection('rides').doc(change.after.id).delete();
        events.afterDeleteRide(change.after.id, change.after.data(), true);
        if (riders.docs.length > 0) {
            for(var riderDoc of riders.docs){
                notifications.sendNotificationByUserId(riderDoc.id, notToRiders);
                let riderId = riderDoc.id;
                // eslint-disable-next-line no-await-in-loop
                let riderInf = await globals.db.collection("users").doc(riderId).get();
                let riderName = riderInf.data().name;
                let riderPic = riderInf.data().picUrl;
                ridersInfo.push({
                    riderId: riderId!==undefined?riderId.slice():null,
                    riderName: riderName!==undefined?riderName.slice():null,
                    picUrl: riderPic!==undefined?riderPic.slice():null

                });
            }
            let not = notifications.createRateRiders(rideId,date,ridersInfo,picUrl);
            notifications.sendNotificationByUserId(driverId,not);
        }
    }
});

exports.DeleteOldRides = functions.https.onRequest((request, response) => {

    const date = (new Date()).getTime();

    globals.db.collection("rides").where("date", "<=", date)
        .get()
        .then(querySnapshot => {

            querySnapshot.forEach(doc => {
                globals.db.collection('rides').doc(doc.id).delete();
            });
            response.send("OK");
            return null;

        }).catch(e => {
        console.log(e);
        response.status(500).send(e);
    })
});