import 'dart:math' as math;

import 'package:emberday/ui/tokens.dart';
import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.done,
    required this.total,
    this.size = 40,
  });

  final int done;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final progress = total == 0 ? 0.0 : done / total;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: '$done of $total done',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: reduceMotion ? progress : 0, end: progress),
              duration: Duration(milliseconds: reduceMotion ? 0 : 250),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: _RingPainter(
                    progress: value,
                    track: t.border,
                    fill: t.primary,
                  ),
                );
              },
            ),
            Text(
              '$done/$total',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: t.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.track != track ||
      oldDelegate.fill != fill;
}
