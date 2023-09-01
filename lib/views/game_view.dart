import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masterBet/elements/line_chart_ui.dart';
import 'package:masterBet/controller/config.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

class GameView extends StatefulWidget {
  const GameView({Key? key}) : super(key: key);

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView>
    with SingleTickerProviderStateMixin {
  final GlobalKey _globalKey = GlobalKey();
  final fps = 1 / 10; // Frame Rate of 10 Frames per second
  Size screenSize = Size.zero;
  Timer? timer;
  bool launched = false, finishing = false, firstGame = true;
  bool isMobile = false;
  Random rnd = new Random();
  List<double> futures = [];
  Queue<int> buys = Queue();
  Queue<int> sells = Queue();
  Queue<double> pricesOfInterest = Queue();
  static const int GAME_LENGTH = 900;
  int currentGameLength = 0;
  double price = 10;
  double cash = 10000;
  // ignore: non_constant_identifier_names
  int numOfStocks = 0;
  // ignore: non_constant_identifier_names
  double totalAssets = 0;
  double remainingTime = 0;
  late AnimationController _controller;
  Config config = Config();

  @override
  void dispose() {
    super.dispose();

    if (timer != null) {
      timer!.cancel();
    }
  }

  void _loadCSV(ticker) async {
    final rawData = await rootBundle.loadString("assets/data/$ticker.csv");
    List<List<dynamic>> listData =
        const CsvToListConverter(eol: '\n').convert(rawData);
    rnd = new Random();
    int randomIndex = rnd.nextInt(listData.length - GAME_LENGTH - 1);
    print("total length: ${listData.length}, randomIndex: $randomIndex");
    listData = listData.sublist(randomIndex + 1, randomIndex + GAME_LENGTH + 2);

    setState(() {
      futures = listData.map((e) => e[1]).cast<double>().toList();
      price = futures[0];
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: Duration(seconds: (GAME_LENGTH * fps).toInt()), vsync: this);
    currentGameLength = 0;
    try {
      isMobile = Platform.isAndroid || Platform.isIOS;
    } catch (e) {}
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      setupGame();
    });
  }

  setupGame() {
    _loadCSV("AAPL");
    RenderBox? renderBox =
        _globalKey.currentContext!.findRenderObject() as RenderBox?;
    screenSize = renderBox!.size;
    cash = 1000000;
    numOfStocks = 0;
    totalAssets = cash;
    currentGameLength = 0;
    buys = Queue();
    sells = Queue();
    pricesOfInterest = Queue();
    remainingTime = fps * GAME_LENGTH;
  }

  reset() {
    setState(() {
      firstGame = false;
      finishing = false;
      launched = false;
    });
    setupGame();
  }

  frameBuilder(dynamic timestamp) {
    setState(() {});
    price = futures[currentGameLength];
    totalAssets = cash + numOfStocks * price;
    buildLine();
    currentGameLength++;
    if (currentGameLength >= GAME_LENGTH) {
      endGame();
    }
    remainingTime -= 0.1;
  }

  buildLine() {
    pricesOfInterest.add(futures[currentGameLength]);
    while (pricesOfInterest.length > config.DISPLAY_LIMIT) {
      pricesOfInterest.removeFirst();
    }
    while (buys.isNotEmpty &&
        buys.first < currentGameLength - config.DISPLAY_LIMIT) {
      buys.removeFirst();
    }
    while (sells.isNotEmpty &&
        sells.first < currentGameLength - config.DISPLAY_LIMIT) {
      sells.removeFirst();
    }
  }

  refreshFrame() {
    if (!launched) {
      setState(() {});
    }
  }

  endGame() {
    launched = false;
    finishing = true;
    if (timer != null) {
      timer!.cancel();
    }
    Future.delayed(Duration(milliseconds: 200), () {
      gameDialog();
    });
  }

