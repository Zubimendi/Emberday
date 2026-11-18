import 'package:emberday/ui/tokens.dart';
import 'package:flutter/material.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({
    super.key,
    required this.count,
    this.atRisk = false,
  });

  final int count;
  final bool atRisk;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (count <= 0 && !atRisk) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          atRisk ? Icons.local_fire_department_outlined : Icons.local_fire_department,
          color: t.flame,
          size: 18,
        ),
        SizedBox(width: t.space4),
        Text(
          '$count',
          style: TextStyle(
            color: t.flame,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
