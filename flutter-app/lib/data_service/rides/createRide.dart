import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/rides/ridesAPI.dart';
import 'package:ulift/models/carona.dart';

Future<void> createRide(Carona c) async {
  try {
    String dep = "${c.dep.latitude};${c.dep.longitude}";
    String arr = "${c.arr.latitude};${c.arr.longitude}";
    ResultFromRide routingInfo = await initialRoutingDetails(dep, arr);
    if (routingInfo == null) {
      Crashlytics.instance.log("ERROR CREATING RIDE - ROUTING DETAILS");
    }
    var result = await Firestore.instance.collection('rides').add({
      "motorista": c.motorista,
      "limit": c.limit,
      "typeAccepted": c.typeAccepted,
      "genderAccepted": c.genderAccepted,
      "status": c.status,
      "date": c.date.millisecondsSinceEpoch,
      "depLat": c.dep.latitude,
      "depLon": c.dep.longitude,
      "arrLat": c.arr.latitude,
      "arrLon": c.arr.longitude,
      "depDesc": c.dep.description,
      "arrDesc": c.arr.description,
      "closeNeibourhoodToArr": c.closeNeibourhoodToArr,
      "lastChange": DateTime.now().millisecondsSinceEpoch + timeOffset,
      "initialDuration": routingInfo.duration.inSeconds,
      "initialDistance": routingInfo.distance,
      "currentDuration": routingInfo.duration.inSeconds,
      "currentDistance": routingInfo.distance,
      "polylineTotal": routingInfo.polylineTotal
    });

    await Firestore.instance
        .collection("users")
        .document(c.motorista)
        .collection("rides")
        .document(result.documentID)
        .setData({});
    return;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return;
  }
}
