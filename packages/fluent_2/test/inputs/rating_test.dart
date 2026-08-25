import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// Geometry and tokens are pinned against `test/fixtures/rating.json`, the
/// Figma `Rating` set (36 variants). Behaviour — half-value rounding, hover
/// preview, arrow keys, the absence of a transition — has no counterpart in the
/// design file and comes from `useRating.tsx` on `microsoft/fluentui@master`.
/// Nothing below is asserted against a value this port invented.
void main() {
  const key = Key('rating');
  final spec = loadSpec('rating');

  const sizeNames = {
    FluentRatingSize.small: 'Small',
    FluentRatingSize.medium: 'Medium',
    FluentRatingSize.large: 'Large',
    FluentRatingSize.extraLarge: 'XLarge',
  };
  const shapeNames = {
    FluentRatingShape.star: 'Stars',
    FluentRatingShape.circle: 'Circles',
    FluentRatingShape.square: 'Square',
  };

  /// A non-compact Display variant. Its frame also carries Figma's numeric
  /// label, which `FluentRating` does not render, so every assertion below
  /// reads the `Shape` row and the shape vectors under it rather than the
  /// frame.
  SpecVariant displayOf(FluentRatingSize size, FluentRatingShape shape) =>
      spec.variant({
        'Type': 'Display',
        'Compact': 'False',
        'Size': sizeNames[size]!,
        'Shape': shapeNames[shape]!,
      });

  /// The auto-layout frame holding the five shapes. Named `Shape`, like the
  /// vectors under it, but it is the only one of them with item spacing.
  SpecPart shapeRow(SpecVariant variant) =>
      variant.parts.firstWhere((p) => p.name == 'Shape' && p.gap != null);

  /// The first shape vector: the unselected layer's glyph.
  SpecPart shapeInk(SpecVariant variant) =>
      variant.parts.firstWhere((p) => p.depth == 4);

  Future<void> pump(
    WidgetTester tester,
    Widget rating, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: rating),
    ),
  );

  /// The rating's own painter, skipping the focus ring's foreground painter.
  FluentRatingPainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((c) => c.painter)
      .whereType<FluentRatingPainter>()
      .first;

  group('geometry, every size, against the Figma shape row', () {
    testWidgets('the row is exactly the Figma frame', (tester) async {
      for (final size in FluentRatingSize.values) {
        final row = shapeRow(displayOf(size, FluentRatingShape.star));

        await pump(
          tester,
          FluentRating(key: key, value: 3, size: size, onChanged: (_) {}),
        );
        // Five square boxes of the ramp size. Figma's row height is the box
        // edge; the taller variant frame belongs to the numeric label.
        expect(
          painterOf(tester).itemSize,
          row.size.height,
          reason: '${size.name}: item size',
        );
        expect(
          tester.getSize(find.byKey(key)),
          row.size,
          reason: '${size.name}: row size',
        );
      }
    });

    testWidgets('the shapes sit Spacing/Horizontal/XXS apart', (tester) async {
      for (final size in FluentRatingSize.values) {
        final row = shapeRow(displayOf(size, FluentRatingShape.star));
        expect(
          row.token('itemSpacing'),
          'Spacing/Horizontal/XXS',
          reason: '${size.name}: the token Figma binds the gap to',
        );
        expect(row.gap, FluentSpacing.xxs, reason: '${size.name}: that is 2');

        await pump(
          tester,
          FluentRating(key: key, value: 3, size: size, onChanged: (_) {}),
        );
        expect(painterOf(tester).gap, row.gap);
        // The row width is only the sum it is because of the gap: five 28
        // boxes and four 2 gaps make the 148 Figma reports at XLarge.
        expect(row.size.width, row.size.height * 5 + row.gap! * 4);
      }
    });

    testWidgets('every silhouette spans the ink Figma draws', (tester) async {
      for (final size in FluentRatingSize.values) {
        for (final shape in FluentRatingShape.values) {
          final variant = displayOf(size, shape);
          final ink = shapeInk(variant);
          final box = Offset.zero & Size.square(shapeRow(variant).size.height);
          final drawn = FluentRatingPainter.pathFor(shape, box).getBounds();

          expect(
            drawn.width,
            moreOrLessEquals(ink.size.width, epsilon: 0.01),
            reason: '${size.name} ${shape.name}: ink width',
          );
          if (shape == FluentRatingShape.star) {
            // The Figma star's tips are rounded and this painter's are not, so
            // its ink box is a shade taller at the same width. Everything else
            // is an exact primitive.
            expect(
              drawn.height,
              moreOrLessEquals(ink.size.height, epsilon: 0.4),
              reason: '${size.name} star: ink height',
            );
          } else {
            expect(
              drawn.height,
              moreOrLessEquals(ink.size.height, epsilon: 0.01),
              reason: '${size.name} ${shape.name}: ink height',
            );
          }
        }
      }
    });
  });

  group('variant axes', () {
    testWidgets('every size maps to its Figma box', (tester) async {
      // Figma's Size axis and useRatingItemStyles.styles.ts agree here:
      // Small 12, Medium 16, Large 20, XLarge 28.
      const expected = {
        FluentRatingSize.small: FluentSize.size120,
        FluentRatingSize.medium: FluentSize.size160,
        FluentRatingSize.large: FluentSize.size200,
        FluentRatingSize.extraLarge: FluentSize.size280,
      };

      for (final entry in expected.entries) {
        expect(
          shapeRow(displayOf(entry.key, FluentRatingShape.star)).size.height,
          entry.value,
          reason: '${entry.key.name}: the Figma box',
        );
        await pump(
          tester,
          FluentRating(key: key, value: 3, size: entry.key, onChanged: (_) {}),
        );
        expect(
          painterOf(tester).itemSize,
          entry.value,
          reason: '${entry.key.name}: item size',
        );
      }
    });

    testWidgets('every shape reaches the painter', (tester) async {
      for (final shape in FluentRatingShape.values) {
        await pump(
          tester,
          FluentRating(key: key, value: 3, shape: shape, onChanged: (_) {}),
        );
        expect(painterOf(tester).shape, shape);
      }
    });

    testWidgets('every colour selects its own token', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final expected = {
        FluentRatingColor.neutral: theme.colors.neutralForeground1,
        FluentRatingColor.brand: theme.colors.brandForeground1,
        FluentRatingColor.marigold: theme.colors.palette.strokeActiveRest(
          FluentPaletteFamily.marigold,
        ),
      };

      for (final entry in expected.entries) {
        await pump(
          tester,
          FluentRating(key: key, value: 3, color: entry.key, onChanged: (_) {}),
        );
        expect(
          painterOf(tester).selected,
          entry.value,
          reason: '${entry.key.name}: selected shape colour',
        );
      }
    });

    testWidgets('display fills its unselected shapes, interactive outlines '
        'them', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

      await pump(
        tester,
        const FluentRating(key: key, value: 3, type: FluentRatingType.display),
      );
      final display = painterOf(tester);
      // Figma binds the Display glyph's fill to `Background Display`, whose
      // Neutral mode is Neutral/Stroke/2/Rest — NOT the colorNeutralBackground6
      // upstream React reaches for. The file is pinned to the Neutral mode, so
      // the extracted hex is that token's light value.
      final ink = shapeInk(
        displayOf(FluentRatingSize.extraLarge, FluentRatingShape.star),
      );
      expect(ink.token('fills'), 'Background Display');
      expect(display.unselected, theme.colors.neutralStroke2);
      expect(display.unselected!.toARGB32(), ink.fill!.toARGB32());
      // transparentStroke is not in the design file at all: it is upstream's
      // `@media (forced-colors)` rule arriving through the token layer.
      expect(display.unselectedStroke, theme.colors.transparentStroke);

      await pump(tester, FluentRating(key: key, value: 3, onChanged: (_) {}));
      final interactive = painterOf(tester);
      // appearance === 'outline': the outline glyph, in the item's own colour,
      // with NO fill. Null is not transparent — an unfilled shape has no fill
      // at all, so nothing can turn opaque behind it in high contrast.
      expect(interactive.unselected, isNull);
      expect(interactive.unselectedStroke, theme.colors.neutralForeground1);
    });

    testWidgets('display picks the per-colour filled token', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      // The three modes of Figma's `Background Display`: Neutral/Stroke/2/Rest,
      // Brand/Stroke/2/Rest, Palette/Marigold/Background/2/Rest. Only marigold
      // is a background token — the other two are strokes, which is exactly
      // where React and Figma part company.
      final expected = {
        FluentRatingColor.neutral: theme.colors.neutralStroke2,
        FluentRatingColor.brand: theme.colors.brandStroke2,
        FluentRatingColor.marigold: theme.colors.palette.background2Rest(
          FluentPaletteFamily.marigold,
        ),
      };

      for (final entry in expected.entries) {
        await pump(
          tester,
          FluentRating(
            key: key,
            value: 3,
            color: entry.key,
            type: FluentRatingType.display,
          ),
        );
        expect(
          painterOf(tester).unselected,
          entry.value,
          reason: '${entry.key.name}: unselected fill',
        );
      }
    });

    testWidgets('compact draws exactly one, always full', (tester) async {
      await pump(
        tester,
        const FluentRating(
          key: key,
          value: 2.5,
          compact: true,
          type: FluentRatingType.display,
        ),
      );
      expect(painterOf(tester).fills, <double>[1]);
      expect(
        tester.getSize(find.byKey(key)),
        const Size(FluentSize.size280, FluentSize.size280),
      );
    });

    testWidgets('max controls the number of shapes', (tester) async {
      await pump(
        tester,
        const FluentRating(
          key: key,
          value: 7,
          max: 10,
          type: FluentRatingType.display,
        ),
      );
      expect(painterOf(tester).fills.length, 10);
    });
  });

  group('value and half values', () {
    testWidgets('a whole value fills whole shapes', (tester) async {
      await pump(
        tester,
        const FluentRating(key: key, value: 3, type: FluentRatingType.display),
      );
      expect(painterOf(tester).fills, <double>[1, 1, 1, 0, 0]);
    });

    testWidgets('a half value half-fills the shape it lands in', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentRating(
          key: key,
          value: 2.5,
          type: FluentRatingType.display,
        ),
      );
      expect(painterOf(tester).fills, <double>[1, 1, 0.5, 0, 0]);
    });

    testWidgets('an arbitrary value rounds to the nearest half', (
      tester,
    ) async {
      // useRatingItem: Math.round(value * 2) / 2.
      await pump(
        tester,
        const FluentRating(
          key: key,
          value: 2.7,
          type: FluentRatingType.display,
        ),
      );
      expect(painterOf(tester).fills, <double>[1, 1, 0.5, 0, 0]);
    });
  });

  group('motion', () {
    testWidgets('a value change is INSTANT — upstream declares no transition', (
      tester,
    ) async {
      // Verified against microsoft/fluentui@master: neither
      // useRatingStyles.styles.ts, useRatingItemStyles.styles.ts nor
      // useRatingDisplayStyles.styles.ts contains a `transition` of any kind.
      // The fill swaps on the frame; there is nothing to tween and no
      // FluentMotionSpec for Rating.
      await pump(
        tester,
        const FluentRating(key: key, value: 1, type: FluentRatingType.display),
      );
      expect(painterOf(tester).fills, <double>[1, 0, 0, 0, 0]);

      await pump(
        tester,
        const FluentRating(key: key, value: 4, type: FluentRatingType.display),
      );
      // A single pump, with no settle: a tweened fill would still be mid-flight.
      expect(painterOf(tester).fills, <double>[1, 1, 1, 1, 0]);
    });
  });

  group('interaction', () {
    testWidgets('hover previews the value under the pointer', (tester) async {
      double? changed;
      await pump(
        tester,
        FluentRating(key: key, value: 1, onChanged: (v) => changed = v),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();

      final topLeft = tester.getTopLeft(find.byKey(key));
      // Into the fourth box of five 28-wide boxes.
      await mouse.moveTo(topLeft + const Offset(28 * 3.5, 14));
      await tester.pump();

      expect(painterOf(tester).fills, <double>[1, 1, 1, 1, 0]);
      expect(changed, isNull, reason: 'hover previews, it does not commit');

      await mouse.moveTo(const Offset(500, 500));
      await tester.pump();
      expect(painterOf(tester).fills, <double>[
        1,
        0,
        0,
        0,
        0,
      ], reason: 'leaving restores the real value');
    });

    testWidgets('tap commits the value under the pointer', (tester) async {
      double? changed;
      await pump(
        tester,
        FluentRating(key: key, value: 1, onChanged: (v) => changed = v),
      );

      final topLeft = tester.getTopLeft(find.byKey(key));
      await tester.tapAt(topLeft + const Offset(28 * 2.5, 14));
      await tester.pump();
      expect(changed, 3);
    });

    testWidgets('with step 0.5 the left half of a shape commits a half', (
      tester,
    ) async {
      double? changed;
      await pump(
        tester,
        FluentRating(
          key: key,
          value: 1,
          step: 0.5,
          onChanged: (v) => changed = v,
        ),
      );

      final topLeft = tester.getTopLeft(find.byKey(key));
      // First quarter of the third box.
      await tester.tapAt(topLeft + const Offset(28 * 2.25, 14));
      await tester.pump();
      expect(changed, 2.5);
    });

    testWidgets('arrow keys move by one step', (tester) async {
      var current = 2.0;
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            child: StatefulBuilder(
              builder: (context, setState) => FluentRating(
                key: key,
                value: current,
                focusNode: node,
                onChanged: (v) => setState(() => current = v),
              ),
            ),
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(current, 3);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(current, 1);
    });

    testWidgets('arrows respect a half step and clamp at both ends', (
      tester,
    ) async {
      var current = 0.0;
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            child: StatefulBuilder(
              builder: (context, setState) => FluentRating(
                key: key,
                value: current,
                step: 0.5,
                max: 2,
                focusNode: node,
                onChanged: (v) => setState(() => current = v),
              ),
            ),
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(current, 0, reason: 'must not go below zero');

      for (var i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
      }
      expect(current, 2, reason: 'must not go above max');
    });

    testWidgets('the keyboard focus ring appears, the pointer one does not', (
      tester,
    ) async {
      // WidgetState.focused means keyboard-VISIBLE focus, which
      // FocusableActionDetector reports only once the framework is in
      // traditional highlight mode. The test binding starts in touch mode.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );

      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentRating(key: key, value: 3, focusNode: node, onChanged: (_) {}),
      );

      FluentFocusRingPainter ring() => tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((c) => c.foregroundPainter)
          .whereType<FluentFocusRingPainter>()
          .first;

      expect(ring().visible, isFalse);
      node.requestFocus();
      await tester.pump();
      expect(ring().visible, isTrue);
    });

    testWidgets('the ring wraps one item, not the whole row', (tester) async {
      // `useRatingItemStyles` puts `createFocusOutlineStyle` on RatingItem;
      // `useRatingStyles`' root is a bare `display: flex` with no indicator of
      // its own, and the live control grows an `::after` on the focused item
      // only. Figma has no Focused state on the item, so it does not object.
      final ring = find.descendant(
        of: find.byKey(key),
        matching: find.byType(FluentFocusRing),
      );

      await pump(tester, FluentRating(key: key, value: 3, onChanged: (_) {}));

      // extraLarge is the default: 28 square, four 2px gaps.
      expect(tester.getSize(ring), const Size(28, 28));
      expect(tester.getSize(find.byKey(key)).width, 5 * 28 + 4 * 2);
      expect(
        tester.getTopLeft(ring).dx - tester.getTopLeft(find.byKey(key)).dx,
        2 * (28 + 2),
        reason: 'the third item, which the value sits on',
      );

      // Zero clamps onto the first item rather than off the row.
      await pump(tester, FluentRating(key: key, value: 0, onChanged: (_) {}));
      expect(
        tester.getTopLeft(ring).dx - tester.getTopLeft(find.byKey(key)).dx,
        0,
      );
    });

    testWidgets('display ignores the pointer entirely', (tester) async {
      await pump(
        tester,
        const FluentRating(key: key, value: 1, type: FluentRatingType.display),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(
        tester.getTopLeft(find.byKey(key)) + const Offset(28 * 4.5, 14),
      );
      await tester.pump();

      expect(painterOf(tester).fills, <double>[1, 0, 0, 0, 0]);
    });
  });

  group('disabled', () {
    testWidgets('null onChanged is a real state, not a visual treatment', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(tester, const FluentRating(key: key, value: 1));

      expect(
        painterOf(tester).selected,
        theme.colors.neutralForegroundDisabled,
        reason: 'the disabled token, not a faded rest token',
      );

      // No hover preview.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(
        tester.getTopLeft(find.byKey(key)) + const Offset(28 * 4.5, 14),
      );
      await tester.pump();
      expect(painterOf(tester).fills, <double>[1, 0, 0, 0, 0]);
    });

    testWidgets('a disabled rating refuses focus and the arrow keys', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, FluentRating(key: key, value: 1, focusNode: node));

      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isFalse);
    });
  });

  group('semantics', () {
    testWidgets('interactive announces itself as a slider', (tester) async {
      await pump(
        tester,
        FluentRating(
          key: key,
          value: 3,
          semanticLabel: 'Overall rating',
          onChanged: (_) {},
        ),
      );

      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          isSlider: true,
          isEnabled: true,
          hasEnabledState: true,
          label: 'Overall rating',
          value: '3 of 5',
          increasedValue: '4 of 5',
          decreasedValue: '2 of 5',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          // Merged up from FluentInteractive's FocusableActionDetector: the
          // rating is one focus stop, activated by pointer or by Space/Enter.
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
    });

    testWidgets('the increase action moves the value', (tester) async {
      double? changed;
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentRating(key: key, value: 3, onChanged: (v) => changed = v),
      );

      tester.semantics.performAction(
        find.semantics.byAction(SemanticsAction.increase),
        SemanticsAction.increase,
      );
      await tester.pump();
      expect(changed, 4);
      handle.dispose();
    });

    testWidgets('display announces a value, not a control', (tester) async {
      await pump(
        tester,
        const FluentRating(
          key: key,
          value: 3.5,
          type: FluentRatingType.display,
        ),
      );

      // role="img" upstream: a picture of a value, with no control semantics
      // and nothing for a screen reader to try to operate.
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(label: '3.5 of 5', isImage: true),
      );
    });

    testWidgets('a disabled rating still says so', (tester) async {
      await pump(tester, const FluentRating(key: key, value: 3));
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          isSlider: true,
          hasEnabledState: true,
          value: '3 of 5',
        ),
      );
    });
  });

  group('style resolution order', () {
    testWidgets('the widget style beats the subtree theme beats the defaults', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      const explicit = Color(0xFF222222);

      await pump(
        tester,
        FluentRatingTheme(
          style: FluentRatingStyle.from(selectedColor: themed),
          child: FluentRating(
            key: key,
            value: 3,
            style: FluentRatingStyle.from(selectedColor: explicit),
            onChanged: (_) {},
          ),
        ),
      );
      expect(painterOf(tester).selected, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentRatingTheme(
          style: FluentRatingStyle.from(selectedColor: themed),
          child: FluentRating(key: key, value: 3, onChanged: (_) {}),
        ),
      );
      expect(painterOf(tester).selected, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        FluentRating(
          key: key,
          value: 3,
          style: FluentRatingStyle.from(itemSize: 40),
          onChanged: (_) {},
        ),
      );
      expect(painterOf(tester).itemSize, 40);
      expect(
        painterOf(tester).selected,
        theme.colors.neutralForeground1,
        reason: 'overriding the size must not drop the resolved colour',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentRatingBaseState(
        value: 2,
        max: 4,
        compact: false,
        enabled: true,
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentRating(
            base,
            FluentRatingStyle.from(
              selectedColor: mine,
              itemSize: 24,
              shape: FluentRatingShape.circle,
            ),
            const <WidgetState>{},
          ),
        ),
      );

      final painter = painterOf(tester);
      expect(painter.selected, mine);
      expect(painter.itemSize, 24);
      expect(painter.shape, FluentRatingShape.circle);
      expect(painter.fills, <double>[1, 1, 0, 0]);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentRatingState(
        value: 3,
        color: FluentRatingColor.brand,
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentRatingStyle(
        state,
        theme,
      ).merge(FluentRatingStyle.from(shape: FluentRatingShape.square));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentRating(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(painterOf(tester).selected, theme.colors.brandForeground1);
      expect(painterOf(tester).shape, FluentRatingShape.square);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the rating', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.brandForeground1: magenta},
            child: Center(
              child: FluentRating(
                key: key,
                value: 3,
                color: FluentRatingColor.brand,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(painterOf(tester).selected, magenta);
    });

    testWidgets('high contrast leaves no invisible outline', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(
        tester,
        const FluentRating(key: key, value: 3, type: FluentRatingType.display),
        theme: theme,
      );

      final painter = painterOf(tester);
      // Forced colors is the one case Figma does not model, and the one case
      // where `Background Display` cannot be followed: neutralStroke2 collapses
      // onto CanvasText there, which is also the selected colour, so an
      // unselected shape would be indistinguishable from a full one. Upstream's
      // `@media (forced-colors)` rule — `color: Canvas` — wins instead.
      expect(painter.unselected, theme.colors.neutralBackground6);
      expect(painter.unselected, isNot(theme.colors.neutralStroke2));
      // Upstream's forced-colors rule for the filled appearance is
      // `color: Canvas; stroke: CanvasText`. Our token layer produces exactly
      // that: neutralBackground6 becomes the canvas and transparentStroke —
      // invisible in every other theme — becomes the text colour. An unselected
      // shape that is canvas-on-canvas is only legible because of that outline.
      expect(painter.unselectedStroke, isNotNull);
      expect(painter.unselectedStroke!.a, 1.0);
      expect(painter.strokeWidth, greaterThan(0));
      expect(
        painter.unselectedStroke,
        isNot(painter.unselected),
        reason: 'the outline must not match the fill it sits on',
      );
    });

    testWidgets('dark resolves every shape colour', (tester) async {
      final theme = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        const FluentRating(
          key: key,
          value: 3,
          color: FluentRatingColor.marigold,
          type: FluentRatingType.display,
        ),
        theme: theme,
      );
      expect(
        painterOf(tester).selected,
        theme.colors.palette.strokeActiveRest(FluentPaletteFamily.marigold),
      );
      expect(
        painterOf(tester).unselected,
        theme.colors.palette.background2Rest(FluentPaletteFamily.marigold),
      );
    });
  });
}
