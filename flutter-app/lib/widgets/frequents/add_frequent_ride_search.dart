import 'dart:async';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import "package:flutter_datetime_picker/flutter_datetime_picker.dart";
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/frequents/frequentRequests.dart';
import 'package:ulift/models/endereco.dart';
import 'package:ulift/widgets/customs/custom_expansion_tile.dart';
import 'package:ulift/widgets/customs/days_of_week.dart';

GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: googlePlaceAPI);

double depLat;
double depLon;

double arrLat;
double arrLon;

DateTime initDate;
DateTime endDate;

double radius;

final TextEditingController departureController = TextEditingController();
final TextEditingController arrivalController = TextEditingController();
final TextEditingController initDateController = TextEditingController();
final TextEditingController endDateController = TextEditingController();
final TextEditingController radiusController = TextEditingController();

final _newFrequentRideForm = GlobalKey<FormState>();
final _customExpansionTile = GlobalKey<CustomExpansionTileState>();

bool _autovalidate;

bool _isOpened;

Widget _isButton;

class AddFrequentRideSearch extends StatefulWidget {
  AddFrequentRideSearch();

  @override
  _AddFrequentRideSearchState createState() => _AddFrequentRideSearchState();
}

class _AddFrequentRideSearchState extends State<AddFrequentRideSearch> {
  Location currentLocation;
  List<bool> days = [false, false, false, false, false, false, false];

