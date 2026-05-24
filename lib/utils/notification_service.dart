import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/models.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ─── Schedule notification for a Task ───────────────────────────────────────
  static Future<void> scheduleTaskNotification(Task task) async {
    if (!task.notificationsEnabled || !task.isScheduled) return;

    final date = task.scheduledDate!;
    final start = task.startMinute!;
    final reminderAt = DateTime(
      date.year, date.month, date.day,
      start ~/ 60, start % 60,
    ).subtract(Duration(minutes: task.reminderMinutes));

    if (reminderAt.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(reminderAt, tz.local);
    await _plugin.zonedSchedule(
      _taskNotifId(task.id),
      '⏰ ${task.title}',
      _taskBody(task),
      tzTime,
      _details('Tasks'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─── Schedule recurring notification for a TimetableEntry ───────────────────
  static Future<void> scheduleEntryNotification(TimetableEntry entry) async {
    if (!entry.notificationsEnabled) return;
    // We schedule for the next occurrence of this weekday
    final now = DateTime.now();
    var next = _nextWeekday(now, entry.weekday);
    final notifTime = DateTime(
      next.year, next.month, next.day,
      entry.startMinute ~/ 60, entry.startMinute % 60,
    ).subtract(Duration(minutes: entry.reminderMinutes));

    if (notifTime.isBefore(now)) {
      next = _nextWeekday(now.add(const Duration(days: 1)), entry.weekday);
    }

    final tzTime = tz.TZDateTime.from(
      DateTime(next.year, next.month, next.day,
          entry.startMinute ~/ 60, entry.startMinute % 60)
          .subtract(Duration(minutes: entry.reminderMinutes)),
      tz.local,
    );

    await _plugin.zonedSchedule(
      _entryNotifId(entry.id),
      '📅 ${entry.title}',
      'Starts in ${entry.reminderMinutes} min${entry.location != null ? ' · ${entry.location}' : ''}',
      tzTime,
      _details('Timetable'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─── Daily digest ────────────────────────────────────────────────────────────
  static Future<void> scheduleDailyDigest({
    required int hour,
    required int minute,
    required String body,
  }) async {
    final now = DateTime.now();
    var digest = DateTime(now.year, now.month, now.day, hour, minute);
    if (digest.isBefore(now)) digest = digest.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      9999,
      '📋 Your day ahead',
      body,
      tz.TZDateTime.from(digest, tz.local),
      _details('Daily digest'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelTask(String taskId) =>
      _plugin.cancel(_taskNotifId(taskId));

  static Future<void> cancelEntry(String entryId) =>
      _plugin.cancel(_entryNotifId(entryId));

  static Future<void> cancelAll() => _plugin.cancelAll();

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  static NotificationDetails _details(String channel) => NotificationDetails(
        android: AndroidNotificationDetails(
          channel.toLowerCase().replaceAll(' ', '_'),
          channel,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  static String _taskBody(Task task) {
    final parts = <String>[];
    if (task.startMinute != null) {
      final h = task.startMinute! ~/ 60;
      final m = task.startMinute! % 60;
      parts.add('${_fmt(h)}:${_fmt(m)}');
    }
    if (task.description?.isNotEmpty == true) parts.add(task.description!);
    return parts.join(' · ').ifEmpty('Upcoming task');
  }

  static String _fmt(int n) => n.toString().padLeft(2, '0');

  static int _taskNotifId(String id) => id.hashCode.abs() % 100000;
  static int _entryNotifId(String id) => (id.hashCode.abs() % 100000) + 100000;

  static DateTime _nextWeekday(DateTime from, int weekday) {
    var d = from;
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }
}

extension _StrExt on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
