import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<bool> rateDriver(
    String driverUid, String rideUid, double rating, String feedback) async {
  try {
    List<Future> futures = List();

    futures.add(
        Firestore.instance.collection('users').document(driverUid).updateData({
      "ratingDriver": FieldValue.increment(rating),
      "numberOfDrived": FieldValue.increment(1)
    }));

    if (feedback != null && feedback != '') {
      futures.add(Firestore.instance.collection('feedbacks').add({
        "text": feedback,
        "rideIdOf": rideUid,
        "ratedAs": rating,
        "for": "driver"
      }));
    }

    await Future.wait(futures);

    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}

Future<bool> rateRider(
    String riderUid, String rideUid, double rating, String feedback) async {
  try {
    List<Future> futures = List();

    futures.add(
        Firestore.instance.collection('users').document(riderUid).updateData({
      "ratingRider": FieldValue.increment(rating),
      "numberOfRided": FieldValue.increment(1)
    }));

    if (feedback != null && feedback != '') {
      futures.add(Firestore.instance.collection('feedbacks').add({
        "text": feedback,
        "rideIdOf": rideUid,
        "ratedAs": rating,
        "for": riderUid
      }));
    }

    await Future.wait(futures);

    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}
