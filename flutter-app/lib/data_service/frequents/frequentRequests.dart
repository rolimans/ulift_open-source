import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/rides/ridesAPI.dart';

class DataForFrequentSearch {
  String author;
  double radius;
  String goToDesc;
  String goFromDesc;
  List<double> goTo;
  List<double> goFrom;
  int initDate;
  int endDate;
  String tipo;
  String gender;
  List<bool> daysOfWeek;
  bool paused = false;
  bool standard;

  DataForFrequentSearch.fromDataToGetRides(DataToGetRides data,
      {this.goFromDesc, this.goTo, this.goToDesc, this.goFrom}) {
    this.tipo = data.tipo;
    this.gender = data.gender;
    this.author = data.currentUser;
    this.radius = data.radius;
    if (data.initDate != null) {
      this.initDate = data.initDate;
      this.endDate = data.endDate;
    } else {
      this.initDate = DateTime.now().millisecondsSinceEpoch + timeOffset;
      this.endDate = DateTime.now().millisecondsSinceEpoch +
          timeOffset +
          Duration(days: 1).inMilliseconds;
    }
    this.daysOfWeek = [
      true,
      true,
      true,
      true,
      true,
      true,
      true,
    ];
    this.standard = false;
  }

  DataForFrequentSearch(
      {this.author,
      this.radius,
      this.initDate,
      this.endDate,
      this.goTo,
      this.goFrom,
      this.daysOfWeek,
      this.goFromDesc,
      this.goToDesc,
      this.standard,
      this.tipo,
      this.gender});

  Map<String, dynamic> toJson() => {
        'goTo': goTo,
        'goFrom': goFrom,
        "goToDesc": goToDesc,
        "goFromDesc": goFromDesc,
        'radius': radius,
        'author': author,
        'initDate': initDate,
        'endDate': endDate,
        "daysOfWeek": daysOfWeek,
        "paused": paused,
        "gender": gender,
        "tipo": tipo,
        "standard": standard
      };
}

class DataForFrequentOffer {
  String author;
  String type;
  String gender;
  String goToDesc;
  String goFromDesc;
  List<double> goTo;
  List<double> goFrom;
  int initDate;
  int endDate;
  List<bool> daysOfWeek;
  String closeNeighbourhood;
  bool paused = false;
  int time;
  double currentDistance;
  double initialDistance;
  int initialDuration;
  int currentDuration;
  String polylineTotal;
  int limit;

  DataForFrequentOffer(
      {this.author,
      this.initDate,
      this.endDate,
      this.goTo,
      this.goFrom,
      this.daysOfWeek,
      this.goFromDesc,
      this.goToDesc,
      this.gender,
      this.type,
      this.closeNeighbourhood,
      this.time,
      this.limit});

  void setRoutingData(ResultFromRide routingInfo) {
    this.initialDuration = routingInfo.duration.inSeconds;
    this.initialDistance = routingInfo.distance;
    this.currentDuration = routingInfo.duration.inSeconds;
    this.currentDistance = routingInfo.distance;
    this.polylineTotal = routingInfo.polylineTotal;
  }

  Map<String, dynamic> toJson() => {
        'goTo': goTo,
        'goFrom': goFrom,
        "goToDesc": goToDesc,
        "goFromDesc": goFromDesc,
        'author': author,
        'initDate': initDate,
        'endDate': endDate,
        "daysOfWeek": daysOfWeek,
        "paused": paused,
        "gender": gender,
        "type": type,
        "time": time,
        "closeNeighbourhood": closeNeighbourhood,
        "initialDuration": initialDuration,
        "initialDistance": initialDistance,
        "currentDuration": currentDuration,
        "currentDistance": currentDistance,
        "polylineTotal": polylineTotal,
        "limit": limit
      };
}

Future<bool> addFrequentSearch(DataForFrequentSearch data) async {
  try {
    await Firestore.instance.collection('frequentSearches').add(data.toJson());
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}

Future<bool> addFrequentOffer(DataForFrequentOffer data) async {
  try {
    String dep = "${data.goFrom[0]};${data.goFrom[1]}";
    String arr = "${data.goTo[0]};${data.goTo[1]}";
    ResultFromRide routingInfo = await initialRoutingDetails(dep, arr);
    if (routingInfo == null) {
      Crashlytics.instance
          .log("ERROR CREATING FREQUENT OFFER - ROUTING DETAILS");
    }
    data.setRoutingData(routingInfo);
    await Firestore.instance.collection('frequentOffers').add(data.toJson());
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}
