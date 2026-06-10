import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/fish_repository.dart';
import '../../data/models/fish.dart';
import '../../providers/premium_provider.dart';
import '../../providers/zone_provider.dart';
import '../../shared/utils/date_utils.dart' as du;
import '../../shared/utils/season_checker.dart';
import '../../shared/widgets/zone_selector.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fishAsync = ref.watch(fishListProvider);
    final zone = ref.watch(zoneProvider);
    final isPremium = ref.watch(premiumProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Hvad er åbent?')),
      body: Column(
        children: [
          const ZoneSelector(),
          Expanded(
            child: fishAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fejl: $e')),
              data: (fish) => _MonthList(
                fish: fish,
                zone: zone,
                isPremium: isPremium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthList extends StatelessWidget {
  final List<Fish> fish;
  final FishingZone zone;
  final bool isPremium;

  const _MonthList({
    required this.fish,
    required this.zone,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final dt = DateTime(now.year, now.month + i, 1);
      return dt;
    });

    // Gratis-brugere ser kun den aktuelle måned
    final visibleMonths = isPremium ? months : months.take(1).toList();

    final items = <Widget>[];
    var hasEvents = false;

    for (final month in visibleMonths) {
      final events = _eventsForMonth(fish, zone, month);
      if (events.isEmpty) continue;
      hasEvents = true;

      items.add(
        Column(
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
        ),
      );
    }

    if (!hasEvents) {
      items.add(Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(isPremium
              ? 'Ingen fredningsperioder de næste 12 måneder.'
              : 'Ingen fredningsperioder denne måned.'),
        ),
      ));
    }

    // Gratis-brugere ser en upsell-banner efter den første måned
    if (!isPremium) {
      items.add(const _PremiumCalendarBanner());
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: items,
    );
  }

  List<_CalendarEvent> _eventsForMonth(
      List<Fish> fish, FishingZone zone, DateTime month) {
    final events = <_CalendarEvent>[];

    for (final f in fish) {
      for (final cs in f.closedSeason) {
        if (cs.startMonth == 1 &&
            cs.startDay == 1 &&
            cs.endMonth == 12 &&
            cs.endDay == 31) {
          continue;
        }

        if (!zoneMatches(cs.zone, zone)) continue;

        // day + 1 (ikke .add(Duration)) — undgår fejl ved sommertidsskift
        final openDate = DateTime(month.year, cs.endMonth, cs.endDay + 1);
        if (openDate.month == month.month) {
          events.add(_CalendarEvent(
            fish: f,
            date: openDate,
            label: 'Åbner ${du.formatDanishDate(openDate)}',
            isOpening: true,
          ));
        }

        final closeDate =
            DateTime(month.year, cs.startMonth, cs.startDay);
        if (closeDate.month == month.month) {
          events.add(_CalendarEvent(
            fish: f,
            date: closeDate,
            label: 'Lukker ${du.formatDanishDate(closeDate)}',
            isOpening: false,
          ));
        }
      }
    }

    events.sort((a, b) => a.date.compareTo(b.date));
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

class _PremiumCalendarBanner extends StatelessWidget {
  const _PremiumCalendarBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => context.push('/paywall'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(Icons.lock_outlined,
                  size: 32, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(height: 12),
              Text(
                'Se de næste 11 måneder',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Planlæg sæsonen på forhånd med fuld kalender — kun i Premium.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/paywall'),
                child: const Text('Lås op — 39 kr.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarEvent {
  final Fish fish;
  final DateTime date;
  final String label;
  final bool isOpening;

  const _CalendarEvent({
    required this.fish,
    required this.date,
    required this.label,
    required this.isOpening,
  });
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
