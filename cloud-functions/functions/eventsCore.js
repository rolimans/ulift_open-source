const directionsApi = require('./directionsApiCore');
const globals = require('./globals');

process.setMaxListeners(5000);

exports.afterDeleteRide =  function (id, data, shouldReject) {
    var promises = [];
    data.oldId = id;
    promises.push(globals.db.collection('users').doc(data.motorista).collection('rides').doc(id).delete());
    globals.db.collection('rides').doc(id).collection('riders').get().then((snapshot)=>{
        if(snapshot.size !== 0){
            let batch = globals.db.batch();
            snapshot.docs.forEach((doc) => {
                batch.delete(doc.ref);
            });
            batch.commit();
        }
    });
    promises.push(globals.db.collection('oldRides').add(data));
    promises.push(globals.db.collection('users').doc(data.motorista).collection('oldRides').doc(id).create({}));
    globals.db.collection('users').doc(data.motorista).collection('rides').doc(id).collection('requests').get().then((snapshot)=>{
        var usersToDelete = [];
        if(snapshot.size !== 0){
            let batch = globals.db.batch();
            snapshot.docs.forEach((doc) => {
                usersToDelete.push(doc.id);
                batch.delete(doc.ref);
            });
            batch.commit();
            if(shouldReject) {
                usersToDelete.forEach((u) => {
                    globals.db.collection('users').doc(u).collection('appliedRides').doc(id).set({
                        status: true,
                        rejected: true
                    }, {merge: true});
                });
            }
        }
    });
    Promise.all(promises).then(()=>{console.log("DELETED "+id)});
};

/*exports.setRoutingDetailsForRide = function (id, data) {
    var dep = new directionsApi.LatLng(data.depLat, data.depLon);
    var arr = new directionsApi.LatLng(data.arrLat, data.arrLon);
    directionsApi.directions('', {
        origin: dep,
        destination: arr,
        optimize: globals.optimize,
        mode: globals.mode,
        alternatives: globals.alternatives,
    }, 0, 0,[], []).then(r => {
        if (r.error === undefined) {
            var duration = r.duration;
            var distance = r.distance;
            var polylineTotal = r.polylineTotal;
            globals.db.collection('rides').doc(id).update({
                initialDuration: duration,
                initialDistance: distance,
                currentDuration: duration,
                currentDistance: distance,
                polylineTotal: polylineTotal
            });
        } else {
            console.error(r);
        }
        return null;
    }).catch(e => console.error(e));
};
*/