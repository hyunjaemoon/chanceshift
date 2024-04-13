import 'package:chanceshfit/menu_screen.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChanceShift',
      theme: ThemeData(
        fontFamily: 'VT323',
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
      ),
      home: const MenuScreen(),
    );
  }
}
