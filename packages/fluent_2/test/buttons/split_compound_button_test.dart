import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentSplitButton` and `FluentCompoundButton` are both recompositions of
/// `FluentButton` rather than new components: they share its appearance, size
/// and shape tables verbatim and add exactly one thing each — a divided
/// container, and a second line.
///
/// These tests therefore assert two things at once: that the shared half really
/// is shared (a change to the button's tokens must reach both), and that the
/// one new thing is right.
///
/// ## Where the numbers come from
///
/// The split button follows upstream as Chrome renders it: the chevron half's
/// size, inset and glyph, the divider's tokens, focus and the open-menu state
/// are pinned against `useSplitButtonStyles`, `useMenuButtonStyles` and live
/// probes of the storybook, each test naming its source.
///
/// `test/fixtures/secondary_action.json` is the Figma `.Secondary action` set
/// (`9026:1241`, 25 variants) — the chevron half as Figma draws it, with no
/// size axis. It still pins what Figma and upstream agree on: the chevron
/// half's square leading corners and missing leading stroke, so the rule
/// between the halves is drawn exactly once.
///
/// The **compound** type ramp comes from Figma's `Compound button`
/// (`9026:2278`), pinned here as literals naming the token Figma binds. Its
/// padding and its subtle and transparent first-line colour follow the
/// storybook instead, where the two disagree: the live React render is the
/// reference, and each of those tests names the computed style it read.
///
/// Everything else is `FluentButton`'s own table, already pinned variant by
/// variant against `test/fixtures/button.json` in `button_test.dart`; asserting
/// it a second time here would pin a copy rather than the shared code.
void main() {
  const splitKey = Key('split');
  const compoundKey = Key('compound');

  Future<void> pump(
    WidgetTester tester,
    Widget button, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: button),
    ),
  );

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  /// The rendered surface of one half, found by position.
  Finder sideOf(FluentSplitButtonSide side) => find
      .descendant(
        of: find.byKey(splitKey),
        matching: find.byType(ConstrainedBox),
      )
      .at(side.index);

  /// The edge painter of one half, or null if it has none.
  FluentSplitButtonEdgePainter? maybePainterOf(
    WidgetTester tester,
    FluentSplitButtonSide side,
  ) {
    final painters = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    for (final paint in painters) {
      final painter = paint.foregroundPainter;
      if (painter is FluentSplitButtonEdgePainter && painter.side == side) {
        return painter;
      }
    }
    return null;
  }

  FluentSplitButtonEdgePainter painterOf(
    WidgetTester tester,
    FluentSplitButtonSide side,
  ) {
    final painter = maybePainterOf(tester, side);
    if (painter == null) fail('no edge painter for ${side.name}');
    return painter;
  }

  /// The decorated surface under [of], skipping the focus ring's CustomPaint.
  BoxDecoration decorationOf(WidgetTester tester, Finder of) => tester
      .widgetList<DecoratedBox>(
        find.descendant(of: of, matching: find.byType(DecoratedBox)),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.borderRadius != null);

  Widget splitButton({
    FluentButtonAppearance appearance = FluentButtonAppearance.secondary,
    FluentButtonSize size = FluentButtonSize.medium,
    FluentButtonShape shape = FluentButtonShape.rounded,
    VoidCallback? onPressed,
    VoidCallback? onMenuPressed,
    FluentSplitButtonStyle? style,
    FocusNode? focusNode,
  }) => FluentSplitButton(
    key: splitKey,
    appearance: appearance,
    size: size,
    shape: shape,
    style: style,
    focusNode: focusNode,
    menuSemanticLabel: 'More options',
    onPressed: onPressed,
    onMenuPressed: onMenuPressed,
    child: const Text('Send'),
  );

  Widget compoundButton({
    FluentButtonAppearance appearance = FluentButtonAppearance.secondary,
    FluentButtonSize size = FluentButtonSize.medium,
    VoidCallback? onPressed,
    FluentCompoundButtonStyle? style,
    Widget? secondaryContent = const Text('Secondary'),
    String? semanticLabel,
  }) => FluentCompoundButton(
    key: compoundKey,
    appearance: appearance,
    size: size,
    style: style,
    secondaryContent: secondaryContent,
    semanticLabel: semanticLabel,
    onPressed: onPressed,
    child: const Text('Button'),
  );

  group('split button — every variant axis', () {
    testWidgets('both halves take the appearance fill the button does', (
      tester,
    ) async {
      final theme = light();
      final expected = <FluentButtonAppearance, Color>{
        FluentButtonAppearance.primary: theme.colors.brandBackground,
        FluentButtonAppearance.secondary: theme.colors.neutralBackground1,
        FluentButtonAppearance.outline: theme.colors.transparentBackground,
        FluentButtonAppearance.subtle: theme.colors.subtleBackground,
        FluentButtonAppearance.transparent: theme.colors.transparentBackground,
      };

      for (final entry in expected.entries) {
        await pump(
          tester,
          splitButton(
            appearance: entry.key,
            onPressed: () {},
            onMenuPressed: () {},
          ),
        );
        await tester.pumpAndSettle();

        for (final side in FluentSplitButtonSide.values) {
          expect(
            decorationOf(tester, sideOf(side)).color,
            entry.value,
            reason: '${entry.key.name} ${side.name}: fill',
          );
        }
      }
    });

    testWidgets('the divider selects a token per appearance', (tester) async {
      final theme = light();
      // `useSplitButtonStyles` sets the primary half's `borderRightColor`:
      // colorNeutralStrokeOnBrand on primary, a transparent colour on subtle
      // and transparent. Secondary and outline keep the button's own border.
      const clear = Color(0x00000000);
      final expected = <FluentButtonAppearance, Color>{
        FluentButtonAppearance.primary: theme.colors.neutralStrokeOnBrand,
        FluentButtonAppearance.secondary: theme.colors.neutralStroke1,
        FluentButtonAppearance.outline: theme.colors.neutralStroke1,
        FluentButtonAppearance.subtle: clear,
        FluentButtonAppearance.transparent: clear,
      };

      for (final entry in expected.entries) {
        await pump(
          tester,
          splitButton(
            appearance: entry.key,
            onPressed: () {},
            onMenuPressed: () {},
          ),
        );
        await tester.pumpAndSettle();
        expect(
          painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
          entry.value,
          reason: '${entry.key.name}: divider',
        );
      }
    });

    testWidgets('the primary divider holds one token through hover', (
      tester,
    ) async {
      // Upstream repeats colorNeutralStrokeOnBrand under `:hover` and
      // `:active`. Dark theme is where it shows: #292929 there, where the
      // on-brand /2/ steps are white.
      final theme = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
      expect(
        theme.colors.neutralStrokeOnBrand,
        isNot(theme.colors.neutralStrokeOnBrand2),
      );
      await pump(
        tester,
        splitButton(
          appearance: FluentButtonAppearance.primary,
          onPressed: () {},
          onMenuPressed: () {},
        ),
        theme: theme,
      );
      await tester.pumpAndSettle();
      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
        theme.colors.neutralStrokeOnBrand,
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer();
      await gesture.moveTo(
        tester.getCenter(sideOf(FluentSplitButtonSide.primaryAction)),
      );
      await tester.pumpAndSettle();
      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
        theme.colors.neutralStrokeOnBrand,
      );
    });

    testWidgets('a disabled split button keeps its seam, in the disabled '
        'stroke', (tester) async {
      // `useSplitButtonStyles.disabled` sets colorNeutralStrokeDisabled on
      // every appearance — so a disabled subtle split button shows a rule its
      // enabled self does not.
      for (final appearance in FluentButtonAppearance.values) {
        await pump(tester, splitButton(appearance: appearance));
        await tester.pumpAndSettle();
        expect(
          painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
          light().colors.neutralStrokeDisabled,
          reason: appearance.name,
        );
      }
    });

    testWidgets('only the primary half draws the divider', (tester) async {
      await pump(tester, splitButton(onPressed: () {}, onMenuPressed: () {}));
      await tester.pumpAndSettle();
      // Both halves carry a painter — the menu one is what draws its outer
      // border — but a rule drawn twice would be two pixels wide.
      expect(
        painterOf(tester, FluentSplitButtonSide.menu).side,
        isNot(FluentSplitButtonSide.primaryAction),
      );
      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).dividerWidth,
        FluentStroke.thin,
      );
    });

    testWidgets('every size keeps both halves on the button height ramp', (
      tester,
    ) async {
      const heights = <FluentButtonSize, double>{
        FluentButtonSize.small: 24,
        FluentButtonSize.medium: 32,
        FluentButtonSize.large: 40,
      };

      for (final entry in heights.entries) {
        await pump(
          tester,
          splitButton(size: entry.key, onPressed: () {}, onMenuPressed: () {}),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(splitKey)).height,
          entry.value,
          reason: '${entry.key.name}: height',
        );
        for (final side in FluentSplitButtonSide.values) {
          expect(
            tester.getSize(sideOf(side)).height,
            entry.value,
            reason: '${entry.key.name} ${side.name}: half height',
          );
        }
      }
    });

    testWidgets('the chevron half is as wide as upstream renders it', (
      tester,
    ) async {
      // A live probe of the Size story: 24, 24 and 31. The half is an
      // icon-only MenuButton whose floor `useSplitButtonStyles` lowers to 24
      // (WCAG 2.2's minimum for adjacent targets); only large, with 7px of
      // padding round a 16px chevron plus its 1px border, grows past it.
      const widths = <FluentButtonSize, double>{
        FluentButtonSize.small: 24,
        FluentButtonSize.medium: 24,
        FluentButtonSize.large: 31,
      };

      for (final entry in widths.entries) {
        await pump(
          tester,
          splitButton(size: entry.key, onPressed: () {}, onMenuPressed: () {}),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(sideOf(FluentSplitButtonSide.menu)).width,
          entry.value,
          reason: '${entry.key.name}: chevron width',
        );
      }
    });

    testWidgets('the chevron half takes the icon-only inset and the menu '
        'glyph', (tester) async {
      // `useRootIconOnlyStyles` pads by 1, 5 or 7; `useMenuIconStyles` sizes
      // the chevron 12, 12 or 16. There is no border on the seam side, so only
      // the other three add its pixel to the inset.
      const expected = <FluentButtonSize, (double, double)>{
        FluentButtonSize.small: (1, FluentSize.size120),
        FluentButtonSize.medium: (5, FluentSize.size120),
        FluentButtonSize.large: (7, FluentSize.size160),
      };

      for (final entry in expected.entries) {
        final (inset, glyph) = entry.value;
        final style = resolveFluentSplitButtonStyle(
          resolveFluentSplitButtonState(size: entry.key),
          light(),
          side: FluentSplitButtonSide.menu,
        ).button!;
        const rest = <WidgetState>{};
        expect(
          style.padding!.resolve(rest),
          EdgeInsetsDirectional.fromSTEB(
            inset,
            inset + 1,
            inset + 1,
            inset + 1,
          ),
          reason: '${entry.key.name}: chevron padding',
        );
        expect(
          style.menuIconSize!.resolve(rest),
          glyph,
          reason: '${entry.key.name}: chevron glyph',
        );
      }
    });

    testWidgets('the chevron half squares its leading corners and leaves the '
        'leading edge to the divider', (tester) async {
      final spec = loadSpec('secondary_action');
      for (final variant in spec.variants) {
        expect(
          variant.radius.topLeft,
          Radius.zero,
          reason: '${variant.name}: topLeft',
        );
        expect(
          variant.radius.bottomLeft,
          Radius.zero,
          reason: '${variant.name}: bottomLeft',
        );
        // The rule between the halves is the OTHER half's right border, so the
        // chevron half zeroes its own leading side. The one exception is
        // Outline/Selected, whose other three sides are 2px: the shared edge
        // still stays thin, so the rule never doubles in weight.
        expect(
          variant.strokeWidths.left,
          variant.strokeWidths.right == FluentStroke.thick
              ? FluentStroke.thin
              : FluentStroke.none,
          reason: '${variant.name}: leading stroke',
        );
      }
    });

    testWidgets('every shape rounds the outer corners and squares the inner', (
      tester,
    ) async {
      const expected = <FluentButtonShape, Radius>{
        FluentButtonShape.rounded: FluentRadius.medium,
        FluentButtonShape.circular: FluentRadius.circular,
        FluentButtonShape.square: FluentRadius.none,
      };

      for (final entry in expected.entries) {
        await pump(
          tester,
          splitButton(shape: entry.key, onPressed: () {}, onMenuPressed: () {}),
        );
        await tester.pumpAndSettle();

        final primary = decorationOf(
          tester,
          sideOf(FluentSplitButtonSide.primaryAction),
        ).borderRadius!.resolve(TextDirection.ltr);
        final menu = decorationOf(
          tester,
          sideOf(FluentSplitButtonSide.menu),
        ).borderRadius!.resolve(TextDirection.ltr);

        expect(primary.topLeft, entry.value, reason: entry.key.name);
        expect(primary.bottomLeft, entry.value, reason: entry.key.name);
        expect(primary.topRight, Radius.zero, reason: entry.key.name);
        expect(primary.bottomRight, Radius.zero, reason: entry.key.name);
        expect(menu.topRight, entry.value, reason: entry.key.name);
        expect(menu.bottomRight, entry.value, reason: entry.key.name);
        expect(menu.topLeft, Radius.zero, reason: entry.key.name);
        expect(menu.bottomLeft, Radius.zero, reason: entry.key.name);
      }
    });

    testWidgets('the border is painted, never decorated', (tester) async {
      // The border is painted together with the rule, whose colour a Border
      // under a radius cannot carry alongside it, so the halves must carry no
      // Border of their own — one would double up with the painter's.
      await pump(
        tester,
        splitButton(
          appearance: FluentButtonAppearance.outline,
          onPressed: () {},
          onMenuPressed: () {},
        ),
      );
      await tester.pumpAndSettle();
      for (final side in FluentSplitButtonSide.values) {
        expect(decorationOf(tester, sideOf(side)).border, isNull);
        expect(painterOf(tester, side).borderWidth, FluentStroke.thin);
        expect(
          painterOf(tester, side).borderColor,
          light().colors.neutralStroke1,
        );
      }
    });

    testWidgets('the divided container mirrors under RTL', (tester) async {
      // Upstream styles the pair with CSS logical properties, so under `rtl`
      // the primary action moves to the right and every piece of geometry that
      // marks the seam — the rounded corners, the open border edge, the rule —
      // moves with it. Getting only the row reversed leaves the two halves
      // rounded on the edges that face each other, which reads as two detached
      // buttons rather than one container.
      await pump(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: splitButton(
            appearance: FluentButtonAppearance.outline,
            onPressed: () {},
            onMenuPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final primary = sideOf(FluentSplitButtonSide.primaryAction);
      final menu = sideOf(FluentSplitButtonSide.menu);
      expect(
        tester.getTopLeft(primary).dx,
        greaterThan(tester.getTopLeft(menu).dx),
        reason: 'the primary action leads, so under RTL it sits on the right',
      );

      const radius = FluentRadius.medium;
      final primaryRadius = decorationOf(
        tester,
        primary,
      ).borderRadius!.resolve(TextDirection.rtl);
      final menuRadius = decorationOf(
        tester,
        menu,
      ).borderRadius!.resolve(TextDirection.rtl);
      expect(primaryRadius.topRight, radius);
      expect(primaryRadius.bottomRight, radius);
      expect(primaryRadius.topLeft, Radius.zero);
      expect(primaryRadius.bottomLeft, Radius.zero);
      expect(menuRadius.topLeft, radius);
      expect(menuRadius.bottomLeft, radius);
      expect(menuRadius.topRight, Radius.zero);
      expect(menuRadius.bottomRight, Radius.zero);

      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).roundsLeft,
        isFalse,
      );
      expect(painterOf(tester, FluentSplitButtonSide.menu).roundsLeft, isTrue);
    });

    testWidgets('a wrapped label takes the chevron half with it', (
      tester,
    ) async {
      // Upstream is a flexbox, so `align-items: stretch` keeps the chevron the
      // full height of the container however tall the label makes it. The
      // `With long text` story is the case that catches it: a two-line label
      // beside a chevron still at the size ramp's height is two buttons, not
      // one divided container.
      await pump(tester, splitButton(onPressed: () {}, onMenuPressed: () {}));
      await tester.pumpAndSettle();
      final oneLine = tester
          .getSize(sideOf(FluentSplitButtonSide.primaryAction))
          .height;

      await pump(
        tester,
        FluentSplitButton(
          key: splitKey,
          menuSemanticLabel: 'More options',
          onPressed: () {},
          onMenuPressed: () {},
          // The label carries the width, which is what makes it wrap: a Row
          // hands its children unbounded main-axis space, so a constraint on
          // the button itself would never reach the text.
          child: const SizedBox(
            width: 280,
            child: Text(
              'Long text wraps after it hits the max width of the component',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final primary = tester.getSize(
        sideOf(FluentSplitButtonSide.primaryAction),
      );
      final menu = tester.getSize(sideOf(FluentSplitButtonSide.menu));
      expect(primary.height, greaterThan(oneLine), reason: 'the label wrapped');
      expect(menu.height, primary.height);
      // Taller, not wider — the chevron half is pinned at 24 at every size.
      expect(menu.width, FluentSize.size240);
    });
  });

  group('split button — edge geometry', () {
    // Upstream's halves ARE buttons. `useSplitButtonStyles.styles.ts` zeroes
    // the two inner corners and the menu half's leading border, and its
    // `circular` rule is empty, so the outer corners keep the button's own
    // radius — 10000px when circular.
    //
    // The oracle is CSS's rule for such a box (CSS Backgrounds 3, "Overlapping
    // Curves"), worked out here rather than left to the engine: every corner
    // shrinks by ONE factor, the largest that lets each side hold its corners,
    // and the inner edge's radius is the outer one less the border beside it.
    // Circular therefore ends in a semicircle — or, on a half narrower than
    // half its height, in quarter circles as wide as the half — and never in
    // an ellipse. The top and bottom run on to the open edge unbroken.
    const scale = 4.0; // DPR 4, the density the Chrome comparison measured at
    const border = FluentStroke.thin;
    const color = Color(0xFFD1D1D1);
    // Two routes to one edge can antialias a few levels apart; a geometry
    // mistake misses by whole pixels, so by up to 255.
    const tolerance = 16;
    const primaryWidth = 96.0; // upstream's labelled floor, as Shape renders it
    // The port's radius, then upstream's CSS one.
    const shapes = <FluentButtonShape, (Radius, double)>{
      FluentButtonShape.rounded: (FluentRadius.medium, 4),
      FluentButtonShape.circular: (FluentRadius.circular, 10000),
      FluentButtonShape.square: (Radius.zero, 0),
    };
    // The three sizes, then the height a wrapped label stretches the pair to
    // in the `With long text` story — where the 24-wide chevron half is
    // narrower than half its height.
    const heights = <double>[24, 32, 40, 52];

    Future<ByteData> render(Size size, void Function(Canvas) paint) async {
      final recorder = ui.PictureRecorder();
      paint(Canvas(recorder)..scale(scale));
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (size.width * scale).round(),
        (size.height * scale).round(),
      );
      picture.dispose();
      final data = (await image.toByteData())!;
      image.dispose();
      return data;
    }

    /// Upstream's border box for a half of [size], [radius] CSS px on the
    /// closed side.
    void css(
      Canvas canvas,
      Size size,
      double radius, {
      required bool roundsLeft,
    }) {
      // One rounded corner on the top and bottom sides, two on the closed one.
      final used = radius == 0
          ? 0.0
          : radius *
                math.min(
                  1,
                  math.min(size.width / radius, size.height / (2 * radius)),
                );
      RRect box(Rect rect, double r) => RRect.fromRectAndCorners(
        rect,
        topLeft: Radius.circular(roundsLeft ? r : 0),
        bottomLeft: Radius.circular(roundsLeft ? r : 0),
        topRight: Radius.circular(roundsLeft ? 0 : r),
        bottomRight: Radius.circular(roundsLeft ? 0 : r),
      );
      canvas.drawDRRect(
        box(Offset.zero & size, used),
        box(
          Rect.fromLTRB(
            roundsLeft ? border : 0,
            border,
            roundsLeft ? size.width : size.width - border,
            size.height - border,
          ),
          math.max(0, used - border),
        ),
        Paint()..color = color,
      );
    }

    test('circular overflows every half below, so each exercises the rule', () {
      expect(FluentRadius.circular.x, greaterThan(primaryWidth));
      expect(FluentRadius.circular.y, greaterThan(heights.last));
    });

    for (final MapEntry(key: shape, value: (radius, cssRadius))
        in shapes.entries) {
      for (final height in heights) {
        for (final side in FluentSplitButtonSide.values) {
          for (final direction in TextDirection.values) {
            test('${shape.name} ${side.name} under ${direction.name}, '
                '${height.toInt()} high, is the box CSS draws', () async {
              final size = Size(
                side == FluentSplitButtonSide.primaryAction
                    ? primaryWidth
                    : FluentSize.size240,
                height,
              );
              final roundsLeft =
                  (side == FluentSplitButtonSide.primaryAction) ==
                  (direction == TextDirection.ltr);
              final ours = await render(
                size,
                (canvas) => FluentSplitButtonEdgePainter(
                  side: side,
                  borderColor: color,
                  borderWidth: border,
                  dividerColor: color,
                  // The rule's own shape is asserted below. The menu half
                  // keeps one, so the model — which has none — also checks
                  // that only the primary half ever draws it.
                  dividerWidth: side == FluentSplitButtonSide.primaryAction
                      ? 0
                      : FluentStroke.thin,
                  radius: roundsLeft
                      ? BorderRadius.horizontal(left: radius)
                      : BorderRadius.horizontal(right: radius),
                  roundsLeft: roundsLeft,
                ).paint(canvas, size),
              );
              final theirs = await render(
                size,
                (canvas) =>
                    css(canvas, size, cssRadius, roundsLeft: roundsLeft),
              );

              final columns = (size.width * scale).round();
              final mismatches = <String>[];
              for (var i = 0; i < ours.lengthInBytes; i += 4) {
                for (var channel = 0; channel < 4; channel++) {
                  final delta =
                      ours.getUint8(i + channel) - theirs.getUint8(i + channel);
                  if (delta.abs() > tolerance) {
                    final pixel = i ~/ 4;
                    mismatches.add('(${pixel % columns}, ${pixel ~/ columns})');
                    break;
                  }
                }
              }
              expect(
                mismatches,
                isEmpty,
                reason:
                    '${mismatches.length} device pixels are off by more than '
                    '$tolerance levels, first ${mismatches.take(8).join(' ')}',
              );
            });
          }
        }
      }
    }

    for (final direction in TextDirection.values) {
      const size = Size(primaryWidth, 32);
      final roundsLeft = direction == TextDirection.ltr;
      final columns = (size.width * scale).round();
      final rows = (size.height * scale).round();

      /// The primary half's pixels as ARGB, [inset] device columns in from the
      /// seam and [y] rows down.
      Future<int Function(int inset, int y)> seam({
        required double borderWidth,
        required Color rule,
      }) async {
        final pixels = await render(
          size,
          (canvas) => FluentSplitButtonEdgePainter(
            side: FluentSplitButtonSide.primaryAction,
            borderColor: color,
            borderWidth: borderWidth,
            dividerColor: rule,
            radius: BorderRadius.zero,
            roundsLeft: roundsLeft,
          ).paint(canvas, size),
        );
        return (int inset, int y) {
          final i = y * columns + (roundsLeft ? columns - 1 - inset : inset);
          return pixels.getUint8(i * 4 + 3) << 24 |
              pixels.getUint8(i * 4) << 16 |
              pixels.getUint8(i * 4 + 1) << 8 |
              pixels.getUint8(i * 4 + 2);
        };
      }

      test('the rule is mitred into the top and bottom under '
          '${direction.name}', () async {
        // Primary's case: no border of its own, and a rule. Upstream's rule is
        // the primary button's border-right beside a 1px transparent top and
        // bottom, so CSS cuts its ends at 45° inside that pixel and the fill
        // shows above the cut; a rule drawn square notches the outline.
        final pixel = await seam(borderWidth: FluentStroke.none, rule: color);
        int alpha(int inset, int y) => pixel(inset, y) >>> 24;

        expect(alpha(3, 0), 0, reason: 'above the cut, at the top');
        expect(alpha(3, rows - 1), 0, reason: 'below the cut, at the bottom');
        expect(alpha(0, 3), 255, reason: 'inside the cut, on the seam');
        expect(alpha(0, rows - 4), 255, reason: 'inside the cut, on the seam');
        expect(alpha(3, rows ~/ 2), 255, reason: 'full width between the cuts');
        expect(alpha(4, rows ~/ 2), 0, reason: 'one CSS pixel wide');
        for (var i = 0; i < 4; i++) {
          expect(alpha(i, i), closeTo(128, 16), reason: 'on the cut, top');
          expect(
            alpha(i, rows - 1 - i),
            closeTo(128, 16),
            reason: 'on the cut, bottom',
          );
        }
      });

      test('a drawn top and bottom own the corner above the cut under '
          '${direction.name}', () async {
        // Default and outline: the rule meets a painted border, and CSS splits
        // that corner along the same diagonal — the top's colour above it, the
        // rule's below. A rule in a colour of its own shows where each ends.
        const rule = Color(0xFF0000FF);
        final pixel = await seam(borderWidth: border, rule: rule);

        expect(pixel(2, 1), color.toARGB32(), reason: 'the top, above the cut');
        expect(pixel(1, 2), rule.toARGB32(), reason: 'the rule, below it');
        expect(pixel(2, rows - 2), color.toARGB32(), reason: 'the bottom');
        expect(pixel(1, rows - 3), rule.toARGB32(), reason: 'the rule');
      });
    }
  });

  // Live probes of the SplitButton stories: keyboard focus, an open menu, the
  // chevron's box, the icon-only half.
  group('split button — upstream states', () {
    Future<void> keyboardFocus(WidgetTester tester, FocusNode node) async {
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    }

    /// The ring round the half [of] finds — the nearest ring above its surface.
    FluentFocusRingPainter ringOf(WidgetTester tester, Finder of) => tester
        .widgetList<CustomPaint>(
          find.ancestor(of: of, matching: find.byType(CustomPaint)),
        )
        .map((p) => p.foregroundPainter)
        .whereType<FluentFocusRingPainter>()
        .first;

    Widget withMenu(Widget Function(VoidCallback toggle) trigger) => FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item'), onPressed: () {}),
      ],
      builder: (context, toggle) => trigger(toggle),
    );

    for (final direction in TextDirection.values) {
      testWidgets('the chevron half\'s ring is one pixel on the seam under '
          '${direction.name}', (tester) async {
        // `borderLeftWidth: 0` survives focus, so on the seam only the 1px
        // inset shadow is black — probed: grey rule, then 4 device px of black.
        final node = FocusNode();
        addTearDown(node.dispose);
        await pump(
          tester,
          Directionality(
            textDirection: direction,
            child: FluentSplitButton(
              key: splitKey,
              menuSemanticLabel: 'More options',
              menuFocusNode: node,
              onPressed: () {},
              onMenuPressed: () {},
              child: const Text('Send'),
            ),
          ),
        );
        await keyboardFocus(tester, node);

        final ring = ringOf(tester, sideOf(FluentSplitButtonSide.menu));
        expect(ring.visible, isTrue);
        expect(
          ring.insets,
          direction == TextDirection.ltr
              ? const EdgeInsets.fromLTRB(1, 2, 2, 2)
              : const EdgeInsets.fromLTRB(2, 2, 1, 2),
        );
      });
    }

    testWidgets('a focused primary half turns its rule the focus stroke', (
      tester,
    ) async {
      // The focus indicator's `borderColor` reaches all four sides, the rule
      // included — on primary as much as on secondary.
      for (final appearance in <FluentButtonAppearance>[
        FluentButtonAppearance.secondary,
        FluentButtonAppearance.primary,
      ]) {
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(const SizedBox());
        await pump(
          tester,
          splitButton(
            appearance: appearance,
            focusNode: node,
            onPressed: () {},
            onMenuPressed: () {},
          ),
        );
        await keyboardFocus(tester, node);
        expect(
          painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
          light().colors.strokeFocus2,
          reason: appearance.name,
        );
      }
    });

    testWidgets('an open menu takes the chevron half\'s Selected tokens', (
      tester,
    ) async {
      // `useRootExpandedStyles.secondary`: colorNeutralBackground1Selected
      // under colorNeutralStroke1Selected, announced as `aria-expanded`.
      final theme = light();
      await pump(
        tester,
        withMenu(
          (toggle) => FluentSplitButton(
            key: splitKey,
            menuSemanticLabel: 'More options',
            onPressed: () {},
            onMenuPressed: toggle,
            child: const Text('Send'),
          ),
        ),
      );
      final menu = sideOf(FluentSplitButtonSide.menu);
      expect(decorationOf(tester, menu).color, theme.colors.neutralBackground1);

      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(
        decorationOf(tester, menu).color,
        theme.colors.neutralBackground1Selected,
      );
      expect(
        painterOf(tester, FluentSplitButtonSide.menu).borderColor,
        theme.colors.neutralStroke1Selected,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('More options')),
        isSemantics(hasExpandedState: true, isExpanded: true),
      );
    });

    testWidgets('an open outline menu thickens the chevron half to 3px', (
      tester,
    ) async {
      // `useRootExpandedStyles.outline`: `strokeWidthThicker`, and the half
      // grows by the difference — probed 24 to 25.
      await pump(
        tester,
        FluentSplitButton(
          key: splitKey,
          appearance: FluentButtonAppearance.outline,
          menuSemanticLabel: 'More options',
          menuExpanded: true,
          onPressed: () {},
          onMenuPressed: () {},
          child: const Text('Send'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        painterOf(tester, FluentSplitButtonSide.menu).borderWidth,
        FluentStroke.thicker,
      );
      expect(tester.getSize(sideOf(FluentSplitButtonSide.menu)).width, 25);
    });

    testWidgets('an icon-only primary half is a square', (tester) async {
      // With no children upstream's primary half is `iconOnly`: 32 at medium.
      await pump(
        tester,
        FluentSplitButton(
          key: splitKey,
          menuSemanticLabel: 'More options',
          semanticLabel: 'Calendar',
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          onPressed: () {},
          onMenuPressed: () {},
        ),
      );
      expect(
        tester.getSize(sideOf(FluentSplitButtonSide.primaryAction)),
        const Size.square(32),
      );
    });

    testWidgets('the chevron is painted a pixel below centre', (tester) async {
      // The svg in upstream's `menuIcon` span sits on a 16px line's baseline,
      // 1px below the span, at every size.
      await pump(tester, splitButton(onPressed: () {}, onMenuPressed: () {}));
      final shift = tester.widget<Transform>(
        find.descendant(
          of: sideOf(FluentSplitButtonSide.menu),
          matching: find.byType(Transform),
        ),
      );
      expect(shift.transform.getTranslation().y, 1);
      expect(shift.transform.getTranslation().x, 0);
    });

    testWidgets('a hovered subtle chevron keeps the label colour', (
      tester,
    ) async {
      // splitbutton--appearance, Subtle, hovered in Chrome: the chevron is the
      // menu button's `menuIcon`, rgb(36,36,36) like the label, not the brand
      // `.fui-Button__icon` rule subtle applies to a real icon.
      final theme = light();
      await pump(
        tester,
        splitButton(
          appearance: FluentButtonAppearance.subtle,
          onPressed: () {},
          onMenuPressed: () {},
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      final centre = tester.getCenter(sideOf(FluentSplitButtonSide.menu));
      await mouse.moveTo(centre);
      await tester.pump();
      await mouse.moveTo(centre + const Offset(1, 0));
      await tester.pumpAndSettle();

      final glyph = tester.widget<RichText>(
        find.descendant(
          of: find.byIcon(FluentIcons.chevron_down_20_regular),
          matching: find.byType(RichText),
        ),
      );
      expect(glyph.text.style?.color, theme.colors.neutralForeground1Hover);
    });

    testWidgets('the seam lands on a whole device pixel', (tester) async {
      // Chrome snaps box edges to device pixels; a label of fractional width
      // must not leave the rule straddling two.
      await pump(
        tester,
        FluentSplitButton(
          key: splitKey,
          menuSemanticLabel: 'More options',
          onPressed: () {},
          onMenuPressed: () {},
          child: const SizedBox(width: 100.3, height: 10),
        ),
      );
      final ratio = tester.view.devicePixelRatio;
      final seam =
          tester.getSize(sideOf(FluentSplitButtonSide.primaryAction)).width *
          ratio;
      expect(seam, closeTo(seam.roundToDouble(), 1e-6));
    });
  });

  group('split button — the two halves are separate controls', () {
    testWidgets('each callback fires from its own half only', (tester) async {
      var actions = 0;
      var menus = 0;
      await pump(
        tester,
        splitButton(onPressed: () => actions++, onMenuPressed: () => menus++),
      );

      await tester.tap(sideOf(FluentSplitButtonSide.primaryAction));
      await tester.pump();
      expect(actions, 1);
      expect(menus, 0);

      await tester.tap(sideOf(FluentSplitButtonSide.menu));
      await tester.pump();
      expect(actions, 1);
      expect(menus, 1);
    });

    testWidgets('hovering one half leaves the other at rest', (tester) async {
      await pump(tester, splitButton(onPressed: () {}, onMenuPressed: () {}));
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(sideOf(FluentSplitButtonSide.menu)));
      await tester.pumpAndSettle();

      final theme = light();
      expect(
        decorationOf(tester, sideOf(FluentSplitButtonSide.menu)).color,
        theme.colors.neutralBackground1Hover,
      );
      expect(
        decorationOf(tester, sideOf(FluentSplitButtonSide.primaryAction)).color,
        theme.colors.neutralBackground1,
        reason: 'the primary half must not react to the chevron being hovered',
      );
    });

    testWidgets('disabled is a real state, per half', (tester) async {
      var menus = 0;
      await pump(tester, splitButton(onMenuPressed: () => menus++));
      await tester.pumpAndSettle();
      final theme = light();

      expect(
        decorationOf(tester, sideOf(FluentSplitButtonSide.primaryAction)).color,
        theme.colors.neutralBackgroundDisabled,
      );
      expect(
        decorationOf(tester, sideOf(FluentSplitButtonSide.menu)).color,
        theme.colors.neutralBackground1,
        reason: 'disabling the action must not disable the menu',
      );
      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
        theme.colors.neutralStrokeDisabled,
      );

      // A disabled half must not merely look disabled: no callback, and no
      // hover state adopted afterwards.
      await tester.tap(
        sideOf(FluentSplitButtonSide.primaryAction),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(
        decorationOf(tester, sideOf(FluentSplitButtonSide.primaryAction)).color,
        theme.colors.neutralBackgroundDisabled,
      );

      await tester.tap(sideOf(FluentSplitButtonSide.menu));
      await tester.pump();
      expect(menus, 1);
    });

    testWidgets('each half is a named, keyboard-reachable button', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var actions = 0;
      await pump(
        tester,
        splitButton(
          focusNode: node,
          onPressed: () => actions++,
          onMenuPressed: () {},
        ),
      );

      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(actions, 1, reason: 'keyboard activation must work');

      expect(
        tester.getSemantics(find.bySemanticsLabel('More options')),
        matchesSemantics(
          label: 'More options',
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasEnabledState: true,
          hasTapAction: true,
          hasFocusAction: true,
          // Collapsed, and saying so: upstream's menu button always carries
          // `aria-expanded`, false until its menu opens.
          hasExpandedState: true,
        ),
        reason: 'the chevron must announce as a named button, not an image',
      );
    });

    testWidgets('a disabled half announces itself as disabled', (tester) async {
      await pump(tester, splitButton(onPressed: () {}));
      expect(
        tester.getSemantics(find.bySemanticsLabel('More options')),
        matchesSemantics(
          label: 'More options',
          isButton: true,
          hasEnabledState: true,
          // No isEnabled and no isFocusable: a disabled half refuses focus and
          // announces as dimmed. The tap action survives because
          // `FluentInteractive` keeps one attached and drops the callback —
          // see `surprises` in the report.
          hasTapAction: false,
          hasExpandedState: true,
        ),
      );
    });
  });

  group('compound button — every variant axis', () {
    testWidgets('the surface takes the appearance fill the button does', (
      tester,
    ) async {
      final theme = light();
      final expected = <FluentButtonAppearance, Color>{
        FluentButtonAppearance.primary: theme.colors.brandBackground,
        FluentButtonAppearance.secondary: theme.colors.neutralBackground1,
        FluentButtonAppearance.outline: theme.colors.transparentBackground,
        FluentButtonAppearance.subtle: theme.colors.subtleBackground,
        FluentButtonAppearance.transparent: theme.colors.transparentBackground,
      };

      for (final entry in expected.entries) {
        await pump(
          tester,
          compoundButton(appearance: entry.key, onPressed: () {}),
        );
        await tester.pumpAndSettle();
        expect(
          decorationOf(tester, find.byKey(compoundKey)).color,
          entry.value,
          reason: '${entry.key.name}: fill',
        );
      }
    });

    testWidgets('the second line selects a token per appearance', (
      tester,
    ) async {
      final theme = light();
      final expected = <FluentButtonAppearance, Color>{
        FluentButtonAppearance.primary: theme.colors.neutralForegroundOnBrand,
        FluentButtonAppearance.secondary: theme.colors.neutralForeground2,
        FluentButtonAppearance.outline: theme.colors.neutralForeground2,
        FluentButtonAppearance.subtle: theme.colors.neutralForeground2,
        FluentButtonAppearance.transparent: theme.colors.neutralForeground2,
      };

      for (final entry in expected.entries) {
        await pump(
          tester,
          compoundButton(appearance: entry.key, onPressed: () {}),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<RichText>(find.byType(RichText).last).text.style?.color,
          entry.value,
          reason: '${entry.key.name}: secondary colour',
        );
      }
    });

    testWidgets('subtle and transparent rest their first line on the button '
        'label colour and darken it on hover', (tester) async {
      // Figma's Compound 9026:2278 binds `Primary text` to
      // Neutral/Foreground/1/Rest on Subtle and Transparent. The storybook
      // renders both at rgb(66,66,66) — neutralForeground2, the plain button's
      // label — and on hover subtle goes to rgb(36,36,36) and transparent to
      // brand rgb(15,108,189): getComputedStyle on
      // components-button-compoundbutton--appearance. React wins.
      final theme = light();
      final hovered = <FluentButtonAppearance, Color>{
        FluentButtonAppearance.subtle: theme.colors.neutralForeground1Hover,
        FluentButtonAppearance.transparent:
            theme.colors.neutralForeground2BrandHover,
      };
      for (final entry in hovered.entries) {
        await pump(
          tester,
          compoundButton(appearance: entry.key, onPressed: () {}),
        );
        await tester.pumpAndSettle();
        Color? first() => tester
            .widgetList<RichText>(find.byType(RichText))
            .first
            .text
            .style
            ?.color;
        expect(
          first(),
          theme.colors.neutralForeground2,
          reason: '${entry.key.name}: first line at rest',
        );

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await tester.pump();
        await mouse.moveTo(tester.getCenter(find.byKey(compoundKey)));
        await tester.pumpAndSettle();
        expect(
          first(),
          entry.value,
          reason: '${entry.key.name}: first line on hover',
        );
        await mouse.removePointer();
      }
    });

    testWidgets('selected resolves to the Selected step, not Pressed', (
      tester,
    ) async {
      // The button set reuses Neutral/Foreground/1/Pressed for Selected; the
      // compound set binds the real Neutral/Foreground/{1,2}/Selected. Resolved
      // directly because FluentInteractive never raises WidgetState.selected on
      // its own.
      final theme = light();
      final style = resolveFluentCompoundButtonStyle(
        resolveFluentCompoundButtonState(),
        theme,
      );
      const selected = <WidgetState>{WidgetState.selected};
      expect(
        style.button!.foregroundColor!.resolve(selected),
        theme.colors.neutralForeground1Selected,
      );
      expect(
        style.secondaryColor!.resolve(selected),
        theme.colors.neutralForeground2Selected,
      );
    });

    testWidgets('the type ramp moves with the size, as the storybook draws '
        'it', (tester) async {
      // Compound button 9026:2278 holds 14/20 Semibold over 12/16 Regular in
      // all 75 variants. The storybook steps it with the size — getComputedStyle
      // on compoundbutton--size: 14/20 w400 over 12/12 at small, 14/20 w600
      // over 12/12 at medium, 16/22 w600 over 14/14 at large, the second line
      // `lineHeight: 100%` — and React wins.
      const expected = <FluentButtonSize, (double, double, FontWeight, double)>{
        FluentButtonSize.small: (14, 20, FontWeight.w400, 12),
        FluentButtonSize.medium: (14, 20, FontWeight.w600, 12),
        FluentButtonSize.large: (16, 22, FontWeight.w600, 14),
      };
      for (final MapEntry(key: size, value: type) in expected.entries) {
        final (fontSize, lineHeight, weight, secondarySize) = type;
        await pump(tester, compoundButton(size: size, onPressed: () {}));
        await tester.pumpAndSettle();
        final texts = tester
            .widgetList<RichText>(find.byType(RichText))
            .toList();
        final first = texts.first.text.style!;
        expect(first.fontSize, fontSize, reason: '${size.name}: primary size');
        expect(
          first.height! * fontSize,
          closeTo(lineHeight, 1e-9),
          reason: '${size.name}: primary lineHeight',
        );
        expect(first.fontWeight, weight, reason: '${size.name}: weight');
        final second = texts.last.text.style!;
        expect(
          second.fontSize,
          secondarySize,
          reason: '${size.name}: secondary size',
        );
        expect(
          second.height,
          1,
          reason: '${size.name}: secondary lineHeight is 100%',
        );
      }
    });

    testWidgets('every size uses the compound padding, not the button ramp', (
      tester,
    ) async {
      // Compound button 9026:2278 insets uniformly — Spacing S, M and L on all
      // four sides. The storybook pads `8px 8px 10px`, `14px 12px 16px` and
      // `18px 16px 20px` inside a 1px border (getComputedStyle on
      // components-button-compoundbutton--size), and React wins; the border
      // takes layout space, as on FluentButton, so each inset is one more. The
      // icon sits `spacingHorizontalM` from the text at every size, where
      // Figma reuses the inset.
      const expected = <FluentButtonSize, EdgeInsets>{
        FluentButtonSize.small: EdgeInsets.fromLTRB(9, 9, 9, 11),
        FluentButtonSize.medium: EdgeInsets.fromLTRB(13, 15, 13, 17),
        FluentButtonSize.large: EdgeInsets.fromLTRB(17, 19, 17, 21),
      };

      for (final entry in expected.entries) {
        await pump(tester, compoundButton(size: entry.key, onPressed: () {}));
        await tester.pumpAndSettle();
        final padding = tester
            .widgetList<Padding>(
              find.descendant(
                of: find.byKey(compoundKey),
                matching: find.byType(Padding),
              ),
            )
            .first
            .padding
            .resolve(TextDirection.ltr);
        expect(padding, entry.value, reason: '${entry.key.name}: padding');
        expect(
          resolveFluentCompoundButtonStyle(
            resolveFluentCompoundButtonState(size: entry.key),
            light(),
          ).button!.gap!.resolve(const <WidgetState>{}),
          FluentSpacing.m,
          reason: '${entry.key.name}: the icon gap',
        );
      }
    });

    testWidgets('the height is content-driven, not the button ramp', (
      tester,
    ) async {
      // `height: auto` on the compound root: border, padding and content,
      // never the button's 24/32/40. Two lines are 20 + 12 (22 + 14 at large);
      // the 40px icon is taller, which is where the storybook's 60/72/80 come
      // from. Chrome renders the three 52, 64 and 76 high without it.
      const lines = <FluentButtonSize, double>{
        FluentButtonSize.small: 1 + 8 + 20 + 12 + 10 + 1,
        FluentButtonSize.medium: 1 + 14 + 20 + 12 + 16 + 1,
        FluentButtonSize.large: 1 + 18 + 22 + 14 + 20 + 1,
      };
      const withIcon = <FluentButtonSize, double>{
        FluentButtonSize.small: 60,
        FluentButtonSize.medium: 72,
        FluentButtonSize.large: 80,
      };

      for (final size in FluentButtonSize.values) {
        await pump(tester, compoundButton(size: size, onPressed: () {}));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(compoundKey)).height,
          lines[size],
          reason: '${size.name}: height',
        );

        await pump(
          tester,
          FluentCompoundButton(
            key: compoundKey,
            size: size,
            icon: const Icon(FluentIcons.calendar_month_20_regular),
            secondaryContent: const Text('Secondary'),
            onPressed: () {},
            child: const Text('Button'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(compoundKey)).height,
          withIcon[size],
          reason: '${size.name}: height with the 40px icon',
        );
      }
    });

    testWidgets('both axes are content-driven', (tester) async {
      // `height: auto` upstream, because two lines make the button's own height
      // ramp meaningless. The width is content-driven for a separate reason,
      // recorded on `FluentButton.minimumSize`: React's 64/96 floor — which a
      // live probe of `components-button-compoundbutton--size` does confirm —
      // is inseparable from its wider TeachingPopover surface, and adopting one
      // without the other overflows Figma's 288 footer.
      for (final size in FluentButtonSize.values) {
        final minimum = resolveFluentCompoundButtonStyle(
          resolveFluentCompoundButtonState(size: size),
          light(),
        ).button!.minimumSize!.resolve(const <WidgetState>{})!;
        expect(
          minimum.width,
          0,
          reason: '${size.name}: width is content-driven',
        );
        expect(minimum.height, 0, reason: '${size.name}: height is auto');
      }
    });

    testWidgets('omitting the second line renders a plain button', (
      tester,
    ) async {
      await pump(
        tester,
        compoundButton(secondaryContent: null, onPressed: () {}),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('disabled is a real state', (tester) async {
      await pump(tester, compoundButton());
      await tester.pumpAndSettle();
      final theme = light();

      expect(
        decorationOf(tester, find.byKey(compoundKey)).color,
        theme.colors.neutralBackgroundDisabled,
      );
      expect(
        tester.widget<RichText>(find.byType(RichText).last).text.style?.color,
        theme.colors.neutralForegroundDisabled,
        reason: 'the second line must disable too, not just the first',
      );

      await tester.tap(find.byKey(compoundKey), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        decorationOf(tester, find.byKey(compoundKey)).color,
        theme.colors.neutralBackgroundDisabled,
        reason: 'a disabled button must not adopt the hover fill',
      );
    });

    testWidgets('it announces as one button carrying both lines', (
      tester,
    ) async {
      await pump(tester, compoundButton(onPressed: () {}));
      expect(
        tester.getSemantics(find.byKey(compoundKey)),
        matchesSemantics(
          // Both lines, one node: the second line exists to be read, so it is
          // merged into the button rather than announced as a sibling.
          label: 'Button\nSecondary',
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasEnabledState: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    });
  });

  group('motion', () {
    testWidgets('the divider tweens with the surface at 100ms easyEase', (
      tester,
    ) async {
      // Upstream declares no transition of its own on either component: both
      // inherit Button's root `transition: background, border, color` at
      // durationFaster / curveEasyEase, and the divider IS that border —
      // upstream paints it as the primary half's `borderRightColor`.
      await pump(tester, splitButton(onPressed: () {}, onMenuPressed: () {}));
      await tester.pumpAndSettle();
      final rest = painterOf(
        tester,
        FluentSplitButtonSide.primaryAction,
      ).dividerColor;

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(
        tester.getCenter(sideOf(FluentSplitButtonSide.primaryAction)),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
        isNot(rest),
        reason: 'must be mid-tween, not instant',
      );

      await tester.pumpAndSettle();
      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
        light().colors.neutralStroke1Hover,
      );
    });

    testWidgets('the compound surface tweens at 100ms easyEase', (
      tester,
    ) async {
      await pump(tester, compoundButton(onPressed: () {}));
      await tester.pumpAndSettle();
      final rest = decorationOf(tester, find.byKey(compoundKey)).color;

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(compoundKey)));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        decorationOf(tester, find.byKey(compoundKey)).color,
        isNot(rest),
        reason: 'must be mid-tween, not instant',
      );

      await tester.pumpAndSettle();
      expect(
        decorationOf(tester, find.byKey(compoundKey)).color,
        light().colors.neutralBackground1Hover,
      );
    });

    testWidgets('reduced motion lands the divider immediately', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
          home: Center(
            child: splitButton(onPressed: () {}, onMenuPressed: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(
        tester.getCenter(sideOf(FluentSplitButtonSide.primaryAction)),
      );
      await tester.pump();
      await tester.pump();

      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
        light().colors.neutralStroke1Hover,
      );
    });
  });

  group('style resolution order', () {
    testWidgets('the split widget style beats the subtree theme', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      const explicit = Color(0xFF222222);

      await pump(
        tester,
        FluentSplitButtonTheme(
          style: FluentSplitButtonStyle.from(dividerColor: themed),
          child: splitButton(
            style: FluentSplitButtonStyle.from(dividerColor: explicit),
            onPressed: () {},
            onMenuPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
        explicit,
      );
    });

    testWidgets('a partial split override keeps every resolved value', (
      tester,
    ) async {
      const mine = Color(0xFF00FF00);
      await pump(
        tester,
        splitButton(
          appearance: FluentButtonAppearance.primary,
          style: FluentSplitButtonStyle.from(dividerColor: mine),
          onPressed: () {},
          onMenuPressed: () {},
        ),
      );
      await tester.pumpAndSettle();
      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
        mine,
      );
      expect(
        decorationOf(tester, sideOf(FluentSplitButtonSide.primaryAction)).color,
        light().colors.brandBackground,
        reason: 'overriding the divider must not drop the brand fill',
      );
    });

    testWidgets('the compound widget style beats the subtree theme', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      const explicit = Color(0xFF222222);

      await pump(
        tester,
        FluentCompoundButtonTheme(
          style: FluentCompoundButtonStyle.from(secondaryColor: themed),
          child: compoundButton(
            style: FluentCompoundButtonStyle.from(secondaryColor: explicit),
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<RichText>(find.byType(RichText).last).text.style?.color,
        explicit,
      );
    });

    testWidgets('the compound subtree theme beats the defaults', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentCompoundButtonTheme(
          style: FluentCompoundButtonStyle.from(secondaryColor: themed),
          child: compoundButton(onPressed: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<RichText>(find.byType(RichText).last).text.style?.color,
        themed,
      );
    });

    testWidgets('a partial compound override keeps the button half', (
      tester,
    ) async {
      await pump(
        tester,
        compoundButton(
          appearance: FluentButtonAppearance.primary,
          style: const FluentCompoundButtonStyle(
            button: FluentButtonStyle(
              borderRadius: WidgetStatePropertyAll<BorderRadius?>(
                FluentRadius.allCircular,
              ),
            ),
          ),
          onPressed: () {},
        ),
      );
      await tester.pumpAndSettle();
      final decoration = decorationOf(tester, find.byKey(compoundKey));
      expect(decoration.borderRadius, FluentRadius.allCircular);
      expect(
        decoration.color,
        light().colors.brandBackground,
        reason: 'overriding radius must not drop the brand fill',
      );
    });
  });

  group('theming', () {
    testWidgets('a subtree token override reaches the split button', (
      tester,
    ) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.brandBackground: magenta},
            child: Center(
              child: splitButton(
                appearance: FluentButtonAppearance.primary,
                onPressed: () {},
                onMenuPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final side in FluentSplitButtonSide.values) {
        expect(decorationOf(tester, sideOf(side)).color, magenta);
      }
    });

    testWidgets('a subtree token override reaches the compound button', (
      tester,
    ) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.neutralForeground2: magenta},
            child: Center(child: compoundButton(onPressed: () {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<RichText>(find.byType(RichText).last).text.style?.color,
        magenta,
        reason: 'the second line must read the overridden token',
      );
    });

    testWidgets('high contrast leaves no invisible border or divider', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(
        tester,
        splitButton(
          appearance: FluentButtonAppearance.outline,
          onPressed: () {},
          onMenuPressed: () {},
        ),
        theme: theme,
      );
      await tester.pumpAndSettle();

      for (final side in FluentSplitButtonSide.values) {
        final painter = painterOf(tester, side);
        expect(painter.borderWidth, FluentStroke.thin);
        expect(
          painter.borderColor.a,
          1.0,
          reason: '${side.name}: the outline border must be opaque here',
        );
      }
      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor.a,
        1.0,
        reason: 'the two halves must stay distinguishable in high contrast',
      );
    });

    testWidgets('high contrast keeps the compound second line opaque', (
      tester,
    ) async {
      await pump(
        tester,
        compoundButton(onPressed: () {}),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      await tester.pumpAndSettle();
      final color = tester
          .widget<RichText>(find.byType(RichText).last)
          .text
          .style
          ?.color;
      expect(color, isNotNull);
      expect(color!.a, 1.0);
    });
  });

  group('recomposition contract', () {
    testWidgets('the split build accepts BASE state', (tester) async {
      const base = FluentSplitButtonBaseState(
        enabled: true,
        menuEnabled: true,
        iconPosition: FluentButtonIconPosition.before,
        label: Text('Send'),
      );
      const mine = Color(0xFF00FF00);
      const divider = Color(0xFF0000FF);

      await pump(
        tester,
        KeyedSubtree(
          key: splitKey,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final side in FluentSplitButtonSide.values)
                buildFluentSplitButton(
                  base,
                  FluentSplitButtonStyle.from(
                    button: FluentButtonStyle.from(
                      backgroundColor: mine,
                      borderRadius: FluentRadius.allLarge,
                    ),
                    dividerColor: divider,
                  ),
                  const <WidgetState>{},
                  side: side,
                ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        decorationOf(tester, sideOf(FluentSplitButtonSide.primaryAction)).color,
        mine,
      );
      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
        divider,
      );
    });

    testWidgets('the compound build accepts BASE state', (tester) async {
      const base = FluentCompoundButtonBaseState(
        enabled: true,
        iconPosition: FluentButtonIconPosition.before,
        label: Text('Button'),
        secondaryLabel: Text('Secondary'),
      );
      const mine = Color(0xFF00FF00);
      const secondary = Color(0xFF0000FF);

      await pump(
        tester,
        KeyedSubtree(
          key: compoundKey,
          child: buildFluentCompoundButton(
            base,
            FluentCompoundButtonStyle.from(
              button: FluentButtonStyle.from(
                backgroundColor: mine,
                borderRadius: FluentRadius.allLarge,
              ),
              secondaryColor: secondary,
              secondaryTextStyle: const TextStyle(fontSize: 12, height: 1),
            ),
            const <WidgetState>{},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(decorationOf(tester, find.byKey(compoundKey)).color, mine);
      expect(
        tester.widget<RichText>(find.byType(RichText).last).text.style?.color,
        secondary,
      );
    });
  });

  group('menu button', () {
    testWidgets('is a button carrying the shared chevron', (tester) async {
      // Not a fourth widget: Figma documents the menu button as a Button with a
      // chevron, and so does upstream's MenuButton.
      await pump(
        tester,
        FluentButton(
          key: compoundKey,
          icon: fluentMenuChevron,
          iconPosition: FluentButtonIconPosition.after,
          onPressed: () {},
          child: const Text('Menu'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(FluentIcons.chevron_down_20_regular), findsOneWidget);
      // Sizeless on purpose: the button's own ramp resolves the icon size.
      expect(
        tester.widget<Icon>(find.byType(Icon)).size,
        isNull,
        reason: 'a pinned size would ignore the button size ramp',
      );
    });
  });
}
