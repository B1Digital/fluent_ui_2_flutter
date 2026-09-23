import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentDropdown` is a closed trigger plus an overlay list, so these tests
/// cover both halves: the trigger against upstream as it renders in Chrome
/// (and the Figma `Dropdown` set where the two agree), the rows against
/// `.ListItem`, and the keyboard contract that ties them together.
void main() {
  const key = Key('dropdown');

  const options = <FluentDropdownOption<String>>[
    FluentDropdownOption<String>.header(
      label: Text('Nordics'),
      text: 'Nordics',
    ),
    FluentDropdownOption<String>(
      value: 'osl',
      label: Text('Oslo'),
      text: 'Oslo',
    ),
    FluentDropdownOption<String>(
      value: 'hel',
      label: Text('Helsinki'),
      text: 'Helsinki',
    ),
    FluentDropdownOption<String>(
      value: 'rvk',
      label: Text('Reykjavik'),
      text: 'Reykjavik',
      enabled: false,
    ),
    FluentDropdownOption<String>(
      value: 'lis',
      label: Text('Lisbon'),
      text: 'Lisbon',
    ),
  ];

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget dropdown, {
    FluentThemeData? theme,
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light(),
      builder: reducedMotion
          ? (context, child) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: child!,
            )
          : null,
      // A dropdown fills its parent's width, so every test pins one.
      home: Center(child: SizedBox(width: 312, child: dropdown)),
    ),
  );

  /// The trigger's own decorated surface. First in tree order, ahead of the
  /// accent rule's own box.
  BoxDecoration triggerDecoration(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  /// The trigger's border, painted the way `FluentInput` paints its own.
  FluentInputBorderPainter borderPainter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((p) => p.painter)
      .whereType<FluentInputBorderPainter>()
      .single;

  /// Every solid colour painted under the trigger, surface and rules alike.
  List<Color> triggerColors(WidgetTester tester) => <Color>[
    for (final box in tester.widgetList<DecoratedBox>(
      find.descendant(of: find.byKey(key), matching: find.byType(DecoratedBox)),
    ))
      if (box.decoration case final BoxDecoration d when d.color != null)
        d.color!,
    for (final box in tester.widgetList<ColoredBox>(
      find.descendant(of: find.byKey(key), matching: find.byType(ColoredBox)),
    ))
      box.color,
  ];

  /// The accent rule's horizontal scale: 0 when it is not painted at all.
  double accentScale(WidgetTester tester) {
    final transforms = tester.widgetList<Transform>(
      find.descendant(of: find.byKey(key), matching: find.byType(Transform)),
    );
    return transforms.isEmpty ? 0 : transforms.first.transform.storage[0];
  }

  /// The decoration of the row whose label is [label].
  BoxDecoration rowDecoration(WidgetTester tester, String label) => tester
      .widgetList<DecoratedBox>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  Future<TestGesture> hover(WidgetTester tester, Finder target) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(target));
    await tester.pump();
    return mouse;
  }

  // Upstream as rendered in Chrome is the oracle; the Figma fixture is still
  // checked wherever the two agree, which is the Rest column and the rows.
  group('pixel fidelity', () {
    final spec = loadSpec('dropdown');
    final rows = loadSpec('dropdown_option');

    test('both fixtures cover their whole component set', () {
      expect(spec.variants.length, 24);
      expect(rows.variants.length, 11);
      expect(spec.properties['Appearance'], <String>[
        'Outline',
        'Transparent',
        'Fill lighter',
        'Fill darker',
      ]);
      expect(spec.properties['Size'], <String>['Small', 'Medium', 'Large']);
      expect(spec.properties['Expanded'], <String>['True', 'False']);
    });

    testWidgets('geometry matches upstream at every size', (tester) async {
      // Measured in Chrome on the live storybook: the button's padding is
      // `3px 6px 3px 8px` / `5px 10px 5px 12px` / `7px 12px 7px 18px` inside
      // the 1px border, so the text starts at 9 / 13 / 19 and the chevron's
      // right edge sits 7 / 11 / 13 in from the root's. Figma's frames say
      // 6 / 10 / 12 either side; upstream wins.
      const names = {
        FluentDropdownSize.small: 'Small',
        FluentDropdownSize.medium: 'Medium',
        FluentDropdownSize.large: 'Large',
      };
      const upstream = {
        FluentDropdownSize.small: (
          height: 24.0,
          text: 9.0,
          end: 7.0,
          icon: 16.0,
        ),
        FluentDropdownSize.medium: (
          height: 32.0,
          text: 13.0,
          end: 11.0,
          icon: 20.0,
        ),
        FluentDropdownSize.large: (
          height: 40.0,
          text: 19.0,
          end: 13.0,
          icon: 24.0,
        ),
      };

      for (final entry in names.entries) {
        final variant = spec.variant({
          'Appearance': 'Outline',
          'Size': entry.value,
          'Expanded': 'False',
        });
        final want = upstream[entry.key]!;

        for (final appearance in FluentDropdownAppearance.values) {
          await pump(
            tester,
            FluentDropdown<String>(
              key: key,
              size: entry.key,
              appearance: appearance,
              options: options,
              value: 'osl',
              onChanged: (_) {},
            ),
          );
          await tester.pumpAndSettle();

          final reason = '${entry.value} ${appearance.name}';
          final box = tester.getRect(find.byKey(key));
          // Transparent has a bottom border only, so it is a pixel shorter:
          // upstream's root states no height of its own.
          expect(
            box.height,
            appearance == FluentDropdownAppearance.transparent
                ? want.height - 1
                : want.height,
            reason: '$reason: height',
          );
          // Transparent has no left border to inset the text by.
          final side = appearance == FluentDropdownAppearance.transparent
              ? 1
              : 0;
          expect(
            tester.getRect(find.text('Oslo')).left - box.left,
            want.text - side,
            reason: '$reason: text start',
          );
          final chevron = tester.getRect(find.byIcon(fluentDropdownChevron));
          expect(chevron.width, want.icon, reason: '$reason: chevron size');
          expect(
            box.right - chevron.right,
            want.end - side,
            reason: '$reason: chevron end',
          );
          expect(
            chevron.top - box.top,
            (want.height - want.icon) / 2 - side,
            reason: '$reason: chevron centred inside the border',
          );
        }

        final text = tester
            .widgetList<RichText>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(RichText),
              ),
            )
            .first
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
        expect(
          triggerDecoration(tester).borderRadius,
          variant.part('Input').radius,
          reason: '${entry.value}: radius',
        );
      }
    });

    testWidgets('resting fill and border match every appearance', (
      tester,
    ) async {
      const names = {
        FluentDropdownAppearance.outline: 'Outline',
        FluentDropdownAppearance.transparent: 'Transparent',
        FluentDropdownAppearance.fillLighter: 'Fill lighter',
        FluentDropdownAppearance.fillDarker: 'Fill darker',
      };

      for (final entry in names.entries) {
        final contents = spec
            .variant({
              'Appearance': entry.value,
              'Size': 'Medium',
              'Expanded': 'False',
            })
            .part('Contents');

        await pump(
          tester,
          FluentDropdown<String>(
            key: key,
            appearance: entry.key,
            options: options,
            onChanged: (_) {},
          ),
        );
        await tester.pumpAndSettle();

        final decoration = triggerDecoration(tester);
        final expected = contents.fill!;
        if (expected.a == 0) {
          // Figma stores a fully transparent token as #00FFFFFF and core as
          // transparent black; only the alpha is observable.
          expect(decoration.color!.a, 0, reason: '${entry.value}: fill alpha');
        } else {
          expect(decoration.color, expected, reason: '${entry.value}: fill');
        }

        // Upstream and Figma agree at rest, so the fixture still settles it.
        final stroke = contents.stroke;
        final border = borderPainter(tester);
        expect(
          border.borderColor != null,
          stroke != null,
          reason: '${entry.value}: has border',
        );
        if (stroke != null) {
          expect(border.borderWidth, contents.strokeWidth, reason: entry.value);
          if (stroke.a == 0) {
            expect(
              border.borderColor!.a,
              0,
              reason: '${entry.value}: border alpha',
            );
          } else {
            expect(
              border.borderColor,
              stroke,
              reason: '${entry.value}: border',
            );
          }
        }
      }
    });

    testWidgets(
      'the bottom border differs on exactly Outline and Transparent',
      (tester) async {
        const names = {
          FluentDropdownAppearance.outline: 'Outline',
          FluentDropdownAppearance.transparent: 'Transparent',
          FluentDropdownAppearance.fillLighter: 'Fill lighter',
          FluentDropdownAppearance.fillDarker: 'Fill darker',
        };
        final theme = light();

        for (final entry in names.entries) {
          final variant = spec.variant({
            'Appearance': entry.value,
            'Size': 'Medium',
            'Expanded': 'False',
          });
          final ruled = variant.parts.any((p) => p.name == 'Thin underline');

          await pump(
            tester,
            FluentDropdown<String>(
              key: key,
              appearance: entry.key,
              options: options,
              onChanged: (_) {},
            ),
          );
          await tester.pumpAndSettle();

          // A side of the border rather than Figma's overlaid rectangle, so it
          // joins the others on the CSS corner diagonal.
          expect(
            borderPainter(tester).bottomBorderColor ==
                theme.colors.neutralStrokeAccessible,
            ruled,
            reason: '${entry.value}: bottom border',
          );
          expect(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(FluentInputUnderline),
            ),
            findsOneWidget,
            reason: '${entry.value}: only the focus bar, no overlaid rule',
          );
          if (ruled) {
            expect(
              variant.part('Thin underline').fill,
              theme.colors.neutralStrokeAccessible,
              reason: '${entry.value}: rule token',
            );
            expect(
              variant.part('Thin underline').size.height,
              FluentStroke.thin,
            );
          }
        }
      },
    );

    testWidgets('Expanded=True paints the 2px brand accent instead', (
      tester,
    ) async {
      final variant = spec.variant({
        'Appearance': 'Outline',
        'Size': 'Medium',
        'Expanded': 'True',
      });
      final accent = variant.part('InFocus');
      final theme = light();
      expect(accent.fill, theme.colors.compoundBrandStroke);
      expect(accent.size.height, FluentStroke.thick);

      await pump(
        tester,
        FluentDropdown<String>(key: key, options: options, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();
      // Scaled to nothing rather than absent: upstream's rule is
      // `transform: scaleX(0)`, and FluentInputFocusUnderline keeps the box so
      // the scale has something to animate.
      expect(accentScale(tester), 0);

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(triggerColors(tester).contains(accent.fill), isTrue);
      expect(accentScale(tester), 1);
      expect(
        tester.getSize(find.byType(FluentDropdown<String>)).width,
        312,
        reason: 'the popup matches the trigger width, so the trigger keeps its',
      );
    });

    testWidgets('option rows match the .ListItem set', (tester) async {
      final rest = rows.variant({'State': 'Rest', 'Type': 'Single select'});
      final hovered = rows.variant({'State': 'Hover', 'Type': 'Single select'});
      final pressed = rows.variant({
        'State': 'Pressed',
        'Type': 'Single select',
      });
      final theme = light();

      expect(hovered.fill, theme.colors.neutralBackground1Hover);
      expect(pressed.fill, theme.colors.neutralBackground1Pressed);
      expect(rest.fill, isNull, reason: 'Rest paints no fill at all');

      await pump(
        tester,
        FluentDropdown<String>(
          key: key,
          options: options,
          value: 'osl',
          onChanged: (_) {},
        ),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.text('Lisbon').hitTestable()).height <=
            rest.size.height,
        isTrue,
      );
      expect(rowDecoration(tester, 'Lisbon').color!.a, 0);
      expect(rowDecoration(tester, 'Lisbon').borderRadius, rest.radius);
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('Lisbon'),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .height,
        rest.size.height,
        reason: 'every .ListItem variant is 32 tall',
      );

      await hover(tester, find.text('Lisbon'));
      expect(rowDecoration(tester, 'Lisbon').color, hovered.fill);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Lisbon')),
      );
      await tester.pump();
      expect(rowDecoration(tester, 'Lisbon').color, pressed.fill);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the header row takes its own ramp', (tester) async {
      final header = rows.variant({'State': 'Rest', 'Type': 'Header'});
      final theme = light();
      expect(header.text!.fontSize, theme.typography.caption1Strong.fontSize);
      expect(
        header.part('List item text').fill,
        theme.colors.neutralForeground3,
      );

      await pump(
        tester,
        FluentDropdown<String>(key: key, options: options, onChanged: (_) {}),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      final style = tester
          .widget<RichText>(
            find
                .descendant(
                  of: find
                      .ancestor(
                        of: find.text('Nordics'),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                  matching: find.byType(RichText),
                )
                .first,
          )
          .text
          .style!;
      expect(style.fontSize, header.text!.fontSize);
      expect(style.height! * style.fontSize!, header.text!.lineHeight);
      expect(style.color, theme.colors.neutralForeground3);
      expect(style.fontWeight, theme.typography.caption1Strong.fontWeight);
    });

    testWidgets('a rule separates option groups, and never leads the list', (
      tester,
    ) async {
      // `useOptionGroupStyles.styles.ts`: `&:not(:last-child)::after` paints
      // `borderBottom: strokeWidthThin solid colorNeutralStroke2`. A live probe
      // of components-dropdown--grouped reads `1px solid rgb(224, 224, 224)` on
      // the first group and none on the last. The `.ListItem` fixture has no
      // group axis at all, so Figma says nothing here either way.
      const grouped = <FluentDropdownOption<String>>[
        FluentDropdownOption<String>.header(label: Text('Nordics')),
        FluentDropdownOption<String>(value: 'osl', label: Text('Oslo')),
        FluentDropdownOption<String>.header(label: Text('Iberia')),
        FluentDropdownOption<String>(value: 'lis', label: Text('Lisbon')),
      ];
      final theme = light();

      await pump(
        tester,
        const FluentDropdown<String>(
          key: key,
          options: grouped,
          onChanged: _ignore,
        ),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      final rule = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == theme.colors.neutralStroke2,
      );
      expect(
        rule,
        findsOneWidget,
        reason: 'one rule between the two groups, none above the first',
      );
      expect(tester.getSize(rule).height, FluentStroke.thin);
      // Between the groups, merged into neither.
      final ruleTop = tester.getRect(rule).top;
      expect(ruleTop, greaterThan(tester.getRect(find.text('Oslo')).bottom));
      expect(ruleTop, lessThan(tester.getRect(find.text('Iberia')).top));
    });

    testWidgets('a disabled row takes the disabled token, not a dimmed one', (
      tester,
    ) async {
      final disabled = rows.variant({
        'State': 'Disabled',
        'Type': 'Single select',
      });
      final theme = light();
      expect(
        disabled.part('List item text').fill,
        theme.colors.neutralForegroundDisabled,
      );

      await pump(
        tester,
        FluentDropdown<String>(key: key, options: options, onChanged: (_) {}),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      final style = tester
          .widget<RichText>(
            find
                .descendant(
                  of: find
                      .ancestor(
                        of: find.text('Reykjavik'),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                  matching: find.byType(RichText),
                )
                .first,
          )
          .text
          .style!;
      expect(style.color, theme.colors.neutralForegroundDisabled);
    });

    test('Multi select is a fixture axis with no counterpart here', () {
      // Deliberate: this wave models single selection only. The Figma variants
      // exist and are extracted; the enum has no member for them.
      expect(rows.properties['Type'], contains('Multi select'));
      expect(rows.where({'Type': 'Multi select'}).length, 5);
      expect(FluentDropdownOptionType.values, <FluentDropdownOptionType>[
        FluentDropdownOptionType.singleSelect,
        FluentDropdownOptionType.header,
      ]);
    });
  });

  // `useDropdownStyles.styles.ts` as it renders in Chrome on the live
  // storybook: hover, press and focus driven with a real mouse.
  group('upstream states', () {
    Color barColor(WidgetTester tester) => tester
        .widget<FluentInputFocusUnderline>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(FluentInputFocusUnderline),
          ),
        )
        .color;

    testWidgets('a pointer open and close keeps the bar until focus leaves', (
      tester,
    ) async {
      // `:focus-within` is any focus: the trigger is a `<button>`, which a
      // browser focuses on mousedown, so the bar outlives the popup.
      await pump(
        tester,
        FluentDropdown<String>(key: key, options: options, onChanged: (_) {}),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(accentScale(tester), 1);

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsNothing, reason: 'closed');
      expect(accentScale(tester), 1, reason: 'still focused');

      // A click on the page elsewhere blurs a browser button; so it does here.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(accentScale(tester), 0);
    });

    testWidgets('a held mouse press focuses at pointer-down; the click opens', (
      tester,
    ) async {
      // Chrome focuses the `<button>` on mousedown — left or right — so the
      // bar grows while the press is held; the popup waits for the click,
      // and a right press never opens it. The dropdown above holds focus
      // first: its outside-press blur must not undo this one's focus.
      final first = FocusNode();
      final node = FocusNode();
      addTearDown(first.dispose);
      addTearDown(node.dispose);
      await pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FluentDropdown<String>(
              focusNode: first,
              options: options,
              onChanged: _ignore,
            ),
            FluentDropdown<String>(
              key: key,
              focusNode: node,
              options: options,
              onChanged: _ignore,
            ),
          ],
        ),
      );
      first.requestFocus();
      await tester.pumpAndSettle();
      final centre = tester.getCenter(find.byKey(key));

      for (final buttons in <int>[kPrimaryButton, kSecondaryMouseButton]) {
        first.requestFocus();
        await tester.pumpAndSettle();
        final mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: buttons,
        );
        await mouse.addPointer(location: centre);
        await mouse.down(centre);
        await tester.pumpAndSettle();
        expect(node.hasFocus, isTrue, reason: 'buttons $buttons, held');
        expect(accentScale(tester), 1, reason: 'buttons $buttons, held');
        expect(find.text('Lisbon'), findsNothing, reason: 'not yet open');

        await mouse.up();
        await tester.pumpAndSettle();
        expect(
          find.text('Lisbon'),
          buttons == kPrimaryButton ? findsOneWidget : findsNothing,
          reason: 'buttons $buttons, released',
        );
        await mouse.removePointer();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('a disabled trigger shows the not-allowed cursor', (
      tester,
    ) async {
      // `disabled: { cursor: 'not-allowed' }` on the button, as Chrome shows
      // it.
      await pump(
        tester,
        const FluentDropdown<String>(key: key, options: options),
      );
      // A mouse `TestPointer` is device 1.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(find.byKey(key)));
      addTearDown(mouse.removePointer);
      await tester.pump();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.forbidden,
      );
    });

    testWidgets('focus moves the outline to Pressed, and hover wins over it', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final colors = light().colors;
      await pump(
        tester,
        FluentDropdown<String>(
          key: key,
          focusNode: node,
          options: options,
          onChanged: (_) {},
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(borderPainter(tester).borderColor, colors.neutralStroke1Pressed);
      expect(
        borderPainter(tester).bottomBorderColor,
        colors.neutralStrokeAccessiblePressed,
      );

      // `:focus-within` is its own rule, sorted before `:hover`.
      final mouse = await hover(tester, find.byKey(key));
      expect(borderPainter(tester).borderColor, colors.neutralStroke1Hover);
      expect(
        borderPainter(tester).bottomBorderColor,
        colors.neutralStrokeAccessibleHover,
      );
      expect(barColor(tester), colors.compoundBrandStroke);

      // `:focus-within:active::after` is the only rule that moves the bar.
      await mouse.down(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(borderPainter(tester).borderColor, colors.neutralStroke1Pressed);
      expect(barColor(tester), colors.compoundBrandStrokePressed);
      await mouse.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'a held right press keeps the hover look; a middle one presses',
      (tester) async {
        // Chrome, held on the live storybook: right keeps #c7c7c7 sides,
        // #575757 bottom and a #0f6cbd bar; middle paints #b3b3b3, #4d4d4d and
        // #0f548c. The root loses `:active` a task after the `contextmenu`.
        final colors = light().colors;
        await pump(
          tester,
          const FluentDropdown<String>(
            key: key,
            options: options,
            onChanged: _ignore,
          ),
        );
        final centre = tester.getCenter(find.byKey(key));
        for (final (buttons, side, bottom, bar) in <(int, Color, Color, Color)>[
          (
            kSecondaryMouseButton,
            colors.neutralStroke1Hover,
            colors.neutralStrokeAccessibleHover,
            colors.compoundBrandStroke,
          ),
          (
            kMiddleMouseButton,
            colors.neutralStroke1Pressed,
            colors.neutralStrokeAccessiblePressed,
            colors.compoundBrandStrokePressed,
          ),
        ]) {
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: buttons,
          );
          await mouse.addPointer(location: centre);
          await tester.pump();
          await mouse.down(centre);
          await tester.pumpAndSettle();
          expect(accentScale(tester), 1, reason: 'buttons $buttons, focused');
          expect(borderPainter(tester).borderColor, side, reason: '$buttons');
          expect(
            borderPainter(tester).bottomBorderColor,
            bottom,
            reason: 'buttons $buttons',
          );
          expect(barColor(tester), bar, reason: 'buttons $buttons');
          await mouse.up();
          await mouse.removePointer();
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets('only Outline ramps: the fill and chevron never move', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final colors = light().colors;
      Color chevron() => tester
          .widget<RichText>(
            find.descendant(
              of: find.byIcon(fluentDropdownChevron),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!
          .color!;

      for (final appearance in FluentDropdownAppearance.values) {
        await pump(
          tester,
          FluentDropdown<String>(
            key: key,
            focusNode: node,
            appearance: appearance,
            options: options,
            onChanged: (_) {},
          ),
        );
        await tester.pumpAndSettle();
        final rest = borderPainter(tester);
        final fill = triggerDecoration(tester).color;

        node.requestFocus();
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: tester.getCenter(find.byKey(key)));
        await mouse.down(tester.getCenter(find.byKey(key)));
        await tester.pump();
        expect(triggerDecoration(tester).color, fill, reason: appearance.name);
        expect(
          chevron(),
          colors.neutralStrokeAccessible,
          reason: appearance.name,
        );
        if (appearance != FluentDropdownAppearance.outline) {
          expect(
            borderPainter(tester).borderColor,
            rest.borderColor,
            reason: '${appearance.name}: no interactive rule upstream',
          );
          expect(
            borderPainter(tester).bottomBorderColor,
            rest.bottomBorderColor,
            reason: '${appearance.name}: no interactive rule upstream',
          );
        }
        await mouse.up();
        await mouse.removePointer();
        node.unfocus();
        await tester.pumpAndSettle();
      }
    });

    testWidgets(
      'error is colorPaletteRedBorder2 until the trigger is focused',
      (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        final colors = light().colors;
        final danger = colors.palette.stroke2Rest(FluentPaletteFamily.red);

        await pump(
          tester,
          FluentDropdown<String>(
            key: key,
            focusNode: node,
            error: true,
            options: options,
            onChanged: (_) {},
          ),
        );
        await tester.pumpAndSettle();
        expect(borderPainter(tester).borderColor, danger);
        expect(borderPainter(tester).bottomBorderColor, danger);

        // `:hover:not(:focus-within)` keeps it red under the pointer.
        await hover(tester, find.byKey(key));
        expect(borderPainter(tester).borderColor, danger);

        // Focus falls back to the ordinary ramp; hover still wins there.
        node.requestFocus();
        await tester.pumpAndSettle();
        expect(borderPainter(tester).borderColor, colors.neutralStroke1Hover);

        // Transparent colours its bottom border only.
        node.unfocus();
        await pump(
          tester,
          FluentDropdown<String>(
            key: key,
            error: true,
            appearance: FluentDropdownAppearance.transparent,
            options: options,
            onChanged: (_) {},
          ),
        );
        await tester.pumpAndSettle();
        expect(borderPainter(tester).borderColor, isNull);
        expect(borderPainter(tester).bottomBorderColor, danger);

        // The palette knows nothing of high contrast; the status token does.
        final contrast = FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        );
        await pump(
          tester,
          FluentDropdown<String>(
            key: key,
            error: true,
            options: options,
            onChanged: (_) {},
          ),
          theme: contrast,
        );
        await tester.pumpAndSettle();
        expect(
          borderPainter(tester).borderColor,
          (contrast.colors as FluentHighContrastColors).statusDangerBorder2,
        );
      },
    );

    testWidgets('error outranks disabled, as Chrome renders it', (
      tester,
    ) async {
      // `invalid` is not gated on `!disabled`, and `:not(:focus-within)`
      // out-specifies `disabled`'s plain class: Chrome reads rgb(209, 52, 56)
      // on a disabled, aria-invalid trigger, over a transparent fill.
      final colors = light().colors;
      final danger = colors.palette.stroke2Rest(FluentPaletteFamily.red);
      for (final appearance in FluentDropdownAppearance.values) {
        await pump(
          tester,
          FluentDropdown<String>(
            key: key,
            error: true,
            appearance: appearance,
            options: options,
          ),
        );
        await tester.pumpAndSettle();
        final transparent = appearance == FluentDropdownAppearance.transparent;
        expect(
          borderPainter(tester).borderColor,
          transparent ? isNull : danger,
          reason: appearance.name,
        );
        if (transparent) {
          expect(borderPainter(tester).bottomBorderColor, danger);
        }
        expect(triggerDecoration(tester).color, colors.transparentBackground);
      }
    });

    testWidgets('a custom border width widens the bottom side too', (
      tester,
    ) async {
      // A CSS `border-width` moves all four sides; only Transparent, which
      // has no others, keeps its bottom at 1px.
      for (final appearance in [
        FluentDropdownAppearance.outline,
        FluentDropdownAppearance.transparent,
      ]) {
        await pump(
          tester,
          FluentDropdown<String>(
            key: key,
            appearance: appearance,
            style: const FluentDropdownStyle(
              borderWidth: WidgetStatePropertyAll<double?>(2),
            ),
            options: options,
            onChanged: (_) {},
          ),
        );
        await tester.pumpAndSettle();
        expect(
          borderPainter(tester).bottomBorderWidth,
          appearance == FluentDropdownAppearance.outline ? 2 : 1,
          reason: appearance.name,
        );
      }
    });

    testWidgets('Transparent is square; the bar overhangs it a pixel a side', (
      tester,
    ) async {
      // `underline: { borderRadius: '0' }`, while `::after` keeps its own 4px
      // bottom radii and `left/right: -1px` — flush with a bordered root, one
      // pixel past a borderless one.
      for (final appearance in [
        FluentDropdownAppearance.outline,
        FluentDropdownAppearance.transparent,
      ]) {
        await pump(
          tester,
          FluentDropdown<String>(
            key: key,
            appearance: appearance,
            options: options,
            onChanged: (_) {},
          ),
        );
        await tester.pumpAndSettle();
        final overhang = appearance == FluentDropdownAppearance.transparent
            ? 1.0
            : 0.0;
        expect(
          triggerDecoration(tester).borderRadius,
          overhang == 1 ? BorderRadius.zero : FluentRadius.allMedium,
          reason: appearance.name,
        );
        final box = tester.getRect(find.byKey(key));
        final bar = find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentInputFocusUnderline),
        );
        expect(tester.getRect(bar).left, box.left - overhang);
        expect(tester.getRect(bar).right, box.right + overhang);
        expect(tester.getRect(bar).bottom, box.bottom);
        expect(
          tester.widget<FluentInputFocusUnderline>(bar).borderRadius,
          const BorderRadius.vertical(bottom: FluentRadius.medium),
          reason: appearance.name,
        );
      }
    });

    testWidgets('a tight parent height stretches the box, bar and all', (
      tester,
    ) async {
      // A CSS `height` sizes the border box, and `::after` sits on its bottom.
      await pump(
        tester,
        SizedBox(
          height: 60,
          child: FluentDropdown<String>(
            key: key,
            options: options,
            onChanged: (_) {},
          ),
        ),
      );
      final painted = find.descendant(
        of: find.byKey(key),
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is FluentInputBorderPainter,
        ),
      );
      final bar = find.descendant(
        of: find.byKey(key),
        matching: find.byType(FluentInputFocusUnderline),
      );
      expect(tester.getRect(painted).height, 60);
      expect(tester.getRect(bar).bottom, tester.getRect(painted).bottom);
    });

    testWidgets(
      'the bottom colour meets the sides on the CSS corner diagonal',
      (tester) async {
        // A browser splits two border colours along the line from the border
        // box's corner to the padding box's — 45° here — so the darker bottom
        // colour climbs half-way round each bottom arc. At DPR 4, device pixel
        // (7, 4h − 6) lies inside the ring below the diagonal; (4, 4h − 8) is
        // the same arc above it. The overlaid 1px rule this replaced left the
        // side colour at the first.
        const boundary = Key('boundary');
        await pump(
          tester,
          RepaintBoundary(
            key: boundary,
            child: FluentDropdown<String>(
              key: key,
              options: options,
              onChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
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
          final actual = [for (var c = 0; c < 3; c++) pixels.getUint8(i + c)];
          final want = [
            for (final channel in [expected.r, expected.g, expected.b])
              (channel * 255).round(),
          ];
          for (var c = 0; c < 3; c++) {
            expect(
              actual[c],
              closeTo(want[c], 3),
              reason: '$reason: got $actual, want $want',
            );
          }
        }

        final colors = light().colors;
        expectPixel(
          7,
          bottom - 6,
          colors.neutralStrokeAccessible,
          'below the diagonal: the bottom colour, #616161',
        );
        expectPixel(
          4,
          bottom - 8,
          colors.neutralStroke1,
          'above the diagonal: the side colour, #d1d1d1',
        );
      },
    );

    testWidgets('the listbox outline sits outside the surface', (tester) async {
      // `useListboxStyles`: `outline: 1px solid colorTransparentStroke`, which
      // takes no room — the first row sits at the 4px padding exactly.
      await pump(
        tester,
        FluentDropdown<String>(key: key, options: options, onChanged: (_) {}),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      final surface = find
          .ancestor(
            of: find.text('Nordics'),
            matching: find.byType(DecoratedBox),
          )
          .last;
      final border =
          (tester.widget<DecoratedBox>(surface).decoration as BoxDecoration)
                  .border!
              as Border;
      expect(border.top.strokeAlign, BorderSide.strokeAlignOutside);
      expect(border.top.color, light().colors.transparentStroke);
    });
  });

  group('motion', () {
    testWidgets('the accent grows over 200ms and collapses over 50ms', (
      tester,
    ) async {
      // useDropdownStyles.styles.ts: ::after transitions `transform`, at
      // durationNormal on :focus-within and durationUltraFast off it, on CSS
      // `ease` both ways — the curve tokens sit in `transitionDelay`, which
      // the browser drops.
      expect(fluentDropdownAccentEnter.duration, FluentDuration.normal);
      expect(fluentDropdownAccentEnter.curve, FluentCssCubic.ease);
      expect(fluentDropdownAccentExit.duration, FluentDuration.ultraFast);
      expect(fluentDropdownAccentExit.curve, FluentCssCubic.ease);

      await pump(
        tester,
        FluentDropdown<String>(key: key, options: options, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();
      expect(accentScale(tester), 0);

      await tester.tap(find.byKey(key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final midway = accentScale(tester);
      expect(midway, greaterThan(0));
      expect(midway, lessThan(1), reason: 'must be mid-tween, not instant');
      await tester.pumpAndSettle();
      expect(accentScale(tester), 1);

      // Tapping outside closes without ever moving focus, so the accent really
      // does have to come back down.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 25));
      final leaving = accentScale(tester);
      expect(leaving, greaterThan(0));
      expect(leaving, lessThan(1));
      await tester.pump(const Duration(milliseconds: 40));
      expect(
        accentScale(tester),
        0,
        reason: 'the exit is four times faster than the entrance',
      );
    });

    testWidgets('reduced motion snaps the accent to its target', (
      tester,
    ) async {
      await pump(
        tester,
        FluentDropdown<String>(key: key, options: options, onChanged: (_) {}),
        reducedMotion: true,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(key));
      await tester.pump();
      await tester.pump();
      expect(accentScale(tester), 1);
    });

    testWidgets('nothing else animates: the border is instant on hover', (
      tester,
    ) async {
      // useDropdownStyles declares no transition on background, border or
      // colour — only on the ::after transform. Nor does it declare a hover
      // fill: only the outline moves.
      await pump(
        tester,
        FluentDropdown<String>(key: key, options: options, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();

      await hover(tester, find.byKey(key));
      expect(
        borderPainter(tester).borderColor,
        light().colors.neutralStroke1Hover,
      );
      expect(
        triggerDecoration(tester).color,
        light().colors.neutralBackground1,
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
        FluentDropdownTheme(
          style: FluentDropdownStyle.from(backgroundColor: themed),
          child: FluentDropdown<String>(
            key: key,
            options: options,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(triggerDecoration(tester).color, themed);

      await pump(
        tester,
        FluentDropdownTheme(
          style: FluentDropdownStyle.from(backgroundColor: themed),
          child: FluentDropdown<String>(
            key: key,
            style: FluentDropdownStyle.from(backgroundColor: explicit),
            options: options,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(triggerDecoration(tester).color, explicit);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentDropdown<String>(
          key: key,
          style: FluentDropdownStyle.from(
            borderRadius: FluentRadius.allCircular,
          ),
          options: options,
          onChanged: (_) {},
        ),
      );
      await tester.pumpAndSettle();
      expect(triggerDecoration(tester).borderRadius, FluentRadius.allCircular);
      expect(
        triggerDecoration(tester).color,
        light().colors.neutralBackground1,
      );
    });

    testWidgets('a row theme crosses into the overlay', (tester) async {
      const rowColor = Color(0xFF00FF00);
      await pump(
        tester,
        const FluentDropdownOptionTheme(
          style: FluentDropdownOptionStyle(
            backgroundColor: WidgetStatePropertyAll<Color?>(rowColor),
          ),
          child: FluentDropdown<String>(
            key: key,
            options: options,
            onChanged: _ignore,
          ),
        ),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(rowDecoration(tester, 'Lisbon').color, rowColor);
    });
  });

  group('theming', () {
    testWidgets('a subtree override reaches the trigger and the overlay', (
      tester,
    ) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: const FluentThemeOverride(
            colors: {FluentColorToken.neutralBackground1: magenta},
            child: Center(
              child: SizedBox(
                width: 312,
                child: FluentDropdown<String>(
                  key: key,
                  options: options,
                  onChanged: _ignore,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(triggerDecoration(tester).color, magenta);

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      // InheritedTheme.capture is what carries the override across the overlay
      // boundary; without it the popup would fall back to the app theme.
      final surface = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.text('Lisbon'),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .last;
      expect(surface.color, magenta, reason: 'the popup surface');
    });

    testWidgets('high contrast leaves no appearance without an outline', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );

      for (final appearance in FluentDropdownAppearance.values) {
        await pump(
          tester,
          FluentDropdown<String>(
            key: key,
            appearance: appearance,
            options: options,
            onChanged: _ignore,
          ),
          theme: theme,
        );
        await tester.pumpAndSettle();

        final border = borderPainter(tester);
        if (appearance == FluentDropdownAppearance.transparent) {
          // Transparent has no box border in any theme — upstream sets only
          // `borderBottom` — so its outline is the bottom border, which must
          // stay opaque.
          expect(border.borderColor, isNull);
          expect(
            border.bottomBorderColor,
            theme.colors.neutralStrokeAccessible,
            reason: 'transparent keeps its bottom border in high contrast',
          );
        } else {
          expect(border.borderColor, isNotNull, reason: appearance.name);
          expect(
            border.borderColor!.a,
            1.0,
            reason: '${appearance.name}: border must be opaque here',
          );
        }
      }
    });
  });

  group('behaviour', () {
    testWidgets('null onChanged disables it for real', (tester) async {
      await pump(
        tester,
        const FluentDropdown<String>(key: key, options: options),
      );
      await tester.pumpAndSettle();
      final theme = light();
      // Upstream's `disabled`: a transparent fill, and
      // `colorNeutralStrokeDisabled` on every side, the bottom included.
      expect(
        triggerDecoration(tester).color,
        theme.colors.transparentBackground,
      );
      expect(
        borderPainter(tester).borderColor,
        theme.colors.neutralStrokeDisabled,
      );
      expect(
        borderPainter(tester).bottomBorderColor,
        theme.colors.neutralStrokeDisabled,
      );

      await hover(tester, find.byKey(key));
      await tester.tap(find.byKey(key), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsNothing, reason: 'must not open');
      expect(
        borderPainter(tester).borderColor,
        theme.colors.neutralStrokeDisabled,
        reason: 'must not adopt the hover border',
      );
    });

    testWidgets('opens under a leader ancestor deep in a scrolled page', (
      tester,
    ) async {
      // The popup caps its height at the room left below the trigger, and used
      // to measure that off the trigger's own `LeaderLayer`. A `LeaderLayer`
      // paints its child from its OWN origin, so any ancestor that anchors an
      // overlay — `SelectableRegion` wraps every selectable page in one — made
      // the trigger report how far it sat down the *article* rather than down
      // the screen. Four thousand pixels into a docs page that came out
      // negative, clamped to zero, and clicking a dropdown moved focus and
      // showed nothing at all.
      final link = LayerLink();
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: SingleChildScrollView(
            controller: controller,
            // Inside the scroll view, the way `SelectableRegion` wraps an
            // article rather than the viewport around it: the layer's origin
            // then IS the top of the content.
            child: CompositedTransformTarget(
              link: link,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 4000),
                  SizedBox(
                    width: 312,
                    child: FluentDropdown<String>(
                      key: key,
                      options: options,
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(height: 4000),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.jumpTo(3900);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      final surface = find.descendant(
        of: find.byType(CompositedTransformFollower),
        matching: find.byType(SingleChildScrollView),
      );
      expect(surface, findsOneWidget);
      expect(
        tester.getSize(surface).height,
        greaterThan(0),
        reason: 'the popup must not be capped at zero height',
      );
      expect(find.text('Lisbon'), findsOneWidget);
    });

    testWidgets('re-measures its max height when the page scrolls under it', (
      tester,
    ) async {
      // The room below the trigger is measured at open, and the entry lives in
      // the Overlay, so nothing used to rebuild it when the page moved: a
      // dropdown opened 28 tall against the bottom edge stayed 28 tall after
      // the page scrolled it back up to the top, with the whole viewport free
      // beneath it. `@fluentui/react-positioning` repositions on scroll rather
      // than closing, so the entry re-measures.
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: SingleChildScrollView(
            controller: controller,
            child: const Column(
              children: <Widget>[
                SizedBox(height: 900),
                SizedBox(
                  width: 312,
                  child: FluentDropdown<String>(
                    key: key,
                    options: options,
                    onChanged: _ignore,
                  ),
                ),
                SizedBox(height: 900),
              ],
            ),
          ),
        ),
      );
      // Puts the trigger 540 down a 600 viewport: about one row of room left.
      controller.jumpTo(360);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      // The height-clamping box specifically: the popup also carries a
      // `minWidth: 160` box, whose maxHeight is infinite.
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
      // touch drag dismisses (see the light-dismiss group), and `jumpTo` never
      // flips `isScrollingNotifier`, which the rebuild is gated on.
      final before = controller.offset;
      final wheel = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(wheel.hover(const Offset(400, 100)));
      await tester.sendEventToBinding(wheel.scroll(const Offset(0, 460)));
      await tester.pumpAndSettle();

      expect(find.text('Lisbon'), findsOneWidget, reason: 'still open');
      // Without this the assertion below reads 0 == 0 and proves nothing.
      expect(controller.offset - before, 460);
      expect(
        cap() - opened,
        moreOrLessEquals(controller.offset - before, epsilon: 0.5),
        reason: 'every pixel the trigger climbed is a pixel of room below it',
      );
    });

    testWidgets('tapping an option selects it and closes', (tester) async {
      String? chosen;
      await pump(
        tester,
        FluentDropdown<String>(
          key: key,
          options: options,
          onChanged: (value) => chosen = value,
        ),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsOneWidget);

      await tester.tap(find.text('Lisbon'));
      await tester.pumpAndSettle();
      expect(chosen, 'lis');
      expect(find.text('Lisbon'), findsNothing);
    });

    testWidgets('a disabled option cannot be chosen', (tester) async {
      var calls = 0;
      await pump(
        tester,
        FluentDropdown<String>(
          key: key,
          options: options,
          onChanged: (_) => calls++,
        ),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reykjavik'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('Reykjavik'), findsOneWidget, reason: 'still open');
    });

    testWidgets('a tap outside closes without choosing', (tester) async {
      var calls = 0;
      await pump(
        tester,
        FluentDropdown<String>(
          key: key,
          options: options,
          onChanged: (_) => calls++,
        ),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('Lisbon'), findsNothing);
    });

    testWidgets(
      'a press on another field takes focus from it while still held',
      (tester) async {
        // Chrome: with the dropdown focused, a mousedown on a field focuses
        // that field at once, so its bar grows under the held press. The
        // dropdown's outside-tap blur runs later in the same pointer-down and
        // used to park focus on the route's scope, cancelling the field's own
        // request: the held press focused nothing.
        final dropdownNode = FocusNode();
        addTearDown(dropdownNode.dispose);
        final fieldNode = FocusNode();
        addTearDown(fieldNode.dispose);
        await tester.pumpWidget(
          FluentApp(
            theme: light(),
            home: Center(
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FluentDropdown<String>(
                      key: key,
                      focusNode: dropdownNode,
                      options: options,
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 20),
                    FluentSpinButton(
                      key: const Key('field'),
                      focusNode: fieldNode,
                      value: 1,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        dropdownNode.requestFocus();
        await tester.pumpAndSettle();
        expect(dropdownNode.hasFocus, isTrue);

        final press = await tester.startGesture(
          tester.getTopLeft(find.byKey(const Key('field'))) +
              const Offset(20, 16),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        await tester.pump();
        expect(fieldNode.hasFocus, isTrue, reason: 'focused under the press');
        expect(dropdownNode.hasFocus, isFalse);
        await press.up();
        await tester.pumpAndSettle();
        expect(fieldNode.hasFocus, isTrue);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );

    testWidgets('a dropdown removed mid-press takes the release quietly', (
      tester,
    ) async {
      await pump(
        tester,
        FluentDropdown<String>(key: key, options: options, onChanged: (_) {}),
      );
      final press = await tester.startGesture(
        tester.getCenter(find.byKey(key)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await press.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tap on the page still blurs it', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentDropdown<String>(
          key: key,
          focusNode: node,
          options: options,
          onChanged: (_) {},
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(node.hasFocus, isFalse, reason: 'a click on the body blurs');
    });

    testWidgets('a click BEHIND the popup lands, and still dismisses', (
      tester,
    ) async {
      // The popup used to paint a `Positioned.fill` `HitTestBehavior.opaque`
      // barrier over the whole viewport, so the click that dismissed it was
      // also swallowed by it: a button behind an open dropdown took two
      // clicks, and hover and wheel events never reached anything back there
      // either. Upstream has no barrier — `useOnClickOutside` is a
      // document-level listener, so the click dismisses AND lands.
      var behind = 0;
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Above the trigger, because the popup itself legitimately
                // covers what is below it.
                GestureDetector(
                  key: const Key('behind'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => behind++,
                  child: const SizedBox(width: 312, height: 40),
                ),
                const SizedBox(
                  width: 312,
                  child: FluentDropdown<String>(
                    key: key,
                    options: options,
                    onChanged: _ignore,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsOneWidget);

      await tester.tap(find.byKey(const Key('behind')));
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsNothing, reason: 'dismissed');
      expect(behind, 1, reason: 'and the click landed on the first attempt');
    });

    testWidgets('a wheel scroll behind the popup scrolls, and does NOT '
        'dismiss', (tester) async {
      // The other half of the barrier's damage: a PointerScrollEvent never
      // reached the Scrollable, so the page froze while a dropdown was open.
      // A wheel event is not a pointer-down, so it is not an outside tap
      // either — unlike a touch or trackpad drag, which `TapRegion` cannot
      // tell apart from a tap (`widgets/tap_region.dart:189-193`) and which
      // therefore does dismiss.
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: SingleChildScrollView(
            controller: controller,
            child: const Column(
              children: <Widget>[
                SizedBox(height: 200),
                SizedBox(
                  width: 312,
                  child: FluentDropdown<String>(
                    key: key,
                    options: options,
                    onChanged: _ignore,
                  ),
                ),
                SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsOneWidget);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      pointer.hover(const Offset(400, 100));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
      await tester.pumpAndSettle();

      expect(controller.offset, 120);
      expect(find.text('Lisbon'), findsOneWidget, reason: 'still open');
    });

    testWidgets('clicking the trigger while open closes it exactly once', (
      tester,
    ) async {
      // Dead code until the barrier went: the barrier sat ABOVE the trigger,
      // so the trigger's own toggle could never fire while the popup was up.
      // Now the click reaches it, and it must close — not close and reopen on
      // the same click, which is what a second dismissal path would cause.
      await pump(
        tester,
        const FluentDropdown<String>(
          key: key,
          options: options,
          onChanged: _ignore,
        ),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsOneWidget);

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsNothing, reason: 'closed, not reopened');

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsOneWidget, reason: 'and it reopens');
    });

    testWidgets('opening by TAP still lets the arrows move the active row', (
      tester,
    ) async {
      // Every other keyboard test here pre-focuses the trigger with
      // `node.requestFocus()`, so none of them covered the ordinary path: click
      // the control, then press Down. The arrow Shortcuts live on the trigger
      // and the rows are outside the traversal order, so without focus the keys
      // reached nobody and the list sat on the selected row forever.
      String? chosen;
      await pump(
        tester,
        FluentDropdown<String>(
          key: key,
          options: options,
          value: 'osl',
          onChanged: (value) => chosen = value,
        ),
      );

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(
        find.text('Helsinki'),
        findsOneWidget,
        reason: 'the tap opened it',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        chosen,
        isNot('osl'),
        reason: 'Down must move off the selected row, not stick to it',
      );
    });

    testWidgets('Down opens, arrows move, Enter selects, focus never leaves', (
      tester,
    ) async {
      String? chosen;
      final node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        FluentDropdown<String>(
          key: key,
          focusNode: node,
          options: options,
          onChanged: (value) => chosen = value,
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Oslo'), findsOneWidget, reason: 'Down opens');
      expect(node.hasFocus, isTrue, reason: 'focus stays on the trigger');

      // Active starts on the first option row — the header is skipped.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      // Oslo -> Helsinki -> Reykjavik. Upstream's walker visits a disabled
      // option too, and Enter or Space on it does nothing: the list stays open
      // (Chrome, the Default story's Ferret).
      for (final k in <LogicalKeyboardKey>[
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.space,
      ]) {
        await tester.sendKeyEvent(k);
        await tester.pumpAndSettle();
        expect(chosen, isNull, reason: '$k on a disabled row');
        expect(find.text('Lisbon'), findsOneWidget, reason: 'still open');
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, 'lis');
      expect(find.text('Lisbon'), findsNothing, reason: 'and it closed');
      expect(node.hasFocus, isTrue, reason: 'focus returned to the trigger');
    });

    testWidgets('Up from closed opens on the selection, else the first', (
      tester,
    ) async {
      // Chrome: Up opens exactly as Down does — never on the last option.
      String? chosen;
      final node = FocusNode();
      addTearDown(node.dispose);
      for (final (value, expected) in <(String?, String)>[
        (null, 'osl'),
        ('hel', 'hel'),
      ]) {
        chosen = null;
        await pump(
          tester,
          FluentDropdown<String>(
            key: key,
            focusNode: node,
            value: value,
            options: options,
            onChanged: (value) => chosen = value,
          ),
        );
        node.requestFocus();
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(chosen, expected, reason: 'value $value');
      }
    });

    testWidgets('Home and End jump to the ends', (tester) async {
      String? chosen;
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentDropdown<String>(
          key: key,
          focusNode: node,
          options: options,
          onChanged: (value) => chosen = value,
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();

      // Closed, they do nothing (Chrome).
      for (final k in <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
        LogicalKeyboardKey.end,
      ]) {
        await tester.sendKeyEvent(k);
        await tester.pumpAndSettle();
        expect(find.text('Lisbon'), findsNothing, reason: '$k while closed');
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, 'osl', reason: 'Home lands on the first selectable row');
    });

    testWidgets('the list scrolls just far enough, 2px clear of the edge', (
      tester,
    ) async {
      // Upstream's `scrollIntoView` in Chrome on the Default story's ten
      // animals, listbox held to 260px (scrollHeight 346, padding 4 inside the
      // scroller): the scrollTop after each key, and where the active row
      // lands against the listbox's own edges.
      const animals = <String>[
        'Cat', 'Caterpillar', 'Corgi', 'Chupacabra', 'Dog', //
        'Ferret', 'Fish', 'Fox', 'Hamster', 'Snake',
      ];
      final node = FocusNode();
      addTearDown(node.dispose);
      Future<void> mount(String? value) => pump(
        tester,
        FluentDropdown<String>(
          key: key,
          focusNode: node,
          value: value,
          style: const FluentDropdownStyle(
            surfaceMaxHeight: WidgetStatePropertyAll<double?>(260),
          ),
          options: <FluentDropdownOption<String>>[
            for (final a in animals)
              FluentDropdownOption<String>(value: a, label: Text(a), text: a),
          ],
          onChanged: _ignore,
        ),
      );
      final list = find.byType(SingleChildScrollView);
      double scrollTop() => tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      Future<void> key_(LogicalKeyboardKey k) async {
        await tester.sendKeyEvent(k);
        await tester.pumpAndSettle();
      }

      await mount(null);
      node.requestFocus();
      await tester.pump();
      await key_(LogicalKeyboardKey.arrowDown);
      expect(tester.getSize(list).height, 260);
      expect(scrollTop(), 0);
      final down = <double>[];
      for (var i = 0; i < 9; i++) {
        await key_(LogicalKeyboardKey.arrowDown);
        down.add(scrollTop());
      }
      expect(down, <double>[0, 0, 0, 0, 0, 0, 16, 50, 84]);
      expect(
        tester.getRect(list).bottom - tester.getRect(find.text('Snake')).bottom,
        greaterThan(0),
      );
      final up = <double>[];
      for (var i = 0; i < 9; i++) {
        await key_(LogicalKeyboardKey.arrowUp);
        up.add(scrollTop());
      }
      expect(up, <double>[84, 84, 84, 84, 84, 84, 70, 36, 2]);
      await key_(LogicalKeyboardKey.end);
      expect(scrollTop(), 84, reason: 'End');
      await key_(LogicalKeyboardKey.home);
      expect(scrollTop(), 2, reason: 'Home');

      // Opening on a selection runs the same rule from the top: Fish fits,
      // Fox needs 16, Snake the 84 the arrows reach. (Chrome reads 86 for
      // both there, but only because floating-ui's first pass holds that
      // listbox at 140px when the rule runs, before shifting it over the
      // trigger. This popup is laid out once, below the trigger.)
      for (final (value, expected) in <(String, double)>[
        ('Fish', 0),
        ('Fox', 16),
        ('Snake', 84),
      ]) {
        await key_(LogicalKeyboardKey.escape);
        await mount(value);
        await key_(LogicalKeyboardKey.arrowDown);
        expect(scrollTop(), expected, reason: 'opened on $value');
      }
    });

    testWidgets('a list that shrinks under the active row falls back to the '
        'first option', (tester) async {
      // Upstream's `useComboboxBaseState` re-runs `first()` whenever the
      // children change under an open listbox with nothing active, and an
      // option that has left the DOM is not active. Here the stale index
      // threw a RangeError on Enter and left Up and Down stuck.
      String? chosen;
      final node = FocusNode();
      addTearDown(node.dispose);
      Future<void> mount(List<String> items) => pump(
        tester,
        FluentDropdown<String>(
          key: key,
          focusNode: node,
          options: <FluentDropdownOption<String>>[
            for (final a in items)
              FluentDropdownOption<String>(value: a, label: Text(a), text: a),
          ],
          onChanged: (value) => chosen = value,
        ),
      );
      await mount(<String>['Cat', 'Dog', 'Fox', 'Owl']);
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      await mount(<String>['Cat', 'Dog']);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, 'Cat');
      expect(find.text('Dog'), findsNothing, reason: 'closed');
    });

    testWidgets('Escape closes and chooses nothing', (tester) async {
      var calls = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentDropdown<String>(
          key: key,
          focusNode: node,
          options: options,
          onChanged: (_) => calls++,
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsNothing);
      expect(calls, 0);
      expect(node.hasFocus, isTrue);
    });

    testWidgets('the active row carries keyboard-visible focus', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentDropdown<String>(
          key: key,
          focusNode: node,
          options: options,
          onChanged: _ignore,
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      final rings = tester.widgetList<FluentFocusRing>(
        find.byType(FluentFocusRing),
      );
      expect(
        rings.where((ring) => ring.visible).length,
        1,
        reason: 'exactly the active row draws a ring',
      );
    });

    testWidgets('the selected row is the one carrying a checkmark', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentDropdown<String>(
          key: key,
          options: options,
          value: 'hel',
          onChanged: _ignore,
        ),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      final marks = find.byIcon(fluentDropdownCheckmark);
      expect(marks, findsOneWidget);
      expect(
        find.ancestor(of: find.text('Helsinki'), matching: find.byType(Row)),
        findsWidgets,
      );
      // The trigger shows the selected label, not the placeholder.
      expect(find.text('Helsinki'), findsNWidgets(2));
    });

    testWidgets('semantics announce a collapsed, expandable button', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentDropdown<String>(
          key: key,
          semanticLabel: 'City',
          options: options,
          value: 'osl',
          onChanged: _ignore,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          // The trigger's own label merges in, which is the whole announcement:
          // "City, Oslo". The selected value is deliberately not repeated as a
          // semantic value.
          label: 'City\nOslo',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasExpandedState: true,
        ),
      );

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          // The trigger's own label merges in, which is the whole announcement:
          // "City, Oslo". The selected value is deliberately not repeated as a
          // semantic value.
          label: 'City\nOslo',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasExpandedState: true,
          isExpanded: true,
          // Opening focuses the trigger. The rows sit outside the traversal
          // order on purpose, so the trigger is where the keyboard has to be
          // for the arrows to reach the list — and it is what a screen reader
          // should be parked on while the popup is open. Upstream's trigger is
          // a real `<button>`, which the browser focuses on mousedown for the
          // same reason.
          isFocused: true,
        ),
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const mine = Color(0xFF00FF00);
      const base = FluentDropdownBaseState(
        enabled: true,
        open: false,
        chevron: SizedBox(width: 20, height: 20),
        value: Text('Oslo'),
      );

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentDropdown(
            base,
            FluentDropdownStyle.from(
              backgroundColor: mine,
              borderRadius: FluentRadius.allLarge,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(triggerDecoration(tester).color, mine);
      expect(triggerDecoration(tester).borderRadius, FluentRadius.allLarge);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentDropdownState(
        appearance: FluentDropdownAppearance.fillDarker,
        value: const Text('Oslo'),
      );
      final theme = light();
      final adjusted = resolveFluentDropdownStyle(
        state,
        theme,
      ).merge(FluentDropdownStyle.from(borderRadius: FluentRadius.allCircular));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentDropdown(state, adjusted, const <WidgetState>{}),
        ),
      );
      await tester.pumpAndSettle();
      expect(triggerDecoration(tester).color, theme.colors.neutralBackground3);
      expect(triggerDecoration(tester).borderRadius, FluentRadius.allCircular);
    });

    testWidgets('a row can be rendered from base state alone', (tester) async {
      const base = FluentDropdownOptionBaseState(
        enabled: true,
        selected: true,
        showCheckmark: true,
        reserveCheckmark: true,
        label: Text('Oslo'),
      );
      const mine = Color(0xFF0000FF);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentDropdownOption(
            base,
            FluentDropdownOptionStyle.from(backgroundColor: mine),
            const <WidgetState>{},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(triggerDecoration(tester).color, mine);
      expect(find.byIcon(fluentDropdownCheckmark), findsOneWidget);
    });
  });

  // One shape, one implementation: the focus bar is `FluentInputFocusUnderline`
  // (input.dart), which is where the `max(thickness, radius)` + clip trick that
  // keeps a 4px corner on a 2px bar lives.
  testWidgets('the focus bar comes from the shared primitive', (tester) async {
    await pump(
      tester,
      const FluentDropdown<String>(
        key: key,
        options: options,
        onChanged: _ignore,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(FluentInputFocusUnderline),
      ),
      findsOneWidget,
      reason: 'one shape, one implementation — see input.dart',
    );
  });

  // React's positioning layer writes `max-height` inline from the space left
  // below the anchor on every reposition. Ours was a hard-coded 300.
  testWidgets('the popup grows with the viewport instead of stopping at 300', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pump(
      tester,
      FluentDropdown<String>(
        key: key,
        options: <FluentDropdownOption<String>>[
          for (var i = 0; i < 40; i++)
            FluentDropdownOption<String>(
              value: 'v$i',
              label: Text('Item $i'),
              text: 'Item $i',
            ),
        ],
        onChanged: _ignore,
      ),
    );
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Item 0'),
                  matching: find.byType(ExcludeFocus),
                )
                .first,
          )
          .height,
      greaterThan(300),
      reason: 'a 2000px viewport has far more than 300px below the trigger',
    );
  });
}

void _ignore(String value) {}
