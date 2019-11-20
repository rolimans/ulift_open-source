import 'dart:convert' as JSON;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ulift/models/usuario.dart';
import 'package:ulift/util/util.dart';

final storage = FlutterSecureStorage();

Future<bool> createUser(user, Usuario u) async {
  try {
    await Firestore.instance.collection('users').document(user.uid).setData({
      "phone": u.number,
      "name": u.nome,
      "mat": u.mat,
      "sex": u.sex,
      "birth": u.birth.millisecondsSinceEpoch,
      "picUrl": u.picUrl,
      "tipo": u.tipo,
      'level': u.level,
      "numberOfDrived": 1,
      "numberOfRided": 1,
      "ratingDriver": 5,
      "ratingRider": 5,
    });

    storage.write(key: "user_uid", value: user.uid);
    storage.write(key: "user", value: JSON.jsonEncode(u));

    await Firestore.instance
        .collection("registeredNums")
        .document(user.phoneNumber)
        .setData({});
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}

Future<void> changeUserPic(user, String url) async {
  Firestore.instance
      .collection('users')
      .document(user.uid)
      .setData({
        "picUrl": url,
      }, merge: true)
      .then((result) {})
      .catchError((err) => Crashlytics.instance.log(err.toString()));
}

Future<void> changeUserPhone(user, String tel, String oldTel) async {
  try {
    List<Future> futures = List();

    futures
        .add(Firestore.instance.collection('users').document(user.uid).setData({
      "phone": tel,
    }, merge: true));

    futures.add(Firestore.instance
        .collection('registeredNums')
        .document(formattedPhone(oldTel))
        .delete());

    futures.add(Firestore.instance
        .collection('registeredNums')
        .document(formattedPhone(tel))
        .setData({}));

    await Future.wait(futures);
  } catch (e) {
    Crashlytics.instance.log(e.toString());
  }
}
