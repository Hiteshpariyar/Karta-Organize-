import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Official Google "G" logo rendered via a pixel-perfect, resolution-independent CustomPainter.
///
/// Features the 4 official Google brand colors:
/// - Red: #EA4335
/// - Yellow: #FBBC05
/// - Green: #34A853
/// - Blue: #4285F4
class OfficialGoogleLogo extends StatelessWidget {
  final double size;

  const OfficialGoogleLogo({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double s = math.min(width, height);
    final Offset center = Offset(width / 2, height / 2);

    // Official Google Brand Colors
    const Color blue = Color(0xFF4285F4);
    const Color red = Color(0xFFEA4335);
    const Color yellow = Color(0xFFFBBC05);
    const Color green = Color(0xFF34A853);

    final double strokeWidth = s * 0.20;
    final double outerRadius = (s - strokeWidth) / 2;
    final Rect arcRect = Rect.fromCircle(center: center, radius: outerRadius);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // 1. Red top arc (approx 200° to 315°)
    paint.color = red;
    canvas.drawArc(arcRect, -math.pi * 0.85, math.pi * 0.60, false, paint);

    // 2. Yellow left arc (approx 120° to 205°)
    paint.color = yellow;
    canvas.drawArc(arcRect, -math.pi * 1.35, math.pi * 0.50, false, paint);

    // 3. Green bottom arc (approx 35° to 125°)
    paint.color = green;
    canvas.drawArc(arcRect, math.pi * 0.20, math.pi * 0.55, false, paint);

    // 4. Blue right arc & crossbar
    paint.color = blue;
    // Blue arc (approx -30° to 35°)
    canvas.drawArc(arcRect, -math.pi * 0.25, math.pi * 0.45, false, paint);

    // Blue horizontal crossbar
    final Paint barPaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;

    final Rect barRect = Rect.fromLTWH(
      center.dx - strokeWidth * 0.1,
      center.dy - strokeWidth / 2,
      outerRadius + strokeWidth / 2 + strokeWidth * 0.1,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

