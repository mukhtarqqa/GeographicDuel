import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const AppLogo({
    super.key,
    this.size = 72,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xffffffff),
            Color(0xfff3f7f5),
          ],
        ),
        border: Border.all(color: AtlasColors.gold.withValues(alpha: 0.8), width: size * 0.035),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AtlasColors.green.withValues(alpha: 0.18),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.08),
                ),
                BoxShadow(
                  color: AtlasColors.gold.withValues(alpha: 0.20),
                  blurRadius: size * 0.15,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: _CompassLogoPainter(),
        ),
      ),
    );
  }
}

class _CompassLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Grid Latitude and Longitude Circles
    final gridPaint = Paint()
      ..color = AtlasColors.green.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.015;

    canvas.drawCircle(center, radius * 0.72, gridPaint);
    canvas.drawCircle(center, radius * 0.45, gridPaint);

    // Meridian cross lines
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.85),
      Offset(center.dx, center.dy + radius * 0.85),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.85, center.dy),
      Offset(center.dx + radius * 0.85, center.dy),
      gridPaint,
    );

    // 2. Compass Rose Points
    void drawNeedle(double angle, double length, double width, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final path = Path();
      final rad = angle * math.pi / 180;
      final tipX = center.dx + length * math.sin(rad);
      final tipY = center.dy - length * math.cos(rad);

      final leftRad = (angle - 90) * math.pi / 180;
      final rightRad = (angle + 90) * math.pi / 180;

      final p1X = center.dx + width * math.sin(leftRad);
      final p1Y = center.dy - width * math.cos(leftRad);

      final p2X = center.dx + width * math.sin(rightRad);
      final p2Y = center.dy - width * math.cos(rightRad);

      path.moveTo(center.dx, center.dy);
      path.lineTo(p1X, p1Y);
      path.lineTo(tipX, tipY);
      path.close();
      canvas.drawPath(path, paint);

      // Darker shading on second half for 3D metallic feel
      final shadePaint = Paint()
        ..color = color == AtlasColors.green ? const Color(0xff1d4032) : const Color(0xff997300)
        ..style = PaintingStyle.fill;

      final path2 = Path();
      path2.moveTo(center.dx, center.dy);
      path2.lineTo(p2X, p2Y);
      path2.lineTo(tipX, tipY);
      path2.close();
      canvas.drawPath(path2, shadePaint);
    }

    final needleLength = radius * 0.76;
    final needleBase = size.width * 0.09;

    // Secondary points (NE, SE, SW, NW)
    drawNeedle(45, needleLength * 0.60, needleBase * 0.65, AtlasColors.gold.withValues(alpha: 0.7));
    drawNeedle(135, needleLength * 0.60, needleBase * 0.65, AtlasColors.gold.withValues(alpha: 0.7));
    drawNeedle(225, needleLength * 0.60, needleBase * 0.65, AtlasColors.gold.withValues(alpha: 0.7));
    drawNeedle(315, needleLength * 0.60, needleBase * 0.65, AtlasColors.gold.withValues(alpha: 0.7));

    // South needle
    drawNeedle(180, needleLength * 0.85, needleBase, AtlasColors.rust);
    // East & West needles
    drawNeedle(90, needleLength * 0.80, needleBase, AtlasColors.muted);
    drawNeedle(270, needleLength * 0.80, needleBase, AtlasColors.muted);
    // North needle (Primary Emerald pointer)
    drawNeedle(0, needleLength, needleBase, AtlasColors.green);

    // 3. Central Golden Core Pivot
    final corePaint = Paint()
      ..color = AtlasColors.gold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.08, corePaint);

    final innerCorePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.04, innerCorePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
