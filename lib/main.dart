import 'package:args/args.dart';
import 'package:chanceshfit/app.dart';
import 'package:chanceshfit/dual_app.dart';
import 'package:flutter/material.dart';

void main(List<String> arguments) {
  var parser = ArgParser()
    ..addFlag('enable-dual-screen', negatable: false, defaultsTo: false);

  var results = parser.parse(arguments);
  bool enableFeature = results['enable-dual-screen'];

  if (enableFeature) {
    runApp(const MyDualApp());
  } else {
    runApp(const MyApp());
  }
}
