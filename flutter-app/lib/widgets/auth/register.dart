import 'dart:async';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ulift/animations/fancy_background.dart';
import 'package:ulift/config/application.dart';
import 'package:ulift/config/routes.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/generic/checkData.dart';
import 'package:ulift/models/usuario.dart';
import 'package:ulift/util/dialogo.dart';
import 'package:ulift/util/util.dart';
import 'package:url_launcher/url_launcher.dart';

final _numController = new MaskedTextController(mask: "(00) 0 0000-0000");
final _nomeController = new TextEditingController();
final _matController = new TextEditingController();
final _nomeFocus = new FocusNode();
final _numFocus = new FocusNode();
final _matFocus = new FocusNode();
final _secondForm = GlobalKey<FormState>();
final _birthController = TextEditingController();
DateTime _birth = DateTime.now();
String _sex;
bool _terms = false;
bool _clicked = false;
bool _selected = false;
bool _autovalidate = false;
String _defNum;

class RegisterScreen extends StatefulWidget {
  RegisterScreen({Key key, num}) {
    _defNum = num;
  }

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  void dispose() {
    _nomeController.text =
        _numController.text = _matController.text = _birthController.text = "";

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            body: FancyBackground(
          child: Content(),
          waves: <Widget>[
            FancyBackground.onBottom(AnimatedWave(
              height: 250,
              speed: 1,
              offset: pi,
            )),
            FancyBackground.onBottom(AnimatedWave(
              height: 200,
              speed: 1.5,
              offset: pi * 2,
            )),
            FancyBackground.onBottom(AnimatedWave(
              height: 150,
              speed: 2,
              offset: 1,
            ))
          ],
          track1: AnimationTrack(3, Color(0xff254e70), Color(0xff0abab5)),
          track2: AnimationTrack(3, Colors.lime, Colors.blueAccent),
        )));
  }
}

