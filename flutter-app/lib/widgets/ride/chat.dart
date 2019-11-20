import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ulift/config/shared_data.dart';

class ChatPage extends StatefulWidget {
  final Map ride;

  ChatPage({@required this.ride});

  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  void dispose() {
    messageController.text = '';
    super.dispose();
  }

  @override
  void initState() {
    CurrentPage.page = Page.chat;
    initializeIds();
    AdditionalPageData.currentChatId = rideId;
    AdditionalPageData.currentDriverChatId = motoristaId;
    AdditionalPageData.currentUserChatId = userId;
    getOtherUserName();
    super.initState();
  }

  Map ride;
  String motoristaId;
  String userId;
  String otherUserName;
  String rideId;
  final Firestore _firestore = Firestore.instance;
  final ScrollController listScrollController = new ScrollController();

  initializeIds() {
    ride = widget.ride;
    motoristaId = ride['motoristaId'];
    userId = ride['userId'];
    rideId = ride['rideId'];
  }

  TextEditingController messageController = TextEditingController();
  ScrollController scrollController = ScrollController();

  Future<void> callback() async {
    if (messageController.text.length > 0 && checkConn(context)) {
      if (FireUserService.user.uid == motoristaId) {
        _firestore
            .collection('rides')
            .document(rideId)
            .collection('riders')
            .document(userId)
            .collection('chat')
            .document()
            .setData({
          'text': messageController.text,
          'from': motoristaId,
          'to': userId,
          'date': FieldValue.serverTimestamp(),
          'sentByMotorista': false,
          'rideId': rideId
        }).catchError((_) {
          Crashlytics.instance.log(_.toString());
          Navigator.pop(context);
          Flushbar(
            message: "Erro ao enviar mensagem!",
            duration: Duration(seconds: 2),
          ).show(context);
        });
        messageController.clear();
        listScrollController.animateTo(0,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      } else {
        _firestore
            .collection('rides')
            .document(rideId)
            .collection('riders')
            .document(userId)
            .collection('chat')
            .document()
            .setData({
          'text': messageController.text,
          'from': userId,
          'to': motoristaId,
          'date': FieldValue.serverTimestamp(),
          'sentByMotorista': false,
          'rideId': rideId
        }).catchError((_) {
          Crashlytics.instance.log(_.toString());
          Navigator.pop(context);
          Flushbar(
            message: "Erro ao enviar mensagem!",
            duration: Duration(seconds: 2),
          ).show(context);
        });
        messageController.clear();
        listScrollController.animateTo(0,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  getOtherUserName() {
    if (FireUserService.user.uid == motoristaId) {
      _firestore.collection('users').document(userId).get().then((snapshot) {
        setState(() {
          otherUserName = snapshot.data['name'];
        });
      });
    } else {
      _firestore
          .collection('users')
          .document(motoristaId)
          .get()
          .then((snapshot) {
        setState(() {
          otherUserName = snapshot.data['name'];
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            );
          },
        ),
        title: Text(
          otherUserName != null ? otherUserName : "Carregando...",
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                child: StreamBuilder(
                    stream: Firestore.instance
                        .collection('rides')
                        .document(rideId)
                        .collection('riders')
                        .document(userId)
                        .collection('chat')
                        .orderBy('date', descending: true)
                        .limit(20)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: SpinKitDoubleBounce(
                              color: Colors.tealAccent, size: 30),
                        );
                      } else {
                        return ListView.builder(
                          reverse: true,
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: snapshot.data.documents.length,
                          itemBuilder: (context, index) => Message(
                            when: snapshot.data.documents[index]['date'],
                            text: snapshot.data.documents[index]['text'],
                            me: FireUserService.user.uid ==
                                snapshot.data.documents[index]['from'],
                          ),
                          controller: listScrollController,
                        );
                      }
                    }),
              ),
              Container(
                color: Colors.grey.shade200,
                width: double.infinity,
                height: 50,
                padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        onSubmitted: (value) => callback(),
                        controller: messageController,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Escreva sua Mensagem...',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: callback,
                      icon: Icon(Icons.send),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Message extends StatelessWidget {
  final String text;
  final Timestamp when;
  final bool me;

  const Message({Key key, this.when, this.text, this.me}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(5, 10, 10, 5),
      child: Column(
        crossAxisAlignment:
            me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: me ? Colors.lightBlueAccent[100] : Colors.black12,
              ),
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              child: Text(
                text,
              )),
          Container(
            height: 5,
          ),
          Text(
            _getDateInString(when),
            style: TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  String _getDateInString(Timestamp when) {
    if (when == null) {
      return "...";
    }
    String weekDay;
    String hour;
    switch (when.toDate().weekday) {
      case 1:
        weekDay = "Seg";
        break;
      case 2:
        weekDay = "Ter";
        break;
      case 3:
        weekDay = "Qua";
        break;
      case 4:
        weekDay = "Qui";
        break;
      case 5:
        weekDay = "Sex";
        break;
      case 6:
        weekDay = "Sab";
        break;
      case 7:
        weekDay = "Dom";
        break;
    }
    hour = when.toDate().toLocal().toString().substring(11, 16);

    return weekDay + " - " + hour;
  }
}
