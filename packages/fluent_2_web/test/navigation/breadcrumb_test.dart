import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentBreadcrumb` is a trail of subtle buttons with a chevron between them
/// and an overflow popup for the middle. These tests cover the four Figma
/// variant axes (`Size` x `Type` x `States` x `Icon`), the overlay's theme
/// crossing, the keyboard contract, and the two Figma authoring slips that must
/// not be copied.
void main() {
  final spec = loadSpec('breadcrumb');

  String figmaSize(FluentBreadcrumbSize size) => switch (size) {
    FluentBreadcrumbSize.small => 'Small',
    FluentBreadcrumbSize.medium => 'Medium',
    FluentBreadcrumbSize.large => 'Large',
  };

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FluentThemeData? theme,
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light(),
      builder: reducedMotion
          ? (context, inner) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: inner!,
            )
          : null,
      home: Center(child: child),
    ),
  );

  /// A three-crumb trail: an icon crumb, a plain crumb, and the current page.
  Widget trail({
    FluentBreadcrumbSize size = FluentBreadcrumbSize.medium,
    VoidCallback? onHome,
    bool reportsEnabled = true,
    FluentBreadcrumbStyle? style,
    String? semanticLabel,
  }) => FluentBreadcrumb(
    size: size,
    style: style,
    semanticLabel: semanticLabel,
    items: <FluentBreadcrumbItem>[
      FluentBreadcrumbItem(
        label: const Text('Home'),
        icon: const Icon(FluentIcons.home_20_regular),
        onPressed: onHome ?? () {},
      ),
      FluentBreadcrumbItem(
        label: const Text('Reports'),
        enabled: reportsEnabled,
        onPressed: () {},
      ),
      const FluentBreadcrumbItem(label: Text('Q3')),
    ],
  );

  /// The decorated surface of the crumb carrying [label].
  BoxDecoration surfaceOf(WidgetTester tester, String label) => tester
      .widgetList<DecoratedBox>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  /// The focus ring on the crumb carrying [label], or null when it has none.
  ///
  /// React draws a crumb's ring INSIDE its box — `BreadcrumbButton` composes
  /// `useButtonStyles_unstable`, whose indicator is a 1px `colorStrokeFocus2`
  /// border plus `boxShadow: 0 0 0 1px colorStrokeFocus2 inset`, with the
  /// outline itself transparent — so it is a foreground border here rather than
  /// a `FluentFocusRing`, which paints its band outward.
  Border? ringOn(WidgetTester tester, String label) => tester
      .widgetList<DecoratedBox>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(DecoratedBox),
        ),
      )
      .where((d) => d.position == DecorationPosition.foreground)
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .map((d) => d.border)
      .whereType<Border>()
      .firstOrNull;

  EdgeInsets paddingOf(WidgetTester tester, String label) => tester
      .widgetList<Padding>(
        find.ancestor(of: find.text(label), matching: find.byType(Padding)),
      )
      .first
      .padding
      .resolve(TextDirection.ltr);

  Size crumbSize(WidgetTester tester, String label) => tester.getSize(
    find
        .ancestor(of: find.text(label), matching: find.byType(ConstrainedBox))
        .first,
  );

  TextStyle textOf(WidgetTester tester, String label) =>
      resolvedTextStyleOf(tester, of: find.text(label));

  Color? iconColour(WidgetTester tester, IconData icon) =>
      IconTheme.of(tester.element(find.byIcon(icon).first)).color;

  Future<TestGesture> hover(WidgetTester tester, Finder target) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(target));
    await tester.pumpAndSettle();
    return gesture;
  }

  group('the fixture', () {
    test('covers the whole component set', () {
      expect(spec.variants.length, 51);
      expect(spec.properties['Size'], <String>['Large', 'Medium', 'Small']);
      expect(spec.properties['Type'], <String>['Button', 'Overflow']);
      expect(spec.properties['States'], <String>[
        'Rest',
        'Hover',
        'Pressed',
        'Focused',
        'Disabled',
        'Current',
      ]);
      expect(spec.properties['Icon'], <String>['ON', 'OFF']);
    });

    test('the trail frame itself paints nothing', () {
      // Every number lives on `.Breadcrumb Item`; the enclosing `Breadcrumb`
      // set (node 9077:5932) has no fill, no stroke and `Spacing/Horizontal/
      // None` as its item spacing, which is why the separator is a child of the
      // crumb rather than a gap in the row.
      for (final variant in spec.variants) {
        expect(variant.fill, isNull, reason: variant.name);
        expect(variant.stroke, isNull, reason: variant.name);
        expect(variant.token('itemSpacing'), 'Horizontal/None');
      }
    });
  });

  group('pixel fidelity against Figma', () {
    testWidgets('crumb geometry matches every size', (tester) async {
      for (final size in FluentBreadcrumbSize.values) {
        final withIcon = spec.variant({
          'Size': figmaSize(size),
          'Type': 'Button',
          'States': 'Rest',
          'Icon': 'ON',
        });
        final withoutIcon = spec.variant({
          'Size': figmaSize(size),
          'Type': 'Button',
          'States': 'Rest',
          'Icon': 'OFF',
        });

        await pump(tester, trail(size: size));

        // Figma measures the crumb's own `Button` child, not the variant frame,
        // because the frame also holds the chevron.
        final iconCrumb = withIcon.part('Button');
        final plainCrumb = withoutIcon.part('Button');

        expect(
          paddingOf(tester, 'Home'),
          EdgeInsets.only(
            top: iconCrumb.padding!.top,
            right: iconCrumb.padding!.right,
            bottom: iconCrumb.padding!.bottom,
            left: iconCrumb.padding!.left,
          ),
          reason: '${size.name}: an icon tightens the leading inset',
        );
        expect(
          paddingOf(tester, 'Reports'),
          EdgeInsets.only(
            top: plainCrumb.padding!.top,
            right: plainCrumb.padding!.right,
            bottom: plainCrumb.padding!.bottom,
            left: plainCrumb.padding!.left,
          ),
          reason: '${size.name}: symmetric without an icon',
        );

        expect(
          crumbSize(tester, 'Reports').height,
          plainCrumb.size.height,
          reason: '${size.name}: crumb height',
        );
        expect(
          surfaceOf(tester, 'Reports').borderRadius,
          BorderRadius.all(plainCrumb.radius!.topLeft),
          reason: '${size.name}: Button/Container -> Corner radius/Medium',
        );
      }
    });

    testWidgets('the icon and separator ramps match every size', (
      tester,
    ) async {
      // Icon slot widths are the crumb width minus its insets and label:
      // 20 / 16 / 12, which is also the chevron's own frame.
      const expected = <FluentBreadcrumbSize, double>{
        FluentBreadcrumbSize.small: 12,
        FluentBreadcrumbSize.medium: 16,
        FluentBreadcrumbSize.large: 20,
      };

      for (final size in FluentBreadcrumbSize.values) {
        await pump(tester, trail(size: size));
        final chevron = fluentBreadcrumbSeparatorIcon(size);

        expect(
          IconTheme.of(
            tester.element(find.byIcon(FluentIcons.home_20_regular).first),
          ).size,
          expected[size],
          reason: '${size.name}: leading icon',
        );
        expect(
          tester.getSize(find.byIcon(chevron).first).width,
          expected[size],
          reason: '${size.name}: separator frame',
        );
      }
    });

    testWidgets('the type ramp is regular, and only the current crumb is '
        'semibold', (tester) async {
      const ramp = <FluentBreadcrumbSize, (double, double, double, double)>{
        // (regular size, regular line height, current size, current height)
        FluentBreadcrumbSize.small: (12, 16, 12, 16),
        FluentBreadcrumbSize.medium: (14, 20, 14, 20),
        FluentBreadcrumbSize.large: (16, 22, 16, 22),
      };

      for (final size in FluentBreadcrumbSize.values) {
        await pump(tester, trail(size: size));
        final (fontSize, lineHeight, currentSize, currentHeight) = ramp[size]!;

        final rest = textOf(tester, 'Reports');
        expect(rest.fontSize, fontSize, reason: '${size.name}: label size');
        expect(
          rest.height! * rest.fontSize!,
          lineHeight,
          reason: '${size.name}: label line height',
        );

        final current = textOf(tester, 'Q3');
        expect(current.fontSize, currentSize);
        expect(current.height! * current.fontSize!, currentHeight);
        expect(
          current.fontWeight!.value,
          greaterThan(rest.fontWeight!.value),
          reason: '${size.name}: the current crumb is the semibold step',
        );

        // Sanity-check the ramp against Figma's own numbers for this size.
        final variant = spec.variant({
          'Size': figmaSize(size),
          'Type': 'Button',
          'States': 'Rest',
          'Icon': 'OFF',
        });
        expect(variant.text!.fontSize, fontSize);
        expect(variant.text!.lineHeight, lineHeight);
        expect(variant.text!.fontStyle, 'Regular');
      }
    });

    testWidgets('the overflow trigger is square and holds its own glyph ramp', (
      tester,
    ) async {
      for (final size in FluentBreadcrumbSize.values) {
        final variant = spec.variant({
          'Size': figmaSize(size),
          'Type': 'Overflow',
          'States': 'Rest',
          'Icon': 'OFF',
        });
        final button = variant.part('Button');
        final container = variant.part('Container');

        await pump(
          tester,
          FluentBreadcrumb(
            size: size,
            maxDisplayedItems: 2,
            items: List<FluentBreadcrumbItem>.generate(
              4,
              (i) => FluentBreadcrumbItem(
                label: Text('Crumb $i'),
                onPressed: () {},
              ),
            ),
          ),
        );

        final glyph = find.byIcon(fluentBreadcrumbOverflowIcon(size));
        final box = find
            .ancestor(of: glyph, matching: find.byType(ConstrainedBox))
            .first;

        expect(
          tester.getSize(box),
          Size(button.size.width, button.size.height),
          reason: '${size.name}: the overflow trigger is a square',
        );
        expect(
          tester
              .widgetList<Padding>(
                find.ancestor(of: glyph, matching: find.byType(Padding)),
              )
              .first
              .padding,
          EdgeInsets.all(button.padding!.top),
          reason: '${size.name}: square-padded on all four sides',
        );
        expect(
          IconTheme.of(tester.element(glyph)).size,
          container.size.width,
          reason: '${size.name}: 20 at small and medium, 24 at large',
        );
      }
    });
  });

  group('tokens', () {
    testWidgets('the surface walks the subtle ramp', (tester) async {
      final theme = light();
      await pump(tester, trail(), theme: theme);

      expect(surfaceOf(tester, 'Reports').color, theme.colors.subtleBackground);

      final gesture = await hover(tester, find.text('Reports'));
      expect(
        surfaceOf(tester, 'Reports').color,
        theme.colors.subtleBackgroundHover,
      );

      await gesture.down(tester.getCenter(find.text('Reports')));
      await tester.pumpAndSettle();
      expect(
        surfaceOf(tester, 'Reports').color,
        theme.colors.subtleBackgroundPressed,
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the label holds at Foreground/2 on hover and only moves on '
        'press', (tester) async {
      final theme = light();
      await pump(tester, trail(), theme: theme);
      expect(textOf(tester, 'Reports').color, theme.colors.neutralForeground2);

      final gesture = await hover(tester, find.text('Reports'));
      expect(
        textOf(tester, 'Reports').color,
        theme.colors.neutralForeground2,
        reason: 'all 51 variants bind Neutral/Foreground/2/Rest on hover',
      );

      await gesture.down(tester.getCenter(find.text('Reports')));
      await tester.pumpAndSettle();
      expect(
        textOf(tester, 'Reports').color,
        theme.colors.neutralForeground1Pressed,
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the leading icon takes a brand ramp the label does not', (
      tester,
    ) async {
      final theme = light();
      await pump(tester, trail(), theme: theme);
      const home = FluentIcons.home_20_regular;
      expect(iconColour(tester, home), theme.colors.neutralForeground2);

      final gesture = await hover(tester, find.text('Home'));
      expect(
        iconColour(tester, home),
        theme.colors.neutralForeground2BrandHover,
      );
      expect(
        textOf(tester, 'Home').color,
        theme.colors.neutralForeground2,
        reason: 'the icon goes brand, the label does not — two ramps',
      );

      await gesture.down(tester.getCenter(find.text('Home')));
      await tester.pumpAndSettle();
      expect(
        iconColour(tester, home),
        theme.colors.neutralForeground2BrandPressed,
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the separator never changes colour', (tester) async {
      final theme = light();
      await pump(tester, trail(reportsEnabled: false), theme: theme);
      const chevron = FluentIcons.chevron_right_16_regular;

      expect(iconColour(tester, chevron), theme.colors.neutralForeground2);

      // Even beside a disabled crumb: Figma binds Neutral/Foreground/2/Rest on
      // the chevron in all 51 variants, Disabled included.
      final disabled = spec.variant({
        'Size': 'Medium',
        'Type': 'Button',
        'States': 'Disabled',
        'Icon': 'OFF',
      });
      expect(disabled.parts.last.token('fills'), 'Neutral/Foreground/2/Rest');
      expect(iconColour(tester, chevron), theme.colors.neutralForeground2);
    });

    testWidgets('disabled is a real state, not a treatment', (tester) async {
      var pressed = 0;
      final theme = light();
      await pump(
        tester,
        FluentBreadcrumb(
          items: <FluentBreadcrumbItem>[
            FluentBreadcrumbItem(
              label: const Text('Home'),
              icon: const Icon(FluentIcons.home_20_regular),
              enabled: false,
              onPressed: () => pressed++,
            ),
            const FluentBreadcrumbItem(label: Text('Q3')),
          ],
        ),
        theme: theme,
      );

      expect(
        textOf(tester, 'Home').color,
        theme.colors.neutralForegroundDisabled,
      );
      expect(
        iconColour(tester, FluentIcons.home_20_regular),
        theme.colors.neutralForegroundDisabled,
      );

      // No hover state, no callback, no focus.
      await hover(tester, find.text('Home'));
      expect(surfaceOf(tester, 'Home').color, theme.colors.subtleBackground);
      await tester.tap(find.text('Home'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(pressed, 0);
    });

    testWidgets('the current crumb is inert', (tester) async {
      var pressed = 0;
      await pump(
        tester,
        FluentBreadcrumb(
          items: <FluentBreadcrumbItem>[
            FluentBreadcrumbItem(label: const Text('Home'), onPressed: () {}),
            // A current crumb with a callback still never fires it — upstream
            // puts aria-disabled on it for the same reason.
            FluentBreadcrumbItem(
              label: const Text('Q3'),
              onPressed: () => pressed++,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Q3'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(pressed, 0);
      expect(
        find.byIcon(FluentIcons.chevron_right_16_regular),
        findsOneWidget,
        reason: 'the last crumb carries no chevron, so two crumbs draw one',
      );
    });
  });

  group('motion', () {
    testWidgets('the surface uses the Button transition and nothing else '
        'moves', (tester) async {
      await pump(tester, trail());
      final animated = tester.widgetList<FluentAnimatedStyle<Color>>(
        find.byType(FluentAnimatedStyle<Color>),
      );
      expect(animated, isNotEmpty);
      for (final style in animated) {
        // useBreadcrumb*Styles.styles.ts declare no transition at all;
        // useBreadcrumbButton returns appearance: 'subtle', so the crumb is
        // rendered through the Button styles and inherits theirs.
        expect(style.spec, FluentMotionSpec.buttonSurface);
      }
    });

    testWidgets('the fill tweens rather than jumping', (tester) async {
      final theme = light();
      await pump(tester, trail(), theme: theme);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Reports')));

      await tester.pump();
      await tester.pump(FluentDuration.faster ~/ 2);
      final midway = surfaceOf(tester, 'Reports').color;
      expect(midway, isNot(theme.colors.subtleBackground));
      expect(midway, isNot(theme.colors.subtleBackgroundHover));

      await tester.pumpAndSettle();
      expect(
        surfaceOf(tester, 'Reports').color,
        theme.colors.subtleBackgroundHover,
      );
    });

    testWidgets('reduced motion jumps straight to the end state', (
      tester,
    ) async {
      final theme = light();
      await pump(tester, trail(), theme: theme, reducedMotion: true);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Reports')));

      await tester.pump();
      await tester.pump();
      expect(
        surfaceOf(tester, 'Reports').color,
        theme.colors.subtleBackgroundHover,
        reason: 'no frame of the tween should be observable',
      );
    });
  });

  group('truncation and the overflow popup', () {
    Widget longTrail({int max = 3, bool thirdEnabled = true}) =>
        FluentBreadcrumb(
          maxDisplayedItems: max,
          items: <FluentBreadcrumbItem>[
            FluentBreadcrumbItem(label: const Text('One'), onPressed: () {}),
            FluentBreadcrumbItem(label: const Text('Two'), onPressed: () {}),
            FluentBreadcrumbItem(
              label: const Text('Three'),
              enabled: thirdEnabled,
              onPressed: () {},
            ),
            FluentBreadcrumbItem(label: const Text('Four'), onPressed: () {}),
            const FluentBreadcrumbItem(label: Text('Five')),
          ],
        );

    test('the partition pins the root and keeps the tail', () {
      final items = List<FluentBreadcrumbItem>.generate(
        5,
        (i) => FluentBreadcrumbItem(label: Text('$i')),
      );

      final split = FluentBreadcrumbPartition(items, maxDisplayedItems: 3);
      expect(split.displayed.length, 3);
      expect(split.overflow.length, 2);
      expect(split.displayed.first, items[0]);
      expect(split.displayed.last, items[4]);
      expect(split.overflow, <FluentBreadcrumbItem>[items[1], items[2]]);

      // Short enough to fit, or no limit at all: nothing folds away.
      expect(FluentBreadcrumbPartition(items).overflow, isEmpty);
      expect(
        FluentBreadcrumbPartition(items, maxDisplayedItems: 9).displayed.length,
        5,
      );
    });

    testWidgets('the trigger sits after the pinned root', (tester) async {
      await pump(tester, longTrail());
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsNothing);
      expect(find.text('Four'), findsOneWidget);
      expect(find.text('Five'), findsOneWidget);

      final trigger = find.byIcon(
        fluentBreadcrumbOverflowIcon(FluentBreadcrumbSize.medium),
      );
      expect(trigger, findsOneWidget);
      expect(
        tester.getCenter(trigger).dx,
        greaterThan(tester.getCenter(find.text('One')).dx),
      );
      expect(
        tester.getCenter(trigger).dx,
        lessThan(tester.getCenter(find.text('Four')).dx),
      );
    });

    testWidgets('tapping the trigger opens the popup and a row follows the '
        'crumb', (tester) async {
      await pump(tester, longTrail());
      final trigger = find.byIcon(
        fluentBreadcrumbOverflowIcon(FluentBreadcrumbSize.medium),
      );

      await tester.tap(trigger);
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsNothing, reason: 'the popup closed');
    });

    testWidgets('a tap outside dismisses without following anything', (
      tester,
    ) async {
      await pump(tester, longTrail());
      await tester.tap(
        find.byIcon(fluentBreadcrumbOverflowIcon(FluentBreadcrumbSize.medium)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Three'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Three'), findsNothing);
    });

    testWidgets('a FluentThemeOverride wrapping the trail reaches the popup', (
      tester,
    ) async {
      const pink = Color(0xFFFF00AA);
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(
            child: FluentThemeOverride(
              colors: const <FluentColorToken, Color>{
                FluentColorToken.neutralForeground2: pink,
              },
              child: longTrail(),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byIcon(fluentBreadcrumbOverflowIcon(FluentBreadcrumbSize.medium)),
      );
      await tester.pumpAndSettle();

      // The row is built inside the Overlay, in a different branch of the tree.
      // Without InheritedTheme.capture it would resolve against the app root.
      expect(textOf(tester, 'Three').color, pink);
    });

    testWidgets(
      'a FluentBreadcrumbTheme wrapping the trail reaches the popup',
      (tester) async {
        const teal = Color(0xFF00B294);
        await pump(
          tester,
          FluentBreadcrumbTheme(
            style: FluentBreadcrumbStyle.from(surfaceColor: teal),
            child: longTrail(),
          ),
        );

        await tester.tap(
          find.byIcon(
            fluentBreadcrumbOverflowIcon(FluentBreadcrumbSize.medium),
          ),
        );
        await tester.pumpAndSettle();

        final surface = tester
            .widgetList<DecoratedBox>(
              find.ancestor(
                of: find.text('Three'),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((d) => d.decoration)
            .whereType<BoxDecoration>()
            .firstWhere((d) => d.boxShadow != null);
        expect(surface.color, teal);
      },
    );

    testWidgets('the popup outlines itself with a token, not a transparent '
        'literal', (tester) async {
      for (final theme in <FluentThemeData>[
        light(),
        FluentThemeData.dark(fontPlatform: FluentFontPlatform.web),
        FluentThemeData.highContrast(fontPlatform: FluentFontPlatform.web),
      ]) {
        final style = resolveFluentBreadcrumbStyle(
          resolveFluentBreadcrumbState(overflow: true),
          theme,
        );
        const states = <WidgetState>{};

        expect(style.surfaceBorderWidth!.resolve(states), FluentStroke.thin);
        expect(
          style.surfaceBorderColor!.resolve(states),
          theme.colors.transparentStroke,
        );
      }

      // Which is the whole point of selecting the token rather than writing a
      // transparent literal: in high contrast it turns opaque, and it is the
      // only thing separating the popup from the page there.
      final hc = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      expect(hc.colors.transparentStroke.a, 1.0);
      expect(light().colors.transparentStroke.a, 0.0);
    });

    testWidgets('there is no scrim to be transparent', (tester) async {
      await pump(tester, longTrail());
      await tester.tap(
        find.byIcon(fluentBreadcrumbOverflowIcon(FluentBreadcrumbSize.medium)),
      );
      await tester.pumpAndSettle();

      // The dismiss layer is a bare GestureDetector: it paints nothing at all,
      // rather than painting a colour that would have to be a token.
      final overlay = find.byType(Overlay);
      for (final box in tester.widgetList<ColoredBox>(
        find.descendant(of: overlay, matching: find.byType(ColoredBox)),
      )) {
        expect(
          box.color,
          isNot(const Color(0x00000000)),
          reason: 'a hardcoded transparent surface turns opaque nowhere',
        );
      }
    });
  });

  group('keyboard', () {
    Widget longTrail() => FluentBreadcrumb(
      maxDisplayedItems: 2,
      items: <FluentBreadcrumbItem>[
        FluentBreadcrumbItem(label: const Text('One'), onPressed: () {}),
        FluentBreadcrumbItem(label: const Text('Two'), onPressed: () {}),
        FluentBreadcrumbItem(label: const Text('Three'), onPressed: () {}),
        const FluentBreadcrumbItem(label: Text('Four')),
      ],
    );

    Finder trigger() =>
        find.byIcon(fluentBreadcrumbOverflowIcon(FluentBreadcrumbSize.medium));

    Future<void> focusTrigger(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }

    testWidgets('Down opens, Escape closes and focus stays on the trigger', (
      tester,
    ) async {
      await pump(tester, longTrail());
      await focusTrigger(tester);
      expect(trigger(), findsOneWidget);

      final focused = FocusManager.instance.primaryFocus;
      expect(focused?.debugLabel, 'FluentBreadcrumb');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsNothing);
      expect(
        FocusManager.instance.primaryFocus,
        same(focused),
        reason: 'focus never entered the popup, so it never had to come back',
      );
    });

    testWidgets('Enter opens, then follows the active row', (tester) async {
      var followed = '';
      await pump(
        tester,
        FluentBreadcrumb(
          maxDisplayedItems: 2,
          items: <FluentBreadcrumbItem>[
            FluentBreadcrumbItem(label: const Text('One'), onPressed: () {}),
            FluentBreadcrumbItem(
              label: const Text('Two'),
              onPressed: () => followed = 'Two',
            ),
            FluentBreadcrumbItem(
              label: const Text('Three'),
              onPressed: () => followed = 'Three',
            ),
            const FluentBreadcrumbItem(label: Text('Four')),
          ],
        ),
      );
      await focusTrigger(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(followed, 'Three');
      expect(find.text('Three'), findsNothing, reason: 'the popup closed');
    });

    testWidgets('Tab out of an open trigger closes the popup', (tester) async {
      await pump(tester, longTrail());
      await focusTrigger(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        find.text('Two'),
        findsNothing,
        reason:
            'a menu is not a dialog — Tab moves on rather than being '
            'trapped, and the popup must not outlive the focus',
      );
    });

    testWidgets(
      'Enter follows a focused crumb, and focus is keyboard-visible',
      (tester) async {
        var followed = 0;
        await pump(tester, trail(onHome: () => followed++));

        final size = crumbSize(tester, 'Home');
        expect(ringOn(tester, 'Home'), isNull, reason: 'not focused yet');

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final ring = ringOn(tester, 'Home');
        expect(ring?.top.color, light().colors.strokeFocus2);
        expect(ring?.top.width, FluentStroke.thick);
        expect(
          ring?.top.strokeAlign,
          BorderSide.strokeAlignInside,
          reason: 'the 2px runs from the crumb edge inward, never outside it',
        );
        expect(ringOn(tester, 'Reports'), isNull, reason: 'one ring at a time');
        expect(
          crumbSize(tester, 'Home'),
          size,
          reason: 'a foreground border consumes no layout',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(followed, 1);
      },
    );

    testWidgets('the current crumb refuses focus', (tester) async {
      await pump(tester, trail());

      // Two interactive crumbs, so Tab cycles between exactly those two. The
      // current crumb is never a stop, however many times it is offered one.
      final reached = <String>{};
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        for (final label in <String>['Home', 'Reports']) {
          if (ringOn(tester, label) != null) reached.add(label);
        }
        expect(
          ringOn(tester, 'Q3'),
          isNull,
          reason: 'tab $i landed on the page',
        );
      }
      expect(reached, <String>{'Home', 'Reports'});
    });
  });

  group('semantics', () {
    testWidgets('a crumb is a link, the current page is not', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, trail(semanticLabel: 'Breadcrumb'));

      expect(
        tester.getSemantics(find.text('Home')),
        isSemantics(
          isLink: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          label: 'Home',
        ),
      );

      expect(
        tester.getSemantics(find.text('Q3')),
        isSemantics(isLink: false, isSelected: true, label: 'Q3'),
      );

      expect(
        find.bySemanticsLabel('Breadcrumb'),
        findsWidgets,
        reason: 'the trail carries the counterpart of <nav aria-label>',
      );
      handle.dispose();
    });

    testWidgets('a disabled crumb announces itself as one', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, trail(reportsEnabled: false));

      expect(
        tester.getSemantics(find.text('Reports')),
        isSemantics(
          isLink: true,
          hasEnabledState: true,
          isEnabled: false,
          // An attached tap action would announce a disabled crumb as
          // activatable.
          hasTapAction: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('the overflow trigger reports its expanded state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentBreadcrumb(
          maxDisplayedItems: 2,
          items: <FluentBreadcrumbItem>[
            FluentBreadcrumbItem(label: const Text('One'), onPressed: () {}),
            FluentBreadcrumbItem(label: const Text('Two'), onPressed: () {}),
            const FluentBreadcrumbItem(label: Text('Three')),
          ],
        ),
      );

      final trigger = find.byIcon(
        fluentBreadcrumbOverflowIcon(FluentBreadcrumbSize.medium),
      );
      expect(
        tester.getSemantics(trigger),
        isSemantics(isButton: true, isExpanded: false, label: 'More'),
      );

      await tester.tap(trigger);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(trigger),
        isSemantics(isButton: true, isExpanded: true),
      );
      handle.dispose();
    });

    testWidgets('the separator is not announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, trail());
      expect(
        find.descendant(
          of: find.byType(FluentBreadcrumb),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      handle.dispose();
    });
  });

  group('style resolution', () {
    testWidgets('the caller style is merged last and wins', (tester) async {
      const green = Color(0xFF107C10);
      await pump(
        tester,
        FluentBreadcrumbTheme(
          style: FluentBreadcrumbStyle.from(
            backgroundColor: const Color(0xFF000000),
            borderRadius: BorderRadius.zero,
          ),
          child: trail(
            style: FluentBreadcrumbStyle.from(backgroundColor: green),
          ),
        ),
      );

      final surface = surfaceOf(tester, 'Reports');
      expect(surface.color, green, reason: 'the widget style wins');
      expect(
        surface.borderRadius,
        BorderRadius.zero,
        reason: 'the subtree theme still supplies what the widget did not',
      );
    });

    test('merge is per-property and copyWith round-trips', () {
      const radius = WidgetStatePropertyAll<BorderRadius?>(
        FluentRadius.allMedium,
      );
      const gap = WidgetStatePropertyAll<double?>(4);
      const base = FluentBreadcrumbStyle(borderRadius: radius, gap: gap);
      final merged = base.merge(
        const FluentBreadcrumbStyle(gap: WidgetStatePropertyAll<double?>(8)),
      );

      expect(merged.borderRadius, radius);
      expect(merged.gap!.resolve(const <WidgetState>{}), 8);
      expect(base.copyWith(), base);
      expect(base.merge(null), base);
    });
  });

  group('Figma authoring slips, pinned rather than copied', () {
    test('Small Rest and Current are swapped in the design file', () {
      // Size=Small, Type=Button, States=Rest, Icon=ON (node 9077:5785) is drawn
      // semibold with no chevron — which is what Current means — while
      // States=Current (node 9083:1883) is regular and *has* one. The pair is
      // transposed. Every other size and the whole Icon=OFF column agree with
      // the rule the widget implements, so the rule wins.
      final rest = spec.variant({
        'Size': 'Small',
        'Type': 'Button',
        'States': 'Rest',
        'Icon': 'ON',
      });
      final current = spec.variant({
        'Size': 'Small',
        'Type': 'Button',
        'States': 'Current',
        'Icon': 'ON',
      });
      expect(rest.text!.fontStyle, 'Semibold');
      expect(current.text!.fontStyle, 'Regular');

      // The Icon=OFF column, and both other sizes, say the opposite.
      for (final size in <String>['Small', 'Medium', 'Large']) {
        expect(
          spec
              .variant({
                'Size': size,
                'Type': 'Button',
                'States': 'Current',
                'Icon': 'OFF',
              })
              .text!
              .fontStyle,
          'Semibold',
          reason: '$size Current, Icon=OFF',
        );
      }
    });

    test('Medium Disabled with no icon was never switched', () {
      // Node 9077:5845 keeps Neutral/Background/Subtle/Rest and
      // Neutral/Foreground/2/Rest where its five siblings take the disabled
      // ramp. The widget follows the siblings.
      final odd = spec.variant({
        'Size': 'Medium',
        'Type': 'Button',
        'States': 'Disabled',
        'Icon': 'OFF',
      });
      expect(odd.text!.tokens['fills']!.first, 'Neutral/Foreground/2/Rest');
      expect(
        spec
            .variant({
              'Size': 'Large',
              'Type': 'Button',
              'States': 'Disabled',
              'Icon': 'OFF',
            })
            .text!
            .tokens['fills']!
            .first,
        'Neutral/Foreground/Disabled/Rest',
      );
    });
  });
}
