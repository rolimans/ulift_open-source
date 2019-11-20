import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/rides/getRide.dart';
import 'package:ulift/util/dialogo.dart';
import 'package:ulift/widgets/new/new_search.dart';
import 'package:ulift/widgets/ride/chat.dart';
import 'package:ulift/widgets/ride/my_applied_ride.dart';
import 'package:ulift/widgets/ride/my_ride.dart';

import 'carona.dart';

class NotificationData {
  String id;
  String text;
  String title;
  List<Button> buttons = List();
  String action;
  Map additionalData;
  String iconUrl;

  NotificationData.fromJson(Map json, String id) {
    this.id = id;
    this.text = json['body'];
    this.title = json['title'];
    this.iconUrl = json['large_icon'];
    this.action = json['data'] != null ? json['data']['action'] : null;
    this.additionalData = json['data'];
    if (json['buttons'] != null && json['buttons'].length > 0) {
      for (var button in json["buttons"]) {
        this.buttons.add(Button.fromJson(button, this));
      }
    }
  }

  NotificationData.fromNotification(OSNotification notification) {
    this.text = notification.payload.body;
    this.title = notification.payload.title;
    this.iconUrl = notification.payload.largeIcon;
    this.additionalData = notification.payload.additionalData;
    this.id = this.additionalData == null
        ? null
        : this.additionalData['notificationId'];
    this.action =
        this.additionalData == null ? null : this.additionalData['action'];
    if (notification.payload.buttons != null &&
        notification.payload.buttons.length > 0) {
      for (var button in notification.payload.buttons) {
        this.buttons.add(Button.fromButtonNotification(button, this));
      }
    }
  }

  Future<bool> delete() async {
    try {
      if (this.id == null) {
        return false;
      }
      await Firestore.instance
          .collection('notifications')
          .document(this.id)
          .delete();
      return true;
    } catch (e) {
      Crashlytics.instance.log(e.toString());
      return false;
    }
  }

  Future performAction(BuildContext context, Function load, Function finishLoad,
      Page pageWhenOpened) async {
    switch (this.action) {
      case "rate_driver":
        rateDriverDialog(
            context,
            this.additionalData["rideId"],
            this.additionalData["driverId"],
            this.additionalData["driverName"],
            this.additionalData["data"],
            this.additionalData["picUrl"]);
        break;
      case "rate_riders":
        rateRidersDialog(context, this.additionalData["rideId"],
            this.additionalData['date'], this.additionalData['riders']);
        break;
      case "frequent_search":
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(
                builder: (context) => NewSearch(
                      radiusStart: this
                          .additionalData['search_data']['radius']
                          ?.toDouble(),
                      arrLatStart: this
                          .additionalData['search_data']['arr'][0]
                          ?.toDouble(),
                      arrLonStart: this
                          .additionalData['search_data']['arr'][1]
                          ?.toDouble(),
                      depLatStart: this
                          .additionalData['search_data']['dep'][0]
                          ?.toDouble(),
                      depLonStart: this
                          .additionalData['search_data']['dep'][1]
                          ?.toDouble(),
                      arrTxt: this.additionalData['search_data']['arrDesc'],
                      departureTxt: this.additionalData['search_data']
                          ['depDesc'],
                    )))
            .then((_) {
          CurrentPage.page = pageWhenOpened;
        });
        break;
      case "init_ride":
        load();
        if (this.additionalData['isDriver'] == true) {
          Carona ride = await getRideById(this.additionalData['rideId']);
          if (ride == null) {
            Flushbar(
              message: "A carona associada a notificação foi deletada!",
              duration: Duration(seconds: 2),
            ).show(context);
          } else {
            if (pageWhenOpened != Page.notifications_page) {
              Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(
                      builder: (context) => MyRide(
                            rideReceived: ride,
                            fromNotification: true,
                          )))
                  .then((_) {
                CurrentPage.page = pageWhenOpened;
              });
            } else {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (context) => MyRide(
                            rideReceived: ride,
                            fromNotification: true,
                          )))
                  .then((_) {
                CurrentPage.page = pageWhenOpened;
              });
            }
          }
        } else {
          Carona ride = await getRideById(this.additionalData['rideId']);
          if (ride == null) {
            Flushbar(
              message: "A carona associada a notificação foi deletada!",
              duration: Duration(seconds: 2),
            ).show(context);
          } else {
            if (pageWhenOpened != Page.notifications_page) {
              Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(
                      builder: (context) => MyAppliedRide(
                            ride: ride,
                            accepted: true,
                          )))
                  .then((_) {
                CurrentPage.page = pageWhenOpened;
              });
            } else {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (context) => MyAppliedRide(
                            ride: ride,
                            accepted: true,
                          )))
                  .then((_) {
                CurrentPage.page = pageWhenOpened;
              });
            }
          }
        }
        finishLoad();
        break;
      case "driver_request":
        if (this.additionalData['accepted'] == true) {
          Flushbar(
            message:
                "Parabéns agora você é um motorista! Reinicie o app para ver mudanças!",
            duration: Duration(seconds: 2),
          ).show(context);
        } else {
          Flushbar(
            message: "Infelizmente seu pedido foi deferido!",
            duration: Duration(seconds: 2),
          ).show(context);
        }
        break;
      case "chat":
        Map rideChat = {
          'motoristaId': this.additionalData['driverId'],
          'userId': this.additionalData['riderId'],
          'rideId': this.additionalData['rideId']
        };
        if (pageWhenOpened != Page.notifications_page) {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(
                  builder: (context) => ChatPage(
                        ride: rideChat,
                      )))
              .then((_) {
            CurrentPage.page = pageWhenOpened;
          });
        } else {
          Navigator.of(context)
              .push(MaterialPageRoute(
                  builder: (context) => ChatPage(
                        ride: rideChat,
                      )))
              .then((_) {
            CurrentPage.page = pageWhenOpened;
          });
        }
        break;
      case "ride_applied":
        if (this.additionalData['event'] == 'accepted') {
          load();
          Carona ride = await getRideById(this.additionalData['rideId']);
          if (ride == null) {
            Flushbar(
              message: "A carona associada a notificação foi deletada!",
              duration: Duration(seconds: 2),
            ).show(context);
          } else {
            if (pageWhenOpened != Page.notifications_page) {
              Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(
                      builder: (context) => MyAppliedRide(
                            ride: ride,
                            accepted: true,
                          )))
                  .then((_) {
                CurrentPage.page = pageWhenOpened;
              });
            } else {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (context) => MyAppliedRide(
                            ride: ride,
                            accepted: true,
                          )))
                  .then((_) {
                CurrentPage.page = pageWhenOpened;
              });
            }
          }
          finishLoad();
        } else if (this.additionalData['event'] == 'removed') {
          Flushbar(
            message:
                "Infelizmente você foi removido da carona! Tente procurar outra carona!",
            duration: Duration(seconds: 2),
          ).show(context);
        } else {
          Flushbar(
            message:
                "Infelizmente a carona foi deletada! Tente procurar outra carona!",
            duration: Duration(seconds: 2),
          ).show(context);
        }
        break;
      case "my_ride":
        load();
        Carona ride = await getRideById(this.additionalData['rideId']);
        if (ride == null) {
          Flushbar(
            message: "A carona associada a notificação foi deletada!",
            duration: Duration(seconds: 2),
          ).show(context);
        } else {
          if (pageWhenOpened != Page.notifications_page) {
            Navigator.of(context)
                .pushReplacement(MaterialPageRoute(
                    builder: (context) => MyRide(
                          rideReceived: ride,
                          fromNotification: true,
                        )))
                .then((_) {
              CurrentPage.page = pageWhenOpened;
            });
          } else {
            Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (context) => MyRide(
                          rideReceived: ride,
                          fromNotification: true,
                        )))
                .then((_) {
              CurrentPage.page = pageWhenOpened;
            });
          }
        }
        finishLoad();
        break;
      default:
        Flushbar(
          message: "Erro ao realizar ação da notificação",
          duration: Duration(seconds: 2),
        ).show(context);
    }
    this.delete();
  }

  List<Widget> generateButtons(
      BuildContext context, Function load, Function finishLoad) {
    List<Widget> flatButtons = List();
    flatButtons.add(FlatButton(
      child: const Text('ABRIR'),
      onPressed: () {
        if (!checkConn(context)) {
          return;
        }
        this.performAction(context, load, finishLoad, Page.notifications_page);
      },
    ));

    for (Button b in this.buttons) {
      flatButtons.add(b.generateFlatButton(context, load, finishLoad));
    }

    return flatButtons;
  }
}

