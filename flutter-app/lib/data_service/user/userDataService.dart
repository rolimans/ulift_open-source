import 'dart:async';
import 'dart:convert' as JSON;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/models/usuario.dart';

final storage = FlutterSecureStorage();

Future<Usuario> getUser(uid) async {
  DocumentSnapshot doc =
      await Firestore.instance.collection('users').document(uid).get();
  if (doc.exists) {
    var mat = doc.data['mat'];
    var phone = doc.data['phone'];
    var name = doc.data['name'];
    var birth = doc.data['birth'];
    var sex = doc.data['sex'];
    var picUrl = doc.data['picUrl'];
    var tipo = doc.data['tipo'];
    var playerIds = doc.data['playerIds'];
    var onGoingRequest = doc.data['onGoingRequest'];
    double ratingDriver = doc.data["ratingDriver"]?.toDouble();
    double ratingRider = doc.data["ratingRider"]?.toDouble();
    int numberOfDrived = doc.data["numberOfDrived"]?.toInt();
    int numberOfRided = doc.data["numberOfRided"]?.toInt();
    String level = doc.data['level'];

    if (name != null && phone != null && mat != null) {
      Usuario u = Usuario(
          level: level,
          number: phone,
          nome: name,
          mat: mat,
          sex: sex,
          birth: DateTime.fromMillisecondsSinceEpoch(birth),
          tipo: tipo,
          playerIds: playerIds,
          onGoingRequest: onGoingRequest,
          ratingRider: ratingRider,
          ratingDriver: ratingDriver,
          numberOfDrived: numberOfDrived,
          numberOfRided: numberOfRided);
      u.picUrl = picUrl;
      if (uid == FireUserService.user.uid) {
        storage.write(key: "user_uid", value: uid);
        storage.write(key: "user", value: JSON.jsonEncode(u));
      }
      u.uid = uid;
      return u;
    } else {
      return null;
    }
  } else {
    return null;
  }
}

Future<bool> removePlayerIdFromDb() async {
  try {
    var status = await OneSignal.shared.getPermissionSubscriptionState();
    String currentId = status.subscriptionStatus.userId;
    if (currentId != null) {
      var user = await Firestore.instance
          .collection('users')
          .document(FireUserService.user.uid)
          .get();

      Map playerIds = user.data["playerIds"];
      playerIds.remove(currentId);
      await Firestore.instance
          .collection('users')
          .document(FireUserService.user.uid)
          .updateData({"playerIds": playerIds});
    }
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}

Future<bool> savePlayerIdToDb(String playerId) async {
  try {
    if (playerId == null) {
      print("NULL PLAYER ID");
      return false;
    }
    await Firestore.instance
        .collection('users')
        .document(FireUserService.user.uid)
        .setData({
      'playerIds': {
        playerId: {
          "date": DateTime.now().millisecondsSinceEpoch + timeOffset,
          "uid": Unique.id
        }
      }
    }, merge: true);
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}
