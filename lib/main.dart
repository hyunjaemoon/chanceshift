import 'package:args/args.dart';
import 'package:chanceshfit/dual_main.dart';
import 'package:chanceshfit/game_interface.dart';
import 'package:flutter/material.dart';

void main(List<String> arguments) {
  var parser = ArgParser()
    ..addFlag('enable-dual-screen', negatable: false, defaultsTo: false);

  var results = parser.parse(arguments);
  bool enableFeature = results['enable-dual-screen'];

  if (enableFeature) {
    runApp(MyDualApp());
  } else {
    runApp(MyApp());
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChanceShift',
      theme: ThemeData(
        fontFamily: 'VT323',
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
      ),
      home: GameInterface(),
    );
  }
}
