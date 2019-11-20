import 'dart:convert' as JSON;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ulift/config/routes.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/models/usuario.dart';

final storage = new FlutterSecureStorage();

final FirebaseAuth _auth = FirebaseAuth.instance;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    CurrentPage.page = Page.splash;
    initial();
    super.initState();
  }

  void initial() async {
    Geolocator().getLastKnownPosition().catchError((e) {
      print("DENIED");
    });
    Unique.id = await FlutterUdid.udid;
    _auth.currentUser().then((val) {
      if (val == null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.loginScreen, (Route<dynamic> route) => false);
      } else {
        Crashlytics.instance.setUserEmail(val.uid);
        Crashlytics.instance.setUserName(val.uid);
        Crashlytics.instance.setUserIdentifier(val.uid);
        FireUserService.user = val;
        storage.read(key: "user_uid").then((uid) {
          if (uid == val.uid) {
            storage.read(key: 'user').then((u) {
              Usuario saved = Usuario.fromJson(JSON.jsonDecode(u));
              UserService.user = saved;
              Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.homeScreen, (Route route) => route == null);
            });
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(
                Routes.homeScreen, (Route route) => route == null);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(color: Colors.white),
            child: Image.asset(
              "images/splash.png",
              scale: 3,
            ),
          )
        ],
      ),
    );
  }
}
