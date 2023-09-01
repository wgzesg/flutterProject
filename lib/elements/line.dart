import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:matrix4_transform/matrix4_transform.dart';

class Line extends StatefulWidget {
  final List<double> prices;
  late Path path;
  AnimationController controller;

  Line({required this.prices, required this.controller}) {
    path = Path();
    path.moveTo(0, 0 - prices[0]);
    double x = 0;
    for (double price in prices) {
      path.lineTo(x, 0 - price);
      x += 5;
    }
  }
  @override
  State<StatefulWidget> createState() => _LineState();
}

class _LineState extends State<Line> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  late Animation<double> animation;
  late AnimationController controller;
  late PathMetrics pms;
  @override
  void initState() {
    super.initState();

    animation = Tween(begin: 0.0, end: 1.0).animate(this.widget.controller)
      ..addListener(() {
        setState(() {
          _progress = animation.value;
        });
      });
    // controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: LinePainter(_progress, widget.path, widget.prices));
  }

  void start() {
    this.controller.forward();
  }
}

class LinePainter extends CustomPainter {
  Paint _paint = Paint()..color = Colors.blue;
  double _progress;
  Path path;
  late PathMetrics pathMetrics;
  late PathMetric pm;
  final List<double> prices;
  static const OCCUPY_RATIO = 0.3;
  static const RANGE_SIZE = 0.08;

  LinePainter(this._progress, this.path, this.prices) {
    _paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    pathMetrics = path.computeMetrics();
    pm = pathMetrics.elementAt(0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    double progressStart =
        _progress - RANGE_SIZE < 0 ? 0 : _progress - RANGE_SIZE;
    double begin = pm.length * progressStart;
    Path subpath = pm.extractPath(begin, pm.length * _progress);
    double currLeft = subpath.getBounds().left;
    double currUp = subpath.getBounds().top;
    double currDown = subpath.getBounds().bottom;
    double targetWidth;
    if (currDown == currUp) {
      targetWidth = (currDown * OCCUPY_RATIO).abs();
    } else {
      targetWidth = (currDown - currUp);
    }
    double scaleFactor = targetWidth / (432 * (1 - OCCUPY_RATIO));
    var verticalScaling = Matrix4Transform().scaleVertically(1 / scaleFactor);
    subpath = subpath.transform(verticalScaling.matrix4.storage);
    currUp = subpath.getBounds().top;
    var verticalTranslation = Matrix4Transform()
        .translate(y: -currUp + 432 * OCCUPY_RATIO / 2)
        .matrix4;
    subpath = subpath.transform(verticalTranslation.storage);
    subpath =
        subpath.transform(Matrix4.translationValues(-currLeft, 0, 0).storage);
    canvas.drawPath(subpath, _paint);
    paintLowHighCurr(progressStart, canvas, size);
    // canvas.drawLine(Offset(0.0, 0.0),
    //     Offset(200 - 200 * _progress, 500 - 500 * _progress), _paint);
  }

  void paintLowHighCurr(double progressStart, Canvas canvas, Size size) {
    int startIndex = (progressStart * prices.length).toInt();
    int endIndex = (_progress * prices.length).toInt();
    if (endIndex == startIndex) {
      endIndex += 1;
    }
    int maxPriceIdx = startIndex;
    int minPriceIdx = startIndex;
    int currPriceIdx = endIndex - 1;
    for (int i = startIndex; i < endIndex; i++) {
      if (prices[i] > prices[maxPriceIdx]) {
        maxPriceIdx = i;
      }
      if (prices[i] < prices[minPriceIdx]) {
        minPriceIdx = i;
      }
    }
    paintTextPainter("Max price: " + prices[maxPriceIdx].toStringAsFixed(2),
        canvas, Offset(-240, 20));
    paintTextPainter("Min price: " + prices[minPriceIdx].toStringAsFixed(2),
        canvas, Offset(-240, 350));
    paintTextPainter(
        "Current price: " + prices[currPriceIdx].toStringAsFixed(2),
        canvas,
        Offset(432 / 2, -50));
  }

  void paintTextPainter(String text, Canvas canvas, Offset offset) {
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 30,
    );
    final t = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    t.layout();
    t.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) {
    return oldDelegate._progress != _progress;
  }
}
