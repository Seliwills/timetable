import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';

class AddEntrySheet extends ConsumerStatefulWidget {
  final TimetableEntry? existingEntry;
  final String? timetableId;

  const AddEntrySheet({this.existingEntry, this.timetableId, super.key});

  @override
  ConsumerState<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<AddEntrySheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _notesCtrl;
  late int _weekday;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _selectedColorValue;
  late String? _selectedTimetableId;
  late bool _notificationsEnabled;
  late int _reminderMinutes;

  @override
  void initState() {
    super.initState();
    final e = widget.existingEntry;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _weekday = e?.weekday ?? DateTime.now().weekday;
    _startTime = e?.startTime ?? const TimeOfDay(hour: 8, minute: 0);
    _endTime = e?.endTime ?? const TimeOfDay(hour: 9, minute: 0);
    _selectedColorValue = e?.colorValue ?? kTimetableColors[1].value;
    _selectedTimetableId = e?.timetableId ?? widget.timetableId;
    _notificationsEnabled = e?.notificationsEnabled ?? true;
    _reminderMinutes = e?.reminderMinutes ?? 15;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timetables = ref.watch(timetableProvider);
    final isEdit = widget.existingEntry != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(children: [
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
              Text(isEdit ? 'Edit entry' : 'New timetable entry',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (isEdit)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    ref.read(entryProvider.notifier).remove(widget.existingEntry!.id);
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
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  autofocus: !isEdit,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Timetable selector
                DropdownButtonFormField<String>(
                  value: _selectedTimetableId,
                  decoration: const InputDecoration(
                    labelText: 'Timetable *',
                    prefixIcon: Icon(Icons.view_week),
                  ),
                  items: timetables.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Row(children: [
                      Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(color: t.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(t.name),
                    ]),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedTimetableId = v),
                ),
                const SizedBox(height: 16),

                // Day of week
                const Text('Day of week', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(kWeekdayNames[day]),
                          selected: _weekday == day,
                          onSelected: (_) => setState(() => _weekday = day),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // Time range
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context, initialTime: _startTime);
                        if (t != null) setState(() => _startTime = t);
                      },
                      icon: const Icon(Icons.schedule, size: 16),
                      label: Text('Start: ${formatTimeOfDay(_startTime)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context, initialTime: _endTime);
                        if (t != null) setState(() => _endTime = t);
                      },
                      icon: const Icon(Icons.schedule_send, size: 16),
                      label: Text('End: ${formatTimeOfDay(_endTime)}'),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Color
                const Text('Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: kTimetableColors.map((c) => GestureDetector(
                    onTap: () => setState(() => _selectedColorValue = c.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _selectedColorValue == c.value
                            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)
                            : Border.all(color: Colors.transparent, width: 2),
                      ),
                      child: _selectedColorValue == c.value
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),

                // Notifications
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reminder notification'),
                  subtitle: const Text('Recurring each week'),
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
                child: Text(isEdit ? 'Save changes' : 'Add to timetable',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (_selectedTimetableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a timetable')));
      return;
    }

    final startMin = _startTime.hour * 60 + _startTime.minute;
    final endMin = _endTime.hour * 60 + _endTime.minute;

    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')));
      return;
    }

    if (widget.existingEntry != null) {
      final updated = TimetableEntry(
        id: widget.existingEntry!.id,
        timetableId: _selectedTimetableId!,
        title: _titleCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        weekday: _weekday,
        startMinute: startMin,
        endMinute: endMin,
        colorValue: _selectedColorValue,
        notificationsEnabled: _notificationsEnabled,
        reminderMinutes: _reminderMinutes,
      );
      ref.read(entryProvider.notifier).update(updated);
    } else {
      final entry = TimetableEntry(
        timetableId: _selectedTimetableId!,
        title: _titleCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        weekday: _weekday,
        startMinute: startMin,
        endMinute: endMin,
        colorValue: _selectedColorValue,
        notificationsEnabled: _notificationsEnabled,
        reminderMinutes: _reminderMinutes,
      );
      ref.read(entryProvider.notifier).add(entry);
    }

    Navigator.pop(context);
  }
}
