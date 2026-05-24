import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/theme.dart';

class EntryCard extends StatelessWidget {
  final TimetableEntry entry;
  final bool showDate;

  const EntryCard({required this.entry, this.showDate = false, super.key});

  @override
  Widget build(BuildContext context) {
    final color = entry.color;
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            // Color stripe
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(entry.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${formatMinutes(entry.startMinute)} – ${formatMinutes(entry.endMinute)}',
                      style: TextStyle(
                          fontSize: 11, color: color, fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  if (entry.location?.isNotEmpty == true) ...[
                    Icon(Icons.location_on_outlined, size: 12, color: cs.outline),
                    const SizedBox(width: 2),
                    Text(entry.location!,
                        style: TextStyle(fontSize: 12, color: cs.outline)),
                    const SizedBox(width: 8),
                  ],
                  if (showDate) ...[
                    Icon(Icons.repeat, size: 12, color: cs.outline),
                    const SizedBox(width: 2),
                    Text(kWeekdayFull[entry.weekday],
                        style: TextStyle(fontSize: 12, color: cs.outline)),
                  ],
                  const Spacer(),
                  Icon(
                    entry.notificationsEnabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    size: 14,
                    color: cs.outlineVariant,
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
