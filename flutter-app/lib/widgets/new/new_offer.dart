import 'dart:async';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import "package:flutter_datetime_picker/flutter_datetime_picker.dart";
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/rides/createRide.dart';
import 'package:ulift/models/carona.dart';
import 'package:ulift/models/endereco.dart';

GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: googlePlaceAPI);

double depLat;
double depLon;

double arrLat;
double arrLon;

DateTime rideDate;

int maxUsers;

List<String> types = <String>['Todos', 'Alunos', 'Servidores'];
String userType = 'Todos';
List<String> genders = <String>['Todos', 'Mulheres', 'Homens'];
String userGender = 'Todos';

final TextEditingController departureController = TextEditingController();
final TextEditingController arrivalController = TextEditingController();
final TextEditingController dateController = TextEditingController();
final TextEditingController maxUsersController = TextEditingController();
final TextEditingController userTypeController = TextEditingController();

final _newRideForm = GlobalKey<FormState>();

bool _autovalidate;

Widget _isButton;

class NewOffer extends StatefulWidget {
  @override
  _NewOfferState createState() => _NewOfferState();
}

class _NewOfferState extends State<NewOffer> {
  Location currentLocation;

  @override
  void initState() {
    CurrentPage.page = Page.new_offer;
    getInitialLocation();
    _autovalidate = false;
    _setButton();
    super.initState();
  }

  void getInitialLocation() async {
    if (await checkGps(context)) {
      Geolocator()
          .getLastKnownPosition(desiredAccuracy: LocationAccuracy.best)
          .then((pos) {
        setState(() {
          currentLocation = Location(pos.latitude, pos.longitude);
        });
      });
    }
  }

