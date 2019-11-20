import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:android_intent/android_intent.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fluro/fluro.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ulift/config/application.dart';
import 'package:ulift/config/routes.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/rides/acceptRide.dart';
import 'package:ulift/data_service/rides/deleteRide.dart';
import 'package:ulift/data_service/rides/getRide.dart';
import 'package:ulift/data_service/rides/ridesAPI.dart';
import 'package:ulift/models/carona.dart';
import 'package:ulift/models/usuario.dart';
import 'package:ulift/util/resizeMarkers.dart';
import 'package:ulift/widgets/ride/chat.dart';
import 'package:ulift/widgets/ride/evaluate_ride_requests.dart';
import 'package:url_launcher/url_launcher.dart';

class MyRide extends StatefulWidget {
  final Carona rideReceived;
  final bool fromHome;
  final bool fromNotification;

  MyRide({this.rideReceived, this.fromHome, this.fromNotification});

  @override
  _MyRideState createState() => _MyRideState();
}

class _MyRideState extends State<MyRide> with AfterLayoutMixin {
  bool wasDeleted = false;
  Carona ride;
  List<ResultFromRide> ridesInfoNotAccepted;
  List<ResultFromRide> ridesInfoAccepted;
  Map<String, Usuario> riders = Map();
  bool reloaded = false;
  Completer<GoogleMapController> _controller = Completer();
  bool loading = true;
  static final CameraPosition _initial = CameraPosition(
    target: LatLng(-12.0355039, -50.319212),
    zoom: 4,
  );
  Set<Marker> _markers = Set();
  Set<Polyline> _polyline = Set();
  List<LatLng> latLngOfPolyline = List();
  StreamSubscription<Map> answerListener;
  BitmapDescriptor depIcon;
  BitmapDescriptor arrIcon;
  BitmapDescriptor stopIcon;

  loadIcons() async {
    depIcon = await getMarker('images/marker-start.png', context);

    arrIcon = await getMarker('images/marker-end.png', context);

    stopIcon = await getMarker('images/marker-stop.png', context);
  }

  void startGoogleMaps() async {
    String waypoints = "";
    int k = 0;
    if (ridesInfoAccepted.length > 0) {
      waypoints = "&waypoints=";
      for (var i in ridesInfoAccepted.first.points) {
        if (k != 0 && (k + 1) != ridesInfoAccepted.first.points.length) {
          if (k != 1) {
            waypoints += "|";
          }
          waypoints += '${i.latitude},${i.longitude}';
        }
        k++;
      }
    }
    String finalUrl =
        "https://www.google.com/maps/dir/?api=1&origin=${ride.depLatLng.latitude},${ride.depLatLng.longitude}$waypoints&destination=${ride.arrLatLng.latitude},${ride.arrLatLng.longitude}&travelmode=driving&dir_action=navigate";

    if (Platform.isAndroid) {
      final AndroidIntent intent = new AndroidIntent(
          action: 'action_view',
          data: Uri.encodeFull(finalUrl),
          package: 'com.google.android.apps.maps');
      intent.launch();
    } else {
      if (await canLaunch(finalUrl)) {
        await launch(finalUrl);
      } else {
        Crashlytics.instance.log("UNABLE TO LAUNCH URL");
      }
    }
  }

