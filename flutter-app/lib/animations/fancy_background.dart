import 'dart:math';

import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class FancyBackground extends StatelessWidget {
  final Widget child;
  final List<Widget> waves;
  final AnimationTrack track1;
  final AnimationTrack track2;

  FancyBackground({this.child, this.waves, this.track1, this.track2})
      : assert(child != null),
        assert(track1 != null),
        assert(track2 != null);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    children.add(Positioned.fill(
        child: AnimatedBackground(
      track1: track1,
      track2: track2,
    )));
    children.addAll(waves);
    children.add(Positioned.fill(child: child));
    return Stack(
      children: children,
    );
  }

  static onBottom(Widget child) => Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );
}

class AnimatedWave extends StatelessWidget {
  final double height;
  final double speed;
  final double offset;

  AnimatedWave({this.height, this.speed, this.offset = 0.0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        height: height,
        width: constraints.biggest.width,
        child: ControlledAnimation(
            playback: Playback.LOOP,
            duration: Duration(milliseconds: (5000 / speed).round()),
            tween: Tween(begin: 0.0, end: 2 * pi),
            builder: (context, value) {
              return CustomPaint(
                foregroundPainter: CurvePainter(value + offset),
              );
            }),
      );
    });
  }
}

class CurvePainter extends CustomPainter {
  final double value;

  CurvePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white.withAlpha(60);
    final path = Path();

    final y1 = sin(value);
    final y2 = sin(value + pi / 2);
    final y3 = sin(value + pi);

    final startPointY = size.height * (0.5 + 0.4 * y1);
    final controlPointY = size.height * (0.5 + 0.4 * y2);
    final endPointY = size.height * (0.5 + 0.4 * y3);

    path.moveTo(size.width * 0, startPointY);
    path.quadraticBezierTo(
        size.width * 0.5, controlPointY, size.width, endPointY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, white);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class AnimationTrack {
  final int seconds;
  final Color begin;
  final Color end;

  AnimationTrack(this.seconds, this.begin, this.end)
      : assert(seconds > 0),
        assert(begin != null),
        assert(end != null);
}

class AnimatedBackground extends StatelessWidget {
  final AnimationTrack track1;
  final AnimationTrack track2;

  AnimatedBackground({this.track1, this.track2});

  @override
  Widget build(BuildContext context) {
    final tween = MultiTrackTween([
      Track("color1").add(Duration(seconds: track1.seconds),
          ColorTween(begin: track1.begin, end: track1.end)),
      Track("color2").add(Duration(seconds: track2.seconds),
          ColorTween(begin: track2.begin, end: track2.end))
    ]);

    return ControlledAnimation(
      playback: Playback.MIRROR,
      tween: tween,
      duration: tween.duration,
      builder: (context, animation) {
        return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [animation["color1"], animation["color2"]])),
        );
      },
    );
  }
}
