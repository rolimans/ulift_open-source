import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/rides/ridesAPI.dart';
import 'package:ulift/models/carona.dart';
import 'package:ulift/models/usuario.dart';

import '../user/userDataService.dart';
import 'applyToRide.dart';

Stream<QuerySnapshot> getValidRidesSnapshot() {
  return Firestore.instance
      .collection('rides')
      .where('status', isEqualTo: 0)
      .where('date',
          isGreaterThanOrEqualTo:
              DateTime.now().millisecondsSinceEpoch + timeOffset)
      .snapshots();
}

Future<Carona> getRideById(String id) async {
  var doc = await Firestore.instance.collection('rides').document(id).get();
  if (!doc.exists || doc.data['status'] > 1) {
    return null;
  }
  Carona carona = Carona.fromDB(doc.data);
  var user = await Firestore.instance
      .collection('users')
      .document(carona.motorista)
      .get();
  int usedSeats = (await Firestore.instance
          .collection('rides')
          .document(id)
          .collection('riders')
          .getDocuments())
      .documents
      .length;
  carona.usedSeats = usedSeats;
  carona.motoristaName = user.data['name'];
  carona.picUrlDriver = user.data['picUrl'];
  carona.motoristaRating =
      user.data['ratingDriver'] / user.data["numberOfDrived"];
  carona.uid = id;
  return carona;
}

/*Future<List> getNewApplicationsOfRideByRide(Carona carona) async{
  List<ResultFromRide> ridesInfoNotAccepted = List<ResultFromRide>();
  List<ResultFromRide> ridesInfoAccepted = List<ResultFromRide>();
  QuerySnapshot docs = await Firestore.instance.collection('users').document(carona.motorista).collection('rides').document(carona.uid).collection('requests').getDocuments();
  for(var doc in docs.documents){
    ResultFromRide r = ResultFromRide.fromJson(doc.data,doc.documentID);
    r.rideId = carona.uid;
    if(carona.ridersInfo==null ||carona.ridersInfo[r.riderUid]==null){
      ridesInfoNotAccepted.add(r);
    }else{
      ridesInfoAccepted.add(r);
    }
  }
  return [ridesInfoNotAccepted,ridesInfoAccepted];
}*/

Stream<Map> getNewApplicationsOfRideByRideStream(Carona carona) {
  StreamController<Map> controller;
  StreamSubscription<QuerySnapshot> docsListener;

  void _onListen(QuerySnapshot docs) async {
    Map answer = Map();
    List<ResultFromRide> ridesInfoNotAccepted = List<ResultFromRide>();
    List<ResultFromRide> ridesInfoAccepted = List<ResultFromRide>();
    Map<String, Usuario> riders = Map();
    List<Future<Usuario>> futures = List();
    for (var doc in docs.documents) {
      ResultFromRide r = ResultFromRide.fromJson(doc.data, doc.documentID);
      r.rideId = carona.uid;
      if (carona.ridersInfo == null || carona.ridersInfo[r.riderUid] == null) {
        ridesInfoNotAccepted.add(r);
      } else {
        ridesInfoAccepted.add(r);
      }
    }
    for (var i in ridesInfoNotAccepted) {
      futures.add(getUser(i.riderUid));
    }
    for (var i in ridesInfoAccepted) {
      futures.add(getUser(i.riderUid));
    }
    List<Usuario> users = await Future.wait(futures);
    for (Usuario user in users) {
      riders[user.uid] = user;
    }
    answer['riders'] = riders;
    answer['ridesInfoNotAccepted'] = ridesInfoNotAccepted;
    answer['ridesInfoAccepted'] = ridesInfoAccepted;
    controller.add(answer);
  }

  void _start() {
    docsListener = Firestore.instance
        .collection('users')
        .document(carona.motorista)
        .collection('rides')
        .document(carona.uid)
        .collection('requests')
        .snapshots()
        .listen(_onListen);
  }

  void _end() {
    docsListener?.cancel();
    controller.close();
  }

  controller = StreamController<Map>(
      onListen: _start, onPause: _end, onResume: _start, onCancel: _end);

  return controller.stream;
}

Future<ResultFromRide> getAppliedRideAndInfoByRide(
    Carona ride, bool status) async {
  try {
    var rideDoc =
        await Firestore.instance.collection('rides').document(ride.uid).get();
    if (!rideDoc.exists || rideDoc.data['status'] > 1) {
      Crashlytics.instance
          .log("CARONA INEXISTENTE getAppliedRideAndInfoByRide");
      return null;
    }
    DocumentSnapshot rideInfoDocument = await Firestore.instance
        .collection('users')
        .document(ride.motorista)
        .collection('rides')
        .document(ride.uid)
        .collection('requests')
        .document(FireUserService.user.uid)
        .get();

    ResultFromRide rideInfo = ResultFromRide.fromJson(
        rideInfoDocument.data, FireUserService.user.uid);
    rideInfo.rideId = ride.uid;

    if (ride.lastChange.millisecondsSinceEpoch ==
        rideInfo.lastChangeAtTime.millisecondsSinceEpoch) {
      return rideInfo;
    } else {
      LatLng goTo = rideInfo.myPoint;
      String goToString = "${goTo.latitude};${goTo.longitude}";
      ResultFromRide rideInfoUpdated =
          await singleRideApi(ride.uid, goToString, FireUserService.user.uid);
      if (rideInfo == null) {
        return null;
      }
      rideInfoUpdated.whereToDesc = rideInfo.whereToDesc;
      applyToRideByResultRideAndUser(
              rideInfoUpdated, ride, FireUserService.user.uid, status)
          .then((did) {
        if (!did) {
          return null;
        }
      });
      return rideInfoUpdated;
    }
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return null;
  }
}

