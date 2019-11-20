import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:ulift/data_service/rides/applyToRide.dart';
import 'package:ulift/data_service/rides/getRide.dart';
import 'package:ulift/data_service/rides/ridesAPI.dart';
import 'package:ulift/models/carona.dart';
import 'package:ulift/util/resizeMarkers.dart';

import 'chat.dart';

class MyAppliedRide extends StatefulWidget {
  final ResultFromRide rideInfo;
  final Carona ride;
  final bool accepted;

  MyAppliedRide({this.rideInfo, this.ride, this.accepted});

  @override
  _MyAppliedRideState createState() => _MyAppliedRideState();
}

class _MyAppliedRideState extends State<MyAppliedRide> with AfterLayoutMixin {
  ResultFromRide rideInfo;
  Carona ride;
  bool accepted;
  Completer<GoogleMapController> _controller = Completer();
  bool loadingUser = true;
  static final CameraPosition _initial = CameraPosition(
    target: LatLng(-12.0355039, -50.319212),
    zoom: 4,
  );
  Set<Marker> _markers = Set();
  Set<Polyline> _polyline = Set();
  List<LatLng> latLngOfPolyline = List();
  StreamSubscription remoteReloadListener;
  BitmapDescriptor depIcon;
  BitmapDescriptor othersIcon;
  BitmapDescriptor stopIcon;

  loadIcons() async {
    depIcon = await getMarker('images/marker-start.png', context);

    othersIcon = await getMarker('images/marker-others.png', context);

    stopIcon = await getMarker('images/marker-stop.png', context);
  }

