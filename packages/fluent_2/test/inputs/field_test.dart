import 'dart:ui' show PictureRecorder;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentField` is a wrapper, so almost none of its contract is about pixels
/// it paints itself — it paints none. What it owes is: the right type ramp on
/// three text rows, the right gap between them, upstream's glyph and tint per
/// validation state, and a semantics tree that reads as one field.
///
/// The Figma `Field` set (page `8911:3195`, set `9122:703`) has exactly one
/// axis, `Size`, and draws exactly one validation state, `error`. Everything
/// about `warning` and `success` therefore comes from
/// `useFieldStyles.styles.ts`, and every test that relies on it says so.
void main() {
  const key = Key('field');
  const childKey = Key('control');
  const glyphKey = Key('glyph');

  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  // Upstream's colorPalette{Red,DarkOrange,Green}Foreground1 and the label's
  // colorPaletteRedForeground3, as Chrome paints them under web-light.
  const red = Color(0xFFBC2F32);
  const darkOrange = Color(0xFFC43501);
  const green = Color(0xFF0E700E);
  const asteriskRed = Color(0xFFD13438);

  /// Figma's `Placeholder` slot: a 250x44 block standing in for the control.
  /// Using the same box the design file uses is what makes the row heights
  /// below comparable to the fixture at all.
  const child = SizedBox(key: childKey, height: 44);

  Future<void> pump(
    WidgetTester tester,
    Widget field, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light,
      home: Center(child: SizedBox(width: 250, child: field)),
    ),
  );

  /// Every painted text style under the field, in tree order: the label, the
  /// label's required asterisk, the validation message, then the hint. Read off
  /// [RichText] because that is where the ambient `DefaultTextStyle` has
  /// already been merged in — the value that reaches the rasteriser.
  List<TextStyle> stylesOf(WidgetTester tester) => tester
      .widgetList<RichText>(
        find.descendant(of: find.byKey(key), matching: find.byType(RichText)),
      )
      .map((r) => r.text.style!)
      .toList();

  /// The resolved [IconThemeData] wrapping the validation glyph.
  IconThemeData iconTheme(WidgetTester tester) =>
      IconTheme.of(tester.element(find.byKey(glyphKey)));

  /// The validation row proper — the one holding the glyph. Scoped through the
  /// glyph rather than by type, because a field with a label has a `Row` inside
  /// `FluentLabel` too.
  Finder validationRow() =>
      find.ancestor(of: find.byKey(glyphKey), matching: find.byType(Row)).first;

  /// The nearest [Padding] above [of] that belongs to the field.
  EdgeInsets paddingAbove(WidgetTester tester, Finder of) => tester
      .widget<Padding>(
        find
            .ancestor(
              of: of,
              matching: find.descendant(
                of: find.byKey(key),
                matching: find.byType(Padding),
              ),
            )
            .first,
      )
      .padding
      .resolve(TextDirection.ltr);

  final spec = loadSpec('field');

  // Figma names the same slot three different ways across the three variants —
  // the validation row is `Status text` at medium and ` Validation text`
  // (leading space and all) at small and large, and its text node is `Text` at
  // medium and `Error text` elsewhere. Look the parts up by what they *are*
  // rather than by a name that is not stable across the set.
  SpecPart labelRowOf(SpecVariant v) =>
      v.parts.firstWhere((p) => p.name == 'Label + Icon');
  SpecPart labelSlotOf(SpecVariant v) => v.part('Label');
  SpecPart labelTextOf(SpecVariant v) => v.parts.firstWhere(
    (p) => p.text?.tokens['fills']?.single == 'Neutral/Foreground/1/Rest',
  );
  SpecPart asteriskOf(SpecVariant v) => v.part('Required asterisk');
  SpecPart validationRowOf(SpecVariant v) => v.parts.firstWhere(
    (p) =>
        p.depth == 2 &&
        const {'Status text', 'Validation text'}.contains(p.name.trim()),
  );
  SpecPart validationTextOf(SpecVariant v) => v.parts.firstWhere(
    (p) =>
        p.depth == 3 &&
        p.text?.tokens['fills']?.single == 'Status/Danger/Foreground/1/Rest' &&
        p.text!.fontSize == 12,
  );
  SpecPart validationIconOf(SpecVariant v) => v.part('Icon');
  SpecPart hintRowOf(SpecVariant v) => v.part('Helper text');
  SpecPart hintTextOf(SpecVariant v) => v.parts.firstWhere(
    (p) => p.text?.tokens['fills']?.single == 'Neutral/Foreground/3/Rest',
  );

  FluentFieldSize sizeOf(SpecVariant v) => switch (v.props['Size']) {
    'Small' => FluentFieldSize.small,
    'Medium' => FluentFieldSize.medium,
    'Large' => FluentFieldSize.large,
    final other => fail('unmapped Size $other'),
  };

  /// The label-to-control gap Figma states for [v].
  ///
  /// Small is the one variant whose `Label + Icon` frame binds no variable at
  /// all, so it never reaches the fixture's `parts` — see the test that pins
  /// that. Its 2 is read off node `9122:717` directly.
  double labelGapOf(SpecVariant v) =>
      v.props['Size'] == 'Small' ? 2 : labelRowOf(v).padding!.bottom;

  /// The label's own inset, which Figma does not draw: upstream's
  /// `useFieldStyles.styles.ts` pads a vertical Field's label 2 above and 2
  /// below (1 and 1 at large) on top of the gap. Chrome, field--default and
  /// datepicker--default: the label box is 24 and the control starts 26 down.
  double labelInsetOf(SpecVariant v) => v.props['Size'] == 'Large' ? 1 : 2;

  group('pixel fidelity against Figma', () {
    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 3);
      expect(spec.properties.keys, ['Size']);
      expect(spec.properties['Size'], ['Medium', 'Small', 'Large']);
    });

    test('Figma ships no validation axis — only the error message', () {
      // Every variant draws one message bound to the danger family, and there
      // is no property to switch it. `warning` and `success` are upstream-only;
      // the tests for them say so.
      for (final variant in spec.variants) {
        expect(
          validationTextOf(variant).text!.tokens['fills']!.single,
          'Status/Danger/Foreground/1/Rest',
          reason: variant.name,
        );
      }
      expect(spec.properties.containsKey('Validation'), isFalse);
      expect(spec.properties.containsKey('State'), isFalse);
      expect(spec.properties.containsKey('Orientation'), isFalse);
    });

    test('Small binds nothing on its label row, so the fixture is silent', () {
      // The frame is there and insets 2 at the bottom; it simply carries a raw
      // number rather than a Spacing token, so the extractor — which records a
      // child only when it paints or binds — never sees it. Medium and Large do
      // bind, and are asserted from the fixture everywhere below.
      final small = spec.variant(const {'Size': 'Small'});
      expect(small.parts.where((p) => p.name == 'Label + Icon'), isEmpty);
      expect(
        labelRowOf(
          spec.variant(const {'Size': 'Medium'}),
        ).token('paddingBottom'),
        // An axis slip in the file: a vertical inset bound to the horizontal
        // ramp. Both ramps hold the same numbers, so the value is 2 either way.
        'Spacing/Horizontal/XXS',
      );
      expect(
        labelRowOf(
          spec.variant(const {'Size': 'Large'}),
        ).token('paddingBottom'),
        'Spacing/Vertical/XS',
      );
    });

    testWidgets('every size draws its label at the ramp Figma states', (
      tester,
    ) async {
      for (final variant in spec.variants) {
        await pump(
          tester,
          FluentField(
            key: key,
            size: sizeOf(variant),
            label: const Text('Label'),
            child: child,
          ),
        );

        final text = labelTextOf(variant).text!;
        final style = stylesOf(tester).first;

        expect(style.fontSize, text.fontSize, reason: '${variant.name}: size');
        expect(
          style.height! * style.fontSize!,
          text.lineHeight,
          reason: '${variant.name}: line height',
        );
        // Large is 16/22 SEMIBOLD in the design file, which `FluentLabel`
        // reaches only as large + semibold — large + regular is `body2`, a ramp
        // step Figma's Label set does not ship at all. Reading the weight off
        // the fixture rather than assuming regular is what catches that.
        expect(style.fontWeight, switch (text.tokens['fontStyle']!.single) {
          'Typography/Weight/Regular' => FluentFontWeight.regular,
          'Typography/Weight/Semibold' => FluentFontWeight.semibold,
          final other => fail('unmapped weight token $other'),
        }, reason: '${variant.name}: weight');
        expect(
          style.color,
          light.colors.neutralForeground1,
          reason: '${variant.name}: ${text.tokens['fills']!.single}',
        );
        expect(
          tester.getSize(find.byType(FluentLabel)).height,
          labelSlotOf(variant).size.height,
          reason: '${variant.name}: label slot height',
        );
      }
    });

    testWidgets('the label sits its stated gap above the control', (
      tester,
    ) async {
      for (final variant in spec.variants) {
        await pump(
          tester,
          FluentField(
            key: key,
            size: sizeOf(variant),
            label: const Text('Label'),
            child: child,
          ),
        );

        final inset = labelInsetOf(variant);
        expect(
          paddingAbove(tester, find.byType(FluentLabel)),
          EdgeInsets.only(top: inset, bottom: inset + labelGapOf(variant)),
          reason:
              '${variant.name}: Figma binds paddingBottom and nothing else on '
              'Label + Icon. React additionally pads the label 2 above and 2 '
              'below (1 and 1 at large); React wins.',
        );
      }
    });

    testWidgets('the validation row matches Figma, size for size', (
      tester,
    ) async {
      for (final variant in spec.variants) {
        await pump(
          tester,
          FluentField(
            key: key,
            size: sizeOf(variant),
            validationState: FluentFieldValidationState.error,
            validationMessage: const Text('Error text'),
            validationMessageIcon: const SizedBox(key: glyphKey),
            child: child,
          ),
        );

        final row = validationRowOf(variant);
        final text = validationTextOf(variant).text!;
        final style = stylesOf(tester).first;

        // Size-invariant: the Size axis moves the label ramp and the label gap
        // and nothing else. All three variants draw the message at 12/16.
        expect(style.fontSize, text.fontSize, reason: '${variant.name}: size');
        expect(
          style.height! * style.fontSize!,
          text.lineHeight,
          reason: '${variant.name}: line height',
        );
        // Figma binds Status/Danger/Foreground/1 (#b10e1c); upstream's
        // colorPaletteRedForeground1 is what Chrome paints, and wins.
        expect(
          style.color,
          red,
          reason: '${variant.name}: ${text.tokens['fills']!.single}',
        );

        // Spacing/Vertical/XXS above the row, Spacing/Horizontal/XS between
        // the glyph and the text.
        expect(
          paddingAbove(tester, validationRow()),
          EdgeInsets.only(top: row.padding!.top),
          reason: '${variant.name}: ${row.token('paddingTop')}',
        );
        expect(
          tester.widget<Row>(validationRow()).spacing,
          row.gap,
          reason: '${variant.name}: ${row.token('itemSpacing')}',
        );

        // The glyph: 12 across, nudged Spacing/Vertical/XXS down so it lands
        // against the 16px line box beside it.
        final icon = validationIconOf(variant);
        expect(
          iconTheme(tester).size,
          icon.size.width,
          reason: '${variant.name}: glyph size',
        );
        expect(
          iconTheme(tester).color,
          red,
          reason: '${variant.name}: glyph tint',
        );
        expect(
          paddingAbove(tester, find.byKey(glyphKey)),
          EdgeInsets.only(top: icon.padding!.top),
          reason: '${variant.name}: ${icon.token('paddingTop')}',
        );

        expect(
          tester.getSize(validationRow()).height,
          row.size.height - row.padding!.top,
          reason: '${variant.name}: the row inside its own top inset',
        );
      }
    });

    testWidgets('the hint row matches the hidden Helper text layer', (
      tester,
    ) async {
      for (final variant in spec.variants) {
        await pump(
          tester,
          FluentField(
            key: key,
            size: sizeOf(variant),
            hint: const Text('Helper text'),
            child: child,
          ),
        );

        // `Helper text` is hidden in all three shipped variants — it is the
        // slot, not a decoration — so this component's fixture was extracted
        // with the traversal's invisible-node gate dropped. Without that it
        // would carry no hint numbers at all.
        final row = hintRowOf(variant);
        final text = hintTextOf(variant).text!;
        final style = stylesOf(tester).first;

        expect(style.fontSize, text.fontSize, reason: '${variant.name}: size');
        expect(
          style.height! * style.fontSize!,
          text.lineHeight,
          reason: '${variant.name}: line height',
        );
        expect(
          style.color,
          light.colors.neutralForeground3,
          reason: '${variant.name}: ${text.tokens['fills']!.single}',
        );
        expect(
          paddingAbove(tester, find.text('Helper text')),
          EdgeInsets.only(top: row.padding!.top),
          reason: '${variant.name}: ${row.token('paddingTop')}',
        );
        expect(
          tester.getSize(find.byKey(key)).height -
              tester.getSize(find.byKey(childKey)).height,
          row.size.height,
          reason: '${variant.name}: hint row height',
        );
      }
    });

    testWidgets('the assembled field is exactly the sum of its rows', (
      tester,
    ) async {
      // Figma's own frame heights are NOT the target, and both discrepancies
      // are in the file rather than in the port:
      //
      //  * every variant's label row is sized by the `.Info button` beside the
      //    label (24 tall at medium, against the label's 20). That is upstream
      //    `InfoLabel`, a separate component, and is not shipped here; and
      //  * Large's `Label + Icon` frame is a fixed 24 while its own content is
      //    22 plus a 4 bottom inset — 26. A frame shorter than what it holds is
      //    an authoring slip, not a spec.
      //
      // So the assertion is the sum of the rows the fixture states, each of
      // which is checked on its own above.
      for (final variant in spec.variants) {
        await pump(
          tester,
          FluentField(
            key: key,
            size: sizeOf(variant),
            label: const Text('Label'),
            validationMessage: const Text('Error text'),
            hint: const Text('Helper text'),
            child: child,
          ),
        );

        expect(
          tester.getSize(find.byKey(key)).height,
          labelSlotOf(variant).size.height +
              2 * labelInsetOf(variant) +
              labelGapOf(variant) +
              44 +
              validationRowOf(variant).size.height +
              hintRowOf(variant).size.height,
          reason: variant.name,
        );
        expect(
          tester.getSize(find.byKey(childKey)).width,
          250,
          reason:
              '${variant.name}: the control stretches to the field, which is '
              "what upstream's display:grid root does",
        );
      }
    });

    testWidgets('the required asterisk is FluentLabel, not a second copy', (
      tester,
    ) async {
      final variant = spec.variant(const {'Size': 'Medium'});
      await pump(
        tester,
        const FluentField(
          key: key,
          required: true,
          label: Text('Label'),
          child: child,
        ),
      );

      final styles = stylesOf(tester);
      expect(styles, hasLength(2), reason: 'label plus asterisk');
      expect(find.text('*'), findsOneWidget);
      expect(styles[1].fontSize, asteriskOf(variant).text!.fontSize);
      // The label runs the field's width, so the gap is measured from the
      // last glyph's right edge rather than from the label's box.
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.text('Label'),
          matching: find.byType(RichText),
        ),
      );
      final lastGlyph = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 4, extentOffset: 5),
          )
          .single;
      expect(
        tester.getTopLeft(find.text('*')).dx -
            paragraph.localToGlobal(Offset(lastGlyph.right, 0)).dx,
        moreOrLessEquals(labelSlotOf(variant).gap!),
        reason: labelSlotOf(variant).token('itemSpacing'),
      );

      // Figma disagrees with itself and with upstream. The standalone `Label`
      // set binds its asterisk to `Status/Danger/Foreground/3/Rest`; the
      // `Label` INSTANCE inside every `Field` variant overrides it to
      // `Status/Danger/Foreground/1/Rest`. Upstream's Field renders its Label
      // unchanged, and Chrome paints the asterisk colorPaletteRedForeground3 —
      // so reusing FluentLabel wins over restating either Figma token here.
      expect(
        asteriskOf(variant).text!.tokens['fills']!.single,
        'Status/Danger/'
        'Foreground/1/Rest',
      );
      expect(styles[1].color, asteriskRed);
    });

    testWidgets('a long label wraps, the asterisk ending its last line', (
      tester,
    ) async {
      // components-field--required in Chrome, label text swapped for a long
      // one and the field narrowed to 250px: the label runs the field's full
      // width, wraps, and the asterisk follows the last word. The TimePicker
      // story had fixed its label to 300 wide to dodge an overflow here.
      const long =
          'Type a time outside of 10:00 to 19:59, type an invalid time, or '
          'leave the input empty and close the TimePicker.';
      await pump(
        tester,
        const FluentField(
          key: key,
          required: true,
          label: Text(long),
          child: child,
        ),
      );
      final label = tester.getRect(find.byType(FluentLabel));
      expect(label.width, 250);
      expect(label.height, greaterThanOrEqualTo(3 * 20));
      expect(
        tester.getRect(find.text('*')).bottom,
        label.bottom,
        reason: 'on the last line, not on a line of its own',
      );
    });
  });

  group('validation state', () {
    Future<void> pumpState(
      WidgetTester tester,
      FluentFieldValidationState state,
    ) => pump(
      tester,
      FluentField(
        key: key,
        validationState: state,
        validationMessage: const Text('Message'),
        validationMessageIcon: const SizedBox(key: glyphKey),
        child: child,
      ),
    );

    testWidgets('error tints the message AND the glyph', (tester) async {
      // The only state Figma draws. Both the `Error text` node and upstream's
      // `secondaryTextStyles.error` agree on recolouring the text here.
      await pumpState(tester, FluentFieldValidationState.error);
      expect(stylesOf(tester).first.color, red);
      expect(iconTheme(tester).color, red);
    });

    testWidgets('warning and success tint the glyph ONLY', (tester) async {
      // Not an oversight. `useFieldStyles.styles.ts` applies
      // `secondaryTextStyles.error` for the error state alone, while
      // `useValidationMessageIconStyles` has an entry for all three — so a
      // warning's message stays `colorNeutralForeground3` and only its glyph
      // goes amber. Figma cannot arbitrate: it ships no warning or success
      // variant at all.
      for (final (state, tint) in <(FluentFieldValidationState, Color)>[
        (FluentFieldValidationState.warning, darkOrange),
        (FluentFieldValidationState.success, green),
      ]) {
        await pumpState(tester, state);
        expect(
          stylesOf(tester).first.color,
          light.colors.neutralForeground3,
          reason: '$state: the message text must NOT take the status tint',
        );
        expect(iconTheme(tester).color, tint, reason: '$state: glyph');
      }
    });

    testWidgets('none leaves both neutral', (tester) async {
      await pumpState(tester, FluentFieldValidationState.none);
      expect(stylesOf(tester).first.color, light.colors.neutralForeground3);
      expect(iconTheme(tester).color, light.colors.neutralForeground3);
    });

    test('the tints come off the palette layer, not the status aliases', () {
      // Upstream names colorPaletteRedForeground1 / DarkOrange / Green; Figma
      // binds Status/Danger/Foreground/1/Rest, whose light value #b10e1c is
      // statusDangerForeground1. Chrome paints the palette token, so that is
      // what the field selects.
      expect(light.colors.statusDangerForeground1, const Color(0xFFB10E1C));
      expect(
        validationTextOf(spec.variant(const {'Size': 'Medium'})).fill,
        light.colors.statusDangerForeground1,
      );
      final palette = light.colors.palette;
      expect(palette.foreground1Rest(FluentPaletteFamily.red), red);
      expect(
        palette.foreground1Rest(FluentPaletteFamily.darkOrange),
        darkOrange,
      );
      expect(palette.foreground1Rest(FluentPaletteFamily.green), green);
    });

    testWidgets('a message with no glyph still lays out', (tester) async {
      await pump(
        tester,
        const FluentField(
          key: key,
          validationState: FluentFieldValidationState.error,
          showValidationMessageIcon: false,
          validationMessage: Text('Message'),
          child: child,
        ),
      );
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Row)),
        findsNothing,
        reason: 'no glyph, no glyph row',
      );
      expect(stylesOf(tester).first.color, red);
    });
  });

  group('upstream in Chrome', () {
    // components-field--validation-message on storybooks.fluentui.dev, read
    // with getComputedStyle in Chrome under web-light and web-dark: the
    // message's `color` and the `.fui-Field__validationMessageIcon`'s.
    testWidgets('message and glyph take the palette Foreground1 per state', (
      tester,
    ) async {
      final dark = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
      for (final (theme, rows) in <(FluentThemeData, List<(Color, Color)>)>[
        (
          light,
          const [
            (Color(0xFF616161), Color(0xFF616161)), // none
            (Color(0xFFBC2F32), Color(0xFFBC2F32)), // error: RedForeground1
            (Color(0xFF616161), Color(0xFFC43501)), // warning: DarkOrange
            (Color(0xFF616161), Color(0xFF0E700E)), // success: Green
          ],
        ),
        (
          dark,
          const [
            (Color(0xFFADADAD), Color(0xFFADADAD)),
            (Color(0xFFE37D80), Color(0xFFE37D80)),
            (Color(0xFFADADAD), Color(0xFFE9835E)),
            (Color(0xFFADADAD), Color(0xFF54B054)),
          ],
        ),
        // teams-high-contrast: every one of them is #ffffff.
        (
          FluentThemeData.highContrast(fontPlatform: FluentFontPlatform.web),
          const [
            (Color(0xFFFFFFFF), Color(0xFFFFFFFF)),
            (Color(0xFFFFFFFF), Color(0xFFFFFFFF)),
            (Color(0xFFFFFFFF), Color(0xFFFFFFFF)),
            (Color(0xFFFFFFFF), Color(0xFFFFFFFF)),
          ],
        ),
      ]) {
        for (final state in FluentFieldValidationState.values) {
          final (text, glyph) = rows[state.index];
          await pump(
            tester,
            FluentField(
              key: key,
              validationState: state,
              validationMessage: const Text('Message'),
              validationMessageIcon: const SizedBox(key: glyphKey),
              child: child,
            ),
            theme: theme,
          );
          final where = '${theme.colors.brightness.name} $state';
          expect(stylesOf(tester).first.color, text, reason: '$where: text');
          expect(iconTheme(tester).color, glyph, reason: '$where: glyph');
        }
      }
    });

    // `useField_unstable` renders DiamondDismiss12Filled, Warning12Filled and
    // CheckmarkCircle12Filled by default, and nothing for `none`. In Chrome
    // the 12x12 svg sits 2px below the message's top and the text starts 16px
    // in (the icon's width plus spacingHorizontalXS).
    testWidgets("each state draws upstream's glyph unless told otherwise", (
      tester,
    ) async {
      for (final state in FluentFieldValidationState.values) {
        await pump(
          tester,
          FluentField(
            key: key,
            validationState: state,
            validationMessage: const Text('Message'),
            child: child,
          ),
        );
        final glyph = find.byType(FluentFieldValidationGlyph);
        if (state == FluentFieldValidationState.none) {
          expect(glyph, findsNothing, reason: 'none has no default glyph');
          continue;
        }
        expect(tester.widget<FluentFieldValidationGlyph>(glyph).state, state);
        final painter =
            tester
                    .widget<CustomPaint>(
                      find.descendant(
                        of: glyph,
                        matching: find.byType(CustomPaint),
                      ),
                    )
                    .painter!
                as FluentFieldValidationGlyphPainter;
        expect(
          painter.color,
          IconTheme.of(tester.element(glyph)).color,
          reason: '$state: tinted like any Icon',
        );
        final text = tester.getRect(find.text('Message'));
        final ink = tester.getRect(glyph);
        expect(ink.size, const Size.square(12), reason: '$state');
        expect(
          ink.topLeft - text.topLeft,
          const Offset(-16, 2),
          reason: '$state',
        );
      }

      // `validationMessageIcon` replaces the default …
      await pump(
        tester,
        const FluentField(
          key: key,
          validationState: FluentFieldValidationState.error,
          validationMessage: Text('Message'),
          validationMessageIcon: SizedBox(key: glyphKey),
          child: child,
        ),
      );
      expect(find.byType(FluentFieldValidationGlyph), findsNothing);
      expect(find.byKey(glyphKey), findsOneWidget);

      // … and `showValidationMessageIcon: false` drops it and its gutter, the
      // counterpart of `validationMessageIcon={null}`.
      await pump(
        tester,
        const FluentField(
          key: key,
          validationState: FluentFieldValidationState.error,
          showValidationMessageIcon: false,
          validationMessage: Text('Message'),
          child: child,
        ),
      );
      expect(find.byType(FluentFieldValidationGlyph), findsNothing);
      expect(
        tester.getRect(find.text('Message')).left,
        tester.getRect(find.byKey(key)).left,
      );
    });

    testWidgets("the glyphs ink as upstream's svg paths", (tester) async {
      // Each svg rasterised by Chrome, black on white in a 12px box at DPR 4:
      // the ink's bounds and its area, in CSS px.
      const dpr = 4.0;
      for (final (state, bounds, area) in const [
        (FluentFieldValidationState.error, Rect.fromLTWH(1, 1, 10, 10), 54.8),
        (FluentFieldValidationState.warning, Rect.fromLTWH(1, 1, 10, 9), 50.93),
        (
          FluentFieldValidationState.success,
          Rect.fromLTWH(1, 1, 10, 10),
          71.15,
        ),
      ]) {
        const px = 48;
        final recorder = PictureRecorder();
        FluentFieldValidationGlyphPainter(
          state: state,
          color: const Color(0xFF000000),
        ).paint(Canvas(recorder)..scale(dpr), const Size.square(12));
        final bytes = (await tester.runAsync(() async {
          final image = await recorder.endRecording().toImage(px, px);
          return image.toByteData();
        }))!;
        var (minX, minY, maxX, maxY) = (px, px, -1, -1);
        var ink = 0.0;
        for (var y = 0; y < px; y++) {
          for (var x = 0; x < px; x++) {
            final alpha = bytes.getUint8((y * px + x) * 4 + 3) / 255;
            ink += alpha;
            if (alpha > .1) {
              (minX, minY) = (x < minX ? x : minX, y < minY ? y : minY);
              (maxX, maxY) = (x > maxX ? x : maxX, y > maxY ? y : maxY);
            }
          }
        }
        expect(
          Rect.fromLTRB(
            minX / dpr,
            minY / dpr,
            (maxX + 1) / dpr,
            (maxY + 1) / dpr,
          ),
          bounds,
          reason: '$state: ink bounds',
        );
        expect(ink / dpr / dpr, closeTo(area, 1), reason: '$state: ink area');
      }
    });
  });

  group('motion', () {
    testWidgets('validation changes are instant — Field has no transition', (
      tester,
    ) async {
      // useFieldStyles.styles.ts contains no `transition`, no `animation` and
      // no motionTokens reference of any kind. This is the Checkbox and Tag
      // category: the colour lands on the frame the state changes.
      await pump(
        tester,
        const FluentField(
          key: key,
          validationMessage: Text('Message'),
          child: child,
        ),
      );
      expect(stylesOf(tester).first.color, light.colors.neutralForeground3);

      await pump(
        tester,
        const FluentField(
          key: key,
          validationState: FluentFieldValidationState.error,
          validationMessage: Text('Message'),
          child: child,
        ),
      );
      // One frame, no settle.
      expect(
        stylesOf(tester).first.color,
        red,
        reason: 'must be instant, not mid-tween',
      );
    });

    testWidgets('there is no implicit animation to shorten', (tester) async {
      await pump(
        tester,
        const FluentField(
          key: key,
          label: Text('Label'),
          validationState: FluentFieldValidationState.error,
          validationMessage: Text('Message'),
          hint: Text('Hint'),
          child: child,
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byWidgetPredicate(
            (w) => w is ImplicitlyAnimatedWidget,
          ),
        ),
        findsNothing,
        reason:
            'nothing here animates, so MediaQuery.disableAnimations has '
            'nothing to clamp — that is the spec, not an omission',
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
        FluentFieldTheme(
          style: FluentFieldStyle.from(hintColor: themed),
          child: FluentField(
            key: key,
            style: FluentFieldStyle.from(hintColor: explicit),
            hint: const Text('Hint'),
            child: child,
          ),
        ),
      );
      expect(stylesOf(tester).first.color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentFieldTheme(
          style: FluentFieldStyle.from(hintColor: themed),
          child: const FluentField(key: key, hint: Text('Hint'), child: child),
        ),
      );
      expect(stylesOf(tester).first.color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentField(
          key: key,
          size: FluentFieldSize.large,
          validationState: FluentFieldValidationState.warning,
          style: FluentFieldStyle.from(gap: 20),
          label: const Text('Label'),
          validationMessage: const Text('Message'),
          validationMessageIcon: const SizedBox(key: glyphKey),
          child: child,
        ),
      );

      expect(tester.widget<Row>(validationRow()).spacing, 20);
      expect(
        stylesOf(tester).first.fontSize,
        16,
        reason: 'overriding the gap must not drop the Large label ramp',
      );
      expect(
        iconTheme(tester).color,
        darkOrange,
        reason: 'overriding the gap must not drop the warning tint',
      );
      expect(
        paddingAbove(tester, find.byType(FluentLabel)),
        const EdgeInsets.only(top: 1, bottom: 5),
        reason: 'overriding the gap must not drop the Large label inset',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const hint = Color(0xFF00FF00);
      const message = Color(0xFF0000FF);
      const tint = Color(0xFFFF00FF);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentField(
            const FluentFieldBaseState(
              enabled: true,
              // A bare Text, because the base state takes any widget at all —
              // this is the path a consumer uses to keep Fluent's layout while
              // supplying their own label component.
              label: Text('Label'),
              validationMessage: Text('Message'),
              validationMessageIcon: SizedBox(key: glyphKey),
              hint: Text('Hint'),
              child: child,
            ),
            FluentFieldStyle.from(
              hintColor: hint,
              validationMessageColor: message,
              validationMessageIconColor: tint,
              validationMessageIconSize: 40,
              secondaryTextStyle: const TextStyle(
                fontSize: 30,
                height: 40 / 30,
              ),
            ),
            const <WidgetState>{},
          ),
        ),
      );

      final styles = stylesOf(tester);
      expect(styles[1].color, message);
      expect(styles[1].fontSize, 30);
      expect(styles[2].color, hint);
      expect(iconTheme(tester).color, tint);
      expect(iconTheme(tester).size, 40);
      expect(find.byType(FluentLabel), findsNothing);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentFieldState(
        size: FluentFieldSize.small,
        validationState: FluentFieldValidationState.success,
        label: const Text('Label'),
        validationMessage: const Text('Message'),
      );
      final adjusted = resolveFluentFieldStyle(state, light).merge(
        FluentFieldStyle.from(validationMessageColor: const Color(0xFF00FF00)),
      );

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentField(state, adjusted, const <WidgetState>{}),
        ),
      );
      final styles = stylesOf(tester);
      expect(
        styles.first.fontSize,
        12,
        reason: 'the Small label ramp survives',
      );
      expect(styles.last.color, const Color(0xFF00FF00));
    });

    testWidgets('resolveState composes a real FluentLabel', (tester) async {
      // The label is deliberately not restyled through FluentFieldStyle: it is
      // a FluentLabel, so FluentLabelTheme is the rung that restyles it, and
      // there stays one place to look when a label goes wrong.
      const themed = Color(0xFF780510);
      await pump(
        tester,
        FluentLabelTheme(
          style: FluentLabelStyle.from(foregroundColor: themed),
          child: const FluentField(
            key: key,
            label: Text('Label'),
            child: child,
          ),
        ),
      );
      expect(find.byType(FluentLabel), findsOneWidget);
      expect(stylesOf(tester).first.color, themed);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the neutral message', (
      tester,
    ) async {
      // The palette tint is not an alias token, so it is restyled through
      // FluentFieldStyle; the neutral ramp still follows the theme.
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light,
          home: const Center(
            child: SizedBox(
              width: 250,
              child: FluentThemeOverride(
                colors: {FluentColorToken.neutralForeground3: magenta},
                child: FluentField(
                  key: key,
                  validationState: FluentFieldValidationState.warning,
                  validationMessage: Text('Message'),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
      expect(stylesOf(tester).first.color, magenta);
    });

    testWidgets('an override on a subtree reaches the hint too', (
      tester,
    ) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light,
          home: const Center(
            child: SizedBox(
              width: 250,
              child: FluentThemeOverride(
                colors: {FluentColorToken.neutralForeground3: magenta},
                child: FluentField(key: key, hint: Text('Hint'), child: child),
              ),
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

      // Field paints no surface and no border, so what can vanish here is a
      // foreground: a colour derived by arithmetic rather than selected from a
      // token can land transparent, or land on the background it sits on.
      for (final state in FluentFieldValidationState.values) {
        for (final enabled in [true, false]) {
          await pump(
            tester,
            FluentField(
              key: key,
              enabled: enabled,
              required: true,
              validationState: state,
              label: const Text('Label'),
              validationMessage: const Text('Message'),
              validationMessageIcon: const SizedBox(key: glyphKey),
              hint: const Text('Hint'),
              child: child,
            ),
            theme: theme,
          );

          final painted = <Color>[
            ...stylesOf(tester).map((s) => s.color!),
            iconTheme(tester).color!,
          ];
          for (final color in painted) {
            expect(
              color.a,
              1.0,
              reason: '$state enabled=$enabled: a transparent foreground',
            );
            expect(
              color,
              isNot(theme.colors.neutralBackground1),
              reason: '$state enabled=$enabled: invisible against the surface',
            );
          }
        }
      }
    });
  });

  group('behaviour', () {
    testWidgets('disabled is a state, not an opacity', (tester) async {
      await pump(
        tester,
        const FluentField(
          key: key,
          enabled: false,
          required: true,
          validationState: FluentFieldValidationState.error,
          label: Text('Label'),
          validationMessage: Text('Message'),
          validationMessageIcon: SizedBox(key: glyphKey),
          hint: Text('Hint'),
          child: child,
        ),
      );

      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Opacity)),
        findsNothing,
        reason:
            'Fluent ships a Disabled token; fading the enabled colour would '
            'be a different colour on every background',
      );
      // Every row swaps to the disabled ramp wholesale — the error message
      // included, which loses its danger tint rather than dimming it. Neither
      // Figma nor React states this: the set has no Disabled axis and React's
      // Field has no `disabled` prop at all. It is the call every other
      // component in this port makes.
      for (final style in stylesOf(tester)) {
        expect(style.color, light.colors.neutralForegroundDisabled);
      }
      expect(iconTheme(tester).color, light.colors.neutralForegroundDisabled);
    });

    testWidgets('disabling does not reach into the child control', (
      tester,
    ) async {
      // A wrapper that switched an arbitrary widget off would be guessing at
      // what "off" means for it.
      var pressed = 0;
      await pump(
        tester,
        FluentField(
          key: key,
          enabled: false,
          label: const Text('Label'),
          child: FluentButton(
            onPressed: () => pressed++,
            child: const Text('Go'),
          ),
        ),
      );
      await tester.tap(find.byType(FluentButton));
      expect(pressed, 1);
    });

    testWidgets('the field owns no focus and never takes the control’s', (
      tester,
    ) async {
      // Field has no keyboard interaction of its own: it is a wrapper, and the
      // control it wraps is what focus belongs to.
      final node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        FluentField(
          key: key,
          label: const Text('Label'),
          hint: const Text('Hint'),
          child: FluentButton(
            focusNode: node,
            autofocus: true,
            onPressed: () {},
            child: const Text('Go'),
          ),
        ),
      );
      await tester.pump();

      expect(node.hasPrimaryFocus, isTrue);
      expect(
        find
            .descendant(
              of: find.byKey(key),
              matching: find.byType(FocusableActionDetector),
            )
            .evaluate(),
        hasLength(1),
        reason: 'exactly one — the button’s. The field adds none of its own',
      );
    });

    testWidgets('rows render only when their content is given', (tester) async {
      await pump(tester, const FluentField(key: key, child: child));
      expect(stylesOf(tester), isEmpty);
      expect(find.byType(FluentLabel), findsNothing);
      expect(
        tester.getSize(find.byKey(key)).height,
        44,
        reason: 'a field with nothing but a control is exactly the control',
      );
    });

    testWidgets('the control is optional too', (tester) async {
      await pump(tester, const FluentField(key: key, label: Text('Label')));
      expect(find.byType(FluentLabel), findsOneWidget);
    });
  });

  group('semantics', () {
    testWidgets('the field is one node, marked required and enabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const FluentField(
          key: key,
          required: true,
          label: Text('Label'),
          child: child,
        ),
      );

      expect(
        tester.getSemantics(find.byKey(key)),
        isSemantics(isRequired: true, hasEnabledState: true),
      );
      // Required-ness belongs to the field, not to the text of its label:
      // FluentLabel excludes its asterisk from semantics, so "Label*" is never
      // announced even though the glyph is painted.
      expect(find.text('*'), findsOneWidget);
      expect(find.bySemanticsLabel('*'), findsNothing);
      handle.dispose();
    });

    testWidgets('a disabled field says so', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const FluentField(
          key: key,
          enabled: false,
          label: Text('Label'),
          child: child,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('the validation message is a live region of its own', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const FluentField(
          key: key,
          validationState: FluentFieldValidationState.error,
          validationMessage: Text('That address is taken'),
          hint: Text('Hint'),
          child: child,
        ),
      );

      // Upstream's role="alert": a message that appears after the user has left
      // the control still gets announced. It has to be a node of its own —
      // merged upwards, the flag would turn the entire field into a live
      // region and every unrelated change would be read out.
      final message = find
          .ancestor(
            of: find.text('That address is taken'),
            matching: find.byType(Semantics),
          )
          .first;
      expect(tester.getSemantics(message), isSemantics(isLiveRegion: true));
      expect(
        tester.getSemantics(find.byKey(key)),
        isNot(isSemantics(isLiveRegion: true)),
      );
      // A hint is not an alert.
      expect(
        tester.getSemantics(find.text('Hint')),
        isNot(isSemantics(isLiveRegion: true)),
      );
      handle.dispose();
    });
  });
}
