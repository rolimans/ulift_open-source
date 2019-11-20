import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:ulift/config/application.dart';
import 'package:ulift/config/routes.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/user/updatePicture.dart';
import 'package:ulift/data_service/user/userDataService.dart';
import 'package:ulift/models/usuario.dart';
import 'package:ulift/util/image_picker_handler.dart';

class UserProfileScreen extends StatefulWidget {
  final String userUid;

  UserProfileScreen({this.userUid});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin, ImagePickerListener {
  ImagePickerHandler imagePicker;
  bool uploading = false;
  bool loadingUser;
  Usuario user;
  String userUid;

  @override
  void initState() {
    userUid = widget.userUid;
    CurrentPage.page = Page.user_profile;
    if (userUid == FireUserService.user.uid) {
      userUid = null;
    }
    super.initState();
    if (widget.userUid == null) {
      imagePicker = new ImagePickerHandler(this, this.context);
      setState(() {
        loadingUser = false;
        user = UserService.user;
      });
    } else {
      setState(() {
        loadingUser = true;
      });
      getUser(widget.userUid).then((u) {
        setState(() {
          user = u;
          loadingUser = false;
        });
      });
    }
  }

  @override
  userImage(File _image, String type) {
    setState(() {
      uploading = true;
      updatePicture(_image, type).then((val) {
        setState(() {
          uploading = false;
        });
        if (val == null) {
          Flushbar(
            message: "Upload da imagem não realizado!",
            duration: Duration(seconds: 3),
          ).show(context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Perfil'),
        ),
        body: !loadingUser
            ? Builder(
                builder: (context) => ListView(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(
                        top: 32.0,
                        bottom: 16.0,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Hero(
                              tag: 'profile-pic',
                              child: user.picUrl == null
                                  ? CircleAvatar(
                                      radius: 70.0,
                                      backgroundColor: Colors.white,
                                      child: uploading
                                          ? CircularProgressIndicator()
                                          : Text(
                                              user != null && user.nome != null
                                                  ? user.nome
                                                      .substring(0, 1)
                                                      .toUpperCase()
                                                  : "",
                                              style: TextStyle(fontSize: 70.0),
                                            ))
                                  : CircleAvatar(
                                      radius: 70.0,
                                      backgroundColor: Colors.white,
                                      child: uploading
                                          ? CircularProgressIndicator()
                                          : ClipOval(
                                              child: CachedNetworkImage(
                                                width: 140,
                                                height: 140,
                                                imageUrl: user.picUrl,
                                                placeholder: (context, url) =>
                                                    new CircularProgressIndicator(),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Text(
                                                  user != null &&
                                                          UserService
                                                                  .user.nome !=
                                                              null
                                                      ? user.nome
                                                          .substring(0, 1)
                                                          .toUpperCase()
                                                      : "",
                                                  style:
                                                      TextStyle(fontSize: 70.0),
                                                ),
                                              ),
                                            ))),
                          Visibility(
                              visible: widget.userUid == null,
                              child: Positioned(
                                bottom: 0.0,
                                right: 10.0,
                                child: FloatingActionButton(
                                    child: Icon(Icons.camera_alt),
                                    onPressed: () {
                                      if (!checkConn(context)) {
                                        return;
                                      }
                                      showModalBottomSheet(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(15.0)),
                                          ),
                                          context: context,
                                          builder: (context) => Container(
                                                child: Wrap(
                                                  children: <Widget>[
                                                    ListTile(
                                                        leading: Icon(
                                                          Icons.photo,
                                                        ),
                                                        title: Text('Galeria'),
                                                        onTap: () {
                                                          imagePicker
                                                              .openGallery(256,
                                                                  256, 'user');
                                                          Navigator.of(context)
                                                              .pop();
                                                        }),
                                                    ListTile(
                                                      leading: Icon(
                                                        Icons.camera_alt,
                                                      ),
                                                      title: Text('Câmera'),
                                                      onTap: () {
                                                        imagePicker.openCamera(
                                                            256, 256, 'user');
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading: Icon(
                                                        Icons.close,
                                                      ),
                                                      title: Text('Cancelar'),
                                                      onTap: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ));
                                    }),
                              ))
                        ],
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        Icons.account_circle,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Nome',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15.0,
                            ),
                          ),
                          Text(
                            user != null && user.nome != null ? user.nome : "",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    Visibility(
                        visible: widget.userUid == null,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          leading: Icon(
                            Icons.call,
                          ),
                          title: Text(
                            'Telefone',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15.0,
                            ),
                          ),
                          subtitle: Text(
                            user != null && user.number != null
                                ? user.number
                                : "",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                            ),
                          ),
                          trailing: widget.userUid == null
                              ? Icon(Icons.mode_edit)
                              : null,
                          onTap: () {
                            if (widget.userUid == null && checkConn(context)) {
                              Application.router
                                  .navigateTo(context, Routes.changeNumber)
                                  .then((_) {
                                CurrentPage.page = Page.user_profile;
                              });
                            }
                          },
                        )),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        Icons.star,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Avaliação em ${user.numberOfRided - 1} carona(s) como caroneiro avaliadas',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15.0,
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              Text(
                                  "${(user.ratingRider / user.numberOfRided).toStringAsFixed(1)}"),
                              SmoothStarRating(
                                  allowHalfRating: true,
                                  onRatingChanged: (_) {},
                                  starCount: 1,
                                  rating: 1,
                                  size: 25.0,
                                  color: Colors.yellow,
                                  borderColor: Colors.yellow,
                                  spacing: 0.0),
                            ],
                          )
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    Visibility(
                      visible: user.tipo == 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        leading: Icon(
                          FontAwesomeIcons.car,
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Avaliação em ${user.numberOfDrived - 1} carona(s) como motorista avaliadas',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15.0,
                              ),
                            ),
                            Row(
                              children: <Widget>[
                                Text(
                                    "${(user.ratingDriver / user.numberOfDrived).toStringAsFixed(1)}"),
                                SmoothStarRating(
                                    allowHalfRating: true,
                                    onRatingChanged: (_) {},
                                    starCount: 1,
                                    rating: 1,
                                    size: 25.0,
                                    color: Colors.yellow,
                                    borderColor: Colors.yellow,
                                    spacing: 0.0),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                      visible: user.tipo == 2,
                      child: Divider(
                        height: 0.0,
                        indent: 72.0,
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        Icons.school,
                      ),
                      title: Text(
                        'Matrícula',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15.0,
                        ),
                      ),
                      subtitle: Text(
                        user != null && user.mat != null
                            ? user.mat.toUpperCase()
                            : "",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        user != null && user.sex == 'F'
                            ? FontAwesomeIcons.female
                            : FontAwesomeIcons.male,
                      ),
                      title: Text(
                        'Sexo',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15.0,
                        ),
                      ),
                      subtitle: Text(
                        user != null && user.sex == "F"
                            ? "Feminino"
                            : "Masculino",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    Divider(
                      height: 0.0,
                      indent: 72.0,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      leading: Icon(
                        FontAwesomeIcons.calendar,
                      ),
                      title: Text(
                        'Data de Nascimento',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15.0,
                        ),
                      ),
                      subtitle: Text(
                        user != null && user.birth != null
                            ? leadingZero(user.birth.day.toString()) +
                                "/" +
                                leadingZero(user.birth.month.toString()) +
                                "/" +
                                user.birth.year.toString()
                            : "",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: SpinKitDoubleBounce(color: Colors.tealAccent, size: 30),
              ));
  }
}
