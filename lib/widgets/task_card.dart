import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool showDate;

  const TaskCard({
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    this.showDate = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final priority = task.priority;
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(children: [
              // Priority bar
              Container(
                width: 3,
                height: 52,
                margin: const EdgeInsets.only(left: 6, right: 10),
                decoration: BoxDecoration(
                  color: task.isCompleted
                      ? cs.outlineVariant
                      : priority.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Checkbox
              Checkbox(
                value: task.isCompleted,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              // Content
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? cs.outline : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    if (showDate && task.scheduledDate != null) ...[
                      Icon(Icons.calendar_today, size: 11, color: cs.outline),
                      const SizedBox(width: 3),
                      Text(formatDate(task.scheduledDate!),
                          style: TextStyle(fontSize: 11, color: cs.outline)),
                      const SizedBox(width: 8),
                    ],
                    if (task.startMinute != null) ...[
                      Icon(Icons.schedule, size: 11, color: cs.outline),
                      const SizedBox(width: 3),
                      Text(
                        '${formatMinutes(task.startMinute!)}${task.endMinute != null ? ' → ${formatMinutes(task.endMinute!)}' : ''}',
                        style: TextStyle(fontSize: 11, color: cs.outline),
                      ),
                    ] else
                      Text('Unscheduled',
                          style: TextStyle(fontSize: 11, color: cs.outline)),
                  ]),
                ]),
              ),
              // Priority chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PriorityChip(task.priority),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
