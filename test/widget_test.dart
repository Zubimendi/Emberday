import 'package:emberday/core/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatLocalDate pads', () {
    expect(formatLocalDate(DateTime(2026, 1, 2)), '2026-01-02');
  });
}
