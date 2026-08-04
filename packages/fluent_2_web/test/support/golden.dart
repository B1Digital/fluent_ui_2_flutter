/// Golden-image harness: a **regression net**, not a fidelity check.
///
/// These images catch *unintended* visual change between commits — a padding
/// that moved, a token that stopped resolving, a surface that went transparent.
/// They prove nothing about whether the component matches Figma, because the
/// `flutter test` does not register bundled application fonts, so it substitutes
/// a deterministic placeholder font whose glyphs are all identical boxes.
/// Figma fidelity is asserted numerically by `spec_fixture.dart` against
/// `test/fixtures/*.json`.
///
/// The open-source Selawik substitute is bundled for real applications but is
/// deliberately not loaded by this harness. The placeholder font is what makes
/// these goldens reproduce across machines.
///
/// ## Using it
///
/// ```dart
/// goldenGridTest('badge', () => goldenGrid(<Widget>[...], columns: 4));
/// ```
///
/// That emits one image per theme into `test/goldens/goldens/`. Regenerate with
/// `flutter test --update-goldens test/goldens/`, then re-run without the flag.
library;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Marks the subtree the golden is captured from, so the image is exactly the
/// grid's own size rather than the whole 1200x900 test surface.
const Key _boundary = Key('golden-boundary');

/// Inset between the grid and the edge of the captured image.
const double _margin = FluentSpacing.l;

/// The three themes every component grid is captured in.
///
/// High contrast is not optional garnish: it is the mode nobody looks at, and
/// the one where a hardcoded transparent surface silently disappears.
Map<String, FluentThemeData> goldenThemes() => <String, FluentThemeData>{
  'light': FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
  'dark': FluentThemeData.dark(fontPlatform: FluentFontPlatform.web),
  'high_contrast': FluentThemeData.highContrast(
    fontPlatform: FluentFontPlatform.web,
  ),
};

/// Renders [child] under [theme] and compares it to `goldens/<name>.png`.
///
/// [surfaceSize] only bounds layout — the captured image is cropped to the
/// child, so a generous surface costs nothing but avoids overflow.
///
/// [elapsed] pumps a single frame that far into the future instead of settling.
/// Skeleton, Spinner and ProgressBar loop forever, so `pumpAndSettle` would time
/// out on them; a fixed elapsed time picks one deterministic frame of the loop.
///
/// [reducedMotion] captures the `MediaQuery.disableAnimations` code path, which
/// is a genuinely different appearance for those three, not just a faster one.
Future<void> expectGolden(
  WidgetTester tester,
  String name,
  Widget child, {
  FluentThemeData? theme,
  Size? surfaceSize,
  Duration? elapsed,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = surfaceSize ?? const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final data =
      theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  await tester.pumpWidget(
    FluentApp(
      theme: data,
      // The banner is painted over the app in debug and would land in the image.
      debugShowCheckedModeBanner: false,
      builder: reducedMotion
          ? (context, child) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: child!,
            )
          : null,
      home: Center(
        child: RepaintBoundary(
          key: _boundary,
          // Inside the boundary, so the captured PNG has an opaque background
          // rather than showing whatever the viewer's image tool puts behind
          // alpha. Also what makes a light-on-light regression visible.
          child: ColoredBox(
            color: data.colors.neutralBackground1,
            child: Padding(
              padding: const EdgeInsets.all(_margin),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );

  if (elapsed == null) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(elapsed);
  }

  await expectLater(
    find.byKey(_boundary),
    matchesGoldenFile('goldens/$name.png'),
  );
}

/// Lays [cells] out in rows of [columns].
///
/// One image of every variant beats 150 one-variant images: a reviewer diffs a
/// single PNG per component per theme and sees which cell moved. Cells are not
/// labelled — the placeholder test font draws every glyph as the same box, so a
/// caption would be noise. The cell order is the order in the test file, which
/// is the legend.
Widget goldenGrid(List<Widget> cells, {int columns = 4, double gap = 16}) =>
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: gap,
      children: <Widget>[
        for (var i = 0; i < cells.length; i += columns)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: gap,
            children: cells.sublist(
              i,
              i + columns > cells.length ? cells.length : i + columns,
            ),
          ),
      ],
    );

/// Registers one golden test per theme for [component].
///
/// [build] is called once per theme rather than shared, so a cell may hold
/// state without leaking between images.
void goldenGridTest(
  String component,
  Widget Function() build, {
  Size? surfaceSize,
  Duration? elapsed,
  bool reducedMotion = false,
  String suffix = '',
}) {
  goldenThemes().forEach((name, theme) {
    testWidgets('$component$suffix — $name', (tester) async {
      await expectGolden(
        tester,
        '$component$suffix.$name',
        build(),
        theme: theme,
        surfaceSize: surfaceSize,
        elapsed: elapsed,
        reducedMotion: reducedMotion,
      );
    });
  });
}
