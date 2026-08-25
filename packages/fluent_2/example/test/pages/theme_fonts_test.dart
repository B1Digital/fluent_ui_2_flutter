import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Fonts is a specimen sheet: four groups, each row naming a token and drawing
/// a preview *at* that token. So the only defect it can carry is a preview that
/// does not answer to the name beside it — a size row set at the wrong size, a
/// weight row all in regular, a line-height band whose box is not the height it
/// is measuring. Every test below reads a preview's own geometry or style and
/// compares it with the token its row names.
void main() {
  const String page = 'theme-fonts';

  const List<(String, double)> sizes = <(String, double)>[
    ('fontSizeBase100', FluentFontSize.base100),
    ('fontSizeBase200', FluentFontSize.base200),
    ('fontSizeBase300', FluentFontSize.base300),
    ('fontSizeBase400', FluentFontSize.base400),
    ('fontSizeBase500', FluentFontSize.base500),
    ('fontSizeBase600', FluentFontSize.base600),
    ('fontSizeHero700', FluentFontSize.hero700),
    ('fontSizeHero800', FluentFontSize.hero800),
    ('fontSizeHero900', FluentFontSize.hero900),
    ('fontSizeHero1000', FluentFontSize.hero1000),
  ];
  const List<(String, FontWeight)> weights = <(String, FontWeight)>[
    ('fontWeightRegular', FluentFontWeight.regular),
    ('fontWeightMedium', FluentFontWeight.medium),
    ('fontWeightSemibold', FluentFontWeight.semibold),
    ('fontWeightBold', FluentFontWeight.bold),
  ];
  const List<(String, double)> lineHeights = <(String, double)>[
    ('lineHeightBase100', FluentLineHeight.base100),
    ('lineHeightBase200', FluentLineHeight.base200),
    ('lineHeightBase300', FluentLineHeight.base300),
    ('lineHeightBase400', FluentLineHeight.base400),
    ('lineHeightBase500', FluentLineHeight.base500),
    ('lineHeightBase600', FluentLineHeight.base600),
    ('lineHeightHero700', FluentLineHeight.hero700),
    ('lineHeightHero800', FluentLineHeight.hero800),
    ('lineHeightHero900', FluentLineHeight.hero900),
    ('lineHeightHero1000', FluentLineHeight.hero1000),
  ];

  group('the groups', () {
    testWidgets('all four ramps are headed and complete', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      for (final String heading in <String>[
        'Font family',
        'Font size',
        'Font weight',
        'Line height',
      ]) {
        expect(find.text(heading), findsOneWidget, reason: heading);
      }
      for (final String name in <String>[
        'fontFamilyBase',
        'fontFamilyMonospace',
        'fontFamilyNumeric',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      // Twice each: once as the row's name, once as its own preview.
      for (final (String name, double _) in <(String, double)>[
        ...sizes,
        ...lineHeights,
      ]) {
        expect(find.text(name), findsNWidgets(2), reason: name);
      }
      for (final (String name, FontWeight _) in weights) {
        expect(find.text(name), findsOneWidget, reason: name);
        expect(find.text('Font weight $name'), findsOneWidget);
      }
    });
  });

  group('font family', () {
    testWidgets('each preview is set in the stack it prints', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      // The preview is the only place the stack is real: the row prints the
      // family names as prose, and a preview left in the base face would print
      // "Consolas, Courier New…" in Selawik and look entirely convincing.
      const List<(String, String, List<String>)> families =
          <(String, String, List<String>)>[
            (
              'fontFamilyBase',
              FluentFontFamily.base,
              FluentFontFamily.baseFallback,
            ),
            (
              'fontFamilyMonospace',
              FluentFontFamily.monospace,
              FluentFontFamily.monospaceFallback,
            ),
            (
              'fontFamilyNumeric',
              FluentFontFamily.numeric,
              FluentFontFamily.numericFallback,
            ),
          ];
      for (final (String name, String family, List<String> fallback)
          in families) {
        final String stack = <String>[family, ...fallback].join(', ');
        expect(find.text(stack), findsOneWidget, reason: '$name prints $stack');
        final TextStyle? painted = textStyleOf(tester, find.text(stack));
        expect(painted?.fontFamily, family, reason: '$name preview family');
        expect(painted?.fontFamilyFallback, fallback, reason: '$name fallback');
        expect(
          painted?.fontSize,
          FluentFontSize.base300,
          reason: 'a family preview is set at the base size, not at a hero one',
        );
      }
    });
  });

  group('font size', () {
    testWidgets('every preview is set at its own token', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      for (final (String name, double size) in sizes) {
        final Finder preview = find.text(name).last;
        expect(
          textStyleOf(tester, preview)?.fontSize,
          size,
          reason: '$name is previewed at the wrong size',
        );
        // Line height 1 makes the box exactly one em per line, so the rendered
        // height is the token itself — the measurement the row is making. The
        // multiple absorbs the test font, whose square glyphs wrap the longest
        // names onto a second line at hero sizes.
        final double height = tester.getRect(preview).height;
        expect(
          height % size,
          0,
          reason: '$name renders $height, which is no whole multiple of $size',
        );
      }
    });

    testWidgets('the ramp is drawn in ascending order', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      double previousTop = -1;
      double previousSize = 0;
      for (final (String name, double size) in sizes) {
        final Rect preview = tester.getRect(find.text(name).last);
        expect(preview.top, greaterThan(previousTop), reason: '$name position');
        expect(size, greaterThan(previousSize), reason: '$name size');
        previousTop = preview.top;
        previousSize = size;
      }
    });
  });

  group('font weight', () {
    testWidgets('every preview is set at its own token', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      for (final (String name, FontWeight weight) in weights) {
        expect(
          textStyleOf(tester, find.text('Font weight $name'))?.fontWeight,
          weight,
          reason: '$name is previewed at the wrong weight',
        );
        expect(
          textStyleOf(tester, find.text('Font weight $name'))?.fontSize,
          FluentFontSize.base300,
          reason: 'weight is the variable here, so size must not be',
        );
      }
    });
  });

  group('line height', () {
    testWidgets('every band is exactly its own token tall', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final Color band = FluentTheme.of(
        tester.element(find.text('Line height')),
      ).colors.neutralBackground4;

      // The band *is* the measurement — a 14px line inside a box exactly one
      // line-height tall — so its rendered height is the assertion. Collected
      // in tree order rather than by row lookup, which also proves there are
      // ten of them and no more.
      final List<Element> bands = find
          .byWidgetPredicate(
            (Widget widget) => widget is Container && widget.color == band,
          )
          .evaluate()
          .toList();
      expect(bands, hasLength(lineHeights.length));

      for (final (int i, (String name, double height)) in lineHeights.indexed) {
        final Finder swatch = find.byWidget(bands[i].widget);
        expect(
          tester.getRect(swatch).height,
          height,
          reason: '$name is measured by a box that is not $height tall',
        );
        expect(
          find.descendant(of: swatch, matching: find.text(name)),
          findsOneWidget,
          reason: 'band $i must be labelled $name',
        );
        expect(
          textStyleOf(
            tester,
            find.descendant(of: swatch, matching: find.text(name)),
          )?.fontSize,
          FluentFontSize.base300,
          reason: 'line height is the variable here, so size must not be',
        );
      }
    });
  });

  group('lifecycle', () {
    testWidgets('a real click on a specimen changes nothing', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final String before = textSnapshot(tester);

      // The page is a specimen sheet, not a control surface. A pointer press
      // has to be inert rather than throwing or revealing an affordance — which
      // a synthetic tap could not tell apart, since it never hovers.
      await mouseClick(tester, find.text('fontSizeBase500').last);
      expect(textSnapshot(tester), before);
    });

    testWidgets('the page unmounts without throwing', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      await expectCleanTeardown(tester, page);
    });
  });
}
