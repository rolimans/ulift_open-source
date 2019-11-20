import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ulift/animations/fancy_background.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/generic/checkData.dart';
import 'package:ulift/util/dialogo.dart';
import 'package:ulift/util/util.dart';
import 'package:ulift/widgets/auth/phone_confirm.dart';

final _telController = new MaskedTextController(mask: "(00) 0 0000-0000");
final GlobalKey<FormState> _form = GlobalKey<FormState>();
final _telFocus = FocusNode();
bool _autovalidate = false;

class ChangePhoneNumberScreen extends StatefulWidget {
  ChangePhoneNumberScreen({Key key});

  @override
  _ChangePhoneNumberScreenState createState() =>
      _ChangePhoneNumberScreenState();
}

class _ChangePhoneNumberScreenState extends State<ChangePhoneNumberScreen> {
  @override
  void initState() {
    CurrentPage.page = Page.change_phone_number;
    super.initState();
  }

  @override
  void dispose() {
    _telController.text = "";
    _autovalidate = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FancyBackground(
      child: Content(),
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
              text: ["Digite o número para qual deseja mudar!"],
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
              "Alterar Número de Telefone:",
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
                        _change();
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
            ],
          ),
        )
      ],
    )));
  }

  void _setButton() {
    setState(() {
      _isbutton = RaisedButton(
        onPressed: _change,
        child: Text("Mudar"),
      );
    });
  }

  void _setAnimation() {
    setState(() {
      _isbutton = SpinKitDoubleBounce(color: Colors.white, size: 30);
    });
  }

  void _change() {
    setState(() {
      if (_form.currentState.validate() && checkConn(context)) {
        _setAnimation();
        checkIfNumExists(formattedPhone(_telController.text)).then((val) {
          _setButton();
          if (val) {
            dialogo(context, "Já existe um usuário com esse número",
                "Você não pode mudar seu número para ${_telController.text}, pois já existe um usuário com esse número",
                confirm: "Ok", okFun: () {
              Navigator.pop(context);
            });
          } else {
            String oldNumber = UserService.user.number;
            UserService.user.number = _telController.text;
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PhoneConfirmScreen(
                          changeNumber: true,
                          oldNumber: oldNumber,
                        ))).then((did) {
              CurrentPage.page = Page.change_phone_number;
              if (did) {
                Navigator.pop(context);
                Flushbar(
                  message: "Número alterado com sucesso!",
                  duration: Duration(seconds: 2),
                ).show(context);
              } else {
                UserService.user.number = oldNumber;
                Flushbar(
                  message:
                      "Seu número não foi alterado pois não foi possível verificar o novo número!",
                  duration: Duration(seconds: 3),
                ).show(context);
              }
            });
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
    _setButton();
  }
}
