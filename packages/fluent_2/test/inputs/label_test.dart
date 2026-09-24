import 'dart:math' as math;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/rendering.dart';
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
        expect(style.color, switch (text.tokens['fills']!.single) {
          'Neutral/Foreground/1/Rest' => light.colors.neutralForeground1,
          'Neutral/Foreground/Disabled/Rest' =>
            light.colors.neutralForegroundDisabled,
          final other => fail('unmapped fill token $other'),
        }, reason: '${variant.name}: fill (${text.tokens['fills']!.single})');
        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: '${variant.name}: height',
        );
      }
    });

    testWidgets('the required asterisk shares the ramp, XS from the label', (
      tester,
    ) async {
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
      // Figma: the hidden `Required asterisk` layer shares the label's
      // size, line height and weight. Its fill, Status/Danger/Foreground/3,
      // loses to the colorPaletteRedForeground3 Chrome paints — see the
      // upstream group.
      expect(styles[1].fontSize, variant.text!.fontSize);
      expect(styles[1].fontWeight, styles.first.fontWeight);

      expect(
        tester.getTopLeft(find.text('*')).dx -
            tester.getTopRight(find.text('Label')).dx,
        variant.gap,
        reason: 'Spacing/Horizontal/XS',
      );
      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('no asterisk unless required', (tester) async {
      await pump(tester, const FluentLabel(key: key, child: Text('Label')));
      expect(find.text('*'), findsNothing);
      expect(stylesOf(tester), hasLength(1));
    });
  });

  group('upstream in Chrome', () {
    // components-label--required and components-field--required on
    // storybooks.fluentui.dev, read in Chrome with the label's text swapped
    // for a long one and its host narrowed to 250px. `<label>` is inline flow:
    // the text wraps at the host's width, and the `*` span (paddingLeft
    // spacingHorizontalXS) sits 4px after the END of the last line, on that
    // line — not beside the paragraph's box.
    const long =
        'Type a time outside of 10:00 to 19:59, type an invalid time, or '
        'leave the input empty and close the TimePicker.';

    Future<void> pumpAt(WidgetTester tester, double width, Widget label) =>
        tester.pumpWidget(
          FluentApp(
            theme: light,
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: label),
            ),
          ),
        );

    /// The last glyph of [text]'s paragraph, in global coordinates.
    Rect lastGlyph(WidgetTester tester, String text) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      );
      final box = paragraph
          .getBoxesForSelection(
            TextSelection(
              baseOffset: text.length - 1,
              extentOffset: text.length,
            ),
          )
          .last
          .toRect();
      return box.shift(paragraph.localToGlobal(Offset.zero));
    }

    testWidgets('a long label wraps at its width', (tester) async {
      for (final required in [false, true]) {
        await pumpAt(
          tester,
          250,
          FluentLabel(key: key, required: required, child: const Text(long)),
        );
        final size = tester.getSize(find.byKey(key));
        expect(
          size.width,
          lessThanOrEqualTo(250),
          reason: 'required=$required',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(3 * 20),
          reason: 'required=$required: 14/20 lines, wrapped rather than cut',
        );
      }
    });

    testWidgets('the asterisk ends the last line, 4px after its last glyph', (
      tester,
    ) async {
      for (final (width, text) in [(400.0, 'Required field'), (250.0, long)]) {
        await pumpAt(
          tester,
          width,
          FluentLabel(key: key, required: true, child: Text(text)),
        );
        final end = lastGlyph(tester, text);
        final star = lastGlyph(tester, '*');
        expect(star.left, moreOrLessEquals(end.right + 4), reason: text);
        expect(
          star.top,
          moreOrLessEquals(end.top),
          reason: '$text: on the last line, sharing its baseline',
        );
        expect(
          tester.getRect(find.text('*')).bottom,
          tester.getRect(find.byKey(key)).bottom,
          reason: '$text: the asterisk adds no line of its own',
        );
      }
    });

    testWidgets('right to left, the asterisk ends the line on its left', (
      tester,
    ) async {
      // components-label--required under the storybook's RTL global: the
      // span flips to paddingRight 4 and sits left of the line, whether the
      // text is Latin or Hebrew.
      for (final (width, text) in [(null, 'Label'), (250.0, long)]) {
        await tester.pumpWidget(
          FluentApp(
            theme: light,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: width,
                  child: FluentLabel(
                    key: key,
                    required: true,
                    child: Text(text),
                  ),
                ),
              ),
            ),
          ),
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.text(text), matching: find.byType(RichText)),
        );
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: text.length),
        );
        final lastTop = boxes.map((b) => b.top).reduce(math.max);
        final lineLeft = paragraph.localToGlobal(
          Offset(
            boxes
                .where((b) => b.top == lastTop)
                .map((b) => b.left)
                .reduce(math.min),
            lastTop,
          ),
        );
        final star = lastGlyph(tester, '*');
        expect(star.right, moreOrLessEquals(lineLeft.dx - 4), reason: text);
        expect(star.top, moreOrLessEquals(lineLeft.dy), reason: text);
        if (width == null) {
          expect(
            tester.getRect(find.byKey(key)).left,
            moreOrLessEquals(tester.getRect(find.text('*')).left),
            reason: 'a loose label makes room on its left, spilling nothing',
          );
        }
      }
    });

    testWidgets('a last line with no room left sends the asterisk down', (
      tester,
    ) async {
      // ponytail: CSS would carry the last word down with it; the port moves
      // the asterisk alone. Pinned so the fallback stays on the label's box.
      await pump(tester, const FluentLabel(key: key, child: Text('A')));
      final width = tester.getSize(find.byKey(key)).width;
      await pumpAt(
        tester,
        width,
        const FluentLabel(key: key, required: true, child: Text('A')),
      );
      final label = tester.getRect(find.byKey(key));
      expect(
        tester.getTopLeft(find.text('*')),
        label.topLeft + const Offset(0, 20),
      );
      expect(label.size, Size(width, 40));
    });

    testWidgets('the asterisk is colorPaletteRedForeground3', (tester) async {
      // getComputedStyle(.fui-Label__required).color: web-light #d13438,
      // web-dark #e37d80, teams-high-contrast #ffffff.
      final dark = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
      final hc = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final (theme, expected) in [
        (light, const Color(0xFFD13438)),
        (dark, const Color(0xFFE37D80)),
        (hc, const Color(0xFFFFFFFF)),
      ]) {
        await pump(
          tester,
          const FluentLabel(key: key, required: true, child: Text('Label')),
          theme: theme,
        );
        expect(stylesOf(tester).last.color, expected);
      }
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
      expect(
        tester.getTopLeft(find.text('*')).dx -
            tester.getTopRight(find.text('Label')).dx,
        20,
      );
      expect(
        stylesOf(tester).first.fontSize,
        16,
        reason: 'overriding the gap must not drop the Large ramp step',
      );
      expect(
        stylesOf(tester).last.color,
        const Color(0xFFD13438),
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
      // Neutral/Foreground/Disabled/Rest, not to the danger token — and so does
      // upstream's useLabelStyles, which applies `styles.disabled` to the
      // required slot too.
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

    testWidgets('toggling required keeps the label child and its state', (
      tester,
    ) async {
      // The asterisk comes and goes beside the caller's widget; the widget
      // itself must not be torn down and rebuilt with fresh state.
      Future<State> pumpRequired({required bool required}) async {
        await pump(
          tester,
          FluentLabel(key: key, required: required, child: const _Stateful()),
        );
        return tester.state(find.byType(_Stateful));
      }

      final before = await pumpRequired(required: false);
      expect(await pumpRequired(required: true), same(before));
      expect(find.text('*'), findsOneWidget);
      expect(await pumpRequired(required: false), same(before));
      expect(find.text('*'), findsNothing);
    });
  });
}

class _Stateful extends StatefulWidget {
  const _Stateful();

  @override
  State<_Stateful> createState() => _StatefulState();
}

class _StatefulState extends State<_Stateful> {
  @override
  Widget build(BuildContext context) => const Text('Label');
}
