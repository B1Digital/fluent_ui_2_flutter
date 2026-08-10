import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web_example/storybook/components/all_stories.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the two spec §9 storybook entries this plan owns.
///
/// The existing `storybook_smoke_test.dart` proves the storybook compiles and
/// that names are unique; this file proves polar and sankey are actually on the
/// shelf, which is the gap the programme audit found.
void main() {
  test('the polar and sankey charts are on the shelf exactly once', () {
    final names = allStories.map((story) => story.name).toList();
    expect(
      names.where((name) => name == 'Charts/FluentPolarChart').length,
      1,
      reason:
          'spec section 9 requires a storybook entry for all 20 components, and '
          'FluentPolarChart is one of the two this plan owns',
    );
    expect(
      names.where((name) => name == 'Charts/FluentSankeyChart').length,
      1,
      reason:
          'spec section 9 requires a storybook entry for all 20 components, and '
          'FluentSankeyChart is the other one this plan owns',
    );
  });

  // Being on the shelf is not the same as being buildable: every rail mounts a
  // real chart, so a layout assertion inside one would sail past the check
  // above and only surface when a human opened the storybook.
  for (final name in const [
    'Charts/FluentPolarChart',
    'Charts/FluentSankeyChart',
  ]) {
    testWidgets('$name builds every rail without throwing', (tester) async {
      // Tall enough for the four sankey rails; the surface only has to exceed
      // the demo column, it is not a golden.
      await tester.binding.setSurfaceSize(const Size(1400, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final story = allStories.singleWhere((story) => story.name == name);
      await tester.pumpWidget(
        FluentTheme(
          data: FluentThemeData.light(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SingleChildScrollView(
              child: Builder(builder: story.builder),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '$name must build with the upstream story data as written',
      );
    });
  }
}
