import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

const _kTimetables = 'timetables';
const _kEntries = 'entries';
const _kTasks = 'tasks';
const _kColumns = 'planning_columns';
const _kSettings = 'settings';

class DbService {
  static late Box<Timetable> timetablesBox;
  static late Box<TimetableEntry> entriesBox;
  static late Box<Task> tasksBox;
  static late Box<PlanningColumn> columnsBox;
  static late Box<AppSettings> settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive
      ..registerAdapter(TimetableAdapter())
      ..registerAdapter(TimetableEntryAdapter())
      ..registerAdapter(TaskAdapter())
      ..registerAdapter(PlanningColumnAdapter())
      ..registerAdapter(AppSettingsAdapter());

    timetablesBox = await Hive.openBox<Timetable>(_kTimetables);
    entriesBox = await Hive.openBox<TimetableEntry>(_kEntries);
    tasksBox = await Hive.openBox<Task>(_kTasks);
    columnsBox = await Hive.openBox<PlanningColumn>(_kColumns);
    settingsBox = await Hive.openBox<AppSettings>(_kSettings);

    await _seedDefaults();
  }

  static Future<void> _seedDefaults() async {
    if (timetablesBox.isEmpty) {
      final personal = Timetable(
        id: 'personal',
        name: 'Personal',
        colorValue: const Color(0xFF7F77DD).value,
        isBuiltIn: true,
      );
      final school = Timetable(
        id: 'school',
        name: 'School',
        colorValue: const Color(0xFF1D9E75).value,
        isBuiltIn: true,
      );
      await timetablesBox.put(personal.id, personal);
      await timetablesBox.put(school.id, school);
    }

    if (columnsBox.isEmpty) {
      final inbox = PlanningColumn(
        id: 'inbox',
        title: 'Unscheduled inbox',
        colorValue: const Color(0xFFBA7517).value,
        sortOrder: 0,
        isInbox: true,
      );
      final thisWeek = PlanningColumn(
        id: 'this_week',
        title: 'This week',
        colorValue: const Color(0xFF7F77DD).value,
        sortOrder: 1,
      );
      final nextWeek = PlanningColumn(
        id: 'next_week',
        title: 'Next week',
        colorValue: const Color(0xFF1D9E75).value,
        sortOrder: 2,
      );
      await columnsBox.put(inbox.id, inbox);
      await columnsBox.put(thisWeek.id, thisWeek);
      await columnsBox.put(nextWeek.id, nextWeek);
    }

    if (settingsBox.isEmpty) {
      await settingsBox.put('settings', AppSettings());
    }

    // Seed sample school timetable entries
    if (entriesBox.isEmpty) {
      final sampleEntries = [
        TimetableEntry(timetableId: 'school', title: 'Mathematics', weekday: 1, startMinute: 480, endMinute: 570, colorValue: const Color(0xFF1D9E75).value, location: 'Room 204'),
        TimetableEntry(timetableId: 'school', title: 'Physics', weekday: 1, startMinute: 600, endMinute: 690, colorValue: const Color(0xFF1D9E75).value, location: 'Lab B'),
        TimetableEntry(timetableId: 'school', title: 'English', weekday: 2, startMinute: 480, endMinute: 570, colorValue: const Color(0xFF1D9E75).value, location: 'Room 101'),
        TimetableEntry(timetableId: 'school', title: 'Chemistry', weekday: 2, startMinute: 600, endMinute: 690, colorValue: const Color(0xFF1D9E75).value, location: 'Lab A'),
        TimetableEntry(timetableId: 'school', title: 'Mathematics', weekday: 3, startMinute: 480, endMinute: 570, colorValue: const Color(0xFF1D9E75).value, location: 'Room 204'),
        TimetableEntry(timetableId: 'personal', title: 'Gym session', weekday: 1, startMinute: 360, endMinute: 450, colorValue: const Color(0xFF7F77DD).value),
        TimetableEntry(timetableId: 'personal', title: 'Evening reading', weekday: 1, startMinute: 1260, endMinute: 1320, colorValue: const Color(0xFF7F77DD).value),
      ];
      for (final e in sampleEntries) {
        await entriesBox.put(e.id, e);
      }
    }
  }

  static AppSettings get settings =>
      settingsBox.get('settings') ?? AppSettings();

  static Future<void> saveSettings(AppSettings s) =>
      settingsBox.put('settings', s);
}
