import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluro/fluro.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ulift/config/application.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/models/endereco.dart';
import 'package:ulift/widgets/new/new_search.dart';
import 'package:ulift/widgets/ride/my_applied_ride.dart';
import 'package:ulift/widgets/ride/my_ride.dart';

class Carona {
  String uid;
  String motorista;
  String motoristaName;
  double motoristaRating;
  int limit;
  int status;
  String typeAccepted;
  String genderAccepted;
  Endereco dep;
  Endereco arr;
  DateTime date;
  String picUrlDriver;
  double currentDistance;
  double initialDistance;
  Duration initialDuration;
  Duration currentDuration;
  int usedSeats = 0;
  String polylineTotal;
  String closeNeibourhoodToArr;
  DateTime lastChange;
  bool amIIn = false;
  Map ridersInfo = Map();

  Carona(
      {this.motorista,
      this.dep,
      this.arr,
      this.typeAccepted,
      this.status,
      this.date,
      this.limit,
      this.closeNeibourhoodToArr,
      this.uid,
      this.lastChange,
      this.polylineTotal,
      this.genderAccepted});

  Carona.fromDB(Map<String, dynamic> data) {
    motorista = data['motorista'];
    ridersInfo = data['ridersInfo'];
    date = DateTime.fromMillisecondsSinceEpoch(data['date']);
    limit = data['limit'];
    status = data['status'];
    typeAccepted = data['typeAccepted'];
    lastChange = DateTime.fromMillisecondsSinceEpoch(data['lastChange']);
    arr =
        Endereco(data['arrLat'], data['arrLon'], description: data['arrDesc']);
    dep =
        Endereco(data['depLat'], data['depLon'], description: data['depDesc']);
    initialDuration = data["initialDuration"] == null
        ? null
        : Duration(seconds: data['initialDuration'].toInt());
    currentDuration = data["currentDuration"] == null
        ? null
        : Duration(seconds: data['currentDuration'].toInt());
    currentDistance = data['currentDistance'] == null
        ? null
        : data['currentDistance'].toDouble();
    initialDistance = data['initialDistance'] == null
        ? null
        : data['initialDistance'].toDouble();
    closeNeibourhoodToArr = data['closeNeibourhoodToArr'];
    polylineTotal = data['polylineTotal'];
    genderAccepted = data['genderAccepted'];
  }

  Widget getModal(context) {
    return Wrap(
      children: <Widget>[
        ListTile(
            title: Text(
              'Carona Cadastrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            onTap: () {}),
        ListTile(
            leading: Hero(
                tag: "profile-pic",
                child: picUrlDriver == null
                    ? CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(
                          motoristaName != null
                              ? motoristaName.substring(0, 1).toUpperCase()
                              : "",
                          style: TextStyle(fontSize: 20.0),
                        ))
                    : CircleAvatar(
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: picUrlDriver,
                            placeholder: (context, url) =>
                                new CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Text(
                              motoristaName != null
                                  ? motoristaName.substring(0, 1).toUpperCase()
                                  : "",
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                        ))),
            title: Text(
                'Motorista: $motoristaName | Avaliação ${motoristaRating?.toStringAsFixed(1)}'),
            onTap: () {
              Navigator.of(context).pop();
              Application.router
                  .navigateTo(context, "/user/$motorista",
                      transition: TransitionType.inFromBottom)
                  .then((_) {
                CurrentPage.page = Page.home;
              });
            }),
        ListTile(
          leading: Icon(
            FontAwesomeIcons.locationArrow,
          ),
          title: Text('Endereço de partida: ${dep.description}'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(
            Icons.transit_enterexit,
          ),
          title: Text('Bairro de destino final: $closeNeibourhoodToArr'),
          trailing: IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              Flushbar(
                message:
                    "Para manter a privacidade dos usuários mostramos apenas o bairro de destino final. Note que o nome de alguns bairros pode não ser o mais usual!",
                duration: Duration(seconds: 3),
              ).show(context);
            },
          ),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(
            FontAwesomeIcons.clock,
          ),
          title: Text(
              'Data de partida: ${leadingZero(date.day)}/${leadingZero(date.month)}/${date.year} - ${leadingZero(date.hour)}:${leadingZero(date.minute)}'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(
            FontAwesomeIcons.userCheck,
          ),
          title: Text('Passageiros aceitos: $typeAccepted'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(
            FontAwesomeIcons.venusMars,
          ),
          title: Text('Gênero(s) aceito(s): $genderAccepted'),
          onTap: () {},
        ),
        motorista == FireUserService.user.uid
            ? ListTile(
                leading: Icon(
                  Icons.info,
                ),
                title: Text('Ver mais sobre sua carona'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (this.polylineTotal == null) {
                    Flushbar(
                      message:
                          "Essa carona ainda está sendo criada... Aguarde!",
                      duration: Duration(seconds: 2),
                    ).show(context);
                  } else {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (context) => MyRide(
                                  rideReceived: this,
                                  fromHome: true,
                                )))
                        .then((_) {
                      CurrentPage.page = Page.home;
                    });
                  }
                },
              )
            : amIIn
                ? ListTile(
                    leading: Icon(
                      Icons.info,
                    ),
                    title: Text('Ver mais sobre a carona que você participa'),
                    onTap: () {
                      Navigator.of(context).pop();
                      if (this.polylineTotal == null) {
                        Flushbar(
                          message:
                              "Essa carona ainda está sendo criada... Aguarde!",
                          duration: Duration(seconds: 2),
                        ).show(context);
                      } else {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (context) => MyAppliedRide(
                                      ride: this,
                                      accepted: true,
                                    )))
                            .then((_) {
                          CurrentPage.page = Page.home;
                        });
                      }
                    },
                  )
                : ListTile(
                    leading: Icon(
                      FontAwesomeIcons.search,
                    ),
                    title: Text('Realizar busca de carona nessa área'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (context) => NewSearch(
                                    departureTxt: dep.description,
                                    depLatStart: dep.latitude,
                                    depLonStart: dep.longitude,
                                  )))
                          .then((_) {
                        CurrentPage.page = Page.home;
                      });
                    },
                  ),
        ListTile(
          leading: Icon(
            Icons.close,
          ),
          title: Text('Fechar'),
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  LatLng get depLatLng {
    return LatLng(dep.latitude, dep.longitude);
  }

  LatLng get arrLatLng {
    return LatLng(arr.latitude, arr.longitude);
  }

  Duration get deviationOfInitialRoute {
    return this.currentDuration - this.initialDuration;
  }

  get dateFormatted {
    return leadingZero(this.date.day.toString()) +
        "/" +
        leadingZero(this.date.month.toString()) +
        "/" +
        this.date.year.toString();
  }

  get timeFormatted {
    return leadingZero(this.date.hour.toString()) +
        ":" +
        leadingZero(this.date.minute.toString());
  }

  get vacantSeats {
    return this.limit - this.usedSeats;
  }
}
