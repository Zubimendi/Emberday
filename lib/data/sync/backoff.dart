import 'dart:math';

/// Exponential backoff with ±20% jitter. Cap 300s. Base 2s.
Duration nextBackoff(int attempts, {Random? random}) {
  final rand = random ?? Random();
  final exp = min(300.0, 2.0 * pow(2, attempts).toDouble());
  final jitter = 1 + ((rand.nextDouble() * 0.4) - 0.2);
  final seconds = (exp * jitter).clamp(1.0, 300.0);
  return Duration(milliseconds: (seconds * 1000).round());
}
