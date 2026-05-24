import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../utils/db_service.dart';
import '../utils/notification_service.dart';

// ─── Timetables ───────────────────────────────────────────────────────────────

class TimetableNotifier extends StateNotifier<List<Timetable>> {
  TimetableNotifier() : super(DbService.timetablesBox.values.toList());

  void _sync() => state = DbService.timetablesBox.values.toList();

  Future<void> add(Timetable t) async {
    await DbService.timetablesBox.put(t.id, t);
    _sync();
  }

  Future<void> update(Timetable t) async {
    await DbService.timetablesBox.put(t.id, t);
    _sync();
  }

  Future<void> toggleActive(String id) async {
    final t = DbService.timetablesBox.get(id);
    if (t == null) return;
    await DbService.timetablesBox.put(id, t.copyWith(isActive: !t.isActive));
    _sync();
  }

  Future<void> remove(String id) async {
    final t = DbService.timetablesBox.get(id);
    if (t == null || t.isBuiltIn) return;
    await DbService.timetablesBox.delete(id);
    // remove all entries for this timetable
    final toDelete = DbService.entriesBox.values.where((e) => e.timetableId == id).map((e) => e.id).toList();
    for (final eid in toDelete) await DbService.entriesBox.delete(eid);
    _sync();
  }
}

final timetableProvider = StateNotifierProvider<TimetableNotifier, List<Timetable>>(
    (_) => TimetableNotifier());

// ─── TimetableEntries ─────────────────────────────────────────────────────────

class EntryNotifier extends StateNotifier<List<TimetableEntry>> {
  EntryNotifier() : super(DbService.entriesBox.values.toList());

  void _sync() => state = DbService.entriesBox.values.toList();

  Future<void> add(TimetableEntry e) async {
    await DbService.entriesBox.put(e.id, e);
    await NotificationService.scheduleEntryNotification(e);
    _sync();
  }

  Future<void> update(TimetableEntry e) async {
    await DbService.entriesBox.put(e.id, e);
    await NotificationService.cancelEntry(e.id);
    await NotificationService.scheduleEntryNotification(e);
    _sync();
  }

  Future<void> remove(String id) async {
    await DbService.entriesBox.delete(id);
    await NotificationService.cancelEntry(id);
    _sync();
  }

  List<TimetableEntry> forWeekday(int weekday, List<String> activeTimetableIds) =>
      state.where((e) => e.weekday == weekday && activeTimetableIds.contains(e.timetableId)).toList()
        ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
}

final entryProvider = StateNotifierProvider<EntryNotifier, List<TimetableEntry>>(
    (_) => EntryNotifier());

// ─── Tasks ────────────────────────────────────────────────────────────────────

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super(DbService.tasksBox.values.toList());

  void _sync() => state = DbService.tasksBox.values.toList();

  Future<void> add(Task t) async {
    await DbService.tasksBox.put(t.id, t);
    if (t.isScheduled) await NotificationService.scheduleTaskNotification(t);
    _sync();
  }

  Future<void> update(Task t) async {
    await DbService.tasksBox.put(t.id, t);
    await NotificationService.cancelTask(t.id);
    if (t.isScheduled && !t.isCompleted) {
      await NotificationService.scheduleTaskNotification(t);
    }
    _sync();
  }

  Future<void> toggleComplete(String id) async {
    final t = DbService.tasksBox.get(id);
    if (t == null) return;
    await update(t.copyWith(isCompleted: !t.isCompleted));
  }

  Future<void> remove(String id) async {
    await DbService.tasksBox.delete(id);
    await NotificationService.cancelTask(id);
    _sync();
  }

  Future<void> reorder(String id, String? newColumnId, int newSortOrder) async {
    final t = DbService.tasksBox.get(id);
    if (t == null) return;
    await update(t.copyWith(planningColumn: newColumnId, sortOrder: newSortOrder));
  }

  List<Task> forDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return state
        .where((t) => t.scheduledDate != null &&
            DateTime(t.scheduledDate!.year, t.scheduledDate!.month, t.scheduledDate!.day) == d)
        .toList()
      ..sort((a, b) => (a.startMinute ?? 9999).compareTo(b.startMinute ?? 9999));
  }

  List<Task> get unscheduled =>
      state.where((t) => t.isUnscheduled && !t.isCompleted).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<Task> inColumn(String columnId) =>
      state.where((t) => t.planningColumn == columnId).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}

final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>(
    (_) => TaskNotifier());

// ─── PlanningColumns ──────────────────────────────────────────────────────────

class ColumnNotifier extends StateNotifier<List<PlanningColumn>> {
  ColumnNotifier() : super(
    DbService.columnsBox.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  void _sync() {
    state = DbService.columnsBox.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> add(PlanningColumn c) async {
    await DbService.columnsBox.put(c.id, c);
    _sync();
  }

  Future<void> update(PlanningColumn c) async {
    await DbService.columnsBox.put(c.id, c);
    _sync();
  }

  Future<void> remove(String id) async {
    // move tasks in this column to inbox
    final tasks = DbService.tasksBox.values.where((t) => t.planningColumn == id).toList();
    for (final t in tasks) {
      await DbService.tasksBox.put(t.id, t.copyWith(planningColumn: 'inbox'));
    }
    await DbService.columnsBox.delete(id);
    _sync();
  }
}

final columnProvider = StateNotifierProvider<ColumnNotifier, List<PlanningColumn>>(
    (_) => ColumnNotifier());

// ─── Settings ─────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(DbService.settings);

  Future<void> update(AppSettings s) async {
    await DbService.saveSettings(s);
    state = s;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
    (_) => SettingsNotifier());

// ─── Selected date ────────────────────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime>((_) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// ─── Active timetable ids (derived) ──────────────────────────────────────────

final activeTimetableIdsProvider = Provider<List<String>>((ref) =>
    ref.watch(timetableProvider).where((t) => t.isActive).map((t) => t.id).toList());
