import 'package:fluent_2_gallery/gallery/gallery_app.dart';
import 'package:fluent_2_gallery/gallery/story.dart';
import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The gallery is also a composition test: every story builds the real
/// component against the real theme, so a page that renders is evidence the
/// component composes outside its own test file.
void main() {
  final section = StorySection(
    component: 'Probe',
    stories: [
      Story(
        name: 'Default',
        description: 'A probe story.',
        knobs: const [BoolKnob(label: 'On', id: 'on', initial: true)],
        builder: (context) => FluentButton(
          onPressed: () {},
          child: Text('${KnobsScope.of(context).get<bool>('on', false)}'),
        ),
      ),
    ],
  );

  testWidgets('renders a story with its knob value applied', (tester) async {
    // The gallery is a desktop layout; the default 800x600 test surface is
    // narrower than its own sidebar plus canvas.
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GalleryApp(sections: [section]));
    await tester.pumpAndSettle();

    expect(find.text('Probe'), findsWidgets);
    expect(find.text('true'), findsOneWidget, reason: 'knob initial applied');
  });

  testWidgets('every theme resolves without throwing', (tester) async {
    for (final theme in GalleryTheme.values) {
      expect(() => theme.resolve(null), returnsNormally, reason: theme.label);
      expect(theme.resolve(null), isA<FluentThemeData>());
    }
    // A custom brand key must rebrand every theme except high contrast, which
    // has no brand colour at all.
    const key = Color(0xFF780510);
    expect(
      GalleryTheme.webLight.resolve(key).colors.brand,
      isNot(GalleryTheme.webLight.resolve(null).colors.brand),
    );
    expect(
      GalleryTheme.highContrast.resolve(key).colors.brandBackground,
      GalleryTheme.highContrast.resolve(null).colors.brandBackground,
    );
  });
}
