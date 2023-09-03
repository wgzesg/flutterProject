import 'dart:io';

import 'package:flutter/material.dart';

class EntryPage extends StatelessWidget {
  bool isMobile = false;

  EntryPage({Key? key}) {
    try {
      isMobile = Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      isMobile = false;
    }
  }

  void showRulesDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Rules'),
            content: Text('This is the rules'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: Text('OK'))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    var img = DecorationImage(
        image: Image.asset("assets/images/app_background.jpg").image,
        fit: BoxFit.cover,
        scale: 10);
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        return Container(
          // width: constraints.maxWidth as double,
          // height: constraints.maxHeight as double,
          constraints: BoxConstraints(
              maxHeight: constraints.maxHeight, maxWidth: constraints.maxWidth),
          decoration: BoxDecoration(
            image: img,
          ),
          child: Center(
            child: Stack(
              children: [
                Image.asset(
                  "assets/images/gb.jpeg",
                  fit: BoxFit.cover,
                  height: constraints.maxHeight,
                  width: constraints.maxWidth,
                ),
                Center(
                    child: Padding(
                        padding: EdgeInsets.all(isMobile ? 80 : 150),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            MaterialButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              color: Colors.blueAccent,
                              splashColor: Colors.blueGrey,
                              minWidth: 300,
                              onPressed: () {
                                Navigator.of(context).pushNamed('/game');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  "Start Game",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 40),
                                ),
                              ),
                            ),
                            MaterialButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              color: Colors.blueAccent,
                              splashColor: Colors.blueGrey,
                              minWidth: 300,
                              onPressed: () {
                                showRulesDialog(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  "Rules",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 40),
                                ),
                              ),
                            ),
                          ],
                        )))
              ],
            ),
          ),
        );
      }),
    );
  }
}
