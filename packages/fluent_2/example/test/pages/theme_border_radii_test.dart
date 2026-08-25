import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/docs_metrics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Border Radii draws each token twice — a filled block and an outlined one —
/// so a reader can see the corner both as a silhouette and as a stroke. The
/// radius applied to those two boxes is the page's only claim, and a row that
/// prints `16px` beside a 12px corner is a defect no amount of mounting
/// catches. Every test below reads a swatch's own `BorderRadius`.
void main() {
  const String page = 'theme-border-radii';

  /// Upstream's names for our stops. React flattens everything past XLarge into
  /// `borderRadius2XLarge`..`6XLarge`; the same stops are spelled
  /// `FluentRadius.xxLarge`..`xxxxxxLarge` here.
  const List<(String, Radius)> ramp = <(String, Radius)>[
    ('borderRadiusNone', FluentRadius.none),
    ('borderRadiusSmall', FluentRadius.small),
    ('borderRadiusMedium', FluentRadius.medium),
    ('borderRadiusLarge', FluentRadius.large),
    ('borderRadiusXLarge', FluentRadius.xLarge),
    ('borderRadius2XLarge', FluentRadius.xxLarge),
    ('borderRadius3XLarge', FluentRadius.xxxLarge),
    ('borderRadius4XLarge', FluentRadius.xxxxLarge),
    ('borderRadius5XLarge', FluentRadius.xxxxxLarge),
    ('borderRadius6XLarge', FluentRadius.xxxxxxLarge),
    ('borderRadiusCircular', FluentRadius.circular),
  ];

  /// Upstream's filled swatch is a flat `#bbb`, which is not a stop on the
  /// Fluent grey ramp — chrome, not a token, and so a reliable key.
  const Color swatchFill = Color(0xFFBBBBBB);

  List<Element> boxes(bool Function(BoxDecoration) test) => find
      .byWidgetPredicate(
        (Widget widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            test(widget.decoration! as BoxDecoration),
      )
      .evaluate()
      .toList();

  List<Element> filled() => boxes((BoxDecoration d) => d.color == swatchFill);

  /// Keyed on the stroke colour, not merely on having a border: the card the
  /// whole ramp sits on is also a bordered white box, and counting it as a
  /// swatch would put twelve rows on an eleven-stop ramp.
  List<Element> outlined() => boxes(
    (BoxDecoration d) =>
        d.color == DocsMetrics.canvas &&
        d.border is Border &&
        (d.border! as Border).top.color == DocsMetrics.headingText,
  );

  group('the ramp', () {
    testWidgets('draws every stop twice and names it once', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      for (final (String name, Radius _) in ramp) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(filled(), hasLength(ramp.length));
      expect(outlined(), hasLength(ramp.length));
    });

    testWidgets('both swatches in a row carry that row\'s radius', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final List<Element> fills = filled();
      final List<Element> outlines = outlined();

      for (final (int i, (String name, Radius radius)) in ramp.indexed) {
        for (final (String kind, List<Element> row)
            in <(String, List<Element>)>[
              ('filled', fills),
              ('outlined', outlines),
            ]) {
          expect(
            ((row[i].widget as Container).decoration! as BoxDecoration)
                .borderRadius,
            BorderRadius.all(radius),
            reason: '$name\'s $kind swatch is rounded to another stop',
          );
        }
      }
    });

    testWidgets(
      'the outlined swatch is two pixels larger than the filled one',
      (WidgetTester tester) async {
        await pumpPageBody(tester, page);
        final List<Element> fills = filled();
        final List<Element> outlines = outlined();

        // Both box 42x42 of *content*. Flutter insets a border, so the outlined
        // one is declared 44 across for its 1px stroke to land outside the same
        // 42px area — which is what upstream's `border` does to a 42px div. A
        // swatch declared 42 with a border would be 40 of content and read a
        // fraction rounder than the filled block beside it.
        for (int i = 0; i < ramp.length; i++) {
          expect(
            tester.getRect(find.byWidget(fills[i].widget)).size,
            const Size(42, 42),
          );
          expect(
            tester.getRect(find.byWidget(outlines[i].widget)).size,
            const Size(44, 44),
          );
        }
      },
    );

    testWidgets('the value column prints upstream\'s label', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      expect(find.text('0'), findsOneWidget, reason: 'none is a bare 0');
      for (final (String _, Radius radius) in ramp.skip(1).take(9)) {
        expect(find.text('${radius.x.toStringAsFixed(0)}px'), findsOneWidget);
      }
      // `borderRadiusCircular` reads "10000px" because that is the literal
      // React ships; `FluentRadius.circular` is 9999, and both mean "as round
      // as the box allows", so the printed string follows upstream rather than
      // the Dart value. The swatch still has to carry the real radius.
      expect(find.text('10000px'), findsOneWidget);
      expect(find.text('9999px'), findsNothing);
      expect(
        ((filled().last.widget as Container).decoration! as BoxDecoration)
            .borderRadius,
        const BorderRadius.all(FluentRadius.circular),
      );
    });

    testWidgets('the corners grow down the page', (WidgetTester tester) async {
      await pumpPageBody(tester, page);
      final List<Element> fills = filled();

      double previous = -1;
      for (final (int i, (String name, Radius radius)) in ramp.indexed) {
        expect(
          tester.getRect(find.byWidget(fills[i].widget)).top,
          greaterThan(previous),
          reason: '$name is out of ramp order',
        );
        previous = tester.getRect(find.byWidget(fills[i].widget)).top;
        expect(radius.x, radius.y, reason: '$name must be a circular corner');
      }
    });
  });

  group('lifecycle', () {
    testWidgets('a real click on a swatch changes nothing', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final String before = textSnapshot(tester);

      // A specimen sheet, not a control surface: a pointer press must be inert
      // rather than throwing or revealing an affordance a tap never hovers for.
      await mouseClick(tester, find.text('borderRadiusCircular'));
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
