import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

// ─── Theme ────────────────────────────────────────────────────────────────────

class AppTheme {
  static const _seed = Color(0xFF7F77DD);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seed,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seed,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2C2C2C), width: 0.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}

// ─── Color palette ────────────────────────────────────────────────────────────

const kTimetableColors = [
  Color(0xFF7F77DD), // purple
  Color(0xFF1D9E75), // teal
  Color(0xFFD85A30), // coral
  Color(0xFFBA7517), // amber
  Color(0xFF378ADD), // blue
  Color(0xFF639922), // green
  Color(0xFFD4537E), // pink
  Color(0xFF888780), // gray
];

// ─── Formatting helpers ───────────────────────────────────────────────────────

String formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  final period = h < 12 ? 'AM' : 'PM';
  final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '${displayH}:${m.toString().padLeft(2, '0')} $period';
}

String formatTimeOfDay(TimeOfDay t) {
  final period = t.hour < 12 ? 'AM' : 'PM';
  final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
  return '$h:${t.minute.toString().padLeft(2, '0')} $period';
}

String formatDate(DateTime d) => DateFormat('EEE, MMM d').format(d);
String formatDateFull(DateTime d) => DateFormat('EEEE, MMMM d, y').format(d);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ─── Weekday helpers ──────────────────────────────────────────────────────────

const kWeekdayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const kWeekdayFull = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

List<DateTime> weekDays(DateTime anchor) {
  final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
  return List.generate(7, (i) => monday.add(Duration(days: i)));
}

// ─── Priority chip ────────────────────────────────────────────────────────────

class PriorityChip extends StatelessWidget {
  final Priority priority;
  const PriorityChip(this.priority, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: priority.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(priority.icon, size: 12, color: priority.color),
        const SizedBox(width: 3),
        Text(priority.label,
            style: TextStyle(fontSize: 11, color: priority.color, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─── Time range display ───────────────────────────────────────────────────────

class TimeRangeLabel extends StatelessWidget {
  final int? start;
  final int? end;
  const TimeRangeLabel({this.start, this.end, super.key});

  @override
  Widget build(BuildContext context) {
    if (start == null) {
      return const Text('Unscheduled', style: TextStyle(fontSize: 12, color: Colors.grey));
    }
    return Text(
      '${formatMinutes(start!)}${end != null ? ' → ${formatMinutes(end!)}' : ''}',
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {this.trailing, super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, letterSpacing: .5)),
          const Spacer(),
          if (trailing != null) trailing!,
        ]),
      );
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  const EmptyState({required this.icon, required this.title, required this.subtitle, this.action, super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ]),
        ),
      );
}
