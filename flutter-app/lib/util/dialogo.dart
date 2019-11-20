import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:ulift/data_service/rides/rateRide.dart';

Future<void> dialogo(context, String t, String s,
    {String confirm, String cancel, okFun, cancelFun}) async {
  List<Widget> actions = [];
  if (confirm != null && okFun != null) {
    actions.add(FlatButton(
      child: Text(confirm),
      onPressed: () {
        okFun();
      },
    ));
  }
  if (cancel != null && cancelFun != null) {
    actions.add(FlatButton(
      child: Text(cancel),
      onPressed: () {
        cancelFun();
      },
    ));
  }
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(t),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(s),
            ],
          ),
        ),
        actions: actions,
      );
    },
  );
}

Future<void> rateDriverDialog(
    context, rideId, driverId, driverName, data, picUrl) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return CustomRatingDriverDialog(
          rideId: rideId,
          driverId: driverId,
          driverName: driverName,
          data: data,
          picUrl: picUrl);
    },
  );
}

Future<void> rateRidersDialog(context, rideId, date, riders) async {
  for (Map rider in riders) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomRatingRiderDialog(
          rideId: rideId,
          riderId: rider['riderId'],
          riderName: rider['riderName'],
          data: date,
          picUrl: rider['picUrl'],
        );
      },
    );
  }
}

class CustomRatingDriverDialog extends StatefulWidget {
  final String driverName;
  final String driverId;
  final String data;
  final String rideId;
  final String picUrl;

  CustomRatingDriverDialog(
      {this.picUrl, this.driverName, this.driverId, this.data, this.rideId});

  @override
  _CustomRatingDriverDialogState createState() =>
      new _CustomRatingDriverDialogState();
}

class _CustomRatingDriverDialogState extends State<CustomRatingDriverDialog> {
  TextEditingController feedbackController = TextEditingController();
  double rating = 5;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: AlertDialog(
        title: Text("Avalie a corrida do dia ${widget.data}"),
        content: loading
            ? Center(
                child: SpinKitDoubleBounce(color: Colors.tealAccent, size: 30))
            : SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(
                        "Avalie a carona de ${widget.driverName}, e se julgar necessário deixe um feedback anônimo para nossa equipe sobre o motorista!"),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Hero(
                            tag: 'profile-pic',
                            child: widget.picUrl == null
                                ? CircleAvatar(
                                    radius: 40.0,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      widget.driverName != null
                                          ? widget.driverName
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : "",
                                      style: TextStyle(fontSize: 70.0),
                                    ))
                                : CircleAvatar(
                                    radius: 40.0,
                                    backgroundColor: Colors.white,
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        width: 140,
                                        height: 140,
                                        imageUrl: widget.picUrl,
                                        placeholder: (context, url) =>
                                            new CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            Text(
                                          widget.driverName != null
                                              ? widget.driverName
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                              : "",
                                          style: TextStyle(fontSize: 70.0),
                                        ),
                                      ),
                                    ))),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Avaliação:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Center(
                      child: SmoothStarRating(
                          allowHalfRating: true,
                          onRatingChanged: (rated) {
                            setState(() {
                              rating = rated;
                            });
                          },
                          starCount: 5,
                          rating: rating,
                          size: 40.0,
                          color: Colors.yellow,
                          borderColor: Colors.yellow,
                          spacing: 0.0),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Feedback:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    TextField(
                      controller: feedbackController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                          hintText:
                              "Algo de ruim ocorreu na carona?\nDeixe aqui seu feedback"),
                    )
                  ],
                ),
              ),
        actions: loading
            ? null
            : <Widget>[
                FlatButton(
                  child: Text("Avaliar"),
                  onPressed: () async {
                    setState(() {
                      loading = true;
                    });
                    await rateDriver(widget.driverId, widget.rideId, rating,
                        feedbackController.text);
                    Navigator.pop(context);
                  },
                ),
              ],
      ),
    );
  }
}

class CustomRatingRiderDialog extends StatefulWidget {
  final String riderName;
  final String riderId;
  final String data;
  final String rideId;
  final String picUrl;

  CustomRatingRiderDialog(
      {this.picUrl, this.riderName, this.riderId, this.data, this.rideId});

  @override
  _CustomRatingRiderDialogState createState() =>
      new _CustomRatingRiderDialogState();
}

class _CustomRatingRiderDialogState extends State<CustomRatingRiderDialog> {
  TextEditingController feedbackController = TextEditingController();
  double rating = 5;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: AlertDialog(
        title: Text("Avalie o caroneiro da corrida do dia ${widget.data}"),
        content: loading
            ? Center(
                child: SpinKitDoubleBounce(color: Colors.tealAccent, size: 30))
            : SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(
                        "Avalie o caroneiro ${widget.riderName}, e se julgar necessário deixe um feedback anônimo para nossa equipe sobre ele!"),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Hero(
                            tag: 'profile-pic',
                            child: widget.picUrl == null
                                ? CircleAvatar(
                                    radius: 40.0,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      widget.riderName != null
                                          ? widget.riderName
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : "",
                                      style: TextStyle(fontSize: 70.0),
                                    ))
                                : CircleAvatar(
                                    radius: 40.0,
                                    backgroundColor: Colors.white,
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        width: 140,
                                        height: 140,
                                        imageUrl: widget.picUrl,
                                        placeholder: (context, url) =>
                                            new CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            Text(
                                          widget.riderName != null
                                              ? widget.riderName
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                              : "",
                                          style: TextStyle(fontSize: 70.0),
                                        ),
                                      ),
                                    ))),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Avaliação:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Center(
                      child: SmoothStarRating(
                          allowHalfRating: true,
                          onRatingChanged: (rated) {
                            setState(() {
                              rating = rated;
                            });
                          },
                          starCount: 5,
                          rating: rating,
                          size: 40.0,
                          color: Colors.yellow,
                          borderColor: Colors.yellow,
                          spacing: 0.0),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Feedback:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    TextField(
                      controller: feedbackController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                          hintText:
                              "Algo de ruim ocorreu na carona?\nDeixe aqui seu feedback"),
                    )
                  ],
                ),
              ),
        actions: loading
            ? null
            : <Widget>[
                FlatButton(
                  child: Text("Avaliar"),
                  onPressed: () async {
                    setState(() {
                      loading = true;
                    });
                    await rateRider(widget.riderId, widget.rideId, rating,
                        feedbackController.text);
                    Navigator.pop(context);
                  },
                ),
              ],
      ),
    );
  }
}
