import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:ulift/data_service/user/userDataService.dart';
import 'package:ulift/models/notification.dart';
import 'package:ulift/widgets/notifications/notifications_page.dart';

void initNotifications(var contextReceived) {
  OneSignal.shared.init("ONESIGNAL-API", iOSSettings: {
    OSiOSSettings.autoPrompt: true,
    OSiOSSettings.inAppLaunchUrl: false
  });

  //DONT SHOW WHEN APP IN FOREGROUND
  OneSignal.shared.setInFocusDisplayType(OSNotificationDisplayType.none);

  OneSignal.shared
      .setNotificationReceivedHandler((OSNotification notification) {
    if (!notification.shown) {
      _handleNotificationPayload(
          notification, CurrentPage.page, contextReceived);
    }
  });

  OneSignal.shared
      .setNotificationOpenedHandler((OSNotificationOpenedResult result) {
    _handleNotificationPayload(
        result.notification, CurrentPage.page, contextReceived,
        buttonId: result.action.actionId);
  });

  OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {
    // will be called whenever the permission changes
    // (ie. user taps Allow on the permission prompt in iOS)
  });

  _getPlayerIdNotification();
}

Future _getPlayerIdNotification() async {
  var status = await OneSignal.shared.getPermissionSubscriptionState();
  if (status.subscriptionStatus.subscribed) {
    String oneSignalUserId = status.subscriptionStatus.userId;
    if (oneSignalUserId != null) {
      savePlayerIdToDb(oneSignalUserId).then((did) {
        if (!did) {
          Crashlytics.instance.log("ERRO AO ATUALIZAR PLAYER ID");
        }
      });
    } else {
      OneSignal.shared
          .setSubscriptionObserver((OSSubscriptionStateChanges changes) {
        String oneSignalUserId = changes.to.userId;
        savePlayerIdToDb(oneSignalUserId).then((did) {
          if (!did) {
            Crashlytics.instance.log("ERRO AO ATUALIZAR PLAYER ID");
          }
        });
      });
    }
  } else {
    OneSignal.shared
        .setSubscriptionObserver((OSSubscriptionStateChanges changes) {
      String oneSignalUserId = changes.to.userId;
      savePlayerIdToDb(oneSignalUserId).then((did) {
        if (!did) {
          Crashlytics.instance.log("ERRO AO ATUALIZAR PLAYER ID");
        }
      });
    });
  }
}

void _handleNotificationPayload(
    OSNotification notification, Page currentPage, BuildContext context,
    {String buttonId}) {
  const WHEN_CLOSED = 1;
  const WHEN_IN_BG = 2;
  const WHEN_IN_FG = 3;

  int notificationState;

  if (notification.shown) {
    if (CurrentPage.page == Page.home) {
      notificationState = WHEN_CLOSED; // THIS WORKS BUT ITS NOT SO INTUITIVE
    } else {
      notificationState = WHEN_IN_BG;
    }
  } else {
    notificationState = WHEN_IN_FG;
  }

  NotificationData notData = NotificationData.fromNotification(notification);

  Page pageWhenOpened = CurrentPage.page;

  void performDefaultAction() {
    bool fromButton = false;
    if (buttonId != null) {
      fromButton = true;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NotificationsPage(
                initNotification: notData,
                fromButton: fromButton,
                pageWhenOpened: pageWhenOpened))).then((_) {
      CurrentPage.page = pageWhenOpened;
    });
  }

  void performDefaultActionWhenFG() {
    Flushbar(
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.white,
      messageText: Text(
        notData.text,
        style: TextStyle(color: Colors.black),
      ),
      titleText: Text(
        notData.title,
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      mainButton: notData.buttons.length != 0
          ? FlatButton(
              child: Text(notData.buttons.first.text),
              onPressed: () {
                buttonId = notData.buttons.first.act;
                Navigator.pop(context);
                performDefaultAction();
              },
            )
          : null,
      onTap: (bar) {
        Navigator.pop(context);
        performDefaultAction();
      },
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      barBlur: 10,
      margin: EdgeInsets.all(8),
      borderRadius: 8,
      flushbarStyle: FlushbarStyle.FLOATING,
      icon: notData.iconUrl != null
          ? Padding(
              padding: const EdgeInsets.all(1.0),
              child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: CachedNetworkImage(
                        width: 40,
                        height: 40,
                        imageUrl: notData.iconUrl,
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Container()),
                  )))
          : null,
      duration: Duration(seconds: 5),
    ).show(context);
  }

  if (notificationState == WHEN_CLOSED) {
    performDefaultAction();
  } else if (notificationState == WHEN_IN_BG) {
    switch (pageWhenOpened) {
      case Page.chat:
        if (notData.action != "chat") {
          performDefaultAction();
        } else {
          if (notData.additionalData['rideId'] !=
                  AdditionalPageData.currentChatId ||
              notData.additionalData['riderId'] !=
                  AdditionalPageData.currentUserChatId ||
              notData.additionalData['driverId'] !=
                  AdditionalPageData.currentDriverChatId) {
            performDefaultAction();
          } else {
            notData.delete();
          }
        }
        break;
      case Page.my_ride:
        if (notData.action != "my_ride") {
          performDefaultAction();
        } else {
          if (notData.additionalData['rideId'] !=
              AdditionalPageData.currentRideId) {
            performDefaultAction();
          }
        }
        break;
      case Page.ride_applied:
        if (notData.action != "ride_applied") {
          performDefaultAction();
        } else {
          if (notData.additionalData['rideId'] !=
              AdditionalPageData.currentRideId) {
            performDefaultAction();
          } else {
            remoteReloadInfoFromRideApplied(notData.additionalData['event']);
            notData.delete();
          }
        }
        break;
      case Page.notifications_page:
        break;
      default:
        performDefaultAction();
        break;
    }
  } else {
    switch (pageWhenOpened) {
      case Page.chat:
        if (notData.action != "chat") {
          performDefaultActionWhenFG();
        } else {
          if (notData.additionalData['rideId'] !=
                  AdditionalPageData.currentChatId ||
              notData.additionalData['riderId'] !=
                  AdditionalPageData.currentUserChatId ||
              notData.additionalData['driverId'] !=
                  AdditionalPageData.currentDriverChatId) {
            performDefaultActionWhenFG();
          } else {
            notData.delete();
          }
        }
        break;
      case Page.my_ride:
        if (notData.action != "my_ride") {
          performDefaultActionWhenFG();
        } else {
          if (notData.additionalData['rideId'] !=
              AdditionalPageData.currentRideId) {
            performDefaultActionWhenFG();
          }
        }
        break;
      case Page.ride_applied:
        if (notData.action != "ride_applied") {
          performDefaultActionWhenFG();
        } else {
          if (notData.additionalData['rideId'] !=
              AdditionalPageData.currentRideId) {
            performDefaultActionWhenFG();
          } else {
            remoteReloadInfoFromRideApplied(notData.additionalData['event']);
            notData.delete();
          }
        }
        break;
      case Page.notifications_page:
        break;
      default:
        performDefaultActionWhenFG();
        break;
    }
  }
}
