import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ulift/config/application.dart';
import 'package:ulift/config/routes.dart';
import 'package:ulift/config/shared_data.dart';

class FrequentOffers extends StatefulWidget {
  FrequentOffers();

  @override
  _FrequentOffersState createState() => _FrequentOffersState();
}

class _FrequentOffersState extends State<FrequentOffers> {
  List documents;

  @override
  void initState() {
    CurrentPage.page = Page.frequent_offers;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Ofertas Frequentes'),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            if (checkConn(context)) {
              Application.router
                  .navigateTo(context, Routes.addFrequentOffer)
                  .then((_) {
                CurrentPage.page = Page.frequent_offers;
              });
            }
          },
        ),
        body: StreamBuilder(
            stream: Firestore.instance
                .collection('frequentOffers')
                .where("author", isEqualTo: FireUserService.user.uid)
                .snapshots(),
            builder: ((context, snapshot) {
              if (!snapshot.hasData || snapshot.hasError) {
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
                              return frequentOfferCard(documents[index]);
                            },
                          ))
                        : Center(
                            child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.close,
                                  size: 40,
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                ),
                                Text(
                                  "Você não possui nenhuma oferta frequente!",
                                  style: TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
                                )
                              ],
                            ),
                          )));
              }
            })));
  }

  Widget frequentOfferCard(document) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
                leading: Icon(FontAwesomeIcons.car, size: 30),
                title: Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Text(
                      "Oferta de carona frequente para ${document.data['goToDesc']}"),
                ),
                subtitle: Text(
                    "\nHorário: ${hourAndMinute(DateTime.fromMillisecondsSinceEpoch(document.data["time"]))}"
                    "\n\nPartida: ${document.data["goFromDesc"]}"
                    "\n\nGêneros Aceitos: ${document.data["gender"]}"
                    "\n\nTipos Aceitos: ${document.data["type"]}"
                    "\n\nDias ofertados: ${weekDays(document.data["daysOfWeek"])}"
                    "\n\nVagas Ofertadas: ${document.data["limit"]}")),
            ButtonTheme.bar(
              child: ButtonBar(children: [
                FlatButton(
                  child: document.data["paused"]
                      ? Text("Voltar a ofertar")
                      : Text("Pausar Oferta"),
                  onPressed: () {
                    if (checkConn(context)) {
                      if (document.data["paused"]) {
                        document.reference.updateData({"paused": false});
                      } else {
                        document.reference.updateData({"paused": true});
                      }
                    }
                  },
                ),
                FlatButton(
                  child: Text("Remover Oferta"),
                  onPressed: () {
                    if (checkConn(context)) {
                      document.reference.delete();
                    }
                  },
                )
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String hourAndMinute(DateTime time) {
    DateTime clone = time.add(Duration(hours: 3));
    return "${leadingZero(clone.hour)}:${leadingZero(clone.minute)}";
  }

  String weekDays(List days) {
    String f = "";
    List<String> daysStr = [
      " | D | ",
      " | S | ",
      " | T | ",
      " | Q | ",
      " | Q | ",
      " | S | ",
      " | S | "
    ];

    int index = 0;
    for (bool day in days) {
      if (day) {
        f += daysStr[index];
      }
      index++;
    }
    return f;
  }
}
