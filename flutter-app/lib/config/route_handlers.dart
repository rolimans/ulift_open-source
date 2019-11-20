import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:ulift/widgets/about/about.dart';
import 'package:ulift/widgets/auth/change_phone_number.dart';
import 'package:ulift/widgets/auth/login.dart';
import 'package:ulift/widgets/auth/phone_confirm.dart';
import 'package:ulift/widgets/auth/register.dart';
import 'package:ulift/widgets/driverRequest/driver_request.dart';
import 'package:ulift/widgets/frequents/add_frequent_ride_offer.dart';
import 'package:ulift/widgets/frequents/add_frequent_ride_search.dart';
import 'package:ulift/widgets/frequents/frequent_offers.dart';
import 'package:ulift/widgets/frequents/frequent_searches.dart';
import 'package:ulift/widgets/home.dart';
import 'package:ulift/widgets/new/new_offer.dart';
import 'package:ulift/widgets/new/new_search.dart';
import 'package:ulift/widgets/notifications/notifications_page.dart';
import 'package:ulift/widgets/ride/chat.dart';
import 'package:ulift/widgets/ride/my_applied_ride.dart';
import 'package:ulift/widgets/ride/my_applied_rides.dart';
import 'package:ulift/widgets/ride/my_rides.dart';
import 'package:ulift/widgets/splash.dart';
import 'package:ulift/widgets/users/user_profile.dart';

Handler rootHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return SplashScreen();
});

Handler homeHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return HomeScreen();
});

Handler loginHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return LoginScreen();
});

Handler registerHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  String num = params['num']?.first;
  return RegisterScreen(
    num: num,
  );
});

Handler phoneConfirmHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return PhoneConfirmScreen();
});

Handler userProfileHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  String userUid = params['id']?.first;
  if (userUid == ":id") userUid = null;
  return UserProfileScreen(
    userUid: userUid,
  );
});

Handler driverRequestHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return DriverRequestScreen();
});

Handler newOfferHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return NewOffer();
});

Handler newSearchHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return NewSearch();
});

Handler rideAppliedHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return MyAppliedRide();
});

Handler chatHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return ChatPage(
    ride: {},
  );
});

Handler appliedRidesHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return AppliedRides();
});

Handler myRidesHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return MyRides();
});

Handler notificationsPageHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return NotificationsPage();
});

Handler changePhoneNumberPageHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return ChangePhoneNumberScreen();
});

Handler addFrequentSearchHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return AddFrequentRideSearch();
});

Handler addFrequentOfferHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return AddFrequentRideOffer();
});

Handler frequentOffersHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return FrequentOffers();
});

Handler frequentSearchesHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return FrequentSearches();
});

Handler aboutScreenHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return AboutScreen();
});
