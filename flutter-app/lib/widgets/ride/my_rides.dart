import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/rides/getRide.dart';
import 'package:ulift/models/carona.dart';
import 'package:ulift/widgets/ride/my_ride.dart';

class MyRides extends StatefulWidget {
  MyRides();

  @override
  _MyRidesState createState() => _MyRidesState();
}

class _MyRidesState extends State<MyRides> {
  bool loading = true;
  List<Carona> offeredRides;
  StreamSubscription<List> offersListener;

  @override
  void dispose() {
    offersListener?.cancel();
    super.dispose();
  }

  void load() {
    loading = true;
    offersListener = getOfferedRidesDidNotHappenOrOnGoingByUserIdStream(
            FireUserService.user.uid)
        .listen(_onData);
  }

  void _onData(rides) {
    rides.sort((a, b) {
      if (a.date.millisecondsSinceEpoch < b.date.millisecondsSinceEpoch) {
        return -1;
      }
      if (a.date.millisecondsSinceEpoch > b.date.millisecondsSinceEpoch) {
        return 1;
      }
      return 0;
    });
    setState(() {
      offeredRides = rides;
      loading = false;
    });
  }

  @override
  void initState() {
    CurrentPage.page = Page.my_rides;
    load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Caronas Ofertadas'),
        ),
        body: Builder(builder: ((context) {
          return !loading
              ? Container(
                  child: offeredRides.isNotEmpty
                      ? Scrollbar(
                          child: ListView.builder(
                          scrollDirection: Axis.vertical,
                          itemCount: offeredRides.length,
                          itemBuilder: (BuildContext context, int index) {
                            return offeredRideCard(offeredRides[index]);
                          },
                        ))
                      : Center(
                          child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.close,
                                size: 40,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              Text(
                                "Nenhuma carona ofertada ativa!",
                                style: TextStyle(fontSize: 20),
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        )))
              : Center(
                  child:
                      SpinKitDoubleBounce(color: Colors.tealAccent, size: 30),
                );
        })));
  }

  Widget offeredRideCard(Carona ride) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
                leading: ride.picUrlDriver == null
                    ? CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(
                          ride.motoristaName != null
                              ? ride.motoristaName.substring(0, 1).toUpperCase()
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
                              ride.motoristaName != null
                                  ? ride.motoristaName
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : "",
                              style: TextStyle(fontSize: 40.0),
                            ),
                          ),
                        )),
                title: Text("Carona do dia ${ride.dateFormatted}"),
                subtitle: Text(
                    "\nPartida: ${ride.dep.description}\n\nDestino: ${ride.arr.description}\n\nStatus: ${ride.status == 0 ? "Marcada" : "Em andamento"}")),
            ButtonTheme.bar(
              child: ButtonBar(
                children: <Widget>[
                  FlatButton(
                    child: const Text('VER MAIS'),
                    onPressed: () {
                      if (!checkConn(context)) {
                        return;
                      }
                      if (ride.polylineTotal == null) {
                        Flushbar(
                          message:
                              "Essa carona ainda está sendo criada... Aguarde!",
                          duration: Duration(seconds: 2),
                        ).show(context);
                      } else {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (context) => MyRide(
                                      rideReceived: ride,
                                    )))
                            .then((_) {
                          CurrentPage.page = Page.my_rides;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
