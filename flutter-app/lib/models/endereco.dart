import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:geocoder/geocoder.dart';

class Endereco {
  String description;
  double latitude;
  double longitude;

  Endereco(this.latitude, this.longitude, {this.description});

  void setDescriptionFromLatLon() async {
    this.description =
        await descriptionFromLatLon(this.latitude, this.longitude);
  }

  static Future<String> descriptionFromLatLon(double lat, double lon) async {
    String desc = "$lat / $lon";

    try {
      var response = await Geocoder.local
          .findAddressesFromCoordinates(Coordinates(lat, lon));

      if (response.first != null && response.first.addressLine != null) {
        desc = response.first.addressLine;
      }

      return desc;
    } catch (e) {
      Crashlytics.instance.log("COULD NOT TRANSFORM LATLON TO DESC");
      Crashlytics.instance.log(e.toString());
      return desc;
    }
  }
}
