import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Shadows is a 12x3 grid of specimens where every cell is both the sample and
/// its own caption: a box carrying a real `BoxShadow` pair with the CSS that
/// pair resolves to printed inside it. That doubling is what makes the page
/// testable — a cell whose caption and shadow disagree is a lie no screenshot
/// would catch, and a column wired to the wrong theme prints Light's numbers
/// under Dark's heading.
void main() {
  const String page = 'theme-shadows';

  final List<(String, FluentThemeData)> columns = <(String, FluentThemeData)>[
    ('Light', FluentThemeData.light()),
    ('Dark', FluentThemeData.dark()),
    ('High Contrast', FluentThemeData.highContrast()),
  ];

  /// Upstream's notation, which is also the page's: a bare `0` for the zero
  /// offset, since a CSS length of zero carries no unit.
  String css(BoxShadow shadow) {
    final double dy = shadow.offset.dy;
    return '0 ${dy == 0 ? '0' : '${dy.toStringAsFixed(0)}px'} '
        '${shadow.blurRadius.toStringAsFixed(0)}px '
        'rgba(0,0,0,${shadow.color.a.toStringAsFixed(2)})';
  }

  /// Every specimen box, in tree order — the neutral levels, then the same six
  /// cast onto brand colour, three themes to a row.
  List<Element> swatches(WidgetTester tester) => find
      .byWidgetPredicate(
        (Widget widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).boxShadow != null,
      )
      .evaluate()
      .toList();

  group('the grid', () {
    testWidgets('names every level under every theme', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      expect(find.text('Shadow'), findsOneWidget);
      for (final (String label, FluentThemeData _) in columns) {
        expect(find.text(label), findsOneWidget, reason: 'column $label');
      }
      for (final FluentElevation level in FluentElevation.values) {
        expect(find.text(level.name), findsOneWidget, reason: level.name);
        expect(
          find.text('${level.name}Brand'),
          findsOneWidget,
          reason: '${level.name} on brand',
        );
      }
      expect(
        swatches(tester),
        hasLength(FluentElevation.values.length * 2 * columns.length),
      );
    });

    testWidgets('every specimen carries the shadow its row and column name', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final List<Element> boxes = swatches(tester);

      int at = 0;
      for (final bool onBrand in <bool>[false, true]) {
        for (final FluentElevation level in FluentElevation.values) {
          for (final (String label, FluentThemeData theme) in columns) {
            final BoxDecoration decoration =
                (boxes[at].widget as Container).decoration! as BoxDecoration;
            expect(
              decoration.boxShadow,
              onBrand ? theme.brandShadow(level) : theme.shadow(level),
              reason:
                  '${level.name}${onBrand ? 'Brand' : ''} under $label carries '
                  'another cell\'s elevation',
            );
            at++;
          }
        }
      }
    });

    testWidgets('every specimen prints the CSS of its own shadow', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      for (final Element box in swatches(tester)) {
        final Finder swatch = find.byWidget(box.widget);
        final List<BoxShadow> shadows =
            ((box.widget as Container).decoration! as BoxDecoration).boxShadow!;
        final List<String> printed = tester
            .widgetList<Text>(
              find.descendant(of: swatch, matching: find.byType(Text)),
            )
            .map((Text text) => text.data ?? '')
            .toList();
        expect(
          printed,
          shadows.map(css).toList(),
          reason: 'a specimen captioned itself with another shadow',
        );
      }
    });

    testWidgets('the dark columns are not the light one repeated', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final List<Element> boxes = swatches(tester);

      // The three columns resolve from three theme objects, and the only thing
      // separating them is opacity — 12%/14% against 24%/28%. A column left
      // bound to the ambient theme would render three identical cells and read
      // as a plausible page.
      final BoxDecoration light =
          (boxes[0].widget as Container).decoration! as BoxDecoration;
      final BoxDecoration dark =
          (boxes[1].widget as Container).decoration! as BoxDecoration;
      expect(dark.boxShadow, isNot(light.boxShadow));
      expect(
        dark.boxShadow!.first.color.a,
        greaterThan(light.boxShadow!.first.color.a),
        reason: 'a dark surface needs the heavier shadow',
      );
    });

    testWidgets('the brand specimens sit on brand colour', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final List<Element> boxes = swatches(tester);
      final int neutral = FluentElevation.values.length * columns.length;
      final FluentColors colors = FluentTheme.of(
        tester.element(find.text('Shadow')),
      ).colors;

      // Brand shadows carry heavier opacities precisely because they are cast
      // on brand colour, so a brand specimen on a neutral surface is showing a
      // shadow the page cannot justify.
      for (final (int i, Element box) in boxes.indexed) {
        final BoxDecoration decoration =
            (box.widget as Container).decoration! as BoxDecoration;
        expect(
          decoration.color,
          i < neutral ? colors.neutralBackground1 : FluentBrandRamp.teams[80],
          reason: 'specimen $i sits on the wrong surface',
        );
      }
      final Finder brandCaptions = find.descendant(
        of: find.byWidget(boxes[neutral].widget),
        matching: find.byType(Text),
      );
      expect(brandCaptions, findsWidgets);
      for (int i = 0; i < brandCaptions.evaluate().length; i++) {
        expect(
          textStyleOf(tester, brandCaptions.at(i))?.color,
          colors.neutralForegroundOnBrand,
          reason: 'a caption on brand colour needs the on-brand foreground',
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

      // A specimen sheet, not a control surface: a pointer press must be inert
      // rather than throwing or revealing an affordance a tap never hovers for.
      await mouseClick(tester, find.text('shadow8'));
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
