/// Golden-image harness: a **regression net**, not a fidelity check.
///
/// These images catch *unintended* visual change between commits — a padding
/// that moved, a token that stopped resolving, a surface that went transparent.
/// They prove nothing about whether the component matches Figma: that is
/// asserted numerically by `spec_fixture.dart` against `test/fixtures/*.json`.
///
/// ## Linux amd64 owns the images
///
/// The images hold real glyphs. `test/flutter_test_config.dart` loads Selawik
/// and both Fluent System Icons fonts before every test, so text and icons
/// render as they do in a release Web build. Glyphs are what the engine does
/// not rasterise the same everywhere: the macOS `flutter_tester` draws them
/// through CoreText, heavier and with a wider anti-aliased edge, while the
/// Linux one uses the FreeType it links statically and reads no system font.
/// Paths and gradients also round one level apart on arm64 and x86.
///
/// So the images are recorded where CI compares them: Linux amd64, `TZ=UTC`,
/// Flutter 3.47.1, from the pinned image in `test/goldens/Dockerfile`.
/// Anywhere else [expectGolden] still builds and settles the widget, so a
/// component that throws or never settles fails on any machine, but skips the
/// comparison, because every image with a glyph in it would fail. On a CI
/// runner (the `CI` environment variable is set) it fails instead: a runner
/// that moved off Linux amd64 must not pass by skipping every golden.
///
/// ## Using it
///
/// ```dart
/// goldenGridTest('badge', () => goldenGrid(<Widget>[...], columns: 4));
/// ```
///
/// That emits one image per theme into `test/goldens/goldens/`. From the
/// repository root, `dart run melos run goldens` checks them in the pinned
/// image and `dart run melos run goldens:update` regenerates them; see
/// `test/goldens/README.md`.
library;

import 'dart:ffi' show Abi;
import 'dart:io' show Platform;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Marks the subtree the golden is captured from, so the image is exactly the
/// grid's own size rather than the whole 1200x900 test surface.
const Key _boundary = Key('golden-boundary');

/// Inset between the grid and the edge of the captured image.
const double _margin = FluentSpacing.l;

/// Why goldens are not compared on this machine, or null on Linux amd64,
/// the only platform the images are recorded on.
final String? _goldenSkipReason = Abi.current() == Abi.linuxX64
    ? null
    : 'golden images are recorded on Linux amd64, not ${Abi.current()}; '
          'run them with `dart run melos run goldens`';

/// Whether this is a CI run, where a golden that cannot be compared means the
/// runner changed, not that a developer is on a Mac.
final bool _onCi = Platform.environment.containsKey('CI');

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

  // Only the pixel comparison is platform-bound; the build and settle above
  // ran everywhere.
  final skipReason = _goldenSkipReason;
  if (skipReason != null) {
    if (_onCi) fail('$skipReason. A CI runner must compare goldens.');
    markTestSkipped(skipReason);
    return;
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
/// labelled: a caption would be text the component did not draw. The cell
/// order is the order in the test file, which is the legend.
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
