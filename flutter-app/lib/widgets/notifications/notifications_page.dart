import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/models/notification.dart';

class NotificationsPage extends StatefulWidget {
  final NotificationData initNotification;
  final bool fromButton;
  final Page pageWhenOpened;

  NotificationsPage(
      {this.initNotification, this.fromButton, this.pageWhenOpened});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List documents = List();
  bool loading = false;

  @override
  void initState() {
    CurrentPage.page = Page.notifications_page;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initNotification != null && checkConn(context)) {
        if (widget.fromButton == true) {
          if (widget.initNotification.buttons.length > 0) {
            widget.initNotification.buttons.first.performAction(
                context, load, finishLoad, widget.pageWhenOpened);
          } else {
            Crashlytics.instance.log("CLICKED IN BUTTON THAT DOESNT EXISTS");
          }
        } else {
          widget.initNotification
              .performAction(context, load, finishLoad, widget.pageWhenOpened);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Notificações'),
        ),
        body: StreamBuilder(
            stream: Firestore.instance
                .collection('notifications')
                .where("toWho", isEqualTo: FireUserService.user.uid)
                .where('uniqueId', isEqualTo: Unique.id)
                .orderBy('creationDate', descending: true)
                .snapshots(),
            builder: ((context, snapshot) {
              if (!snapshot.hasData || snapshot.hasError || loading) {
                return Container(
                    child: Center(
                  child:
                      SpinKitDoubleBounce(color: Colors.tealAccent, size: 30),
                ));
              } else {
                documents = snapshot.data.documents;
                return Container(
                    child: snapshot.data.documents.isNotEmpty
                        ? Scrollbar(
                            child: ListView.builder(
                            scrollDirection: Axis.vertical,
                            itemCount: documents.length,
                            itemBuilder: (BuildContext context, int index) {
                              if (documents[index].data['obj'] != null) {
                                return notificationCard(
                                    NotificationData.fromJson(
                                        snapshot
                                            .data.documents[index].data['obj'],
                                        snapshot
                                            .data.documents[index].documentID),
                                    index);
                              } else {
                                return Container();
                              }
                            },
                          ))
                        : Center(
                            child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.notifications_off,
                                  size: 40,
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                ),
                                Text(
                                  "Nenhuma notifcação no momento!",
                                  style: TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
                                )
                              ],
                            ),
                          )));
              }
            })));
  }

  void load() {
    setState(() {
      loading = true;
    });
  }

  void finishLoad() {
    setState(() {
      loading = false;
    });
  }

  Widget notificationCard(NotificationData notification, int index) {
    bool visible = true;
    return Dismissible(
      key: Key(notification.id),
      onDismissed: (d) {
        if (notification.action != "rate_driver" &&
            notification.action != "rate_riders") {
          if (!checkConn(context)) {
            return;
          }
          setState(() {
            documents.removeAt(index);
            visible = false;
          });
          notification.delete().then((did) {
            if (did) {
              Flushbar(
                message: "Notificação removida!",
                duration: Duration(seconds: 2),
              ).show(context);
            } else {
              Flushbar(
                message: "Falha ao remover notificação!",
                duration: Duration(seconds: 3),
              ).show(context);
            }
          });
        }
      },
      child: visible
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: Stack(children: <Widget>[
                Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                          leading: notification.iconUrl == null
                              ? Icon(
                                  Icons.notifications,
                                  size: 30,
                                )
                              : CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                        imageUrl: notification.iconUrl,
                                        placeholder: (context, url) =>
                                            new CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.notifications,
                                                size: 30)),
                                  )),
                          title: Padding(
                            padding: const EdgeInsets.only(right: 18),
                            child: Text(notification.title),
                          ),
                          subtitle: Text(notification.text)),
                      ButtonTheme.bar(
                        child: ButtonBar(
                            children: notification.generateButtons(
                                context, load, finishLoad)),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: (notification.action != "rate_driver" &&
                      notification.action != "rate_riders"),
                  child: Positioned(
                    right: 5,
                    top: 2,
                    child: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        if (notification.action != "rate_driver" &&
                            notification.action != "rate_riders") {
                          if (!checkConn(context)) {
                            return;
                          }
                          setState(() {
                            documents.removeAt(index);
                            visible = false;
                          });
                          notification.delete().then((did) {
                            if (did) {
                              Flushbar(
                                message: "Notificação removida!",
                                duration: Duration(seconds: 2),
                              ).show(context);
                            } else {
                              Flushbar(
                                message: "Falha ao remover notificação!",
                                duration: Duration(seconds: 3),
                              ).show(context);
                            }
                          });
                        }
                      },
                    ),
                  ),
                )
              ]),
            )
          : Container(),
    );
  }
}
