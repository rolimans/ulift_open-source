import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:photo_view/photo_view.dart';
import 'package:ulift/config/routes.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/driverRequest/makeDriverRequest.dart';
import 'package:ulift/data_service/user/updatePicture.dart';
import 'package:ulift/util/image_picker_handler.dart';

final _cnhController = MaskedTextController(mask: "00000000000");
final _cnhDateController = TextEditingController();
final _cpfUser = MaskedTextController(mask: "000.000.000-00");
final _driverRequestForm = GlobalKey<FormState>();
final _cnhFocus = new FocusNode();
final _cpfFocus = new FocusNode();
DateTime _cnhDate = DateTime.now();
bool _autovalidate = false;

String urlFront;
String urlBack;
String urlSelfie;

class DriverRequestScreen extends StatefulWidget {
  DriverRequestScreen();

  @override
  _DriverRequestScreenState createState() => _DriverRequestScreenState();
}

class _DriverRequestScreenState extends State<DriverRequestScreen> {
  @override
  void dispose() {
    urlSelfie = urlBack = urlFront = null;
    _cnhDateController.text = _cnhController.text = _cpfUser.text = "";
    super.dispose();
  }

  void _submit() {
    if (UserService.user.picUrl != null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SecondRoute()));
    } else {
      Flushbar(
        message:
            "Você precisa ter uma foto de perfil para ser um motorista! Coloque uma na página de seu perfil!",
        duration: Duration(seconds: 3),
      ).show(context);
    }
  }

  @override
  void initState() {
    CurrentPage.page = Page.driver_request;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Solicitar para ser Motorista'),
        ),
        body: Builder(
          builder: (context) => ListView(children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Text(
                "Para ser motorista é necessário fazer um requerimento aos admnistradores do aplicativo, por questões de segurança e integridade dos usuários. Ao fim da solicitação, nossa equipe analisará seus documentos e responderá o mais rápido possível!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17.0,
                ),
              ),
            ),
            Container(
              padding: new EdgeInsets.all(25.0),
              child: new Form(
                autovalidate: _autovalidate,
                key: _driverRequestForm,
                child: new ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    new TextFormField(
                        keyboardType: TextInputType.number,
                        focusNode: _cpfFocus,
                        onFieldSubmitted: (val) {
                          _cpfFocus.unfocus();
                          FocusScope.of(context).requestFocus(_cnhFocus);
                        },
                        controller: _cpfUser,
                        validator: (value) {
                          if (value.isEmpty) {
                            return "Preencha seu CPF";
                          }
                          if (!RegExp(r"^\d{3}\.\d{3}\.\d{3}\-\d{2}$")
                                  .hasMatch(value) ||
                              !validateCPF(value)) {
                            return "Preencha um CPF válido";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Color(0xff254e70))),
                            labelText: "CPF",
                            labelStyle:
                                TextStyle(fontSize: 16, color: Colors.black))),
                    new Padding(
                      padding: new EdgeInsets.all(5.0),
                    ),
                    new TextFormField(
                        keyboardType: TextInputType.number,
                        controller: _cnhController,
                        focusNode: _cnhFocus,
                        onFieldSubmitted: (val) {
                          _cnhFocus.unfocus();
                          _selectDate(context);
                        },
                        validator: (value) {
                          if (value.isEmpty) {
                            return "Digite o Nº de registro";
                          }
                          if (!RegExp(r"^\d{11}$").hasMatch(value)) {
                            return "Digite um Nº de registro válido";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Color(0xff254e70))),
                            labelText: "Registro CNH",
                            labelStyle:
                                TextStyle(fontSize: 16, color: Colors.black))),
                    new Padding(
                      padding: new EdgeInsets.all(5.0),
                    ),
                    GestureDetector(
                      onTap: () {
                        _cpfFocus.unfocus();
                        _cnhFocus.unfocus();
                        _selectDate(context);
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: IgnorePointer(
                          child: new TextFormField(
                              controller: _cnhDateController,
                              validator: (value) {
                                if (value.isEmpty) {
                                  return "Informe a validade da CNH";
                                }
                                if (!_cnhDate.isAfter(DateTime.now())) {
                                  return "A CNH não pode estar vencida!";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Color(0xff254e70))),
                                  labelText: "Validade da CNH",
                                  labelStyle: TextStyle(
                                      fontSize: 16, color: Colors.black))),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 25),
                    ),
                    FloatingActionButton.extended(
                      onPressed: () {
                        if (_driverRequestForm.currentState.validate() &&
                            checkConn(context)) {
                          _submit();
                        } else {
                          setState(() {
                            _autovalidate = true;
                          });
                        }
                      },
                      label: Text('Continuar'),
                      icon: Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ));
  }

  Future<Null> _selectDate(BuildContext context) async {
    var firstDate = DateTime.now();
    var initDate = !_cnhDate.isBefore(firstDate) ? _cnhDate : firstDate;
    DatePicker.showDatePicker(context, showTitleActions: true,
        onConfirm: (date) {
      setState(() {
        _cnhDate = date;
        _changeDate();
      });
    }, currentTime: initDate, minTime: firstDate, locale: LocaleType.pt);
  }

  void _changeDate() {
    _cnhDateController.text =
        "${leadingZero(_cnhDate.day)}/${leadingZero(_cnhDate.month)}/${_cnhDate.year}";
  }
}

