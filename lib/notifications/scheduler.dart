import 'dart:io' show Platform;

import 'package:emberday/domain/models.dart';
import 'package:emberday/notifications/channels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationScheduler {
  NotificationScheduler._();
  static final instance = NotificationScheduler._();

  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;
  var _supported = true;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: ios,
          linux: linux,
        ),
      );
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(reminderChannel());
      }
      _supported = true;
    } on Object {
      // Desktop/web without a working plugin still runs the app offline.
      _supported = false;
    }
    _ready = true;
  }

  Future<void> apply(List<PlannedNotification> plan) async {
    await init();
    if (!_supported) return;
    try {
      await _plugin.cancelAll();
      for (final n in plan) {
        await _plugin.zonedSchedule(
          id: n.id,
          title: n.title,
          body: n.body,
          scheduledDate: tz.TZDateTime.from(n.fireAt, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              reminderChannelId,
              reminderChannelName,
              channelDescription: reminderChannelDescription,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: const DarwinNotificationDetails(),
            linux: const LinuxNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } on Object {
      // Scheduling failures must not block check-in flows.
    }
  }

  Future<void> scheduleTestIn(Duration delay) async {
    await init();
    if (!_supported) return;
    final when = tz.TZDateTime.now(tz.local).add(delay);
    await _plugin.zonedSchedule(
      id: 999001,
      title: 'Emberday',
      body: 'Test reminder',
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          reminderChannelId,
          reminderChannelName,
          channelDescription: reminderChannelDescription,
        ),
        iOS: const DarwinNotificationDetails(),
        linux: const LinuxNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
