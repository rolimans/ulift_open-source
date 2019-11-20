import 'dart:convert';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/models/endereco.dart';

class ResultFromAPI {
  List<ResultFromRide> results = List<ResultFromRide>();
  List<String> errors = List<String>();

  ResultFromAPI.fromError(String e) {
    errors.add(e);
  }

  ResultFromAPI.fromJson(Map<String, dynamic> json) {
    for (dynamic x in json['errors']) {
      this.errors.add(x.toString());
    }
    for (Map<String, dynamic> x in json['results']) {
      results.add(ResultFromRide.fromJson(x, FireUserService.user.uid));
    }
  }
}

class ResultFromRide {
  String riderUid;
  String rideId;
  Duration duration;
  double distance;
  int myPointIndex;
  double distanceToMine;
  Duration durationToMine;
  Duration currentDuration;
  double currentDistance;
  String polylineTotal;
  String polylineToMe;
  List<LatLng> points = List();
  DateTime lastChangeAtTime;
  Map ridersInfo = Map();
  String whereToDesc;

  ResultFromRide.fromJson(Map<String, dynamic> json, String riderId) {
    this.riderUid = riderId;
    rideId = json['rideId'];
    if (json['duration'] == null) {
      json['duration'] = 0;
    }
    duration = Duration(seconds: json['duration'].toInt());
    distance = json['distance'].toDouble();
    currentDistance = json['currentDistance'].toDouble();
    if (json['currentDuration'] == null) {
      json['currentDuration'] = 0;
    }
    currentDuration = Duration(seconds: json['currentDuration'].toInt());
    polylineTotal = json['polylineTotal'];
    var p = json['points'];
    for (dynamic x in p) {
      this.points.add(LatLng(x['lat'], x['lng']));
    }
    if (json['lastChangeAtTime'] != null) {
      this.lastChangeAtTime =
          DateTime.fromMillisecondsSinceEpoch(json['lastChangeAtTime']);
    }
    this.ridersInfo = json["ridersInfo"];
    this.whereToDesc = json['whereToDesc'];
    if (riderId != null) _setDataFromRidersInfo(json['ridersInfo'][riderId]);
  }

  void _setDataFromRidersInfo(Map riderInfo) {
    this.myPointIndex = riderInfo['myPointIndex'];
    this.distanceToMine = riderInfo['distanceToMine'].toDouble();
    this.durationToMine =
        Duration(seconds: riderInfo['durationToMine'].toInt());
    this.polylineToMe = riderInfo['polylineToMe'];
  }

  List<Map> get pointsToMapList {
    List<Map> points = List();
    for (var x in this.points) {
      var map = Map();
      map['lat'] = x.latitude;
      map['lng'] = x.longitude;
      points.add(map);
    }
    return points;
  }

  LatLng get myPoint {
    return this.points[this.myPointIndex + 1];
  }

  Duration get deviationOfDuration {
    return this.duration - this.currentDuration;
  }

  double get deviationOfDistance {
    var dev = this.distance - this.currentDistance;
    if (dev < 0) return 0;
    return dev;
  }

  get bestRideCriteriaByDuration {
    return ((this.deviationOfDuration.inSeconds * 3) +
            (this.durationToMine.inSeconds * 2)) /
        5;
  }

  static int compareByBestRideDeviationTime(
      ResultFromRide a, ResultFromRide b) {
    if (a.deviationOfDuration < b.deviationOfDuration) {
      return -1;
    }
    if (a.deviationOfDuration > b.deviationOfDuration) {
      return 1;
    }
    return 0;
  }

  static int compareByBestRideDurationToMine(
      ResultFromRide a, ResultFromRide b) {
    if (a.durationToMine < b.durationToMine) {
      return -1;
    }
    if (a.durationToMine > b.durationToMine) {
      return 1;
    }
    return 0;
  }

  static int compareByBestRideCriteriaDuration(
      ResultFromRide a, ResultFromRide b) {
    if (a.bestRideCriteriaByDuration < b.bestRideCriteriaByDuration) {
      return -1;
    }
    if (a.bestRideCriteriaByDuration > b.bestRideCriteriaByDuration) {
      return 1;
    }
    return 0;
  }
}

class DataToGetRides {
  String currentUser;
  double radius;
  String _goTo;
  String _goFrom;
  String tipo;
  String gender;
  int initDate;
  int endDate;

