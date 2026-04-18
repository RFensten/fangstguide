import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fish_repository.dart';
import '../../data/models/fish.dart';
import '../../providers/zone_provider.dart';
import '../../shared/utils/date_utils.dart' as du;

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fishAsync = ref.watch(fishListProvider);
    final zone = ref.watch(zoneProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hvad er åbent?')),
      body: fishAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fejl: $e')),
        data: (fish) => _MonthList(fish: fish, zone: zone),
      ),
    );
  }
}

class _MonthList extends StatelessWidget {
  final List<Fish> fish;
  final FishingZone zone;

  const _MonthList({required this.fish, required this.zone});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final dt = DateTime(now.year, now.month + i, 1);
      return dt;
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: months.length,
      itemBuilder: (context, index) {
        final month = months[index];
        final events = _eventsForMonth(fish, zone, month);

        if (events.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                _formatMonth(month),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...events.map((e) => _EventTile(event: e)),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  List<_CalendarEvent> _eventsForMonth(
      List<Fish> fish, FishingZone zone, DateTime month) {
    final events = <_CalendarEvent>[];
    final monthStart = month;
    final monthEnd = DateTime(month.year, month.month + 1, 0);

    for (final f in fish) {
      for (final cs in f.closedSeason) {
        final matchesZone = cs.zone == 'all' ||
            cs.zone == zone.jsonKey ||
            (cs.zone == 'salt' && zone != FishingZone.ferskvand);
        if (!matchesZone) continue;

        // Check if season opens this month
        final openDate =
            DateTime(month.year, cs.endMonth, cs.endDay).add(const Duration(days: 1));
        if (openDate.month == month.month) {
          events.add(_CalendarEvent(
            fish: f,
            label: 'Åbner ${du.formatDanishDate(openDate)}',
            isOpening: true,
          ));
        }

        // Check if season closes this month
        final closeDate = DateTime(month.year, cs.startMonth, cs.startDay);
        if (closeDate.month == month.month) {
          events.add(_CalendarEvent(
            fish: f,
            label: 'Lukker ${du.formatDanishDate(closeDate)}',
            isOpening: false,
          ));
        }
      }
    }

    return events;
  }

  String _formatMonth(DateTime dt) {
    const months = [
      'Januar', 'Februar', 'Marts', 'April', 'Maj', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

class _CalendarEvent {
  final Fish fish;
  final String label;
  final bool isOpening;

  const _CalendarEvent(
      {required this.fish, required this.label, required this.isOpening});
}

class _EventTile extends StatelessWidget {
  final _CalendarEvent event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: event.isOpening
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828),
        ),
      ),
      title: Text(event.fish.nameDa),
      trailing: Text(
        event.label,
        style: TextStyle(
          color: event.isOpening
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}
