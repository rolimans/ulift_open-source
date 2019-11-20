import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:ulift/data_service/rides/applyToRide.dart';
import 'package:ulift/data_service/rides/ridesAPI.dart';
import 'package:ulift/models/carona.dart';

/*Future<bool> acceptRideFromRideInfoAndRide(
    ResultFromRide rideInfo, Carona ride) async {
  try {
    var rideDoc =
        Firestore.instance.collection("rides").document(rideInfo.rideId);

    ride.lastChange = DateTime.now();

    await rideDoc.updateData({
      "currentDistance": rideInfo.distance,
      "currentDuration": rideInfo.duration.inSeconds,
      "lastChange": ride.lastChange.millisecondsSinceEpoch,
      "polylineTotal": rideInfo.polylineTotal,
      "motorista": ride.motorista
    });

    DocumentSnapshot doc = await rideDoc.get();

    if(doc.data['ridersInfo']!=null) {
      await rideDoc.updateData(
          {
            "ridersInfo": rideInfo.ridersInfo,
          });
    }else{
      await rideDoc.setData(
          {
            "ridersInfo": rideInfo.ridersInfo,
          },merge: true);
    }

    await rideDoc.collection("riders").document(rideInfo.riderUid).setData({
      "goTo": {
        "lat": rideInfo.myPoint.latitude,
        "lng": rideInfo.myPoint.longitude
      },
      "whereToDesc": rideInfo.whereToDesc
    });

    if (!(await updateApplyToRideByResultRideAndUser(
        rideInfo, ride, rideInfo.riderUid))) {
      throw Exception("ERROR APPLYING");
    }
    return true;
  } catch (e) {
    print(e);
    return false;
  }
}*/

Future<bool> acceptRideFromRidesInfoAndRide(
    List<ResultFromRide> ridesInfo, Carona ride) async {
  try {
    ResultFromRide genericRideInfo = ridesInfo.first;

    var rideDoc = Firestore.instance.collection("rides").document(ride.uid);

    var rideDocInfo = await rideDoc.get();
    if (!rideDocInfo.exists || rideDocInfo.data['status'] != 0) {
      Crashlytics.instance.log('CANNOT ACCEPT RIDE ANYMORE');
      return false;
    }

    ride.lastChange = DateTime.now();

    await rideDoc.updateData({
      "currentDistance": genericRideInfo.distance,
      "currentDuration": genericRideInfo.duration.inSeconds,
      "lastChange": ride.lastChange.millisecondsSinceEpoch,
      "polylineTotal": genericRideInfo.polylineTotal,
      "motorista": ride.motorista
    });

    DocumentSnapshot doc = await rideDoc.get();

    if (doc.data['ridersInfo'] != null) {
      await rideDoc.updateData({
        "ridersInfo": genericRideInfo.ridersInfo,
      });
    } else {
      await rideDoc.setData({
        "ridersInfo": genericRideInfo.ridersInfo,
      }, merge: true);
    }

    List<Future> futures = List();
    List<Future> futureRiders = List();

    for (ResultFromRide rideInfo in ridesInfo) {
      if (rideInfo.riderUid == null) {
        Crashlytics.instance.log("FATAL ERROR ACCEPTING RIDE");
        break;
      }
      futureRiders.add(
          rideDoc.collection("riders").document(rideInfo.riderUid).setData({
        "goTo": {
          "lat": rideInfo.myPoint.latitude,
          "lng": rideInfo.myPoint.longitude
        },
        "whereToDesc": rideInfo.whereToDesc
      }));
      futures.add(updateApplyToRideByResultRideAndUser(
          rideInfo, ride, rideInfo.riderUid));
    }
    await Future.wait(futureRiders);
    var results = await Future.wait(futures);

    var i = 0;
    bool error = false;

    for (var result in results) {
      if (!result) {
        Crashlytics.instance
            .log("ERROR APPLYING USER ${ridesInfo[i].riderUid}");
        error = true;
      }
      i++;
    }
    if (error) {
      return false;
    }
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}

Future<bool> removeRiderFromRidesInfoAndRide(
    List<ResultFromRide> ridesInfo, Carona ride) async {
  try {
    ResultFromRide genericRideInfo = ridesInfo.first;

    var rideDoc = Firestore.instance.collection("rides").document(ride.uid);
    var rideDocInfo = await rideDoc.get();
    if (!rideDocInfo.exists || rideDocInfo.data['status'] != 0) {
      return false;
    }

    ride.lastChange = DateTime.now();

    await rideDoc.updateData({
      "currentDistance": genericRideInfo.distance,
      "currentDuration": genericRideInfo.duration.inSeconds,
      "lastChange": ride.lastChange.millisecondsSinceEpoch,
      "polylineTotal": genericRideInfo.polylineTotal,
      "motorista": ride.motorista
    });

    await rideDoc.updateData({"ridersInfo": genericRideInfo.ridersInfo});

    List<Future> futures = List();

    for (ResultFromRide rideInfo in ridesInfo) {
      futures.add(updateApplyToRideByResultRideAndUser(
          rideInfo, ride, rideInfo.riderUid));
    }

    var results = await Future.wait(futures);

    var i = 0;
    bool error = false;

    for (var result in results) {
      if (!result) {
        Crashlytics.instance
            .log("ERROR APPLYING USER ${ridesInfo[i].riderUid}");
        error = true;
      }
      i++;
    }
    if (error) {
      return false;
    }
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}

Future<bool> resetRideFromRidesInfoAndRide(
    ResultFromRide rideInfo, Carona ride) async {
  try {
    var rideDoc = Firestore.instance.collection("rides").document(ride.uid);

    var rideDocInfo = await rideDoc.get();
    if (!rideDocInfo.exists || rideDocInfo.data['status'] != 0) {
      return false;
    }

    ride.lastChange = DateTime.now();

    await rideDoc.updateData({
      "currentDistance": rideInfo.distance,
      "currentDuration": rideInfo.duration.inSeconds,
      "lastChange": ride.lastChange.millisecondsSinceEpoch,
      "polylineTotal": rideInfo.polylineTotal,
      "motorista": ride.motorista,
      "initialDistance": rideInfo.distance,
      "initialDuration": rideInfo.duration.inSeconds
    });

    await rideDoc.setData({"ridersInfo": null, "motorista": ride.motorista},
        merge: true);

    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}

Future<bool> removeRiderFromRideInfoAndRide(
    ResultFromRide rideInfo, Carona ride, bool dropped) async {
  try {
    await Firestore.instance
        .collection('rides')
        .document(ride.uid)
        .collection('riders')
        .document(rideInfo.riderUid)
        .delete();
    await Firestore.instance
        .collection('users')
        .document(ride.motorista)
        .collection("rides")
        .document(ride.uid)
        .collection("requests")
        .document(rideInfo.riderUid)
        .delete();

    var drop = dropped ? true : null;

    await Firestore.instance
        .collection("users")
        .document(rideInfo.riderUid)
        .collection("appliedRides")
        .document(ride.uid)
        .setData({"rejected": true, "dropped": drop}, merge: true);
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}

Future<bool> removeRequest(ResultFromRide rideInfo, Carona ride) async {
  try {
    await Firestore.instance
        .collection("users")
        .document(rideInfo.riderUid)
        .collection("appliedRides")
        .document(ride.uid)
        .setData({"rejected": true, "droppedBf": true}, merge: true);

    await Firestore.instance
        .collection('users')
        .document(ride.motorista)
        .collection("rides")
        .document(ride.uid)
        .collection("requests")
        .document(rideInfo.riderUid)
        .delete();
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}
