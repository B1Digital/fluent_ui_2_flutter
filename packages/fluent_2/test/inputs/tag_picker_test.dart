/// `FluentTagPicker` is three components in a trench coat — a surface, a
/// `FluentInput` with its chrome switched off, and an overlay list of rows
/// rendered by `buildFluentDropdownOption` — so these tests cover all three:
/// the token table against upstream as it renders in Chrome (and the Figma
/// `Tag picker/TagPicker` set where the two agree), the widgets it actually
/// composes, and the keyboard contract that ties them together.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/internal/input_modality.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

void _noop(List<String> values) {}

void main() {
  const key = Key('picker');

  const options = <FluentTagPickerOption<String>>[
    FluentTagPickerOption<String>.header(label: Text('People'), text: 'People'),
    FluentTagPickerOption<String>(
      value: 'kat',
      label: Text('Katri'),
      text: 'Katri',
    ),
    FluentTagPickerOption<String>(
      value: 'ben',
      label: Text('Ben'),
      text: 'Ben',
    ),
    FluentTagPickerOption<String>(
      value: 'ola',
      label: Text('Ola'),
      text: 'Ola',
      enabled: false,
    ),
  ];

  FluentThemeData themeOf(
    FluentThemeData Function({TargetPlatform platform}) f,
  ) => f(platform: TargetPlatform.windows);

  final light = themeOf(FluentThemeData.light);
  final dark = themeOf(FluentThemeData.dark);
  final highContrast = themeOf(FluentThemeData.highContrast);

  Widget app(
    Widget child, {
    FluentThemeData? theme,
    bool reducedMotion = false,
  }) => FluentApp(
    theme: theme ?? light,
    debugShowCheckedModeBanner: false,
    builder: reducedMotion
        ? (context, inner) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: inner!,
          )
        : null,
    home: Center(child: SizedBox(width: 320, child: child)),
  );

  // ---------------------------------------------------------------------------
  // Figma fidelity: the fixture's 72 variants, asserted where upstream agrees.
  // ---------------------------------------------------------------------------

  group('figma', () {
    final spec = loadSpec('tag_picker');

    FluentTagPickerAppearance appearanceOf(String value) => switch (value) {
      'Outline' => FluentTagPickerAppearance.outline,
      'Transparent' => FluentTagPickerAppearance.transparent,
      'Filled darker' => FluentTagPickerAppearance.filledDarker,
      'Filled lighter' => FluentTagPickerAppearance.filledLighter,
      _ => throw StateError('unknown Style=$value'),
    };

    FluentTagPickerSize sizeOf(String value) => switch (value) {
      'Medium' => FluentTagPickerSize.medium,
      'Large' => FluentTagPickerSize.large,
      'Extra large' => FluentTagPickerSize.extraLarge,
      _ => throw StateError('unknown Size=$value'),
    };

    (bool, bool, Set<WidgetState>) conditionOf(String value) => switch (value) {
      'Rest' => (true, false, <WidgetState>{}),
      'Hover' => (true, false, <WidgetState>{WidgetState.hovered}),
      'Pressed' => (true, false, <WidgetState>{WidgetState.pressed}),
      'Focused' => (true, true, <WidgetState>{}),
      'Disabled' => (false, false, <WidgetState>{WidgetState.disabled}),
      _ => throw StateError('unknown State=$value'),
    };

    /// The picker set is the only one in the file with an axis this test has to
    /// resolve into three separate inputs, so it is spelled out once here.
    FluentTagPickerStyle styleFor(SpecVariant variant, FluentThemeData theme) {
      final (enabled, focused, _) = conditionOf(variant.props['State']!);
      return resolveFluentTagPickerStyle(
        resolveFluentTagPickerState(
          field: const SizedBox.shrink(),
          enabled: enabled,
          focused: focused,
          open: variant.props['Expanded'] == 'True',
          appearance: appearanceOf(variant.props['Style']!),
          size: sizeOf(variant.props['Size']!),
        ),
        theme,
      );
    }

    String hex(Color color) =>
        '#${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}';

    test('the fixture covers all 72 variants', () {
      expect(spec.variants, hasLength(72));
      expect(spec.properties['Style'], hasLength(4));
      expect(spec.properties['Size'], hasLength(3));
      expect(spec.properties['State'], hasLength(5));
      expect(spec.properties['Expanded'], hasLength(2));
    });

    // Only the Rest column is asserted against Figma: it is where Figma and
    // upstream as it renders in Chrome agree. Everywhere else the two part —
    // Figma's disabled fill, its Hover-on-Pressed and Stroke1Selected-on-open
    // ramps, its 48-tall Extra large — and upstream wins; the `upstream` group
    // below asserts those states.
    bool atRest(SpecVariant variant) =>
        variant.props['State'] == 'Rest' &&
        variant.props['Expanded'] == 'False';

    for (final variant in spec.variants.where(atRest)) {
      test('${variant.name} — surface', () {
        final style = styleFor(variant, light);
        final (_, _, states) = conditionOf(variant.props['State']!);
        final input = variant.part('Input');

        final fill = style.backgroundColor!.resolve(states)!;
        if (input.fill!.a == 0) {
          // Figma's `Neutral/Background/Transparent/Rest` is transparent WHITE;
          // this package's `transparentBackground` is transparent black, which
          // is what CSS `transparent` actually is and what upstream therefore
          // ships. Both are invisible, and only the alpha is observable — see
          // `fluentLerpColor`, which exists because of that difference.
          expect(fill.a, 0, reason: '${variant.name}: fill must be invisible');
        } else {
          expect(
            hex(fill),
            hex(input.fill!),
            reason:
                '${variant.name}: fill (token ${input.token('fills')}) '
                'on node ${input.nodeId}',
          );
        }
      });
    }

    for (final variant in spec.variants.where(atRest)) {
      test('${variant.name} — border and rules', () {
        final style = styleFor(variant, light);
        final (_, _, states) = conditionOf(variant.props['State']!);
        final input = variant.part('Input');

        if (input.stroke == null) {
          // Transparent paints no border at all — a zero-width one, which
          // cannot reappear in high contrast. The two filled appearances paint
          // none in Figma but keep the *transparent* token here, which does
          // turn opaque there. That distinction is the whole reason both cases
          // are asserted rather than collapsed into "no border".
          if (variant.props['Style'] == 'Transparent') {
            expect(style.borderColor, isNull);
            expect(style.borderWidth!.resolve(states), FluentStroke.none);
          } else {
            expect(
              style.borderColor!.resolve(states)!.a,
              0,
              reason: '${variant.name}: invisible, not absent',
            );
            expect(style.borderWidth!.resolve(states), FluentStroke.thin);
          }
        } else {
          expect(
            hex(style.borderColor!.resolve(states)!),
            hex(input.stroke!),
            reason: '${variant.name}: border (token ${input.token('strokes')})',
          );
          expect(
            style.borderWidth!.resolve(states),
            input.strokeWidth,
            reason: '${variant.name}: border width',
          );
        }

        final rules = variant.parts
            .where((part) => part.name.endsWith('underline'))
            .toList();
        final resting = rules.where((part) => part.size.height == 1).toList();
        final accent = rules.where((part) => part.size.height == 2).toList();

        // Only the two filled appearances have no resting rule. The Expanded
        // frames omit it too, but that is the full-width accent bar covering
        // it rather than the rule being absent.
        expect(
          style.underlineColor == null,
          variant.props['Style'].toString().startsWith('Filled'),
          reason: '${variant.name}: only Filled draws no resting rule',
        );

        if (resting.isNotEmpty) {
          expect(
            hex(style.underlineColor!.resolve(states)!),
            hex(resting.first.fill!),
            reason:
                '${variant.name}: bottom rule '
                '(token ${resting.first.token('fills')})',
          );
          expect(style.underlineWidth!.resolve(states), FluentStroke.thin);
        }

        if (accent.isNotEmpty) {
          expect(
            hex(style.accentColor!.resolve(states)!),
            hex(accent.first.fill!),
            reason:
                '${variant.name}: accent bar '
                '(token ${accent.first.token('fills')})',
          );
          expect(style.accentWidth!.resolve(states), FluentStroke.thick);
        }
      });
    }

    test('exactly six Input nodes lost their corner radius in Figma', () {
      final square = <String>[
        for (final variant in spec.variants)
          if (variant.part('Input').radius == BorderRadius.zero) variant.name,
      ];
      // Authoring drift, not a design decision: the three unbordered
      // appearances at `Size=Medium` bind `Corner-radius/None` on Rest and
      // Disabled, while the other 66 variants — the same appearances at Large
      // and Extra large included — bind `Corner-radius/Input/Medium`. Upstream
      // settles it: 4 on the bordered appearances, and 0 on Transparent
      // (`underline: { borderRadius: '0' }`) at every size.
      expect(square, hasLength(6));
      expect(
        square.every(
          (name) =>
              !name.contains('Style=Outline') &&
              name.contains('Size=Medium') &&
              (name.contains('State=Rest') || name.contains('State=Disabled')),
        ),
        isTrue,
        reason: 'unexpected square variants: $square',
      );
    });

    test('the type ramp holds still across all three sizes', () {
      final ramps = <TextStyle?>{
        for (final size in FluentTagPickerSize.values)
          resolveFluentTagPickerStyle(
            resolveFluentTagPickerState(
              field: const SizedBox.shrink(),
              size: size,
            ),
            light,
          ).textStyle!.resolve(const <WidgetState>{}),
      };
      expect(ramps, hasLength(1));
      expect(ramps.single!.fontSize, 14);
      expect(ramps.single!.height! * 14, 20);
    });

    test('a disabled control has no accent bar at all', () {
      final style = resolveFluentTagPickerStyle(
        resolveFluentTagPickerState(
          field: const SizedBox.shrink(),
          enabled: false,
        ),
        light,
      );
      expect(style.accentColor, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Composition — the point of this wave.
  // ---------------------------------------------------------------------------

  group('composition', () {
    testWidgets('the field is a FluentInput, not a second EditableText', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          FluentTagPicker<String>(
            key: key,
            options: options,
            placeholder: const Text('Search'),
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(FluentInput), findsOneWidget);
      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('chips are plain dismissible FluentTags, as upstream draws', (
      tester,
    ) async {
      // Every upstream TagPicker story puts a `<Tag>` in the `TagPickerGroup`,
      // not an InteractionTag: no divider, and on the extra-small tag a medium
      // picker uses, 20 tall with a 12px dismiss glyph (Chrome).
      await tester.pumpWidget(
        app(
          FluentTagPicker<String>(
            key: key,
            options: options,
            selected: const <String>['kat', 'ben'],
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(FluentTag), findsNWidgets(2));
      expect(find.byType(FluentInteractionTag), findsNothing);
      expect(find.text('Katri'), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
      final chip = find.byType(FluentTag).first;
      expect(tester.getSize(chip).height, 20);
      expect(
        tester.getSize(
          find.descendant(
            of: chip,
            matching: find.byType(FluentTagDismissGlyph),
          ),
        ),
        const Size.square(12),
      );
    });

    testWidgets('a chip draws tagMedia, and falls back to media', (
      tester,
    ) async {
      // Upstream's stories hand the Tag and the TagPickerOption separate
      // avatars: 16 in the extra-small chip, 32 in a 44-tall row.
      const chipMedia = Key('chip media');
      const katRow = Key('kat row media');
      const benRow = Key('ben row media');
      var selected = <String>['kat'];
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => FluentTagPicker<String>(
              key: key,
              options: const <FluentTagPickerOption<String>>[
                FluentTagPickerOption<String>(
                  value: 'kat',
                  label: Text('Katri'),
                  media: SizedBox.square(key: katRow, dimension: 32),
                  tagMedia: SizedBox.square(key: chipMedia, dimension: 16),
                ),
                FluentTagPickerOption<String>(
                  value: 'ben',
                  label: Text('Ben'),
                  media: SizedBox.square(key: benRow, dimension: 16),
                ),
              ],
              selected: selected,
              autofocus: true,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(FluentTag),
          matching: find.byKey(chipMedia),
        ),
        findsOneWidget,
      );
      expect(find.byKey(katRow), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(FluentTag),
          matching: find.byKey(benRow),
        ),
        findsNothing,
        reason: 'Ben is a row, not a chip',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(FluentTag),
          matching: find.byKey(benRow),
        ),
        findsOneWidget,
        reason: 'no tagMedia: the chip reuses media',
      );
    });

    testWidgets('the accent bar is FluentInput\'s own focus underline', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          FluentTagPicker<String>(
            key: key,
            options: options,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(FluentInputFocusUnderline), findsOneWidget);
    });

    testWidgets('popup rows carry the shared dropdown-row geometry', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          FluentTagPicker<String>(
            key: key,
            options: options,
            autofocus: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(find.text('Katri'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);

      final row = find.ancestor(
        of: find.text('Katri'),
        matching: find.byType(FluentFocusRing),
      );
      // Upstream's `TagPickerOption` is the combobox `Option` with no check
      // slot: `padding: 6px 8px` around a 20px line, 32 tall — as measured in
      // Chrome — not Figma's 48-tall `TagPicker/Item`. The label starts at the
      // 8px inset, with no checkmark column reserved before it.
      expect(tester.getSize(row).height, 32);
      expect(
        tester.getRect(find.text('Katri')).left - tester.getRect(row).left,
        FluentSpacing.s,
      );
      expect(
        tester
            .widget<RichText>(
              find.descendant(
                of: find.text('Katri'),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style!
            .color,
        light.colors.neutralForeground1,
      );
    });

    test('rows resolve against the shared FluentDropdownOptionStyle', () {
      final style = resolveFluentTagPickerOptionStyle(
        resolveFluentDropdownOptionState(label: const Text('x')),
        light,
      );
      expect(style, isA<FluentDropdownOptionStyle>());
      expect(style.minimumSize!.resolve(const <WidgetState>{})!.height, 32);
      // The `Option`'s `columnGap: spacingHorizontalXS`.
      expect(style.gap!.resolve(const <WidgetState>{}), FluentSpacing.xs);
    });

    test('headers fall through to the dropdown row style untouched', () {
      const state = FluentDropdownOptionState(
        enabled: false,
        selected: false,
        showCheckmark: false,
        reserveCheckmark: false,
        label: Text('People'),
        type: FluentDropdownOptionType.header,
      );
      final ours = resolveFluentTagPickerOptionStyle(state, light);
      final shared = resolveFluentDropdownOptionStyle(state, light);
      const none = <WidgetState>{};
      expect(ours.textStyle!.resolve(none), shared.textStyle!.resolve(none));
      expect(ours.padding!.resolve(none), shared.padding!.resolve(none));
      expect(
        ours.foregroundColor!.resolve(none),
        shared.foregroundColor!.resolve(none),
      );
      expect(
        ours.minimumSize!.resolve(none)!.height,
        shared.minimumSize!.resolve(none)!.height,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Upstream as it renders: `useTagPickerControlStyles.styles.ts` and
  // `useTagPickerInputStyles.styles.ts` measured in Chrome on the storybook.
  // ---------------------------------------------------------------------------

  group('upstream', () {
    const none = <WidgetState>{};
    const hover = <WidgetState>{WidgetState.hovered};
    const press = <WidgetState>{WidgetState.pressed};
    final c = light.colors;
    final danger = c.palette.stroke2Rest(FluentPaletteFamily.red)!;

    FluentTagPickerStyle resolve(
      FluentTagPickerAppearance appearance, {
      bool enabled = true,
      bool focused = false,
      bool open = false,
      bool error = false,
      FluentThemeData? theme,
    }) => resolveFluentTagPickerStyle(
      resolveFluentTagPickerState(
        field: const SizedBox.shrink(),
        enabled: enabled,
        focused: focused,
        open: open,
        error: error,
        appearance: appearance,
      ),
      theme ?? light,
    );

    /// The control's own border: the first painter in tree order, ahead of the
    /// composed input's chromeless one.
    FluentInputBorderPainter borderPainter(WidgetTester tester) => tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(CustomPaint),
          ),
        )
        .map((p) => p.painter)
        .whereType<FluentInputBorderPainter>()
        .first;

    test('Outline: focus and open are Pressed, and hover wins over both', () {
      // `:focus-within` is its own rule, which Griffel sorts before `:hover`;
      // upstream has no open rule, and an open picker holds focus.
      final rest = resolve(FluentTagPickerAppearance.outline);
      expect(rest.borderColor!.resolve(none), c.neutralStroke1);
      expect(rest.underlineColor!.resolve(none), c.neutralStrokeAccessible);
      expect(rest.borderColor!.resolve(hover), c.neutralStroke1Hover);
      expect(
        rest.underlineColor!.resolve(hover),
        c.neutralStrokeAccessibleHover,
      );
      for (final style in [
        resolve(FluentTagPickerAppearance.outline, focused: true),
        resolve(FluentTagPickerAppearance.outline, open: true),
      ]) {
        expect(style.borderColor!.resolve(none), c.neutralStroke1Pressed);
        expect(
          style.underlineColor!.resolve(none),
          c.neutralStrokeAccessiblePressed,
        );
        expect(style.borderColor!.resolve(hover), c.neutralStroke1Hover);
        expect(style.borderColor!.resolve(press), c.neutralStroke1Pressed);
        // `:focus-within:active::after` is the bar's only other colour.
        expect(style.accentColor!.resolve(none), c.compoundBrandStroke);
        expect(style.accentColor!.resolve(press), c.compoundBrandStrokePressed);
      }
    });

    test('Transparent and the filled appearances never ramp', () {
      for (final appearance in [
        FluentTagPickerAppearance.transparent,
        FluentTagPickerAppearance.filledDarker,
        FluentTagPickerAppearance.filledLighter,
      ]) {
        for (final focused in [false, true]) {
          final style = resolve(appearance, focused: focused);
          for (final states in [none, hover, press]) {
            final reason = '${appearance.name} focused=$focused $states';
            if (appearance == FluentTagPickerAppearance.transparent) {
              expect(style.borderColor, isNull, reason: reason);
              expect(
                style.underlineColor!.resolve(states),
                c.neutralStrokeAccessible,
                reason: reason,
              );
            } else {
              expect(
                style.borderColor!.resolve(states),
                c.transparentStroke,
                reason: reason,
              );
              expect(style.underlineColor, isNull, reason: reason);
            }
          }
        }
      }
    });

    test('disabled is transparent, with a disabled stroke on every side', () {
      for (final appearance in FluentTagPickerAppearance.values) {
        final style = resolve(appearance, enabled: false);
        final reason = appearance.name;
        expect(
          style.backgroundColor!.resolve(none),
          c.transparentBackground,
          reason: reason,
        );
        expect(style.accentColor, isNull, reason: reason);
        if (appearance == FluentTagPickerAppearance.transparent) {
          expect(style.borderColor, isNull, reason: reason);
          expect(
            style.underlineColor!.resolve(none),
            c.neutralStrokeDisabled,
            reason: reason,
          );
        } else {
          expect(
            style.borderColor!.resolve(none),
            c.neutralStrokeDisabled,
            reason: reason,
          );
        }
      }
    });

    test('error is colorPaletteRedBorder2 until the control is focused', () {
      final outline = resolve(FluentTagPickerAppearance.outline, error: true);
      // `:hover:not(:focus-within)` keeps it red under the pointer.
      for (final states in [none, hover]) {
        expect(outline.borderColor!.resolve(states), danger);
        expect(outline.underlineColor!.resolve(states), danger);
      }
      expect(
        resolve(
          FluentTagPickerAppearance.outline,
          error: true,
          focused: true,
        ).borderColor!.resolve(none),
        c.neutralStroke1Pressed,
      );
      final filled = resolve(
        FluentTagPickerAppearance.filledDarker,
        error: true,
      );
      expect(filled.borderColor!.resolve(none), danger);
      // Transparent colours its bottom border only.
      final underline = resolve(
        FluentTagPickerAppearance.transparent,
        error: true,
      );
      expect(underline.borderColor, isNull);
      expect(underline.underlineColor!.resolve(none), danger);
      // The palette knows nothing of high contrast; the status token does.
      expect(
        resolve(
          FluentTagPickerAppearance.outline,
          error: true,
          theme: highContrast,
        ).borderColor!.resolve(none),
        (highContrast.colors as FluentHighContrastColors).statusDangerBorder2,
      );
    });

    test('error outranks disabled, as Chrome renders it', () {
      // `invalid` is not gated on `!disabled`, and `:not(:focus-within)`
      // out-specifies `disabled`'s plain class: Chrome reads rgb(209, 52, 56)
      // on a disabled control inside an error Field.
      for (final appearance in FluentTagPickerAppearance.values) {
        final style = resolve(appearance, enabled: false, error: true);
        final transparent = appearance == FluentTagPickerAppearance.transparent;
        expect(
          transparent ? style.underlineColor : style.borderColor,
          isNotNull,
          reason: appearance.name,
        );
        expect(
          (transparent ? style.underlineColor : style.borderColor)!.resolve(
            const {WidgetState.disabled},
          ),
          danger,
          reason: appearance.name,
        );
        expect(
          style.backgroundColor!.resolve(none),
          c.transparentBackground,
          reason: appearance.name,
        );
      }
    });

    testWidgets('geometry matches upstream at every size', (tester) async {
      // `TagPickerInput` pads a 20px line by 6 / 10 / 12, so the control is
      // 34 / 42 / 46 with its borders. The field starts at `paddingLeft:
      // spacingHorizontalM` inside the border; the chevron is 16 / 20 / 24,
      // 12 in from the inside of the right border, centred in a box of the
      // root's minimum height pinned to the top.
      const upstream = {
        FluentTagPickerSize.medium: (height: 34.0, icon: 16.0, top: 9.0),
        FluentTagPickerSize.large: (height: 42.0, icon: 20.0, top: 11.0),
        FluentTagPickerSize.extraLarge: (height: 46.0, icon: 24.0, top: 11.0),
      };
      for (final entry in upstream.entries) {
        for (final appearance in FluentTagPickerAppearance.values) {
          await tester.pumpWidget(
            app(
              FluentTagPicker<String>(
                key: key,
                size: entry.key,
                appearance: appearance,
                options: options,
                onChanged: _noop,
              ),
            ),
          );
          final reason = '${entry.key.name} ${appearance.name}';
          // Transparent has a bottom border only.
          final side = appearance == FluentTagPickerAppearance.transparent
              ? 1.0
              : 0.0;
          final want = entry.value;
          final box = tester.getRect(find.byKey(key));
          expect(box.height, want.height - side, reason: '$reason: height');
          expect(
            tester.getRect(find.byType(EditableText)).left - box.left,
            13 - side,
            reason: '$reason: field start',
          );
          final chevron = tester.getRect(find.byIcon(fluentTagPickerChevron));
          expect(chevron.width, want.icon, reason: '$reason: chevron size');
          expect(
            box.right - chevron.right,
            13 - side,
            reason: '$reason: chevron end',
          );
          expect(
            chevron.top - box.top,
            want.top - side,
            reason: '$reason: chevron top',
          );
        }
      }
    });

    testWidgets(
      'the secondary action spans the control; the chevron stays up',
      (tester) async {
        // `components-tagpicker--secondary-action` in Chrome, at 400 and forced
        // to wrap at 260: the aside and its button run the full inner height
        // (32, then 64) with the label centred in it, flush after the content;
        // only the expand icon is `alignSelf: flex-start`, its glyph 9 down,
        // 2 after the button.
        for (final (width, selected) in <(double, List<String>)>[
          (400, <String>['kat']),
          (260, <String>['kat', 'ben']),
        ]) {
          await tester.pumpWidget(
            FluentApp(
              theme: light,
              home: Center(
                child: SizedBox(
                  width: width,
                  child: FluentTagPicker<String>(
                    key: key,
                    options: options,
                    selected: selected,
                    onChanged: _noop,
                    secondaryAction: FluentButton(
                      appearance: FluentButtonAppearance.transparent,
                      size: FluentButtonSize.small,
                      onPressed: () {},
                      child: const Text('All Clear'),
                    ),
                  ),
                ),
              ),
            ),
          );
          final reason = 'at $width';
          final box = tester.getRect(find.byKey(key));
          final button = tester.getRect(find.byType(FluentButton));
          final label = tester.getRect(find.text('All Clear'));
          final chevron = tester.getRect(find.byIcon(fluentTagPickerChevron));
          if (width == 260) expect(box.height, greaterThan(34), reason: reason);
          expect(button.top, box.top + 1, reason: '$reason: button top');
          expect(button.bottom, box.bottom - 1, reason: '$reason: button end');
          expect(label.center.dy, button.center.dy, reason: '$reason: label');
          expect(chevron.top - box.top, 9, reason: '$reason: chevron top');
          expect(chevron.left - button.right, 2, reason: '$reason: icon gap');
          expect(
            button.left,
            tester.getRect(find.byType(Wrap)).right,
            reason: '$reason: the aside follows the content directly',
          );
        }
      },
    );

    testWidgets('the chevron toggles the popup and keeps focus in the field', (
      tester,
    ) async {
      // `useTagPickerControl`'s mousedown: `setOpen(!open)`, then focus the
      // field.
      await tester.pumpWidget(
        app(
          const FluentTagPicker<String>(
            key: key,
            options: options,
            onChanged: _noop,
          ),
        ),
      );
      Color chevronColor() => tester
          .widget<RichText>(
            find.descendant(
              of: find.byIcon(fluentTagPickerChevron),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!
          .color!;
      expect(chevronColor(), c.neutralStrokeAccessible);

      await tester.tap(find.byIcon(fluentTagPickerChevron));
      await tester.pumpAndSettle();
      expect(find.text('Katri'), findsOneWidget, reason: 'opened');
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.focusNode.hasFocus, isTrue);

      await tester.tap(find.byIcon(fluentTagPickerChevron));
      await tester.pumpAndSettle();
      expect(find.text('Katri'), findsNothing, reason: 'closed');
      expect(field.focusNode.hasFocus, isTrue);
      expect(
        chevronColor(),
        c.neutralStrokeAccessible,
        reason: 'no hover rule',
      );

      await tester.pumpWidget(
        app(const FluentTagPicker<String>(key: key, options: options)),
      );
      expect(chevronColor(), c.neutralForegroundDisabled);

      await tester.pumpWidget(
        app(
          const FluentTagPicker<String>(
            key: key,
            options: options,
            expandIcon: null,
            onChanged: _noop,
          ),
        ),
      );
      expect(find.byIcon(fluentTagPickerChevron), findsNothing);
    });

    testWidgets('a real mouse on the padding or the chevron band toggles', (
      tester,
    ) async {
      // Upstream toggles on a mousedown whose target is the root (its
      // padding), the aside or the expand icon — a 16px glyph centred in a
      // 32-tall span, so 8px above it is still the icon. Only the text field
      // opens without closing.
      await tester.pumpWidget(
        app(
          const FluentTagPicker<String>(
            key: key,
            options: options,
            onChanged: _noop,
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      Future<void> clickAt(Offset at) async {
        await mouse.moveTo(at);
        await tester.pump();
        await mouse.down(at);
        await tester.pump();
        await mouse.up();
        await tester.pumpAndSettle();
      }

      final chevron = tester.getRect(find.byIcon(fluentTagPickerChevron));
      final box = tester.getRect(find.byKey(key));
      for (final (where, at) in [
        ('above the chevron', Offset(chevron.center.dx, chevron.top - 4)),
        ('the left padding', Offset(box.left + 6, box.center.dy)),
      ]) {
        await clickAt(at);
        expect(find.text('Katri'), findsOneWidget, reason: '$where opens');
        await clickAt(at);
        expect(find.text('Katri'), findsNothing, reason: '$where closes');
      }
    });

    testWidgets('a real mouse: hover wins over focus, press moves the bar', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        app(
          FluentTagPicker<String>(
            key: key,
            focusNode: node,
            options: options,
            onChanged: _noop,
          ),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(borderPainter(tester).borderColor, c.neutralStroke1Pressed);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(borderPainter(tester).borderColor, c.neutralStroke1Hover);
      expect(
        borderPainter(tester).bottomBorderColor,
        c.neutralStrokeAccessibleHover,
      );

      await mouse.down(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(borderPainter(tester).borderColor, c.neutralStroke1Pressed);
      expect(
        tester
            .widget<FluentInputFocusUnderline>(
              find.byType(FluentInputFocusUnderline),
            )
            .color,
        c.compoundBrandStrokePressed,
      );
      await mouse.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a right press is not :active, as Chrome renders it', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const FluentTagPicker<String>(
            key: key,
            options: options,
            onChanged: _noop,
          ),
        ),
      );
      final at = tester.getCenter(find.byKey(key));
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await mouse.addPointer(location: at);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.down(at);
      await tester.pump();
      expect(borderPainter(tester).borderColor, c.neutralStroke1Hover);
      await mouse.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a press released after the picker is gone is harmless', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const FluentTagPicker<String>(
            key: key,
            options: options,
            onChanged: _noop,
          ),
        ),
      );
      final at = tester.getCenter(find.byKey(key));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: at);
      addTearDown(mouse.removePointer);
      await mouse.down(at);
      await tester.pump();
      await tester.pumpWidget(app(const SizedBox()));
      await mouse.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('re-enabled under a resting mouse, it hovers at once', (
      tester,
    ) async {
      // Chrome keeps a disabled root's `:hover`, so no new mouseenter is
      // needed once the picker is enabled again.
      Widget picker({required bool enabled}) => app(
        FluentTagPicker<String>(
          key: key,
          options: options,
          onChanged: enabled ? _noop : null,
        ),
      );
      await tester.pumpWidget(picker(enabled: false));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(borderPainter(tester).borderColor, c.neutralStrokeDisabled);
      await tester.pumpWidget(picker(enabled: true));
      await tester.pump();
      expect(borderPainter(tester).borderColor, c.neutralStroke1Hover);
    });

    testWidgets('a LayoutBuilder in a chip lays out without intrinsics', (
      tester,
    ) async {
      // A chip's label or media is the caller's widget, and a LayoutBuilder
      // cannot answer an intrinsic-size query.
      await tester.pumpWidget(
        app(
          FluentTagPicker<String>(
            key: key,
            options: <FluentTagPickerOption<String>>[
              FluentTagPickerOption<String>(
                value: 'kat',
                label: LayoutBuilder(builder: (_, _) => const Text('Katri')),
                text: 'Katri',
              ),
            ],
            selected: const <String>['kat'],
            onChanged: _noop,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Katri'), findsOneWidget);
    });

    testWidgets('a tight parent height stretches the box, bar and all', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const SizedBox(
            height: 60,
            child: FluentTagPicker<String>(
              key: key,
              options: options,
              onChanged: _noop,
            ),
          ),
        ),
      );
      final painted = find
          .descendant(
            of: find.byKey(key),
            matching: find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is FluentInputBorderPainter,
            ),
          )
          .first;
      final bar = find.descendant(
        of: find.byKey(key),
        matching: find.byType(FluentInputFocusUnderline),
      );
      expect(tester.getRect(painted).height, 60);
      expect(tester.getRect(bar).bottom, tester.getRect(painted).bottom);
    });

    testWidgets('a taller box centres the content; the chevron stays up', (
      tester,
    ) async {
      // components-tagpicker--default in Chrome with the control forced to
      // 60px: the root's `alignItems: center` puts the input's box 14 from
      // either border and a chip 20, while the expand icon's glyph stays 9
      // down. A minimum height taller than the content centres it the same
      // way. The chip is a LayoutBuilder, which no intrinsic pass may reach.
      final picker = FluentTagPicker<String>(
        key: key,
        options: <FluentTagPickerOption<String>>[
          ...options,
          FluentTagPickerOption<String>(
            value: 'lars',
            label: LayoutBuilder(builder: (_, _) => const Text('Lars')),
            text: 'Lars',
          ),
        ],
        selected: const <String>['lars'],
        onChanged: _noop,
      );
      for (final (why, child) in <(String, Widget)>[
        ('a tight parent', SizedBox(height: 60, child: picker)),
        (
          'a minimum height',
          FluentTagPickerTheme(
            style: const FluentTagPickerStyle(
              minimumSize: WidgetStatePropertyAll<Size?>(Size(0, 60)),
            ),
            child: picker,
          ),
        ),
      ]) {
        await tester.pumpWidget(app(child));
        expect(tester.takeException(), isNull, reason: why);
        final box = tester.getRect(find.byKey(key));
        expect(box.height, 60, reason: why);
        final chip = tester.getRect(find.byType(FluentTag));
        expect(chip.top - box.top, 20, reason: '$why: chip');
        expect(chip.bottom, box.bottom - 20, reason: '$why: chip');
        final field = tester.getRect(find.byType(EditableText));
        expect(field.center.dy, box.center.dy, reason: '$why: field');
        expect(
          tester.getRect(find.byIcon(fluentTagPickerChevron)).top - box.top,
          9,
          reason: '$why: chevron',
        );
      }
    });

    testWidgets('a click beside the field focuses it and keeps its text', (
      tester,
    ) async {
      // Upstream's control focuses the input from its mousedown with
      // `focus()`, which restores the caret rather than selecting the text a
      // blurred field still holds — a plain `requestFocus` trips
      // `selectAllOnFocus` on desktop and the web.
      final controller = TextEditingController(text: 'Be');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          FluentTagPicker<String>(
            key: key,
            options: options,
            controller: controller,
            onChanged: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final at = tester.getCenter(find.byIcon(fluentTagPickerChevron));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: at);
      addTearDown(mouse.removePointer);
      await mouse.down(at);
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();
      expect(
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .widget
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(controller.text, 'Be');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('Transparent is square; the bar overhangs it a pixel a side', (
      tester,
    ) async {
      for (final appearance in [
        FluentTagPickerAppearance.outline,
        FluentTagPickerAppearance.transparent,
      ]) {
        await tester.pumpWidget(
          app(
            FluentTagPicker<String>(
              key: key,
              appearance: appearance,
              options: options,
              onChanged: _noop,
            ),
          ),
        );
        final overhang = appearance == FluentTagPickerAppearance.transparent
            ? 1.0
            : 0.0;
        expect(
          borderPainter(tester).radius,
          overhang == 1 ? BorderRadius.zero : FluentRadius.allMedium,
        );
        final box = tester.getRect(find.byKey(key));
        final bar = find.byType(FluentInputFocusUnderline);
        expect(tester.getRect(bar).left, box.left - overhang);
        expect(tester.getRect(bar).right, box.right + overhang);
        expect(
          tester.widget<FluentInputFocusUnderline>(bar).borderRadius,
          const BorderRadius.vertical(bottom: FluentRadius.medium),
        );
      }
    });

    testWidgets(
      'the bottom colour meets the sides on the CSS corner diagonal',
      (tester) async {
        // See the same test in input_test.dart: device pixel (7, 4h − 6) is in
        // the ring below the 45° diagonal, (4, 4h − 8) the same arc above it.
        const boundary = Key('boundary');
        await tester.pumpWidget(
          app(
            const RepaintBoundary(
              key: boundary,
              child: FluentTagPicker<String>(
                key: key,
                options: options,
                onChanged: _noop,
              ),
            ),
          ),
        );
        const ratio = 4.0;
        final size = tester.getSize(find.byKey(boundary));
        final width = (size.width * ratio).round();
        final bottom = (size.height * ratio).round();
        final pixels = (await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(find.byKey(boundary))
              .toImage(pixelRatio: ratio);
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          image.dispose();
          return data;
        }))!;
        void expectPixel(int x, int y, Color expected, String reason) {
          final i = (y * width + x) * 4;
          final actual = [for (var k = 0; k < 3; k++) pixels.getUint8(i + k)];
          final want = [
            for (final channel in [expected.r, expected.g, expected.b])
              (channel * 255).round(),
          ];
          for (var k = 0; k < 3; k++) {
            expect(
              actual[k],
              closeTo(want[k], 3),
              reason: '$reason: got $actual, want $want',
            );
          }
        }

        expectPixel(7, bottom - 6, c.neutralStrokeAccessible, 'below: #616161');
        expectPixel(4, bottom - 8, c.neutralStroke1, 'above: #d1d1d1');
      },
    );

    testWidgets('chips follow upstream\'s size and appearance mapping', (
      tester,
    ) async {
      // `tagPickerSizeToTagSize` and `tagPickerAppearanceToTagAppearance`.
      const sizes = {
        FluentTagPickerSize.medium: FluentTagSize.extraSmall,
        FluentTagPickerSize.large: FluentTagSize.small,
        FluentTagPickerSize.extraLarge: FluentTagSize.medium,
      };
      for (final entry in sizes.entries) {
        for (final appearance in FluentTagPickerAppearance.values) {
          await tester.pumpWidget(
            app(
              FluentTagPicker<String>(
                key: key,
                size: entry.key,
                appearance: appearance,
                options: options,
                selected: const <String>['kat'],
                onChanged: _noop,
              ),
            ),
          );
          final tag = tester.widget<FluentTag>(find.byType(FluentTag));
          expect(tag.size, entry.value, reason: entry.key.name);
          expect(
            tag.appearance,
            appearance == FluentTagPickerAppearance.filledDarker
                ? FluentTagAppearance.outline
                : FluentTagAppearance.filled,
            reason: appearance.name,
          );
        }
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Geometry upstream states and the Figma fixture is silent about.
  // ---------------------------------------------------------------------------

  group('geometry', () {
    FluentTagPickerStyle styleForSize(FluentTagPickerSize size) =>
        resolveFluentTagPickerStyle(
          resolveFluentTagPickerState(
            field: const SizedBox.shrink(),
            size: size,
          ),
          light,
        );

    const none = <WidgetState>{};

    test('the chip gap ramps 4 / 6 / 6 with the size', () {
      // `useTagPickerGroupStyles`: `medium: { gap: spacingHorizontalXS }`, and
      // `large` and `'extra-large'` BOTH `spacingHorizontalSNudge`. The ramp
      // stops at large — extra-large repeats 6 rather than going on to 8, which
      // is the whole point of asserting the last stop separately.
      // The Figma Rest variants hold no tags, so the fixture records no
      // chip-to-chip spacing to contradict it — the 2 it does bind on
      // `Start content` is the group↔input gap, not this one.
      expect(
        styleForSize(FluentTagPickerSize.medium).tagSpacing!.resolve(none),
        FluentSpacing.xs,
      );
      expect(
        styleForSize(FluentTagPickerSize.large).tagSpacing!.resolve(none),
        FluentSpacing.sNudge,
      );
      expect(
        styleForSize(FluentTagPickerSize.extraLarge).tagSpacing!.resolve(none),
        FluentSpacing.sNudge,
        reason: 'extra-large shares large\'s gap upstream, it does not grow',
      );
    });

    test('the control carries upstream\'s 250px minimum width', () {
      // `useTagPickerControlStyles` root: `minWidth: '250px'`, at every size.
      // Figma draws all 72 variants at a fixed 320 — a design width, not a
      // minimum — so it does not contradict this.
      for (final size in FluentTagPickerSize.values) {
        expect(
          styleForSize(size).minimumSize!.resolve(none)!.width,
          250,
          reason: size.name,
        );
      }
    });

    testWidgets(
      'the popup sits 2px below the control and clamps to the room left, capped at 80vh',
      (tester) async {
        // `useTagPicker`'s `usePositioning({ offset: { mainAxis: 2 } })` and
        // `useTagPickerListStyles`' `maxHeight: '80vh'`. Figma models Expanded as
        // one merged frame with no separate popup node, so it states neither.
        await tester.pumpWidget(
          app(
            FluentTagPicker<String>(
              key: key,
              options: options,
              autofocus: true,
              onChanged: (_) {},
            ),
          ),
        );
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        final control = find.byKey(key);
        // The height-clamping box specifically: the popup is also wrapped in a
        // `minWidth: 160` ConstrainedBox further out, which caps nothing.
        final surface = find
            .ancestor(
              of: find.text('Katri'),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is ConstrainedBox &&
                    widget.constraints.maxHeight.isFinite,
              ),
            )
            .last;
        expect(
          tester.getTopLeft(surface).dy - tester.getBottomLeft(control).dy,
          FluentSpacing.xxs,
        );

        // 80vh is upstream's CAP, not the whole rule. On its own it says nothing
        // about where the control sits, so a picker low on the page threw most of
        // its list off the bottom of the screen. The room actually left below the
        // control is the other half of the constraint.
        final viewport =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        final room = viewport - tester.getBottomLeft(control).dy;
        expect(
          room,
          lessThan(viewport * 0.8),
          reason: 'else this proves nothing',
        );
        expect(
          tester.widget<ConstrainedBox>(surface).constraints.maxHeight,
          math.min(viewport * 0.8, room),
        );
      },
    );

    testWidgets('re-measures its max height when the page scrolls under it', (
      tester,
    ) async {
      // `min(80vh, room below)` was measured once at open, and the entry lives
      // in the Overlay, so nothing rebuilt it when the page moved: a picker
      // opened a row tall against the bottom edge stayed that tall after the
      // page carried it back to the top, with the whole viewport free beneath
      // it. `@fluentui/react-positioning` repositions on scroll rather than
      // closing, so the entry re-measures.
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            controller: scrollController,
            child: const Column(
              children: <Widget>[
                SizedBox(height: 900, child: Text('above')),
                FluentTagPicker<String>(
                  key: key,
                  options: options,
                  autofocus: true,
                  onChanged: _noop,
                ),
                SizedBox(height: 900),
              ],
            ),
          ),
        ),
      );
      // Puts the control 540 down a 600 viewport: about one row of room left.
      scrollController.jumpTo(360);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // The height-clamping box specifically, as above.
      final surface = find.descendant(
        of: find.byType(CompositedTransformFollower),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox && widget.constraints.maxHeight.isFinite,
        ),
      );
      expect(surface, findsOneWidget);
      double cap() =>
          tester.widget<ConstrainedBox>(surface).constraints.maxHeight;

      final opened = cap();
      expect(opened, lessThan(40), reason: 'else this proves nothing');

      // A wheel, not a drag: `TapRegion` cannot tell a drag from a tap, so a
      // touch drag dismisses (see `pointer dismissal`), and `jumpTo` never
      // flips `isScrollingNotifier`, which the rebuild is gated on. 300 keeps
      // the room below under 80vh, so this measures the clamp and not the cap.
      // Read after opening: autofocus lets `EditableText` bring its caret on
      // screen, which may legitimately move the offset first.
      final before = scrollController.offset;
      final wheel = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        wheel.hover(tester.getCenter(find.text('above'))),
      );
      await tester.sendEventToBinding(wheel.scroll(const Offset(0, 300)));
      await tester.pumpAndSettle();

      expect(find.text('Ben'), findsOneWidget, reason: 'still open');
      // Without this the assertion below reads 0 == 0 and proves nothing.
      expect(scrollController.offset - before, 300);
      expect(
        cap() - opened,
        moreOrLessEquals(scrollController.offset - before, epsilon: 0.5),
        reason: 'every pixel the control climbed is a pixel of room below it',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Motion, and the absence of it.
  // ---------------------------------------------------------------------------

  group('motion', () {
    test('the accent bar reuses the input specs verbatim', () {
      expect(fluentTagPickerAccentEnter, fluentInputFocusUnderlineEnter);
      expect(fluentTagPickerAccentExit, fluentInputFocusUnderlineExit);
      expect(fluentTagPickerAccentEnter.duration, FluentDuration.normal);
      expect(fluentTagPickerAccentEnter.curve, FluentCssCubic.ease);
      expect(fluentTagPickerAccentExit.duration, FluentDuration.ultraFast);
      expect(fluentTagPickerAccentExit.curve, FluentCssCubic.ease);
    });

    double barScale(WidgetTester tester) {
      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byType(FluentInputFocusUnderline),
          matching: find.byType(Transform),
        ),
      );
      return transform.transform.getColumn(0)[0];
    }

    testWidgets('the bar grows over durationNormal', (tester) async {
      await tester.pumpWidget(
        app(
          FluentTagPicker<String>(
            key: key,
            options: options,
            onChanged: (_) {},
          ),
        ),
      );
      expect(barScale(tester), 0);

      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(barScale(tester), lessThan(1));
      await tester.pump(FluentDuration.normal);
      expect(barScale(tester), 1);
    });

    testWidgets('reduced motion lands the bar on the first frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          FluentTagPicker<String>(
            key: key,
            options: options,
            onChanged: (_) {},
          ),
          reducedMotion: true,
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(barScale(tester), 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Theming.
  // ---------------------------------------------------------------------------

  group('theming', () {
    testWidgets('a subtree FluentThemeOverride reaches the control', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const FluentThemeOverride(
            colors: <FluentColorToken, Color>{
              FluentColorToken.neutralBackground1: Color(0xFF780510),
            },
            child: FluentTagPicker<String>(
              key: key,
              options: options,
              onChanged: _noop,
            ),
          ),
        ),
      );

      final decoration = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((decoration) => decoration.color != null);
      expect(decoration.color, const Color(0xFF780510));
      expect(decoration.color, isNot(light.colors.neutralBackground1));
    });

    testWidgets('FluentTagPickerTheme sits between the defaults and style', (
      tester,
    ) async {
      const override = Color(0xFF00FF00);
      await tester.pumpWidget(
        app(
          FluentTagPickerTheme(
            style: FluentTagPickerStyle.from(backgroundColor: override),
            child: FluentTagPicker<String>(
              key: key,
              options: options,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final decoration = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((decoration) => decoration.color != null);
      expect(decoration.color, override);
    });
  });

  // ---------------------------------------------------------------------------
  // High contrast. The mode nobody looks at, and the one where an inverted
  // foreground silently equals the surface it sits on.
  // ---------------------------------------------------------------------------

  group('high contrast', () {
    for (final theme in <(String, FluentThemeData)>[
      ('light', light),
      ('dark', dark),
      ('high contrast', highContrast),
    ]) {
      for (final appearance in FluentTagPickerAppearance.values) {
        for (final enabled in <bool>[true, false]) {
          test('no foreground matches its own background — '
              '${theme.$1}, ${appearance.name}, enabled=$enabled', () {
            final style = resolveFluentTagPickerStyle(
              resolveFluentTagPickerState(
                field: const SizedBox.shrink(),
                appearance: appearance,
                enabled: enabled,
              ),
              theme.$2,
            );
            const states = <WidgetState>{};
            final background = style.backgroundColor!.resolve(states)!;
            // A transparent control paints on the app surface, so that is the
            // colour its text actually has to survive.
            final surface = background.a == 0
                ? theme.$2.colors.neutralBackground1
                : background;

            for (final pair in <(String, Color)>[
              ('foreground', style.foregroundColor!.resolve(states)!),
              ('placeholder', style.placeholderColor!.resolve(states)!),
              ('secondary', style.secondaryColor!.resolve(states)!),
            ]) {
              expect(
                pair.$2.toARGB32(),
                isNot(surface.toARGB32()),
                reason:
                    '${pair.$1} is invisible on the ${appearance.name} '
                    'surface in ${theme.$1}',
              );
            }
          });
        }
      }

      test('the popup row survives its own surface — ${theme.$1}', () {
        final style = resolveFluentTagPickerStyle(
          resolveFluentTagPickerState(field: const SizedBox.shrink()),
          theme.$2,
        );
        const states = <WidgetState>{};
        final surface = style.surfaceColor!.resolve(states)!;

        for (final rowStates in <Set<WidgetState>>[
          <WidgetState>{},
          <WidgetState>{WidgetState.hovered},
          <WidgetState>{WidgetState.pressed},
        ]) {
          final row = resolveFluentTagPickerOptionStyle(
            resolveFluentDropdownOptionState(label: const Text('x')),
            theme.$2,
          );
          final background = row.backgroundColor!.resolve(rowStates)!;
          final foreground = row.foregroundColor!.resolve(rowStates)!;
          expect(
            foreground.toARGB32(),
            isNot(background.toARGB32()),
            reason: 'row label is invisible in ${theme.$1} for $rowStates',
          );
          if (background.a == 0) {
            expect(
              foreground.toARGB32(),
              isNot(surface.toARGB32()),
              reason: 'row label is invisible on the popup in ${theme.$1}',
            );
          }
        }
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Disabled is a real state.
  // ---------------------------------------------------------------------------

  group('disabled', () {
    testWidgets('refuses the popup, edits and focus', (tester) async {
      await tester.pumpWidget(
        app(
          const FluentTagPicker<String>(
            key: key,
            options: options,
            selected: <String>['kat'],
          ),
        ),
      );

      final input = tester.widget<FluentInput>(find.byType(FluentInput));
      expect(input.enabled, isFalse);

      // Upstream's disabled story keeps each chip's dismiss glyph, greyed.
      final tag = tester.widget<FluentTag>(find.byType(FluentTag));
      expect(tag.enabled, isFalse);
      expect(find.byType(FluentTagDismissGlyph), findsOneWidget);

      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(find.text('Ben'), findsNothing);
    });

    testWidgets('reports itself disabled to assistive technology', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const FluentTagPicker<String>(
            key: key,
            options: options,
            semanticLabel: 'Assignees',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Assignees',
          hasEnabledState: true,
          hasExpandedState: true,
        ),
      );
      handle.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // Keyboard.
  // ---------------------------------------------------------------------------

  group('keyboard', () {
    testWidgets('Backspace on an empty field removes the last chip', (
      tester,
    ) async {
      var selected = <String>['kat', 'ben'];
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => FluentTagPicker<String>(
              key: key,
              options: options,
              selected: selected,
              autofocus: true,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(selected, <String>['kat']);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(selected, isEmpty);
    });

    testWidgets('Backspace with text falls through to the character delete', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Ka');
      addTearDown(controller.dispose);
      var selected = <String>['kat'];
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => FluentTagPicker<String>(
              key: key,
              options: options,
              selected: selected,
              controller: controller,
              autofocus: true,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      );
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(selected, <String>['kat'], reason: 'the chip must survive');
      expect(controller.text, 'K');
    });

    testWidgets('Down opens, Enter commits, and the chip appears', (
      tester,
    ) async {
      var selected = <String>[];
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => FluentTagPicker<String>(
              key: key,
              options: options,
              selected: selected,
              autofocus: true,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, <String>['kat']);
      expect(find.byType(FluentTag), findsOneWidget);

      // The field is still the one taking keys, as upstream's input is.
      tester.testTextInput.enterText('B');
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('only a printable key reopens a closed list', (tester) async {
      // Upstream opens on `getDropdownActionFromKey(...) === 'Type'`: one
      // printable character, not Space, with no Alt, Ctrl or Meta. Measured
      // in Chrome: Space lands in the input and Backspace deletes it with the
      // list still shut; a letter or a digit opens it. A desktop embedder
      // reports Backspace as the control character it is, which is not
      // typing either.
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          FluentTagPicker<String>(
            key: key,
            options: options,
            controller: controller,
            autofocus: true,
            onChanged: _noop,
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      tester.testTextInput.enterText(' ');
      await tester.pumpAndSettle();
      expect(controller.text, ' ');
      expect(find.text('Ben'), findsNothing, reason: 'Space');

      await tester.sendKeyEvent(
        LogicalKeyboardKey.backspace,
        character: '\x7f',
      );
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(find.text('Ben'), findsNothing, reason: 'Backspace');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsNothing, reason: 'Meta+V');

      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsOneWidget, reason: 'a letter');
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('typing makes the first option starting with it active', (
      tester,
    ) async {
      // `useInputTriggerSlot`'s `getOptionFromInput`, measured on
      // components-tagpicker--default: 'm' and 'ma' make Max Mustermann
      // active over the John Doe the list opened on, Enter adds him; text
      // that starts no option leaves nothing active, and Enter adds nothing.
      for (final (typed, added) in <(String, List<String>)>[
        ('b', <String>['ben']),
        ('BE ', <String>['ben']),
        ('x', <String>[]),
      ]) {
        var selected = <String>[];
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          app(
            StatefulBuilder(
              builder: (context, setState) => FluentTagPicker<String>(
                key: key,
                options: options,
                selected: selected,
                autofocus: true,
                onChanged: (value) => setState(() => selected = value),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
        tester.testTextInput.enterText(typed);
        await tester.pumpAndSettle();
        expect(find.text('Ben'), findsOneWidget, reason: typed);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(selected, added, reason: typed);
        expect(find.text('Ben'), added.isEmpty ? findsNothing : findsOneWidget);
      }
    });

    testWidgets('a type-ahead match shows its ring after a mouse open', (
      tester,
    ) async {
      // components-tagpicker--default in Chrome: a click opens the list with
      // no ring on John Doe; typing 'm' puts
      // `data-activedescendant-focusvisible` on Max Mustermann. The flag is
      // process-wide, and an earlier test's key press would otherwise leak in.
      FluentInputModality.debugReset();
      await tester.pumpWidget(
        app(
          const FluentTagPicker<String>(
            key: key,
            options: options,
            onChanged: _noop,
          ),
        ),
      );
      final at = tester.getCenter(find.byType(EditableText));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: at);
      addTearDown(mouse.removePointer);
      await mouse.down(at);
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();
      bool ringOn(String label) => tester
          .widget<FluentFocusRing>(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(FluentFocusRing),
                )
                .first,
          )
          .visible;
      expect(ringOn('Katri'), isFalse, reason: 'opened by the mouse');

      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      tester.testTextInput.enterText('b');
      await tester.pumpAndSettle();
      expect(ringOn('Ben'), isTrue);
      expect(ringOn('Katri'), isFalse);
    });

    testWidgets('an open list follows options filtered by the typed text', (
      tester,
    ) async {
      // components-tagpicker--filtering: the list the caller filters on each
      // keystroke is the one on screen. When no option starts with the text,
      // the new list's first option is active, as upstream's fallback on a
      // children change makes it.
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final filtered = <FluentTagPickerOption<String>>[...options];
      controller.addListener(() {
        final query = controller.text.toLowerCase();
        filtered
          ..clear()
          ..addAll(<FluentTagPickerOption<String>>[
            for (final option in options)
              if (!option.isHeader &&
                  option.text!.toLowerCase().contains(query))
                option,
          ]);
      });
      var selected = <String>[];
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => FluentTagPicker<String>(
              key: key,
              options: filtered,
              controller: controller,
              selected: selected,
              autofocus: true,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pumpAndSettle();
      expect(find.text('Katri'), findsOneWidget, reason: 'opened on the key');
      tester.testTextInput.enterText('e');
      await tester.pumpAndSettle();
      expect(find.text('Katri'), findsNothing);
      expect(find.text('Ben'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, <String>['ben']);
    });

    testWidgets('a caller filtering through setState keeps the match active', (
      tester,
    ) async {
      // The same filtering, but the idiomatic way: the caller rebuilds the
      // picker with a fresh list after the picker has already matched the
      // text against the old one. Upstream tracks the active option, not its
      // row: 'mar' is Mario Rossi however the rows moved, and a 'd' no name
      // starts with falls back to the filtered list's first row
      // (components-tagpicker--filtering in Chrome).
      const names = <String>[
        'John Doe',
        'Jane Doe',
        'Max Mustermann',
        'Erika Mustermann',
        'Pierre Dupont',
        'Amelie Dupont',
        'Mario Rossi',
        'Maria Rossi',
      ];
      for (final (typed, added) in <(String, String)>[
        ('mar', 'Mario Rossi'),
        ('d', 'John Doe'),
      ]) {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        var selected = <String>[];
        late StateSetter rebuild;
        controller.addListener(() => rebuild(() {}));
        await tester.pumpWidget(const SizedBox());
        // The last round's Enter would otherwise leave the keyboard flag up.
        FluentInputModality.debugReset();
        await tester.pumpWidget(
          app(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                final query = controller.text.trim().toLowerCase();
                return FluentTagPicker<String>(
                  key: key,
                  controller: controller,
                  options: <FluentTagPickerOption<String>>[
                    for (final name in names)
                      if (name.toLowerCase().contains(query))
                        FluentTagPickerOption<String>(
                          value: name,
                          label: Text(name),
                        ),
                  ],
                  selected: selected,
                  autofocus: true,
                  onChanged: (value) => setState(() => selected = value),
                );
              },
            ),
          ),
        );
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
        await tester.pumpAndSettle();
        for (var i = 1; i <= typed.length; i++) {
          tester.testTextInput.enterText(typed.substring(0, i));
          await tester.pumpAndSettle();
        }
        // Printable keys leave the keyboard modality alone; the match is
        // focus-visible all the same, as upstream's is.
        final ring = tester.widget<FluentFocusRing>(
          find
              .ancestor(
                of: find.text(added),
                matching: find.byType(FluentFocusRing),
              )
              .first,
        );
        expect(ring.visible, isTrue, reason: '$typed: ring');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(selected, <String>[added], reason: typed);
      }
    });

    testWidgets('a chip removed under the open list is not filtering', (
      tester,
    ) async {
      // Only a list that changed with the keystroke falls back to its first
      // row. A chip Backspace removed changes the rows too; text typed after
      // it that starts no option must still leave nothing to add.
      var selected = <String>['kat', 'ben'];
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => FluentTagPicker<String>(
              key: key,
              options: options,
              selected: selected,
              autofocus: true,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(selected, <String>['kat']);
      expect(find.text('Ben'), findsOneWidget, reason: 'the list stays open');

      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      tester.testTextInput.enterText('x');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, <String>['kat']);
    });

    testWidgets('Escape closes without selecting', (tester) async {
      var selected = <String>[];
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => FluentTagPicker<String>(
              key: key,
              options: options,
              selected: selected,
              autofocus: true,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsNothing);
      expect(selected, isEmpty);
    });

    testWidgets('an already chosen value drops out of the list', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          FluentTagPicker<String>(
            key: key,
            options: options,
            selected: const <String>['kat'],
            autofocus: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Once in the control as a chip, never again in the popup.
      expect(find.text('Katri'), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Pointer dismissal.
  //
  // The popup used to paint a full-screen `HitTestBehavior.opaque` barrier from
  // inside its OverlayEntry to catch outside taps. It caught everything else
  // too: a click on a control behind an open list dismissed the list and did
  // nothing else, hover never arrived, and no wheel event reached the enclosing
  // Scrollable, so the page could not scroll. Upstream's `useOnClickOutside` is
  // a document-level listener — the click dismisses AND lands — and a
  // `TapRegion` group is the framework's version of that.
  // ---------------------------------------------------------------------------

  group('pointer dismissal', () {
    /// A real mouse click: press, let a frame or two pass, release.
    ///
    /// `tester.tap` fires both ends without a frame in between, which hides
    /// anything that tears the target down on pointer-DOWN — and that is
    /// exactly the class of failure this group exists to catch. The device kind
    /// matters as much: `EditableText` drops focus on a pointer-down outside
    /// itself for every kind except touch (`editable_text.dart:6876`), so a
    /// touch-only suite never exercises the desktop path this package ships on.
    Future<void> click(WidgetTester tester, Finder target) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.down(tester.getCenter(target));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await mouse.up();
      await tester.pumpAndSettle();
    }

    Future<void> openWith(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(app(child));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsOneWidget);
    }

    testWidgets('an outside click dismisses AND lands on what is behind it', (
      tester,
    ) async {
      var taps = 0;
      var hovers = 0;
      await openWith(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MouseRegion(
              onEnter: (_) => hovers++,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(height: 40, child: Text('behind')),
              ),
            ),
            const FluentTagPicker<String>(
              key: key,
              options: options,
              autofocus: true,
              onChanged: _noop,
            ),
          ],
        ),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('behind')));
      await tester.pump();
      expect(hovers, 1, reason: 'the barrier swallowed hover as well');

      await mouse.down(tester.getCenter(find.text('behind')));
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();

      expect(find.text('Ben'), findsNothing, reason: 'the click must dismiss');
      expect(taps, 1, reason: 'and the same click must land');
    });

    testWidgets('clicking the field while open neither closes nor reopens', (
      tester,
    ) async {
      // Dead code until the barrier came out: the barrier sat above the whole
      // control, so the field's own pointer handlers could never fire while the
      // popup was up. Both of them route into `_openPopup`, which no-ops on an
      // already-open picker — the list must survive untouched, not be torn down
      // and rebuilt, because the field is a text input and this click is a
      // caret placement.
      await openWith(
        tester,
        const FluentTagPicker<String>(
          key: key,
          options: options,
          autofocus: true,
          onChanged: _noop,
        ),
      );
      final before = tester.element(find.text('Ben'));

      await click(tester, find.byType(EditableText));

      expect(find.text('Ben'), findsOneWidget);
      expect(
        tester.element(find.text('Ben')),
        same(before),
        reason: 'a close-then-reopen would rebuild the overlay from scratch',
      );
    });

    testWidgets('a mouse click on a row still selects it', (tester) async {
      var selected = <String>[];
      await openWith(
        tester,
        StatefulBuilder(
          builder: (context, setState) => FluentTagPicker<String>(
            key: key,
            options: options,
            selected: selected,
            autofocus: true,
            onChanged: (value) => setState(() => selected = value),
          ),
        ),
      );

      await click(tester, find.text('Ben'));

      expect(selected, <String>['ben']);
    });

    testWidgets(
      'a mouse pick keeps the field focused, and typing reopens the list',
      (tester) async {
        // Upstream, measured in Chrome: after the first pick the list closes,
        // the input keeps focus, and a typed character lands in it and opens
        // the list again.
        final node = FocusNode();
        addTearDown(node.dispose);
        var selected = <String>[];
        await tester.pumpWidget(
          app(
            StatefulBuilder(
              builder: (context, setState) => FluentTagPicker<String>(
                key: key,
                options: options,
                selected: selected,
                focusNode: node,
                onChanged: (value) => setState(() => selected = value),
              ),
            ),
          ),
        );

        await click(tester, find.byKey(key));
        expect(find.text('Ben'), findsOneWidget, reason: 'the click opened');
        await click(tester, find.text('Katri'));
        expect(selected, <String>['kat']);
        expect(node.hasFocus, isTrue, reason: 'the pick kept focus');
        expect(find.text('Ben'), findsNothing, reason: 'the pick closed');

        // A keystroke is its key event, then the text it inserts.
        await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
        tester.testTextInput.enterText('Be');
        await tester.pumpAndSettle();
        expect(find.text('Be'), findsOneWidget, reason: 'typed into the field');
        expect(find.text('Ben'), findsOneWidget, reason: 'typing reopened');
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );

    testWidgets(
      "a click on a chip's body dismisses it and leaves the list shut",
      (tester) async {
        // Upstream's dismissible `Tag` is one `<button>`: a left click
        // anywhere on it dismisses (Chrome), and the control's mousedown
        // toggle skips it, because it only fires on the root, the group
        // itself, the aside and the expand icon. The body shows the arrow.
        // Middle and right clicks do nothing.
        var selected = <String>['kat', 'ben'];
        await tester.pumpWidget(
          app(
            StatefulBuilder(
              builder: (context, setState) => FluentTagPicker<String>(
                key: key,
                options: options,
                selected: selected,
                onChanged: (value) => setState(() => selected = value),
              ),
            ),
          ),
        );

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: tester.getCenter(find.text('Katri')));
        addTearDown(mouse.removePointer);
        await tester.pump();
        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          SystemMouseCursors.basic,
        );

        for (final buttons in <int>[kMiddleMouseButton, kSecondaryButton]) {
          final other = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: buttons,
          );
          await other.down(tester.getCenter(find.text('Ben')));
          await tester.pump();
          await other.up();
          await tester.pumpAndSettle();
          expect(selected, <String>['kat', 'ben'], reason: 'buttons $buttons');
          expect(find.text('Ola'), findsNothing, reason: 'buttons $buttons');
        }

        await click(tester, find.text('Katri'));
        expect(selected, <String>['ben']);
        expect(find.text('Ola'), findsNothing, reason: 'the list stays shut');
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );

    testWidgets('a chip dismiss counts as inside: chip goes, list stays', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var selected = <String>['kat'];
      await openWith(
        tester,
        StatefulBuilder(
          builder: (context, setState) => FluentTagPicker<String>(
            key: key,
            options: options,
            selected: selected,
            autofocus: true,
            dismissSemanticLabel: 'Remove Katri',
            onChanged: (value) => setState(() => selected = value),
          ),
        ),
      );

      await click(tester, find.bySemanticsLabel('Remove Katri'));

      expect(selected, isEmpty);
      expect(
        find.text('Ben'),
        findsOneWidget,
        reason: 'removing a chip must not collapse the list being picked from',
      );
      handle.dispose();
    });

    testWidgets('the page behind still scrolls with the popup open', (
      tester,
    ) async {
      // The third symptom the barrier caused, and the one the other tests in
      // this group do not reach: an opaque `Positioned.fill` is the first hit
      // in the Overlay's reverse-order hit test, so the page's `Scrollable`
      // was never in the path and no `PointerScrollEvent` reached it. A wheel
      // is not a `PointerDownEvent`, so it must scroll WITHOUT dismissing.
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            controller: scrollController,
            child: const Column(
              children: <Widget>[
                SizedBox(height: 400, child: Text('above')),
                FluentTagPicker<String>(
                  key: key,
                  options: options,
                  autofocus: true,
                  onChanged: _noop,
                ),
                SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsOneWidget);

      // Read after opening: autofocus lets `EditableText` bring its caret on
      // screen, which legitimately moves this offset before the wheel turns.
      final before = scrollController.offset;
      final wheel = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        wheel.hover(tester.getCenter(find.text('above'))),
      );
      await tester.sendEventToBinding(wheel.scroll(const Offset(0, 120)));
      await tester.pump();

      expect(
        scrollController.offset,
        greaterThan(before),
        reason: 'the barrier swallowed the wheel too',
      );
      expect(
        find.text('Ben'),
        findsOneWidget,
        reason: 'a wheel is not a tap and must not dismiss',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Semantics.
  // ---------------------------------------------------------------------------

  testWidgets('a chip announces its own dismiss affordance', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        FluentTagPicker<String>(
          key: key,
          options: options,
          selected: const <String>['kat'],
          dismissSemanticLabel: 'Remove Katri',
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Remove Katri'), findsOneWidget);
    handle.dispose();
  });

  // `useTagPicker.ts` passes `matchTargetSize: 'width'` and the popup renders a
  // `Listbox`, whose `useListboxStyles` carries `minWidth: '160px'`. Ours was
  // trigger-matched with no floor; `dropdown.dart` already pairs the two.
  testWidgets('the popup never renders narrower than 160', (tester) async {
    await tester.pumpWidget(
      FluentApp(
        theme: light,
        home: const Center(
          child: SizedBox(
            width: 80,
            child: FluentTagPicker<String>(
              key: key,
              options: options,
              onChanged: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FluentInput));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(find.text('Katri'), findsOneWidget);
    // The popup surface: the `ExcludeFocus` the rows are built inside.
    expect(
      tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Katri'),
                  matching: find.byType(ExcludeFocus),
                )
                .first,
          )
          .width,
      greaterThanOrEqualTo(160),
    );
  });
}
