import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/rides/getRide.dart';
import 'package:ulift/models/carona.dart';
import 'package:ulift/widgets/customs/skeleton.dart';
import 'package:ulift/widgets/ride/chat.dart';
import 'package:ulift/widgets/ride/my_applied_ride.dart';

class AppliedRides extends StatefulWidget {
  AppliedRides();

  @override
  _AppliedRidesState createState() => _AppliedRidesState();
}

class _AppliedRidesState extends State<AppliedRides> {
  bool loading = true;
  List<AppliedRideInfo> appliedRidesInfo;
  Map<String, Carona> appliedRides = Map();
  StreamSubscription<List> appliedsListener;

  @override
  void dispose() {
    appliedsListener?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    CurrentPage.page = Page.my_applied_rides;
    appliedsListener =
        getAppliedRidesDidNotHappenByUserIdStream(FireUserService.user.uid)
            .listen(_onData);
    super.initState();
  }

  void _onData(rides) {
    setState(() {
      appliedRides = Map();
    });
    rides.sort((a, b) {
      if (a.rideDate.millisecondsSinceEpoch <
          b.rideDate.millisecondsSinceEpoch) {
        return -1;
      }
      if (a.rideDate.millisecondsSinceEpoch >
          b.rideDate.millisecondsSinceEpoch) {
        return 1;
      }
      return 0;
    });
    setState(() {
      appliedRidesInfo = rides;
      loading = false;
      loadRides();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Caronas Aplicadas'),
        ),
        body: Builder(builder: ((context) {
          return !loading
              ? Container(
                  child: appliedRidesInfo.isNotEmpty
                      ? Scrollbar(
                          child: ListView.builder(
                          scrollDirection: Axis.vertical,
                          itemCount: appliedRidesInfo.length,
                          itemBuilder: (BuildContext context, int index) {
                            return AnimatedCrossFade(
                                crossFadeState: appliedRides[
                                            appliedRidesInfo[index].rideUid] !=
                                        null
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                duration: Duration(milliseconds: 300),
                                firstChild: appliedRideCard(
                                    appliedRides[
                                        appliedRidesInfo[index].rideUid],
                                    appliedRidesInfo[index]),
                                secondChild: CardSkeleton());
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
                                "Você não tem nenhuma carona aplicada no momento!",
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

  void loadRides() async {
    for (var info in appliedRidesInfo) {
      getRideById(info.rideUid).then((ride) {
        if (ride == null) {
          setState(() {
            appliedRidesInfo.remove(info);
          });
        } else {
          setState(() {
            appliedRides[info.rideUid] = ride;
          });
        }
      });
    }
  }

  Widget appliedRideCard(Carona ride, AppliedRideInfo info) {
    if (ride == null) {
      return Container();
    }
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
                    "\nMotorista: ${ride.motoristaName}\n\nPartida: ${ride.dep.description}")),
            ButtonTheme.bar(
              child: ButtonBar(
                children: <Widget>[
                  Visibility(
                    visible: info.status && ride.status == 0,
                    child: FlatButton(
                      child: const Text('CHAT'),
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
                          CurrentPage.page = Page.my_applied_rides;
                        });
                      },
                    ),
                  ),
                  FlatButton(
                    child: const Text('VER MAIS'),
                    onPressed: () {
                      if (!checkConn(context)) {
                        return;
                      }
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (context) => MyAppliedRide(
                                    ride: ride,
                                    accepted: info.status,
                                  )))
                          .then((_) {
                        CurrentPage.page = Page.my_applied_rides;
                      });
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
