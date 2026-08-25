import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentSearchBox` is the wave's first text input: it owns the `EditableText`
/// wiring the other input components will reuse. These tests therefore cover
/// the editor's behaviour as well as the Figma fidelity of its chrome.
void main() {
  const key = Key('search-box');

  final appearanceNames = <FluentSearchBoxAppearance, String>{
    FluentSearchBoxAppearance.filledDarker: 'Filled darker',
    FluentSearchBoxAppearance.filledLighter: 'Filled lighter',
    FluentSearchBoxAppearance.outline: 'Outline',
    FluentSearchBoxAppearance.transparent: 'Transparent',
  };
  final sizeNames = <FluentSearchBoxSize, String>{
    FluentSearchBoxSize.small: 'Small',
    FluentSearchBoxSize.medium: 'Medium',
    FluentSearchBoxSize.large: 'Large',
  };

  Future<void> pump(
    WidgetTester tester,
    Widget searchBox, {
    FluentThemeData? theme,
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      builder: reducedMotion
          ? (context, child) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: child!,
            )
          : null,
      // Figma draws every variant at a fixed 468, which is also upstream's
      // maxWidth. A search box fills the width it is given.
      home: Center(child: SizedBox(width: 468, child: searchBox)),
    ),
  );

  Iterable<BoxDecoration> decorationsOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>();

  /// The search box's own surface: the only box carrying the full corner
  /// radius.
  BoxDecoration surfaceOf(WidgetTester tester) => decorationsOf(
    tester,
  ).firstWhere((d) => d.borderRadius == FluentRadius.allMedium);

  /// The 2px focus underline.
  ///
  /// Scoped to [FluentInputFocusUnderline] rather than picked out by its
  /// bottom-only radius: the 1px resting rule carries the same radius now, so
  /// shape alone no longer tells them apart.
  BoxDecoration underlineOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(FluentInputFocusUnderline),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  /// How far the focus underline has scaled: 0 hidden, 1 fully across.
  double underlineScaleOf(WidgetTester tester) => tester
      .widget<Transform>(
        find.descendant(of: find.byKey(key), matching: find.byType(Transform)),
      )
      .transform
      .storage[0];

  /// The 1px bottom rule Figma draws as its own rectangle. Null when the
  /// appearance paints none.
  ///
  /// It is a [FluentInputUnderline] rather than a bare `ColoredBox` so that its
  /// ends follow the field's corner radius — see that widget for why a 1px rule
  /// cannot simply carry a 4px radius.
  Color? bottomRuleOf(WidgetTester tester) {
    // Both rules are a FluentInputUnderline now — the resting one directly,
    // the accent inside FluentInputFocusUnderline — so pick by thickness
    // rather than by order. The resting rule is the 1px one.
    final rules = tester
        .widgetList<FluentInputUnderline>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(FluentInputUnderline),
          ),
        )
        .where((r) => r.thickness == FluentStroke.thin);
    return rules.isEmpty ? null : rules.first.color;
  }

  Widget box({
    FluentSearchBoxAppearance appearance = FluentSearchBoxAppearance.outline,
    FluentSearchBoxSize size = FluentSearchBoxSize.medium,
    bool enabled = true,
    TextEditingController? controller,
    FocusNode? focusNode,
    FluentSearchBoxStyle? style,
    String? placeholder = 'Search',
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
  }) => FluentSearchBox(
    key: key,
    appearance: appearance,
    size: size,
    enabled: enabled,
    controller: controller,
    focusNode: focusNode,
    style: style,
    placeholder: placeholder,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    onClear: onClear,
  );

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('search_box');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 36);
      expect(spec.properties['Style'], appearanceNames.values.toList());
      expect(spec.properties['Size'], <String>['Small', 'Medium', 'Large']);
      expect(spec.properties['State'], <String>['Rest', 'Focus', 'Hover']);
    });

    testWidgets('geometry and type ramp match every size', (tester) async {
      for (final entry in sizeNames.entries) {
        final variant = spec.variant({
          'Style': 'Outline',
          'Size': entry.value,
          'State': 'Rest',
        });
        // Figma states the inset on the `Contents` frame, not on the variant
        // frame — which carries no auto-layout at all.
        final contents = variant.part('Contents');

        await pump(tester, box(size: entry.key));

        final padding = tester
            .widgetList<Padding>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Padding),
              ),
            )
            .first
            .padding
            .resolve(TextDirection.ltr);

        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: '${entry.value}: height',
        );
        expect(
          padding.left,
          contents.padding!.left,
          reason: '${entry.value}: padding.left',
        );
        expect(
          padding.right,
          contents.padding!.right,
          reason: '${entry.value}: padding.right',
        );
        expect(
          surfaceOf(tester).borderRadius,
          variant.radius,
          reason: '${entry.value}: radius',
        );

        final text = tester
            .widget<RichText>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style!;
        expect(
          text.fontSize,
          variant.text!.fontSize,
          reason: '${entry.value}: fontSize',
        );
        expect(
          text.height! * text.fontSize!,
          variant.text!.lineHeight,
          reason: '${entry.value}: lineHeight',
        );
      }
    });

    testWidgets('resting fill and border match every appearance', (
      tester,
    ) async {
      for (final entry in appearanceNames.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'Size': 'Medium',
          'State': 'Rest',
        });
        final contents = variant.part('Contents');

        await pump(tester, box(appearance: entry.key));
        await tester.pumpAndSettle();

        final surface = surfaceOf(tester);
        final expected = contents.fill;
        if (expected == null) {
          // Transparent is the only appearance Figma leaves unpainted. Upstream
          // still sets `colorTransparentBackground` there, and so do we — the
          // observable claim is that nothing shows.
          expect(surface.color!.a, 0, reason: '${entry.value}: fill alpha');
        } else {
          expect(surface.color, expected, reason: '${entry.value}: fill');
        }

        final stroke = contents.stroke;
        if (stroke == null) {
          // Filled: Figma paints no stroke, we keep a transparent-token one so
          // high contrast still outlines the box. Transparent: no border at all.
          if (entry.key == FluentSearchBoxAppearance.transparent) {
            expect(surface.border, isNull, reason: '${entry.value}: border');
          } else {
            expect(
              surface.border!.top.color.a,
              0,
              reason: '${entry.value}: transparent border alpha',
            );
          }
        } else {
          expect(
            surface.border!.top.color,
            stroke,
            reason: '${entry.value}: border',
          );
          expect(surface.border!.top.width, contents.strokeWidth);
        }
      }
    });

    testWidgets('the bottom rule matches Figma on rest and on hover', (
      tester,
    ) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      // Only Outline and Transparent draw the `Thin underline` rectangle.
      for (final appearance in <FluentSearchBoxAppearance>[
        FluentSearchBoxAppearance.outline,
        FluentSearchBoxAppearance.transparent,
      ]) {
        final rest = spec.variant({
          'Style': appearanceNames[appearance]!,
          'Size': 'Medium',
          'State': 'Rest',
        });
        await pump(tester, box(appearance: appearance));
        expect(
          bottomRuleOf(tester),
          rest.part('Thin underline').fill,
          reason: '${appearanceNames[appearance]}: rest rule',
        );

        await mouse.moveTo(tester.getCenter(find.byKey(key)));
        await tester.pumpAndSettle();

        // Figma's Outline hover rule is `Neutral/Stroke/Accessible/Hover`; its
        // Transparent hover twin was never switched off Rest, so the Outline
        // variant is the one that states the intent for both.
        expect(
          bottomRuleOf(tester),
          spec
              .variant({'Style': 'Outline', 'Size': 'Medium', 'State': 'Hover'})
              .part('Thin underline')
              .fill,
          reason: '${appearanceNames[appearance]}: hover rule',
        );
        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('filled appearances draw no bottom rule', (tester) async {
      for (final appearance in <FluentSearchBoxAppearance>[
        FluentSearchBoxAppearance.filledDarker,
        FluentSearchBoxAppearance.filledLighter,
      ]) {
        final variant = spec.variant({
          'Style': appearanceNames[appearance]!,
          'Size': 'Medium',
          'State': 'Rest',
        });
        expect(
          variant.parts.where((p) => p.name == 'Thin underline'),
          isEmpty,
          reason: 'the fixture should have no rule to reproduce',
        );
        await pump(tester, box(appearance: appearance));
        expect(bottomRuleOf(tester), isNull);
      }
    });

    testWidgets('the focus underline matches the InFocus rectangle', (
      tester,
    ) async {
      final variant = spec.variant({
        'Style': 'Outline',
        'Size': 'Medium',
        'State': 'Focus',
      });
      final inFocus = variant.part('InFocus');

      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, box(focusNode: node));
      node.requestFocus();
      await tester.pumpAndSettle();

      expect(underlineOf(tester).color, inFocus.fill);
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Transform),
              ),
            )
            .height,
        inFocus.size.height,
        reason: 'the focus bar is 2 tall',
      );
      expect(underlineOf(tester).borderRadius, inFocus.radius);
    });

    testWidgets('focus keeps the resting border, as all 12 Figma Focus '
        'variants do', (tester) async {
      final focusVariant = spec.variant({
        'Style': 'Outline',
        'Size': 'Medium',
        'State': 'Focus',
      });
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, box(focusNode: node));
      node.requestFocus();
      await tester.pumpAndSettle();

      // React's `:focus-within` selects colorNeutralStroke1Pressed here.
      expect(
        surfaceOf(tester).border!.top.color,
        focusVariant.part('Contents').stroke,
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(surfaceOf(tester).border!.top.color, theme.colors.neutralStroke1);
    });
  });

  group('motion', () {
    testWidgets('the underline scales in over 200ms and out over 50ms', (
      tester,
    ) async {
      // useInputStyles.styles.ts: ::after transform scaleX, durationNormal in,
      // durationUltraFast out. It is the only transition either the SearchBox
      // or the Input styles file declares.
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, box(focusNode: node));
      await tester.pumpAndSettle();
      expect(underlineScaleOf(tester), 0, reason: 'hidden at rest');

      node.requestFocus();
      // Two pumps: the first applies the focus change, the second is the first
      // frame built with it — which is where the tween starts.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final midway = underlineScaleOf(tester);
      expect(midway, greaterThan(0), reason: 'must be mid-tween, not instant');
      expect(midway, lessThan(1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(underlineScaleOf(tester), 1);

      node.unfocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 25));
      expect(
        underlineScaleOf(tester),
        greaterThan(0),
        reason: 'the exit is four times faster, but still a tween',
      );
      await tester.pump(const Duration(milliseconds: 25));
      expect(underlineScaleOf(tester), 0);
    });

    testWidgets('reduced motion lands the underline immediately', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, box(focusNode: node), reducedMotion: true);
      await tester.pumpAndSettle();

      node.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(underlineScaleOf(tester), 1);
    });

    testWidgets('the surface never animates', (tester) async {
      // Neither styles file transitions background, border or colour — the
      // hover rule changes on the frame the pointer arrives.
      await pump(tester, box());
      await tester.pumpAndSettle();
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();

      expect(
        surfaceOf(tester).border!.top.color,
        theme.colors.neutralStroke1Hover,
      );
      expect(bottomRuleOf(tester), theme.colors.neutralStrokeAccessibleHover);
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
        FluentSearchBoxTheme(
          style: FluentSearchBoxStyle.from(backgroundColor: themed),
          child: box(
            style: FluentSearchBoxStyle.from(backgroundColor: explicit),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentSearchBoxTheme(
          style: FluentSearchBoxStyle.from(backgroundColor: themed),
          child: box(),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        box(
          appearance: FluentSearchBoxAppearance.filledDarker,
          style: FluentSearchBoxStyle.from(gap: 40),
        ),
      );
      await tester.pumpAndSettle();
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(
        surfaceOf(tester).color,
        theme.colors.neutralBackground3,
        reason: 'overriding the gap must not drop the fill',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentSearchBoxBaseState(
        enabled: true,
        focused: false,
        field: SizedBox(height: 20),
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSearchBox(
            base,
            FluentSearchBoxStyle.from(
              backgroundColor: mine,
              borderRadius: FluentRadius.allMedium,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, mine);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentSearchBoxState(
        field: const SizedBox(height: 20),
        appearance: FluentSearchBoxAppearance.filledDarker,
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentSearchBoxStyle(state, theme).merge(
        FluentSearchBoxStyle.from(borderRadius: FluentRadius.allCircular),
      );

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSearchBox(state, adjusted, const <WidgetState>{}),
        ),
      );
      await tester.pumpAndSettle();
      final surface = decorationsOf(tester).first;
      expect(surface.color, theme.colors.neutralBackground3);
      expect(surface.borderRadius, FluentRadius.allCircular);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the search box', (
      tester,
    ) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.neutralBackground3: magenta},
            child: Center(
              child: SizedBox(
                width: 468,
                child: box(appearance: FluentSearchBoxAppearance.filledDarker),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, magenta);
    });

    testWidgets('high contrast leaves no invisible border on any appearance', (
      tester,
    ) async {
      for (final appearance in FluentSearchBoxAppearance.values) {
        await pump(
          tester,
          box(appearance: appearance),
          theme: FluentThemeData.highContrast(
            fontPlatform: FluentFontPlatform.web,
          ),
        );
        await tester.pumpAndSettle();

        if (appearance == FluentSearchBoxAppearance.transparent) {
          // No border by design; the bottom rule is the whole component, and it
          // must still be opaque.
          expect(
            bottomRuleOf(tester)!.a,
            1.0,
            reason: '${appearance.name} rule',
          );
        } else {
          // transparentStroke resolves to an opaque highlight in high contrast,
          // which is the only thing outlining a filled search box there.
          expect(
            surfaceOf(tester).border!.top.color.a,
            1.0,
            reason: '${appearance.name} border',
          );
        }
      }
    });
  });

  group('behaviour', () {
    testWidgets('typing reports every edit and Enter submits', (tester) async {
      final changes = <String>[];
      final submitted = <String>[];
      final node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        box(
          focusNode: node,
          onChanged: changes.add,
          onSubmitted: submitted.add,
        ),
      );
      node.requestFocus();
      await tester.pump();

      await tester.enterText(find.byType(EditableText), 'fluent');
      await tester.pump();
      expect(changes, <String>['fluent']);

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(submitted, <String>['fluent']);
    });

    testWidgets('the placeholder shows only while the value is empty', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(tester, box(controller: controller));

      expect(find.text('Search'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pump();
      expect(find.text('Search'), findsNothing);
    });

    testWidgets('the clear button appears with focus, clears, and gives focus '
        'back', (tester) async {
      final controller = TextEditingController(text: 'fluent');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);
      var cleared = 0;

      await pump(
        tester,
        box(controller: controller, focusNode: node, onClear: () => cleared++),
      );

      // Both sources gate the clear affordance on focus, not on the value:
      // upstream collapses `contentAfter` whenever `!focused`, and Figma hides
      // `Icon after container` on every Rest and Hover variant.
      expect(find.bySemanticsLabel('Clear'), findsNothing);

      node.requestFocus();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Clear'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(cleared, 1);
      expect(node.hasFocus, isTrue, reason: 'focus returns to the field');
    });

    testWidgets('Escape clears the field', (tester) async {
      final controller = TextEditingController(text: 'fluent');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);

      await pump(tester, box(controller: controller, focusNode: node));
      node.requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(controller.text, isEmpty);
    });

    testWidgets('the clear button stays out of the tab order', (tester) async {
      // Upstream gives the dismiss slot `tabIndex: -1`; Escape is the keyboard
      // path, not a second tab stop between the field and whatever follows it.
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, box(focusNode: node));
      node.requestFocus();
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FluentInteractive>(find.byType(FluentInteractive))
            .focusNode!
            .skipTraversal,
        isTrue,
      );
    });

    testWidgets('disabled is a real state', (tester) async {
      final controller = TextEditingController(text: 'fluent');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);

      await pump(
        tester,
        box(
          enabled: false,
          controller: controller,
          focusNode: node,
          appearance: FluentSearchBoxAppearance.outline,
        ),
      );
      await tester.pumpAndSettle();
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

      // The disabled ramp replaces the enabled one wholesale rather than
      // dimming it — useInputStyles.styles.ts `disabled`.
      expect(surfaceOf(tester).color!.a, 0, reason: 'transparent fill');
      expect(
        surfaceOf(tester).border!.top.color,
        theme.colors.neutralStrokeDisabled,
      );
      expect(bottomRuleOf(tester), isNull, reason: 'no accessible rule');
      expect(find.bySemanticsLabel('Clear'), findsNothing);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );

      // A disabled box must not adopt the hover ramp either.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(
        surfaceOf(tester).border!.top.color,
        theme.colors.neutralStrokeDisabled,
      );
    });

    testWidgets('the disabled focus underline never shows', (tester) async {
      // `disabled` sets `::after { content: unset }` upstream — the bar is gone,
      // not merely unscaled.
      await pump(tester, box(enabled: false));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Transform)),
        findsNothing,
      );
    });

    testWidgets('it announces itself as a named text field', (tester) async {
      await pump(
        tester,
        const FluentSearchBox(
          key: key,
          semanticLabel: 'Search files',
          placeholder: 'Search',
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        isSemantics(label: 'Search files', isTextField: true, isEnabled: true),
      );
    });
  });

  testWidgets('the bordered box fills the control height at every size', (
    tester,
  ) async {
    const heights = <FluentSearchBoxSize, double>{
      FluentSearchBoxSize.small: 24,
      FluentSearchBoxSize.medium: 32,
      FluentSearchBoxSize.large: 40,
    };

    for (final entry in heights.entries) {
      await tester.pumpWidget(
        FluentApp(
          home: Center(
            child: SizedBox(
              width: 300,
              child: FluentSearchBox(key: const Key('sb'), size: entry.key),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.getRect(
        find
            .descendant(
              of: find.byKey(const Key('sb')),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        box.height,
        entry.value,
        reason: '${entry.key.name}: the decorated surface must fill the slot',
      );
      // The rule sits ON the box's bottom edge, not below it.
      final rule = tester.getRect(
        find
            .descendant(
              of: find.byKey(const Key('sb')),
              matching: find.byType(FluentInputUnderline),
            )
            .first,
      );
      expect(
        rule.bottom,
        box.bottom,
        reason: '${entry.key.name}: the underline must not detach',
      );
    }
  });
  // One shape, one implementation: the focus bar is `FluentInputFocusUnderline`
  // (input.dart), which is where the `max(thickness, radius)` + clip trick that
  // keeps a 4px corner on a 2px bar lives.
  testWidgets('the focus bar comes from the shared primitive', (tester) async {
    await tester.pumpWidget(
      const FluentApp(
        home: Center(
          child: SizedBox(
            width: 300,
            child: FluentSearchBox(key: Key('sb-primitive')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('sb-primitive')),
        matching: find.byType(FluentInputFocusUnderline),
      ),
      findsOneWidget,
      reason: 'one shape, one implementation — see input.dart',
    );
  });
}
