import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/user/createUser.dart';

Future<String> updatePicture(File image, String type) async {
  if (type == 'user') {
    try {
      final fileName = "/user/" +
          FireUserService.user.uid +
          "/public/profilePic" +
          extension(image.path);
      final StorageReference storageRef =
          FirebaseStorage.instance.ref().child(fileName);

      final StorageUploadTask uploadTask = storageRef.putFile(image);

      final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);

      final String url = (await downloadUrl.ref.getDownloadURL());

      UserService.user.picUrl = url;

      changeUserPic(FireUserService.user, url);

      return url;
    } catch (e) {
      Crashlytics.instance.log(e.toString());
      return null;
    }
  } else if (type == 'front') {
    try {
      final fileName = "/user/" +
          FireUserService.user.uid +
          "/private/driverLicenseInfo/front" +
          extension(image.path);
      final StorageReference storageRef =
          FirebaseStorage.instance.ref().child(fileName);

      final StorageUploadTask uploadTask = storageRef.putFile(image);

      final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);

      final String url = (await downloadUrl.ref.getDownloadURL());

      return url;
    } catch (e) {
      Crashlytics.instance.log(e.toString());
      return null;
    }
  } else if (type == 'back') {
    try {
      final fileName = "/user/" +
          FireUserService.user.uid +
          "/private/driverLicenseInfo/back" +
          extension(image.path);
      final StorageReference storageRef =
          FirebaseStorage.instance.ref().child(fileName);

      final StorageUploadTask uploadTask = storageRef.putFile(image);

      final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);

      final String url = (await downloadUrl.ref.getDownloadURL());

      return url;
    } catch (e) {
      Crashlytics.instance.log(e.toString());
      return null;
    }
  } else if (type == 'holding') {
    try {
      final fileName = "/user/" +
          FireUserService.user.uid +
          "/private/driverLicenseInfo/holding" +
          extension(image.path);
      final StorageReference storageRef =
          FirebaseStorage.instance.ref().child(fileName);

      final StorageUploadTask uploadTask = storageRef.putFile(image);

      final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);

      final String url = (await downloadUrl.ref.getDownloadURL());

      return url;
    } catch (e) {
      Crashlytics.instance.log(e.toString());
      return null;
    }
  }

  return null;
}
