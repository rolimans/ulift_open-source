import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ulift/config/application.dart';
import 'package:ulift/config/routes.dart';
import 'package:ulift/config/shared_data.dart';

class FrequentSearches extends StatefulWidget {
  FrequentSearches();

  @override
  _FrequentSearchesState createState() => _FrequentSearchesState();
}

class _FrequentSearchesState extends State<FrequentSearches> {
  List documents;

  @override
  void initState() {
    CurrentPage.page = Page.frequent_searches;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Buscas Frequentes'),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(FontAwesomeIcons.searchPlus),
          onPressed: () {
            if (checkConn(context)) {
              Application.router
                  .navigateTo(context, Routes.addFrequentSearch)
                  .then((_) {
                CurrentPage.page = Page.frequent_searches;
              });
            }
          },
        ),
        body: StreamBuilder(
            stream: Firestore.instance
                .collection('frequentSearches')
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
                              return frequentSearchCard(documents[index]);
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
                                  "Você não possui nenhuma busca frequente!",
                                  style: TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
                                )
                              ],
                            ),
                          )));
              }
            })));
  }

  Widget frequentSearchCard(document) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
                leading: Icon(Icons.search, size: 30),
                title: Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Text(
                      "Busca de carona frequente para ${document.data['goToDesc']}"),
                ),
                subtitle: Text("\nPartida: ${document.data["goFromDesc"]}"
                    "\n\nRaio: ${document.data["radius"]} m"
                    "\n\nDias buscados: ${weekDays(document.data["daysOfWeek"])}"
                    "${!document.data["standard"] ? "\n\nInfo: Criada a partir de uma busca recente." : ""}")),
            ButtonTheme.bar(
              child: ButtonBar(children: [
                FlatButton(
                  child: document.data["paused"]
                      ? Text("Voltar a buscar")
                      : Text("Pausar Busca"),
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
                  child: Text("Remover Busca"),
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
