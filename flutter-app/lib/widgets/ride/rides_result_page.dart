import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ulift/config/application.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/rides/getRide.dart';
import 'package:ulift/data_service/rides/ridesAPI.dart';
import 'package:ulift/models/carona.dart';
import 'package:ulift/util/dialogo.dart';
import 'package:ulift/widgets/customs/skeleton.dart';
import 'package:ulift/widgets/ride/my_applied_ride.dart';

Map<String, Carona> rides = Map<String, Carona>();

class ResultsPage extends StatefulWidget {
  final ResultFromAPI result;
  final String whereToDesc;

  ResultsPage(this.result, this.whereToDesc);

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  @override
  void initState() {
    setState(() {
      widget.result.results
          .sort(ResultFromRide.compareByBestRideCriteriaDuration);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Resultados da Busca'),
        ),
        floatingActionButton: Visibility(
            visible: widget.result.errors.isEmpty,
            child: SpeedDial(
              overlayOpacity: 0,
              backgroundColor: Colors.white,
              child: Icon(
                FontAwesomeIcons.sortAmountUpAlt,
                color: Colors.black87,
              ),
              closeManually: false,
              curve: Curves.bounceIn,
              elevation: 8.0,
              shape: CircleBorder(),
              children: [
                SpeedDialChild(
                  backgroundColor: Colors.white,
                  child: Icon(FontAwesomeIcons.award,
                      color: Colors.black87, size: 20),
                  label: 'Organizar Por Melhor Carona',
                  labelStyle: TextStyle(fontSize: 12.0, color: Colors.black),
                  onTap: () {
                    setState(() {
                      widget.result.results.sort(
                          ResultFromRide.compareByBestRideCriteriaDuration);
                    });
                  },
                ),
                SpeedDialChild(
                  backgroundColor: Colors.white,
                  child: Icon(FontAwesomeIcons.clock,
                      color: Colors.black87, size: 20),
                  label: 'Organizar Por Menor Desvio de Tempo',
                  labelStyle: TextStyle(fontSize: 12.0, color: Colors.black),
                  onTap: () {
                    setState(() {
                      widget.result.results
                          .sort(ResultFromRide.compareByBestRideDeviationTime);
                    });
                  },
                ),
                SpeedDialChild(
                  backgroundColor: Colors.white,
                  child: Icon(
                    FontAwesomeIcons.userClock,
                    color: Colors.black87,
                    size: 20,
                  ),
                  label: 'Organizar Por Menor Tempo Até Minha Parada',
                  labelStyle: TextStyle(fontSize: 12.0, color: Colors.black),
                  onTap: () {
                    setState(() {
                      widget.result.results
                          .sort(ResultFromRide.compareByBestRideDurationToMine);
                    });
                  },
                ),
              ],
            )),
        body: Builder(builder: ((context) {
          if (widget.result.errors.isNotEmpty &&
              widget.result.errors.first != "No rides found") {
            Crashlytics.instance.log(widget.result.errors.toString());
          }
          return Container(
              child: widget.result.errors.isEmpty
                  ? Scrollbar(
                      child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: widget.result.results.length,
                      itemBuilder: (BuildContext context, int index) {
                        return RideContainer(widget.whereToDesc,
                            rideInfo: widget.result.results[index]);
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
                            "Nenhuma Carona Encontrada",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20),
                          )
                        ],
                      ),
                    )));
        })));
  }
}

class RideContainer extends StatefulWidget {
  final ResultFromRide rideInfo;
  final String whereToDesc;

  RideContainer(this.whereToDesc, {this.rideInfo});

  @override
  _RideContainerState createState() => _RideContainerState();
}

class _RideContainerState extends State<RideContainer> {
  Carona ride;

  @override
  void initState() {
    CurrentPage.page = Page.rides_result_page;
    if (rides[widget.rideInfo.rideId] == null) {
      load();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ride = rides[widget.rideInfo.rideId];
    return AnimatedCrossFade(
      crossFadeState:
          ride == null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: Duration(milliseconds: 300),
      firstChild: RideSummarySkeleton(),
      secondChild: RideSummary(ride, widget.rideInfo, widget.whereToDesc),
    );
  }

  void load() {
    getRideById(widget.rideInfo.rideId).then((val) {
      if (val != null) {
        if (this.mounted) {
          setState(() {
            rides[widget.rideInfo.rideId] = val;
          });
        } else {
          rides[widget.rideInfo.rideId] = val;
        }
      } else {
        this.dispose();
      }
    });
  }
}

class RideSummary extends StatelessWidget {
  final Carona ride;
  final ResultFromRide rideInfo;

