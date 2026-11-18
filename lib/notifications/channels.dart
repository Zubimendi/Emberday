import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const reminderChannelId = 'emberday_reminders';
const reminderChannelName = 'Habit reminders';
const reminderChannelDescription = 'Reminders for habits you asked for';

AndroidNotificationChannel reminderChannel() {
  return const AndroidNotificationChannel(
    reminderChannelId,
    reminderChannelName,
    description: reminderChannelDescription,
    importance: Importance.defaultImportance,
  );
}
