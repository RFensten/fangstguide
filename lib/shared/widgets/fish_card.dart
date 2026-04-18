import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/fish.dart';
import '../../providers/zone_provider.dart';
import '../../shared/utils/season_checker.dart';
import 'status_badge.dart';

class FishCard extends ConsumerWidget {
  final Fish fish;
  final VoidCallback onTap;

  const FishCard({
    super.key,
    required this.fish,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zone = ref.watch(zoneProvider);
    final result = checkSeason(fish, zone, DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _FishThumbnail(imageAsset: fish.imageAsset),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fish.nameDa,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      fish.nameLatin,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: result.status),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _FishThumbnail extends StatelessWidget {
  final String imageAsset;

  const _FishThumbnail({required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SvgPicture.asset(
          imageAsset,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => Icon(
            Icons.set_meal_outlined,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
