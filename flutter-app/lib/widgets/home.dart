import 'dart:async';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clustering_google_maps/clustering_google_maps.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fluro/fluro.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:ulift/config/application.dart';
import 'package:ulift/config/notification_handler.dart';
import 'package:ulift/config/routes.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/rides/getRide.dart';
import 'package:ulift/data_service/user/userDataService.dart';
import 'package:ulift/models/carona.dart';
import 'package:ulift/models/endereco.dart';
import 'package:ulift/util/resizeMarkers.dart';
import 'package:ulift/widgets/customs/crouser_with_slider.dart';
import 'package:ulift/widgets/customs/custom_bottom_sheet.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final storage = FlutterSecureStorage();

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AfterLayoutMixin {
  Completer<GoogleMapController> _controller = Completer();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Set<Marker> markers = new Set<Marker>();
  List<BitmapDescriptor> icons = List<BitmapDescriptor>();
  BitmapDescriptor yourRideIcon;
  CameraPosition currentPos;
  StreamSubscription notListener;
  final QuickActions quickActions = QuickActions();

  double latitude = 0.0;
  double longitude = 0.0;
  int _notifications = 0;
  List<LatLngAndGeohash> markerList = new List<LatLngAndGeohash>();
  Map<String, List<Carona>> positions = new Map<String, List<Carona>>();
  Map ride = new Map();
  ClusteringHelper clusteringHelper;
  AnimationController _animationController;
  static const List<IconData> fabIcons = const [
    Icons.sms,
    Icons.mail,
    Icons.phone
  ];
  static final CameraPosition _initial = CameraPosition(
    target: LatLng(-12.0355039, -50.319212),
    zoom: 4,
  );

  _HomeScreenState();

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
    if (await checkGps(context)) {
      Geolocator()
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
          .then((location) async {
        if (location != null) {
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(CameraUpdate.newCameraPosition(
              (_getCameraFromLatLong(
                  latitude: location.latitude,
                  longitude: location.longitude,
                  zoom: 17))));
        }
      });
    }
  }

  Future<void> _lastKnownPositionCamera() async {
    if (await checkGps(context)) {
      Geolocator()
          .getLastKnownPosition(desiredAccuracy: LocationAccuracy.best)
          .then((location) async {
        if (location != null) {
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(CameraUpdate.newCameraPosition(
              (_getCameraFromLatLong(
                  latitude: location.latitude,
                  longitude: location.longitude,
                  zoom: 17))));
        }
      });
    }
  }

  void _onData(QuerySnapshot data) {
    setState(() {
      _notifications = data.documents.length;
    });
  }

  @override
  void dispose() {
    notListener?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    notListener = Firestore.instance
        .collection('notifications')
        .where("toWho", isEqualTo: FireUserService.user.uid)
        .where('uniqueId', isEqualTo: Unique.id)
        .snapshots()
        .listen(_onData);
    handleQuickShortcuts();
    CurrentPage.page = Page.home;
    initNotifications(context);
    _animationController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    listenToChanges();
    initMemoryClustering();
    super.initState();
  }

  void setupQuickShortcuts() async {
    List<ShortcutItem> shortcuts = List();
    if (UserService.user.tipo != 2) {
      shortcuts.add(const ShortcutItem(
          type: 'notifications',
          localizedTitle: 'Notificações',
          icon: 'notifications'));
    }
    if (UserService.user.tipo == 2) {
      shortcuts.add(const ShortcutItem(
          type: 'my_rides',
          localizedTitle: 'Caronas ofertadas',
          icon: 'my_rides'));
    }
    shortcuts.add(const ShortcutItem(
        type: 'rides_applied',
        localizedTitle: 'Caronas aplicadas',
        icon: 'rides_applied'));
    if (UserService.user.tipo == 2) {
      shortcuts.add(const ShortcutItem(
          type: 'new_ride',
          localizedTitle: 'Ofertar nova carona',
          icon: 'new_ride'));
    }

    shortcuts.add(const ShortcutItem(
        type: 'search', localizedTitle: 'Buscar nova carona', icon: 'search'));

    quickActions.setShortcutItems(shortcuts);
  }

  void handleQuickShortcuts() {
    quickActions.initialize((shortcutType) {
      switch (shortcutType) {
        case "notifications":
          Application.router
              .navigateTo(context, Routes.notifications)
              .then((_) {
            CurrentPage.page = Page.home;
          });
          break;
        case "my_rides":
          if (UserService.user.tipo == 2 && checkConn(context)) {
            Application.router.navigateTo(context, Routes.myRides).then((_) {
              CurrentPage.page = Page.home;
            });
          }
          break;
        case "rides_applied":
          if (checkConn(context)) {
            Application.router
                .navigateTo(context, Routes.appliedRides)
                .then((_) {
              CurrentPage.page = Page.home;
            });
          }
          break;
        case "new_ride":
          if (UserService.user.tipo == 2 && checkConn(context)) {
            Navigator.pushNamed(context, Routes.newOffer).then((val) {
              CurrentPage.page = Page.home;
              if (val is Endereco) {
                _controller.future.then((controller) {
                  controller.animateCamera(CameraUpdate.newCameraPosition(
                      _getCameraFromLatLong(
                          latitude: val.latitude,
                          longitude: val.longitude,
                          zoom: 17)));
                });
              }
            });
          }
          break;
        case "search":
          if (checkConn(context)) {
            Application.router.navigateTo(context, Routes.newSearch).then((_) {
              CurrentPage.page = Page.home;
            });
          }
          break;
        default:
          Crashlytics.instance.log("INEXISTENT SHORTCUT");
          break;
      }
    });
  }

  loadIcons() async {
    for (int i = 0; i < 9; i++) {
      icons.add(await getMarker('images/marker${i + 1}.png', context));
    }
    yourRideIcon = await getMarker('images/marker-yours.png', context);
  }

  listenToChanges() async {
    getValidRidesSnapshot().listen((querySnapshot) {
      querySnapshot.documentChanges.forEach((change) async {
        if (change.type == DocumentChangeType.added) {
          bool amIIn = false;
          var riders = (await Firestore.instance
                  .collection('rides')
                  .document(change.document.documentID)
                  .collection('riders')
                  .getDocuments())
              .documents;
          for (var r in riders) {
            if (r.documentID == FireUserService.user.uid) {
              amIIn = true;
              break;
            }
          }
          int usedSeats = riders.length;
          DocumentSnapshot doc = await Firestore.instance
              .collection('users')
              .document(change.document.data['motorista'])
              .get();
          var data = change.document.data;
          Carona save = Carona.fromDB(data);
          if (save.motorista == FireUserService.user.uid ||
              (save.limit > usedSeats &&
                  UserService.user.fitsGender(save.genderAccepted) &&
                  UserService.user.fitsLevel(save.typeAccepted))) {
            setState(() {
              var motorista = doc.data['name'];
              var pic = doc.data['picUrl'];
              var motoristaRating =
                  doc.data['ratingDriver'] / doc.data['numberOfDrived'];
              var pointA =
                  LatLngAndGeohash(LatLng(data['depLat'], data['depLon']));
              save.usedSeats = usedSeats;
              save.amIIn = amIIn;
              save.uid = change.document.documentID;
              save.motoristaName = motorista;
              save.picUrlDriver = pic;
              save.motoristaRating = motoristaRating?.toDouble();
              if (positions[pointA.geohash] == null) {
                positions[pointA.geohash] = List<Carona>();
              }
              positions[pointA.geohash].add(save);
              markerList.add(pointA);
              clusteringHelper.updateMap();
            });
          }
        } else if (change.type == DocumentChangeType.removed) {
          var data = change.document.data;
          var pointA = LatLngAndGeohash(LatLng(data['depLat'], data['depLon']));
          setState(() {
            for (var mark in markerList) {
              if (mark.geohash == pointA.geohash) {
                markerList.remove(mark);
                break;
              }
            }
            if (positions[pointA.geohash] != null) {
              for (var pos in positions[pointA.geohash]) {
                if (pos.uid == change.document.documentID) {
                  positions[pointA.geohash].remove(pos);
                  break;
                }
              }
            }
            clusteringHelper.updateMap();
          });
        } else if (change.type == DocumentChangeType.modified) {
          bool amIIn = false;
          var riders = (await Firestore.instance
                  .collection('rides')
                  .document(change.document.documentID)
                  .collection('riders')
                  .getDocuments())
              .documents;
          for (var r in riders) {
            if (r.documentID == FireUserService.user.uid) {
              amIIn = true;
              break;
            }
          }
          int usedSeats = riders.length;
          DocumentSnapshot doc = await Firestore.instance
              .collection('users')
              .document(change.document.data['motorista'])
              .get();
          setState(() {
            var motorista = doc.data['name'];
            var pic = doc.data['picUrl'];
            var motoristaRating =
                doc.data['ratingDriver'] / doc.data['numberOfDrived'];
            var data = change.document.data;
            var pointA =
                LatLngAndGeohash(LatLng(data['depLat'], data['depLon']));
            Carona save = Carona.fromDB(data);
            save.usedSeats = usedSeats;
            save.amIIn = amIIn;
            save.uid = change.document.documentID;
            save.motoristaName = motorista;
            save.picUrlDriver = pic;
            save.motoristaRating = motoristaRating?.toDouble();

            for (var mark in markerList) {
              if (mark.geohash == pointA.geohash) {
                markerList.remove(mark);
                break;
              }
            }
            if (positions[pointA.geohash] != null) {
              for (var pos in positions[pointA.geohash]) {
                if (pos.uid == change.document.documentID) {
                  positions[pointA.geohash].remove(pos);
                  break;
                }
              }
            }
            clusteringHelper.updateMap();
            if (positions[pointA.geohash] == null) {
              positions[pointA.geohash] = List<Carona>();
            }
            if (save.motorista == FireUserService.user.uid ||
                (save.limit > usedSeats &&
                    UserService.user.fitsGender(save.genderAccepted) &&
                    UserService.user.fitsLevel(save.typeAccepted))) {
              positions[pointA.geohash].add(save);
              markerList.add(pointA);
            }
            clusteringHelper.updateMap();
          });
        }
      });
    });
  }

  updateMarkers(Set<Marker> markers) {
    Set<Marker> end = Set<Marker>();
    for (var marker in markers) {
      if (marker.infoWindow.title.contains(',') ||
          marker.infoWindow.title == '1') {
        var title;
        var geohash = LatLngAndGeohash(marker.position).geohash;
        if (positions[geohash].length == 1) {
          if (!DateTime.now().isAfter(positions[geohash].first.date)) {
            title = () {
              if (!DateTime.now().isAfter(positions[geohash].first.date)) {
                showModalBottomSheetCustom(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(15.0)),
                    ),
                    context: context,
                    builder: (context) =>
                        positions[geohash].first.getModal(context));
              } else {
                Flushbar(
                  message: "Todas caronas neste local expiraram!",
                  duration: Duration(seconds: 2),
                ).show(context);
                clusteringHelper.updateMap();
              }
            };
          } else {
            positions[geohash].removeLast();
            for (var mark in markerList) {
              if (mark.geohash == geohash) {
                markerList.remove(mark);
                break;
              }
            }
          }
        } else {
          positions[geohash].forEach((pos) {
            if (DateTime.now().isAfter(pos.date)) {
              positions[geohash].remove(pos);
              for (var mark in markerList) {
                if (mark.geohash == geohash) {
                  markerList.remove(mark);
                  break;
                }
              }
            }
          });
          title = () {
            List<Widget> widgets = List<Widget>();

            bool update = false;

            positions[geohash].forEach((pos) {
              if (!DateTime.now().isAfter(pos.date)) {
                widgets.add(pos.getModal(context));
              } else {
                update = true;
              }
            });

            if (widgets.length > 1) {
              showModalBottomSheetCustom(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(15.0)),
                  ),
                  builder: (context) => CarouselWithIndicator(widgets.map((i) {
                        return Builder(
                          builder: (BuildContext context) {
                            return i;
                          },
                        );
                      }).toList()));
            } else if (widgets.isNotEmpty) {
              showModalBottomSheetCustom(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(15.0)),
                  ),
                  builder: (context) => widgets.first);
            } else {
              Flushbar(
                message: "Todas caronas neste local expiraram!",
                duration: Duration(seconds: 2),
              ).show(context);
            }
            if (update) clusteringHelper.updateMap();
          };
        }
        if (positions[geohash].isNotEmpty) {
          BitmapDescriptor ico = icons[positions[geohash].length - 1];
          if (positions[geohash].length == 1) {
            if (positions[geohash].first.motorista ==
                FireUserService.user.uid) {
              ico = yourRideIcon;
            }
          }
          Marker tmp = new Marker(
              markerId: marker.markerId,
              onTap: title,
              position: marker.position,
              icon: ico);
          end.add(tmp);
        }
      } else {
        Marker tmp = new Marker(
            markerId: marker.markerId,
            onTap: () async {
              var c = await _controller.future;
              if (currentPos != null) {
                c.animateCamera(CameraUpdate.newCameraPosition(
                    _getCameraFromLatLong(
                        latitude: marker.position.latitude,
                        longitude: marker.position.longitude,
                        zoom: currentPos.zoom + 2)));
              }
            },
            position: marker.position,
            icon: marker.icon);
        end.add(tmp);
      }
    }
    setState(() {
      this.markers = end;
    });
  }

  initMemoryClustering() {
    clusteringHelper = ClusteringHelper.forMemory(
      list: markerList,
      updateMarkers: updateMarkers,
      maxZoomForAggregatePoints: 17,
      bitmapAssetPathForSingleMarker: 'images/marker1.png',
      aggregationSetup: AggregationSetup(markerSize: 150),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: UserService.user.tipo == 2
          ? Container(
              padding: EdgeInsets.fromLTRB(0, 0, 18, 15),
              height: double.infinity,
              width: 100,
              child: SpeedDial(
                overlayOpacity: 0,
                child: new AnimatedBuilder(
                  animation: _animationController,
                  builder: (BuildContext context, Widget child) {
                    return new Transform(
                      transform: new Matrix4.rotationZ(
                          _animationController.value * 0.5 * pi),
                      alignment: FractionalOffset.center,
                      child: new Icon(_animationController.isDismissed
                          ? Icons.add
                          : Icons.close),
                    );
                  },
                ),
                onOpen: () {
                  _animationController.forward();
                },
                onClose: () {
                  _animationController.reverse();
                },
                closeManually: false,
                curve: Curves.bounceIn,
                elevation: 8.0,
                shape: CircleBorder(),
                children: [
                  SpeedDialChild(
                    child: Icon(Icons.search),
                    label: 'Procurar Carona',
                    labelStyle: TextStyle(fontSize: 12.0, color: Colors.black),
                    onTap: () {
                      if (checkConn(context)) {
                        Navigator.pushNamed(context, Routes.newSearch)
                            .then((_) {
                          CurrentPage.page = Page.home;
                        });
                      }
                    },
                  ),
                  SpeedDialChild(
                    child: Icon(
                      FontAwesomeIcons.car,
                      size: 20,
                    ),
                    label: 'Nova Carona',
                    labelStyle: TextStyle(fontSize: 12.0, color: Colors.black),
                    onTap: () {
                      if (checkConn(context)) {
                        Navigator.pushNamed(context, Routes.newOffer)
                            .then((val) {
                          CurrentPage.page = Page.home;
                          if (val is Endereco) {
                            _controller.future.then((controller) {
                              controller.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                      _getCameraFromLatLong(
                                          latitude: val.latitude,
                                          longitude: val.longitude,
                                          zoom: 17)));
                            });
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
            )
          : FloatingActionButton(
              child: Icon(Icons.search),
              onPressed: () {
                if (checkConn(context)) {
                  Navigator.pushNamed(context, Routes.newSearch).then((_) {
                    CurrentPage.page = Page.home;
                  });
                }
              }),
      bottomNavigationBar: BottomAppBar(
        elevation: 20,
        shape: CircularNotchedRectangle(),
        notchMargin: UserService.user.tipo == 2 ? -double.infinity : 7.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState.openDrawer();
              },
            ),
            Stack(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () async {
                    Navigator.pushNamed(context, Routes.notifications)
                        .then((_) {
                      CurrentPage.page = Page.home;
                    });
                  },
                ),
                Visibility(
                    visible: _notifications != 0,
                    child: Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '$_notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
      body: Stack(children: <Widget>[
        GoogleMap(
          onMapCreated: (controller) {
            clusteringHelper.mapController = controller;
            clusteringHelper.updateMap();
            setState(() {
              controller.setMapStyle(mapStyle);
              _controller.complete(controller);
              _initialCameraPos();
            });
          },
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          myLocationButtonEnabled: false,
          myLocationEnabled: true,
          mapType: MapType.normal,
          zoomGesturesEnabled: true,
          initialCameraPosition: _initial,
          markers: markers,
          onCameraMove: (newPosition) {
            clusteringHelper.onCameraMove(newPosition, forceUpdate: false);
            setState(() {
              currentPos = newPosition;
            });
          },
          onCameraIdle: clusteringHelper.onMapIdle,
        ),
        Positioned(
            top: 0,
            right: 0,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: RawMaterialButton(
                      fillColor: Colors.white,
                      shape: CircleBorder(),
                      elevation: 2.0,
                      child: Icon(Icons.gps_fixed, color: Colors.black),
                      onPressed: () {
                        _lastKnownPositionCamera();
                      },
                    ),
                  ),
                ))),
      ]),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Stack(
              children: <Widget>[
                UserAccountsDrawerHeader(
                  accountName: Text(
                      UserService.user != null && UserService.user.nome != null
                          ? UserService.user.nome
                          : ""),
                  accountEmail: Text(
                      UserService.user != null && UserService.user.mat != null
                          ? UserService.user.mat.toUpperCase()
                          : ""),
                  decoration:
                      BoxDecoration(color: Theme.of(context).backgroundColor),
                  currentAccountPicture: GestureDetector(
                      onTap: () {
                        Application.router
                            .navigateTo(context, Routes.userProfile,
                                transition: TransitionType.fadeIn)
                            .then((_) {
                          CurrentPage.page = Page.home;
                        });
                      },
                      child: Hero(
                          tag: "profile-pic",
                          child: UserService.user.picUrl == null
                              ? CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    UserService.user != null &&
                                            UserService.user.nome != null
                                        ? UserService.user.nome
                                            .substring(0, 1)
                                            .toUpperCase()
                                        : "",
                                    style: TextStyle(fontSize: 40.0),
                                  ))
                              : CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: UserService.user.picUrl,
                                      placeholder: (context, url) =>
                                          new CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          Text(
                                        UserService.user != null &&
                                                UserService.user.nome != null
                                            ? UserService.user.nome
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : "",
                                        style: TextStyle(fontSize: 40.0),
                                      ),
                                    ),
                                  )))),
                ),
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Application.router
                                .navigateTo(context, Routes.userProfile,
                                    transition: TransitionType.fadeIn)
                                .then((_) {
                              CurrentPage.page = Page.home;
                            });
                          },
                        )))
              ],
            ),
            ListTile(
              title: Text("Buscas Frequentes"),
              trailing: Icon(Icons.search),
              onTap: () {
                if (checkConn(context)) {
                  Navigator.pop(context);
                  Application.router
                      .navigateTo(context, Routes.frequentSearches)
                      .then((_) {
                    CurrentPage.page = Page.home;
                  });
                }
              },
            ),
            Visibility(
              visible: UserService.user.tipo == 2,
              child: ListTile(
                trailing: Icon(FontAwesomeIcons.usersCog),
                title: Text("Ofertas Frequentes"),
                onTap: () {
                  if (checkConn(context)) {
                    Navigator.pop(context);
                    Application.router
                        .navigateTo(context, Routes.frequentOffers)
                        .then((_) {
                      CurrentPage.page = Page.home;
                    });
                  }
                },
              ),
            ),
            ListTile(
              trailing: Icon(FontAwesomeIcons.streetView),
              title: Text("Caronas que me apliquei"),
              onTap: () {
                if (checkConn(context)) {
                  Navigator.pop(context);
                  Application.router
                      .navigateTo(context, Routes.appliedRides)
                      .then((_) {
                    CurrentPage.page = Page.home;
                  });
                }
              },
            ),
            Visibility(
                visible: UserService.user.tipo == 2,
                child: ListTile(
                  trailing: Icon(FontAwesomeIcons.car),
                  title: Text("Caronas que ofertei"),
                  onTap: () {
                    if (checkConn(context)) {
                      Navigator.pop(context);
                      Application.router
                          .navigateTo(context, Routes.myRides)
                          .then((_) {
                        CurrentPage.page = Page.home;
                      });
                    }
                  },
                )),
            Visibility(
                visible: UserService.user.tipo != 2 &&
                    UserService.user.onGoingRequest != true,
                child: ListTile(
                  title: Text("Pedir para ser motorista"),
                  trailing: Icon(FontAwesomeIcons.solidIdCard),
                  onTap: () {
                    if (checkConn(context)) {
                      Navigator.pop(context);
                      Application.router
                          .navigateTo(context, Routes.driverRequest);
                    }
                  },
                )),
            ListTile(
              title: Text('Sobre o app'),
              trailing: Icon(Icons.info),
              onTap: () {
                Navigator.pop(context);
                Application.router.navigateTo(context, Routes.about).then((_) {
                  CurrentPage.page = Page.home;
                });
              },
            ),
            ListTile(
              title: Text('Logout'),
              trailing: Icon(Icons.exit_to_app),
              onTap: () {
                if (checkConn(context)) {
                  Navigator.pop(context);
                  signout();
                }
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {
    loadIcons();
    getUser(FireUserService.user.uid).then((val) {
      if (val != null) {
        setState(() {
          UserService.user = val;
          setupQuickShortcuts();
        });
      } else {
        signout();
      }
    });
  }

  Future<void> signout() async {
    await removePlayerIdFromDb();
    await _auth.signOut();
    await storage.delete(key: "user");
    await storage.delete(key: "user_uid");
    Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.loginScreen, (Route route) => route == null);
  }
}
