import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/internal/input_modality.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentMenu` is a trigger plus a chain of overlays, so these tests cover
/// three things that can each break on their own: the numbers, against the
/// Figma `Menu/Menu`, `Menu item` and `Menu section` sets; the overlay contract
/// — theme capture, focus return, reduced motion; and the keyboard.
void main() {
  const triggerKey = Key('menu-trigger');

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  FluentThemeData dark() =>
      FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
  FluentThemeData highContrast() =>
      FluentThemeData.highContrast(fontPlatform: FluentFontPlatform.web);

  // --- harness --------------------------------------------------------------

  /// Pumps a menu whose trigger is a real focusable button.
  Future<void> pumpMenu(
    WidgetTester tester,
    List<FluentMenuItem> items, {
    FluentThemeData? theme,
    bool reducedMotion = false,
    FluentMenuStyle? style,
    FluentMenuItemStyle? itemStyle,
    FocusNode? triggerFocus,
    Widget Function(Widget child)? wrap,
    Duration hoverDelay = fluentMenuHoverDelay,
  }) {
    Widget menu = FluentMenu(
      items: items,
      style: style,
      itemStyle: itemStyle,
      hoverDelay: hoverDelay,
      semanticLabel: 'Edit',
      builder: (context, toggle) => FluentButton(
        key: triggerKey,
        onPressed: toggle,
        focusNode: triggerFocus,
        child: const Text('Edit'),
      ),
    );
    if (wrap != null) menu = wrap(menu);

    return tester.pumpWidget(
      FluentApp(
        theme: theme ?? light(),
        builder: reducedMotion
            ? (context, child) => MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: child!,
              )
            : null,
        home: Align(alignment: Alignment.topLeft, child: menu),
      ),
    );
  }

  /// Opens the menu by tapping the trigger and lets the entrance finish.
  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(triggerKey));
    await tester.pumpAndSettle();
  }

  /// The menu surface's decoration — the only [DecoratedBox] carrying a shadow.
  BoxDecoration surface(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .map((box) => box.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((decoration) => decoration.boxShadow != null);

  /// The surface's own inset — the [Padding] wrapping the row column.
  EdgeInsets surfacePadding(WidgetTester tester) => tester
      .widget<Padding>(
        find
            .ancestor(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Padding),
            )
            .first,
      )
      .padding
      .resolve(TextDirection.ltr);

  /// The entrance opacity of the frontmost surface.
  double entranceOpacity(WidgetTester tester) =>
      tester.widgetList<Opacity>(find.byType(Opacity)).last.opacity;

  /// The row whose label reads [label].
  Finder row(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(DecoratedBox));

  /// Marks the single row a `pumpRow`/`pumpSection` test builds, so every
  /// assertion is scoped to it rather than to the app around it.
  const rowKey = Key('menu-row');

  // --- fixtures -------------------------------------------------------------

  final menuSpec = loadSpec('menu');
  final itemSpec = loadSpec('menu_item');
  final sectionSpec = loadSpec('menu_section');

  group('the surface, against Menu/Menu', () {
    for (final variant in menuSpec.variants) {
      testWidgets('${variant.name} — geometry and fill', (tester) async {
        await pumpMenu(tester, <FluentMenuItem>[
          FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
        ]);
        await open(tester);

        final decoration = surface(tester);
        expect(
          decoration.borderRadius?.resolve(TextDirection.ltr),
          variant.radius,
          reason: '${variant.name}: radius',
        );
        expect(
          decoration.color?.toARGB32(),
          variant.fill?.toARGB32(),
          reason: '${variant.name}: fill (${variant.token('fills')})',
        );
        expect(
          surfacePadding(tester),
          variant.padding,
          reason: '${variant.name}: padding',
        );
      });
    }

    testWidgets('stacks rows on the Figma section gap', (tester) async {
      await pumpMenu(tester, <FluentMenuItem>[
        FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
        FluentMenuItem(label: const Text('Copy'), onPressed: () {}),
      ]);
      await open(tester);

      final column = tester.widget<Column>(
        find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(column.spacing, menuSpec.variants.first.gap);
      expect(column.spacing, FluentSpacing.xxs);
    });

    testWidgets('carries the shadow16 pair Figma binds', (tester) async {
      await pumpMenu(tester, <FluentMenuItem>[
        FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
      ]);
      await open(tester);
      expect(
        surface(tester).boxShadow,
        light().shadow(FluentElevation.shadow16),
      );
    });

    test('both Custom menu variants resolve identically', () {
      const rows = <Widget>[];
      final theme = light();
      const none = <WidgetState>{};
      final items = resolveFluentMenuStyle(
        resolveFluentMenuState(children: rows),
        theme,
      );
      final custom = resolveFluentMenuStyle(
        resolveFluentMenuState(children: rows, custom: true),
        theme,
      );
      // Compared property by property, not struct to struct: a
      // `FluentStateColor` is a fresh closure on every call and is never `==`
      // to another one.
      expect(
        custom.backgroundColor!.resolve(none),
        items.backgroundColor!.resolve(none),
      );
      expect(custom.padding!.resolve(none), items.padding!.resolve(none));
      expect(custom.gap!.resolve(none), items.gap!.resolve(none));
      expect(
        custom.borderRadius!.resolve(none),
        items.borderRadius!.resolve(none),
      );
    });
  });

  group('rows, against the Menu item set', () {
    /// Builds one row in isolation through the three-function contract, which
    /// is exactly what the contract is for.
    Future<void> pumpRow(
      WidgetTester tester,
      FluentMenuItemState state,
      Set<WidgetState> states, {
      FluentThemeData? theme,
    }) {
      final data = theme ?? light();
      return tester.pumpWidget(
        FluentApp(
          theme: data,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 240,
              child: KeyedSubtree(
                key: rowKey,
                child: buildFluentMenuItem(
                  state,
                  resolveFluentMenuItemStyle(state, data),
                  states,
                ),
              ),
            ),
          ),
        ),
      );
    }

    /// The colour the single glyph in the row actually paints with.
    Color glyphColor(WidgetTester tester) {
      final finder = find.byType(Icon);
      final icon = tester.widget<Icon>(finder);
      return icon.color ?? IconTheme.of(tester.element(finder)).color!;
    }

    /// Every `State` value of the set, as the state and interaction pair that
    /// reproduces it.
    final cases = <String, (FluentMenuItemState, Set<WidgetState>)>{
      'State=Rest': (
        resolveFluentMenuItemState(
          label: const Text('Action'),
          icon: const Icon(FluentIcons.cut_20_regular),
        ),
        const <WidgetState>{},
      ),
      'State=Rest (Checked only)': (
        resolveFluentMenuItemState(label: const Text('Action'), checked: true),
        const <WidgetState>{},
      ),
      'State=Hover': (
        resolveFluentMenuItemState(label: const Text('Action'), checked: true),
        const <WidgetState>{WidgetState.hovered},
      ),
      'State=Pressed': (
        resolveFluentMenuItemState(label: const Text('Action'), checked: true),
        const <WidgetState>{WidgetState.pressed},
      ),
      'State=Selected': (
        resolveFluentMenuItemState(label: const Text('Action'), checked: true),
        const <WidgetState>{WidgetState.selected},
      ),
      'State=Disabled': (
        resolveFluentMenuItemState(
          label: const Text('Action'),
          enabled: false,
          icon: const Icon(FluentIcons.cut_20_regular),
        ),
        const <WidgetState>{WidgetState.disabled},
      ),
      'State=Disabled (Checked only)': (
        resolveFluentMenuItemState(
          label: const Text('Action'),
          enabled: false,
          checked: true,
        ),
        const <WidgetState>{WidgetState.disabled},
      ),
    };

    // Every variant the set ships is covered, and the map is asserted against
    // the fixture rather than trusted.
    test('covers every State value', () {
      expect(
        cases.keys.toSet(),
        itemSpec.variants.map((variant) => variant.name).toSet(),
      );
    });

    for (final entry in cases.entries) {
      final variant = itemSpec.variant(<String, String>{
        'State': entry.key.split('=').last,
      });
      final (state, states) = entry.value;

      testWidgets('${variant.name} — label, glyph and fill', (tester) async {
        await pumpRow(tester, state, states);

        expect(
          tester.getSize(find.byKey(rowKey)).height,
          variant.size.height,
          reason: '${variant.name}: height',
        );

        // Scoped to the label's own Text: an Icon is a RichText too, and it
        // sits first in the row.
        final label = resolvedTextStyleOf(tester, of: find.text('Action'));
        expect(label.fontSize, variant.text!.fontSize);
        expect(label.height! * label.fontSize!, variant.text!.lineHeight);
        expect(
          label.color?.toARGB32(),
          variant.part('Item text').fill?.toARGB32(),
          reason: '${variant.name}: label colour',
        );

        expect(
          glyphColor(tester).toARGB32(),
          variant.part('Shape').fill?.toARGB32(),
          reason: '${variant.name}: glyph colour',
        );

        expect(
          resolvedRadiusOf(tester, of: find.byKey(rowKey)),
          variant.radius,
          reason: '${variant.name}: radius',
        );

        // The inset lives on the `Item content` child; the variant frame pads
        // nothing at all.
        expect(variant.padding, EdgeInsets.zero);
        final inset = tester
            .widget<Padding>(
              find
                  .descendant(
                    of: find.byKey(rowKey),
                    matching: find.byType(Padding),
                  )
                  .first,
            )
            .padding
            .resolve(TextDirection.ltr);
        expect(
          inset,
          variant.part('Item content').padding,
          reason: '${variant.name}: content inset',
        );

        final fill = surfaceColorOf(tester, of: find.byKey(rowKey));
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.selected)) {
          expect(
            fill.toARGB32(),
            variant.fill?.toARGB32(),
            reason: '${variant.name}: fill (${variant.token('fills')})',
          );
        } else {
          // Figma repeats the surface's own `Neutral/Background/1/Rest` on
          // every resting row; upstream declares no background until `:hover`.
          // Read as silence — the row is transparent and the menu shows
          // through.
          expect(fill.a, 0, reason: '${variant.name}: resting fill');
          expect(
            variant.fill?.toARGB32(),
            light().colors.neutralBackground1.toARGB32(),
          );
        }
      });
    }

    testWidgets('the secondary line is caption2 on neutralForeground3', (
      tester,
    ) async {
      final state = resolveFluentMenuItemState(
        label: const Text('Action'),
        secondary: const Text('Secondary content'),
      );
      await pumpRow(tester, state, const <WidgetState>{});

      final secondary = tester
          .widgetList<RichText>(find.byType(RichText))
          .last
          .text
          .style!;
      expect(secondary.fontSize, 10);
      expect(secondary.height! * secondary.fontSize!, 14);
      expect(secondary.color, light().colors.neutralForeground3);

      // The root's `:hover` block moves `subText` on to
      // `colorNeutralForeground3Hover`, so the line is not stuck at rest.
      await pumpRow(tester, state, const <WidgetState>{WidgetState.hovered});
      expect(
        tester
            .widgetList<RichText>(find.byType(RichText))
            .last
            .text
            .style!
            .color,
        light().colors.neutralForeground3Hover,
      );
    });

    testWidgets('the submenu chevron is 20 on the label ramp', (tester) async {
      final state = resolveFluentMenuItemState(
        label: const Text('More'),
        hasSubmenu: true,
      );
      await pumpRow(tester, state, const <WidgetState>{});
      final chevron = tester.widget<Icon>(find.byType(Icon));
      expect(chevron.icon, fluentMenuSubmenuChevron);
      expect(chevron.size, FluentSize.size200);
      expect(chevron.color, light().colors.neutralForeground2);
    });

    // `useMenuItemStyles.styles.ts` `:hover` recolours the icon slot alone —
    // `[& .${menuItemClassNames.icon}]: colorNeutralForeground2BrandSelected`,
    // measured as #0F6CBD on the live hovered row — while `submenuIndicator`
    // declares no colour and keeps the root's `currentColor`. Figma's `Menu
    // item` hover variant binds `Brand/Foreground/Compound/Hover` to its single
    // glyph layer, which this port reads as the checkmark; neither source puts
    // the icon on the label's ramp at hover.
    testWidgets('a hovered row brands its icon and leaves the chevron on the '
        'label ramp', (tester) async {
      final state = resolveFluentMenuItemState(
        label: const Text('Action'),
        icon: const Icon(FluentIcons.cut_20_regular),
        hasSubmenu: true,
      );
      await pumpRow(tester, state, const <WidgetState>{WidgetState.hovered});

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.last.icon, fluentMenuSubmenuChevron);
      expect(
        IconTheme.of(tester.element(find.byType(Icon).first)).color,
        light().colors.neutralForeground2BrandSelected,
      );
      expect(icons.last.color, light().colors.neutralForeground2Hover);
    });

    // `useRootBaseStyles` is `alignItems: 'start'`, so on a row tall enough to
    // tell the difference the glyph sits at the top of the content column.
    testWidgets('a multiline row top-aligns its glyph', (tester) async {
      final state = resolveFluentMenuItemState(
        label: const Text('Action'),
        secondary: const Text('Secondary content'),
        icon: const Icon(FluentIcons.cut_20_regular),
      );
      await pumpRow(tester, state, const <WidgetState>{});
      expect(
        tester.getTopLeft(find.byType(Icon)).dy -
            tester.getTopLeft(find.byKey(rowKey)).dy,
        FluentSpacing.sNudge,
      );
    });
  });

  group('sections, against the Menu section set', () {
    Future<void> pumpSection(
      WidgetTester tester,
      FluentMenuItem item, {
      FluentThemeData? theme,
    }) {
      final data = theme ?? light();
      final state = resolveFluentMenuItemState(
        label: item.label,
        enabled: item.enabled,
        type: item.type,
      );
      return tester.pumpWidget(
        FluentApp(
          theme: data,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 240,
              child: KeyedSubtree(
                key: rowKey,
                child: buildFluentMenuItem(
                  state,
                  resolveFluentMenuItemStyle(state, data),
                  const <WidgetState>{},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Divider=False, State=Rest', (tester) async {
      final variant = sectionSpec.variant(const <String, String>{
        'Divider': 'False',
        'State': 'Rest',
      });
      await pumpSection(
        tester,
        const FluentMenuItem.header(label: Text('Section')),
      );

      expect(tester.getSize(find.byKey(rowKey)).height, variant.size.height);
      final style = resolvedTextStyleOf(tester, of: find.text('Section'));
      expect(style.fontSize, variant.text!.fontSize);
      expect(style.height! * style.fontSize!, variant.text!.lineHeight);
      expect(style.fontWeight, light().typography.caption1Stronger.fontWeight);
      expect(
        style.color?.toARGB32(),
        variant.part('Item text').fill?.toARGB32(),
      );
      expect(
        tester
            .widget<Padding>(
              find
                  .descendant(
                    of: find.byKey(rowKey),
                    matching: find.byType(Padding),
                  )
                  .first,
            )
            .padding
            .resolve(TextDirection.ltr),
        variant.padding,
      );
    });

    testWidgets('Divider=False, State=Disabled', (tester) async {
      final variant = sectionSpec.variant(const <String, String>{
        'Divider': 'False',
        'State': 'Disabled',
      });
      await pumpSection(
        tester,
        const FluentMenuItem.header(label: Text('Section'), enabled: false),
      );
      expect(
        resolvedTextStyleOf(tester, of: find.text('Section')).color?.toARGB32(),
        variant.part('Item text').fill?.toARGB32(),
      );
      expect(
        resolvedTextStyleOf(tester, of: find.text('Section')).color,
        light().colors.neutralForegroundDisabled,
      );
    });

    testWidgets('Divider=True, State=Disabled', (tester) async {
      final variant = sectionSpec.variant(const <String, String>{
        'Divider': 'True',
        'State': 'Disabled',
      });
      await pumpSection(tester, const FluentMenuItem.divider());

      final rule = variant.part('Rectangle 1');
      expect(tester.getSize(find.byKey(rowKey)).height, variant.size.height);
      expect(tester.getSize(find.byType(ColoredBox)).height, rule.size.height);
      expect(
        tester.widget<ColoredBox>(find.byType(ColoredBox)).color.toARGB32(),
        rule.fill?.toARGB32(),
      );
      expect(find.byType(Icon), findsNothing);
    });
  });

  // --- the overlay contract -------------------------------------------------

  group('the overlay', () {
    testWidgets('a FluentThemeOverride around the trigger reaches the '
        'surface and its rows', (tester) async {
      const surfaceColor = Color(0xFF00FF00);
      const labelColor = Color(0xFFFF00FF);
      await pumpMenu(
        tester,
        <FluentMenuItem>[
          FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
        ],
        wrap: (child) => FluentThemeOverride(
          colors: const <FluentColorToken, Color>{
            FluentColorToken.neutralBackground1: surfaceColor,
            FluentColorToken.neutralForeground2: labelColor,
          },
          child: child,
        ),
      );
      await open(tester);

      expect(surface(tester).color, surfaceColor);
      expect(
        resolvedTextStyleOf(tester, of: row('Cut').first).color,
        labelColor,
      );
    });

    testWidgets('a FluentMenuTheme and a FluentMenuItemTheme around the '
        'trigger reach the overlay', (tester) async {
      const surfaceColor = Color(0xFF123456);
      const rowColor = Color(0xFF654321);
      await pumpMenu(
        tester,
        <FluentMenuItem>[
          FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
        ],
        wrap: (child) => FluentMenuTheme(
          style: FluentMenuStyle.from(backgroundColor: surfaceColor),
          child: FluentMenuItemTheme(
            style: FluentMenuItemStyle.from(foregroundColor: rowColor),
            child: child,
          ),
        ),
      );
      await open(tester);

      expect(surface(tester).color, surfaceColor);
      expect(resolvedTextStyleOf(tester, of: row('Cut').first).color, rowColor);
    });

    testWidgets('the widget style wins over the subtree theme', (tester) async {
      const themed = Color(0xFF111111);
      const own = Color(0xFF222222);
      await pumpMenu(
        tester,
        <FluentMenuItem>[
          FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
        ],
        style: FluentMenuStyle.from(backgroundColor: own),
        wrap: (child) => FluentMenuTheme(
          style: FluentMenuStyle.from(backgroundColor: themed),
          child: child,
        ),
      );
      await open(tester);
      expect(surface(tester).color, own);
    });

    testWidgets('an RTL trigger lays the surface out RTL', (tester) async {
      await pumpMenu(
        tester,
        <FluentMenuItem>[
          FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
        ],
        wrap: (child) =>
            Directionality(textDirection: TextDirection.rtl, child: child),
      );
      await open(tester);

      // `_buildLevel` already read the trigger's direction to resolve its
      // anchors, but the entry is inflated in the Overlay's branch where that
      // value does not reach — so the placement was computed against one
      // direction and the rows laid out under another until menu.dart
      // re-provided it.
      expect(
        Directionality.of(tester.element(find.text('Cut'))),
        TextDirection.rtl,
      );
    });

    testWidgets('a tap outside closes it', (tester) async {
      await pumpMenu(tester, <FluentMenuItem>[
        FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
      ]);
      await open(tester);
      expect(find.text('Cut'), findsOneWidget);

      await tester.tapAt(const Offset(700, 500));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);
    });

    // The reason the full-screen `HitTestBehavior.opaque` barrier had to go.
    // Upstream dismisses from a document-level `useOnClickOutside` listener, so
    // the click that closes a menu also presses the button under it; the
    // barrier swallowed it and cost the user a second click.
    testWidgets('a tap outside dismisses AND still reaches what it landed on', (
      tester,
    ) async {
      const behindKey = Key('behind');
      var pressed = 0;
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.topLeft,
                child: FluentMenu(
                  items: <FluentMenuItem>[
                    FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
                  ],
                  builder: (context, toggle) => FluentButton(
                    key: triggerKey,
                    onPressed: toggle,
                    child: const Text('Edit'),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: FluentButton(
                  key: behindKey,
                  onPressed: () => pressed++,
                  child: const Text('Behind'),
                ),
              ),
            ],
          ),
        ),
      );
      await open(tester);
      expect(find.text('Cut'), findsOneWidget);

      await tester.tap(find.byKey(behindKey));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);
      expect(pressed, 1);
    });

    // A dead path until the barrier came out: the barrier sat ABOVE the
    // trigger, so the trigger's own toggle could never fire while the menu was
    // open. Now the click reaches it, and it has to close the chain once —
    // not close it and let a second handler reopen it.
    testWidgets('clicking the trigger while open closes it exactly once', (
      tester,
    ) async {
      await pumpMenu(tester, <FluentMenuItem>[
        FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
      ]);
      await open(tester);
      expect(find.text('Cut'), findsOneWidget);

      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);

      // And the trigger is still a toggle afterwards, which is what a stuck
      // `onTapOutside` registration would break.
      await open(tester);
      expect(find.text('Cut'), findsOneWidget);
    });

    testWidgets('an empty item list never opens', (tester) async {
      await pumpMenu(tester, const <FluentMenuItem>[]);
      await open(tester);
      expect(find.byType(Opacity), findsNothing);
    });
  });

  // --- motion ---------------------------------------------------------------

  group('motion', () {
    test('is the popover spec, enter only', () {
      expect(fluentMenuSurfaceEnter, FluentMotionSpec.popover);
      expect(fluentMenuSurfaceEnter.duration, FluentDuration.slower);
      expect(fluentMenuSurfaceEnter.curve, FluentCurve.decelerateMid);
    });

    testWidgets('the surface fades in over 400ms', (tester) async {
      await pumpMenu(tester, <FluentMenuItem>[
        FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
      ]);
      await tester.tap(find.byKey(triggerKey));
      await tester.pump();
      await tester.pump();
      expect(entranceOpacity(tester), lessThan(1));

      await tester.pump(const Duration(milliseconds: 200));
      final mid = entranceOpacity(tester);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(1));

      await tester.pump(const Duration(milliseconds: 250));
      expect(entranceOpacity(tester), 1);
    });

    // `MenuSurfaceMotion.ts` pairs the fade with a `slideAtom` over
    // `direction * 10`, the direction being the positioning layer's
    // `--fui-positioning-slide-direction-{x,y}` — `-1px` on the y axis for a
    // menu below its trigger, so it drops the last 10px into place.
    testWidgets('the surface slides into place as it fades', (tester) async {
      await pumpMenu(tester, <FluentMenuItem>[
        FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
      ]);
      await tester.tap(find.byKey(triggerKey));
      await tester.pump();
      await tester.pump();
      final entering = tester.getTopLeft(find.text('Cut')).dy;

      await tester.pumpAndSettle();
      final landed = tester.getTopLeft(find.text('Cut')).dy;
      expect(entering, lessThan(landed));
      expect(landed - entering, lessThanOrEqualTo(10));
    });

    testWidgets('reduced motion jumps straight to the end state', (
      tester,
    ) async {
      await pumpMenu(tester, <FluentMenuItem>[
        FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
      ], reducedMotion: true);
      await tester.tap(find.byKey(triggerKey));
      await tester.pump();
      await tester.pump();
      expect(entranceOpacity(tester), 1);
      // Nothing is left scheduled, which is what "jump" has to mean.
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  // --- themes ---------------------------------------------------------------

  group('high contrast', () {
    testWidgets('outlines the surface with an opaque border', (tester) async {
      await pumpMenu(tester, <FluentMenuItem>[
        FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
      ], theme: highContrast());
      await open(tester);

      final border = surface(tester).border! as Border;
      expect(border.top.width, FluentStroke.thin);
      expect(border.top.color.a, 1.0);
      // The same token is invisible in light, which is why it is a token and
      // not a hardcoded transparent colour.
      expect(light().colors.transparentStroke.a, 0.0);
      expect(border.top.color, highContrast().colors.transparentStroke);
    });

    testWidgets('every theme resolves a visible row label', (tester) async {
      for (final theme in <FluentThemeData>[light(), dark(), highContrast()]) {
        final state = resolveFluentMenuItemState(label: const Text('Action'));
        final style = resolveFluentMenuItemStyle(state, theme);
        expect(style.foregroundColor!.resolve(const <WidgetState>{})!.a, 1.0);
      }
    });
  });

  // --- interaction ----------------------------------------------------------

  group('keyboard', () {
    late List<String> invoked;
    late FocusNode triggerFocus;

    List<FluentMenuItem> items() => <FluentMenuItem>[
      const FluentMenuItem.header(label: Text('Clipboard')),
      FluentMenuItem(
        label: const Text('Cut'),
        onPressed: () => invoked.add('Cut'),
      ),
      FluentMenuItem(
        label: const Text('Copy'),
        enabled: false,
        onPressed: () => invoked.add('Copy'),
      ),
      const FluentMenuItem.divider(),
      FluentMenuItem(
        label: const Text('Paste'),
        onPressed: () => invoked.add('Paste'),
      ),
    ];

    setUp(() {
      invoked = <String>[];
      triggerFocus = FocusNode(debugLabel: 'trigger');
    });

    tearDown(() => triggerFocus.dispose());

    /// Focuses the trigger and opens the menu from the keyboard.
    Future<void> openByKeyboard(WidgetTester tester) async {
      triggerFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }

    testWidgets('Enter invokes the first selectable row, skipping the '
        'header and the disabled command', (tester) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await openByKeyboard(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(invoked, <String>['Cut']);
      expect(find.text('Paste'), findsNothing);
    });

    testWidgets('Down walks past the disabled row and the divider', (
      tester,
    ) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await openByKeyboard(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(invoked, <String>['Paste']);
    });

    testWidgets('Down wraps at the end', (tester) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await openByKeyboard(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(invoked, <String>['Cut']);
    });

    testWidgets('End and Home jump to the edges', (tester) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await openByKeyboard(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(invoked, <String>['Paste']);

      invoked.clear();
      await openByKeyboard(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(invoked, <String>['Cut']);
    });

    testWidgets('typeahead moves to the next matching row', (tester) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await openByKeyboard(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(invoked, <String>['Paste']);
    });

    testWidgets('Escape closes and returns focus to the trigger', (
      tester,
    ) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await openByKeyboard(tester);
      expect(find.text('Cut'), findsOneWidget);
      expect(triggerFocus.hasPrimaryFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);
      expect(triggerFocus.hasPrimaryFocus, isTrue);
    });

    testWidgets('Tab closes the menu rather than trapping', (tester) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await openByKeyboard(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);
    });

    testWidgets('a disabled row never fires, by pointer or by keyboard', (
      tester,
    ) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await openByKeyboard(tester);

      await tester.tap(row('Copy').first, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(invoked, isEmpty);
      // Still open: a click on a disabled row is not a dismissal either.
      expect(find.text('Copy'), findsOneWidget);
    });
  });

  group('submenus', () {
    late List<String> invoked;
    late FocusNode triggerFocus;

    List<FluentMenuItem> items() => <FluentMenuItem>[
      FluentMenuItem(
        label: const Text('Cut'),
        onPressed: () => invoked.add('Cut'),
      ),
      FluentMenuItem(
        label: const Text('Paste special'),
        submenu: <FluentMenuItem>[
          FluentMenuItem(
            label: const Text('Values'),
            onPressed: () => invoked.add('Values'),
          ),
        ],
      ),
    ];

    setUp(() {
      invoked = <String>[];
      triggerFocus = FocusNode(debugLabel: 'trigger');
    });

    tearDown(() => triggerFocus.dispose());

    Future<void> openAndSelectSubmenuRow(WidgetTester tester) async {
      triggerFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }

    testWidgets('Right opens, Left closes, and the root stays open', (
      tester,
    ) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await openAndSelectSubmenuRow(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Values'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('Values'), findsNothing);
      expect(find.text('Cut'), findsOneWidget);
    });

    // A submenu is the only level that proves `didChangeDependencies`:
    // `didUpdateWidget` repaints `_levels.first` on any rebuild, so a root-only
    // assertion would pass without it. Level 1 has nothing else marking it.
    testWidgets('a direction swap repaints an open submenu', (tester) async {
      Widget Function(Widget) wrapWith(TextDirection direction) =>
          (child) => Directionality(textDirection: direction, child: child);

      await pumpMenu(
        tester,
        items(),
        triggerFocus: triggerFocus,
        wrap: wrapWith(TextDirection.ltr),
      );
      await openAndSelectSubmenuRow(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.text('Values'))),
        TextDirection.ltr,
      );

      await pumpMenu(
        tester,
        items(),
        triggerFocus: triggerFocus,
        wrap: wrapWith(TextDirection.rtl),
      );
      await tester.pumpAndSettle();
      // The submenu re-provides the trigger's direction from inside its own
      // entry, so it renders whatever it captured on its last build — stale
      // until something marks that entry dirty.
      expect(
        Directionality.of(tester.element(find.text('Values'))),
        TextDirection.rtl,
      );
    });

    // Upstream's `submenuOpen` class paints `colorNeutralBackground1Hover` on
    // the parent row for as long as its submenu is showing, however it was
    // opened — the live probe reads #F5F5F5 on a keyboard-opened 'Preferences'
    // row while every sibling stays #FFFFFF.
    testWidgets('the row whose submenu is open paints the hover ramp', (
      tester,
    ) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await openAndSelectSubmenuRow(tester);
      Color fill() => surfaceColorOf(tester, of: row('Paste special').first);
      // Keyboard only — no pointer has ever been over this row.
      expect(fill().a, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(fill(), light().colors.neutralBackground1Hover);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(fill().a, 0);
    });

    testWidgets('Escape in a submenu closes only that level', (tester) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await openAndSelectSubmenuRow(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Values'), findsNothing);
      expect(find.text('Cut'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);
      expect(triggerFocus.hasPrimaryFocus, isTrue);
    });

    testWidgets('invoking a submenu row closes the whole chain', (
      tester,
    ) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await openAndSelectSubmenuRow(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(invoked, <String>['Values']);
      expect(find.text('Cut'), findsNothing);
      expect(triggerFocus.hasPrimaryFocus, isTrue);
    });

    // Every level joins the TRIGGER's tap-region group. Group them per level
    // instead and a click inside a submenu reads as an outside tap for the
    // root, collapsing the chain under the pointer. The header is the probe
    // because it is inert: it neither invokes nor opens anything, so the only
    // thing that could close the menu here is a misclassified outside tap.
    testWidgets('a click inside a submenu dismisses nothing', (tester) async {
      await pumpMenu(tester, <FluentMenuItem>[
        FluentMenuItem(
          label: const Text('Paste special'),
          submenu: <FluentMenuItem>[
            const FluentMenuItem.header(label: Text('Formats')),
            FluentMenuItem(
              label: const Text('Values'),
              onPressed: () => invoked.add('Values'),
            ),
          ],
        ),
      ], triggerFocus: triggerFocus);
      await openAndSelectSubmenuRow(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Formats'), findsOneWidget);

      await tester.tap(find.text('Formats'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Formats'), findsOneWidget);
      expect(find.text('Paste special'), findsOneWidget);
    });

    testWidgets('hover opens after the upstream delay, not before', (
      tester,
    ) async {
      await pumpMenu(tester, items(), triggerFocus: triggerFocus);
      await open(tester);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Paste special')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Values'), findsNothing);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Values'), findsOneWidget);
      expect(fluentMenuHoverDelay, const Duration(milliseconds: 500));
    });
  });

  // --- semantics ------------------------------------------------------------

  group('semantics', () {
    testWidgets('rows announce as buttons carrying their own state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpMenu(tester, <FluentMenuItem>[
        const FluentMenuItem.header(
          label: Text('Clipboard'),
          text: 'Clipboard',
        ),
        FluentMenuItem(label: const Text('Cut'), text: 'Cut', onPressed: () {}),
        FluentMenuItem(
          label: const Text('Wrap'),
          text: 'Wrap',
          checked: true,
          onPressed: () {},
        ),
        FluentMenuItem(
          label: const Text('Copy'),
          text: 'Copy',
          enabled: false,
          onPressed: () {},
        ),
      ]);
      await open(tester);

      expect(
        tester.getSemantics(find.text('Cut')),
        isSemantics(
          label: 'Cut',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Wrap')),
        isSemantics(hasCheckedState: true, isChecked: true),
      );
      expect(
        tester.getSemantics(find.text('Copy')),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      expect(
        tester.getSemantics(find.text('Clipboard')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('a divider is not announced at all', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpMenu(tester, <FluentMenuItem>[
        FluentMenuItem(label: const Text('Cut'), text: 'Cut', onPressed: () {}),
        const FluentMenuItem.divider(),
      ]);
      await open(tester);
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  // --- styles ---------------------------------------------------------------

  group('the style structs', () {
    test('merge per property, and copyWith replaces one', () {
      final base = FluentMenuStyle.from(
        backgroundColor: const Color(0xFF000001),
        borderRadius: BorderRadius.zero,
      );
      final merged = base.merge(
        FluentMenuStyle.from(backgroundColor: const Color(0xFF000002)),
      );
      expect(
        merged.backgroundColor!.resolve(const <WidgetState>{}),
        const Color(0xFF000002),
      );
      expect(
        merged.borderRadius!.resolve(const <WidgetState>{}),
        BorderRadius.zero,
      );
      expect(base.merge(null), base);
      expect(
        base
            .copyWith(gap: const WidgetStatePropertyAll<double?>(9))
            .gap!
            .resolve(const <WidgetState>{}),
        9,
      );
      expect(
        base,
        FluentMenuStyle.from(
          backgroundColor: const Color(0xFF000001),
          borderRadius: BorderRadius.zero,
        ),
      );
      expect(
        base.hashCode,
        FluentMenuStyle.from(
          backgroundColor: const Color(0xFF000001),
          borderRadius: BorderRadius.zero,
        ).hashCode,
      );
    });

    test('the row style merges per property too', () {
      final base = FluentMenuItemStyle.from(
        foregroundColor: const Color(0xFF000001),
        gap: 3,
      );
      final merged = base.merge(
        FluentMenuItemStyle.from(foregroundColor: const Color(0xFF000002)),
      );
      expect(
        merged.foregroundColor!.resolve(const <WidgetState>{}),
        const Color(0xFF000002),
      );
      expect(merged.gap!.resolve(const <WidgetState>{}), 3);
      expect(base.merge(null), base);
      expect(
        base,
        FluentMenuItemStyle.from(
          foregroundColor: const Color(0xFF000001),
          gap: 3,
        ),
      );
      expect(
        base.hashCode,
        FluentMenuItemStyle.from(
          foregroundColor: const Color(0xFF000001),
          gap: 3,
        ).hashCode,
      );
      expect(
        base
            .copyWith(iconSize: const WidgetStatePropertyAll<double?>(11))
            .iconSize!
            .resolve(const <WidgetState>{}),
        11,
      );
    });
  });

  // `useMenuPopoverStyles.styles.ts` states `width: 'max-content'`,
  // `minWidth: '138px'` and `maxWidth: '300px'`. Ours used to be
  // unconditionally 300: the surface sits in a `Positioned(left: 0, top: 0)`
  // inside a `Stack`, which hands it LOOSE constraints, and
  // `CrossAxisAlignment.stretch` then filled the whole cap.
  group('surface width', () {
    /// The surface is the only shadowed box in the tree.
    Finder surfaceBox() => find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).boxShadow != null,
    );

    Future<double> widthOf(WidgetTester tester, List<String> labels) async {
      await pumpMenu(tester, <FluentMenuItem>[
        for (final label in labels)
          FluentMenuItem(label: Text(label), onPressed: () {}),
      ]);
      await open(tester);
      return tester.getSize(surfaceBox()).width;
    }

    testWidgets('short labels do not stretch the surface to the cap', (
      tester,
    ) async {
      expect(await widthOf(tester, <String>['Grid', 'Rulers']), lessThan(300));
    });

    testWidgets('the surface never renders narrower than 138', (tester) async {
      expect(await widthOf(tester, <String>['A']), greaterThanOrEqualTo(138));
    });

    testWidgets('a very long label is capped at 300', (tester) async {
      expect(
        await widthOf(tester, <String>[
          'A label far longer than three hundred logical pixels could ever '
              'hope to be, and then some',
        ]),
        300,
      );
    });
  });

  // React's positioning layer writes `max-height` inline from the space left
  // below the anchor on every reposition — measured 680 / 380 / 880 at viewport
  // heights 800 / 500 / 1000. Ours was a hard-coded 300.
  group('surface height', () {
    Finder surfaceBox() => find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).boxShadow != null,
    );

    List<FluentMenuItem> manyItems() => <FluentMenuItem>[
      for (var i = 0; i < 40; i++)
        FluentMenuItem(label: Text('Item $i'), onPressed: () {}),
    ];

    testWidgets(
      'the popup grows with the viewport instead of stopping at 300',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await pumpMenu(tester, manyItems());
        await open(tester);

        expect(
          tester.getSize(surfaceBox()).height,
          greaterThan(300),
          reason: 'a 2000px viewport has far more than 300px below the trigger',
        );
      },
    );

    testWidgets('an anchor near the bottom opens the menu upward', (
      tester,
    ) async {
      // This used to assert `lessThan(200)`, which the bug satisfied: clamping
      // to the room below and nothing else gave a bottom-edge trigger a menu of
      // height ZERO. Focus moved into it and Escape bound to it, so every
      // keyboard assertion passed while the user saw nothing at all. Upstream's
      // positioning layer flips rather than collapsing.
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpMenu(
        tester,
        manyItems(),
        // Drops the trigger to y ~= 1900, so only ~100 is left below it.
        wrap: (child) => SizedBox(
          height: 1900,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[child],
          ),
        ),
      );
      await open(tester);

      final surface = tester.getRect(surfaceBox());
      final trigger = tester.getRect(find.byType(FluentButton).first);

      expect(
        surface.height,
        greaterThan(200),
        reason: 'a collapsed menu is the bug; it must flip, not shrink to fit',
      );
      expect(
        surface.bottom,
        lessThanOrEqualTo(trigger.top + 1),
        reason: 'flipped means the surface sits ABOVE the trigger',
      );
      expect(
        surface.top,
        greaterThanOrEqualTo(0),
        reason: 'and still inside the viewport',
      );
    });
  });

  // Menu rows sit outside the traversal order inside an `ExcludeFocus`, so
  // `FluentInteractive` never sees focus for them and the row state is
  // synthesised from the level's active index — which **hover** also sets. That
  // makes the ring mean "the mouse is here" unless it is ANDed with the
  // keyboard modality, which is what upstream's keyborg-driven
  // `data-fui-focus-visible` does.
  group('focus modality', () {
    setUp(FluentInputModality.debugReset);
    tearDown(FluentInputModality.debugReset);

    List<FluentMenuItem> rows() => <FluentMenuItem>[
      FluentMenuItem(label: const Text('One'), onPressed: () {}),
      FluentMenuItem(label: const Text('Two'), onPressed: () {}),
    ];

    /// Whether the row carrying [label] paints a focus ring.
    ///
    /// Scoped to the row rather than the whole tree so the trigger button's own
    /// ring cannot answer for it.
    bool ringed(WidgetTester tester, String label) => tester
        .widgetList<FluentFocusRing>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(FluentFocusRing),
          ),
        )
        .any((ring) => ring.visible);

    testWidgets('hovering a row does not ring it', (tester) async {
      await pumpMenu(tester, rows());
      await open(tester);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('One')));
      await tester.pumpAndSettle();

      expect(
        ringed(tester, 'One'),
        isFalse,
        reason: 'React paints the hover fill, never a ring, on mouse',
      );
    });

    testWidgets('arrowing onto a row rings it', (tester) async {
      await pumpMenu(tester, rows());
      await open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(ringed(tester, 'Two'), isTrue);
      expect(ringed(tester, 'One'), isFalse);
    });
  });
}