class Button {
  String text;
  String act;
  NotificationData parent;

  Button.fromJson(Map json, NotificationData parent) {
    this.parent = parent;
    this.text = json['text'];
    this.act = json['id'];
  }

  Button.fromButtonNotification(
      OSActionButton button, NotificationData parent) {
    this.parent = parent;
    this.text = button.text;
    this.act = button.id;
  }

  Widget generateFlatButton(
      BuildContext context, Function load, Function finishLoad) {
    return FlatButton(
      child: Text(this.text),
      onPressed: () {
        if (!checkConn(context)) {
          return;
        }
        this.performAction(context, load, finishLoad, Page.notifications_page);
      },
    );
  }

  Future performAction(BuildContext context, Function load, Function finishLoad,
      Page pageWhenOpened) async {
    switch (this.act) {
      case "answer":
        Map rideChat = {
          'motoristaId': this.parent.additionalData['driverId'],
          'userId': this.parent.additionalData['riderId'],
          'rideId': this.parent.additionalData['rideId']
        };
        if (pageWhenOpened != Page.notifications_page) {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(
                  builder: (context) => ChatPage(
                        ride: rideChat,
                      )))
              .then((_) {
            CurrentPage.page = pageWhenOpened;
          });
        } else {
          Navigator.of(context)
              .push(MaterialPageRoute(
                  builder: (context) => ChatPage(
                        ride: rideChat,
                      )))
              .then((_) {
            CurrentPage.page = pageWhenOpened;
          });
        }
        break;
      case "chat":
        load();
        Carona ride = await getRideById(this.parent.additionalData['rideId']);
        if (ride == null) {
          Flushbar(
            message: "A carona associada a notificação foi deletada!",
            duration: Duration(seconds: 2),
          ).show(context);
        } else {
          Map rideChat = {
            'motoristaId': ride.motorista,
            'userId': FireUserService.user.uid,
            'rideId': ride.uid
          };
          if (pageWhenOpened != Page.notifications_page) {
            Navigator.of(context)
                .pushReplacement(MaterialPageRoute(
                    builder: (context) => ChatPage(
                          ride: rideChat,
                        )))
                .then((_) {
              CurrentPage.page = pageWhenOpened;
            });
          } else {
            Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (context) => ChatPage(
                          ride: rideChat,
                        )))
                .then((_) {
              CurrentPage.page = pageWhenOpened;
            });
          }
        }
        finishLoad();
        break;
      default:
        Flushbar(
          message: "Erro ao realizar ação da notificação",
          duration: Duration(seconds: 2),
        ).show(context);
    }
    parent.delete();
  }
}
