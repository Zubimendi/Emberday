// Local calendar date helpers. Dates are always `YYYY-MM-DD` strings.

String formatLocalDate(DateTime dt) {
  final local = DateTime(dt.year, dt.month, dt.day);
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime parseLocalDate(String ymd) {
  final parts = ymd.split('-');
  if (parts.length != 3) {
    throw FormatException('Invalid local date: $ymd');
  }
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final d = int.parse(parts[2]);
  return DateTime(y, m, d);
}

/// Effective local date: calendar date of (now minus rollover hours).
String effectiveLocalDate(DateTime now, int rolloverHours) {
  final shifted = now.subtract(Duration(hours: rolloverHours));
  return formatLocalDate(shifted);
}

DateTime effectiveDateTime(DateTime now, int rolloverHours) {
  return parseLocalDate(effectiveLocalDate(now, rolloverHours));
}

/// Monday = 1 … Sunday = 7 (ISO).
int weekdayMon1(DateTime date) => date.weekday;

/// Bit 0 = Monday … bit 6 = Sunday.
int weekdayBit(DateTime date) => 1 << (date.weekday - 1);

bool maskContainsWeekday(int mask, DateTime date) =>
    (mask & weekdayBit(date)) != 0;

/// Week key `YYYY-Www` for Monday-start weeks.
String weekKey(DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  final thursday = monday.add(const Duration(days: 3));
  final yearStart = DateTime(thursday.year);
  final week =
      ((thursday.difference(yearStart).inDays) / 7).floor() + 1;
  final y = thursday.year.toString().padLeft(4, '0');
  final w = week.toString().padLeft(2, '0');
  return '$y-W$w';
}

DateTime mondayOfWeek(DateTime date) =>
    DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));

DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

List<String> lastNDates(String endYmd, int n) {
  final end = parseLocalDate(endYmd);
  return List.generate(n, (i) => formatLocalDate(addDays(end, -(n - 1 - i))));
}

int daysBetween(String a, String b) =>
    parseLocalDate(b).difference(parseLocalDate(a)).inDays;

String addDaysYmd(String ymd, int days) =>
    formatLocalDate(addDays(parseLocalDate(ymd), days));

bool isValidYmd(String ymd) {
  try {
    final dt = parseLocalDate(ymd);
    return formatLocalDate(dt) == ymd;
  } on FormatException {
    return false;
  } on Object {
    return false;
  }
}