class Content extends StatefulWidget {
  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> with AfterLayoutMixin<Content> {
  Widget _isButton = RaisedButton(onPressed: null);

  @override
  void initState() {
    CurrentPage.page = Page.register;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SingleChildScrollView(
            child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.fromLTRB(0, 25, 0, 0),
            child: TypewriterAnimatedTextKit(
              duration: Duration(seconds: 5),
              isRepeatingAnimation: false,
              text: [
                "Com alguns dados aqui, outros ali, o app estará prontinho pra você!"
              ],
              textAlign: TextAlign.center,
              textStyle: TextStyle(
                  letterSpacing: 5,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Colors.white),
            )),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "Registrar",
              style: TextStyle(
                  letterSpacing: 5,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Colors.white),
            )),
        Form(
          key: _secondForm,
          autovalidate: _autovalidate,
          child: Column(
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: TextFormField(
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.text,
                      focusNode: _nomeFocus,
                      textCapitalization: TextCapitalization.words,
                      onFieldSubmitted: (term) {
                        _nomeFocus.unfocus();
                        FocusScope.of(context).requestFocus(_numFocus);
                      },
                      controller: _nomeController,
                      validator: (value) {
                        if (value.isNotEmpty) {
                          return null;
                        }
                        return "Digite seu nome";
                      },
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Nome Completo",
                          labelStyle: TextStyle(fontSize: 16)))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: TextFormField(
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      controller: _numController,
                      focusNode: _numFocus,
                      onFieldSubmitted: (term) {
                        _numFocus.unfocus();
                        FocusScope.of(context).requestFocus(_matFocus);
                      },
                      validator: (value) {
                        if (RegExp(r"^\([1-9]{2}\) 9 [0-9]{4}\-[0-9]{4}$")
                            .hasMatch(value)) {
                          return null;
                        }
                        return "Digite um número de telefone válido";
                      },
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Telefone",
                          labelStyle: TextStyle(fontSize: 16)))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: TextFormField(
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.text,
                      focusNode: _matFocus,
                      controller: _matController,
                      onFieldSubmitted: (term) {
                        _matFocus.unfocus();
                        _selectDate(context);
                      },
                      validator: (value) {
                        if (value.isNotEmpty) {
                          return null;
                        }
                        return "Digite um Número de Matrícula válido";
                      },
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Número de Matrícula",
                          labelStyle: TextStyle(fontSize: 16)))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: GestureDetector(
                    onTap: () {
                      _numFocus.unfocus();
                      _nomeFocus.unfocus();
                      _matFocus.unfocus();
                      _selectDate(context);
                    },
                    child: Container(
                        color: Colors.transparent,
                        child: IgnorePointer(
                            child: TextFormField(
                                style: TextStyle(color: Colors.white),
                                controller: _birthController,
                                validator: (val) {
                                  if (_birth.isAfter(DateTime(
                                      DateTime.now().year - 14,
                                      DateTime.now().month,
                                      DateTime.now().day))) {
                                    return "Você deve ter no mínimo 14 anos para utilizar o app";
                                  }

                                  return null;
                                },
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: "Data de Nascimento",
                                    labelStyle: TextStyle(fontSize: 16))))),
                  )),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Eu sou:',
                      style: TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                    Radio(
                      value: "F",
                      groupValue: _sex,
                      onChanged: (val) {
                        setState(() {
                          _sex = val;
                          _selected = true;
                        });
                      },
                    ),
                    Text(
                      'Mulher',
                      style: TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                    Radio(
                      value: "M",
                      groupValue: _sex,
                      onChanged: (val) {
                        setState(() {
                          _sex = val;
                          _selected = true;
                        });
                      },
                    ),
                    Text(
                      'Homem',
                      style: TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Visibility(
                  visible: _clicked && !_selected,
                  child: Text("Selecione uma opção!",
                      style: TextStyle(color: Colors.red, fontSize: 10))),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: <Widget>[
                    Checkbox(
                      value: _terms,
                      onChanged: (value) => setState(() => _terms = value),
                    ),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                    text: "Declaro que li e concordo com os "),
                                TextSpan(
                                    text: "Termos de Uso ",
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchTermsAndConditions();
                                      }),
                                TextSpan(text: "e "),
                                TextSpan(
                                    text: "Política de Privacidade",
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchPrivacyPolicy();
                                      })
                              ],
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          Visibility(
                            visible: !_terms && _clicked,
                            child: Text(
                              'É nescessário concordar para prosseguir.',
                              style: TextStyle(color: Colors.red, fontSize: 10),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0), child: _isButton),
              FlatButton(
                onPressed: () {
                  _onWillPop();
                  Navigator.pop(context);
                },
                child: Text(
                  "Já tenho uma conta!",
                  style: TextStyle(color: Color(0xffeeeeee)),
                ),
              )
            ],
          ),
        )
      ],
    )));
  }

  void _registrar() {
    setState(() {
      _clicked = true;
      if (_secondForm.currentState.validate() &&
          _terms &&
          _selected &&
          checkConn(context)) {
        _setAnimation();

        checkIfNumExists(formattedPhone(_numController.text)).then((val) {
          if (val) {
            _setButton();
            dialogo(context, "Seu número já está registrado",
                "Já existe um usuário com o número ${_numController.text}",
                confirm: "Fazer Login", cancel: "Alterar número", okFun: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login?num=${_numController.text}',
                  (Route route) => route == null);
            }, cancelFun: () {
              Navigator.pop(context);
              _numController.text = "";
              FocusScope.of(context).requestFocus(_numFocus);
            });
          } else {
            checkIfMatIsValid(_matController.text.toLowerCase()).then((val) {
              _setButton();
              if (val) {
                dialogo(context, "Confirmar número",
                    "O número ${_numController.text} está correto?",
                    confirm: "Sim", cancel: "Não", okFun: () {
                  Usuario user = Usuario(
                      number: _numController.text,
                      mat: _matController.text.toLowerCase(),
                      nome: _nomeController.text.trim(),
                      sex: _sex,
                      birth: _birth,
                      level: "A",
                      tipo: 1);
                  UserService.user = user;
                  Navigator.pop(context);
                  Application.router.navigateTo(context, Routes.phoneConfirm);
                }, cancelFun: () {
                  Navigator.pop(context);
                  _numController.text = "";
                  FocusScope.of(context).requestFocus(_numFocus);
                });
              } else {
                dialogo(context, "O Número de Matrícula não é válido",
                    "Lamentamos informar mas seu Número de Matrícula não se encontra no corpo discente da instituição.",
                    confirm: "Ok", okFun: () {
                  Navigator.pop(context);
                  _matController.text = "";
                  FocusScope.of(context).requestFocus(_matFocus);
                });
              }
            });
          }
        });
      } else {
        _autovalidate = true;
      }
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _setButton();
    if (_defNum != null) {
      _numController.text = _defNum;
    }
    _changeDate();
  }

  void _setButton() {
    setState(() {
      _isButton = RaisedButton(
        onPressed: _registrar,
        child: Text("Registrar"),
      );
    });
  }

  void _setAnimation() {
    setState(() {
      _isButton = SpinKitDoubleBounce(color: Colors.white, size: 30);
    });
  }

  Future<Null> _selectDate(BuildContext context) async {
    DatePicker.showDatePicker(context, showTitleActions: true,
        onConfirm: (date) {
      setState(() {
        _birth = date;
        _changeDate();
      });
    },
        currentTime: _birth,
        maxTime: DateTime.now(),
        minTime: DateTime(1900),
        locale: LocaleType.pt);
  }

  void _changeDate() {
    _birthController.text =
        "${leadingZero(_birth.day)}/${leadingZero(_birth.month)}/${_birth.year}";
  }
}

void launchPrivacyPolicy() async {
  String url =
      "YOUR FIREBASE STORAGE URL/o/docs%2Fprivacy_policy.html?alt=media";
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    Crashlytics.instance.log("UNABLE TO LAUNCH URL");
  }
}

void launchTermsAndConditions() async {
  String url =
      "YOUR FIREBASE STORAGE URL/o/docs%2Fterms_and_conditions.html?alt=media";
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    Crashlytics.instance.log("UNABLE TO LAUNCH URL");
  }
}

Future<bool> _onWillPop() async {
  _matController.text = "";
  _numController.text = "";
  _birth = DateTime.now();
  _sex = null;
  _autovalidate = false;
  _clicked = false;
  _selected = false;
  _terms = false;
  return true;
}
