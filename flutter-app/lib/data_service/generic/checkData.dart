import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<bool> checkIfMatIsValid(mat) async {
  bool exists = false;
  await Firestore.instance
      .collection('validMat')
      .document(mat)
      .get()
      .then((value) {
    if (value.exists) {
      exists = true;
    }
  }).catchError((err) {
    Crashlytics.instance.log(err.toString());
  });

  return exists;
}

Future<bool> checkIfNumExists(num) async {
  bool exists = false;
  await Firestore.instance
      .collection('registeredNums')
      .document(num)
      .get()
      .then((value) {
    if (value.exists) {
      exists = true;
    }
  }).catchError((err) {
    Crashlytics.instance.log(err.toString());
  });

  return exists;
}
