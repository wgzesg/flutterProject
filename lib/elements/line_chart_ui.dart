import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:masterBet/resource/app_resources.dart';
import 'package:flutter/material.dart';
import 'package:masterBet/controller/config.dart';

class LineChartUI extends StatefulWidget {
  final List<double> prices;
  final Queue<int> buys;
  final Queue<int> sells;
  final int gameProgress;
  final double ratio;
  LineChartUI(
      {super.key,
      required this.prices,
      required this.buys,
      required this.sells,
      required this.gameProgress,
      required this.ratio});

  final Color lineColor = Color.fromARGB(255, 252, 252, 252);
  final Color buysColor = Color.fromARGB(255, 229, 22, 43);
  final Color sellsColor = Color.fromARGB(255, 23, 195, 46);
  Config config = Config();

  @override
  State<LineChartUI> createState() => _LineChartUIState();
}

class _LineChartUIState extends State<LineChartUI> {
  int step = 1;

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppColors.mainTextColor3,
      fontSize: 12,
    );
    if (widget.gameProgress >= widget.config.DISPLAY_LIMIT)
      value = value + widget.gameProgress - widget.config.DISPLAY_LIMIT;
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(value.toString(), style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    double xValue = 0;
    List<FlSpot> pricesData = [];
    for (double price in widget.prices) {
      pricesData.add(FlSpot(xValue, price));
      xValue += step;
    }
    if (pricesData.isEmpty) {
      return Container();
    }
    final max = widget.prices.reduce((curr, next) => curr > next ? curr : next);
    final min = widget.prices.reduce((curr, next) => curr < next ? curr : next);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AspectRatio(
            aspectRatio: this.widget.ratio,
            child: LineChart(
                curve: Curves.bounceInOut,
                LineChartData(
                  minY: min * 0.9,
                  maxY: max * 1.3,
                  minX: pricesData.first.x,
                  maxX: pricesData.last.x,
                  lineTouchData: const LineTouchData(enabled: false),
                  clipData: const FlClipData.all(),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: true,
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    priceLine(pricesData),
                  ],
                  titlesData: FlTitlesData(
                      show: true,
                      leftTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 25,
                            interval: 10,
                            getTitlesWidget: (value, meta) => leftTitleWidgets(
                                  value,
                                  meta,
                                )),
                      )),
                ))),
      ],
    );
  }

  LineChartBarData priceLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
          show: true,
          checkToShowDot: (spot, barData) {
            int timestamp = (widget.gameProgress > widget.config.DISPLAY_LIMIT)
                ? spot.x.toInt() +
                    widget.gameProgress -
                    widget.config.DISPLAY_LIMIT
                : spot.x.toInt();
            return widget.buys.contains(timestamp) ||
                widget.sells.contains(timestamp);
          },
          getDotPainter: (p0, p1, p2, p3) {
            int timestamp = (widget.gameProgress > widget.config.DISPLAY_LIMIT)
                ? p0.x.toInt() +
                    widget.gameProgress -
                    widget.config.DISPLAY_LIMIT
                : p0.x.toInt();
            return FlDotCirclePainter(
              radius: 3,
              color: widget.buys.contains(timestamp)
                  ? widget.buysColor
                  : widget.sells.contains(timestamp)
                      ? widget.sellsColor
                      : Colors.transparent,
            );
          }),
      gradient: LinearGradient(
        colors: [widget.lineColor.withOpacity(0), widget.lineColor],
        stops: const [0, 0.9],
      ),
      barWidth: 4,
      isCurved: false,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