class SecondRoute extends StatefulWidget {
  @override
  _SecondRouteState createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute>
    with TickerProviderStateMixin, ImagePickerListener {
  ImagePickerHandler imagePicker;
  bool _loading = false;

  void initState() {
    super.initState();
    imagePicker = new ImagePickerHandler(this, this.context);
  }

  @override
  userImage(File _image, String type) {
    setState(() {
      _loading = true;
    });
    updatePicture(_image, type).then((val) {
      setState(() {
        _loading = false;
        urlFront = val;
      });
      if (val == null) {
        Flushbar(
          message: "Upload da imagem não realizado!",
          duration: Duration(seconds: 3),
        ).show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Solicitar pra ser motorista"),
        ),
        body: Builder(
          builder: (context) => ListView(children: <Widget>[
            Container(padding: const EdgeInsets.all(8)),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: Icon(
                Icons.account_circle,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Foto da Carteira Nacional de Habilitação',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                "Parte da frente:",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                ),
              ),
            ),
            Container(
              height: 288,
              width: 512,
              padding: new EdgeInsets.symmetric(horizontal: 30),
              child: Stack(
                children: <Widget>[
                  Container(
                    height: 288.0,
                    width: 512.0,
                    child: Center(
                      child: !_loading
                          ? ClipRect(
                              child: PhotoView(
                                loadingChild: Center(
                                    child: SpinKitDoubleBounce(
                                        color: Colors.tealAccent, size: 50)),
                                backgroundDecoration:
                                    BoxDecoration(color: Colors.grey[30]),
                                imageProvider: urlFront != null
                                    ? NetworkImage(urlFront)
                                    : AssetImage("images/frenteMock.jpg"),
                                maxScale:
                                    PhotoViewComputedScale.contained * 2.0,
                                minScale:
                                    PhotoViewComputedScale.contained * 0.8,
                                initialScale: PhotoViewComputedScale.contained,
                              ),
                            )
                          : SpinKitDoubleBounce(
                              color: Colors.tealAccent, size: 50),
                    ),
                  ),
                  Positioned(
                    bottom: 0.0,
                    right: 10.0,
                    child: FloatingActionButton(
                        heroTag: 2,
                        child: Icon(Icons.edit),
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
                                              imagePicker.openGallery(
                                                  512, 288, 'front');
                                              Navigator.of(context).pop();
                                            }),
                                        ListTile(
                                          leading: Icon(
                                            Icons.camera_alt,
                                          ),
                                          title: Text('Câmera'),
                                          onTap: () {
                                            imagePicker.openCamera(
                                                512, 288, 'front');
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.close,
                                          ),
                                          title: Text('Cancelar'),
                                          onTap: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    ),
                                  ));
                        }),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 25, horizontal: 30),
              child: FloatingActionButton.extended(
                backgroundColor:
                    urlFront != null ? Color(0xff254e70) : Colors.grey,
                onPressed: () {
                  if (urlFront != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ThirdRoute()),
                    );
                  } else {
                    Flushbar(
                      message: "Faça upload da frente da CNH para prosseguir!",
                      duration: Duration(seconds: 2),
                    ).show(context);
                  }
                },
                label: Text('Continuar'),
                icon: Icon(Icons.arrow_forward),
              ),
            )
          ]),
        ));
  }
}

class ThirdRoute extends StatefulWidget {
  @override
  _ThirdRouteState createState() => _ThirdRouteState();
}

