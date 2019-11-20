import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:ulift/config/shared_data.dart';

Future<bool> makeDriveRequest(String cnh, String cpf, DateTime cnhDate,
    String frontUrl, String backUrl, String selfieUrl) async {
  try {
    await Firestore.instance
        .collection('users')
        .document(FireUserService.user.uid)
        .collection('license')
        .document('myLicense')
        .setData({
      "cnhNumber": cnh,
      "cnhValidate": Timestamp.fromDate(cnhDate),
      "cpfUser": cpf,
      "backUrl": backUrl,
      "frontUrl": frontUrl,
      "selfieUrl": selfieUrl
    });

    await Firestore.instance
        .collection('users')
        .document(FireUserService.user.uid)
        .setData({'onGoingRequest': true}, merge: true);

    UserService.user.onGoingRequest = true;
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}