/*Future<List<AppliedRideInfo>> getAppliedRidesDidNotHappenByUserId(String id) async{
  var rides = await Firestore.instance.collection("users").document(id).collection("appliedRides").where('rideDate', isGreaterThan: DateTime.now().millisecondsSinceEpoch).getDocuments();
  var ridesDocs = rides.documents;
  List<AppliedRideInfo> applications = List();
  ridesDocs.forEach((ride){
    if(ride.data['rejected']!=true)
      applications.add(AppliedRideInfo.fromDB(ride.data, ride.documentID));
  });
  return applications;
}*/

Stream<List> getAppliedRidesDidNotHappenByUserIdStream(String id) {
  StreamController<List> controller;
  StreamSubscription<QuerySnapshot> ridesListener;

  void _onListen(QuerySnapshot rides) {
    var ridesDocs = rides.documents;
    List<AppliedRideInfo> applications = List();
    ridesDocs.forEach((ride) {
      if (ride.data['rejected'] != true)
        applications.add(AppliedRideInfo.fromDB(ride.data, ride.documentID));
    });
    controller.add(applications);
  }

  void _start() {
    ridesListener = Firestore.instance
        .collection("users")
        .document(id)
        .collection("appliedRides")
        .snapshots()
        .listen(_onListen);
  }

  void _end() {
    ridesListener?.cancel();
    controller.close();
  }

  controller = StreamController<List>(
      onListen: _start, onPause: _end, onResume: _start, onCancel: _end);

  return controller.stream;
}

/*Future<List<Carona>> getOfferedRidesDidNotHappenByUserId(String id) async{
  var rides = await Firestore.instance.collection("rides").where("motorista",isEqualTo: id).getDocuments();
  var ridesDocs = rides.documents;
  List<Carona> offers = List();
  for(var ride in ridesDocs){
    Carona r = Carona.fromDB(ride.data);

    r.motoristaName = UserService.user.nome;
    r.picUrlDriver = UserService.user.picUrl;
    r.uid = ride.documentID;

  /*var user = await Firestore.instance.collection('users').document(r.motorista).get();
    r.motoristaName = user.data['name'];
    r.picUrlDriver = user.data['picUrl'];
    r.uid = ride.documentID;
   */
    offers.add(r);
  }
  return offers;
}*/

Stream<List> getOfferedRidesDidNotHappenOrOnGoingByUserIdStream(String id) {
  StreamController<List> controller;
  StreamSubscription<QuerySnapshot> ridesListener;

  void _onListen(QuerySnapshot rides) async {
    var ridesDocs = rides.documents;
    List<Carona> offers = List();
    for (var ride in ridesDocs) {
      Carona r = Carona.fromDB(ride.data);
      int usedSeats = (await Firestore.instance
              .collection('rides')
              .document(id)
              .collection('riders')
              .getDocuments())
          .documents
          .length;
      r.usedSeats = usedSeats;
      r.motoristaName = UserService.user.nome;
      r.picUrlDriver = UserService.user.picUrl;
      r.motoristaRating = UserService.user.ratingDriver;
      r.uid = ride.documentID;

      /*var user = await Firestore.instance.collection('users').document(r.motorista).get();
    r.motoristaName = user.data['name'];
    r.picUrlDriver = user.data['picUrl'];
    r.uid = ride.documentID;
   */
      offers.add(r);
    }
    controller.add(offers);
  }

  void _start() {
    ridesListener = Firestore.instance
        .collection("rides")
        .where("motorista", isEqualTo: id)
        .where('status', isLessThanOrEqualTo: 1)
        .snapshots()
        .listen(_onListen);
  }

  void _end() {
    ridesListener?.cancel();
    controller.close();
  }

  controller = StreamController<List>(
      onListen: _start, onPause: _end, onResume: _start, onCancel: _end);

  return controller.stream;
}

class AppliedRideInfo {
  bool status;
  String motorista;
  DateTime lastChangeAtTime;
  String rideUid;
  bool rejected;
  DateTime rideDate;

  AppliedRideInfo.fromDB(Map data, String rideUid) {
    status = data['status'];
    motorista = data['motorista'];
    lastChangeAtTime =
        DateTime.fromMillisecondsSinceEpoch(data['lastChangeAtTime']);
    this.rideUid = rideUid;
    rejected = data['rejected'] == null ? false : data['rejected'];
    rideDate = DateTime.fromMillisecondsSinceEpoch(data['rideDate']);
  }
}
