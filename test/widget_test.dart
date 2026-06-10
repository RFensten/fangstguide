import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fangstguide/shared/utils/season_checker.dart';
import 'package:fangstguide/shared/widgets/status_badge.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('StatusBadge viser korrekt tekst for hver status',
      (tester) async {
    await tester.pumpWidget(wrap(const StatusBadge(status: SeasonStatus.open)));
    expect(find.text('Åben'), findsOneWidget);

    await tester
        .pumpWidget(wrap(const StatusBadge(status: SeasonStatus.closed)));
    expect(find.text('Fredet'), findsOneWidget);

    await tester
        .pumpWidget(wrap(const StatusBadge(status: SeasonStatus.checkSize)));
    expect(find.text('Tjek mål'), findsOneWidget);
  });
}
