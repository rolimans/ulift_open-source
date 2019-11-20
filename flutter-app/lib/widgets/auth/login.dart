import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
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
import 'package:ulift/widgets/auth/phone_confirm.dart';

var _telController = new MaskedTextController(mask: "(00) 0 0000-0000");
GlobalKey<FormState> _form = GlobalKey<FormState>();
var _telFocus = FocusNode();
bool _autovalidate = false;
String _defNum;

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void dispose() {
    _telController.text = "";
    _autovalidate = false;
    super.dispose();
  }

  @override
  void initState() {
    CurrentPage.page = Page.login;
    _telController.text = "";
    _autovalidate = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FancyBackground(
      child: Stack(
        children: <Widget>[
          Positioned(
            child: IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                Application.router.navigateTo(context, Routes.about).then((_) {
                  CurrentPage.page = Page.login;
                });
              },
            ),
            top: 30,
            right: 10,
          ),
          Content(),
        ],
      ),
      waves: <Widget>[
        FancyBackground.onBottom(AnimatedWave(
          height: 200,
          speed: 1.5,
          offset: pi,
        )),
        FancyBackground.onBottom(AnimatedWave(
          height: 150,
          speed: 0.5,
          offset: pi * 2,
        )),
        FancyBackground.onBottom(AnimatedWave(
          height: 100,
          speed: 1,
          offset: 1,
        ))
      ],
      track1: AnimationTrack(3, Color(0xff254e70), Color(0xff0abab5)),
      track2: AnimationTrack(3, Colors.white70, Color(0xff252525)),
    ));
  }
}

class Content extends StatefulWidget {
  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> with AfterLayoutMixin<Content> {
  Widget _isbutton = RaisedButton(onPressed: null);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SingleChildScrollView(
            child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: TypewriterAnimatedTextKit(
              duration: Duration(seconds: 5),
              isRepeatingAnimation: false,
              text: ["Bem vindo ao ULift. Para onde vamos hoje?"],
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
              "Login",
              style: TextStyle(
                  letterSpacing: 5,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Colors.white),
            )),
        Form(
          key: _form,
          autovalidate: _autovalidate,
          child: Column(
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: TextFormField(
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      controller: _telController,
                      focusNode: _telFocus,
                      onFieldSubmitted: (term) {
                        _telFocus.unfocus();
                        _login();
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
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0), child: _isbutton),
              FlatButton(
                onPressed: () {
                  Application.router.navigateTo(context, Routes.registerScreen);
                },
                child: Text(
                  "Registrar",
                  style: TextStyle(color: Color(0xffeeeeee)),
                ),
              )
            ],
          ),
        )
      ],
    )));
  }

  void _setButton() {
    setState(() {
      _isbutton = RaisedButton(
        onPressed: _login,
        child: Text("Login"),
      );
    });
  }

  void _setAnimation() {
    setState(() {
      _isbutton = SpinKitDoubleBounce(color: Colors.white, size: 30);
    });
  }

  void _login() {
    setState(() {
      if (_form.currentState.validate() && checkConn(context)) {
        _setAnimation();
        checkIfNumExists(formattedPhone(_telController.text)).then((val) {
          _setButton();
          if (!val) {
            dialogo(context, "Telefone não encontrado",
                "Nenhum usuário com este número foi encontrado",
                confirm: "Registrar", cancel: "Fechar", okFun: () {
              Navigator.pop(context);
              Application.router
                  .navigateTo(context, '/register?num=${_telController.text}');
            }, cancelFun: () {
              Navigator.pop(context);
              _telController.text = "";
              FocusScope.of(context).requestFocus(_telFocus);
            });
          } else {
            Usuario user = Usuario(number: _telController.text);
            Navigator.pop(context);
            UserService.user = user;
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PhoneConfirmScreen(
                          login: true,
                        )));
          }
        }).catchError((err) {
          Crashlytics.instance.log(err.toString());
        });
      } else {
        _autovalidate = true;
      }
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    if (_defNum != null) {
      _telController.text = _defNum;
    }
    _setButton();
  }
}
