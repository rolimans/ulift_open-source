import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<bool> deleteRideById(String rideId) async {
  try {
    await Firestore.instance
        .collection('rides')
        .document(rideId)
        .setData({"status": 2}, merge: true);
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}

Future<void> deleteRideByDriver(String driverId) async {
  try {
    var userRides = Firestore.instance
        .collection("users")
        .document(driverId)
        .collection("rides");
    var docs = await userRides.getDocuments();
    var collection = Firestore.instance.collection('rides');
    for (var doc in docs.documents) {
      collection.document(doc.documentID).delete();
      doc.reference.delete();
    }
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return;
  }
}
