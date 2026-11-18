import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

final _rand = Random.secure();

/// 15-char lowercase alphanumeric ID (PocketBase-compatible).
String newId() {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final buf = StringBuffer();
  for (var i = 0; i < 15; i++) {
    buf.write(alphabet[_rand.nextInt(alphabet.length)]);
  }
  return buf.toString();
}

/// Deterministic check-in id: `ci` + first 13 hex of SHA-256(habitId:date).
String checkInId(String habitId, String localDate) {
  final digest = sha256.convert(utf8.encode('$habitId:$localDate'));
  return 'ci${digest.toString().substring(0, 13)}';
}

/// Deterministic 31-bit notification id from habitId|date.
int notificationId(String habitId, String localDate) {
  final digest = sha256.convert(utf8.encode('$habitId|$localDate'));
  final bytes = digest.bytes;
  var value = 0;
  for (var i = 0; i < 4; i++) {
    value = (value << 8) | bytes[i];
  }
  return value & 0x7fffffff;
}
