// Snake - from desktop to mobile.
// from CSC1002 (2021 Spring) Assignment 2
// Author: Future
// Date: Jul.14th, 2021

import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:sprintf/sprintf.dart';
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
  final updateInterval = Duration(milliseconds: 750);
  final int monsterSpeed = 1;
  late int monsterBlockX;
  late int monsterBlockY;
  late int monsterDrift;
  late int snakeBlockX;
  late int snakeBlockY;
  late String snakeHeading = "Up";
  final snakeSize = 20;
  late int snakeContactsMonster = 0;
  bool isFirstTime = true;
  var gameLoopTimer;
  var result = 0;
  var initDone = false;
  late var gameStartTime;
  List<int> foodPosX = [-1, -1, -1, -1, -1, -1, -1, -1, -1];
  List<int> foodPosY = [-1, -1, -1, -1, -1, -1, -1, -1, -1];
  List<bool> foodIsEaten = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ];

  @override
  void initState() {
    super.initState();
    initGame();
  }

  void initGame() {
    // final areaWidth = MediaQuery.of(context).size.width;
    // final areaHeight = MediaQuery.of(context).size.height;
    final areaWidth = 400;
    final areaHeight = 400;
    var numOfBlocks = areaWidth ~/ 20;
    var centerBlockX = numOfBlocks / 2;
    var centerBlockY = centerBlockX;
    //var boarderBoxWidth = numOfBlocks * 20;
    var random = Random();
    // set monster init position
    do {
      monsterBlockX = random.nextInt(numOfBlocks - 1);
      monsterBlockY = random.nextInt(numOfBlocks - 1);
    } while ((monsterBlockX - centerBlockX).abs() +
            (monsterBlockY - centerBlockY).abs() <
        10);
    this.monsterDrift = random.nextInt(19);
    // set snake init position
    do {
      snakeBlockX = random.nextInt(numOfBlocks);
      snakeBlockY = random.nextInt(numOfBlocks);
    } while ((snakeBlockX - centerBlockX).abs() +
            (snakeBlockY - centerBlockY).abs() >
        10);
    // set food init position
    int foodBlockX;
    int foodBlockY;
    for (int i = 0; i < 9; i++) {
      do {
        foodBlockX = random.nextInt(numOfBlocks);
        foodBlockY = random.nextInt(numOfBlocks);
      } while ((this.foodPosX.contains(foodBlockX)) &&
          (this.foodPosY.contains(foodBlockY)));
      this.foodPosX[i] = foodBlockX;
      this.foodPosY[i] = foodBlockY;
      this.foodIsEaten[i] = false;
    }
    this.snakeContactsMonster = 0;
    this.result = 0;
    // print(this.foodPosX);
    // print(this.foodPosY);
    // print(this.foodIsEaten);
  }

  List getMonsterNewBlockPos() {
    List newBlockPos = [monsterBlockX, monsterBlockY];
    if ((monsterBlockX - snakeBlockX).abs() >
        (monsterBlockY - snakeBlockY).abs()) {
      if (monsterBlockX > snakeBlockX) {
        newBlockPos[0] -= 1;
      } else {
        newBlockPos[0] += 1;
      }
    } else {
      if (monsterBlockY > snakeBlockY) {
        newBlockPos[1] -= 1;
      } else {
        newBlockPos[1] += 1;
      }
    }

    return newBlockPos;
  }

  bool checkCollision() {
    int monsterPosX = snakeSize * monsterBlockX + monsterDrift;
    int monsterPosY = snakeSize * monsterBlockY + monsterDrift;
    int snakePosX = snakeSize * snakeBlockX;
    int snakePosY = snakeSize * snakeBlockY;
    if (pow(snakePosY - monsterPosY, 2) + pow(snakePosX - monsterPosX, 2) <
        pow(1.3 * snakeSize, 2)) {
      return true;
    }
    return false;
  }

  bool checkPlayerWin() {
    return !foodIsEaten.contains(false);
  }

  void checkIfEating() {
    for (int i = 0; i < 9; i++) {
      if (snakeBlockX == foodPosX[i] && snakeBlockY == foodPosY[i]) {
        foodIsEaten[i] = true;
      }
    }
  }

  void checkIfContact() {}

  void handleTapGameStart() {
    // bind function to the start button
    setState(() {
      this.isFirstTime = false;
      this.isGameOn = true;
      this.gameStartTime = DateTime.now();
    });

    this.gameLoopTimer = Timer.periodic(updateInterval, (timer) {
      // main game loop
      setState(() {
        //print(this.isGameOn);
        //
        // monster movement
        var monsterPos = getMonsterNewBlockPos();
        this.monsterBlockX = monsterPos[0];
        this.monsterBlockY = monsterPos[1];
        // check if snake is eating
        checkIfEating();
        // check if monster contacts with the snake body
        checkIfContact();
        // check if monster collides snake (player loses)
        if (checkCollision()) {
          this.gameLoopTimer.cancel();
          this.isGameOn = false;
          this.result = 2; // the player loses
          //initGame();
          return;
        }
        // check if the player wins
        if (checkPlayerWin()) {
          this.gameLoopTimer.cancel();
          this.isGameOn = false;
          this.result = 1; // the player wins
          //initGame();
          return;
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
        left: ((snakeSize * monsterBlockX) + this.monsterDrift).toDouble(),
        top: ((snakeSize * monsterBlockY) + this.monsterDrift).toDouble(),
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

    // food
    for (int i = 0; i < 9; i++) {
      if (!foodIsEaten[i]) {
        spritesList.add(
          Positioned(
            left: (snakeSize * foodPosX[i]).toDouble(),
            top: (snakeSize * foodPosY[i]).toDouble(),
            child: Text(sprintf("%d", [i + 1]), style: TextStyle(fontSize: 18)),
          ),
        );
      }
    }
    if ((!this.isGameOn) && (this.isFirstTime)) {
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
      spritesList.add(
        Positioned(
          top: boarderBoxWidth / 4.5,
          child: Text(
            "Welcome to the snake!",
            style: TextStyle(fontSize: 24.0, color: Colors.black87),
          ),
        ),
      );
    }

    if (this.result == 1) {
      //player wins
      spritesList.add(Positioned(
        left: (snakeSize * snakeBlockX).toDouble(),
        top: (snakeSize * snakeBlockY).toDouble(),
        child: Text(
          "You win!",
          style: TextStyle(fontSize: 12.0, color: Colors.green[700]),
        ),
      ));
    }
    if (this.result == 2) {
      //player loses
      spritesList.add(Positioned(
        left: (snakeSize * snakeBlockX).toDouble(),
        top: (snakeSize * snakeBlockY).toDouble(),
        child: Text(
          "You Loser!",
          style: TextStyle(fontSize: 12.0, color: Colors.green[700]),
        ),
      ));
    }
    if (this.result == 1 || this.result == 2) {
      spritesList.add(
        Positioned(
          top: boarderBoxWidth / 2.5,
          child: TextButton(
            onPressed: () {
              initGame();
              handleTapGameStart();
            },
            child: Text(
              "Tap to Replay",
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
                Text(
                    isFirstTime
                        ? "Time:  0 sec"
                        : sprintf("Time: %3d sec", [
                            DateTime.now()
                                .difference(this.gameStartTime)
                                .inSeconds
                          ]),
                    style: TextStyle(fontSize: 18)),
                Text("Heading: $snakeHeading", style: TextStyle(fontSize: 18)),
                Text("Contact: $snakeContactsMonster",
                    style: TextStyle(fontSize: 18)),
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
