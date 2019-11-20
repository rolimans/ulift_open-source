import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHandler {
  ImagePickerListener _listener;
  BuildContext context;

  ImagePickerHandler(this._listener, this.context);

  openCamera(int maxWidth, int maxHeight, String type) async {
    try {
      var image = await ImagePicker.pickImage(source: ImageSource.camera);
      cropImage(image, maxWidth, maxHeight, type);
    } catch (e) {
      if (e != null) {
        notifyError();
        Crashlytics.instance.log(e.toString());
      }
    }
  }

  openGallery(int maxWidth, int maxHeight, String type) async {
    try {
      var image = await ImagePicker.pickImage(source: ImageSource.gallery);
      cropImage(image, maxWidth, maxHeight, type);
    } catch (e) {
      if (e != null) {
        notifyError();
        Crashlytics.instance.log(e.toString());
      }
    }
  }

  Future cropImage(File image, int maxWidth, int maxHeight, String type) async {
    if (image != null) {
      var aspect = CropAspectRatio(ratioX: 16.0, ratioY: 9.0);
      if (type == "user") {
        aspect = CropAspectRatio(ratioX: 1, ratioY: 1);
      }
      File croppedFile = await ImageCropper.cropImage(
        sourcePath: image.path,
        aspectRatio: aspect,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      _listener.userImage(croppedFile, type);
    } else {
      notifyError();
    }
  }

  void notifyError() {
    Flushbar(
      message: "Nenhuma imagem selecionada!",
      duration: Duration(seconds: 3),
    ).show(context);
  }
}

abstract class ImagePickerListener {
  userImage(File _image, String type);
}
