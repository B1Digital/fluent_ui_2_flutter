import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web_example/storybook/components/all_stories.dart';
import 'package:fluent_2_web_example/storybook/components/charts_showcase_stories.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the `Charts showcase/` shelf.
///
/// These stories exist to be looked at, so the failure that matters is a rail
/// that throws while a human is scrolling past it — a layout assertion, an
/// unsatisfied constraint, an axis that cannot resolve its domain. Naming the
/// stories in a list would not catch any of that, so every one is mounted.
void main() {
  test('every showcase story is registered exactly once', () {
    final registered = allStories.map((story) => story.name).toList();
    for (final story in chartsShowcaseStories) {
      expect(
        registered.where((name) => name == story.name).length,
        1,
        reason:
            '${story.name} is built by charts_showcase_stories.dart but is not '
            'reachable from all_stories.dart, so nobody can open it',
      );
    }
  });

  test('every showcase story carries a description', () {
    for (final story in chartsShowcaseStories) {
      expect(
        story.description,
        isNotNull,
        reason:
            '${story.name} needs the one line naming the capability it shows, '
            'which is the only label the storybook sidebar renders',
      );
    }
  });

  for (final story in chartsShowcaseStories) {
    testWidgets('${story.name} builds every rail without throwing', (
      tester,
    ) async {
      // Wide enough for the 700-pixel cartesian rails plus the DemoRail gutter,
      // and tall enough for the five-rail line chart story. Not a golden, so
      // the surface only has to exceed the demo column.
      await tester.binding.setSurfaceSize(const Size(1500, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
        reason: '${story.name} must build with the sample data as written',
      );
    });
  }
}
