import 'package:flutter/material.dart';
import '../../shared/utils/season_checker.dart';

class StatusBadge extends StatelessWidget {
  final SeasonStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color fg;
    switch (status) {
      case SeasonStatus.open:
        label = 'Åben'; bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32);
      case SeasonStatus.closed:
        label = 'Fredet'; bg = const Color(0xFFFFEBEE); fg = const Color(0xFFC62828);
      case SeasonStatus.checkSize:
        label = 'Tjek mål'; bg = const Color(0xFFFFF8E1); fg = const Color(0xFFF57F17);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
