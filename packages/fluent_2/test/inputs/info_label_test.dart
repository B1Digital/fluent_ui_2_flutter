import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentInfoLabel` is a composition — a `FluentLabel` beside a
/// `FluentInfoButton` — so these tests cover the seam rather than re-testing
/// either part: that the two slots are wired to one `size`, that `disabled`
/// reaches both, that a single `style` argument reaches both, and that the
/// trigger is allowed to set the row's height the way Figma draws it.
void main() {
  const key = Key('info-label');
  const tipKey = Key('tip');

  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light,
      home: Center(child: child),
    ),
  );

  /// Every painted text style under the label, outermost first.
  List<TextStyle> stylesOf(WidgetTester tester) => tester
      .widgetList<RichText>(
        find.descendant(of: find.byKey(key), matching: find.byType(RichText)),
      )
      .map((r) => r.text.style!)
      .toList();

  /// The InfoLabel's own row. `FluentLabel` renders one of its own for the
  /// asterisk, and depth-first order puts the outer one first.
  Row rowOf(WidgetTester tester) => tester
      .widgetList<Row>(
        find.descendant(of: find.byKey(key), matching: find.byType(Row)),
      )
      .first;

  FluentLabelSize sizeFor(String name) => switch (name) {
    'Small' => FluentLabelSize.small,
    'Medium' => FluentLabelSize.medium,
    'Large' => FluentLabelSize.large,
    final other => fail('unmapped Size $other'),
  };

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('info_label');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 3);
      // One axis only: no State, no Disabled, no Required. Everything this
      // component does beyond the ramp is inherited from its two slots.
      expect(spec.properties.keys, <String>['Size']);
    });

    testWidgets('every variant matches its ramp, its trigger and its height', (
      tester,
    ) async {
      for (final variant in spec.variants) {
        final size = sizeFor(variant.props['Size']!);
        // The weight is the nested Label instance's own, not a rule about
        // InfoLabel: the Label set ships no Large + Regular pair, so Figma's
        // Large InfoLabel is necessarily semibold. Read it off the fixture
        // rather than hardcoding a table that would hide that.
        final weight = switch (variant.text!.tokens['fontStyle']!.single) {
          'Typography/Weight/Regular' => FluentLabelWeight.regular,
          'Typography/Weight/Semibold' => FluentLabelWeight.semibold,
          final other => fail('unmapped weight token $other'),
        };

        await pump(
          tester,
          FluentInfoLabel(
            key: key,
            size: size,
            weight: weight,
            infoSemanticLabel: 'More information',
            info: const Text('Info'),
            child: const Text('Label'),
          ),
        );

        final text = variant.text!;
        final style = stylesOf(tester).first;
        expect(style.fontSize, text.fontSize, reason: '${variant.name}: size');
        expect(
          style.height! * style.fontSize!,
          text.lineHeight,
          reason: '${variant.name}: line height',
        );
        expect(
          style.color,
          light.colors.neutralForeground1,
          reason: '${variant.name}: ${text.tokens['fills']!.single}',
        );

        // The trigger's box, read off the nested instance rather than the
        // variant frame: 20 at small, 24 at both medium and large.
        expect(
          tester.getSize(find.byType(FluentInfoButton)),
          variant.part('.Info button').size,
          reason: '${variant.name}: trigger box',
        );

        // Figma lets the trigger set the row height — 24 against a 20 line box
        // at medium. Upstream instead pulls it in with a negative margin so it
        // never grows the line. Figma wins.
        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: '${variant.name}: height',
        );

        expect(
          rowOf(tester).spacing,
          variant.gap,
          reason: '${variant.name}: itemSpacing is 0 at every size',
        );
        expect(
          variant.padding,
          EdgeInsets.zero,
          reason: '${variant.name}: the frame carries no inset of its own',
        );
      }
    });

    testWidgets('no info means no trigger, as upstream renders it', (
      tester,
    ) async {
      await pump(tester, const FluentInfoLabel(key: key, child: Text('Label')));
      expect(find.byType(FluentInfoButton), findsNothing);
      expect(rowOf(tester).spacing, FluentSpacing.none);
    });
  });

  group('motion', () {
    testWidgets('disabling is instant — neither set declares a transition', (
      tester,
    ) async {
      // Verified against useInfoLabelStyles.styles.ts and
      // useInfoButtonStyles.styles.ts on microsoft/fluentui@master: no
      // transition, no motionTokens, no duration, no curve. Nothing here is
      // waiting to be shortened under reduced motion.
      await pump(
        tester,
        const FluentInfoLabel(
          key: key,
          infoSemanticLabel: 'More information',
          info: Text('Info'),
          child: Text('Label'),
        ),
      );
      expect(stylesOf(tester).first.color, light.colors.neutralForeground1);

      await pump(
        tester,
        const FluentInfoLabel(
          key: key,
          disabled: true,
          infoSemanticLabel: 'More information',
          info: Text('Info'),
          child: Text('Label'),
        ),
      );
      // One frame, no settle.
      expect(
        stylesOf(tester).first.color,
        light.colors.neutralForegroundDisabled,
        reason: 'must be instant, not mid-tween',
      );
      expect(
        find.byType(FluentAnimatedStyle<Color>),
        findsNothing,
        reason: 'nothing in this component animates',
      );
    });
  });

  group('behaviour', () {
    testWidgets('the trigger opens the tip from the label', (tester) async {
      await pump(
        tester,
        const FluentInfoLabel(
          key: key,
          infoSemanticLabel: 'About the retention period',
          info: Text('Kept for 30 days', key: tipKey),
          child: Text('Retention'),
        ),
      );
      expect(find.byKey(tipKey), findsNothing);
      await tester.tap(find.byType(FluentInfoButton));
      await tester.pump();
      expect(find.byKey(tipKey), findsOneWidget);
    });

    testWidgets('the trigger is keyboard reachable and keyboard operable', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentInfoLabel(
          key: key,
          focusNode: node,
          infoSemanticLabel: 'About the retention period',
          info: const Text('Kept for 30 days', key: tipKey),
          child: const Text('Retention'),
        ),
      );

      node.requestFocus();
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byKey(tipKey), findsOneWidget);
    });

    testWidgets('disabled reaches both slots and is a real state', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentInfoLabel(
          key: key,
          disabled: true,
          required: true,
          infoSemanticLabel: 'About the retention period',
          info: Text('Kept for 30 days', key: tipKey),
          child: Text('Retention'),
        ),
      );

      for (final style in stylesOf(tester)) {
        expect(
          style.color,
          light.colors.neutralForegroundDisabled,
          reason: 'the asterisk greys with the label',
        );
      }
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Opacity)),
        findsNothing,
        reason: 'Fluent ships a Disabled token; fading would be a fake',
      );

      await tester.tap(find.byType(FluentInfoButton), warnIfMissed: false);
      await tester.pump();
      expect(find.byKey(tipKey), findsNothing);
      expect(
        tester.getSemantics(find.byType(FluentInfoButton)),
        matchesSemantics(
          label: 'About the retention period',
          isButton: true,
          hasEnabledState: true,
          hasExpandedState: true,
        ),
        reason: 'announced as a button that is present but not enabled',
      );
    });
  });

  group('style resolution order', () {
    testWidgets('the widget style beats the subtree theme beats the defaults', (
      tester,
    ) async {
      await pump(
        tester,
        FluentInfoLabelTheme(
          style: FluentInfoLabelStyle.from(gap: 4),
          child: FluentInfoLabel(
            key: key,
            style: FluentInfoLabelStyle.from(gap: 12),
            infoSemanticLabel: 'More information',
            info: const Text('Info'),
            child: const Text('Label'),
          ),
        ),
      );
      expect(rowOf(tester).spacing, 12);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      await pump(
        tester,
        FluentInfoLabelTheme(
          style: FluentInfoLabelStyle.from(gap: 4),
          child: const FluentInfoLabel(
            key: key,
            infoSemanticLabel: 'More information',
            info: Text('Info'),
            child: Text('Label'),
          ),
        ),
      );
      expect(rowOf(tester).spacing, 4);
    });

    testWidgets('one style argument reaches both slots', (tester) async {
      const labelColour = Color(0xFF00FF00);
      const glyphColour = Color(0xFF0000FF);
      await pump(
        tester,
        FluentInfoLabel(
          key: key,
          style: FluentInfoLabelStyle(
            labelStyle: FluentLabelStyle.from(foregroundColor: labelColour),
            infoButtonStyle: FluentInfoButtonStyle.from(
              foregroundColor: glyphColour,
            ),
          ),
          infoSemanticLabel: 'More information',
          info: const Text('Info'),
          child: const Text('Label'),
        ),
      );
      expect(stylesOf(tester).first.color, labelColour);
      expect(
        tester
            .widgetList<IconTheme>(
              find.descendant(
                of: find.byType(FluentInfoButton),
                matching: find.byType(IconTheme),
              ),
            )
            .first
            .data
            .color,
        glyphColour,
      );
      expect(
        tester.getSize(find.byType(FluentInfoButton)),
        const Size(24, 24),
        reason: 'a slot override must not drop the size defaults',
      );
    });

    testWidgets('nested styles merge per property rather than wholesale', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      const explicit = Color(0xFF222222);
      final merged =
          FluentInfoLabelStyle(
            labelStyle: FluentLabelStyle.from(foregroundColor: themed, gap: 9),
          ).merge(
            FluentInfoLabelStyle(
              labelStyle: FluentLabelStyle.from(foregroundColor: explicit),
            ),
          );
      expect(
        merged.labelStyle!.foregroundColor!.resolve(const <WidgetState>{}),
        explicit,
      );
      expect(
        merged.labelStyle!.gap!.resolve(const <WidgetState>{}),
        9,
        reason:
            'the lower rung keeps the properties the upper one is silent '
            'about',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentInfoLabelBaseState(
        enabled: true,
        label: Text('Label'),
        infoButton: SizedBox(width: 24, height: 24),
      );
      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentInfoLabel(
            base,
            FluentInfoLabelStyle.from(gap: 16),
            const <WidgetState>{},
          ),
        ),
      );
      expect(rowOf(tester).spacing, 16);
    });

    testWidgets('the state resolver maps the size across to the trigger', (
      tester,
    ) async {
      for (final size in FluentLabelSize.values) {
        expect(
          FluentInfoLabel.infoButtonSizeFor(size).name,
          size.name,
          reason: 'one Size axis drives both sets',
        );
      }
      final state = resolveFluentInfoLabelState(
        label: const Text('Label'),
        size: FluentLabelSize.large,
      );
      expect(state.size, FluentLabelSize.large);
      expect(state.enabled, isTrue);
      expect(state.infoButton, isNull);
      expect(
        resolveFluentInfoLabelStyle(
          state,
          light,
        ).gap!.resolve(const <WidgetState>{}),
        FluentSpacing.none,
      );
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches both slots', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light,
          home: const FluentThemeOverride(
            colors: {
              FluentColorToken.neutralForeground1: magenta,
              FluentColorToken.neutralForeground2: magenta,
            },
            child: Center(
              child: FluentInfoLabel(
                key: key,
                infoSemanticLabel: 'More information',
                info: Text('Info'),
                child: Text('Label'),
              ),
            ),
          ),
        ),
      );
      expect(stylesOf(tester).first.color, magenta);
      expect(
        tester
            .widgetList<IconTheme>(
              find.descendant(
                of: find.byType(FluentInfoButton),
                matching: find.byType(IconTheme),
              ),
            )
            .first
            .data
            .color,
        magenta,
      );
    });

    testWidgets('high contrast paints nothing invisible', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final disabled in <bool>[false, true]) {
        await pump(
          tester,
          FluentInfoLabel(
            key: key,
            disabled: disabled,
            required: true,
            infoSemanticLabel: 'More information',
            info: const Text('Info'),
            child: const Text('Label'),
          ),
          theme: theme,
        );
        for (final style in stylesOf(tester)) {
          expect(style.color!.a, 1.0, reason: 'disabled: $disabled');
        }
        expect(
          tester
              .widgetList<IconTheme>(
                find.descendant(
                  of: find.byType(FluentInfoButton),
                  matching: find.byType(IconTheme),
                ),
              )
              .first
              .data
              .color!
              .a,
          1.0,
          reason: 'disabled: $disabled',
        );
      }
    });
  });
}