  RideSummary(this.ride, this.rideInfo, whereToDesc) {
    this.rideInfo.whereToDesc = whereToDesc;
  }

  @override
  Widget build(BuildContext context) {
    final rideThumbnail = GestureDetector(
        onTap: () {
          Application.router
              .navigateTo(context, "/user/${ride.motorista}",
                  transition: TransitionType.inFromBottom)
              .then((_) {
            CurrentPage.page = Page.rides_result_page;
          });
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 16.0),
          alignment: FractionalOffset.centerLeft,
          child: ride != null
              ? ride.picUrlDriver == null
                  ? CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      child: Text(
                        ride.motoristaName != null
                            ? ride.motoristaName.substring(0, 1).toUpperCase()
                            : "",
                        style: TextStyle(fontSize: 40.0),
                      ))
                  : CircleAvatar(
                      radius: 46,
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
                      ),
                    )
              : Container(),
        ));

    Widget _rideValue({String value, IconData icon}) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Icon(
            icon,
            size: 20,
          ),
          Container(width: 12.0),
          Expanded(
              child: Text(
            value,
            style: TextStyle(
                color: const Color(0xffe1defa),
                fontSize: 14.0,
                fontWeight: FontWeight.w400),
          )),
        ]),
      );
    }

    final rideCardContent = Container(
      margin: EdgeInsets.fromLTRB(76.0, 16.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: ride != null
            ? <Widget>[
                Container(height: 4.0),
                Text(
                  "Carona do dia: ${ride.dateFormatted}",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600),
                ),
                _rideValue(
                    value:
                        "Motorista: ${ride.motoristaName} | Avaliação: ${ride.motoristaRating?.toStringAsFixed(1)}",
                    icon: FontAwesomeIcons.user),
                _rideValue(
                    value: ride.dep.description,
                    icon: FontAwesomeIcons.mapMarkerAlt),
                _rideValue(
                    value:
                        "Desvio da rota inicial: ${rideInfo.deviationOfDuration.inMinutes} minuto(s) / ${rideInfo.deviationOfDistance.toInt()} metros",
                    icon: FontAwesomeIcons.stopwatch),
                _rideValue(
                    value:
                        "Duração até minha parada: ${rideInfo.durationToMine.inMinutes} minuto(s) / ${rideInfo.distanceToMine.toInt()} metros",
                    icon: FontAwesomeIcons.userClock),
                _rideValue(
                    value: "Horário de partida: ${ride.timeFormatted}",
                    icon: FontAwesomeIcons.clock),
                _rideValue(
                    value:
                        "Pessoas confirmadas nessa carona: ${ride.usedSeats}",
                    icon: FontAwesomeIcons.users),
                _rideValue(
                    value: "Pessoas aceitas nessa carona: ${ride.typeAccepted}",
                    icon: FontAwesomeIcons.userFriends),
                _rideValue(
                    value:
                        "Gêneros aceitos nessa carona: ${ride.genderAccepted}",
                    icon: FontAwesomeIcons.venusMars),
                RaisedButton.icon(
                  onPressed: () {
                    if (!checkConn(context)) {
                      return;
                    }
                    dialogo(context, "Aplicar Para Carona",
                        "Deseja realmente aplicar-se para a carona do dia ${ride.dateFormatted}?",
                        confirm: "Aplicar", cancel: "Cancelar", cancelFun: () {
                      Navigator.pop(context);
                    }, okFun: () {
                      Navigator.pop(context);
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (context) => MyAppliedRide(
                                  rideInfo: rideInfo, ride: ride)))
                          .then((_) {
                        CurrentPage.page = Page.home;
                      });
                    });
                  },
                  label: Flexible(
                      child: Text(
                    "Aplicar para carona",
                    overflow: TextOverflow.ellipsis,
                  )),
                  icon: Icon(Icons.check),
                ),
              ]
            : <Widget>[Container()],
      ),
    );

    final rideCard = Container(
      child: rideCardContent,
      margin: EdgeInsets.only(left: 46.0),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Theme.of(context).accentColor,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
    );

    return GestureDetector(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 24.0,
          ),
          child: Stack(
            children: <Widget>[
              rideCard,
              rideThumbnail,
            ],
          ),
        ));
  }
}
