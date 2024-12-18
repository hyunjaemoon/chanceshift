import 'package:chanceshfit/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.log});

  final Logger log;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AudioPlayer _player;
  late final Logger log;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    log = widget.log;
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setAsset('audio/chanceshift_theme.mp3');
      await _player.setLoopMode(LoopMode.all);
    } on PlayerException catch (e) {
      log.info("Error loading audio source: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _toggleMusic() {
    setState(() {
      if (_player.playing) {
        _player.pause();
      } else {
        _player.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChanceShift',
      theme: ThemeData(
        fontFamily: 'VT323',
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
      ),
      home: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                  tooltip: 'Toggle music',
                  onPressed: _toggleMusic,
                  icon: Icon(_player.playing ? Icons.pause : Icons.play_arrow))
            ],
          ),
          body: const MenuScreen()),
    );
  }
}
