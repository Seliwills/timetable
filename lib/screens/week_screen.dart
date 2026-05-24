import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';
import '../widgets/entry_card.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/add_entry_sheet.dart';

class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  CalendarFormat _format = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final activeTimetableIds = ref.watch(activeTimetableIdsProvider);
    final allEntries = ref.watch(entryProvider);
    final allTasks = ref.watch(taskProvider);

    // Build event map for calendar dots
    Map<DateTime, List<dynamic>> events = {};
    for (final t in allTasks) {
      if (t.scheduledDate != null) {
        final key = DateTime(t.scheduledDate!.year, t.scheduledDate!.month, t.scheduledDate!.day);
        events.putIfAbsent(key, () => []).add(t);
      }
    }

    final dayEntries = ref.read(entryProvider.notifier)
        .forWeekday(selectedDate.weekday, activeTimetableIds);
    final dayTasks = ref.read(taskProvider.notifier).forDate(selectedDate);

    // Build hour slots
    final slots = _buildSlots(dayEntries, dayTasks);

    return Scaffold(
      appBar: AppBar(
        title: Text(formatDate(selectedDate),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: () => _addTask(context, selectedDate),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _addEntry(context),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: selectedDate,
            calendarFormat: _format,
            selectedDayPredicate: (d) => isSameDay(d, selectedDate),
            eventLoader: (d) {
              final key = DateTime(d.year, d.month, d.day);
              return events[key] ?? [];
            },
            onDaySelected: (selected, focused) {
              ref.read(selectedDateProvider.notifier).state =
                  DateTime(selected.year, selected.month, selected.day);
            },
            onFormatChanged: (f) => setState(() => _format = f),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonShowsNext: false,
              titleCentered: true,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: slots.isEmpty
                ? EmptyState(
                    icon: Icons.event_available,
                    title: 'Nothing scheduled',
                    subtitle: 'No events for ${formatDate(selectedDate)}',
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      for (final s in slots) ...[
                        if (s.isHourLabel)
                          _HourLabel(minute: s.minute)
                        else if (s.entry != null)
                          EntryCard(entry: s.entry!, showDate: false)
                        else if (s.task != null)
                          TaskCard(
                            task: s.task!,
                            onToggle: () => ref
                                .read(taskProvider.notifier)
                                .toggleComplete(s.task!.id),
                            onTap: () => _editTask(context, s.task!),
                            onDelete: () =>
                                ref.read(taskProvider.notifier).remove(s.task!.id),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<_Slot> _buildSlots(
      List<TimetableEntry> entries, List<Task> tasks) {
    final slots = <_Slot>[];
    // hour markers every 60 min from 6am to 11pm
    for (int h = 6; h <= 23; h++) {
      final minute = h * 60;
      slots.add(_Slot.hourLabel(minute));
      // entries in this hour
      for (final e in entries.where(
          (e) => e.startMinute >= minute && e.startMinute < minute + 60)) {
        slots.add(_Slot.entry(e));
      }
      // tasks in this hour
      for (final t in tasks.where((t) =>
          t.startMinute != null &&
          t.startMinute! >= minute &&
          t.startMinute! < minute + 60)) {
        slots.add(_Slot.task(t));
      }
    }
    return slots;
  }

  void _addTask(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddTaskSheet(initialDate: date),
    );
  }

  void _editTask(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddTaskSheet(existingTask: task),
    );
  }

  void _addEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddEntrySheet(),
    );
  }
}

class _Slot {
  final bool isHourLabel;
  final int minute;
  final TimetableEntry? entry;
  final Task? task;

  _Slot.hourLabel(this.minute) : isHourLabel = true, entry = null, task = null;
  _Slot.entry(TimetableEntry e) : entry = e, task = null, isHourLabel = false, minute = e.startMinute;
  _Slot.task(Task t) : task = t, entry = null, isHourLabel = false, minute = t.startMinute ?? 0;
}

class _HourLabel extends StatelessWidget {
  final int minute;
  const _HourLabel({required this.minute});

  @override
  Widget build(BuildContext context) {
    final h = minute ~/ 60;
    final label = h == 12
        ? '12 PM'
        : h < 12
            ? '$h AM'
            : '${h - 12} PM';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: Row(children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        const SizedBox(width: 8),
        Expanded(child: Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant)),
      ]),
    );
  }
}
