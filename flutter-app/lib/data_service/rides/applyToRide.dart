import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:ulift/data_service/rides/ridesAPI.dart';
import 'package:ulift/models/carona.dart';

Future<bool> applyToRideByResultRideAndUser(
    ResultFromRide rideResult, Carona ride, String userId, bool status) async {
  try {
    var rideDoc =
        await Firestore.instance.collection('rides').document(ride.uid).get();
    if (!rideDoc.exists || rideDoc.data['status'] != 0) {
      Crashlytics.instance.log("CANNOT APPLY TO RIDE ANYMORE");
      return false;
    }
    await Firestore.instance
        .collection("users")
        .document(ride.motorista)
        .collection("rides")
        .document(rideResult.rideId)
        .collection('requests')
        .document(userId)
        .setData({
      "duration": rideResult.duration.inSeconds,
      "distance": rideResult.distance,
      "polylineTotal": rideResult.polylineTotal,
      "points": rideResult.pointsToMapList,
      'currentDuration': rideResult.currentDuration.inSeconds,
      'currentDistance': rideResult.currentDistance,
      'lastChangeAtTime': ride.lastChange.millisecondsSinceEpoch,
      'ridersInfo': rideResult.ridersInfo,
      'whereToDesc': rideResult.whereToDesc
    });

    await Firestore.instance
        .collection("users")
        .document(userId)
        .collection("appliedRides")
        .document(rideResult.rideId)
        .setData({
      "status": status,
      "motorista": ride.motorista,
      'lastChangeAtTime': ride.lastChange.millisecondsSinceEpoch,
      "rideDate": ride.date.millisecondsSinceEpoch
    });
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}

Future<bool> updateApplyToRideByResultRideAndUser(
    ResultFromRide rideResult, Carona ride, String userId) async {
  try {
    var rideDoc =
        await Firestore.instance.collection('rides').document(ride.uid).get();

    if (!rideDoc.exists || rideDoc.data['status'] != 0) {
      return false;
    }

    var riderDoc = await Firestore.instance
        .collection('rides')
        .document(ride.uid)
        .collection('riders')
        .document(userId)
        .get();

    if (!riderDoc.exists) {
      return false;
    }

    var docRef = Firestore.instance
        .collection("users")
        .document(ride.motorista)
        .collection("rides")
        .document(rideResult.rideId)
        .collection('requests')
        .document(userId);

    await docRef.setData({
      "duration": rideResult.duration.inSeconds,
      "distance": rideResult.distance,
      "polylineTotal": rideResult.polylineTotal,
      "points": rideResult.pointsToMapList,
      'currentDuration': ride.initialDistance,
      'currentDistance': ride.initialDuration.inSeconds,
      'lastChangeAtTime': ride.lastChange.millisecondsSinceEpoch,
    }, merge: true);

    DocumentSnapshot doc = await docRef.get();

    if (doc.data['ridersInfo'] != null) {
      await docRef.updateData({
        "ridersInfo": rideResult.ridersInfo,
      });
    } else {
      await docRef.setData({
        "ridersInfo": rideResult.ridersInfo,
      }, merge: true);
    }

    await Firestore.instance
        .collection("users")
        .document(userId)
        .collection("appliedRides")
        .document(rideResult.rideId)
        .setData({
      "status": true,
      "motorista": ride.motorista,
      'lastChangeAtTime': ride.lastChange.millisecondsSinceEpoch
    }, merge: true);
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}
