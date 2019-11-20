import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:ulift/config/route_handlers.dart';
import 'package:ulift/widgets/home.dart';

class Routes {
  static String root = '/';
  static String homeScreen = '/home';
  static String loginScreen = '/login';
  static String registerScreen = '/register';
  static String phoneConfirm = '/phoneConfirm';
  static String userProfile = '/user/:id';
  static String newOffer = '/new/offer';
  static String newSearch = '/new/search';
  static String rideApplied = '/ride/applied';
  static String chatPage = '/chat';
  static String appliedRides = '/rides/applieds';
  static String myRides = '/rides/mines';
  static String driverRequest = '/driverRequest';
  static String notifications = '/notifications';
  static String changeNumber = '/changeNumber';
  static String addFrequentSearch = '/addFrequentSearch';
  static String addFrequentOffer = '/addFrequentOffer';
  static String frequentOffers = "/frequentOffers";
  static String frequentSearches = "/frequentSearches";
  static String about = "/about";

  static void configureRoutes(Router router) {
    router.notFoundHandler = new Handler(
        handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      Crashlytics.instance.log("Route doesnt Exist");
      return HomeScreen();
    });
    router.define(root, handler: rootHandler);

    router.define(homeScreen, handler: homeHandler);
    router.define(loginScreen, handler: loginHandler);
    router.define(registerScreen, handler: registerHandler);
    router.define(phoneConfirm, handler: phoneConfirmHandler);
    router.define(userProfile, handler: userProfileHandler);
    router.define(newOffer, handler: newOfferHandler);
    router.define(newSearch, handler: newSearchHandler);
    router.define(rideApplied, handler: rideAppliedHandler);
    router.define(chatPage, handler: chatHandler);
    router.define(appliedRides, handler: appliedRidesHandler);
    router.define(myRides, handler: myRidesHandler);
    router.define(driverRequest, handler: driverRequestHandler);
    router.define(notifications, handler: notificationsPageHandler);
    router.define(changeNumber, handler: changePhoneNumberPageHandler);
    router.define(addFrequentSearch, handler: addFrequentSearchHandler);
    router.define(addFrequentOffer, handler: addFrequentOfferHandler);
    router.define(frequentOffers, handler: frequentOffersHandler);
    router.define(frequentSearches, handler: frequentSearchesHandler);
    router.define(about, handler: aboutScreenHandler);
  }
}
