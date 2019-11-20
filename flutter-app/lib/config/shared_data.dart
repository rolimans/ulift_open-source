import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ntp/ntp.dart';
import 'package:ulift/models/usuario.dart';
import 'package:ulift/util/util.dart';

class FireUserService {
  static FirebaseUser user;
}

class UserService {
  static Usuario user;
}

class CurrentPage {
  static Page page;
}

class Unique {
  static String id;
}

final String mapStyle =
    '[  { "featureType": "administrative", "elementType": "geometry.fill", "stylers": [ { "color": "#d6e2e6" } ] }, { "featureType": "administrative", "elementType": "geometry.stroke", "stylers": [ { "color": "#cfd4d5" } ] }, { "featureType": "administrative", "elementType": "labels.text.fill", "stylers": [ { "color": "#7492a8" } ] }, { "featureType": "administrative.neighborhood", "elementType": "labels.text.fill", "stylers": [ { "lightness": 25 } ] }, { "featureType": "landscape.man_made", "elementType": "geometry.fill", "stylers": [ { "color": "#dde2e3" } ] }, { "featureType": "landscape.man_made", "elementType": "geometry.stroke", "stylers": [ { "color": "#cfd4d5" } ] }, { "featureType": "landscape.natural", "elementType": "geometry.fill", "stylers": [ { "color": "#dde2e3" } ] }, { "featureType": "landscape.natural", "elementType": "labels.text.fill", "stylers": [ { "color": "#7492a8" } ] }, { "featureType": "landscape.natural.terrain", "stylers": [ { "visibility": "off" } ] }, { "featureType": "poi", "elementType": "geometry.fill", "stylers": [ { "color": "#dde2e3" } ] }, { "featureType": "poi", "elementType": "labels.icon", "stylers": [ { "saturation": -100 } ] }, { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [ { "color": "#588ca4" } ] }, { "featureType": "poi.park", "elementType": "geometry.fill", "stylers": [ { "color": "#a9de83" } ] }, { "featureType": "poi.park", "elementType": "geometry.stroke", "stylers": [ { "color": "#bae6a1" } ] }, { "featureType": "poi.sports_complex", "elementType": "geometry.fill", "stylers": [ { "color": "#c6e8b3" } ] }, { "featureType": "poi.sports_complex", "elementType": "geometry.stroke", "stylers": [ { "color": "#bae6a1" } ] }, { "featureType": "road", "elementType": "labels.icon", "stylers": [ { "saturation": -45 }, { "lightness": 10 }, { "visibility": "on" } ] }, { "featureType": "road", "elementType": "labels.text.fill", "stylers": [ { "color": "#41626b" } ] }, { "featureType": "road.arterial", "elementType": "geometry.fill", "stylers": [ { "color": "#ffffff" } ] }, { "featureType": "road.highway", "elementType": "geometry.fill", "stylers": [ { "color": "#c1d1d6" } ] }, { "featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [ { "color": "#a6b5bb" } ] }, { "featureType": "road.highway", "elementType": "labels.icon", "stylers": [ { "visibility": "on" } ] }, { "featureType": "road.highway.controlled_access", "elementType": "geometry.fill", "stylers": [ { "color": "#9fb6bd" } ] }, { "featureType": "road.local", "elementType": "geometry.fill", "stylers": [ { "color": "#ffffff" } ] }, { "featureType": "transit", "elementType": "labels.icon", "stylers": [ { "saturation": -70 } ] }, { "featureType": "transit.line", "elementType": "geometry.fill", "stylers": [ { "color": "#b4cbd4" } ] }, { "featureType": "transit.line", "elementType": "labels.text.fill", "stylers": [ { "color": "#588ca4" } ] }, { "featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [ { "color": "#008cb5" } ] }, { "featureType": "transit.station.airport", "elementType": "geometry.fill", "stylers": [ { "saturation": -100 }, { "lightness": -5 } ] }, { "featureType": "water", "elementType": "geometry.fill", "stylers": [ { "color": "#a6cbe3" } ] } ]';

const String googlePlaceAPI = 'GOOGLEMAPS-API';

enum Page {
  home,
  about,
  chat,
  evaluate_ride_requests,
  login,
  my_applied_rides,
  my_ride,
  my_rides,
  new_offer,
  new_search,
  phone_confirm,
  register,
  ride_applied,
  rides_result_page,
  splash,
  user_profile,
  driver_request,
  notifications_page,
  change_phone_number,
  add_frequent_ride_search,
  add_frequent_ride_offer,
  frequent_offers,
  frequent_searches,
}

class AdditionalPageData {
  static String currentChatId;
  static String currentUserChatId;
  static String currentDriverChatId;
  static String currentRideId;
}

StreamController<String> _controller;

Stream<String> listenToRemoteReload() {
  void _start() {}

  void _end() {
    _controller.close();
  }

  _controller = StreamController<String>(
      onListen: _start, onPause: _end, onResume: _start, onCancel: _end);

  return _controller.stream;
}

void remoteReloadInfoFromRideApplied(String add) {
  _controller?.add(add);
}

String leadingZero(var s) {
  String n = '0' + s.toString();
  if (n.length > 2) {
    return s.toString();
  } else {
    return n;
  }
}

bool isOffline = true;
StreamSubscription _connectionChangeStream;

void initNetWatcher() async {
  ConnectionStatusSingleton connectionStatus =
      ConnectionStatusSingleton.getInstance();
  _connectionChangeStream = connectionStatus.connectionChange.listen((hasConn) {
    isOffline = !hasConn;
  });
}

void endNetWatcher() {
  _connectionChangeStream.cancel();
}

bool checkConn(BuildContext context) {
  if (!isOffline) {
    return true;
  } else {
    Flushbar(
      icon: Icon(
        Icons.signal_cellular_connected_no_internet_4_bar,
        color: Colors.red,
      ),
      message:
          "Você não possui conexão com a internet para realizar esta ação!",
      duration: Duration(seconds: 2),
    ).show(context);
    return false;
  }
}

Future<bool> checkGps(BuildContext context) async {
  var currPerm = await Geolocator().checkGeolocationPermissionStatus();
  if (currPerm != GeolocationStatus.disabled &&
      currPerm != GeolocationStatus.denied &&
      currPerm != GeolocationStatus.unknown) {
    return true;
  } else {
    Flushbar(
      icon: Icon(
        Icons.gps_off,
        color: Colors.red,
      ),
      message:
          "Você não permitiu acesso à sua localização! Algumas ações não estão disponíveis!",
      duration: Duration(seconds: 2),
    ).show(context);
    return false;
  }
}

int timeOffset = 0;

void setTimeOffset() async {
  try {
    DateTime startDate = DateTime.now().toLocal();
    timeOffset = await NTP.getNtpOffset(localTime: startDate);
  } catch (e) {
    Crashlytics.instance.log(e.toString());
  }
}
