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
/// `test/fixtures/secondary_action.json` is the Figma `.Secondary action` set
/// (`9026:1241`, 25 variants) — the chevron half of a split button, which Figma
/// draws as its own component and embeds unresized in all 150 `Split button`
/// variants. Every chevron-half number below is asserted against it.
///
/// The two things that set does not carry were read straight out of the same
/// Figma file and are pinned here as literals, each naming the token Figma binds:
///
/// - the **divider**, which is the primary half's `strokeRightWeight` on
///   `Split button` (`9026:1317`) — the chevron half has `strokeLeftWeight: 0`
///   in every bordered variant, so the rule is drawn exactly once;
/// - the **compound** geometry and ramps from `Compound button` (`9026:2278`).
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

  /// The rendered surface of one half.
  ///
  /// Found by position rather than by the edge painter: the appearances Figma
  /// leaves undivided and unbordered — subtle and transparent — have no painter
  /// at all, and a finder that silently matched nothing there would turn every
  /// assertion below into a no-op.
  Finder sideOf(FluentSplitButtonSide side) => find
      .descendant(
        of: find.byKey(splitKey),
        matching: find.byType(ConstrainedBox),
      )
      .at(side.index);

  /// The edge painter of one half, or null where Figma paints no edge.
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
      // Figma binds these to the primary half's `strokes`, at
      // `strokeRightWeight: Stroke width/Thin`, in Split button 9026:1317.
      // Upstream instead says `colorNeutralStrokeOnBrand` (the /1/ step) for
      // Primary and gives Subtle and Transparent a transparent rule; the Figma
      // file paints no stroke on those two at all, on either half, in any
      // state. Figma wins.
      final expected = <FluentButtonAppearance, Color?>{
        FluentButtonAppearance.primary: theme.colors.neutralStrokeOnBrand2,
        FluentButtonAppearance.secondary: theme.colors.neutralStroke1,
        FluentButtonAppearance.outline: theme.colors.neutralStroke1,
        FluentButtonAppearance.subtle: null,
        FluentButtonAppearance.transparent: null,
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
        final painter = maybePainterOf(
          tester,
          FluentSplitButtonSide.primaryAction,
        );
        expect(
          painter?.dividerColor,
          entry.value,
          reason: '${entry.key.name}: divider',
        );
      }
    });

    testWidgets('the primary divider ramps with the primary half', (
      tester,
    ) async {
      // `Neutral/Stroke/on Brand/2/<State>` on every Primary variant of
      // 9026:1317 — a rest-only token would leave the rule stranded on a fill
      // that has moved underneath it.
      final theme = light();
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        splitButton(
          appearance: FluentButtonAppearance.primary,
          focusNode: node,
          onPressed: () {},
          onMenuPressed: () {},
        ),
      );
      await tester.pumpAndSettle();
      expect(
        painterOf(tester, FluentSplitButtonSide.primaryAction).dividerColor,
        theme.colors.neutralStrokeOnBrand2,
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
        theme.colors.neutralStrokeOnBrand2Hover,
      );
    });

    testWidgets('a disabled primary split button has no divider at all', (
      tester,
    ) async {
      // Both halves fall to neutralBackgroundDisabled and Figma paints nothing
      // between them, so there is no rule to select a token for.
      await pump(
        tester,
        splitButton(appearance: FluentButtonAppearance.primary),
      );
      await tester.pumpAndSettle();
      expect(maybePainterOf(tester, FluentSplitButtonSide.primaryAction), null);
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

    testWidgets('the chevron half is the width the fixture states, at every '
        'size', (tester) async {
      // `.Secondary action` has no size axis: all 25 variants measure 24 wide,
      // and Split button embeds the instance unresized next to a 40-high Large
      // half as much as next to a 24-high Small one. The button ramp would have
      // made it 52 wide at Large.
      final chevron = loadSpec(
        'secondary_action',
      ).variant(const {'Style': 'Secondary', 'State': 'Rest'});

      for (final size in FluentButtonSize.values) {
        await pump(
          tester,
          splitButton(size: size, onPressed: () {}, onMenuPressed: () {}),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(sideOf(FluentSplitButtonSide.menu)).width,
          chevron.size.width,
          reason: '${size.name}: chevron width',
        );
      }
      // Which is also WCAG 2.2's minimum for adjacent targets.
      expect(chevron.size.width, FluentSize.size240);
    });

    testWidgets('the chevron half takes its own inset and glyph, not the '
        'button ramp', (tester) async {
      final chevron = loadSpec(
        'secondary_action',
      ).variant(const {'Style': 'Secondary', 'State': 'Rest'});
      // 6px each side of a 12px glyph is exactly the 24 above; the button ramp
      // would have inset 12 and drawn 20.
      expect(chevron.padding, const EdgeInsets.symmetric(horizontal: 6));
      expect(chevron.token('paddingLeft'), 'Spacing/Horizontal/SNudge');
      expect(chevron.token('paddingTop'), 'Spacing/Vertical/None');
      expect(chevron.gap, 0);

      for (final size in FluentButtonSize.values) {
        final style = resolveFluentSplitButtonStyle(
          resolveFluentSplitButtonState(size: size),
          light(),
          side: FluentSplitButtonSide.menu,
        ).button!;
        const rest = <WidgetState>{};
        expect(
          style.padding!.resolve(rest),
          chevron.padding,
          reason: '${size.name}: chevron padding',
        );
        expect(style.gap!.resolve(rest), chevron.gap, reason: size.name);
        expect(
          style.iconSize!.resolve(rest),
          FluentSize.size120,
          reason: '${size.name}: chevron glyph',
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
      // A three-sided rounded border is not a shape BoxDecoration can express,
      // so the halves must carry no Border of their own — one would double up
      // with the painter and square off the corners it does not own.
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

    testWidgets('the first line is a step louder than the button label', (
      tester,
    ) async {
      // Compound 9026:2278 binds `Primary text` to Neutral/Foreground/1/Rest on
      // Subtle and Transparent too, where a plain button's label takes
      // Neutral/Foreground/2/Rest. The second line is what carries the quieter
      // step here.
      final theme = light();
      for (final appearance in <FluentButtonAppearance>[
        FluentButtonAppearance.subtle,
        FluentButtonAppearance.transparent,
      ]) {
        await pump(
          tester,
          compoundButton(appearance: appearance, onPressed: () {}),
        );
        await tester.pumpAndSettle();
        final texts = tester
            .widgetList<RichText>(find.byType(RichText))
            .toList();
        expect(
          texts.first.text.style?.color,
          theme.colors.neutralForeground1,
          reason: '${appearance.name}: first line',
        );
        expect(
          texts.last.text.style?.color,
          theme.colors.neutralForeground2,
          reason: '${appearance.name}: second line',
        );
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

    testWidgets('the two lines never share a type ramp step', (tester) async {
      // Compound button 9026:2278: `Primary text` is 14/20 Semibold and
      // `Secondary text` 12/16 Regular in ALL 75 variants — the type ramp does
      // not move with the size axis, only the inset does. Upstream steps Large
      // up to fontSizeBase400/300 and pins the second line to `lineHeight: 100%`;
      // Figma does neither.
      for (final size in FluentButtonSize.values) {
        await pump(tester, compoundButton(size: size, onPressed: () {}));
        await tester.pumpAndSettle();
        final texts = tester
            .widgetList<RichText>(find.byType(RichText))
            .toList();
        expect(
          texts.first.text.style?.fontSize,
          14,
          reason: '${size.name}: primary fontSize',
        );
        expect(
          texts.first.text.style!.height! * 14,
          20,
          reason: '${size.name}: primary lineHeight',
        );
        expect(
          texts.last.text.style?.fontSize,
          12,
          reason: '${size.name}: secondary fontSize',
        );
        expect(
          texts.last.text.style!.height! * 12,
          16,
          reason: '${size.name}: secondary lineHeight',
        );
      }
    });

    testWidgets('every size uses the compound padding, not the button ramp', (
      tester,
    ) async {
      // Compound button 9026:2278 insets uniformly — Spacing S, M and L on all
      // four sides — and reuses the same number as the icon gap. Upstream's
      // asymmetric top/bottom pair is not what the Figma file draws.
      const expected = <FluentButtonSize, EdgeInsets>{
        FluentButtonSize.small: EdgeInsets.all(FluentSpacing.s),
        FluentButtonSize.medium: EdgeInsets.all(FluentSpacing.m),
        FluentButtonSize.large: EdgeInsets.all(FluentSpacing.l),
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
          entry.value.top,
          reason: '${entry.key.name}: the icon gap is the inset',
        );
      }
    });

    testWidgets('the height is content-driven, not the button ramp', (
      tester,
    ) async {
      // `height: auto` on the compound root: the inset twice plus the two line
      // heights (20 + 16, at every size), never the button's 24/32/40.
      const expected = <FluentButtonSize, double>{
        FluentButtonSize.small: 8 + 20 + 16 + 8,
        FluentButtonSize.medium: 12 + 20 + 16 + 12,
        FluentButtonSize.large: 16 + 20 + 16 + 16,
      };

      for (final entry in expected.entries) {
        await pump(tester, compoundButton(size: entry.key, onPressed: () {}));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(compoundKey)).height,
          entry.value,
          reason: '${entry.key.name}: height',
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