  DataToGetRides(
      {this.currentUser,
      this.radius,
      this.tipo,
      this.gender,
      Endereco goTo,
      Endereco goFrom,
      this.initDate,
      this.endDate}) {
    this.goTo = goTo;
    this.goFrom = goFrom;
  }

  Map<String, dynamic> toJson() => {
        'goTo': goTo,
        'goFrom': goFrom,
        'tipo': tipo,
        'radius': radius,
        'currentUser': currentUser,
        'initDate': initDate,
        'endDate': endDate,
        'gender': gender
      };

  set goTo(Endereco e) {
    this._goTo = e.latitude.toString() + ";" + e.longitude.toString();
  }

  set goFrom(Endereco e) {
    this._goFrom = e.latitude.toString() + ";" + e.longitude.toString();
  }

  get goTo {
    return this._goTo;
  }

  get goFrom {
    return this._goFrom;
  }
}

Future<ResultFromRide> initialRoutingDetails(String dep, String arr) async {
  ResultFromRide result;
  try {
    var query = {
      'dep': dep,
      "arr": arr,
    };
    var httpRequest = await HttpClient().getUrl(Uri.https(
        "YOUR FIREBASE CLOUD FUNCTIONS URL",
        "/getInitialRoutingDetailsForRide",
        query));
    var httpResponse = await httpRequest.close();
    var rawJson = await (utf8.decodeStream(httpResponse));
    var decodedJson = json.decode(rawJson);
    result = ResultFromRide.fromJson(decodedJson, null);
    return result;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return null;
  }
}

Future<ResultFromRide> singleRideApi(
    String rideId, String goTo, String riderId) async {
  ResultFromRide result;
  try {
    var query = {'rideId': rideId, "goTo": goTo, "riderId": riderId};
    var httpRequest = await HttpClient().getUrl(Uri.https(
        "YOUR FIREBASE CLOUD FUNCTIONS URL",
        "/getSingleRide",
        query));
    var httpResponse = await httpRequest.close();
    var rawJson = await (utf8.decodeStream(httpResponse));
    var decodedJson = json.decode(rawJson);
    result = ResultFromRide.fromJson(decodedJson, riderId);
    return result;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return null;
  }
}

Future<List<ResultFromRide>> singleRideWithMultipleRidersApi(String rideId,
    List<String> goTos, List<String> ridersId, List<String> goTosDesc) async {
  List<ResultFromRide> result = List();
  try {
    var js = {'rideId': rideId, "goTos": goTos, "ridersId": ridersId};
    var query = {"js": json.encode(js)};
    var httpRequest = await HttpClient().getUrl(Uri.https(
        "YOUR FIREBASE CLOUD FUNCTIONS URL",
        "/getSingleRideWithMultipleRiders",
        query));
    var httpResponse = await httpRequest.close();
    var rawJson = await (utf8.decodeStream(httpResponse));
    var decodedJson = json.decode(rawJson);
    int i = 0;
    for (String riderId in ridersId) {
      var r = ResultFromRide.fromJson(decodedJson, riderId);
      r.whereToDesc = goTosDesc[i];
      result.add(r);
      i++;
    }
    var ridersInfoSize = 0;
    decodedJson['ridersInfo'].forEach((id, content) {
      if (!ridersId.contains(id)) {
        var r = ResultFromRide.fromJson(decodedJson, id);
        r.whereToDesc = content['whereToDesc'];
        result.add(r);
        ridersInfoSize++;
      }
    });
    if (ridersId.isEmpty && ridersInfoSize == 0) {
      result.add(ResultFromRide.fromJson(decodedJson, null));
    }
    return result;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return null;
  }
}

Future<ResultFromAPI> ridesAPI(DataToGetRides data) async {
  ResultFromAPI result;
  try {
    var query = {
      'js': json.encode(data),
    };
    var httpRequest = await HttpClient().getUrl(Uri.https(
        "YOUR FIREBASE CLOUD FUNCTIONS URL",
        "/getBestRides",
        query));
    var httpResponse = await httpRequest.close();
    var rawJson = await (utf8.decodeStream(httpResponse));
    var decodedJson = json.decode(rawJson);
    result = ResultFromAPI.fromJson(decodedJson);
  } catch (e) {
    result = ResultFromAPI.fromError(e.toString());
  }
  return result;
}
