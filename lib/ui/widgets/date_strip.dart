import 'package:emberday/core/dates.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:emberday/ui/widgets/press.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateStrip extends StatelessWidget {
  const DateStrip({
    super.key,
    required this.selectedDate,
    required this.todayDate,
    required this.onSelect,
  });

  final String selectedDate;
  final String todayDate;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    final dates = lastNDates(todayDate, 7);
    final dayFmt = DateFormat('E');
    final numFmt = DateFormat('d');

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => SizedBox(width: t.spaceSm),
        itemBuilder: (context, i) {
          final ymd = dates[i];
          final dt = parseLocalDate(ymd);
          final selected = ymd == selectedDate;
          return Semantics(
            selected: selected,
            button: true,
            label: DateFormat('EEEE d MMMM').format(dt),
            child: Press(
              onPressed: () => onSelect(ymd),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48,
                padding: EdgeInsets.symmetric(vertical: t.spaceSm),
                decoration: BoxDecoration(
                  color: selected ? t.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(t.radiusSm),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayFmt.format(dt).substring(0, 1),
                      style: theme.labelLarge?.copyWith(
                        color: selected ? t.onPrimary : t.textFaint,
                      ),
                    ),
                    Text(
                      numFmt.format(dt),
                      style: theme.labelSmall?.copyWith(
                        color: selected ? t.onPrimary : t.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