  void _loadMarkersAndPolyline() {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId('dep'),
          infoWindow: InfoWindow(title: "Partida"),
          icon: depIcon,
          position: ride.depLatLng));

      for (var i in ridesInfoAccepted) {
        var title = "Parada de ${riders[i.riderUid].nome}";
        _markers.add(Marker(
            markerId: MarkerId("${i.riderUid}}"),
            infoWindow: InfoWindow(title: title),
            position: i.myPoint,
            icon: stopIcon));
      }

      _markers.add(Marker(
          markerId: MarkerId('arr'),
          infoWindow: InfoWindow(title: "Destino Final"),
          icon: arrIcon,
          position: ride.arrLatLng));

      List<PointLatLng> poly =
          PolylinePoints().decodePolyline(ride.polylineTotal);

      for (var x in poly) {
        latLngOfPolyline.add(LatLng(x.latitude, x.longitude));
      }

      _polyline.removeAll(_polyline);

      _polyline.add(Polyline(
        width: 5,
        polylineId: PolylineId(ride.polylineTotal),
        visible: true,
        points: latLngOfPolyline,
        color: Colors.orange,
      ));
    });
  }

  LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1) y1 = latLng.longitude;
        if (latLng.longitude < y0) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  CameraPosition _getCameraFromLatLong(
      {double latitude, double longitude, double zoom}) {
    if (latitude == null || longitude == null) {
      return null;
    }
    if (zoom == null) {
      zoom = 15;
    }
    return CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: zoom,
    );
  }

  Future<void> _initialCameraPos() async {
    Geolocator()
        .getLastKnownPosition(desiredAccuracy: LocationAccuracy.best)
        .then((location) async {
      if (location != null) {
        final GoogleMapController controller = await _controller.future;
        await controller.animateCamera(CameraUpdate.newCameraPosition(
            (_getCameraFromLatLong(
                latitude: location.latitude,
                longitude: location.longitude,
                zoom: 17))));
        List<LatLng> bounds = List();

        bounds.add(ride.depLatLng);
        bounds.add(ride.arrLatLng);

        LatLngBounds bound = boundsFromLatLngList(bounds);

        CameraUpdate u = CameraUpdate.newLatLngBounds(bound, 50);
        _controller.future.then((cont) {
          cont.animateCamera(u);
        });
      }
    });
  }

  void reload() async {
    setState(() {
      loading = true;
      reloaded = true;
    });
    Carona reloadedRide = await getRideById(ride.uid);
    if (reloadedRide == null) {
      if (widget.fromHome == true) {
        Navigator.popUntil(context, ModalRoute.withName(Routes.homeScreen));
      } else if (widget.fromNotification == true) {
        Navigator.pop(context);
      } else {
        Navigator.popUntil(context, ModalRoute.withName(Routes.myRides));
      }
      Flushbar(
        message: "A carona foi removida!",
        duration: Duration(seconds: 2),
      ).show(context);
      return;
    }
    answerListener?.cancel();
    setState(() {
      ride = reloadedRide;
    });
    initialLoad();
  }

  void initialLoad() {
    answerListener = getNewApplicationsOfRideByRideStream(ride).listen(_onData);
  }

  void _onData(Map answer) {
    if (!wasDeleted) {
      setState(() {
        loading = true;
        ridesInfoNotAccepted = List();
        riders = Map();
        _markers = Set();
        _polyline = Set();
        latLngOfPolyline = List();
        _controller = Completer();
        ridesInfoNotAccepted = answer["ridesInfoNotAccepted"];
        if (ridesInfoAccepted == answer["ridesInfoAccepted"]) {
          ridesInfoAccepted = answer['ridesInfoAccepted'];
        } else {
          ridesInfoAccepted = answer['ridesInfoAccepted'];
          reload();
        }
        riders = answer['riders'];
        _loadMarkersAndPolyline();
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    answerListener?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    CurrentPage.page = Page.my_ride;
    AdditionalPageData.currentRideId = widget.rideReceived.uid;
    ride = widget.rideReceived;
    initialLoad();
    super.initState();
  }

  Future<bool> removeRider(ResultFromRide toRemove) async {
    try {
      ridesInfoAccepted.remove(toRemove);
      List<String> ridersId = List();
      List<String> goTos = List();
      List<String> goTosDesc = List();
      var removed = await removeRiderFromRideInfoAndRide(toRemove, ride, false);
      if (!removed) {
        return false;
      }
      List<ResultFromRide> results = await singleRideWithMultipleRidersApi(
          ride.uid, goTos, ridersId, goTosDesc);
      if (results == null) {
        return false;
      }
      if (ridesInfoAccepted.isEmpty) {
        var reseted = await resetRideFromRidesInfoAndRide(results.first, ride);
        if (!reseted) {
          return false;
        }
      } else {
        var removed = await removeRiderFromRidesInfoAndRide(results, ride);
        if (!removed) {
          return false;
        }
      }
      return true;
    } catch (e) {
      Crashlytics.instance.log(e.toString());
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Carona do dia ${ride.dateFormatted}'),
        ),
        body: !loading
            ? Builder(
                builder: (context) => ListView(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: GoogleMap(
                        onMapCreated: (controller) {
                          setState(() {
                            controller.setMapStyle(mapStyle);
                            _controller.complete(controller);
                            _initialCameraPos();
                          });
                        },
                        scrollGesturesEnabled: true,
                        tiltGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                        myLocationButtonEnabled: false,
                        myLocationEnabled: true,
                        mapType: MapType.normal,
                        initialCameraPosition: _initial,
                        markers: _markers,
                        polylines: _polyline,
                        gestureRecognizers:
                            <Factory<OneSequenceGestureRecognizer>>[
                          new Factory<OneSequenceGestureRecognizer>(
                            () => new EagerGestureRecognizer(),
                          ),
                        ].toSet(),
                      ),
                    ),
                    Visibility(
                      visible: ridesInfoNotAccepted.isNotEmpty &&
                          ride.vacantSeats > 0,
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            leading: Icon(
                              FontAwesomeIcons.question,
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Requisitantes',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 15.0,
                                  ),
                                ),
                                Text(
                                  "${ridesInfoNotAccepted.length} requisitantes(s)",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.0,
                                  ),
                                )
                              ],
                            ),
                            trailing: FlatButton(
                              child: Text("ANALISAR"),
                              onPressed: () {
                                if (!checkConn(context)) {
                                  return;
                                }
                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        builder: (context) =>
                                            EvaluateRideRequests(ride)))
                                    .then((shoulIReload) {
                                  if (shoulIReload == true) {
                                    reload();
                                  }
                                });
                              },
                            ),
                          ),
                          Divider(
                            height: 0.0,
                            indent: 72.0,
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: ridesInfoAccepted.isNotEmpty,
                      child: ExpansionTile(
                        initiallyExpanded: reloaded,
                        leading: Icon(FontAwesomeIcons.userCheck),
                        title: Text(
                            'Clique para ver as essoas aceitas nessa carona'),
                        children: <Widget>[
                          ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemCount: ridesInfoAccepted.length * 2,
                            itemBuilder: (BuildContext context, int index) {
                              if (index % 2 == 0) {
                                ResultFromRide currentRideInfo =
                                    ridesInfoAccepted[index ~/ 2];
                                Usuario currentRider =
                                    riders[currentRideInfo.riderUid];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  leading: GestureDetector(
                                    onTap: () {
                                      Application.router
                                          .navigateTo(context,
                                              "/user/${currentRideInfo.riderUid}",
                                              transition:
                                                  TransitionType.inFromBottom)
                                          .then((_) {
                                        CurrentPage.page = Page.my_ride;
                                        AdditionalPageData.currentRideId =
                                            widget.rideReceived.uid;
                                      });
                                    },
                                    child: currentRider.picUrl == null
                                        ? CircleAvatar(
                                            backgroundColor: Colors.white,
                                            child: Text(
                                              currentRider.nome != null
                                                  ? currentRider.nome
                                                      .substring(0, 1)
                                                      .toUpperCase()
                                                  : "",
                                              style: TextStyle(fontSize: 40.0),
                                            ))
                                        : CircleAvatar(
                                            backgroundColor: Colors.white,
                                            child: ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl: currentRider.picUrl,
                                                placeholder: (context, url) =>
                                                    new CircularProgressIndicator(),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Text(
                                                  currentRider.nome != null
                                                      ? currentRider.nome
                                                          .substring(0, 1)
                                                          .toUpperCase()
                                                      : "",
                                                  style:
                                                      TextStyle(fontSize: 40.0),
                                                ),
                                              ),
                                            )),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.chat),
                                    onPressed: () {
                                      if (!checkConn(context)) {
                                        return;
                                      }
                                      Map rideChat = {
                                        'motoristaId': FireUserService.user.uid,
                                        'userId': currentRideInfo.riderUid,
                                        'rideId': currentRideInfo.rideId
                                      };
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                              builder: (context) => ChatPage(
                                                    ride: rideChat,
                                                  )));
                                    },
                                  ),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        '${currentRider.nome}',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 15.0,
                                        ),
                                      ),
                                      Text(
                                        "Parada: ${currentRideInfo.whereToDesc}",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                      Visibility(
                                        visible: ride.status == 0,
                                        child: FlatButton.icon(
                                            onPressed: () {
                                              if (!checkConn(context)) {
                                                return;
                                              }
                                              setState(() {
                                                loading = true;
                                              });
                                              removeRider(currentRideInfo)
                                                  .then((did) {
                                                if (!did) {
                                                  Flushbar(
                                                    message:
                                                        "Erro ao remover da carona!",
                                                    duration:
                                                        Duration(seconds: 2),
                                                  ).show(context);
                                                }
                                                reload();
                                              });
                                            },
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            label: Text("Remover da carona")),
                                      )
                                    ],
                                  ),
                                );
                              } else {
                                if (index != ridesInfoAccepted.length * 2) {
                                  return Divider(
                                    height: 0.0,
                                    indent: 72.0,
                                  );
                                } else {
                                  return Container();
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        FontAwesomeIcons.solidClock,
                      ),
                      trailing: IconButton(
                        icon: Icon(FontAwesomeIcons.directions),
                        onPressed: startGoogleMaps,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Duração total da carona',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15.0,
                            ),
                          ),
                          Text(
                            "${ride.currentDuration.inMinutes} minuto(s)",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        FontAwesomeIcons.userClock,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Desvio total da rota inicial',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15.0,
                            ),
                          ),
                          Text(
                            ride.deviationOfInitialRoute.inMilliseconds == 0
                                ? "Nenhum"
                                : "${ride.deviationOfInitialRoute.inMinutes} minuto(s)",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        FontAwesomeIcons.clock,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Horário Partida',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15.0,
                            ),
                          ),
                          Text(
                            "${ride.dateFormatted}  ${ride.timeFormatted}",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        FontAwesomeIcons.streetView,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Local de Partida',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15.0,
                            ),
                          ),
                          Text(
                            "${ride.dep.description}",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        FontAwesomeIcons.mapMarkedAlt,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Local de Destino',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15.0,
                            ),
                          ),
                          Text(
                            "${ride.arr.description}",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        FontAwesomeIcons.users,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Assentos Preenchidos',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15.0,
                            ),
                          ),
                          Text(
                            "${ride.usedSeats}",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        FontAwesomeIcons.couch,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Assentos Vagos',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15.0,
                            ),
                          ),
                          Text(
                            "${ride.vacantSeats}",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        FontAwesomeIcons.userFriends,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Pessoas Aceitas',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15.0,
                            ),
                          ),
                          Text(
                            "${ride.typeAccepted}",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Visibility(
                          visible: ride.status == 0,
                          child: RaisedButton(
                            child: Text("Deletar Carona"),
                            color: Colors.red,
                            onPressed: () async {
                              if (!checkConn(context)) {
                                return;
                              }
                              var removed = await deleteRideById(ride.uid);
                              if (removed) {
                                wasDeleted = true;
                              }
                              if (widget.fromHome == true) {
                                Navigator.popUntil(context,
                                    ModalRoute.withName(Routes.homeScreen));
                              } else if (widget.fromNotification == true) {
                                Navigator.pop(context);
                              } else {
                                Navigator.popUntil(context,
                                    ModalRoute.withName(Routes.myRides));
                              }
                              if (!removed) {
                                Flushbar(
                                  message: "Erro ao deletar carona!",
                                  duration: Duration(seconds: 2),
                                ).show(context);
                              }
                            },
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              )
            : Center(
                child: SpinKitDoubleBounce(color: Colors.tealAccent, size: 30),
              ));
  }

  @override
  void afterFirstLayout(BuildContext context) {
    loadIcons();
  }
}
