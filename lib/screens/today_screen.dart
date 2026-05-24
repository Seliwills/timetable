import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';
import '../widgets/task_card.dart';
import '../widgets/entry_card.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/add_entry_sheet.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(selectedDateProvider);
    final activeTimetableIds = ref.watch(activeTimetableIdsProvider);
    final entries = ref.watch(entryProvider.notifier).forWeekday(today.weekday, activeTimetableIds);
    final tasks = ref.watch(taskProvider.notifier).forDate(today);
    final timetables = ref.watch(timetableProvider);

    // Merge and sort everything by start time
    final timeline = <_TimelineItem>[
      for (final e in entries) _TimelineItem.entry(e),
      for (final t in tasks) _TimelineItem.task(t),
    ]..sort((a, b) => a.startMinute.compareTo(b.startMinute));

    final unscheduledTasks = tasks.where((t) => t.isUnscheduled).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(formatDateFull(today),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text('${timeline.length} event${timeline.length != 1 ? 's' : ''} today',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline)),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: () => ref.read(selectedDateProvider.notifier).state =
                    today.subtract(const Duration(days: 1)),
              ),
              IconButton(
                icon: const Icon(Icons.today),
                onPressed: () {
                  final now = DateTime.now();
                  ref.read(selectedDateProvider.notifier).state =
                      DateTime(now.year, now.month, now.day);
                },
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: () => ref.read(selectedDateProvider.notifier).state =
                    today.add(const Duration(days: 1)),
              ),
            ],
          ),

          // Active timetable chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(spacing: 8, children: [
                for (final t in timetables)
                  FilterChip(
                    label: Text(t.name),
                    selected: t.isActive,
                    onSelected: (_) =>
                        ref.read(timetableProvider.notifier).toggleActive(t.id),
                    selectedColor: Color(t.colorValue).withOpacity(0.2),
                    checkmarkColor: Color(t.colorValue),
                    labelStyle: TextStyle(
                        fontSize: 12,
                        color: t.isActive ? Color(t.colorValue) : null),
                    side: BorderSide(
                        color: t.isActive
                            ? Color(t.colorValue)
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: 0.5),
                  ),
              ]),
            ),
          ),

          if (timeline.isEmpty && unscheduledTasks.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.wb_sunny_outlined,
                title: 'Free day!',
                subtitle: 'No events scheduled for today.\nTap + to add a task or entry.',
                action: FilledButton.icon(
                  onPressed: () => _addTask(context, ref, today),
                  icon: const Icon(Icons.add),
                  label: const Text('Add task'),
                ),
              ),
            )
          else ...[
            if (timeline.isNotEmpty)
              SliverToBoxAdapter(child: SectionHeader('Schedule')),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final item = timeline[i];
                  if (item.entry != null) {
                    return EntryCard(entry: item.entry!, showDate: false);
                  } else {
                    return TaskCard(
                      task: item.task!,
                      onToggle: () => ref.read(taskProvider.notifier).toggleComplete(item.task!.id),
                      onTap: () => _editTask(context, ref, item.task!),
                      onDelete: () => ref.read(taskProvider.notifier).remove(item.task!.id),
                    );
                  }
                },
                childCount: timeline.length,
              ),
            ),

            if (unscheduledTasks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  'Unscheduled tasks',
                  trailing: Text('${unscheduledTasks.length}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => TaskCard(
                    task: unscheduledTasks[i],
                    onToggle: () =>
                        ref.read(taskProvider.notifier).toggleComplete(unscheduledTasks[i].id),
                    onTap: () => _editTask(context, ref, unscheduledTasks[i]),
                    onDelete: () =>
                        ref.read(taskProvider.notifier).remove(unscheduledTasks[i].id),
                  ),
                  childCount: unscheduledTasks.length,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'add_entry',
            onPressed: () => _addEntry(context, ref),
            tooltip: 'Add timetable entry',
            child: const Icon(Icons.calendar_month),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add_task',
            onPressed: () => _addTask(context, ref, today),
            icon: const Icon(Icons.add_task),
            label: const Text('Add task'),
          ),
        ],
      ),
    );
  }

  void _addTask(BuildContext context, WidgetRef ref, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddTaskSheet(initialDate: date),
    );
  }

  void _editTask(BuildContext context, WidgetRef ref, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddTaskSheet(existingTask: task),
    );
  }

  void _addEntry(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddEntrySheet(),
    );
  }
}

class _TimelineItem {
  final TimetableEntry? entry;
  final Task? task;
  final int startMinute;

  _TimelineItem.entry(TimetableEntry e)
      : entry = e, task = null, startMinute = e.startMinute;
  _TimelineItem.task(Task t)
      : task = t, entry = null, startMinute = t.startMinute ?? 9999;
}