  void _loadMarkersAndPolyline() {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId('dep'),
          infoWindow: InfoWindow(title: "Partida"),
          icon: depIcon,
          position: rideInfo.points.first));

      int x = -1;

      for (var i in rideInfo.points) {
        if (x != -1) {
          _markers.add(Marker(
              markerId: MarkerId("$x"),
              infoWindow: InfoWindow(
                  title: x == rideInfo.myPointIndex
                      ? "Sua parada"
                      : "Parada ${x + 1}"),
              position: i,
              icon: x == rideInfo.myPointIndex ? stopIcon : othersIcon));
        }
        if (x == rideInfo.myPointIndex) break;
        x++;
      }

      List<PointLatLng> poly =
          PolylinePoints().decodePolyline(rideInfo.polylineToMe);

      for (var x in poly) {
        latLngOfPolyline.add(LatLng(x.latitude, x.longitude));
      }

      _polyline.removeAll(_polyline);

      _polyline.add(Polyline(
        width: 5,
        polylineId: PolylineId(rideInfo.polylineToMe),
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

        bounds.add(rideInfo.points.first);
        bounds.add(rideInfo.myPoint);

        LatLngBounds bound = boundsFromLatLngList(bounds);

        CameraUpdate u = CameraUpdate.newLatLngBounds(bound, 50);
        _controller.future.then((cont) {
          cont.animateCamera(u);
        });
      }
    });
  }

  @override
  void initState() {
    CurrentPage.page = Page.ride_applied;
    AdditionalPageData.currentRideId = widget.ride.uid;
    rideInfo = widget.rideInfo;
    ride = widget.ride;
    accepted = widget.accepted;
    if (rideInfo != null) {
      accepted = false;
      applyToRideByResultRideAndUser(
              rideInfo, ride, FireUserService.user.uid, accepted)
          .then((did) {
        if (did) {
          setState(() {
            _loadMarkersAndPolyline();
            loadingUser = false;
          });
        } else {
          Navigator.pop(context);
          Flushbar(
            message: "Erro ao aplicar para carona!",
            duration: Duration(seconds: 2),
          ).show(context);
        }
      });
    } else {
      getAppliedRideAndInfoByRide(ride, accepted).then((result) {
        if (result == null) {
          Navigator.pop(context);
          Flushbar(
            message: "Erro ao recuperar dados da carona!",
            duration: Duration(seconds: 2),
          ).show(context);
        } else {
          setState(() {
            rideInfo = result;
            _loadMarkersAndPolyline();
            loadingUser = false;
          });
        }
      });
    }
    remoteReloadListener = listenToRemoteReload().listen((doI) {
      if (doI == "accepted") {
        setState(() {
          loadingUser = true;
        });

        getAppliedRideAndInfoByRide(ride, true).then((result) {
          if (result == null) {
            Navigator.pop(context);
            Flushbar(
              message: "Erro ao recuperar dados da carona!",
              duration: Duration(seconds: 2),
            ).show(context);
          } else {
            setState(() {
              _controller = Completer();
              _markers = Set();
              _polyline = Set();
              latLngOfPolyline = List();
              rideInfo = result;
              _loadMarkersAndPolyline();
              accepted = true;
              loadingUser = false;
            });
          }
        });
      } else if (doI == 'removed') {
        if (widget.rideInfo != null) {
          CurrentPage.page = Page.home;
          Navigator.popUntil(context, ModalRoute.withName(Routes.homeScreen));
        } else {
          Navigator.pop(context);
        }
        Flushbar(
          message:
              'Infelizmente o motorista te removeu desta carona! Tente procurar outra!',
          duration: Duration(seconds: 2),
        ).show(context);
      } else {
        if (widget.rideInfo != null) {
          CurrentPage.page = Page.home;
          Navigator.popUntil(context, ModalRoute.withName(Routes.homeScreen));
        } else {
          Navigator.pop(context);
        }
        Flushbar(
          message:
              'Infelizmente o motorista deletou esta carona! Tente procurar outra!',
          duration: Duration(seconds: 2),
        ).show(context);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    remoteReloadListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.rideInfo != null) {
          CurrentPage.page = Page.home;
          Navigator.popUntil(context, ModalRoute.withName(Routes.homeScreen));
        } else {
          Navigator.pop(context);
        }
        return false;
      },
      child: Scaffold(
          appBar: AppBar(
            title: Text('Carona Aplicada do dia ${ride.dateFormatted}'),
          ),
          body: !loadingUser
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
                              if (!_controller.isCompleted) {
                                _controller.complete(controller);
                              }
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
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        leading: ride.picUrlDriver == null
                            ? CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Text(
                                  ride.motorista != null
                                      ? ride.motorista
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : "",
                                  style: TextStyle(fontSize: 40.0),
                                ))
                            : CircleAvatar(
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: ride.picUrlDriver,
                                    placeholder: (context, url) =>
                                        new CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => Text(
                                      ride.motorista != null
                                          ? ride.motorista
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : "",
                                      style: TextStyle(fontSize: 40.0),
                                    ),
                                  ),
                                )),
                        onTap: () {
                          Application.router
                              .navigateTo(context, "/user/${ride.motorista}",
                                  transition: TransitionType.inFromBottom)
                              .then((_) {
                            CurrentPage.page = Page.ride_applied;
                          });
                        },
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Motorista',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15.0,
                              ),
                            ),
                            Text(
                              "${ride.motoristaName}",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0,
                              ),
                            )
                          ],
                        ),
                        trailing: Visibility(
                          visible: accepted && ride.status == 0,
                          child: IconButton(
                            icon: Icon(Icons.chat),
                            onPressed: () {
                              if (!checkConn(context)) {
                                return;
                              }
                              Map rideChat = {
                                'motoristaId': ride.motorista,
                                'userId': FireUserService.user.uid,
                                'rideId': ride.uid
                              };
                              Navigator.of(context)
                                  .push(MaterialPageRoute(
                                      builder: (context) => ChatPage(
                                            ride: rideChat,
                                          )))
                                  .then((_) {
                                CurrentPage.page = Page.ride_applied;
                                AdditionalPageData.currentRideId =
                                    widget.ride.uid;
                              });
                            },
                          ),
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
                              'Tempo até sua parada',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15.0,
                              ),
                            ),
                            Text(
                              "${rideInfo?.durationToMine?.inMinutes} minuto(s)",
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
                          FontAwesomeIcons.question,
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Status da Carona',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15.0,
                              ),
                            ),
                            Text(
                              accepted
                                  ? "Carona aceita pelo motorista"
                                  : "Carona ainda não aceita pelo motorista",
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
                              'Seu Destino',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15.0,
                              ),
                            ),
                            Text(
                              "${rideInfo.whereToDesc}",
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
                              child: Text("Desistir da Carona"),
                              color: Colors.red,
                              onPressed: () {
                                if (!checkConn(context)) {
                                  return;
                                }
                                if (widget.rideInfo != null) {
                                  CurrentPage.page = Page.home;
                                  Navigator.popUntil(context,
                                      ModalRoute.withName(Routes.homeScreen));
                                } else {
                                  Navigator.pop(context);
                                }
                                dropRideRequest().then((did) {
                                  if (!did) {
                                    Flushbar(
                                      message: "Erro ao desistir da carona!",
                                      duration: Duration(seconds: 2),
                                    ).show(context);
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              : Center(
                  child:
                      SpinKitDoubleBounce(color: Colors.tealAccent, size: 30),
                )),
    );
  }

  Future<bool> dropRideRequest() async {
    try {
      var rideDoc =
          await Firestore.instance.collection('rides').document(ride.uid).get();
      if (!rideDoc.exists || rideDoc.data['status'] != 0) {
        Crashlytics.instance.log("CANNOT DROP REQUEST ANYMORE");
        return false;
      }
      var amIAccepted = (await Firestore.instance
              .collection('rides')
              .document(ride.uid)
              .collection('riders')
              .document(FireUserService.user.uid)
              .get())
          .exists;

      if (amIAccepted) {
        List<String> ridersId = List();
        List<String> goTos = List();
        List<String> goTosDesc = List();
        var removed =
            await removeRiderFromRideInfoAndRide(rideInfo, ride, true);
        if (!removed) {
          return false;
        }
        List<ResultFromRide> results = await singleRideWithMultipleRidersApi(
            ride.uid, goTos, ridersId, goTosDesc);
        if (results == null) {
          return false;
        }
        bool hasRiders = (await Firestore.instance
                .collection("rides")
                .document(ride.uid)
                .collection('riders')
                .getDocuments())
            .documents
            .isNotEmpty;
        if (!hasRiders) {
          var reseted =
              await resetRideFromRidesInfoAndRide(results.first, ride);
          if (!reseted) {
            return false;
          }
        } else {
          var removed = await removeRiderFromRidesInfoAndRide(results, ride);
          if (!removed) {
            return false;
          }
        }
      } else {
        var removed = await removeRequest(rideInfo, ride);
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
  void afterFirstLayout(BuildContext context) {
    loadIcons();
  }
}
