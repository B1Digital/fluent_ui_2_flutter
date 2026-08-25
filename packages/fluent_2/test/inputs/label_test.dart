import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentLabel` is the type ramp made concrete: six size/weight pairs, one
/// colour token, and a required-field asterisk. It is non-interactive, so the
/// interesting contract is that **disabled is a real state resolved from a
/// token** rather than an opacity applied over the enabled rendering.
void main() {
  const key = Key('label');

  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget label, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light,
      home: Center(child: label),
    ),
  );

  /// Every painted text style under the label, outermost first: the label
  /// itself, then the required asterisk. Read off [RichText] because that is
  /// where the ambient `DefaultTextStyle` has already been merged in.
  List<TextStyle> stylesOf(WidgetTester tester) => tester
      .widgetList<RichText>(
        find.descendant(of: find.byKey(key), matching: find.byType(RichText)),
      )
      .map((r) => r.text.style!)
      .toList();

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('label');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 10);
    });

    test('Figma ships no Large + Regular variant', () {
      // 2 types x 3 sizes x 2 disabled would be 12; the set has 10. Large
      // exists only as Semibold. FluentLabelSize.large with the default weight
      // is therefore an extrapolation of the ramp (16/22 regular = body2), not
      // something the design file states — which is exactly why it is called
      // out here rather than quietly asserted against a variant that is not
      // there.
      expect(spec.where({'Size': 'Large', 'Type': 'Regular'}), isEmpty);
    });

    testWidgets('every variant matches its type ramp step and colour', (
      tester,
    ) async {
      for (final variant in spec.variants) {
        final size = switch (variant.props['Size']) {
          'Small' => FluentLabelSize.small,
          'Medium' => FluentLabelSize.medium,
          'Large' => FluentLabelSize.large,
          final other => fail('unmapped Size $other'),
        };
        final weight = switch (variant.props['Type']) {
          'Regular' => FluentLabelWeight.regular,
          'Semibold' => FluentLabelWeight.semibold,
          final other => fail('unmapped Type $other'),
        };
        final disabled = variant.props['Disabled'] == 'On';

        await pump(
          tester,
          FluentLabel(
            key: key,
            size: size,
            weight: weight,
            disabled: disabled,
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
        expect(style.fontWeight, switch (text.tokens['fontStyle']!.single) {
          'Typography/Weight/Regular' => FluentFontWeight.regular,
          'Typography/Weight/Semibold' => FluentFontWeight.semibold,
          final other => fail('unmapped weight token $other'),
        }, reason: '${variant.name}: weight');
        // The colour is selected from the token the fixture names, never
        // reverse-engineered from the hex it resolved to.
        expect(
          style.color,
          switch (text.tokens['fills']!.single) {
            'Neutral/Foreground/1/Rest' => light.colors.neutralForeground1,
            'Neutral/Foreground/Disabled/Rest' =>
              light.colors.neutralForegroundDisabled,
            final other => fail('unmapped fill token $other'),
          },
          reason: '${variant.name}: fill (${text.tokens['fills']!.single})',
        );
        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: '${variant.name}: height',
        );
      }
    });

    testWidgets(
      'the required asterisk is the danger token, XS from the label',
      (tester) async {
        final variant = spec.variant(const {
          'Type': 'Regular',
          'Size': 'Medium',
          'Disabled': 'Off',
        });

        await pump(
          tester,
          const FluentLabel(key: key, required: true, child: Text('Label')),
        );

        final styles = stylesOf(tester);
        expect(styles, hasLength(2), reason: 'label plus asterisk');
        // Figma: the hidden `Required asterisk` layer binds fills to
        // Status/Danger/Foreground/3/Rest, and shares the label's size, line
        // height and weight.
        expect(styles[1].color, light.colors.statusDangerForeground3);
        expect(styles[1].fontSize, variant.text!.fontSize);
        expect(styles[1].fontWeight, styles.first.fontWeight);

        final row = tester.widget<Row>(
          find.descendant(of: find.byKey(key), matching: find.byType(Row)),
        );
        expect(row.spacing, variant.gap, reason: 'Spacing/Horizontal/XS');
        expect(find.text('*'), findsOneWidget);
      },
    );

    testWidgets('no asterisk unless required', (tester) async {
      await pump(tester, const FluentLabel(key: key, child: Text('Label')));
      expect(find.text('*'), findsNothing);
      expect(stylesOf(tester), hasLength(1));
    });
  });

  group('motion', () {
    testWidgets('disabling is instant — Label has no transition', (
      tester,
    ) async {
      // Neither Figma nor upstream's useLabelStyles declares a transition on
      // Label, so the colour swaps on the frame the state changes. There is
      // deliberately no FluentAnimatedStyle here to shorten under reduced
      // motion — there is nothing to shorten.
      await pump(tester, const FluentLabel(key: key, child: Text('Label')));
      expect(stylesOf(tester).first.color, light.colors.neutralForeground1);

      await pump(
        tester,
        const FluentLabel(key: key, disabled: true, child: Text('Label')),
      );
      // One frame, no settle.
      expect(
        stylesOf(tester).first.color,
        light.colors.neutralForegroundDisabled,
        reason: 'must be instant, not mid-tween',
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
        FluentLabelTheme(
          style: FluentLabelStyle.from(foregroundColor: themed),
          child: FluentLabel(
            key: key,
            style: FluentLabelStyle.from(foregroundColor: explicit),
            child: const Text('Label'),
          ),
        ),
      );
      expect(stylesOf(tester).first.color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentLabelTheme(
          style: FluentLabelStyle.from(foregroundColor: themed),
          child: const FluentLabel(key: key, child: Text('Label')),
        ),
      );
      expect(stylesOf(tester).first.color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentLabel(
          key: key,
          size: FluentLabelSize.large,
          weight: FluentLabelWeight.semibold,
          style: FluentLabelStyle.from(gap: 20),
          required: true,
          child: const Text('Label'),
        ),
      );
      final row = tester.widget<Row>(
        find.descendant(of: find.byKey(key), matching: find.byType(Row)),
      );
      expect(row.spacing, 20);
      expect(
        stylesOf(tester).first.fontSize,
        16,
        reason: 'overriding the gap must not drop the Large ramp step',
      );
      expect(
        stylesOf(tester).last.color,
        light.colors.statusDangerForeground3,
        reason: 'overriding the gap must not drop the asterisk colour',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentLabelBaseState(
        enabled: true,
        required: true,
        label: Text('Label'),
      );
      const mine = Color(0xFF00FF00);
      const asterisk = Color(0xFF0000FF);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentLabel(
            base,
            const FluentLabelStyle(
              foregroundColor: WidgetStatePropertyAll<Color?>(mine),
              requiredColor: WidgetStatePropertyAll<Color?>(asterisk),
              textStyle: WidgetStatePropertyAll<TextStyle?>(
                TextStyle(fontSize: 30, height: 40 / 30),
              ),
            ),
            const <WidgetState>{},
          ),
        ),
      );
      final styles = stylesOf(tester);
      expect(styles.first.color, mine);
      expect(styles.first.fontSize, 30);
      expect(styles.last.color, asterisk);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentLabelState(
        size: FluentLabelSize.small,
        weight: FluentLabelWeight.semibold,
        label: const Text('Label'),
      );
      final adjusted = resolveFluentLabelStyle(
        state,
        light,
      ).merge(FluentLabelStyle.from(foregroundColor: const Color(0xFF00FF00)));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentLabel(state, adjusted, const <WidgetState>{}),
        ),
      );
      final style = stylesOf(tester).first;
      expect(style.color, const Color(0xFF00FF00));
      expect(style.fontSize, 12);
      expect(style.fontWeight, FluentFontWeight.semibold);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the label', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light,
          home: const FluentThemeOverride(
            colors: {FluentColorToken.neutralForeground1: magenta},
            child: Center(
              child: FluentLabel(key: key, child: Text('Label')),
            ),
          ),
        ),
      );
      expect(stylesOf(tester).first.color, magenta);
    });

    testWidgets('high contrast paints nothing invisible', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final disabled in [false, true]) {
        await pump(
          tester,
          FluentLabel(
            key: key,
            disabled: disabled,
            required: true,
            child: const Text('Label'),
          ),
          theme: theme,
        );
        for (final style in stylesOf(tester)) {
          // No border to vanish here, but a foreground resolved from anything
          // other than a token could easily land transparent — assert every
          // painted colour is fully opaque under the high contrast tables.
          expect(style.color!.a, 1.0, reason: 'disabled: $disabled');
        }
        expect(
          stylesOf(tester).first.color,
          disabled
              ? theme.colors.neutralForegroundDisabled
              : theme.colors.neutralForeground1,
        );
      }
    });
  });

  group('behaviour', () {
    testWidgets('disabled is a state, not an opacity', (tester) async {
      await pump(
        tester,
        const FluentLabel(key: key, disabled: true, child: Text('Label')),
      );
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Opacity)),
        findsNothing,
        reason:
            'Fluent ships a Disabled token; fading the enabled colour '
            'would be a different colour on every background',
      );
      expect(
        stylesOf(tester).first.color,
        light.colors.neutralForegroundDisabled,
      );
    });

    testWidgets('the asterisk greys with the label when disabled', (
      tester,
    ) async {
      // Figma: the Disabled=On variants bind the asterisk's fill to
      // Neutral/Foreground/Disabled/Rest, not to the danger token. React keeps
      // it red. Figma wins — see doc/token-divergences.md.
      await pump(
        tester,
        const FluentLabel(
          key: key,
          disabled: true,
          required: true,
          child: Text('Label'),
        ),
      );
      expect(
        stylesOf(tester).last.color,
        light.colors.neutralForegroundDisabled,
      );
    });
  });
}
