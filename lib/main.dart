// Snake - from desktop to mobile.
// from CSC1002 (2021 Spring) Assignment 2
// Author: Future
// Date: Jul.14th, 2021

import 'dart:math';
import 'dart:async';
import 'package:sprintf/sprintf.dart';
import 'package:flutter/material.dart';
import 'package:tom_sensors/tom_sensors.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
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
  // out-game config
  late var numOfBlocks;
  final slowModeInterval = [1500, 1300, 1550];
  final mediumModeInterval = [700, 500, 750];
  final fastModeInterval = [250, 200, 300];
  Map intHeadingMapping = {0: "up", 1: "right", 2: "down", 3: "left"};
  List<StreamSubscription>? _subscriptions;
  RotationEvent? _rotationEvent;
  final snakeSize = 20;
  bool isFirstTime = true;

  // monsters
  var monsterUpdateInterval = Duration(milliseconds: 700);
  final int monsterSpeed = 1;
  late int monsterBlockX;
  late int monsterBlockY;
  late int monsterDrift;

  // snake
  var snakeNormalInterval = Duration(milliseconds: 500);
  var snakeEatingInterval = Duration(milliseconds: 750);
  late int snakeBlockX;
  late int snakeBlockY;
  late int snakeCurrentLength;
  late int snakeMaxLength;
  List<int> snakeBodyBlockX = [];
  List<int> snakeBodyBlockY = [];
  late int snakeHeading = 0;

  // in-game config
  late int snakeContactsMonster = 0;
  var gameLoopTimer;
  var result = 0;
  late var gameStartTime;
  late var gameCurrentTime;

  // food
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
    _toggle();
  }

  void _toggle() {
    setState(() {
      if (_subscriptions == null) {
        //print('do subscribe');
        _subscriptions = [
          rotationEvents.listen((e) {
            setState(() => _rotationEvent = e);
          }),
        ];
      } else {
        //print('do unsubscribe');
        for (final sub in _subscriptions!) {
          sub.cancel();
        }
        _subscriptions = null;
      }
    });
  }

  void initGame() {
    // final areaWidth = MediaQuery.of(context).size.width;
    // final areaHeight = MediaQuery.of(context).size.height;
    final areaWidth = 380;
    // final areaHeight = 400;
    var numOfBlocks = areaWidth ~/ 20;
    this.numOfBlocks = numOfBlocks;
    var centerBlockX = numOfBlocks / 2;
    var centerBlockY = centerBlockX;
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
    this.snakeCurrentLength = 0;
    this.snakeMaxLength = 5;
    this.snakeBodyBlockX = [];
    this.snakeBodyBlockY = [];

    this.result = 0;
  }

  List getMonsterNewBlockPos() {
    List newBlockPos = [monsterBlockX, monsterBlockY];
    int monsterPosX = snakeSize * monsterBlockX + monsterDrift;
    int monsterPosY = snakeSize * monsterBlockY + monsterDrift;
    int snakePosX = snakeSize * snakeBlockX;
    int snakePosY = snakeSize * snakeBlockY;
    if ((monsterPosX - snakePosX).abs() > (monsterPosY - snakePosY).abs()) {
      if (monsterPosX > snakePosX) {
        newBlockPos[0] -= 1;
      } else {
        newBlockPos[0] += 1;
      }
    } else {
      if (monsterPosY > snakePosY) {
        newBlockPos[1] -= 1;
      } else {
        newBlockPos[1] += 1;
      }
    }

    return newBlockPos;
  }

  int getSnakeHeading() {
    int newHdg;
    double? pitchAngle = _rotationEvent?.pitch;
    double? rollAngle = _rotationEvent?.roll;
    if (pitchAngle!.abs() > rollAngle!.abs()) {
      if (pitchAngle > 0) {
        if (this.snakeHeading == 2) {
          return 2;
        }
        newHdg = 0;
      } else {
        if (this.snakeHeading == 0) {
          return 0;
        }
        newHdg = 2;
      }
    } else {
      if (rollAngle > 0) {
        if (this.snakeHeading == 3) {
          return 3;
        }
        newHdg = 1;
      } else {
        if (this.snakeHeading == 1) {
          return 1;
        }
        newHdg = 3;
      }
    }
    return newHdg;
  }

  bool checkCollision() {
    int monsterPosX = snakeSize * monsterBlockX + monsterDrift;
    int monsterPosY = snakeSize * monsterBlockY + monsterDrift;
    int snakePosX = snakeSize * snakeBlockX;
    int snakePosY = snakeSize * snakeBlockY;
    if (pow(snakePosY - monsterPosY, 2) + pow(snakePosX - monsterPosX, 2) <
        pow(snakeSize, 2)) {
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
        this.snakeMaxLength += i + 1;
      }
    }
  }

  void checkIfContact() {
    for (int i = 0; i < this.snakeBodyBlockX.length; i++) {
      if (monsterBlockX == snakeBodyBlockX[i] &&
          monsterBlockY == snakeBodyBlockY[i]) {
        this.snakeContactsMonster++;
        break;
      }
    }
  }

  void updateMonster() {
    setState(() {
      if (result == 0) {
        // monster movement
        var monsterPos = getMonsterNewBlockPos();
        this.monsterBlockX = monsterPos[0];
        this.monsterBlockY = monsterPos[1];
        // check if monster contacts with the snake body
        checkIfContact();
        this.gameCurrentTime = DateTime.now();
        Timer(monsterUpdateInterval, updateMonster);
      }
    });
  }

  void updateSnake() {
    setState(() {
      // get the snake heading
      this.snakeHeading = getSnakeHeading();
      // move the snake
      var timerDuration;
      if ((snakeBlockX == 0 && this.snakeHeading == 3) ||
          (snakeBlockY == 0 && this.snakeHeading == 0) ||
          (snakeBlockX == this.numOfBlocks - 1 && this.snakeHeading == 1) ||
          (snakeBlockY == this.numOfBlocks - 1 && this.snakeHeading == 2)) {
        // the snake stops
        // set next timer
        if (snakeBodyBlockX.length < this.snakeMaxLength) {
          timerDuration = snakeEatingInterval;
        } else {
          timerDuration = snakeNormalInterval;
        }
      } else {
        // the snake moves
        this.snakeBodyBlockX.add(snakeBlockX);
        this.snakeBodyBlockY.add(snakeBlockY);
        if (this.snakeHeading == 0) {
          snakeBlockY -= 1;
        } else if (this.snakeHeading == 1) {
          snakeBlockX += 1;
        } else if (this.snakeHeading == 2) {
          snakeBlockY += 1;
        } else {
          snakeBlockX -= 1;
        }
        if (snakeBodyBlockX.length < this.snakeMaxLength) {
          // snake should extending
          timerDuration = snakeEatingInterval;
        } else {
          // snake is at its length
          timerDuration = snakeNormalInterval;
          this.snakeBodyBlockX.removeAt(0);
          this.snakeBodyBlockY.removeAt(0);
        }
      }
      //
      // check if snake is eating
      checkIfEating();
      // check if monster collides snake (player loses)
      if (checkCollision()) {
        this.result = 2; // the player loses
        return;
      }
      // check if the player wins
      if (checkPlayerWin()) {
        this.result = 1; // the player wins
        return;
      }
      Timer(timerDuration, updateSnake);
    });
  }

  void handleTapGameStart() {
    // bind function to the start button
    setState(() {
      this.isFirstTime = false;
      this.gameStartTime = DateTime.now();
      this.gameCurrentTime = DateTime.now();
    });

    Timer(snakeNormalInterval, () {
      // main game loop for snake
      updateSnake();
    });
    Timer(monsterUpdateInterval, () {
      // main game loop for monster
      updateMonster();
    });
  }

  List<Widget> buildAllSprites() {
    final areaWidth = MediaQuery.of(context).size.width;
    //final areaHeight = MediaQuery.of(context).size.height;
    double boarderBoxWidth = (areaWidth ~/ 20) * 20;
    // update sprites in the game board.
    List<Widget> spritesList = [];

    // snake
    for (int i = 0; i < this.snakeBodyBlockX.length; i++) {
      spritesList.add(
        Positioned(
          left: (snakeSize * snakeBodyBlockX[i]).toDouble(),
          top: (snakeSize * snakeBodyBlockY[i]).toDouble(),
          child: Container(
            width: snakeSize.toDouble(),
            height: snakeSize.toDouble(),
            decoration: BoxDecoration(
              color: Colors.blue[200],
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ),
      );
    }
    spritesList.add(
      Positioned(
        left: (snakeSize * snakeBlockX).toDouble(),
        top: (snakeSize * snakeBlockY).toDouble(),
        child: Container(
          width: snakeSize.toDouble(),
          height: snakeSize.toDouble(),
          decoration: BoxDecoration(
            color: Colors.red[300],
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
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
          decoration: BoxDecoration(
            color: Colors.purple[500],
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
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
    // borderBox
    spritesList.add(
      Positioned(
        child: Container(
          width: boarderBoxWidth,
          height: boarderBoxWidth,
          margin: const EdgeInsets.all(0.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(border: Border.all(color: Colors.black)),
        ),
      ),
    );

    if (this.isFirstTime) {
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
          top: boarderBoxWidth / 5,
          child: Text(
            "Welcome to the snake!\nTilt your phone to move!\nEat the food and avoid the monster!",
            style: TextStyle(fontSize: 18.0, color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (this.result == 1) {
      //player wins
      spritesList.add(Positioned(
        left: monsterBlockX > this.numOfBlocks / 2
            ? (snakeSize * snakeBlockX).toDouble() - 100
            : (snakeSize * snakeBlockX).toDouble(),
        top: (snakeSize * snakeBlockY).toDouble(),
        child: Text(
          "You win!",
          style: TextStyle(fontSize: 24.0, color: Colors.red[900]),
        ),
      ));
    }
    if (this.result == 2) {
      //player loses
      spritesList.add(Positioned(
        left: monsterBlockX > this.numOfBlocks / 2
            ? (snakeSize * snakeBlockX).toDouble() - 100
            : (snakeSize * snakeBlockX).toDouble(),
        top: (snakeSize * snakeBlockY).toDouble(),
        child: Text(
          "You Lose!",
          style: TextStyle(fontSize: 24.0, color: Colors.green[700]),
          textAlign: monsterBlockX > this.numOfBlocks / 2
              ? TextAlign.right
              : TextAlign.left,
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
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(child: Text("slow"), value: "slow"),
                PopupMenuItem(child: Text("medium"), value: "medium"),
                PopupMenuItem(child: Text("fast"), value: "fast"),
              ];
            },
            onSelected: (Object object) {
              if (object == 'slow') {
                this.monsterUpdateInterval =
                    Duration(milliseconds: this.slowModeInterval[0]);
                this.snakeNormalInterval =
                    Duration(milliseconds: this.slowModeInterval[1]);
                this.snakeEatingInterval =
                    Duration(milliseconds: this.slowModeInterval[2]);
              } else if (object == 'medium') {
                this.monsterUpdateInterval =
                    Duration(milliseconds: this.mediumModeInterval[0]);
                this.snakeNormalInterval =
                    Duration(milliseconds: this.mediumModeInterval[1]);
                this.snakeEatingInterval =
                    Duration(milliseconds: this.mediumModeInterval[2]);
              } else if (object == 'fast') {
                this.monsterUpdateInterval =
                    Duration(milliseconds: this.fastModeInterval[0]);
                this.snakeNormalInterval =
                    Duration(milliseconds: this.fastModeInterval[1]);
                this.snakeEatingInterval =
                    Duration(milliseconds: this.fastModeInterval[2]);
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.all(5.0),
            padding: const EdgeInsets.all(3.0),
            decoration: BoxDecoration(border: Border.all(color: Colors.black)),
            height: 48,
            //width: ,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(width: 8),
                Text(
                    isFirstTime
                        ? "Time:  0 sec"
                        : sprintf("Time: %3d sec", [
                            this
                                .gameCurrentTime
                                .difference(this.gameStartTime)
                                .inSeconds
                          ]),
                    style: TextStyle(fontSize: 18)),
                Text(
                    sprintf("Heading: %s",
                        [this.intHeadingMapping[this.snakeHeading]]),
                    style: TextStyle(fontSize: 18)),
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
