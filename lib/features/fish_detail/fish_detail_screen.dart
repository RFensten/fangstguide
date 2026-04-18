import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../data/fish_repository.dart';
import '../../data/models/closed_season.dart';
import '../../data/models/fish.dart';
import '../../providers/zone_provider.dart';
import '../../shared/utils/season_checker.dart';
import '../../shared/utils/date_utils.dart' as du;

class FishDetailScreen extends ConsumerWidget {
  final String fishId;

  const FishDetailScreen({super.key, required this.fishId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fishAsync = ref.watch(fishByIdProvider(fishId));
    final zone = ref.watch(zoneProvider);

    return fishAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Fejl: $e'))),
      data: (fish) {
        if (fish == null) {
          return const Scaffold(
            body: Center(child: Text('Art ikke fundet.')),
          );
        }
        return _DetailContent(fish: fish, zone: zone);
      },
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Fish fish;
  final FishingZone zone;

  const _DetailContent({required this.fish, required this.zone});

  @override
  Widget build(BuildContext context) {
    final result = checkSeason(fish, zone, DateTime.now());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(fish.nameDa)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Illustration placeholder
            Container(
              height: 200,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Center(
                child: SvgPicture.asset(
                  fish.imageAsset,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => Icon(
                    Icons.set_meal_outlined,
                    size: 80,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fish.nameDa,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(fish.nameLatin,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      )),
                  const SizedBox(height: 16),
                  _StatusBanner(result: result),
                  const SizedBox(height: 20),
                  _InfoGrid(fish: fish, zone: zone),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          GoRouter.of(context).push('/fish/${fish.id}/measure'),
                      icon: const Icon(Icons.straighten),
                      label: const Text('Tjek din fangst →'),
                    ),
                  ),
                  if (fish.localRules.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _LocalRulesSection(fish: fish),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Kilde: lfst.dk · Opdateret jan 2025',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final SeasonResult result;

  const _StatusBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String text;
    switch (result.status) {
      case SeasonStatus.open:
        bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32); text = 'Åben sæson';
      case SeasonStatus.closed:
        bg = const Color(0xFFFFEBEE); fg = const Color(0xFFC62828);
        text = result.reopensOn != null
            ? 'Fredet — åbner ${du.formatDanishDate(result.reopensOn!)}'
            : 'Fredet';
      case SeasonStatus.checkSize:
        bg = const Color(0xFFFFF8E1); fg = const Color(0xFFF57F17); text = 'Kontrollér mål';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            switch (result.status) {
              SeasonStatus.open => Icons.check_circle_outline,
              SeasonStatus.closed => Icons.do_not_disturb_outlined,
              SeasonStatus.checkSize => Icons.straighten,
            },
            color: fg,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final Fish fish;
  final FishingZone zone;

  const _InfoGrid({required this.fish, required this.zone});

  String _formatMin(double? min) =>
      min != null ? '${min.toInt()} cm' : 'Intet mindstemål';

  String _formatSeasons(List<ClosedSeason> seasons) {
    if (seasons.isEmpty) return 'Ingen';
    return seasons
        .map((cs) => du.formatClosedSeasonRange(
            cs.startMonth, cs.startDay, cs.endMonth, cs.endDay))
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final hasSalt = fish.environment.contains('salt');
    final hasFresh = fish.environment.contains('fresh');
    final hasBoth = hasSalt && hasFresh;

    final saltMin = zone == FishingZone.nordsoeSkagerrak
        ? fish.minimumSizeCm.nordsoeSkagerrak
        : fish.minimumSizeCm.kattegatBaelterOestersoe;
    final freshMin = fish.minimumSizeCm.ferskvand;

    final saltSeasons = fish.closedSeason
        .where((cs) => cs.zone == 'salt' || cs.zone == 'all')
        .toList();
    final freshSeasons = fish.closedSeason
        .where((cs) => cs.zone == 'ferskvand' || cs.zone == 'all')
        .toList();

    return Column(
      children: [
        if (hasBoth) ...[
          _InfoRow(
            icon: Icons.straighten,
            label: 'Mindstemål saltvand',
            value: _formatMin(saltMin),
          ),
          _InfoRow(
            icon: Icons.straighten,
            label: 'Mindstemål ferskvand',
            value: _formatMin(freshMin),
          ),
        ] else
          _InfoRow(
            icon: Icons.straighten,
            label: 'Mindstemål',
            value: hasSalt ? _formatMin(saltMin) : _formatMin(freshMin),
          ),
        if (hasBoth) ...[
          _InfoRow(
            icon: Icons.event_busy,
            label: 'Fredningstid saltvand',
            value: _formatSeasons(saltSeasons),
          ),
          _InfoRow(
            icon: Icons.event_busy,
            label: 'Fredningstid ferskvand',
            value: _formatSeasons(freshSeasons),
          ),
        ] else
          _InfoRow(
            icon: Icons.event_busy,
            label: 'Fredningstid',
            value: hasSalt
                ? _formatSeasons(saltSeasons)
                : _formatSeasons(freshSeasons),
          ),
        _InfoRow(
          icon: Icons.numbers,
          label: 'Dagkvote',
          value: fish.dailyLimit != null
              ? '${fish.dailyLimit} stk.'
              : 'Ingen begrænsning',
        ),
        _InfoRow(
          icon: Icons.water,
          label: 'Farvand',
          value: fish.environment
              .map((e) => e == 'salt' ? 'Saltvand' : 'Ferskvand')
              .join(' / '),
        ),
        if (fish.notes != null)
          _InfoRow(
            icon: Icons.info_outline,
            label: 'Bemærkning',
            value: fish.notes!,
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _LocalRulesSection extends StatelessWidget {
  final Fish fish;

  const _LocalRulesSection({required this.fish});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lokale særregler',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...fish.localRules.map(
          (rule) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: '${rule.location}: ',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: rule.note),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
