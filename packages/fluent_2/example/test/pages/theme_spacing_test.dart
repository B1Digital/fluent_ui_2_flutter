import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Spacing draws each token as a bar sized by its own value, split into a
/// Vertical group whose bars grow downward and a Horizontal group whose bars
/// grow rightward. The bar IS the claim, so every test below measures one: a
/// ramp rendered against the wrong axis, or a group that reuses the other's
/// numbers, is invisible in a screenshot and unmissable in a rect.
void main() {
  const String page = 'theme-spacing';

  const List<(String, double)> ramp = <(String, double)>[
    ('None', FluentSpacing.none),
    ('XXS', FluentSpacing.xxs),
    ('XS', FluentSpacing.xs),
    ('SNudge', FluentSpacing.sNudge),
    ('S', FluentSpacing.s),
    ('MNudge', FluentSpacing.mNudge),
    ('M', FluentSpacing.m),
    ('L', FluentSpacing.l),
    ('XL', FluentSpacing.xl),
    ('XXL', FluentSpacing.xxl),
    ('XXXL', FluentSpacing.xxxl),
  ];

  /// The bars of one axis, in ramp order, found by their own fill.
  ///
  /// The two colours are Storybook's swatches for this page rather than Fluent
  /// tokens — the page is measuring size, so the fill is arbitrary and only has
  /// to separate the axes. Which is exactly what makes it a usable key here.
  List<Element> bars(Color fill) => find
      .byWidgetPredicate(
        (Widget widget) => widget is Container && widget.color == fill,
      )
      .evaluate()
      .toList();

  const Color verticalBar = Color(0xFFCC006A);
  const Color horizontalBar = Color(0xFF00CC6A);

  group('the two ramps', () {
    testWidgets('both groups name every token on their own axis', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      expect(find.text('Vertical'), findsOneWidget);
      expect(find.text('Horizontal'), findsOneWidget);
      for (final (String suffix, double _) in ramp) {
        expect(find.text('spacingVertical$suffix'), findsOneWidget);
        expect(find.text('spacingHorizontal$suffix'), findsOneWidget);
      }
      expect(bars(verticalBar), hasLength(ramp.length));
      expect(bars(horizontalBar), hasLength(ramp.length));
    });

    testWidgets('every vertical bar is exactly its own token tall', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final List<Element> drawn = bars(verticalBar);

      for (final (int i, (String suffix, double value)) in ramp.indexed) {
        final Size bar = tester.getRect(find.byWidget(drawn[i].widget)).size;
        expect(
          bar.height,
          value,
          reason: 'spacingVertical$suffix draws a ${bar.height}px bar',
        );
        expect(
          bar.width,
          280,
          reason: 'a vertical bar measures height, so its width is constant',
        );
      }
    });

    testWidgets('every horizontal bar is exactly its own token wide', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final List<Element> drawn = bars(horizontalBar);

      for (final (int i, (String suffix, double value)) in ramp.indexed) {
        final Size bar = tester.getRect(find.byWidget(drawn[i].widget)).size;
        expect(
          bar.width,
          value,
          reason: 'spacingHorizontal$suffix draws a ${bar.width}px bar',
        );
        expect(
          bar.height,
          28,
          reason: 'a horizontal bar measures width, so its height is constant',
        );
      }
    });

    testWidgets('the None row is still a row on the horizontal axis', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      // `none` is 0, so its bar collapses to nothing visible. It is still built
      // rather than skipped, because on the horizontal axis the box is what
      // gives every row its 28px height — dropping it would shorten this row
      // alone and break the ramp's pitch.
      final Size bar = tester
          .getRect(find.byWidget(bars(horizontalBar).first.widget))
          .size;
      expect(bar.width, 0);
      expect(bar.height, 28);
    });

    testWidgets('the value column prints the token beside its bar', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      // Twice each: once for the vertical row, once for the horizontal one.
      // The zero is spelled `0` rather than `0px`, as upstream has it.
      expect(find.text('0'), findsNWidgets(2));
      for (final (String _, double value) in ramp.skip(1)) {
        expect(
          find.text('${value.toStringAsFixed(0)}px'),
          findsNWidgets(2),
          reason: '${value}px is missing from one of the two ramps',
        );
      }
    });

    testWidgets('the axes are drawn apart', (WidgetTester tester) async {
      await pumpPageBody(tester, page);

      // The whole reason the page carries both groups: `FluentSpacing.vertical`
      // and `.horizontal` resolve to identical numbers today, and the split is
      // what keeps that a fact rather than an assumption. Two groups sharing a
      // fill, or one group rendered twice, would read as correct.
      expect(bars(verticalBar).length, bars(horizontalBar).length);
      final double lastVertical = tester
          .getRect(find.byWidget(bars(verticalBar).last.widget))
          .bottom;
      final double firstHorizontal = tester
          .getRect(find.byWidget(bars(horizontalBar).first.widget))
          .top;
      expect(
        firstHorizontal,
        greaterThan(lastVertical),
        reason: 'the horizontal group is printed below the vertical one',
      );
    });
  });

  group('lifecycle', () {
    testWidgets('a real click on a bar changes nothing', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final String before = textSnapshot(tester);

      // A specimen sheet, not a control surface: a pointer press must be inert
      // rather than throwing or revealing an affordance a tap never hovers for.
      await mouseClick(tester, find.text('spacingVerticalXXXL'));
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
