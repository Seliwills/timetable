import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  final Task? existingTask;
  final DateTime? initialDate;
  final String? initialColumnId;

  const AddTaskSheet({
    this.existingTask,
    this.initialDate,
    this.initialColumnId,
    super.key,
  });

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late int _priorityIndex;
  late bool _notificationsEnabled;
  late int _reminderMinutes;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedTimetableId;
  String? _selectedColumnId;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _priorityIndex = t?.priorityIndex ?? 1;
    _notificationsEnabled = t?.notificationsEnabled ?? true;
    _reminderMinutes = t?.reminderMinutes ?? ref.read(settingsProvider).defaultReminderMinutes;
    _selectedDate = t?.scheduledDate ?? widget.initialDate;
    _startTime = t?.startTime;
    _endTime = t?.endTime;
    _selectedTimetableId = t?.timetableId;
    _selectedColumnId = t?.planningColumn ?? widget.initialColumnId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timetables = ref.watch(timetableProvider);
    final columns = ref.watch(columnProvider);
    final isEdit = widget.existingTask != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(children: [
                Text(isEdit ? 'Edit task' : 'New task',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (isEdit)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      ref.read(taskProvider.notifier).remove(widget.existingTask!.id);
                      Navigator.pop(context);
                    },
                  ),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Title
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Task title *',
                      prefixIcon: Icon(Icons.task_alt),
                    ),
                    autofocus: !isEdit,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // Priority
                  const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: Priority.values.map((p) => ButtonSegment<int>(
                      value: p.index,
                      label: Text(p.label),
                      icon: Icon(p.icon, size: 16),
                    )).toList(),
                    selected: {_priorityIndex},
                    onSelectionChanged: (s) => setState(() => _priorityIndex = s.first),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  const Text('Schedule (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setState(() => _selectedDate = d);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_selectedDate != null
                            ? formatDate(_selectedDate!)
                            : 'Pick date'),
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() {
                          _selectedDate = null;
                          _startTime = null;
                          _endTime = null;
                        }),
                      ),
                    ],
                  ]),

                  // Time range
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (t != null) setState(() => _startTime = t);
                          },
                          icon: const Icon(Icons.schedule, size: 16),
                          label: Text(_startTime != null
                              ? 'Start: ${formatTimeOfDay(_startTime!)}'
                              : 'Start time'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _startTime == null
                              ? null
                              : () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: _endTime ?? TimeOfDay(
                                        hour: (_startTime!.hour + 1).clamp(0, 23),
                                        minute: _startTime!.minute),
                                  );
                                  if (t != null) setState(() => _endTime = t);
                                },
                          icon: const Icon(Icons.schedule_send, size: 16),
                          label: Text(_endTime != null
                              ? 'End: ${formatTimeOfDay(_endTime!)}'
                              : 'End time'),
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 16),

                  // Timetable
                  DropdownButtonFormField<String>(
                    value: _selectedTimetableId,
                    decoration: const InputDecoration(
                      labelText: 'Timetable (optional)',
                      prefixIcon: Icon(Icons.calendar_view_week),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...timetables.map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Row(children: [
                              Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(color: t.color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(t.name),
                            ]),
                          )),
                    ],
                    onChanged: (v) => setState(() => _selectedTimetableId = v),
                  ),
                  const SizedBox(height: 12),

                  // Planning column
                  DropdownButtonFormField<String>(
                    value: _selectedColumnId,
                    decoration: const InputDecoration(
                      labelText: 'Planning board column',
                      prefixIcon: Icon(Icons.view_column_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...columns.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(children: [
                              Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(c.title),
                            ]),
                          )),
                    ],
                    onChanged: (v) => setState(() => _selectedColumnId = v),
                  ),
                  const SizedBox(height: 16),

                  // Notifications
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reminder notification'),
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                  if (_notificationsEnabled) ...[
                    const Text('Remind me', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [5, 10, 15, 30, 60].map((m) => ChoiceChip(
                        label: Text('$m min'),
                        selected: _reminderMinutes == m,
                        onSelected: (_) => setState(() => _reminderMinutes = m),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(isEdit ? 'Save changes' : 'Add task',
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a task title')));
      return;
    }

    final startMin = _startTime != null
        ? _startTime!.hour * 60 + _startTime!.minute
        : null;
    final endMin = _endTime != null
        ? _endTime!.hour * 60 + _endTime!.minute
        : null;

    if (widget.existingTask != null) {
      final updated = widget.existingTask!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        priorityIndex: _priorityIndex,
        scheduledDate: _selectedDate,
        startMinute: startMin,
        endMinute: endMin,
        timetableId: _selectedTimetableId,
        planningColumn: _selectedColumnId,
        notificationsEnabled: _notificationsEnabled,
        reminderMinutes: _reminderMinutes,
        clearSchedule: _selectedDate == null,
      );
      ref.read(taskProvider.notifier).update(updated);
    } else {
      final task = Task(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        priorityIndex: _priorityIndex,
        scheduledDate: _selectedDate,
        startMinute: startMin,
        endMinute: endMin,
        timetableId: _selectedTimetableId,
        planningColumn: _selectedColumnId,
        notificationsEnabled: _notificationsEnabled,
        reminderMinutes: _reminderMinutes,
        sortOrder: 0,
      );
      ref.read(taskProvider.notifier).add(task);
    }

    Navigator.pop(context);
  }
}
