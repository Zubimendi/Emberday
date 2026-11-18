import 'package:emberday/domain/models.dart';
import 'package:flutter/material.dart';

class HeatmapPainter extends CustomPainter {
  HeatmapPainter({
    required this.cells,
    required this.doneColor,
    required this.missedColor,
    required this.skippedColor,
    required this.emptyColor,
    required this.futureColor,
  });

  final List<DayClass?> cells; // 7 cols x rows, null = padding
  final Color doneColor;
  final Color missedColor;
  final Color skippedColor;
  final Color emptyColor;
  final Color futureColor;

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 7;
    final rows = (cells.length / cols).ceil();
    if (rows == 0) return;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final radius = Radius.circular(cellW * 0.2);

    for (var i = 0; i < cells.length; i++) {
      final c = cells[i];
      if (c == null) continue;
      final col = i % cols;
      final row = i ~/ cols;
      final rect = Rect.fromLTWH(
        col * cellW + 2,
        row * cellH + 2,
        cellW - 4,
        cellH - 4,
      );
      final rrect = RRect.fromRectAndRadius(rect, radius);
      switch (c) {
        case DayClass.done:
          canvas.drawRRect(rrect, Paint()..color = doneColor);
        case DayClass.skipped:
          final paint = Paint()
            ..color = skippedColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawRRect(rrect, paint);
          canvas.drawLine(
            Offset(rect.left + 4, rect.center.dy),
            Offset(rect.right - 4, rect.center.dy),
            paint,
          );
        case DayClass.missed:
          canvas.drawCircle(
            rect.center,
            rect.shortestSide * 0.2,
            Paint()
              ..color = missedColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        case DayClass.pending:
          canvas.drawRRect(
            rrect,
            Paint()
              ..color = emptyColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        case DayClass.neutral:
          canvas.drawRRect(rrect, Paint()..color = futureColor.withValues(alpha: 0.15));
      }
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) =>
      oldDelegate.cells != cells ||
      oldDelegate.doneColor != doneColor;
}
