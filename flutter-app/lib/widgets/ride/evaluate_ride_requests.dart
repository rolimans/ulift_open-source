import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fluro/fluro.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ulift/config/application.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/rides/acceptRide.dart';
import 'package:ulift/data_service/rides/getRide.dart';
import 'package:ulift/data_service/rides/ridesAPI.dart';
import 'package:ulift/models/carona.dart';
import 'package:ulift/models/usuario.dart';

class EvaluateRideRequests extends StatefulWidget {
  final Carona ride;

  EvaluateRideRequests(this.ride);

  @override
  _EvaluateRideRequestsState createState() => _EvaluateRideRequestsState();
}

class _EvaluateRideRequestsState extends State<EvaluateRideRequests> {
  List<ResultFromRide> ridesInfo;
  Map<String, Usuario> riders;
  bool loading = true;
  List<ResultFromRide> accepteds = List();
  StreamSubscription<Map> answerListener;
  bool acceptedSomeone = false;

  @override
  void dispose() {
    answerListener?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    CurrentPage.page = Page.evaluate_ride_requests;
    answerListener =
        getNewApplicationsOfRideByRideStream(widget.ride).listen(_onData);
    super.initState();
  }

  void _onData(Map answer) {
    if (acceptedSomeone) return;
    setState(() {
      loading = true;
      ridesInfo = List();
      riders = Map();
      ridesInfo = answer["ridesInfoNotAccepted"];
      riders = answer['riders'];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Novos requisitantes'),
        ),
        floatingActionButton: AnimatedOpacity(
          opacity: accepteds.isNotEmpty && !loading ? 1.0 : 0.0,
          duration: Duration(milliseconds: 300),
          child: FloatingActionButton(
            child: Icon(Icons.check),
            onPressed: () async {
              if (!checkConn(context)) {
                return;
              }
              setState(() {
                loading = true;
                acceptedSomeone = true;
              });
              var accepted = await acceptRiders(accepteds);
              Navigator.pop(context, true);
              if (!accepted) {
                Flushbar(
                  message: "Erro ao aceitar caroneiro!",
                  duration: Duration(seconds: 2),
                ).show(context);
              }
            },
          ),
        ),
        body: Builder(builder: ((context) {
          return !loading
              ? Container(
                  child: ridesInfo.isNotEmpty
                      ? Scrollbar(
                          child: ListView.builder(
                          scrollDirection: Axis.vertical,
                          itemCount: ridesInfo.length,
                          itemBuilder: (BuildContext context, int index) {
                            return requesterCard(ridesInfo[index],
                                riders[ridesInfo[index].riderUid]);
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
                                "Nenhum requisitante!",
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

  Future<bool> acceptRiders(List<ResultFromRide> accepteds) async {
    try {
      List<String> ridersId = List();
      List<String> goTos = List();
      List<String> goTosDesc = List();
      for (ResultFromRide accepted in accepteds) {
        ridersId.add(accepted.riderUid);
        goTos.add("${accepted.myPoint.latitude};${accepted.myPoint.longitude}");
        goTosDesc.add(accepted.whereToDesc);
      }
      List<ResultFromRide> results = await singleRideWithMultipleRidersApi(
          widget.ride.uid, goTos, ridersId, goTosDesc);
      if (results == null) {
        return false;
      }
      var accepted = await acceptRideFromRidesInfoAndRide(results, widget.ride);
      if (!accepted) {
        return false;
      }
      return true;
    } catch (e) {
      Crashlytics.instance.log(e.toString());
      return false;
    }
  }

  Widget requesterCard(ResultFromRide rideInfo, Usuario rider) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
                leading: GestureDetector(
                  onTap: () {
                    Application.router
                        .navigateTo(context, "/user/${rideInfo.riderUid}",
                            transition: TransitionType.inFromBottom)
                        .then((_) {
                      CurrentPage.page = Page.evaluate_ride_requests;
                    });
                  },
                  child: rider.picUrl == null
                      ? CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text(
                            rider.nome != null
                                ? rider.nome.substring(0, 1).toUpperCase()
                                : "",
                            style: TextStyle(fontSize: 40.0),
                          ))
                      : CircleAvatar(
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: rider.picUrl,
                              placeholder: (context, url) =>
                                  new CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Text(
                                rider.nome != null
                                    ? rider.nome.substring(0, 1).toUpperCase()
                                    : "",
                                style: TextStyle(fontSize: 40.0),
                              ),
                            ),
                          )),
                ),
                title: Text("Requisitante: ${rider.nome}"),
                subtitle: Text(
                    "\nAvaliação: ${(rider.ratingRider / rider.numberOfRided).toStringAsFixed(1)}\n\nDestino: ${rideInfo.whereToDesc} \n\nDesvio da rota atual: ${rideInfo.deviationOfDuration.inMinutes} minuto(s)")),
            ButtonTheme.bar(
              child: ButtonBar(
                children: <Widget>[
                  FlatButton.icon(
                    icon: AnimatedCrossFade(
                        crossFadeState: accepteds.contains(rideInfo)
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: Duration(milliseconds: 300),
                        firstChild: Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
                        secondChild: Icon(
                          Icons.close,
                          color: Colors.red,
                        )),
                    label: AnimatedCrossFade(
                        crossFadeState: accepteds.contains(rideInfo)
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: Duration(milliseconds: 300),
                        firstChild: Container(
                            width: 130, child: Text("Clique para remover")),
                        secondChild: Container(
                            width: 130, child: Text("Clique para aceitar"))),
                    onPressed: () {
                      setState(() {
                        if (accepteds.contains(rideInfo)) {
                          accepteds.remove(rideInfo);
                        } else {
                          if (accepteds.length < widget.ride.vacantSeats) {
                            accepteds.add(rideInfo);
                          } else {
                            Flushbar(
                              message:
                                  "Carona lotada! Remova alguém para prosseguir!",
                              duration: Duration(seconds: 2),
                            ).show(context);
                          }
                        }
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
