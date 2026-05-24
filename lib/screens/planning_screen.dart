import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';
import '../widgets/add_task_sheet.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});
  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  @override
  Widget build(BuildContext context) {
    final columns = ref.watch(columnProvider);
    final allTasks = ref.watch(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Planning board',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Add column',
            onPressed: () => _addColumn(context),
          ),
        ],
      ),
      body: columns.isEmpty
          ? const EmptyState(
              icon: Icons.view_column_outlined,
              title: 'No planning columns',
              subtitle: 'Add a column to start organizing your tasks.',
            )
          : ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              children: columns.map((col) {
                final tasks = ref.read(taskProvider.notifier).inColumn(col.id)
                  ..addAll(col.isInbox
                      ? allTasks.where((t) => t.isUnscheduled && t.planningColumn == null).toList()
                      : []);
                return _ColumnWidget(
                  column: col,
                  tasks: tasks,
                  allColumns: columns,
                  onAddTask: () => _addTaskToColumn(context, col.id),
                  onEditColumn: col.isInbox ? null : () => _editColumn(context, col),
                  onDeleteColumn: col.isInbox ? null : () => _deleteColumn(col.id),
                );
              }).toList(),
            ),
    );
  }

  void _addColumn(BuildContext context) {
    _showColumnDialog(context, null);
  }

  void _editColumn(BuildContext context, PlanningColumn col) {
    _showColumnDialog(context, col);
  }

  void _showColumnDialog(BuildContext context, PlanningColumn? existing) {
    final titleCtrl = TextEditingController(text: existing?.title);
    int selectedColor = existing?.colorValue ?? 0xFF7F77DD;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'New column' : 'Edit column'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Column name'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('Color', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: kTimetableColors.map((c) => GestureDetector(
                onTap: () => setS(() => selectedColor = c.value),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: selectedColor == c.value
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: selectedColor == c.value
                        ? [BoxShadow(color: c.withOpacity(.5), blurRadius: 6)]
                        : null,
                  ),
                ),
              )).toList(),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                if (existing == null) {
                  final col = PlanningColumn(
                    title: titleCtrl.text.trim(),
                    colorValue: selectedColor,
                    sortOrder: ref.read(columnProvider).length,
                  );
                  ref.read(columnProvider.notifier).add(col);
                } else {
                  ref.read(columnProvider.notifier).update(PlanningColumn(
                    id: existing.id,
                    title: titleCtrl.text.trim(),
                    colorValue: selectedColor,
                    sortOrder: existing.sortOrder,
                    isInbox: existing.isInbox,
                  ));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteColumn(String id) {
    ref.read(columnProvider.notifier).remove(id);
  }

  void _addTaskToColumn(BuildContext context, String columnId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddTaskSheet(initialColumnId: columnId),
    );
  }
}

// ─── Column widget ────────────────────────────────────────────────────────────

class _ColumnWidget extends ConsumerWidget {
  final PlanningColumn column;
  final List<Task> tasks;
  final List<PlanningColumn> allColumns;
  final VoidCallback onAddTask;
  final VoidCallback? onEditColumn;
  final VoidCallback? onDeleteColumn;

  const _ColumnWidget({
    required this.column,
    required this.tasks,
    required this.allColumns,
    required this.onAddTask,
    this.onEditColumn,
    this.onDeleteColumn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = column.color;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(column.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Text('${tasks.length}',
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              if (onEditColumn != null || onDeleteColumn != null)
                PopupMenuButton<String>(
                  iconSize: 18,
                  itemBuilder: (_) => [
                    if (onEditColumn != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (onDeleteColumn != null)
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') onEditColumn?.call();
                    if (v == 'delete') onDeleteColumn?.call();
                  },
                ),
            ]),
          ),

          // Task list (reorderable within column)
          Expanded(
            child: DragTarget<Task>(
              onAcceptWithDetails: (details) {
                final task = details.data;
                ref.read(taskProvider.notifier).reorder(task.id, column.id, tasks.length);
              },
              builder: (ctx, candidate, _) => Container(
                decoration: candidate.isNotEmpty
                    ? BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  itemCount: tasks.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    ref.read(taskProvider.notifier).reorder(
                        tasks[oldIndex].id, column.id, newIndex);
                  },
                  itemBuilder: (ctx, i) => _PlanningTaskCard(
                    key: ValueKey(tasks[i].id),
                    task: tasks[i],
                    allColumns: allColumns,
                  ),
                ),
              ),
            ),
          ),

          // Add button
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: TextButton.icon(
              onPressed: onAddTask,
              icon: Icon(Icons.add, size: 16, color: color),
              label: Text('Add task', style: TextStyle(color: color, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Planning task card ───────────────────────────────────────────────────────

class _PlanningTaskCard extends ConsumerWidget {
  final Task task;
  final List<PlanningColumn> allColumns;

  const _PlanningTaskCard({required this.task, required this.allColumns, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LongPressDraggable<Task>(
      data: task,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 260,
          child: _cardContent(context, ref, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _cardContent(context, ref)),
      child: _cardContent(context, ref),
    );
  }

  Widget _cardContent(BuildContext context, WidgetRef ref, {bool isDragging = false}) {
    final priority = task.priority;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: priority.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    )),
              ),
              PopupMenuButton<String>(
                iconSize: 16,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'complete', child: Text('Mark done')),
                  ...allColumns.map((c) => PopupMenuItem(
                      value: 'move_${c.id}',
                      child: Text('Move to ${c.title}'))),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
                onSelected: (v) {
                  if (v == 'edit') {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => AddTaskSheet(existingTask: task),
                    );
                  } else if (v == 'complete') {
                    ref.read(taskProvider.notifier).toggleComplete(task.id);
                  } else if (v == 'delete') {
                    ref.read(taskProvider.notifier).remove(task.id);
                  } else if (v.startsWith('move_')) {
                    final colId = v.substring(5);
                    ref.read(taskProvider.notifier).reorder(task.id, colId, 999);
                  }
                },
              ),
            ]),
            if (task.scheduledDate != null || task.startMinute != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  Icon(Icons.schedule, size: 11, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 3),
                  if (task.scheduledDate != null)
                    Text(formatDate(task.scheduledDate!),
                        style: TextStyle(
                            fontSize: 11, color: Theme.of(context).colorScheme.outline)),
                  if (task.startMinute != null) ...[
                    const SizedBox(width: 4),
                    Text(formatMinutes(task.startMinute!),
                        style: TextStyle(
                            fontSize: 11, color: Theme.of(context).colorScheme.outline)),
                  ],
                ]),
              ),
            if (task.description?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(task.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: Theme.of(context).colorScheme.outline)),
              ),
          ]),
        ),
      ]),
    );
  }
}
