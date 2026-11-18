import 'package:flutter/material.dart';

class WeeklyBarsPainter extends CustomPainter {
  WeeklyBarsPainter({
    required this.values,
    required this.barColor,
    required this.highlightColor,
    required this.highlightIndex,
  });

  final List<double> values; // 0..1
  final Color barColor;
  final Color highlightColor;
  final int highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final n = values.length;
    final gap = size.width * 0.04;
    final barW = (size.width - gap * (n - 1)) / n;
    for (var i = 0; i < n; i++) {
      final h = (values[i].clamp(0.0, 1.0)) * size.height;
      final x = i * (barW + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barW, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = i == highlightIndex ? highlightColor : barColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyBarsPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.highlightIndex != highlightIndex;
}
