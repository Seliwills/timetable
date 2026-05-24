import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_sheet.dart';

enum _Filter { all, today, upcoming, unscheduled, completed }

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(taskProvider);
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    List<Task> filtered;
    switch (_filter) {
      case _Filter.all:
        filtered = allTasks.where((t) => !t.isCompleted).toList();
        break;
      case _Filter.today:
        filtered = allTasks.where((t) =>
            !t.isCompleted &&
            t.scheduledDate != null &&
            isSameDay(t.scheduledDate!, todayKey)).toList();
        break;
      case _Filter.upcoming:
        filtered = allTasks.where((t) =>
            !t.isCompleted &&
            t.scheduledDate != null &&
            t.scheduledDate!.isAfter(todayKey)).toList();
        break;
      case _Filter.unscheduled:
        filtered = allTasks.where((t) => !t.isCompleted && t.isUnscheduled).toList();
        break;
      case _Filter.completed:
        filtered = allTasks.where((t) => t.isCompleted).toList();
        break;
    }

    filtered.sort((a, b) {
      // sort by date then start time
      if (a.scheduledDate != null && b.scheduledDate != null) {
        final dc = a.scheduledDate!.compareTo(b.scheduledDate!);
        if (dc != 0) return dc;
      }
      if (a.scheduledDate != null && b.scheduledDate == null) return -1;
      if (a.scheduledDate == null && b.scheduledDate != null) return 1;
      return (a.startMinute ?? 9999).compareTo(b.startMinute ?? 9999);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          Badge(
            label: Text('${allTasks.where((t) => !t.isCompleted).length}'),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: _Filter.values.map((f) {
                final labels = ['All', 'Today', 'Upcoming', 'Unscheduled', 'Done'];
                final icons = [
                  Icons.list, Icons.today, Icons.upcoming,
                  Icons.inbox_outlined, Icons.check_circle_outline
                ];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icons[f.index], size: 14),
                      const SizedBox(width: 4),
                      Text(labels[f.index]),
                    ]),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? EmptyState(
              icon: Icons.task_alt,
              title: 'No tasks here',
              subtitle: _emptySubtitle(_filter),
              action: _filter != _Filter.completed
                  ? FilledButton.icon(
                      onPressed: () => _addTask(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add task'),
                    )
                  : null,
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: filtered.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final task = filtered[oldIndex];
                ref.read(taskProvider.notifier).update(
                    task.copyWith(sortOrder: newIndex));
              },
              itemBuilder: (ctx, i) {
                final task = filtered[i];
                return TaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  showDate: true,
                  onToggle: () => ref.read(taskProvider.notifier).toggleComplete(task.id),
                  onTap: () => _editTask(context, task),
                  onDelete: () => ref.read(taskProvider.notifier).remove(task.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTask(context),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
    );
  }

  String _emptySubtitle(_Filter f) {
    switch (f) {
      case _Filter.all: return 'No pending tasks. Great job!';
      case _Filter.today: return 'Nothing scheduled for today.';
      case _Filter.upcoming: return 'No upcoming tasks.';
      case _Filter.unscheduled: return 'All tasks have been scheduled!';
      case _Filter.completed: return 'No completed tasks yet.';
    }
  }

  void _addTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddTaskSheet(),
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
}