class _ThirdRouteState extends State<ThirdRoute>
    with TickerProviderStateMixin, ImagePickerListener {
  ImagePickerHandler imagePicker;
  bool _loading = false;

  void initState() {
    super.initState();

    imagePicker = new ImagePickerHandler(this, this.context);
  }

  @override
  userImage(File _image, String type) {
    setState(() {
      _loading = true;
    });
    updatePicture(_image, type).then((val) {
      setState(() {
        _loading = false;
        urlBack = val;
      });
      if (val == null) {
        Flushbar(
          message: "Upload da imagem não realizado!",
          duration: Duration(seconds: 3),
        ).show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Solicitar pra ser motorista"),
        ),
        body: Builder(
          builder: (context) => ListView(children: <Widget>[
            Container(padding: const EdgeInsets.all(8)),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: Icon(
                Icons.account_circle,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Foto da Carteira Nacional de Habilitação',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                "Parte de trás:",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                ),
              ),
            ),
            Container(
              height: 288,
              width: 512,
              padding: new EdgeInsets.symmetric(horizontal: 30),
              child: Stack(
                children: <Widget>[
                  Container(
                    height: 288.0,
                    width: 512.0,
                    child: Center(
                      child: !_loading
                          ? ClipRect(
                              child: PhotoView(
                                loadingChild: Center(
                                    child: SpinKitDoubleBounce(
                                        color: Colors.tealAccent, size: 50)),
                                backgroundDecoration:
                                    BoxDecoration(color: Colors.grey[30]),
                                imageProvider: urlBack != null
                                    ? NetworkImage(urlBack)
                                    : AssetImage("images/backMock.jpg"),
                                maxScale:
                                    PhotoViewComputedScale.contained * 2.0,
                                minScale:
                                    PhotoViewComputedScale.contained * 0.8,
                                initialScale: PhotoViewComputedScale.contained,
                              ),
                            )
                          : SpinKitDoubleBounce(
                              color: Colors.tealAccent, size: 50),
                    ),
                  ),
                  Positioned(
                    bottom: 0.0,
                    right: 10.0,
                    child: FloatingActionButton(
                        heroTag: 2,
                        child: Icon(Icons.edit),
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
                                              imagePicker.openGallery(
                                                  512, 288, 'back');
                                              Navigator.of(context).pop();
                                            }),
                                        ListTile(
                                          leading: Icon(
                                            Icons.camera_alt,
                                          ),
                                          title: Text('Câmera'),
                                          onTap: () {
                                            imagePicker.openCamera(
                                                512, 288, 'back');
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.close,
                                          ),
                                          title: Text('Cancelar'),
                                          onTap: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    ),
                                  ));
                        }),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 25, horizontal: 30),
              child: FloatingActionButton.extended(
                backgroundColor:
                    urlBack != null ? Color(0xff254e70) : Colors.grey,
                onPressed: () {
                  if (urlBack != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FourthRoute()),
                    );
                  } else {
                    Flushbar(
                      message:
                          "Faça upload da parte de trás da CNH para prosseguir!",
                      duration: Duration(seconds: 2),
                    ).show(context);
                  }
                },
                label: Text('Continuar'),
                icon: Icon(Icons.arrow_forward),
              ),
            )
          ]),
        ));
  }
}

class FourthRoute extends StatefulWidget {
  @override
  _FourthRouteState createState() => _FourthRouteState();
}