  @override
  void initState() {
    CurrentPage.page = Page.add_frequent_ride_search;
    getInitialLocation();
    _autovalidate = false;
    _isOpened = false;
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
    departureController.text = arrivalController.text = initDateController
        .text = endDateController.text = radiusController.text = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Nova Busca Frequente de Carona'),
        ),
        body: Builder(
            builder: (context) => SingleChildScrollView(
                    child: Column(children: <Widget>[
                  Form(
                      key: _newFrequentRideForm,
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
                            leading: Icon(FontAwesomeIcons.users),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                GestureDetector(
                                    onTap: () {
                                      displayRadius(context);
                                    },
                                    child: Container(
                                        color: Colors.transparent,
                                        child: IgnorePointer(
                                            child: TextFormField(
                                                style: TextStyle(
                                                    color: Colors.black),
                                                controller: radiusController,
                                                keyboardType:
                                                    TextInputType.text,
                                                onFieldSubmitted:
                                                    (val) async {},
                                                validator: (value) {
                                                  if (value.isEmpty) {
                                                    return "Preencha o raio máximo de distância até o ponto de partida da carona!";
                                                  }

                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                    border: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            width: 1,
                                                            color:
                                                                Colors.black)),
                                                    suffix: Text(
                                                      'metros',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                    width: 1,
                                                                    color: Colors
                                                                        .black)),
                                                    labelText:
                                                        "Raio máximo até a partida da carona",
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
                          Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: CustomExpansionTile(
                              onExpansionChanged: (val) {
                                setState(() {
                                  _isOpened = val;
                                });
                              },
                              leading: Icon(FontAwesomeIcons.userClock),
                              title: Text(
                                  'Pesquisar carona em certo intervalo de tempo'),
                              key: _customExpansionTile,
                              children: <Widget>[
                                ListTile(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      GestureDetector(
                                          onTap: () {
                                            displayDatePicker(context, 'init');
                                          },
                                          child: Container(
                                              color: Colors.transparent,
                                              child: IgnorePointer(
                                                  child: TextFormField(
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                      controller:
                                                          initDateController,
                                                      keyboardType:
                                                          TextInputType.text,
                                                      onFieldSubmitted:
                                                          (val) async {},
                                                      validator: (value) {
                                                        if (value.isEmpty) {
                                                          if (_isOpened)
                                                            return "Preencha a Data Inicial";
                                                          else
                                                            return null;
                                                        }
                                                        if (initDate.isBefore(
                                                            DateTime.now())) {
                                                          return "Data inválida! Preencha uma data futura!";
                                                        }
                                                        return null;
                                                      },
                                                      decoration: InputDecoration(
                                                          border: OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  width: 1,
                                                                  color: Colors
                                                                      .black)),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                      width: 1,
                                                                      color: Colors
                                                                          .black)),
                                                          labelText:
                                                              "Data Inicial",
                                                          labelStyle: TextStyle(
                                                              fontSize: 16,
                                                              color: Colors
                                                                  .black))))))
                                    ],
                                  ),
                                ),
                                Divider(
                                  height: 20.0,
                                  indent: 72.0,
                                ),
                                ListTile(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      GestureDetector(
                                          onTap: () {
                                            if (initDateController
                                                .text.isNotEmpty)
                                              displayDatePicker(context, 'end');
                                            else
                                              Flushbar(
                                                message:
                                                    "Preencha a data inicial primeiro!",
                                                duration: Duration(seconds: 2),
                                              ).show(context);
                                          },
                                          child: Container(
                                              color: Colors.transparent,
                                              child: IgnorePointer(
                                                  child: TextFormField(
                                                      style:
                                                          TextStyle(
                                                              color:
                                                                  Colors.black),
                                                      controller:
                                                          endDateController,
                                                      keyboardType:
                                                          TextInputType.text,
                                                      enabled:
                                                          initDateController
                                                              .text.isNotEmpty,
                                                      validator: (value) {
                                                        if (value.isEmpty) {
                                                          if (_isOpened ||
                                                              initDateController
                                                                  .text
                                                                  .isNotEmpty)
                                                            return "Preencha a Data Final";
                                                          else
                                                            return null;
                                                        }
                                                        if (endDate.isBefore(
                                                            initDate)) {
                                                          return "Data inválida! Preencha uma data após a data inicial!";
                                                        }
                                                        return null;
                                                      },
                                                      decoration: InputDecoration(
                                                          border: OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  width: 1,
                                                                  color: Colors
                                                                      .black)),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                      width: 1,
                                                                      color: Colors
                                                                          .black)),
                                                          labelText:
                                                              "Data Final",
                                                          labelStyle: TextStyle(
                                                              fontSize: 16,
                                                              color: Colors
                                                                  .black))))))
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 20.0,
                            indent: 72.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                                leading: Icon(Icons.calendar_today),
                                title: Column(
                                  children: <Widget>[
                                    Text("Buscar nesses dias da semana:"),
                                    DaysOfWeek(days),
                                  ],
                                )),
                          ),
                          Divider(
                            height: 20.0,
                            indent: 72.0,
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

  void displayDatePicker(context, whichOne) {
    if (whichOne == 'init') {
      DatePicker.showDatePicker(context, showTitleActions: true,
          onConfirm: (date) {
        initDate = date;
        setState(() {
          initDateController.text = "${date.day}/${date.month}/${date.year}";
        });
      }, currentTime: DateTime.now(), locale: LocaleType.pt);
    } else {
      DatePicker.showDatePicker(context, showTitleActions: true,
          onConfirm: (date) {
        endDate = date;
        setState(() {
          endDateController.text = "${date.day}/${date.month}/${date.year}";
        });
      }, currentTime: initDate, locale: LocaleType.pt);
    }
  }

  void displayRadius(context) {
    showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return new NumberPickerDialog.integer(
            initialIntegerValue: 1000,
            minValue: 100,
            maxValue: 2000,
            step: 100,
            title: new Text(
                "Raio Máximo de Distância Até o Ponto de Partida da Carona"),
          );
        }).then((val) {
      if (val != null) {
        radius = val.toDouble();
        setState(() {
          radiusController.text = val.toString();
        });
      }
    });
  }

  void _setButton() {
    setState(() {
      _isButton = RaisedButton.icon(
        onPressed: () {
          if (checkConn(context)) {
            _newFrequentSearch();
          }
        },
        label: Text("Adicionar Pesquisa"),
        icon: Icon(Icons.add),
      );
    });
  }

  void _setAnimation() {
    setState(() {
      _isButton = SpinKitDoubleBounce(color: Colors.tealAccent, size: 30);
    });
  }

  bool _validateDays() {
    return days.contains(true);
  }

  void _newFrequentSearch() {
    setState(() {
      if (checkConn(context) &&
          _newFrequentRideForm.currentState.validate() &&
          _customValidateEnd() &&
          _customValidateInit() &&
          _validateDays()) {
        _setAnimation();
        DataForFrequentSearch d = DataForFrequentSearch(
          gender: UserService.user.genderFormatted,
          tipo: UserService.user.levelFormatted,
          goTo: [arrLat, arrLon],
          goFrom: [depLat, depLon],
          radius: radius,
          author: FireUserService.user.uid,
          goFromDesc: departureController.text,
          goToDesc: arrivalController.text,
          initDate: initDate?.millisecondsSinceEpoch,
          endDate: endDate?.millisecondsSinceEpoch,
          daysOfWeek: days,
          standard: true,
        );
        addFrequentSearch(d).then((did) {
          if (did) {
            Navigator.pop(context);
            Flushbar(
              message: "Busca frequente adicionada!",
              duration: Duration(seconds: 2),
            ).show(context);
          } else {
            Flushbar(
              message: "Erro ao adicionar busca frequente!",
              duration: Duration(seconds: 2),
            ).show(context);
          }
        });
      } else {
        if (initDateController.text.isNotEmpty) {
          _customExpansionTile.currentState.expand();
          Future.delayed(const Duration(milliseconds: 200), () {
            _newFrequentRideForm.currentState.validate();
          });
        }

        if (!_validateDays()) {
          Flushbar(
            message: "Selecione pelo menos um dia da semana!",
            duration: Duration(seconds: 2),
          ).show(context);
        }

        _autovalidate = true;
        _setButton();
      }
    });
  }

  bool _customValidateInit() {
    var value = initDateController.text;
    if (value.isEmpty) {
      if (_isOpened)
        return false;
      else
        return true;
    }
    if (initDate.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }

  bool _customValidateEnd() {
    var value = endDateController.text;
    if (value.isEmpty) {
      if (_isOpened || initDateController.text.isNotEmpty)
        return false;
      else
        return true;
    }
    if (endDate.isBefore(initDate)) {
      return false;
    }
    return true;
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