  @override
  void dispose() {
    departureController.text = '';
    arrivalController.text = '';
    dateController.text = '';
    maxUsersController.text = '';
    userTypeController.text = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Nova Oferta de Carona'),
        ),
        body: Builder(
            builder: (context) => SingleChildScrollView(
                    child: Column(children: <Widget>[
                  Form(
                      key: _newRideForm,
                      autovalidate: _autovalidate,
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          Padding(padding: EdgeInsets.symmetric(vertical: 5)),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            leading: Icon(FontAwesomeIcons.streetView),
                            trailing: IconButton(
                              icon: Icon(Icons.gps_fixed),
                              onPressed: () async {
                                if (await checkGps(context)) {
                                  setState(() {
                                    _setAnimation();
                                    getCurrentPos(context, 'dep').then((val) {
                                      _setButton();
                                    });
                                  });
                                }
                              },
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                GestureDetector(
                                    onTap: () async {
                                      Prediction p =
                                          await PlacesAutocomplete.show(
                                              location: currentLocation,
                                              radius: 10,
                                              context: context,
                                              apiKey: googlePlaceAPI,
                                              mode: Mode.fullscreen,
                                              language: 'pt-BR');
                                      displayPrediction(p, "dep");
                                    },
                                    child: Container(
                                        color: Colors.transparent,
                                        child: IgnorePointer(
                                            child: TextFormField(
                                                style: TextStyle(
                                                    color: Colors.black),
                                                controller: departureController,
                                                keyboardType:
                                                    TextInputType.text,
                                                onFieldSubmitted:
                                                    (val) async {},
                                                validator: (value) {
                                                  if (value.isEmpty) {
                                                    return "Preencha o endereço";
                                                  }
                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                    border: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            width: 1,
                                                            color:
                                                                Colors.black)),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                    width: 1,
                                                                    color: Colors
                                                                        .black)),
                                                    labelText:
                                                        "Endereço de Partida",
                                                    labelStyle: TextStyle(
                                                        fontSize: 16,
                                                        color:
                                                            Colors.black)))))),
                              ],
                            ),
                          ),
                          Divider(
                            height: 20.0,
                            indent: 72.0,
                          ),
                          ListTile(
                            leading: Icon(FontAwesomeIcons.mapMarkedAlt),
                            trailing: IconButton(
                              icon: Icon(Icons.gps_fixed),
                              onPressed: () async {
                                if (await checkGps(context)) {
                                  setState(() {
                                    _setAnimation();
                                    getCurrentPos(context, 'arr').then((val) {
                                      _setButton();
                                    });
                                  });
                                }
                              },
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                GestureDetector(
                                    onTap: () async {
                                      Prediction p =
                                          await PlacesAutocomplete.show(
                                              location: currentLocation,
                                              radius: 10,
                                              context: context,
                                              apiKey: googlePlaceAPI,
                                              mode: Mode.fullscreen,
                                              language: 'pt-BR');
                                      displayPrediction(p, "arr");
                                    },
                                    child: Container(
                                        color: Colors.transparent,
                                        child: IgnorePointer(
                                            child: TextFormField(
                                                style: TextStyle(
                                                    color: Colors.black),
                                                controller: arrivalController,
                                                keyboardType:
                                                    TextInputType.text,
                                                onFieldSubmitted:
                                                    (val) async {},
                                                validator: (value) {
                                                  if (value.isEmpty) {
                                                    return "Preencha o endereço";
                                                  }
                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                    border: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            width: 1,
                                                            color:
                                                                Colors.black)),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                    width: 1,
                                                                    color: Colors
                                                                        .black)),
                                                    labelText:
                                                        "Endereço de Destino",
                                                    labelStyle: TextStyle(
                                                        fontSize: 16,
                                                        color:
                                                            Colors.black))))))
                              ],
                            ),
                          ),
                          Divider(
                            height: 20.0,
                            indent: 72.0,
                          ),
                          ListTile(
                            leading: Icon(FontAwesomeIcons.userClock),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                GestureDetector(
                                    onTap: () {
                                      displayDateTmePicker(context);
                                    },
                                    child: Container(
                                        color: Colors.transparent,
                                        child: IgnorePointer(
                                            child: TextFormField(
                                                style: TextStyle(
                                                    color: Colors.black),
                                                controller: dateController,
                                                keyboardType:
                                                    TextInputType.text,
                                                onFieldSubmitted:
                                                    (val) async {},
                                                validator: (value) {
                                                  if (value.isEmpty) {
                                                    return "Preencha a Data";
                                                  }
                                                  if (rideDate.isBefore(
                                                      DateTime.now())) {
                                                    return "Data inválida! Preencha uma data futura!";
                                                  }
                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                    border: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            width: 1,
                                                            color:
                                                                Colors.black)),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                    width: 1,
                                                                    color: Colors
                                                                        .black)),
                                                    labelText:
                                                        "Data de Partida",
                                                    labelStyle: TextStyle(
                                                        fontSize: 16,
                                                        color:
                                                            Colors.black))))))
                              ],
                            ),
                          ),
                          Divider(
                            height: 20.0,
                            indent: 72.0,
                          ),
                          ListTile(
                            leading: Icon(FontAwesomeIcons.users),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                GestureDetector(
                                    onTap: () {
                                      displayMaxUsers(context);
                                    },
                                    child: Container(
                                        color: Colors.transparent,
                                        child: IgnorePointer(
                                            child: TextFormField(
                                                style: TextStyle(
                                                    color: Colors.black),
                                                controller: maxUsersController,
                                                keyboardType:
                                                    TextInputType.text,
                                                onFieldSubmitted:
                                                    (val) async {},
                                                validator: (value) {
                                                  if (value.isEmpty) {
                                                    return "Preencha o número máximo de passageiros!";
                                                  }

                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                    border: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            width: 1,
                                                            color:
                                                                Colors.black)),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                    width: 1,
                                                                    color: Colors
                                                                        .black)),
                                                    labelText:
                                                        "Número Máximo de Passageiros",
                                                    labelStyle: TextStyle(
                                                        fontSize: 16,
                                                        color:
                                                            Colors.black))))))
                              ],
                            ),
                          ),
                          Divider(
                            height: 20.0,
                            indent: 72.0,
                          ),
                          ListTile(
                            leading: Icon(FontAwesomeIcons.userGraduate),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                FormField<String>(
                                  builder: (FormFieldState<String> state) {
                                    return InputDecorator(
                                      decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  width: 1,
                                                  color: Colors.black)),
                                          focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  width: 1,
                                                  color: Colors.black)),
                                          labelText:
                                              "Tipos de Passageiros Aceitos",
                                          labelStyle: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black)),
                                      isEmpty: userType == '',
                                      child: new DropdownButtonHideUnderline(
                                        child: new DropdownButton<String>(
                                          value: userType,
                                          isDense: true,
                                          onChanged: (String newValue) {
                                            setState(() {
                                              userType = newValue;
                                              state.didChange(newValue);
                                            });
                                          },
                                          items: types.map((String value) {
                                            return new DropdownMenuItem<String>(
                                              value: value,
                                              child: new Text(value),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 20.0,
                            indent: 72.0,
                          ),
                          ListTile(
                            leading: Icon(FontAwesomeIcons.venusMars),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                FormField<String>(
                                  builder: (FormFieldState<String> state) {
                                    return InputDecorator(
                                      decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  width: 1,
                                                  color: Colors.black)),
                                          focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  width: 1,
                                                  color: Colors.black)),
                                          labelText: "Gêneros Aceitos",
                                          labelStyle: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black)),
                                      isEmpty: userGender == '',
                                      child: new DropdownButtonHideUnderline(
                                        child: new DropdownButton<String>(
                                          value: userGender,
                                          isDense: true,
                                          onChanged: (String newValue) {
                                            setState(() {
                                              userGender = newValue;
                                              state.didChange(newValue);
                                            });
                                          },
                                          items: genders.map((String value) {
                                            return new DropdownMenuItem<String>(
                                              value: value,
                                              child: new Text(value),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                  Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                      child: _isButton),
                ]))));
  }

  Future<Null> displayPrediction(Prediction p, String type) async {
    if (p != null) {
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);

      if (type == "dep") {
        depLat = detail.result.geometry.location.lat;
        depLon = detail.result.geometry.location.lng;

        setState(() {
          departureController.text = p.description;
        });
      } else if (type == "arr") {
        arrLat = detail.result.geometry.location.lat;
        arrLon = detail.result.geometry.location.lng;
        setState(() {
          arrivalController.text = p.description;
        });
      }
    }
  }

  void displayDateTmePicker(context) {
    DatePicker.showDateTimePicker(context, showTitleActions: true,
        onConfirm: (date) {
      rideDate = date;
      setState(() {
        dateController.text =
            "${leadingZero(date.day)}/${leadingZero(date.month)}/${date.year} - ${leadingZero(date.hour)}:${leadingZero(date.minute)}";
      });
    }, currentTime: DateTime.now(), locale: LocaleType.pt);
  }

  void displayMaxUsers(context) {
    showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return new NumberPickerDialog.integer(
            initialIntegerValue: 1,
            minValue: 1,
            maxValue: 4,
            title: new Text("Número Máximo de Passageiros"),
          );
        }).then((val) {
      if (val != null) {
        maxUsers = val;
        setState(() {
          maxUsersController.text = val.toString();
        });
      }
    });
  }

  void _setButton() {
    setState(() {
      _isButton = RaisedButton.icon(
        onPressed: _newRide,
        label: Text("Criar Oferta"),
        icon: Icon(Icons.add),
      );
    });
  }

  void _setAnimation() {
    setState(() {
      _isButton = SpinKitDoubleBounce(color: Colors.tealAccent, size: 30);
    });
  }

  void _newRide() {
    setState(() {
      if (_newRideForm.currentState.validate() && checkConn(context)) {
        _setAnimation();

        Geocoder.local
            .findAddressesFromCoordinates(Coordinates(arrLat, arrLon))
            .then((response) async {
          String closeNeibourhood = "Não Definido";
          if (response.first != null && response.first.subLocality != null) {
            closeNeibourhood = response.first.subLocality;
          }
          Carona c = Carona(
              limit: maxUsers,
              status: 0,
              motorista: FireUserService.user.uid,
              date: rideDate,
              dep: Endereco(depLat, depLon,
                  description: departureController.text),
              arr:
                  Endereco(arrLat, arrLon, description: arrivalController.text),
              typeAccepted: userType,
              closeNeibourhoodToArr: closeNeibourhood,
              genderAccepted: userGender);
          createRide(c).then((val) {
            Navigator.pop(context, c.dep);
          });
        });
      } else {
        _autovalidate = true;
        _setButton();
      }
    });
  }

  Future<void> getCurrentPos(context, String type) async {
    Position location = await Geolocator()
        .getLastKnownPosition(desiredAccuracy: LocationAccuracy.best);

    if (location != null) {
      String description = await Endereco.descriptionFromLatLon(
          location.latitude, location.longitude);

      if (type == "dep") {
        depLat = location.latitude;
        depLon = location.longitude;

        departureController.text = description;
      } else {
        arrLat = location.latitude;
        arrLon = location.longitude;

        arrivalController.text = description;
      }
    } else {
      Flushbar(
        message: "Incapaz de obter posição atual!",
        duration: Duration(seconds: 3),
      ).show(context);
    }
    return;
  }
}