class _FourthRouteState extends State<FourthRoute>
    with TickerProviderStateMixin, ImagePickerListener {
  ImagePickerHandler imagePicker;
  bool _loading = false;

  void initState() {
    super.initState();

    imagePicker = new ImagePickerHandler(this, this.context);
  }

  @override
  userImage(File _image, String type) {
    setState(() {
      _loading = true;
    });
    updatePicture(_image, type).then((val) {
      setState(() {
        _loading = false;
        urlSelfie = val;
      });
      if (val == null) {
        Flushbar(
          message: "Upload da imagem não realizado!",
          duration: Duration(seconds: 3),
        ).show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Solicitar pra ser motorista"),
        ),
        body: Builder(
          builder: (context) => ListView(children: <Widget>[
            Container(padding: const EdgeInsets.all(8)),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: Icon(
                Icons.account_circle,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Foto da Carteira Nacional de Habilitação',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                "Selfie segurando a CNH:",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                ),
              ),
            ),
            Container(
              height: 288,
              width: 512,
              padding: new EdgeInsets.symmetric(horizontal: 30),
              child: Stack(
                children: <Widget>[
                  Container(
                    height: 288.0,
                    width: 512.0,
                    child: Center(
                      child: !_loading
                          ? ClipRect(
                              child: PhotoView(
                                loadingChild: Center(
                                    child: SpinKitDoubleBounce(
                                        color: Colors.tealAccent, size: 50)),
                                backgroundDecoration:
                                    BoxDecoration(color: Colors.grey[30]),
                                imageProvider: urlSelfie != null
                                    ? NetworkImage(urlSelfie)
                                    : AssetImage("images/selfieMock.jpeg"),
                                maxScale:
                                    PhotoViewComputedScale.contained * 2.0,
                                minScale:
                                    PhotoViewComputedScale.contained * 0.8,
                                initialScale: PhotoViewComputedScale.contained,
                              ),
                            )
                          : SpinKitDoubleBounce(
                              color: Colors.tealAccent, size: 50),
                    ),
                  ),
                  Positioned(
                    bottom: 0.0,
                    right: 10.0,
                    child: FloatingActionButton(
                        heroTag: 2,
                        child: Icon(Icons.edit),
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
                                              imagePicker.openGallery(
                                                  512, 288, 'holding');
                                              Navigator.of(context).pop();
                                            }),
                                        ListTile(
                                          leading: Icon(
                                            Icons.camera_alt,
                                          ),
                                          title: Text('Câmera'),
                                          onTap: () {
                                            imagePicker.openCamera(
                                                512, 288, 'holding');
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.close,
                                          ),
                                          title: Text('Cancelar'),
                                          onTap: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    ),
                                  ));
                        }),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 25, horizontal: 30),
              child: FloatingActionButton.extended(
                backgroundColor:
                    urlSelfie != null ? Color(0xff254e70) : Colors.grey,
                onPressed: () {
                  if (urlSelfie != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FinalRequest()),
                    );
                  } else {
                    Flushbar(
                      message:
                          "Faça upload da selfie com a CNH para prosseguir!",
                      duration: Duration(seconds: 2),
                    ).show(context);
                  }
                },
                label: Text('Continuar'),
                icon: Icon(Icons.arrow_forward),
              ),
            )
          ]),
        ));
  }
}

class FinalRequest extends StatefulWidget {
  @override
  _FinalRequestState createState() => _FinalRequestState();
}

class _FinalRequestState extends State<FinalRequest> with AfterLayoutMixin {
  bool _uploading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_uploading) {
          CurrentPage.page = Page.home;
          Navigator.popUntil(context, ModalRoute.withName(Routes.homeScreen));
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Solicitação feita!"),
        ),
        body: Center(
          child: !_uploading
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      CurrentPage.page = Page.home;
                      Navigator.popUntil(
                          context, ModalRoute.withName(Routes.homeScreen));
                    },
                    label: Text('Retornar'),
                    icon: Icon(Icons.arrow_back),
                  ),
                )
              : SpinKitDoubleBounce(color: Colors.tealAccent, size: 30),
        ),
      ),
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {
    if (!checkConn(context)) {
      CurrentPage.page = Page.home;
      Navigator.popUntil(context, ModalRoute.withName(Routes.homeScreen));
      Flushbar(
        message: "Erro ao concluir requisição! Tente novamente!",
        duration: Duration(seconds: 2),
      ).show(context);
      return;
    }
    makeDriveRequest(_cnhController.text, _cpfUser.text, _cnhDate, urlFront,
            urlBack, urlSelfie)
        .then((did) {
      if (did) {
        setState(() {
          _uploading = false;
        });
      } else {
        Flushbar(
          message: "Erro ao concluir requisição! Tente novamente!",
          duration: Duration(seconds: 2),
        ).show(context);
      }
    });
  }
}

bool validateCPF(String cpf) {
  try {
    int soma = 0;
    int resto;
    cpf = cpf.replaceAll('.', '').replaceAll('-', '');

    if (cpf == '00000000000') return false;
    for (int i = 1; i <= 9; i++)
      soma = soma + int.parse(cpf.substring(i - 1, i)) * (11 - i);
    resto = (soma * 10) % 11;

    if ((resto == 10) || (resto == 11)) resto = 0;
    if (resto != int.parse(cpf.substring(9, 10))) return false;

    soma = 0;
    for (int i = 1; i <= 10; i++)
      soma = soma + int.parse(cpf.substring(i - 1, i)) * (12 - i);
    resto = (soma * 10) % 11;

    if ((resto == 10) || (resto == 11)) resto = 0;
    if (resto != int.parse(cpf.substring(10, 11))) return false;
    return true;
  } catch (e) {
    Crashlytics.instance.log(e.toString());
    return false;
  }
}
