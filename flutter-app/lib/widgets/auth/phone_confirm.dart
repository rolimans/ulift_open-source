import 'dart:async';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ulift/animations/fancy_background.dart';
import 'package:ulift/config/routes.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/user/createUser.dart';
import 'package:ulift/util/util.dart';

Timer _timer;
int _start;
String _sec;
bool _canGoBack;
var _funcSendAgain;
final FirebaseAuth _auth = FirebaseAuth.instance;
Widget _isButton = SpinKitDoubleBounce(color: Colors.white, size: 30);

final GlobalKey<FormState> _form = GlobalKey<FormState>();
final _codeController = TextEditingController();
String _verificationId;

class PhoneConfirmScreen extends StatefulWidget {
  final bool changeNumber;
  final bool login;
  final String oldNumber;

  PhoneConfirmScreen({Key key, this.changeNumber, this.oldNumber, this.login})
      : super(key: key);

  @override
  _PhoneConfirmScreenState createState() => _PhoneConfirmScreenState();
}

class _PhoneConfirmScreenState extends State<PhoneConfirmScreen> {
  @override
  void initState() {
    CurrentPage.page = Page.phone_confirm;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (_canGoBack) {
            if (widget.changeNumber == true) {
              Navigator.pop(context, false);
            } else {
              if (widget.login == true) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    Routes.loginScreen, (Route route) => route == null);
              } else {
                Navigator.pop(context);
              }
            }
            return false;
          }
          return false;
        },
        child: Scaffold(
            body: FancyBackground(
          child: Content(
            changeNumber: widget.changeNumber,
            oldNumber: widget.oldNumber,
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
        )));
  }
}

class Content extends StatefulWidget {
  final bool changeNumber;
  final String oldNumber;

  Content({this.changeNumber, this.oldNumber});

  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> with AfterLayoutMixin<Content> {
  void _signInWithPhoneNumber(String sms) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.getCredential(
        verificationId: _verificationId,
        smsCode: sms,
      );
      if (widget.changeNumber == true) {
        _afterConfirm(credential);
      } else {
        final FirebaseUser user =
            (await _auth.signInWithCredential(credential)).user;
        final FirebaseUser currentUser = await _auth.currentUser();
        assert(user.uid == currentUser.uid);
        setState(() {
          if (user != null) {
            Scaffold.of(context).showSnackBar(new SnackBar(
              content: new Text("Telefone verificado com sucesso!"),
              duration: Duration(seconds: 1),
            ));
            _afterConfirm(credential);
          } else {
            Scaffold.of(context).showSnackBar(new SnackBar(
              content: new Text("Erro ao logar!"),
              duration: Duration(seconds: 1),
            ));
            _setButton();
          }
        });
      }
    } catch (err) {
      Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text("Código inválido!"),
        duration: Duration(seconds: 1),
      ));
      _setButton();
    }
  }

  void afterFirstLayout(BuildContext context) {
    _verifyPhoneNumber();
  }

  void _verifyPhoneNumber() async {
    _setButton();

    setState(() {
      _start = 60;
      _sec = "($_start)";
      _canGoBack = false;
      _funcSendAgain = null;
    });

    _startTimer();

    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {
      if (widget.changeNumber == true) {
        _afterConfirm(phoneAuthCredential);
      } else {
        _auth.signInWithCredential(phoneAuthCredential).then((value) {
          Scaffold.of(context).showSnackBar(new SnackBar(
            content: new Text("Telefone verificado com sucesso!"),
            duration: Duration(seconds: 1),
          ));
          _afterConfirm(phoneAuthCredential);
        });
      }
    };

    final PhoneVerificationFailed verificationFailed =
        (AuthException authException) {
      Crashlytics.instance.log(authException.message);
      Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text("A verificação falhou! Tente novamente!"),
        duration: Duration(seconds: 1),
      ));
    };

    final PhoneCodeSent codeSent =
        (String verification, [int forceResendingToken]) async {
      Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text("Código enviado com sucesso"),
        duration: Duration(milliseconds: 500),
      ));
      _verificationId = verification;
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verification) {
      _verificationId = verification;
    };

    await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone(UserService.user.number),
        timeout: const Duration(seconds: 5),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SingleChildScrollView(
            child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TypewriterAnimatedTextKit(
          duration: Duration(seconds: 5),
          isRepeatingAnimation: false,
          text: ["Digite o código recebido por SMS"],
          textAlign: TextAlign.center,
          textStyle: TextStyle(
              letterSpacing: 5,
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: Colors.white),
        ),
        Form(
          key: _form,
          child: Column(
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15),
                  child: TextFormField(
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.phone,
                      controller: _codeController,
                      onFieldSubmitted: (val) {
                        _signIn();
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Preencha o código";
                        }

                        if (!RegExp(r'^[0-9]*$').hasMatch(value)) {
                          return "O código deve conter apenas números";
                        }

                        return null;
                      },
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Código SMS",
                          labelStyle: TextStyle(fontSize: 16)))),
              _isButton,
              FlatButton(
                onPressed: _funcSendAgain,
                child: Text("$_sec Reenviar código "),
              ),
            ],
          ),
        )
      ],
    )));
  }

  void _signIn() {
    if (_form.currentState.validate() && checkConn(context)) {
      _setAnimation();
      _signInWithPhoneNumber(_codeController.text);
    }
  }

  @override
  void dispose() {
    _codeController.text = "";
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
        oneSec,
        (Timer timer) => setState(() {
              if (_start < 1) {
                timer.cancel();
                _sec = "";
                _canGoBack = true;
                _funcSendAgain = _sendAgain;
              } else {
                _start = _start - 1;
                _sec = "($_start)";
              }
            }));
  }

  void _sendAgain() {
    setState(() {
      _verifyPhoneNumber();
      _funcSendAgain = null;
      _canGoBack = false;
    });
  }

  void _setAnimation() {
    setState(() {
      _isButton = SpinKitDoubleBounce(color: Colors.white, size: 30);
    });
  }

  void _setButton() {
    setState(() {
      _isButton = RaisedButton(
        onPressed: _signIn,
        child: Text("Confirmar"),
      );
    });
  }

  void _afterConfirm(var credential) async {
    _timer.cancel();
    if (widget.changeNumber == true) {
      try {
        _setAnimation();
        await (await FirebaseAuth.instance.currentUser())
            .updatePhoneNumberCredential(credential);
        FireUserService.user = await FirebaseAuth.instance.currentUser();
        await changeUserPhone(
            FireUserService.user, UserService.user.number, widget.oldNumber);
        Navigator.pop(context, true);
      } catch (e) {
        Crashlytics.instance.log(e.toString());
        Navigator.pop(context, false);
      }
    } else {
      FireUserService.user = await FirebaseAuth.instance.currentUser();
      if (UserService.user.mat != null) {
        await createUser(FireUserService.user, UserService.user);
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.homeScreen, (Route route) => route == null);
    }
  }
}