  gameDialog() async {
    final borderRadius = BorderRadius.circular(20.0);
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return Dialog(
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              child: StatefulBuilder(
                builder: (context, updateState) {
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  child: Text(
                                    "Your Stats",
                                    style: TextStyle(
                                        fontSize: isMobile ? 20 : 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                    height: 20,
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                            fontSize: isMobile ? 15 : 30,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange),
                                        children: <TextSpan>[
                                          TextSpan(text: 'Stock Growth: '),
                                          TextSpan(
                                              text:
                                                  '${((futures[GAME_LENGTH] / futures[0] - 1) * 100).toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                  color: Colors.black)),
                                        ],
                                      ),
                                    )),
                                SizedBox(
                                    height: 20,
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                            fontSize: isMobile ? 15 : 30,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange),
                                        children: <TextSpan>[
                                          TextSpan(text: 'Your Growth: '),
                                          TextSpan(
                                              text:
                                                  '${((totalAssets / 1000000 - 1) * 100).toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                  color: Colors.black)),
                                        ],
                                      ),
                                    )),
                                MaterialButton(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: borderRadius),
                                  color: Colors.orange,
                                  onPressed: () {
                                    reset();
                                    Navigator.of(context).pop();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      "Restart",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isMobile ? 20 : 25),
                                    ),
                                  ),
                                ),
                              ]),
                        ),
                      ),
                    ],
                  );
                },
              ));
        });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      var aspectRatio =
          constraints.maxWidth * 5 / 6 / (constraints.maxHeight * 3 / 4);
      return GestureDetector(
        onTap: () {
          if (!launched && !finishing) {
            launched = true;
            this._controller.forward();
            // Refreshing State at Rate of 60/Sec
            timer = Timer.periodic(
                Duration(milliseconds: (fps * 1000).floor()), frameBuilder);
          }
          print("The key is pressed.");
        },
        onTapDown: (details) {
          if (!launched) {
            return;
          }
          final y = details.globalPosition.dy;
          totalAssets = cash + numOfStocks * price;
          int tenPcStock = totalAssets ~/ 10 ~/ price;
          if (y > screenSize.height / 2) {
            if (tenPcStock > numOfStocks) {
              tenPcStock = numOfStocks;
            }
            if (tenPcStock == 0) {
              return;
            }
            numOfStocks = numOfStocks - tenPcStock;
            cash += tenPcStock * price;
            sells.add(currentGameLength);
          } else {
            if (tenPcStock * price > cash) {
              tenPcStock = cash ~/ price;
            }
            if (tenPcStock == 0) {
              return;
            }
            numOfStocks += tenPcStock;
            cash -= tenPcStock * price;
            buys.add(currentGameLength);
          }
        },
        child: Center(
          child: Container(
            key: _globalKey,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: MouseRegion(
              child: Stack(
                children: [
                  Positioned(
                      top: constraints.maxHeight / 3,
                      height: constraints.maxHeight / 3,
                      left: 0,
                      width: constraints.maxWidth / 12,
                      child: Column(
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.black87,
                            size: constraints.maxWidth / 14,
                          ),
                          Text(
                            remainingTime.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )),
                  Positioned(
                      top: constraints.maxHeight / 6,
                      height: constraints.maxHeight * 3 / 4,
                      left: constraints.maxWidth / 12,
                      width: constraints.maxWidth / 6 * 5,
                      child: Container(
                          decoration: BoxDecoration(
                              color: Color.fromARGB(255, 24, 85, 114)
                                  .withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10.0)),
                          // child: this.line,
                          child: LineChartUI(
                            prices: pricesOfInterest.toList(),
                            buys: buys,
                            sells: sells,
                            gameProgress: currentGameLength,
                            ratio: aspectRatio,
                          ))),
                  Positioned(
                      top: 0,
                      left: 0,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight / 6,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Cash: ",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange),
                              ),
                              Text(
                                cash.toStringAsFixed(2),
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Stocks:",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange),
                              ),
                              Text(
                                numOfStocks.toString(),
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Percentage Gain:",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange),
                              ),
                              Text(
                                (totalAssets / 1000000).toStringAsFixed(2),
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Price:",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange),
                              ),
                              Text(
                                price.toStringAsFixed(2),
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
