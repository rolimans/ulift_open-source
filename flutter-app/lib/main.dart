import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:ulift/config/application.dart';
import 'package:ulift/config/routes.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/util/util.dart';

void main() {
  ConnectionStatusSingleton connectionStatus =
      ConnectionStatusSingleton.getInstance();
  connectionStatus.initialize();
  initNetWatcher();
  setTimeOffset();
  Crashlytics.instance.enableInDevMode = true;
  FlutterError.onError = Crashlytics.instance.recordFlutterError;
  Crashlytics.instance.setUserEmail("UNLOGGED");
  Crashlytics.instance.setUserName("UNLOGGED");
  Crashlytics.instance.setUserIdentifier("UNLOGGED");
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  _AppState() {
    final router = new Router();
    Routes.configureRoutes(router);
    Application.router = router;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ULift',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.cyan,
        backgroundColor: Color(0xff0abab5),
        fontFamily: 'Roboto',
        hintColor: Color(0xffe8e9eb),
        cursorColor: Color(0xffe8e9eb),
        primaryColor: Colors.white,
        primaryColorDark: Color(0xff252525),
        accentColor: Color(0xff254e70),
        buttonColor: Color(0xff0abab5),
        iconTheme: IconThemeData(color: Color(0xff0abab5)),
      ),
      onGenerateRoute: Application.router.generator,
    );
  }
}
