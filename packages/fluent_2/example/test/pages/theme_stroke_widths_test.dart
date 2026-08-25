import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/docs_metrics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Stroke Widths is the shortest page in the showroom: four names, four rules,
/// and the rule's thickness is the entire content. There is nothing to click,
/// so the only defect available is a rule that is not the width beside it — one
/// pixel out of four, which is exactly the kind of thing a reader trusts the
/// page for and cannot verify by eye.
void main() {
  const String page = 'theme-stroke-widths';

  /// The four widths React's web token set exposes, in ramp order.
  /// `FluentStroke` also carries `none`, `hairline`, `width15` and `width60`
  /// for the mobile surfaces; upstream's page does not print them, so neither
  /// does this one — and a page that started printing them would be showing
  /// tokens the web reader has no access to.
  const List<(String, double)> ramp = <(String, double)>[
    ('strokeWidthThin', FluentStroke.thin),
    ('strokeWidthThick', FluentStroke.thick),
    ('strokeWidthThicker', FluentStroke.thicker),
    ('strokeWidthThickest', FluentStroke.thickest),
  ];

  /// The rules, in ramp order. Keyed on the chrome black upstream draws them
  /// in, which no other box on the page uses.
  List<Element> rules() => find
      .byWidgetPredicate(
        (Widget widget) =>
            widget is Container && widget.color == DocsMetrics.headingText,
      )
      .evaluate()
      .toList();

  group('the ramp', () {
    testWidgets('prints exactly the four published widths', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      for (final (String name, double _) in ramp) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('strokeWidthNone'), findsNothing);
      expect(find.text('strokeWidthHairline'), findsNothing);
      expect(rules(), hasLength(ramp.length));
    });

    testWidgets('every rule is exactly its own token thick', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final List<Element> drawn = rules();

      for (final (int i, (String name, double width)) in ramp.indexed) {
        final Rect rule = tester.getRect(find.byWidget(drawn[i].widget));
        expect(
          rule.height,
          width,
          reason: '$name draws a ${rule.height}px rule',
        );
        expect(
          rule.width,
          greaterThan(100),
          reason: 'the rule fills the row, so its length is not the subject',
        );
      }
    });

    testWidgets('the rules share a left edge whatever the label reads', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final List<Element> drawn = rules();

      // The label column is a fixed 132px, measured off the reference: the rule
      // starts at the same x on every row. An intrinsic column would step the
      // rules in and out as the names change length, which is the one thing a
      // ramp of thicknesses must not do — a reader compares these by eye,
      // stacked.
      final double left = tester
          .getRect(find.byWidget(drawn.first.widget))
          .left;
      double previousTop = -1;
      for (final (int i, (String name, double _)) in ramp.indexed) {
        final Rect rule = tester.getRect(find.byWidget(drawn[i].widget));
        expect(rule.left, left, reason: '$name starts at a different x');
        expect(rule.top, greaterThan(previousTop), reason: '$name order');
        previousTop = rule.top;
      }
    });

    testWidgets('the ramp thickens as it descends', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final List<Element> drawn = rules();

      double previous = 0;
      for (final (int i, (String name, double _)) in ramp.indexed) {
        final double height = tester
            .getRect(find.byWidget(drawn[i].widget))
            .height;
        expect(
          height,
          greaterThan(previous),
          reason: '$name is no thicker than the rule above it',
        );
        previous = height;
      }
    });
  });

  group('lifecycle', () {
    testWidgets('a real click on a rule changes nothing', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final String before = textSnapshot(tester);

      // A specimen sheet, not a control surface: a pointer press must be inert
      // rather than throwing or revealing an affordance a tap never hovers for.
      await mouseClick(tester, find.text('strokeWidthThickest'));
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
