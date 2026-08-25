import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/docs_metrics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Typography has no controls: it is one 18-row table whose every cell is
/// *computed* from the live theme, which is exactly the claim worth testing.
/// A transcribed table can drift from the ramp it describes silently — the row
/// prints `fontSize: 12px` while its specimen is drawn at 14 — so the tests
/// below never assert a literal. Each one compares what a row PRINTS against
/// what its own specimen was RENDERED with, and both against the theme.
void main() {
  const String page = 'theme-typography';

  /// The ramp the page walks, keyed the way the Name column spells it.
  ///
  /// Written out because `FluentTypography` exposes 18 named fields rather than
  /// a map — the same reason the page writes it out.
  Map<String, TextStyle> ramp(FluentTypography t) => <String, TextStyle>{
    'caption2': t.caption2,
    'caption2Strong': t.caption2Strong,
    'caption1': t.caption1,
    'caption1Strong': t.caption1Strong,
    'caption1Stronger': t.caption1Stronger,
    'body1': t.body1,
    'body1Strong': t.body1Strong,
    'body1Stronger': t.body1Stronger,
    'body2': t.body2,
    'body2Strong': t.body2Strong,
    'subtitle2': t.subtitle2,
    'subtitle2Stronger': t.subtitle2Stronger,
    'subtitle1': t.subtitle1,
    'title3': t.title3,
    'title2': t.title2,
    'title1': t.title1,
    'largeTitle': t.largeTitle,
    'display': t.display,
  };

  /// The global ramps, keyed by the token name the Tokens column prints.
  const Map<String, double> fontSizeTokens = <String, double>{
    'fontSizeBase100': FluentFontSize.base100,
    'fontSizeBase200': FluentFontSize.base200,
    'fontSizeBase300': FluentFontSize.base300,
    'fontSizeBase400': FluentFontSize.base400,
    'fontSizeBase500': FluentFontSize.base500,
    'fontSizeBase600': FluentFontSize.base600,
    'fontSizeHero700': FluentFontSize.hero700,
    'fontSizeHero800': FluentFontSize.hero800,
    'fontSizeHero900': FluentFontSize.hero900,
    'fontSizeHero1000': FluentFontSize.hero1000,
  };
  const Map<String, double> lineHeightTokens = <String, double>{
    'lineHeightBase100': FluentLineHeight.base100,
    'lineHeightBase200': FluentLineHeight.base200,
    'lineHeightBase300': FluentLineHeight.base300,
    'lineHeightBase400': FluentLineHeight.base400,
    'lineHeightBase500': FluentLineHeight.base500,
    'lineHeightBase600': FluentLineHeight.base600,
    'lineHeightHero700': FluentLineHeight.hero700,
    'lineHeightHero800': FluentLineHeight.hero800,
    'lineHeightHero900': FluentLineHeight.hero900,
    'lineHeightHero1000': FluentLineHeight.hero1000,
  };
  const Map<String, FontWeight> weightTokens = <String, FontWeight>{
    'fontWeightRegular': FluentFontWeight.regular,
    'fontWeightMedium': FluentFontWeight.medium,
    'fontWeightSemibold': FluentFontWeight.semibold,
    'fontWeightBold': FluentFontWeight.bold,
  };

  /// The ten `Text`s of one ramp row: the key, four token lines, four value
  /// lines, then the specimen.
  List<Text> cellsOf(WidgetTester tester, String key) => tester
      .widgetList<Text>(
        find.descendant(
          of: find
              .ancestor(of: find.text(key), matching: find.byType(Row))
              .first,
          matching: find.byType(Text),
        ),
      )
      .toList();

  group('the ramp table', () {
    testWidgets('prints every style in the theme, once', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final FluentTypography type = FluentTheme.of(
        tester.element(find.text('Name')),
      ).typography;

      for (final String key in ramp(type).keys) {
        expect(
          find.text(key),
          findsOneWidget,
          reason: '$key has no row on the typography page',
        );
      }
      for (final String header in <String>[
        'Name',
        'Tokens',
        'Default Values',
        'Example',
      ]) {
        expect(find.text(header), findsOneWidget);
      }
    });

    testWidgets('every specimen is drawn in its own style from the theme', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final FluentTypography type = FluentTheme.of(
        tester.element(find.text('Name')),
      ).typography;

      ramp(type).forEach((String key, TextStyle style) {
        final List<Text> cells = cellsOf(tester, key);
        expect(cells, hasLength(10), reason: '$key row shape');
        final String specimen = cells.last.data ?? '';
        // The specimen spells its own key, so a row cannot show `body1`'s
        // sample text beside `caption2`'s name.
        expect(
          specimen.toLowerCase().replaceAll(' ', ''),
          key.toLowerCase(),
          reason: '$key is illustrated by "$specimen"',
        );

        final TextStyle? painted = textStyleOf(tester, find.text(specimen));
        expect(painted?.fontSize, style.fontSize, reason: '$key size');
        expect(painted?.fontWeight, style.fontWeight, reason: '$key weight');
        expect(painted?.height, style.height, reason: '$key line height');
        expect(painted?.fontFamily, style.fontFamily, reason: '$key family');
      });
    });

    testWidgets('the Default Values column describes its own specimen', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final FluentTypography type = FluentTheme.of(
        tester.element(find.text('Name')),
      ).typography;

      // This is the whole point of a generated table: the numbers printed in a
      // row and the type its neighbouring cell is set in come from one source.
      // A hand-transcribed table drifts here and nowhere else.
      for (final String key in ramp(type).keys) {
        final List<Text> cells = cellsOf(tester, key);
        final TextStyle? painted = textStyleOf(
          tester,
          find.text(cells.last.data ?? ''),
        );
        final double size = painted!.fontSize!;
        expect(cells[6].data, 'fontSize: ${size.toStringAsFixed(0)}px');
        expect(cells[7].data, 'fontWeight: ${painted.fontWeight!.value}');
        expect(
          cells[8].data,
          'lineHeight: ${(size * painted.height!).roundToDouble().toStringAsFixed(0)}px',
        );
        expect(cells[5].data, startsWith('fontFamily: '));
        expect(
          cells[5].data,
          contains("'${painted.fontFamily}'"),
          reason: '$key prints a family its specimen is not set in',
        );
      }
    });

    testWidgets('the Tokens column names tokens that carry the row\'s values', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final FluentTypography type = FluentTheme.of(
        tester.element(find.text('Name')),
      ).typography;

      // A named token has to *be* the value beside it. Rows whose resolved
      // value sits on no published stop print an em dash instead, which is the
      // honest answer and is left alone here.
      for (final String key in ramp(type).keys) {
        final List<Text> cells = cellsOf(tester, key);
        final TextStyle? painted = textStyleOf(
          tester,
          find.text(cells.last.data ?? ''),
        );
        expect(cells[1].data, 'fontFamilyBase');

        final String sizeToken = cells[2].data ?? '';
        if (fontSizeTokens.containsKey(sizeToken)) {
          expect(
            fontSizeTokens[sizeToken],
            painted!.fontSize,
            reason: '$key names $sizeToken but is set at ${painted.fontSize}',
          );
        } else {
          expect(sizeToken, '—', reason: '$key size token');
        }

        final String weightToken = cells[3].data ?? '';
        expect(
          weightTokens[weightToken],
          painted!.fontWeight,
          reason: '$key names $weightToken but is set at ${painted.fontWeight}',
        );

        final String heightToken = cells[4].data ?? '';
        if (lineHeightTokens.containsKey(heightToken)) {
          expect(
            lineHeightTokens[heightToken],
            (painted.fontSize! * painted.height!).roundToDouble(),
            reason: '$key names $heightToken but its line box is not that tall',
          );
        } else {
          expect(heightToken, '—', reason: '$key line-height token');
        }
      }
    });

    testWidgets('the rows render in the order the page declares them', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final FluentTypography type = FluentTheme.of(
        tester.element(find.text('Name')),
      ).typography;

      // Order is upstream's, and only order: `body1Stronger` is 16px and
      // `body2` is 14 on the mobile ramps, so "ascending size" is a property of
      // the web ramp rather than of the table. What the table must not do is
      // shuffle, drop or repeat a row — every one of the eighteen appears once,
      // below the one declared before it.
      double previous = -1;
      for (final String key in ramp(type).keys) {
        final double top = tester.getRect(find.text(key)).top;
        expect(
          top,
          greaterThan(previous),
          reason: '$key is not below the row declared before it',
        );
        previous = top;
      }
    });
  });

  group('the callout', () {
    testWidgets('renders both sentences and the drawn info glyph', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      expect(find.textContaining('fully leverage the tokens'), findsOneWidget);
      expect(
        find.textContaining('Text component documentation'),
        findsOneWidget,
      );
      // The glyph is drawn rather than typed, because whether a colour emoji
      // renders at all depends on a font the host happens to ship.
      expect(find.text('i'), findsOneWidget);
    });

    testWidgets('the doc reference is styled as a link but is inert', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final Finder line = find.textContaining('Text component documentation');
      final String before = textSnapshot(tester);

      final List<TextSpan> linkRuns = inlineRuns(
        tester,
        line,
        (TextStyle style) => style.color == DocsMetrics.sidebarSelected,
      );
      expect(
        linkRuns.map((TextSpan span) => span.text),
        <String>['Text component documentation'],
        reason: 'exactly the reference run is painted in the link blue',
      );
      expect(linkRuns.single.style!.decoration, TextDecoration.underline);

      // A real press, because the shell owns navigation and a body has no route
      // to hand it: the run must be inert rather than throwing on a click.
      await mouseClick(tester, line);
      expect(
        textSnapshot(tester),
        before,
        reason: 'the reference is styled as a link but navigates nowhere',
      );
    });
  });

  group('lifecycle', () {
    testWidgets('the page unmounts without throwing', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      await expectCleanTeardown(tester, page);
    });
  });
}
