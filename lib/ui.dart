import 'package:flutter/material.dart';

class PushButton extends StatefulWidget {
  final VoidCallback onPressed;

  PushButton({required this.onPressed});

  @override
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
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
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
                      offset: Offset(0, 4),
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
            child: Center(
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
    Key? key,
    required this.value,
    required this.maxValue,
    this.color = Colors.green,
    this.width = 200,
    this.height = 30,
  }) : super(key: key);

  @override
  _StatusBarState createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _StatusBarPainter(
          valuePercentage: widget.value / widget.maxValue,
          color: widget.color,
        ),
      ),
    );
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
