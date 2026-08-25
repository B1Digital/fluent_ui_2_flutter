import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentToolbar` is a **container**, so these tests assert the absence of the
/// control machinery as deliberately as they assert the geometry: no
/// `FluentInteractive` of its own, no focus ring, no transition, and no Escape
/// handler.
///
/// Two things about the Figma set shape the whole file:
///
/// * the `Size` axis moves only the toolbar's own padding. All six variants hold
///   32-high medium buttons, and upstream's `useToolbarButton` hard-codes
///   `size: 'medium'`, so a small toolbar is a tighter frame around the same
///   controls.
/// * the `Type` axis changes exactly one thing, the elevation. The surface,
///   border, radius and stroke width are byte-identical across all six.
void main() {
  const key = Key('toolbar');

  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  final dark = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
  final highContrast = FluentThemeData.highContrast(
    fontPlatform: FluentFontPlatform.web,
  );

  /// A 32-high subtle icon button — what every Figma variant is made of.
  Widget item(
    String label, {
    VoidCallback? onPressed = _noop,
    FocusNode? focusNode,
  }) => FluentButton.icon(
    icon: const Icon(FluentIcons.circle_20_regular, size: 20),
    semanticLabel: label,
    appearance: FluentButtonAppearance.subtle,
    focusNode: focusNode,
    onPressed: onPressed,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget toolbar, {
    FluentThemeData? theme,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light,
      home: Directionality(
        textDirection: direction,
        child: Center(child: toolbar),
      ),
    ),
  );

  /// The toolbar's own surface: the first coloured [DecoratedBox] under it,
  /// which is the one `buildFluentToolbar` paints.
  BoxDecoration surface(WidgetTester tester, {Key of = key}) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(of),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((box) => box.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((decoration) => decoration.color != null);

  /// The toolbar's own inset: the outermost [Padding] under it.
  EdgeInsets inset(WidgetTester tester) => tester
      .widgetList<Padding>(
        find.descendant(of: find.byKey(key), matching: find.byType(Padding)),
      )
      .first
      .padding
      .resolve(TextDirection.ltr);

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('toolbar');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 6);
      expect(spec.properties['Size'], <String>['Medium', 'Large', 'Small']);
      expect(spec.properties['Type'], <String>[
        'Static',
        'Contextual (floating)',
      ]);
    });

    testWidgets('every Size x Type variant reproduces its Figma frame', (
      tester,
    ) async {
      for (final variant in spec.variants) {
        final size = switch (variant.props['Size']) {
          'Small' => FluentToolbarSize.small,
          'Large' => FluentToolbarSize.large,
          _ => FluentToolbarSize.medium,
        };
        final type = variant.props['Type'] == 'Contextual (floating)'
            ? FluentToolbarType.floating
            : FluentToolbarType.standard;

        await pump(
          tester,
          FluentToolbar(
            key: key,
            size: size,
            type: type,
            items: <Widget>[item('one'), item('two')],
          ),
        );

        // Height only. The fixture's 1176 width is the demo frame's, not the
        // component's — a toolbar hugs its items.
        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: '${variant.name}: height',
        );

        // Figma states the inset on `Start-content` / `End-content` rather than
        // on the variant frame, mirrored left and right.
        final expected = switch (size) {
          FluentToolbarSize.small => const EdgeInsets.symmetric(
            horizontal: FluentSpacing.xs,
          ),
          FluentToolbarSize.medium => const EdgeInsets.symmetric(
            horizontal: FluentSpacing.s,
            vertical: FluentSpacing.xs,
          ),
          FluentToolbarSize.large => const EdgeInsets.symmetric(
            horizontal: FluentSpacing.xl,
            vertical: FluentSpacing.s,
          ),
        };
        expect(inset(tester), expected, reason: '${variant.name}: padding');

        final decoration = surface(tester);

        // `Neutral/Background/1/Rest`, identical on all six variants.
        expect(
          decoration.color,
          light.colors.neutralBackground1,
          reason: '${variant.name}: fill (token ${variant.token('fills')})',
        );
        expect(
          decoration.borderRadius?.resolve(TextDirection.ltr),
          variant.radius,
          reason: '${variant.name}: radius',
        );

        // `Neutral/Stroke/Transparent/Rest` at `Stroke width/Thin`.
        final border = decoration.border! as Border;
        expect(
          border.top.width,
          variant.strokeWidth,
          reason: '${variant.name}: stroke width',
        );
        expect(
          border.top.color,
          light.colors.transparentStroke,
          reason: '${variant.name}: stroke (token ${variant.token('strokes')})',
        );

        // The whole Type axis: `Shadow/Key` + `Shadow/Ambient` on the three
        // floating variants, nothing on the three static ones.
        expect(
          decoration.boxShadow,
          type == FluentToolbarType.floating
              ? light.shadow(FluentElevation.shadow8)
              : isNull,
          reason: '${variant.name}: elevation',
        );
        expect(
          variant.tokens.containsKey('effects'),
          type == FluentToolbarType.floating,
          reason: '${variant.name}: the fixture agrees about the elevation',
        );
      }
    });

    testWidgets('the divider is FluentDivider in a 24-wide slot inset 6', (
      tester,
    ) async {
      final variant = spec.variant(const <String, String>{
        'Size': 'Medium',
        'Type': 'Static',
      });

      // Figma node 9383:24508 — a 24x32 `Divider` frame with padding
      // [6, 0, 6, 0] holding a rotated Divider instance whose rule is 1px
      // `Neutral/Stroke/2/Rest`.
      final slot = variant.part('Divider');
      expect(slot.size.width, FluentSize.size240);
      expect(slot.padding, const EdgeInsets.symmetric(vertical: 6));

      await pump(
        tester,
        FluentToolbar(
          key: key,
          items: <Widget>[
            item('one'),
            const FluentToolbarDivider(),
            item('two'),
          ],
        ),
      );

      final slotRect = tester.getRect(find.byType(FluentToolbarDivider));
      expect(slotRect.width, slot.size.width, reason: 'slot width');
      // The item row is 32 tall — the button height — at every toolbar size.
      expect(slotRect.height, 32, reason: 'slot spans the item row');

      // Reused, not reimplemented: the rule is FluentDivider's.
      expect(
        find.descendant(
          of: find.byType(FluentToolbarDivider),
          matching: find.byType(FluentDivider),
        ),
        findsOneWidget,
      );

      final rule = find.descendant(
        of: find.byType(FluentToolbarDivider),
        matching: find.byType(ColoredBox),
      );
      final ruleRect = tester.getRect(rule);
      expect(ruleRect.width, FluentStroke.thin, reason: 'hairline');
      expect(
        ruleRect.height,
        slotRect.height - 12,
        reason: 'SNudge off the top and the bottom',
      );
      expect(
        ruleRect.center.dx,
        moreOrLessEquals(slotRect.center.dx),
        reason: 'centred in its slot',
      );
      expect(
        tester.widget<ColoredBox>(rule).color,
        light.colors.neutralStroke2,
      );
    });

    testWidgets('items butt against each other — the Figma gap is zero', (
      tester,
    ) async {
      final variant = spec.variant(const <String, String>{
        'Size': 'Medium',
        'Type': 'Static',
      });
      // Both content frames carry `itemSpacing: 0`; upstream's root is a bare
      // `display: flex` with no gap either.
      expect(variant.part('Start-content').gap, 0);
      expect(variant.part('End-content').gap, 0);

      await pump(
        tester,
        FluentToolbar(key: key, items: <Widget>[item('one'), item('two')]),
      );

      final first = tester.getRect(find.byType(FluentButton).at(0));
      final second = tester.getRect(find.byType(FluentButton).at(1));
      expect(second.left, moreOrLessEquals(first.right));
    });
  });

  group('themes', () {
    testWidgets('dark selects the dark alias of the same tokens', (
      tester,
    ) async {
      await pump(
        tester,
        FluentToolbar(key: key, items: <Widget>[item('one')]),
        theme: dark,
      );
      final decoration = surface(tester);
      expect(decoration.color, dark.colors.neutralBackground1);
      expect(
        (decoration.border! as Border).top.color,
        dark.colors.transparentStroke,
      );
    });

    testWidgets('high contrast outlines the surface rather than losing it', (
      tester,
    ) async {
      await pump(
        tester,
        FluentToolbar(
          key: key,
          type: FluentToolbarType.floating,
          items: <Widget>[
            item('one'),
            const FluentToolbarDivider(),
            item('two'),
          ],
        ),
        theme: highContrast,
      );

      final decoration = surface(tester);
      final border = decoration.border! as Border;

      // `transparentStroke` resolves to the *text* colour in high contrast. A
      // hardcoded Colors.transparent — or a null border — would leave a floating
      // toolbar with no edge at all there, since the shadow does not render.
      expect(border.top.color, highContrast.colors.transparentStroke);
      expect(
        border.top.color.a,
        1,
        reason: 'opaque, not a transparent literal',
      );
      expect(border.top.width, greaterThan(0));
      expect(decoration.color!.a, 1, reason: 'the surface is opaque');
      expect(
        decoration.color,
        isNot(border.top.color),
        reason: 'the outline reads against the fill',
      );

      // And the rule between groups survives too.
      final rule = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(FluentToolbarDivider),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(rule.color, highContrast.colors.neutralStroke2);
      expect(rule.color.a, 1);
    });
  });

  group('motion', () {
    // `useToolbarStyles.styles.ts` and `useToolbarDividerStyles.styles.ts` on
    // microsoft/fluentui@master declare no transition, no animation and no
    // motionTokens reference at all. This is the Checkbox / Divider / Tooltip
    // category, not an omission waiting to be "improved".
    testWidgets('a size and type change lands on the very next frame', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentToolbar(
          key: key,
          items: <Widget>[SizedBox.square(dimension: 32)],
        ),
      );
      expect(inset(tester).horizontal, FluentSpacing.s * 2);
      expect(surface(tester).boxShadow, isNull);

      await pump(
        tester,
        const FluentToolbar(
          key: key,
          size: FluentToolbarSize.large,
          type: FluentToolbarType.floating,
          items: <Widget>[SizedBox.square(dimension: 32)],
        ),
      );

      // No settle. One frame is the whole transition.
      expect(inset(tester).horizontal, FluentSpacing.xl * 2);
      expect(surface(tester).boxShadow, light.shadow(FluentElevation.shadow8));
      expect(
        tester.hasRunningAnimations,
        isFalse,
        reason: 'the toolbar drives no controller',
      );
    });

    testWidgets('the toolbar chrome owns no implicit animation', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentToolbar(
          key: key,
          items: <Widget>[SizedBox.square(dimension: 32)],
        ),
      );
      // With no button in the row there is nothing left that could animate.
      expect(find.byType(FluentAnimatedStyle<Color>), findsNothing);
    });

    testWidgets('reduced motion is the same picture, not a faster one', (
      tester,
    ) async {
      Widget build({required bool reduced, required FluentToolbarType type}) =>
          FluentApp(
            theme: light,
            builder: (context, child) => MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: child!,
            ),
            home: Center(
              child: FluentToolbar(
                key: key,
                type: type,
                items: <Widget>[item('one')],
              ),
            ),
          );

      await tester.pumpWidget(
        build(reduced: true, type: FluentToolbarType.standard),
      );
      expect(surface(tester).boxShadow, isNull);

      await tester.pumpWidget(
        build(reduced: true, type: FluentToolbarType.floating),
      );
      // Already at the end state on the first frame, with nothing scheduled.
      expect(surface(tester).boxShadow, light.shadow(FluentElevation.shadow8));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('keyboard', () {
    testWidgets('the whole toolbar is one tab stop', (tester) async {
      final before = FocusNode(debugLabel: 'before');
      final after = FocusNode(debugLabel: 'after');
      final one = FocusNode(debugLabel: 'one');
      final two = FocusNode(debugLabel: 'two');
      addTearDown(before.dispose);
      addTearDown(after.dispose);
      addTearDown(one.dispose);
      addTearDown(two.dispose);

      await pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FluentButton(
              focusNode: before,
              onPressed: _noop,
              child: const Text('b'),
            ),
            FluentToolbar(
              key: key,
              items: <Widget>[
                item('one', focusNode: one),
                item('two', focusNode: two),
              ],
            ),
            FluentButton(
              focusNode: after,
              onPressed: _noop,
              child: const Text('a'),
            ),
          ],
        ),
      );

      before.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(one.hasFocus, isTrue, reason: 'Tab enters at the roving item');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        two.hasFocus,
        isFalse,
        reason: 'the second item is not a second tab stop',
      );
      expect(after.hasFocus, isTrue, reason: 'Tab leaves the toolbar');
    });

    testWidgets('arrows move between items and wrap around', (tester) async {
      final one = FocusNode(debugLabel: 'one');
      final two = FocusNode(debugLabel: 'two');
      final three = FocusNode(debugLabel: 'three');
      addTearDown(one.dispose);
      addTearDown(two.dispose);
      addTearDown(three.dispose);

      await pump(
        tester,
        FluentToolbar(
          key: key,
          items: <Widget>[
            item('one', focusNode: one),
            item('two', focusNode: two),
            item('three', focusNode: three),
          ],
        ),
      );

      one.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(two.hasFocus, isTrue);

      // `axis: 'both'` upstream — the vertical arrows walk the same row.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(three.hasFocus, isTrue);

      // `circular: true` upstream.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(one.hasFocus, isTrue, reason: 'wraps to the first item');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(three.hasFocus, isTrue, reason: 'wraps back to the last');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(two.hasFocus, isTrue);
    });

    testWidgets('the horizontal arrows follow the reading direction', (
      tester,
    ) async {
      final one = FocusNode(debugLabel: 'one');
      final two = FocusNode(debugLabel: 'two');
      addTearDown(one.dispose);
      addTearDown(two.dispose);

      await pump(
        tester,
        FluentToolbar(
          key: key,
          items: <Widget>[
            item('one', focusNode: one),
            item('two', focusNode: two),
          ],
        ),
        direction: TextDirection.rtl,
      );

      one.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(two.hasFocus, isTrue, reason: 'Left is forwards in RTL');
    });

    testWidgets('dividers and disabled items are stepped over', (tester) async {
      final one = FocusNode(debugLabel: 'one');
      final disabled = FocusNode(debugLabel: 'disabled');
      final three = FocusNode(debugLabel: 'three');
      addTearDown(one.dispose);
      addTearDown(disabled.dispose);
      addTearDown(three.dispose);

      await pump(
        tester,
        FluentToolbar(
          key: key,
          items: <Widget>[
            item('one', focusNode: one),
            const FluentToolbarDivider(),
            // Disabled is a real state: the button refuses focus outright.
            item('two', focusNode: disabled, onPressed: null),
            item('three', focusNode: three),
          ],
        ),
      );

      one.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(disabled.hasFocus, isFalse, reason: 'a disabled item is skipped');
      expect(three.hasFocus, isTrue, reason: 'and so is the divider');
    });

    testWidgets('the tab stop parks on the first item that can take it', (
      tester,
    ) async {
      final before = FocusNode(debugLabel: 'before');
      final two = FocusNode(debugLabel: 'two');
      addTearDown(before.dispose);
      addTearDown(two.dispose);

      await pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FluentButton(
              focusNode: before,
              onPressed: _noop,
              child: const Text('b'),
            ),
            FluentToolbar(
              key: key,
              items: <Widget>[
                // Item 0 is a divider, so a naive roving index would leave the
                // toolbar with no tab stop at all.
                const FluentToolbarDivider(),
                item('two', focusNode: two),
              ],
            ),
          ],
        ),
      );
      await tester.pump();

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(two.hasFocus, isTrue);
    });

    testWidgets('Escape is left alone — a toolbar has nothing to dismiss', (
      tester,
    ) async {
      var dismissed = 0;
      final one = FocusNode(debugLabel: 'one');
      addTearDown(one.dispose);

      await pump(
        tester,
        Actions(
          actions: <Type, Action<Intent>>{
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                dismissed++;
                return null;
              },
            ),
          },
          child: FluentToolbar(
            key: key,
            items: <Widget>[item('one', focusNode: one)],
          ),
        ),
      );

      one.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(
        dismissed,
        1,
        reason: 'Escape travels on to the dialog or popover outside',
      );
      expect(one.hasFocus, isTrue, reason: 'and moves no focus on the way');
    });

    testWidgets('the roving index is remembered across a Tab round trip', (
      tester,
    ) async {
      final before = FocusNode(debugLabel: 'before');
      final one = FocusNode(debugLabel: 'one');
      final two = FocusNode(debugLabel: 'two');
      addTearDown(before.dispose);
      addTearDown(one.dispose);
      addTearDown(two.dispose);

      await pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FluentButton(
              focusNode: before,
              onPressed: _noop,
              child: const Text('b'),
            ),
            FluentToolbar(
              key: key,
              items: <Widget>[
                item('one', focusNode: one),
                item('two', focusNode: two),
              ],
            ),
          ],
        ),
      );

      one.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(two.hasFocus, isTrue);

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(two.hasFocus, isTrue, reason: 'back to the item that was left');
    });
  });

  group('overlays reached from a toolbar item', () {
    testWidgets('a FluentThemeOverride around the toolbar reaches the popup', (
      tester,
    ) async {
      const magenta = Color(0xFFFF00FF);

      await tester.pumpWidget(
        FluentApp(
          theme: light,
          home: Center(
            // FluentTheme is an InheritedTheme, so this has to survive the trip
            // into the Overlay — the popup builds in a different branch of the
            // tree and would otherwise fall back to the app theme.
            child: FluentThemeOverride(
              colors: const <FluentColorToken, Color>{
                FluentColorToken.neutralBackground1: magenta,
              },
              child: FluentToolbar(
                key: key,
                items: <Widget>[
                  // Figma gives each toolbar dropdown a fixed-width slot
                  // (`Dropdown`, 112 wide at medium); a row that hugs its
                  // children cannot size an Expanded on its own.
                  SizedBox(
                    width: 112,
                    child: FluentDropdown<int>(
                      placeholder: const Text('pick'),
                      options: const <FluentDropdownOption<int>>[
                        FluentDropdownOption<int>(value: 1, label: Text('one')),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(surface(tester).color, magenta, reason: 'the trigger side');

      await tester.tap(find.byType(FluentDropdown<int>));
      await tester.pumpAndSettle();

      // The popup surface lives outside the toolbar's subtree entirely.
      final popup = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .where((decoration) => decoration.boxShadow != null)
          .toList();
      expect(popup, isNotEmpty, reason: 'the popup is open');
      expect(
        popup.single.color,
        magenta,
        reason: 'the override crossed the Overlay boundary',
      );
    });
  });

  group('semantics', () {
    testWidgets('the toolbar is one named group of its items', (tester) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        FluentToolbar(
          key: key,
          semanticLabel: 'Formatting',
          items: <Widget>[
            item('Bold'),
            const FluentToolbarDivider(),
            item('Link', onPressed: null),
          ],
        ),
      );

      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(label: 'Formatting'),
      );
      // The rule is decoration; it must not be announced.
      expect(find.bySemanticsLabel('Bold'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Link')),
        matchesSemantics(label: 'Link', isButton: true, hasEnabledState: true),
      );

      handle.dispose();
    });
  });

  group('customisation', () {
    testWidgets('style wins over the theme, which wins over the defaults', (
      tester,
    ) async {
      const themed = Color(0xFF112233);
      const own = Color(0xFF445566);

      await pump(
        tester,
        FluentToolbarTheme(
          style: FluentToolbarStyle.from(backgroundColor: themed, gap: 4),
          child: FluentToolbar(
            key: key,
            style: FluentToolbarStyle.from(backgroundColor: own),
            items: <Widget>[item('one'), item('two')],
          ),
        ),
      );

      // Per-property merge: the widget's style replaces only the colour, and the
      // subtree theme's gap survives underneath it.
      expect(surface(tester).color, own);
      final first = tester.getRect(find.byType(FluentButton).at(0));
      final second = tester.getRect(find.byType(FluentButton).at(1));
      expect(second.left - first.right, 4);
    });

    testWidgets('the subtree theme restyles the dividers too', (tester) async {
      await pump(
        tester,
        FluentToolbarTheme(
          style: FluentToolbarStyle.from(dividerWidth: 40),
          child: FluentToolbar(
            key: key,
            items: <Widget>[item('one'), const FluentToolbarDivider()],
          ),
        ),
      );

      expect(tester.getSize(find.byType(FluentToolbarDivider)).width, 40);
    });

    test('merge and copyWith are per-property', () {
      const base = FluentToolbarStyle(
        gap: WidgetStatePropertyAll<double?>(2),
        dividerWidth: WidgetStatePropertyAll<double?>(24),
      );
      const over = FluentToolbarStyle(gap: WidgetStatePropertyAll<double?>(8));

      expect(base.merge(over).gap, over.gap);
      expect(base.merge(over).dividerWidth, base.dividerWidth);
      expect(base.merge(null), base);
      expect(
        base.copyWith(gap: const WidgetStatePropertyAll<double?>(8)),
        base.merge(over),
      );
      expect(base, isNot(over));
      expect(base.hashCode, base.copyWith().hashCode);
    });
  });
}

void _noop() {}
