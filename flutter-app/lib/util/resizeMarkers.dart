import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<Uint8List> getBytesFromAsset(String path, double width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: width.floor());
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
      .buffer
      .asUint8List();
}

Future<BitmapDescriptor> getMarker(String path, BuildContext context) async {
  double width = 85;
  /*if (Platform.isAndroid) {
    double mq = MediaQuery.of(context).devicePixelRatio;
    width *=mq;
  }*/
  final Uint8List markerIcon = await getBytesFromAsset(path, width);
  return BitmapDescriptor.fromBytes(markerIcon);
}
