import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'models.g.dart';

// ─── Timetable ────────────────────────────────────────────────────────────────

@HiveType(typeId: 0)
class Timetable extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String name;
  @HiveField(2) late int colorValue;
  @HiveField(3) late bool isActive;
  @HiveField(4) late bool isBuiltIn; // personal / school can't be deleted

  Timetable({
    String? id,
    required this.name,
    required this.colorValue,
    this.isActive = true,
    this.isBuiltIn = false,
  }) {
    this.id = id ?? const Uuid().v4();
  }

  Color get color => Color(colorValue);
  Timetable copyWith({String? name, int? colorValue, bool? isActive}) => Timetable(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        isActive: isActive ?? this.isActive,
        isBuiltIn: isBuiltIn,
      );
}

// ─── TimetableEntry (recurring class / fixed block) ──────────────────────────

@HiveType(typeId: 1)
class TimetableEntry extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String timetableId;
  @HiveField(2) late String title;
  @HiveField(3) late String? location;
  @HiveField(4) late String? notes;
  @HiveField(5) late int weekday; // 1=Mon … 7=Sun
  @HiveField(6) late int startMinute; // minutes since midnight
  @HiveField(7) late int endMinute;
  @HiveField(8) late int colorValue;
  @HiveField(9) late bool notificationsEnabled;
  @HiveField(10) late int reminderMinutes; // lead time

  TimetableEntry({
    String? id,
    required this.timetableId,
    required this.title,
    this.location,
    this.notes,
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
    required this.colorValue,
    this.notificationsEnabled = true,
    this.reminderMinutes = 15,
  }) {
    this.id = id ?? const Uuid().v4();
  }

  TimeOfDay get startTime => TimeOfDay(hour: startMinute ~/ 60, minute: startMinute % 60);
  TimeOfDay get endTime => TimeOfDay(hour: endMinute ~/ 60, minute: endMinute % 60);
  Duration get duration => Duration(minutes: endMinute - startMinute);
  Color get color => Color(colorValue);
}

// ─── Task (timed todo) ───────────────────────────────────────────────────────

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String title;
  @HiveField(2) late String? description;
  @HiveField(3) late String? timetableId;
  @HiveField(4) late DateTime? scheduledDate;
  @HiveField(5) late int? startMinute; // null = unscheduled
  @HiveField(6) late int? endMinute;
  @HiveField(7) late int priorityIndex; // 0=low 1=med 2=high
  @HiveField(8) late bool isCompleted;
  @HiveField(9) late bool notificationsEnabled;
  @HiveField(10) late int reminderMinutes;
  @HiveField(11) late String? planningColumn; // planning board column id
  @HiveField(12) late int sortOrder;
  @HiveField(13) late DateTime createdAt;

  Task({
    String? id,
    required this.title,
    this.description,
    this.timetableId,
    this.scheduledDate,
    this.startMinute,
    this.endMinute,
    this.priorityIndex = 1,
    this.isCompleted = false,
    this.notificationsEnabled = true,
    this.reminderMinutes = 15,
    this.planningColumn,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
  }

  bool get isScheduled => scheduledDate != null && startMinute != null;
  bool get isUnscheduled => !isScheduled;

  Priority get priority => Priority.values[priorityIndex.clamp(0, 2)];

  TimeOfDay? get startTime => startMinute == null ? null : TimeOfDay(hour: startMinute! ~/ 60, minute: startMinute! % 60);
  TimeOfDay? get endTime => endMinute == null ? null : TimeOfDay(hour: endMinute! ~/ 60, minute: endMinute! % 60);

  Task copyWith({
    String? title, String? description, String? timetableId,
    DateTime? scheduledDate, int? startMinute, int? endMinute,
    int? priorityIndex, bool? isCompleted, bool? notificationsEnabled,
    int? reminderMinutes, String? planningColumn, int? sortOrder,
    bool clearSchedule = false, bool clearPlanningColumn = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      timetableId: timetableId ?? this.timetableId,
      scheduledDate: clearSchedule ? null : (scheduledDate ?? this.scheduledDate),
      startMinute: clearSchedule ? null : (startMinute ?? this.startMinute),
      endMinute: clearSchedule ? null : (endMinute ?? this.endMinute),
      priorityIndex: priorityIndex ?? this.priorityIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      planningColumn: clearPlanningColumn ? null : (planningColumn ?? this.planningColumn),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }
}

enum Priority { low, medium, high }

extension PriorityExt on Priority {
  String get label => ['Low', 'Medium', 'High'][index];
  Color get color => [Colors.green, Colors.orange, Colors.red][index];
  IconData get icon => [Icons.arrow_downward, Icons.remove, Icons.arrow_upward][index];
}

// ─── PlanningColumn ───────────────────────────────────────────────────────────

@HiveType(typeId: 3)
class PlanningColumn extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String title;
  @HiveField(2) late int colorValue;
  @HiveField(3) late int sortOrder;
  @HiveField(4) late bool isInbox; // the special "unassigned" column

  PlanningColumn({
    String? id,
    required this.title,
    required this.colorValue,
    this.sortOrder = 0,
    this.isInbox = false,
  }) {
    this.id = id ?? const Uuid().v4();
  }

  Color get color => Color(colorValue);
}

// ─── AppSettings ─────────────────────────────────────────────────────────────

@HiveType(typeId: 4)
class AppSettings extends HiveObject {
  @HiveField(0) late bool globalNotifications;
  @HiveField(1) late int defaultReminderMinutes;
  @HiveField(2) late bool dailyDigest;
  @HiveField(3) late int dailyDigestHour;
  @HiveField(4) late int dailyDigestMinute;
  @HiveField(5) late int startOfDay; // minutes since midnight
  @HiveField(6) late int endOfDay;
  @HiveField(7) late bool showWeekends;

  AppSettings({
    this.globalNotifications = true,
    this.defaultReminderMinutes = 15,
    this.dailyDigest = true,
    this.dailyDigestHour = 7,
    this.dailyDigestMinute = 0,
    this.startOfDay = 420, // 7am
    this.endOfDay = 1320,  // 10pm
    this.showWeekends = true,
  });
}
