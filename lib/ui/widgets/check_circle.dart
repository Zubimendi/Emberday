import 'package:emberday/domain/models.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CheckCircle extends StatelessWidget {
  const CheckCircle({
    super.key,
    required this.status,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final CheckInStatus? status;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final size = t.checkSize;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget child;
    if (status == CheckInStatus.done) {
      child = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: t.success,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, color: t.surface),
      );
    } else if (status == CheckInStatus.skipped) {
      child = CustomPaint(
        size: Size(size, size),
        painter: _DashedCirclePainter(color: t.skipped),
        child: Center(
          child: Icon(Icons.remove, color: t.skipped, size: 22),
        ),
      );
    } else {
      child = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: t.border, width: 2),
        ),
      );
    }

    return Semantics(
      label: label,
      button: true,
      checked: status == CheckInStatus.done,
      enabled: enabled,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onTap();
              }
            : null,
        customBorder: const CircleBorder(),
        child: reduceMotion
            ? child
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: KeyedSubtree(
                  key: ValueKey(status?.name ?? 'pending'),
                  child: child,
                ),
              ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final radius = size.width / 2;
    final circumference = 2 * 3.1415926535 * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    final sweep = (dashWidth / circumference) * 2 * 3.1415926535;
    final gap = (dashSpace / circumference) * 2 * 3.1415926535;
    var start = 0.0;
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
