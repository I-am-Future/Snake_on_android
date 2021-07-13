// snake - from desktop to mobile.
// from CSC1002 (2021 Spring) Assignment 2
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Snake by Future'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var isGameOn = false;
  final updateInterval = Duration(milliseconds: 1500);
  late int monsterBlockX;
  late int monsterBlockY;
  late int snakeBlockX;
  late int snakeBlockY;
  final snakeSize = 20;
  var gameLoopTimer;
  var result = 0;

  // late var updateTimer = Timer.periodic(updateInterval, (timer) { })
  @override
  void initState() {
    super.initState();

  }

  void initGame() {
    final areaWidth = MediaQuery.of(context).size.width;
    final areaHeight = MediaQuery.of(context).size.height;
    var numOfBlocks = areaWidth ~/ 20;
    var centerBlockX = numOfBlocks / 2;
    var centerBlockY = centerBlockX;
    //var boarderBoxWidth = numOfBlocks * 20;
    var random = Random();
    do {
      monsterBlockX = random.nextInt(numOfBlocks);
      monsterBlockY = random.nextInt(numOfBlocks);
    } while ((monsterBlockX - centerBlockX).abs() +
            (monsterBlockY - centerBlockY).abs() <
        30);
    do {
      snakeBlockX = random.nextInt(numOfBlocks);
      snakeBlockY = random.nextInt(numOfBlocks);
    } while ((snakeBlockX - centerBlockX).abs() +
            (snakeBlockY - centerBlockY).abs() >
        30);
  }

  int checkCollision() {
    monsterPosX = snakeSize*monsterBlockX+monster
  }

  void loop() {
  
  }

  void gameStartButton() {
    // bind function to the start button
    this.isGameOn = true;
    this.gameLoopTimer = Timer.periodic(updateInterval, (timer) {
       // main game loop
    setState(() {
      print(this.isGameOn);

      this.result = checkColision();
      if (result == 1) {
        // the player wins
        this.gameLoopTimer.cancel();
        this.isGameOn = false;
      } else if (result == 2) {
        // the player loses
        this.gameLoopTimer.cancel();
        this.isGameOn = false;
      }
    });
    });
  }

  List<Widget> buildAllSprites() {
    final areaWidth = MediaQuery.of(context).size.width;
    final areaHeight = MediaQuery.of(context).size.height;
    double boarderBoxWidth = (areaWidth ~/ 20) * 20;
    // update sprites in the game board.
    List<Widget> spritesList = [];

    if (!this.isGameOn) {
      // game not on. display snake, monster, food, BUTTON on the screen.
      initGame();
    } else {
      // game on. display the new pos of snake, monster, food on the screen.
      spritesList.add(
        Positioned(
          top: boarderBoxWidth / 2.5,
          child: TextButton(
            onPressed: () {
              this.isGameOn = false;
            },
            child: Text(
              "finished",
              style: TextStyle(fontSize: 24.0, color: Colors.black87),
            ),
          ),
        ),
      );
    }

    // borderBox
    spritesList.add(
      Positioned(
        child: Container(
          width: boarderBoxWidth,
          height: boarderBoxWidth,
          color: Colors.blue[100],
        ),
      ),
    );
    // monster
    spritesList.add(
      Positioned(
        left: (snakeSize * monsterBlockX).toDouble(),
        top: (snakeSize * monsterBlockY).toDouble(),
        child: Container(
          width: snakeSize.toDouble(),
          height: snakeSize.toDouble(),
          color: Colors.purple[500],
        ),
      ),
    );

    // snake
    spritesList.add(
      Positioned(
        left: (snakeSize * snakeBlockX).toDouble(),
        top: (snakeSize * snakeBlockY).toDouble(),
        child: Container(
          width: snakeSize.toDouble(),
          height: snakeSize.toDouble(),
          color: Colors.red[600],
        ),
      ),
    );

    if (!this.isGameOn) {
      // game not on. display snake, monster, food, BUTTON on the screen.
      spritesList.add(
        Positioned(
          top: boarderBoxWidth / 2.5,
          child: TextButton(
            onPressed: handleTapGameStart,
            child: Text(
              "Tap to play!",
              style: TextStyle(fontSize: 24.0, color: Colors.black87),
            ),
          ),
        ),
      );
    }

    return spritesList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // at the top of the app
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            alignment: Alignment.center,
            height: 48,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(width: 8),
                Text("Time: 00", style: TextStyle(fontSize: 18)),
                Text("Heading: Up", style: TextStyle(fontSize: 18)),
                Text("Contact: 00", style: TextStyle(fontSize: 18)),
                Container(width: 8),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.topCenter,
              children: buildAllSprites(),
            ),
          ),
        ],
      ),
    );
  }
}
