import 'package:args/args.dart';
import 'package:chanceshfit/app.dart';
import 'package:chanceshfit/chacneshift_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

void main(List<String> arguments) {
  Logger log = Logger('chanceshift');
  var parser = ArgParser()
    ..addFlag('enable-dual-screen', negatable: false, defaultsTo: false);

  var results = parser.parse(arguments);
  bool enableFeature = results['enable-dual-screen'];

  if (enableFeature) {
    log.info("Dual screen feature enabled");
  }

  if (kDebugMode) {
    final game = ChanceShiftGame(); // Modify this line
    runApp(GameWidget(game: game));
  } else {
    runApp(MyApp(log: log));
  }
}
