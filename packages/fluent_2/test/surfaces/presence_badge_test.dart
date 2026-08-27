import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Visual parity for `FluentPresenceBadge` is covered by
/// `test/goldens/presence_badge_golden_test.dart`; this file exists for the
/// semantics contract, which a golden cannot see.
void main() {
  const key = Key('presence');

  Future<void> pump(WidgetTester tester, Widget badge) => tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: badge),
    ),
  );

  group('accessibility', () {
    testWidgets('it announces its status under the status role', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentPresenceBadge(key: key, status: FluentPresenceStatus.busy),
      );
      final node = tester.getSemantics(find.byKey(key));
      expect(node, matchesSemantics(label: 'Busy'));
      // `matchesSemantics` gained a `role` argument after this package's
      // Flutter floor, so the role is read off the node instead.
      expect(node.role, SemanticsRole.status);
    });

    testWidgets('a custom label keeps the role', (tester) async {
      await pump(
        tester,
        const FluentPresenceBadge(
          key: key,
          status: FluentPresenceStatus.away,
          semanticLabel: 'In a meeting',
        ),
      );
      final node = tester.getSemantics(find.byKey(key));
      expect(node, matchesSemantics(label: 'In a meeting'));
      expect(node.role, SemanticsRole.status);
    });

    testWidgets('the role and a live region never coexist', (tester) async {
      // `SemanticsRole.status` and `isLiveRegion` cannot sit on one node
      // (`semantics.dart:182`, `_noLiveRegion`), and the check runs against
      // merged data — so a caller that merges a live region over the badge
      // would throw. Pinning `isLiveRegion: false` is what keeps someone from
      // "improving" the badge by adding one.
      await pump(
        tester,
        const FluentPresenceBadge(
          key: key,
          status: FluentPresenceStatus.available,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(label: 'Available', isLiveRegion: false),
      );
    });
  });
}
