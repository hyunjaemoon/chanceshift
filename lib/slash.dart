import 'package:flutter/material.dart';
import 'package:gif/gif.dart';

class SlashAnimation extends StatefulWidget {
  const SlashAnimation({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SlashAnimationState createState() => _SlashAnimationState();
}

class _SlashAnimationState extends State<SlashAnimation>
    with SingleTickerProviderStateMixin {
  late GifController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        GifController(vsync: this); // Now 'this' is a valid TickerProvider
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // Set the background color to transparent
      body: Center(
        child: Gif(
          image: const AssetImage("images/slash.gif"),
          controller: _controller,
          autostart: Autostart.no,
          placeholder: (context) => const Text('Loading...'),
          onFetchCompleted: () {
            _controller.reset();
            _controller.forward();
          },
        ),
      ),
    );
  }
}
