import 'package:fluent_2_web_example/main.dart';
import 'package:fluent_2_web_example/storybook/components/all_stories.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A smoke test over the storybook.
///
/// Two reasons beyond "the package needs a test". `melos run test` matches any
/// package with a `test/` directory and `flutter test` exits non-zero when it
/// finds none — so without this the whole CI gate fails on an empty folder.
/// More usefully, a story that fails to **compile** breaks the GitHub Pages
/// deploy, which builds this app on every push to `main`; importing
/// `all_stories.dart` here forces every story file through the compiler, so
/// that lands as a red test instead of a failed deploy.
///
/// Individual stories are deliberately not built in isolation: any story using
/// `context.knobs` needs Storybook's own `KnobsNotifier` above it, so mounting
/// one outside the shell throws a `ProviderNotFoundException` that says nothing
/// about the story.
void main() {
  testWidgets('the storybook app boots', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const StorybookApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  test('every story has a unique, grouped name', () {
    final names = allStories.map((story) => story.name).toList();
    expect(
      names.toSet().length,
      names.length,
      reason: 'two stories share a name, so one is unreachable',
    );
    expect(names.every((name) => name.contains('/')), isTrue);
  });

  test('the date and time components are on the shelf', () {
    final names = allStories.map((story) => story.name).toSet();
    expect(
      names,
      containsAll(<String>[
        'Inputs/FluentCalendar',
        'Inputs/FluentDatePicker',
        'Inputs/FluentTimePicker',
      ]),
    );
  });
}
