import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// CarouselNav is one section with two things in it that have to move: a switch
/// that swaps every dot for a thumbnail, and five steps that own the selection
/// between them.
///
/// Both are easy to get almost right. A step's hit target is 24x24 whether or
/// not it is selected — Fluent keeps the target constant and grows the *mark*
/// inside it — so "the button changed size" is not available as a signal and
/// every assertion here reads the mark itself. And the selected step is the
/// only one carrying a `style` override, so a selection that moved the flag
/// without moving the tint would still look selected in the widget tree and
/// wrong on the screen.
void main() {
  const String page = 'components-carousel-carouselnav';
  final DocsSection section = sectionOf(
    'components-carousel-carouselnav--default',
  );

  /// The dot or pill [step] is drawing, or null when it is showing a thumbnail.
  ///
  /// A step is two decorated boxes deep: the button surface, rounded to
  /// `FluentRadius.allMedium`, and the mark inside it, rounded fully. The radius
  /// is what tells them apart without reaching into either private widget, and
  /// with a preview the mark is an image and there is no fully rounded box at
  /// all.
  ({Size size, Color? color})? markOf(WidgetTester tester, Finder step) {
    final Finder boxes = find.descendant(
      of: step,
      matching: find.byType(DecoratedBox),
    );
    for (int i = 0; i < boxes.evaluate().length; i++) {
      final BoxDecoration decoration =
          tester.widget<DecoratedBox>(boxes.at(i)).decoration as BoxDecoration;
      if (decoration.borderRadius == FluentRadius.allCircular) {
        return (size: tester.getSize(boxes.at(i)), color: decoration.color);
      }
    }
    return null;
  }

  /// The index of the step that currently holds focus, or null.
  ///
  /// Read by walking up from the focus node rather than by comparing focus
  /// nodes: the node belongs to the `FluentButton` a step composes, several
  /// elements below the step itself, and the semantic label is the only thing
  /// on the way up that says which one this is.
  int? focusedStep(WidgetTester tester) {
    final Element? focused = primaryFocus?.context as Element?;
    if (focused == null) return null;
    String? label;
    focused.visitAncestorElements((Element element) {
      if (element.widget is FluentCarouselStep) {
        label = (element.widget as FluentCarouselStep).semanticLabel;
        return false;
      }
      return true;
    });
    return label == null ? null : int.tryParse(label!.split(' ').last);
  }

  /// Which of the five steps is currently drawing the wide pill.
  ///
  /// Returned as a list rather than an index so a demo that lit two steps — or
  /// none — fails on the count instead of quietly reporting the first.
  List<int> selected(WidgetTester tester) => <int>[
    for (int i = 0; i < 5; i++)
      if (markOf(tester, find.byType(FluentCarouselStep).at(i))!.size.width > 8)
        i,
  ];

  /// The shadowed box upstream calls `container`: controls on top, card below.
  Finder container() => find
      .ancestor(
        of: find.byType(FluentSwitch),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).boxShadow != null,
        ),
      )
      .first;

  /// The colour the frame shows at [position], read off the rasterised layer
  /// tree. A shadow painted under a transparent box exists nowhere in the
  /// widget tree, only in the pixels, so this is the one honest reading of it.
  Future<Color> pixelAt(WidgetTester tester, Offset position) async {
    final OffsetLayer layer =
        tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    return (await tester.runAsync(() async {
      final ui.Image image = await layer.toImage(
        Rect.fromLTWH(
          position.dx.floorToDouble(),
          position.dy.floorToDouble(),
          1,
          1,
        ),
      );
      final ByteData bytes = (await image.toByteData())!;
      image.dispose();
      return Color.fromARGB(
        bytes.getUint8(3),
        bytes.getUint8(0),
        bytes.getUint8(1),
        bytes.getUint8(2),
      );
    }))!;
  }

  group('matches upstream as Chrome renders it', () {
    testWidgets('the card shows the page through it, and the shadow only '
        'outside it', (WidgetTester tester) async {
      await pumpSection(tester, section);

      // Upstream's container is `boxShadow: shadow16` with no background, and
      // CSS never paints an outer shadow inside the border box. A plain
      // BoxDecoration does — this card used to read #c1c1c1 all through, with
      // a lighter band along the top where the 8px key offset starts.
      final Rect box = tester.getRect(container());
      final Color page = await pixelAt(
        tester,
        Offset(box.right - 20, box.bottom + 60),
      );
      expect(
        await pixelAt(tester, Offset(box.right - 20, box.bottom - 20)),
        page,
        reason: 'the empty corner of the card must be the page behind it',
      );
      expect(
        await pixelAt(tester, Offset(box.right - 20, box.top + 5)),
        page,
        reason: 'the top band of the controls must be the page too',
      );
      expect(
        await pixelAt(tester, Offset(box.center.dx, box.bottom + 2)),
        isNot(page),
        reason: 'the shadow itself must still fall below the box',
      );
    });

    testWidgets('it is laid out like the upstream story', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Measured in Chrome: 3px borders that inset the content, so controls
      // are 3 + 10 + switch + 10 (59 around Chrome's 36px switch) and the card
      // 3 + 10 + 100 + 10 + 3 = 126. The switch is read rather than assumed:
      // `flutter test` has no Consolas, and its fallback sets the label taller.
      final double controls =
          3 + 10 + tester.getSize(find.byType(FluentSwitch)).height + 10;
      expect(tester.getSize(container()).height, controls + 126);

      // CarouselNav's `margin: auto 8px` soaks up the card's free space, so
      // the strip sits centred in the 100px body — not at the bottom, where
      // the card's own `justify-content: end` alone would put it.
      final Finder body = find.byWidgetPredicate(
        (Widget widget) =>
            widget is ConstrainedBox && widget.constraints.minHeight == 100,
      );
      final Finder steps = find.byType(FluentCarouselStep);
      expect(tester.getCenter(steps.first).dy, tester.getCenter(body).dy);

      // …on the translucent pill upstream draws behind the buttons.
      final Finder pill = find.ancestor(
        of: steps.first,
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  FluentTheme.of(
                    tester.element(steps.first),
                  ).colors.neutralBackgroundAlpha,
        ),
      );
      expect(pill, findsOneWidget);
      expect(
        (tester.widget<DecoratedBox>(pill).decoration as BoxDecoration)
            .borderRadius,
        FluentRadius.allXLarge,
      );
    });

    testWidgets('the label starts at the content edge, like a Field label', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Upstream's label is the Field's, flush with the controls' content box
      // (3px border + 10px padding in). The switch's own `before` label would
      // start 8px further in.
      expect(
        tester.getTopLeft(find.text('Use ')).dx -
            tester.getTopLeft(container()).dx,
        13,
      );
    });

    testWidgets('the brand pill is compoundBrandBackground, which parts from '
        'brandBackground in dark themes', (WidgetTester tester) async {
      final FluentThemeData dark = FluentThemeData.dark(
        fontPlatform: FluentFontPlatform.web,
      );
      await tester.pumpWidget(
        FluentApp(
          debugShowCheckedModeBanner: false,
          theme: dark,
          home: SingleChildScrollView(child: Builder(builder: section.builder)),
        ),
      );
      await settle(tester);

      // In light both tokens are brand[80], so only a dark theme can tell a
      // demo that tints with the wrong one.
      expect(
        dark.colors.compoundBrandBackground,
        isNot(dark.colors.brandBackground),
      );
      expect(
        markOf(tester, find.byType(FluentCarouselStep).first)!.color,
        dark.colors.compoundBrandBackground,
      );
    });

    testWidgets('the brand pill ramps under a resting pointer', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Upstream's `brand` appearance moves the selected pill to the compound
      // brand hover and pressed tokens.
      final Finder selected = find.byType(FluentCarouselStep).first;
      final FluentColors colors = FluentTheme.of(
        tester.element(selected),
      ).colors;
      final TestGesture mouse = await mouseHover(tester, selected);
      expect(
        markOf(tester, selected)!.color,
        colors.compoundBrandBackgroundHover,
      );
      await mouseAway(tester, mouse);
      expect(markOf(tester, selected)!.color, colors.compoundBrandBackground);
    });

    testWidgets('thumbnails sit 8px apart', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await tapAndSettle(
        tester,
        find.byType(FluentSwitch),
        what: 'the image button switch',
      );

      // CarouselNavImageButton carries `margin: 0 spacingHorizontalXS`.
      final Finder steps = find.byType(FluentCarouselStep);
      expect(
        tester.getTopLeft(steps.at(2)).dx - tester.getTopRight(steps.at(1)).dx,
        8,
      );
    });
  });

  group('image button switch', () {
    testWidgets('it swaps every dot for a thumbnail, and back again', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder steps = find.byType(FluentCarouselStep);
      expect(steps, findsNWidgets(5));
      expect(find.text('CarouselNavImageButton'), findsOneWidget);
      expect(markOf(tester, steps.at(1))!.size, const Size(8, 8));
      expect(find.byType(Image), findsNothing);

      final Finder toggle = find.byType(FluentSwitch);
      await tapAndSettle(tester, toggle, what: 'the image button switch');

      // The switch's own `checked` moving proves nothing: what it claims is
      // that every step swaps its dot for a 40 thumbnail — and the selected one
      // for a 48.
      expect(tester.widget<FluentSwitch>(toggle).checked, isTrue);
      expect(find.byType(Image), findsNWidgets(5));
      expect(markOf(tester, steps.at(1)), isNull);
      expect(tester.getSize(steps.at(1)), const Size(40, 40));
      expect(tester.getSize(steps.at(0)), const Size(48, 48));

      await tapAndSettle(tester, toggle, what: 'the image button switch');
      expect(tester.widget<FluentSwitch>(toggle).checked, isFalse);
      expect(find.byType(Image), findsNothing);
      expect(
        markOf(tester, steps.at(1))!.size,
        const Size(8, 8),
        reason: 'turning the switch back must restore the dot strip',
      );

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('it commits under a real mouse', (WidgetTester tester) async {
      await pumpSection(tester, section);

      // The two pixels of travel between press and release are the point: a
      // scrollable that claimed the mouse as a drag device would swallow the
      // click, and this page's only knob would be dead to every pointer user
      // while passing every synthetic tap.
      await mouseClick(tester, find.byType(FluentSwitch));
      expect(
        tester.widget<FluentSwitch>(find.byType(FluentSwitch)).checked,
        isTrue,
      );
      expect(find.byType(Image), findsNWidgets(5));
    });
  });

  group('steps', () {
    testWidgets('pressing a step moves the selection onto it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder steps = find.byType(FluentCarouselStep);
      expect(selected(tester), <int>[0]);

      await tapAndSettle(tester, steps.at(3), what: 'the fourth step');

      // Exclusive, and both halves of the swap: the pressed step grows into the
      // pill and the one that had it shrinks back. A demo that only ever added
      // to `_index` would light two.
      expect(selected(tester), <int>[3]);
      expect(markOf(tester, steps.at(3))!.size, const Size(16, 8));
      expect(markOf(tester, steps.at(0))!.size, const Size(8, 8));

      await tapAndSettle(tester, steps.at(0), what: 'the first step');
      expect(selected(tester), <int>[
        0,
      ], reason: 'the selection must be able to come back');

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the selected step takes the brand tint and the rest do not', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder steps = find.byType(FluentCarouselStep);
      final FluentColors colors = FluentTheme.of(
        tester.element(steps.first),
      ).colors;

      // The story's `appearance="brand"` reaches the mark through the
      // button's IconTheme — several hops — and a step that grew the pill
      // without taking the tint is the failure that leaves. Upstream's brand
      // pill is `colorCompoundBrandBackground`, which parts from
      // `brandBackground` in dark themes; every other dot rests at
      // Foreground1 under `opacity: 0.6` (useCarouselNavButtonStyles,
      // #7B7B7B in Chrome).
      final Color dot = colors.neutralForeground1.withValues(alpha: 0.6);
      expect(
        markOf(tester, steps.at(0))!.color,
        colors.compoundBrandBackground,
      );
      for (int i = 1; i < 5; i++) {
        expect(
          markOf(tester, steps.at(i))!.color,
          dot,
          reason: 'step $i is not the selected one and must stay neutral',
        );
      }

      await tapAndSettle(tester, steps.at(2), what: 'the third step');
      expect(
        markOf(tester, steps.at(2))!.color,
        colors.compoundBrandBackground,
      );
      expect(markOf(tester, steps.at(0))!.color, dot);
    });

    testWidgets('a real mouse press selects a step too', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.byType(FluentCarouselStep).at(4));
      expect(selected(tester), <int>[4]);
    });

    testWidgets('a resting pointer ramps the step it is over', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder steps = find.byType(FluentCarouselStep);
      final FluentColors colors = FluentTheme.of(
        tester.element(steps.first),
      ).colors;
      final Color dot = colors.neutralForeground1.withValues(alpha: 0.6);
      expect(markOf(tester, steps.at(2))!.color, dot);

      // The step tracks no state of its own — the mark reads whatever the
      // button's IconTheme resolved — so hover is the one axis that cannot be
      // reached with `tester.tap`, and an unreachable hover is a strip that
      // gives no feedback at all under a pointer. A brand nav's dot hovers at
      // the compound brand hover under `opacity: 0.75`
      // (useCarouselNavButtonStyles, `brand` `:hover`).
      final TestGesture mouse = await mouseHover(tester, steps.at(2));
      expect(
        markOf(tester, steps.at(2))!.color,
        colors.compoundBrandBackgroundHover.withValues(alpha: 0.75),
        reason: 'the mark must ramp while the pointer rests on it',
      );
      expect(
        markOf(tester, steps.at(3))!.color,
        dot,
        reason: 'only the step under the pointer may ramp',
      );

      await mouseAway(tester, mouse);
      expect(markOf(tester, steps.at(2))!.color, dot);
    });

    testWidgets('Tab walks the strip and Space activates a step', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The props table promises activation "on tap and on Space or Enter", and
      // the strip is the whole of this page's navigation — a pagination that
      // only answers a mouse is unusable without one. Tab order matters as much
      // as the key: the steps must come in reading order, not in whatever order
      // the Stack painted them.
      for (int i = 0; i < 10 && focusedStep(tester) != 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await settle(tester);
      }
      expect(focusedStep(tester), 3, reason: 'Tab must reach the fourth step');

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await settle(tester);
      expect(selected(tester), <int>[3]);
    });

    testWidgets('the selection survives the swap to image buttons', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder steps = find.byType(FluentCarouselStep);
      await tapAndSettle(tester, steps.at(2), what: 'the third step');
      await tapAndSettle(tester, find.byType(FluentSwitch), what: 'the switch');

      // The two knobs share one State. Rebuilding the strip with previews must
      // not reset `_index` — a pagination that jumped back to slide one every
      // time the indicator style changed would be a real defect, and the only
      // visible trace of it is which thumbnail is the big one.
      expect(tester.getSize(steps.at(2)), const Size(48, 48));
      expect(tester.getSize(steps.at(0)), const Size(40, 40));

      await tapAndSettle(tester, steps.at(4), what: 'the fifth thumbnail');
      expect(
        tester.getSize(steps.at(4)),
        const Size(48, 48),
        reason: 'a thumbnail must be pressable, not just decorative',
      );
      expect(tester.getSize(steps.at(2)), const Size(40, 40));
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection each in sectionsOf(page)) {
        await pumpSection(tester, each);
        await expectCleanTeardown(tester, each.id);
      }
    });
  });
}
