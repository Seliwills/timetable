import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';
import '../utils/notification_service.dart';
import '../widgets/add_entry_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetables = ref.watch(timetableProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        children: [
          // ── Timetables ──────────────────────────────────────────────────────
          const SectionHeader('My timetables'),
          for (final t in timetables)
            _TimetableTile(timetable: t),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: () => _addTimetable(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add timetable'),
            ),
          ),

          // ── Notifications ───────────────────────────────────────────────────
          const SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Enable notifications'),
            subtitle: const Text('Reminders for events and tasks'),
            value: settings.globalNotifications,
            onChanged: (v) => ref.read(settingsProvider.notifier)
                .update(AppSettings(
                  globalNotifications: v,
                  defaultReminderMinutes: settings.defaultReminderMinutes,
                  dailyDigest: settings.dailyDigest,
                  dailyDigestHour: settings.dailyDigestHour,
                  dailyDigestMinute: settings.dailyDigestMinute,
                  startOfDay: settings.startOfDay,
                  endOfDay: settings.endOfDay,
                  showWeekends: settings.showWeekends,
                )),
          ),
          ListTile(
            title: const Text('Default reminder'),
            subtitle: Text('${settings.defaultReminderMinutes} minutes before'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickReminderTime(context, ref, settings),
          ),
          SwitchListTile(
            title: const Text('Daily digest'),
            subtitle: Text(
                'Summary at ${_fmt(settings.dailyDigestHour)}:${settings.dailyDigestMinute.toString().padLeft(2, '0')} ${settings.dailyDigestHour < 12 ? 'AM' : 'PM'}'),
            value: settings.dailyDigest,
            onChanged: (v) {
              final s = AppSettings(
                globalNotifications: settings.globalNotifications,
                defaultReminderMinutes: settings.defaultReminderMinutes,
                dailyDigest: v,
                dailyDigestHour: settings.dailyDigestHour,
                dailyDigestMinute: settings.dailyDigestMinute,
                startOfDay: settings.startOfDay,
                endOfDay: settings.endOfDay,
                showWeekends: settings.showWeekends,
              );
              ref.read(settingsProvider.notifier).update(s);
            },
          ),
          if (settings.dailyDigest)
            ListTile(
              title: const Text('Digest time'),
              trailing: Text(
                  '${_fmt(settings.dailyDigestHour)}:${settings.dailyDigestMinute.toString().padLeft(2, '0')}'),
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                      hour: settings.dailyDigestHour,
                      minute: settings.dailyDigestMinute),
                );
                if (t != null) {
                  ref.read(settingsProvider.notifier).update(AppSettings(
                    globalNotifications: settings.globalNotifications,
                    defaultReminderMinutes: settings.defaultReminderMinutes,
                    dailyDigest: settings.dailyDigest,
                    dailyDigestHour: t.hour,
                    dailyDigestMinute: t.minute,
                    startOfDay: settings.startOfDay,
                    endOfDay: settings.endOfDay,
                    showWeekends: settings.showWeekends,
                  ));
                }
              },
            ),

          // ── Display ─────────────────────────────────────────────────────────
          const SectionHeader('Display'),
          SwitchListTile(
            title: const Text('Show weekends'),
            value: settings.showWeekends,
            onChanged: (v) => ref.read(settingsProvider.notifier).update(AppSettings(
              globalNotifications: settings.globalNotifications,
              defaultReminderMinutes: settings.defaultReminderMinutes,
              dailyDigest: settings.dailyDigest,
              dailyDigestHour: settings.dailyDigestHour,
              dailyDigestMinute: settings.dailyDigestMinute,
              startOfDay: settings.startOfDay,
              endOfDay: settings.endOfDay,
              showWeekends: v,
            )),
          ),

          // ── About ────────────────────────────────────────────────────────────
          const SectionHeader('About'),
          ListTile(
            title: const Text('Request notification permissions'),
            leading: const Icon(Icons.notifications_active_outlined),
            onTap: () => NotificationService.requestPermissions(),
          ),
          const ListTile(
            title: Text('Version'),
            trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _fmt(int h) {
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return display.toString();
  }

  void _addTimetable(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    int selectedColor = kTimetableColors[2].value;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('New timetable'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
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
                  ),
                ),
              )).toList(),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                ref.read(timetableProvider.notifier).add(Timetable(
                  name: nameCtrl.text.trim(),
                  colorValue: selectedColor,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickReminderTime(BuildContext context, WidgetRef ref, AppSettings settings) {
    final options = [5, 10, 15, 30, 60];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Default reminder time'),
        children: options.map((m) => SimpleDialogOption(
          onPressed: () {
            ref.read(settingsProvider.notifier).update(AppSettings(
              globalNotifications: settings.globalNotifications,
              defaultReminderMinutes: m,
              dailyDigest: settings.dailyDigest,
              dailyDigestHour: settings.dailyDigestHour,
              dailyDigestMinute: settings.dailyDigestMinute,
              startOfDay: settings.startOfDay,
              endOfDay: settings.endOfDay,
              showWeekends: settings.showWeekends,
            ));
            Navigator.pop(ctx);
          },
          child: Text('$m minutes before'),
        )).toList(),
      ),
    );
  }
}

// ─── Timetable settings tile ──────────────────────────────────────────────────

class _TimetableTile extends ConsumerWidget {
  final Timetable timetable;
  const _TimetableTile({required this.timetable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 14, height: 14,
        decoration: BoxDecoration(
          color: timetable.color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(timetable.name),
      subtitle: timetable.isBuiltIn ? const Text('Built-in') : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Switch(
          value: timetable.isActive,
          onChanged: (_) => ref.read(timetableProvider.notifier).toggleActive(timetable.id),
        ),
        if (!timetable.isBuiltIn)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => ref.read(timetableProvider.notifier).remove(timetable.id),
          ),
      ]),
      onTap: () => _viewEntries(context, ref),
    );
  }

  void _viewEntries(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TimetableEntriesSheet(timetable: timetable),
    );
  }
}

class _TimetableEntriesSheet extends ConsumerWidget {
  final Timetable timetable;
  const _TimetableEntriesSheet({required this.timetable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEntries = ref.watch(entryProvider);
    final entries = allEntries
        .where((e) => e.timetableId == timetable.id)
        .toList()
      ..sort((a, b) {
        if (a.weekday != b.weekday) return a.weekday.compareTo(b.weekday);
        return a.startMinute.compareTo(b.startMinute);
      });

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (ctx, ctrl) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: timetable.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(timetable.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => AddEntrySheet(timetableId: timetable.id),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add entry'),
            ),
            const SizedBox(width: 8),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: entries.isEmpty
              ? EmptyState(
                  icon: Icons.calendar_today_outlined,
                  title: 'No entries',
                  subtitle: 'Add recurring events to this timetable.',
                )
              : ListView.builder(
                  controller: ctrl,
                  itemCount: entries.length,
                  itemBuilder: (_, i) => _EntryListTile(entry: entries[i]),
                ),
        ),
      ]),
    );
  }
}

class _EntryListTile extends ConsumerWidget {
  final TimetableEntry entry;
  const _EntryListTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: entry.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(entry.title),
      subtitle: Text(
          '${kWeekdayFull[entry.weekday]}  •  ${formatMinutes(entry.startMinute)} – ${formatMinutes(entry.endMinute)}'),
      trailing: PopupMenuButton<String>(
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
        onSelected: (v) {
          if (v == 'edit') {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => AddEntrySheet(existingEntry: entry),
            );
          } else if (v == 'delete') {
            ref.read(entryProvider.notifier).remove(entry.id);
          }
        },
      ),
    );
  }
}
