/// Injected time source. Never call [DateTime.now] outside this file.
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Mutable clock for tests and the P2 dev override.
class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void setNow(DateTime value) => _now = value;

  void advance(Duration by) => _now = _now.add(by);
}
