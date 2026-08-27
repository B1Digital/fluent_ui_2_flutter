/// `FluentTagPicker` is three components in a trench coat — a surface, a
/// `FluentInput` with its chrome switched off, and an overlay list of rows
/// rendered by `buildFluentDropdownOption` — so these tests cover all three:
/// the token table against the Figma `Tag picker/TagPicker` set, the widgets it
/// actually composes, and the keyboard contract that ties them together.
library;

import 'dart:math' as math;

import 'package:fluent_2/fluent_2.dart';
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
  // Figma fidelity: every one of the 72 variants.
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

    for (final variant in spec.variants) {
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

        // 68 of the 72 `Input` nodes bind `Corner-radius/Input/Medium`; the
        // four exceptions are pinned by the test below rather than ported.
        expect(
          style.borderRadius!.resolve(states),
          FluentRadius.allMedium,
          reason: '${variant.name}: radius',
        );

        expect(
          style.minimumSize!.resolve(states)!.height,
          input.size.height,
          reason: '${variant.name}: control height',
        );
      });
    }

    // The border and the resting rule are asserted where Figma is internally
    // consistent. `Size=Large` and `Size=Extra large` bind
    // `Neutral/Stroke/1/Rest` and `Neutral/Stroke/Accessible/Rest` in EVERY
    // state — the ramp is simply not authored there — so only Medium can speak
    // for Hover, Pressed and Focused. See doc/token-divergences.md.
    for (final variant in spec.variants) {
      final ramped =
          variant.props['State'] != 'Rest' &&
          variant.props['State'] != 'Disabled';
      if (ramped && variant.props['Size'] != 'Medium') continue;

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
      // and Extra large included — bind `Corner-radius/Input/Medium`. Ported as
      // 4 everywhere; the frame around each of those six still states 4.
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

    testWidgets('chips are FluentInteractionTags', (tester) async {
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
      expect(find.byType(FluentInteractionTag), findsNWidgets(2));
      expect(find.text('Katri'), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
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
      // 48, from the Figma `TagPicker/Item` set — not `.ListItem`'s 32.
      expect(tester.getSize(row).height, 48);
    });

    test('rows resolve against the shared FluentDropdownOptionStyle', () {
      final style = resolveFluentTagPickerOptionStyle(
        resolveFluentDropdownOptionState(label: const Text('x')),
        light,
      );
      expect(style, isA<FluentDropdownOptionStyle>());
      expect(style.minimumSize!.resolve(const <WidgetState>{})!.height, 48);
      expect(style.gap!.resolve(const <WidgetState>{}), FluentSpacing.s);
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
  });

  // ---------------------------------------------------------------------------
  // Motion, and the absence of it.
  // ---------------------------------------------------------------------------

  group('motion', () {
    test('the accent bar reuses the input specs verbatim', () {
      expect(fluentTagPickerAccentEnter, fluentInputFocusUnderlineEnter);
      expect(fluentTagPickerAccentExit, fluentInputFocusUnderlineExit);
      expect(fluentTagPickerAccentEnter.duration, FluentDuration.normal);
      expect(fluentTagPickerAccentEnter.curve, FluentCurve.decelerateMid);
      expect(fluentTagPickerAccentExit.duration, FluentDuration.ultraFast);
      expect(fluentTagPickerAccentExit.curve, FluentCurve.accelerateMid);
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

      final tag = tester.widget<FluentInteractionTag>(
        find.byType(FluentInteractionTag),
      );
      expect(tag.onPressed, isNull);
      expect(tag.onDismiss, isNull);

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
      expect(find.byType(FluentInteractionTag), findsOneWidget);
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
