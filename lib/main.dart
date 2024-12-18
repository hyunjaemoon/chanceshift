import 'package:args/args.dart';
import 'package:chanceshfit/app.dart';
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

  runApp(MyApp(log: log));
}
