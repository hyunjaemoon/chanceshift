import 'package:flutter/material.dart';

class CreditScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Credits'),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game Creator:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Hyun Jae Moon',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blueGrey,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Notice:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'This app was built using the Flutter framework, which is an open-source UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}