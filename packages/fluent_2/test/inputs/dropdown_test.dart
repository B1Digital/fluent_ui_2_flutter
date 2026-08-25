import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentDropdown` is a closed trigger plus an overlay list, so these tests
/// cover both halves: the trigger against the Figma `Dropdown` set, the rows
/// against `.ListItem`, and the keyboard contract that ties them together.
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

  group('pixel fidelity against Figma', () {
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

    testWidgets('geometry matches every size', (tester) async {
      const names = {
        FluentDropdownSize.small: 'Small',
        FluentDropdownSize.medium: 'Medium',
        FluentDropdownSize.large: 'Large',
      };

      for (final entry in names.entries) {
        final variant = spec.variant({
          'Appearance': 'Outline',
          'Size': entry.value,
          'Expanded': 'False',
        });

        await pump(
          tester,
          FluentDropdown<String>(
            key: key,
            size: entry.key,
            options: options,
            value: 'osl',
            onChanged: (_) {},
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byKey(key)).height,
          variant.part('Input').size.height,
          reason: '${entry.value}: height',
        );

        // The text's own inset, and the chevron slot's, are the only paddings
        // the variant frame states — it carries none of its own.
        final paddings = tester
            .widgetList<Padding>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Padding),
              ),
            )
            .map((p) => p.padding.resolve(TextDirection.ltr))
            .toList();

        expect(
          paddings.first,
          variant.part('Icon-Text-stack').padding,
          reason: '${entry.value}: content inset',
        );
        expect(
          paddings[1],
          variant.part('Icon End').padding,
          reason: '${entry.value}: chevron slot inset',
        );

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

        final stroke = contents.stroke;
        expect(
          decoration.border != null,
          stroke != null,
          reason: '${entry.value}: has border',
        );
        if (stroke != null) {
          final side = decoration.border!.top;
          expect(side.width, contents.strokeWidth, reason: entry.value);
          if (stroke.a == 0) {
            expect(side.color.a, 0, reason: '${entry.value}: border alpha');
          } else {
            expect(side.color, stroke, reason: '${entry.value}: border');
          }
        }
      }
    });

    testWidgets('the resting rule is on exactly Outline and Transparent', (
      tester,
    ) async {
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

        expect(
          triggerColors(tester).contains(theme.colors.neutralStrokeAccessible),
          ruled,
          reason: '${entry.value}: resting rule',
        );
        if (ruled) {
          expect(
            variant.part('Thin underline').fill,
            theme.colors.neutralStrokeAccessible,
            reason: '${entry.value}: rule token',
          );
          expect(variant.part('Thin underline').size.height, FluentStroke.thin);
        }
      }
    });

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

  group('motion', () {
    testWidgets('the accent grows over 200ms and collapses over 50ms', (
      tester,
    ) async {
      // useDropdownStyles.styles.ts: ::after transitions `transform`, at
      // durationNormal on :focus-within and durationUltraFast off it.
      expect(fluentDropdownAccentEnter.duration, FluentDuration.normal);
      expect(fluentDropdownAccentEnter.curve, FluentCurve.decelerateMid);
      expect(fluentDropdownAccentExit.duration, FluentDuration.ultraFast);
      expect(fluentDropdownAccentExit.curve, FluentCurve.accelerateMid);

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

    testWidgets('nothing else animates: the fill is instant on hover', (
      tester,
    ) async {
      // useDropdownStyles declares no transition on background, border or
      // colour — only on the ::after transform.
      await pump(
        tester,
        FluentDropdown<String>(key: key, options: options, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();

      await hover(tester, find.byKey(key));
      expect(
        triggerDecoration(tester).color,
        light().colors.neutralBackground1Hover,
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

        final decoration = triggerDecoration(tester);
        if (appearance == FluentDropdownAppearance.transparent) {
          // Transparent has no box border in any theme — Figma paints none —
          // so its outline is the resting rule, which must stay opaque.
          expect(decoration.border, isNull);
          expect(
            triggerColors(tester),
            contains(theme.colors.neutralStrokeAccessible),
            reason: 'transparent keeps its rule in high contrast',
          );
        } else {
          expect(decoration.border, isNotNull, reason: appearance.name);
          expect(
            decoration.border!.top.color.a,
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
      expect(
        triggerDecoration(tester).color,
        theme.colors.neutralBackgroundDisabled,
      );
      expect(
        triggerDecoration(tester).border!.top.color,
        theme.colors.neutralStrokeDisabled,
      );

      await tester.tap(find.byKey(key), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsNothing, reason: 'must not open');
      expect(
        triggerDecoration(tester).color,
        theme.colors.neutralBackgroundDisabled,
        reason: 'must not adopt the hover fill',
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

      // Active starts on the first selectable row — the header is skipped.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      // Oslo -> Helsinki -> Lisbon: the disabled Reykjavik is stepped over.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, 'lis');
      expect(find.text('Lisbon'), findsNothing, reason: 'and it closed');
      expect(node.hasFocus, isTrue, reason: 'focus returned to the trigger');
    });

    testWidgets('Up from closed opens on the last option', (tester) async {
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

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(chosen, 'lis');
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
