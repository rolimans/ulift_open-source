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
import 'package:ulift/data_service/rides/ridesAPI.dart';
import 'package:ulift/models/endereco.dart';
import 'package:ulift/widgets/customs/custom_expansion_tile.dart';
import 'package:ulift/widgets/ride/rides_result_page.dart';

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

final _newRideForm = GlobalKey<FormState>();
final _customExpansionTile = GlobalKey<CustomExpansionTileState>();

bool _autovalidate;

bool _isOpened;

Widget _isButton;

class NewSearch extends StatefulWidget {
  final String departureTxt;
  final double depLatStart;
  final double depLonStart;
  final String arrTxt;
  final double arrLatStart;
  final double arrLonStart;
  final double radiusStart;

  NewSearch(
      {this.departureTxt,
      this.depLatStart,
      this.depLonStart,
      this.arrLatStart,
      this.arrLonStart,
      this.arrTxt,
      this.radiusStart});

  @override
  _NewSearchState createState() => _NewSearchState();
}

class _NewSearchState extends State<NewSearch> {
  Location currentLocation;

  @override
  void initState() {
    CurrentPage.page = Page.new_search;
    if (widget.depLonStart != null &&
        widget.depLatStart != null &&
        widget.departureTxt != null) {
      setState(() {
        departureController.text = widget.departureTxt;
      });
      depLat = widget.depLatStart;
      depLon = widget.depLonStart;
    }
    if (widget.arrLonStart != null &&
        widget.arrLatStart != null &&
        widget.arrTxt != null &&
        widget.radiusStart != null) {
      setState(() {
        arrivalController.text = widget.arrTxt;
        radiusController.text = widget.radiusStart.toString();
      });
      arrLat = widget.arrLatStart;
      arrLon = widget.arrLonStart;
      radius = widget.radiusStart;
    }
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
          title: Text('Nova Busca de Carona'),
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
                                            displayDateTimePicker(
                                                context, 'init');
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
                                              displayDateTimePicker(
                                                  context, 'end');
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

  void displayDateTimePicker(context, whichOne) {
    if (whichOne == 'init') {
      DatePicker.showDateTimePicker(context, showTitleActions: true,
          onConfirm: (date) {
        initDate = date;
        setState(() {
          initDateController.text =
              "${leadingZero(date.day)}/${leadingZero(date.month)}/${date.year} - ${leadingZero(date.hour)}:${leadingZero(date.minute)}";
        });
      }, currentTime: DateTime.now(), locale: LocaleType.pt);
    } else {
      DatePicker.showDateTimePicker(context, showTitleActions: true,
          onConfirm: (date) {
        endDate = date;
        setState(() {
          endDateController.text =
              "${leadingZero(date.day)}/${leadingZero(date.month)}/${date.year} - ${leadingZero(date.hour)}:${leadingZero(date.minute)}";
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
        onPressed: _newSearch,
        label: Text("Pesquisar"),
        icon: Icon(Icons.search),
      );
    });
  }

  void _setAnimation() {
    setState(() {
      _isButton = SpinKitDoubleBounce(color: Colors.tealAccent, size: 30);
    });
  }

  void _newSearch() {
    setState(() {
      if (_newRideForm.currentState.validate() &&
          _customValidateEnd() &&
          _customValidateInit() &&
          checkConn(context)) {
        _setAnimation();
        var data = DataToGetRides(
            currentUser: FireUserService.user.uid,
            goFrom: Endereco(depLat, depLon),
            goTo: Endereco(arrLat, arrLon),
            radius: radius,
            tipo: UserService.user.levelFormatted,
            gender: UserService.user.genderFormatted);
        if (initDateController.text.isNotEmpty &&
            endDateController.text.isNotEmpty) {
          data.initDate = initDate.millisecondsSinceEpoch;
          data.endDate = endDate.millisecondsSinceEpoch;
        }
        ridesAPI(data).then((ResultFromAPI r) {
          if (r.results.length == 0) {
            if (endDateController.text.isEmpty) {
              DataForFrequentSearch d =
                  DataForFrequentSearch.fromDataToGetRides(data,
                      goToDesc: arrivalController.text,
                      goFromDesc: departureController.text,
                      goFrom: [depLat, depLon],
                      goTo: [arrLat, arrLon]);
              addFrequentSearch(d);
            }
          }
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ResultsPage(r, arrivalController.text)));
          _setButton();
        });
      } else {
        if (initDateController.text.isNotEmpty) {
          _customExpansionTile.currentState.expand();
          Future.delayed(const Duration(milliseconds: 200), () {
            _newRideForm.currentState.validate();
          });
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
