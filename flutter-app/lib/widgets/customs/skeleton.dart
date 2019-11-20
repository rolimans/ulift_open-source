import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RideSummarySkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300],
        highlightColor: Colors.grey[100],
        child: RideSummarySpace(),
      ),
    );
  }
}

class TextSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300],
        highlightColor: Colors.grey[100],
        child: Container(
          child: Container(
            height: 20.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class CardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        child: CardSpace());
  }
}

class RideSummarySpace extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rideThumbnail = Container(
        margin: EdgeInsets.symmetric(vertical: 16.0),
        alignment: FractionalOffset.centerLeft,
        child: Container(
          width: 92.0,
          height: 92.0,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(300))),
        ));

    Widget _rideValue() {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Container(
          width: double.infinity,
          height: 8.0,
          color: Colors.white,
        ),
      );
    }

    final rideCardContent = Container(
      margin: EdgeInsets.fromLTRB(76.0, 16.0, 16.0, 16.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(height: 4.0),
            Container(
              width: double.infinity,
              height: 13.0,
              color: Colors.white,
            ),
            Container(height: 10.0),
            _rideValue(),
            _rideValue(),
            _rideValue(),
            _rideValue(),
            _rideValue(),
            _rideValue(),
            _rideValue(),
            Container(height: 30.0),
            _rideValue(),
          ]),
    );

    final rideCard = Container(
      child: rideCardContent,
      margin: EdgeInsets.only(left: 46.0),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white70,
        borderRadius: BorderRadius.circular(8.0),
      ),
    );

    return GestureDetector(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 24.0,
          ),
          child: Stack(
            children: <Widget>[
              rideCard,
              rideThumbnail,
            ],
          ),
        ));
  }
}

class CardSpace extends StatelessWidget {
  Widget _placeHolder() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Container(
        width: double.infinity,
        height: 8.0,
        color: Colors.white,
      ),
    );
  }

  Widget _placeHolderButton() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Container(
        width: 80,
        height: 20.0,
        color: Colors.white,
      ),
    );
  }

  Widget _placeHolderIcon() {
    return Container(
      child: Container(
        width: 40,
        height: 40.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Shimmer.fromColors(
              baseColor: Colors.grey[300],
              highlightColor: Colors.grey[100],
              child: ListTile(
                leading: _placeHolderIcon(),
                title: _placeHolder(),
                subtitle: Column(
                  children: <Widget>[_placeHolder(), _placeHolder()],
                ),
              )),
          ButtonTheme.bar(
            child: Shimmer.fromColors(
                baseColor: Colors.grey[300],
                highlightColor: Colors.grey[100],
                child: ButtonBar(
                  children: <Widget>[
                    _placeHolderButton(),
                    _placeHolderButton()
                  ],
                )),
          ),
        ],
      ),
    );
  }
}
