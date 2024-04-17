import 'package:chanceshfit/credit_screen.dart';
import 'package:chanceshfit/game_interface.dart';
import 'package:chanceshfit/tutorial.dart';
import 'package:flutter/material.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _idleAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _idleAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _idleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.easeInOutCirc,
      ),
    );
    _idleAnimation = Tween<double>(begin: 0, end: 20).animate(CurvedAnimation(
        parent: _idleAnimationController, curve: Curves.easeInOut));

    // Start the scale animation
    _scaleAnimationController.forward().whenComplete(() {
      // Start the idle animation in a loop after the scale animation completes
      _idleAnimationController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _scaleAnimationController.dispose();
    _idleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 40),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge(
                  [_scaleAnimationController, _idleAnimationController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _idleAnimation.value),
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'images/game_logo.png',
                width: 500,
                height: 500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Handle Start button press
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        FadeTransition(
                      opacity: animation,
                      child: const GameInterface(),
                    ),
                  ),
                );
              },
              child: const Text(
                'Demo Game',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Handle Credits button press
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        FadeTransition(
                      opacity: animation,
                      child: const TutorialWidget(),
                    ),
                  ),
                );
              },
              child: const Text(
                'Tutorial',
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Handle Credits button press
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        FadeTransition(
                      opacity: animation,
                      child: const CreditScreen(),
                    ),
                  ),
                );
              },
              child: const Text(
                'Credits',
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
