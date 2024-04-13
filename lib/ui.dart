import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PushButton extends StatefulWidget {
  final VoidCallback onPressed;

  const PushButton({super.key, required this.onPressed});

  @override
  // ignore: library_private_types_in_public_api
  _PushButtonState createState() => _PushButtonState();
}

class _PushButtonState extends State<PushButton> {
  bool isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => isPressed = false);
  }

  void _onTapCancel() {
    setState(() => isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: Transform.scale(
        scale: isPressed ? 0.95 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFF4B79A1),
                Color(0xFF283E51),
              ],
            ),
            boxShadow: isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      offset: const Offset(0, 4),
                      blurRadius: 4.0,
                    ),
                  ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.redAccent,
                width: 4.0,
                style: BorderStyle.solid,
              ),
            ),
            child: const Center(
              child: Text(
                'Attack',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatusBar extends StatefulWidget {
  final int value;
  final int maxValue;
  final Color color;
  final double width;
  final double height;

  const StatusBar({
    super.key,
    required this.value,
    required this.maxValue,
    this.color = Colors.green,
    this.width = 200,
    this.height = 30,
  });

  @override
  // ignore: library_private_types_in_public_api
  _StatusBarState createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(
          milliseconds: 300), // Animation duration of 300 milliseconds
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.value / widget.maxValue,
      end: widget.value / widget.maxValue,
    ).animate(_animationController);
  }

  @override
  void didUpdateWidget(covariant StatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value / widget.maxValue,
      ).animate(_animationController)
        ..addListener(() {
          setState(
              () {}); // Calls setState every time the animation value changes
        });
      _animationController
          .reset(); // Reset the controller and then start the animation
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _StatusBarPainter(
          valuePercentage: _animation.value,
          color: widget.color,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController
        .dispose(); // Clean up the controller when the widget is disposed
    super.dispose();
  }
}

class _StatusBarPainter extends CustomPainter {
  final double valuePercentage;
  final Color color;

  _StatusBarPainter({required this.valuePercentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()..color = Colors.black;
    // Background
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    Paint valuePaint = Paint()..color = color;
    // Health bar
    double valueWidth =
        size.width * valuePercentage; // Width of the health portion
    canvas.drawRect(Rect.fromLTWH(0, 0, valueWidth, size.height), valuePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

class SwordIconsRow extends StatelessWidget {
  final int numIcons;

  const SwordIconsRow({super.key, required this.numIcons});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(numIcons, (index) => Icon(MdiIcons.sword)),
    );
  }
}
