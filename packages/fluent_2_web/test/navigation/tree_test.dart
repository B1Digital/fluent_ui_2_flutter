import 'dart:ui' show SemanticsRole, Tristate;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentTree` is a flattened list of indented rows built from the existing
/// primitives: `FluentInteractive` for state, `FluentFocusRing` for focus,
/// `FluentAnimatedStyle` for the chevron, and `FluentCheckbox` / `FluentRadio`
/// for the selector. These tests cover all four Figma axes, the ARIA-tree
/// keyboard contract, the compositions, high contrast, reduced motion and the
/// subtree theme.
void main() {
  final spec = loadSpec('tree');

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  FluentThemeData dark() =>
      FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
  FluentThemeData highContrast() =>
      FluentThemeData.highContrast(fontPlatform: FluentFontPlatform.web);

  String figmaStyle(FluentTreeAppearance appearance) => switch (appearance) {
    FluentTreeAppearance.subtle => 'Subtle',
    FluentTreeAppearance.subtleAlpha => 'Subtle alpha',
    FluentTreeAppearance.transparent => 'Transparent',
  };

  String figmaSize(FluentTreeSize size) => switch (size) {
    FluentTreeSize.small => 'Small',
    FluentTreeSize.medium => 'Medium',
  };

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FluentThemeData? theme,
    bool reducedMotion = false,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light(),
      builder: reducedMotion
          ? (context, inner) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: inner!,
            )
          : null,
      home: Directionality(
        textDirection: direction,
        // The Figma frame is 280 wide and the row fills its container, so
        // pinning the width lets `expectSpec` assert size.width too.
        child: Center(child: SizedBox(width: 280, child: child)),
      ),
    ),
  );

  /// One branch holding one leaf. No leading icon: `expectSpec` reads the first
  /// `RichText` under the finder for its text metrics, and an `Icon` renders as
  /// a `RichText` carrying the *icon* size.
  List<FluentTreeItem> tree({
    bool enabled = true,
    Widget? actions,
    Widget? icon,
  }) => <FluentTreeItem>[
    FluentTreeItem(
      value: 'branch',
      label: const Text('Branch'),
      searchLabel: 'Branch',
      enabled: enabled,
      icon: icon,
      actions: actions,
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: 'leaf',
          label: const Text('Leaf'),
          searchLabel: 'Leaf',
          enabled: enabled,
        ),
        const FluentTreeItem(
          value: 'zebra',
          label: Text('Zebra'),
          searchLabel: 'Zebra',
        ),
        // Shares its first letter with Zebra, so a two-key search can only
        // land here if the typeahead buffer actually accumulated.
        const FluentTreeItem(
          value: 'zulu',
          label: Text('Zulu'),
          searchLabel: 'Zulu',
        ),
      ],
    ),
    const FluentTreeItem(
      value: 'sibling',
      label: Text('Sibling'),
      searchLabel: 'Sibling',
    ),
  ];

  /// The row carrying [label], as a finder scoped to its own `Semantics`.
  Finder rowOf(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byType(FluentFocusRing),
  );

  /// Asserts a rendered row against [variant].
  ///
  /// Not `expectSpec`, for one reason: Figma cannot store a colour without an
  /// RGB triple, so it records fully transparent tokens as `#00FFFFFF`, while
  /// core stores CSS `transparent` — `rgba(0,0,0,0)`. Both are invisible, so
  /// only the alpha is observable and only the alpha is asserted, the same rule
  /// `button_test.dart` applies. Everything else goes through the harness's own
  /// public resolvers, so the numbers compared are identical to `expectSpec`'s.
  void expectVariant(WidgetTester tester, Finder finder, SpecVariant variant) {
    final size = tester.getSize(finder);
    expect(size.width, closeTo(variant.size.width, 0.01), reason: 'width');
    expect(size.height, closeTo(variant.size.height, 0.01), reason: 'height');

    final padding = tester
        .widgetList<Padding>(
          find.descendant(
            of: finder,
            matching: find.byType(Padding),
            matchRoot: true,
          ),
        )
        .first
        .padding
        .resolve(TextDirection.ltr);
    expect(padding.top, variant.padding!.top, reason: 'padding.top');
    expect(padding.right, variant.padding!.right, reason: 'padding.right');
    expect(padding.bottom, variant.padding!.bottom, reason: 'padding.bottom');
    expect(padding.left, variant.padding!.left, reason: 'padding.left');

    expect(resolvedRadiusOf(tester, of: finder), variant.radius);

    final fill = surfaceColorOf(tester, of: finder);
    if (variant.fill!.a == 0) {
      expect(fill.a, 0, reason: 'fill alpha');
    } else {
      expect(fill.toARGB32(), variant.fill!.toARGB32(), reason: 'fill');
    }

    // Off the label, not the finder: a branch row's chevron is an `Icon`,
    // which renders as a `RichText` carrying the icon's own size.
    final style = resolvedTextStyleOf(
      tester,
      of: find.descendant(of: finder, matching: find.text('Root')),
    );
    expect(style.fontSize, variant.text!.fontSize, reason: 'fontSize');
    expect(
      style.height! * style.fontSize!,
      closeTo(variant.text!.lineHeight, 0.01),
      reason: 'lineHeight',
    );
  }

  BoxDecoration surfaceOf(WidgetTester tester, String label) => tester
      .widgetList<DecoratedBox>(
        find.descendant(of: rowOf(label), matching: find.byType(DecoratedBox)),
      )
      .map((box) => box.decoration)
      .whereType<BoxDecoration>()
      .first;

  group('Figma variants', () {
    // Style x Size x Leaf node, at rest. State=Hover/Pressed/Selected/Disabled
    // are covered by the state group below, which is where the pointer can
    // actually put the row into them.
    for (final appearance in FluentTreeAppearance.values) {
      for (final size in FluentTreeSize.values) {
        for (final leaf in <bool>[false, true]) {
          final variant = spec.variant(<String, String>{
            'Style': figmaStyle(appearance),
            'Size': figmaSize(size),
            'State': 'Rest',
            'Leaf node': leaf ? 'True' : 'False',
          });

          testWidgets(variant.name, (tester) async {
            await pump(
              tester,
              FluentTree(
                appearance: appearance,
                size: size,
                // The Figma frame is a single level-1 row. A leaf variant is a
                // level-1 item with no children; a branch variant has some.
                items: <FluentTreeItem>[
                  FluentTreeItem(
                    value: 'root',
                    label: const Text('Root'),
                    children: leaf
                        ? const <FluentTreeItem>[]
                        : const <FluentTreeItem>[
                            FluentTreeItem(value: 'kid', label: Text('Kid')),
                          ],
                  ),
                ],
              ),
            );

            expectVariant(tester, rowOf('Root'), variant);
          });
        }
      }
    }

    testWidgets('all 60 variants resolve to their own Figma fill token', (
      tester,
    ) async {
      expect(spec.variants, hasLength(60));
      expect(
        spec.properties.keys,
        containsAll(<String>['Style', 'Size', 'State', 'Leaf node']),
      );

      const appearances = <String, FluentTreeAppearance>{
        'Subtle': FluentTreeAppearance.subtle,
        'Subtle alpha': FluentTreeAppearance.subtleAlpha,
        'Transparent': FluentTreeAppearance.transparent,
      };
      const states = <String, Set<WidgetState>>{
        'Rest': <WidgetState>{},
        'Hover': <WidgetState>{WidgetState.hovered},
        'Pressed': <WidgetState>{WidgetState.pressed},
        'Selected': <WidgetState>{WidgetState.selected},
        'Disabled': <WidgetState>{WidgetState.disabled},
      };
      const sizes = <String, FluentTreeSize>{
        'Small': FluentTreeSize.small,
        'Medium': FluentTreeSize.medium,
      };

      for (final variant in spec.variants) {
        final style = resolveFluentTreeItemStyle(
          resolveFluentTreeItemState(
            appearance: appearances[variant.props['Style']]!,
            size: sizes[variant.props['Size']]!,
          ),
          light(),
        );
        final resolved = style.backgroundColor!.resolve(
          states[variant.props['State']]!,
        )!;

        final expected = variant.fill;
        if (expected == null) {
          // `Style=Transparent, Size=Medium, State=Disabled` carries no fill
          // node at all, while its Small twin binds
          // `Neutral/Background/Transparent/Rest`. The Small reading is used;
          // both are invisible outside high contrast.
          expect(resolved.a, 0, reason: '${variant.name}: fill');
          continue;
        }
        if (expected.a == 0) {
          expect(resolved.a, 0, reason: '${variant.name}: fill alpha');
        } else {
          // One unit of tolerance per channel, and no more. Figma stores a
          // paint's alpha as a byte, core stores upstream's float: the light
          // alpha hover token is `rgba(255,255,255,0.7)` in core's
          // `alias_colors.dart`, which Flutter rounds to 179, while Figma holds
          // the byte 178. The same colour, 1/255 apart and invisible either
          // way — and a tolerance this tight still catches a wrong token, since
          // the nearest wrong one is a whole ramp stop away.
          final where =
              '${variant.name}: fill token ${variant.tokens['fills']}';
          expect(resolved.a * 255, closeTo(expected.a * 255, 1), reason: where);
          expect(resolved.r * 255, closeTo(expected.r * 255, 1), reason: where);
          expect(resolved.g * 255, closeTo(expected.g * 255, 1), reason: where);
          expect(resolved.b * 255, closeTo(expected.b * 255, 1), reason: where);
        }
      }
    });

    testWidgets('all 60 variants share the geometry of their Rest twin', (
      tester,
    ) async {
      // The 12 Rest variants are asserted against a rendered row above. Every
      // other variant differs only in colour, which is the claim this makes
      // checkable rather than assumed.
      for (final variant in spec.variants) {
        final rest = spec.variant(<String, String>{
          ...variant.props,
          'State': 'Rest',
        });
        expect(variant.size, rest.size, reason: '${variant.name}: size');
        expect(variant.radius, rest.radius, reason: '${variant.name}: radius');
        expect(
          variant.padding!.left,
          rest.padding!.left,
          reason: '${variant.name}: indent',
        );
        expect(
          variant.padding!.right,
          rest.padding!.right,
          reason: '${variant.name}: trailing inset',
        );
        expect(
          variant.text!.fontSize,
          rest.text!.fontSize,
          reason: '${variant.name}: fontSize',
        );
        expect(
          variant.text!.lineHeight,
          rest.text!.lineHeight,
          reason: '${variant.name}: lineHeight',
        );
      }
    });

    testWidgets('indent is 24 per level, and a leaf takes one step more', (
      tester,
    ) async {
      await pump(
        tester,
        FluentTree(items: tree(), defaultOpenItems: const <Object>{'branch'}),
      );

      EdgeInsets outerPadding(String label) => tester
          .widgetList<Padding>(
            find.descendant(of: rowOf(label), matching: find.byType(Padding)),
          )
          .first
          .padding
          .resolve(TextDirection.ltr);

      // Level 1 branch: (1 - 1) * 24 = 0. Its level 2 leaf: 2 * 24 = 48.
      expect(outerPadding('Branch').left, 0);
      expect(outerPadding('Branch').right, FluentSpacing.s);
      expect(outerPadding('Leaf').left, 48);

      // Both match `tree-padding-left` / `treeleaf-padding-left`, whose Figma
      // modes are 0/24/48/... and 24/48/72/...
      final branchVariant = spec.variant(<String, String>{
        'Style': 'Subtle',
        'Size': 'Medium',
        'State': 'Rest',
        'Leaf node': 'False',
      });
      expect(branchVariant.token('paddingLeft'), 'tree-padding-left');
      final leafVariant = spec.variant(<String, String>{
        'Style': 'Subtle',
        'Size': 'Medium',
        'State': 'Rest',
        'Leaf node': 'True',
      });
      expect(leafVariant.token('paddingLeft'), 'treeleaf-padding-left');
      expect(leafVariant.padding!.left, 24);
    });

    testWidgets('the chevron column and glyph match the Figma parts', (
      tester,
    ) async {
      await pump(tester, FluentTree(items: tree()));

      final variant = spec.variant(<String, String>{
        'Style': 'Subtle',
        'Size': 'Medium',
        'State': 'Rest',
        'Leaf node': 'False',
      });
      final chevron = variant.part('Chevron');
      expect(chevron.size.width, FluentSpacing.xxl);
      // 24 x 32 with a 6/10 inset leaves a 12 x 12 glyph box.
      expect(chevron.size.width - chevron.padding!.horizontal, 12);
      expect(chevron.size.height - chevron.padding!.vertical, 12);
      expect(chevron.token('fills'), isNull);

      final icon = tester.widget<Icon>(
        find.descendant(of: rowOf('Branch'), matching: find.byType(Icon)),
      );
      expect(icon.icon, FluentIcons.chevron_right_12_regular);
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.byIcon(FluentIcons.chevron_right_12_regular),
                    matching: find.byType(SizedBox),
                  )
                  .first,
            )
            .width,
        FluentSpacing.xxl,
      );
    });

    testWidgets('the leading icon is 16 medium and 12 small, not React 20', (
      tester,
    ) async {
      for (final (size, expected) in <(FluentTreeSize, double)>[
        (FluentTreeSize.medium, 16),
        (FluentTreeSize.small, 12),
      ]) {
        await pump(
          tester,
          FluentTree(
            size: size,
            items: tree(icon: const Icon(FluentIcons.folder_20_regular)),
          ),
        );
        final theme = tester
            .widgetList<IconTheme>(
              find.ancestor(
                of: find.byIcon(FluentIcons.folder_20_regular),
                matching: find.byType(IconTheme),
              ),
            )
            .first;
        expect(theme.data.size, expected, reason: 'icon at $size');

        final variant = spec.variant(<String, String>{
          'Style': 'Subtle',
          'Size': figmaSize(size),
          'State': 'Rest',
          'Leaf node': 'True',
        });
        // The Figma leaf's `Start content > Shape` is the leading icon.
        expect(
          variant.parts
              .where((part) => part.name == 'Shape' && part.size.width > 0)
              .first
              .size
              .width,
          expected,
        );
      }
    });
  });

  group('states', () {
    testWidgets('hover, pressed and rest select their own Figma tokens', (
      tester,
    ) async {
      await pump(tester, FluentTree(items: tree()));
      final colors = light().colors;

      expect(surfaceOf(tester, 'Branch').color, colors.subtleBackground);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: tester.getCenter(rowOf('Branch')));
      await tester.pumpAndSettle();
      expect(surfaceOf(tester, 'Branch').color, colors.subtleBackgroundHover);

      await gesture.down(tester.getCenter(rowOf('Branch')));
      await tester.pumpAndSettle();
      expect(surfaceOf(tester, 'Branch').color, colors.subtleBackgroundPressed);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('subtle alpha and transparent swap the whole ramp', (
      tester,
    ) async {
      final colors = light().colors;
      for (final (appearance, hover) in <(FluentTreeAppearance, Color)>[
        (
          FluentTreeAppearance.subtleAlpha,
          colors.subtleBackgroundLightAlphaHover,
        ),
        (FluentTreeAppearance.transparent, colors.transparentBackgroundHover),
      ]) {
        await pump(tester, FluentTree(appearance: appearance, items: tree()));
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: tester.getCenter(rowOf('Branch')));
        await tester.pumpAndSettle();
        expect(surfaceOf(tester, 'Branch').color, hover, reason: '$appearance');
        await gesture.removePointer();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('selected is a real token ramp, not a tint', (tester) async {
      await pump(
        tester,
        FluentTree(items: tree(), selectedItems: const <Object>{'branch'}),
      );
      expect(
        surfaceOf(tester, 'Branch').color,
        light().colors.subtleBackgroundSelected,
      );
      expect(
        spec
            .variant(<String, String>{
              'Style': 'Subtle',
              'Size': 'Medium',
              'State': 'Selected',
              'Leaf node': 'False',
            })
            .token('fills'),
        'Neutral/Background/Subtle/Selected',
      );
    });

    testWidgets('disabled is a real state: no hover, no focus, no callback', (
      tester,
    ) async {
      var invoked = 0;
      await pump(
        tester,
        FluentTree(items: tree(enabled: false), onInvoke: (_) => invoked++),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: tester.getCenter(rowOf('Branch')));
      await tester.pumpAndSettle();
      // Still the rest token — a disabled row does not report hover at all.
      expect(
        surfaceOf(tester, 'Branch').color,
        light().colors.subtleBackground,
      );

      await tester.tap(rowOf('Branch'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(invoked, 0);

      // And the whole foreground family swaps.
      final text = tester.widget<RichText>(
        find.descendant(
          of: find.text('Branch'),
          matching: find.byType(RichText),
        ),
      );
      expect(text.text.style!.color, light().colors.neutralForegroundDisabled);
    });

    testWidgets('the chevron takes Foreground/3, not the label ramp', (
      tester,
    ) async {
      await pump(tester, FluentTree(items: tree()));
      final theme = tester
          .widgetList<IconTheme>(
            find.ancestor(
              of: find.byIcon(FluentIcons.chevron_right_12_regular),
              matching: find.byType(IconTheme),
            ),
          )
          .first;
      expect(theme.data.color, light().colors.neutralForeground3);
      expect(
        spec
            .variant(<String, String>{
              'Style': 'Subtle',
              'Size': 'Medium',
              'State': 'Rest',
              'Leaf node': 'False',
            })
            .parts
            .firstWhere((part) => part.token('fills') != null)
            .token('fills'),
        'Neutral/Foreground/3/Rest',
      );
    });
  });

  group('composition', () {
    testWidgets('multiple selection composes FluentCheckbox', (tester) async {
      var selected = const <Object>{};
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: StatefulBuilder(
            builder: (context, setState) => Center(
              child: SizedBox(
                width: 280,
                child: FluentTree(
                  selectionMode: FluentTreeSelectionMode.multiple,
                  items: tree(),
                  selectedItems: selected,
                  onSelectionChange: (next) => setState(() => selected = next),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FluentCheckbox), findsNWidgets(2));
      expect(find.byType(FluentRadio<bool>), findsNothing);

      await tester.tap(find.byType(FluentCheckbox).first);
      await tester.pumpAndSettle();
      expect(selected, <Object>{'branch'});
    });

    testWidgets('single selection composes FluentRadio and replaces', (
      tester,
    ) async {
      var selected = const <Object>{'sibling'};
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: StatefulBuilder(
            builder: (context, setState) => Center(
              child: SizedBox(
                width: 280,
                child: FluentTree(
                  selectionMode: FluentTreeSelectionMode.single,
                  items: tree(),
                  selectedItems: selected,
                  onSelectionChange: (next) => setState(() => selected = next),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FluentRadio<bool>), findsNWidgets(2));
      expect(find.byType(FluentCheckbox), findsNothing);

      await tester.tap(find.byType(FluentRadio<bool>).first);
      await tester.pumpAndSettle();
      // Replaced, not accumulated.
      expect(selected, <Object>{'branch'});
    });

    testWidgets('the actions slot renders a real FluentButton', (tester) async {
      var pressed = 0;
      await pump(
        tester,
        FluentTree(
          items: tree(
            actions: FluentButton.icon(
              icon: const Icon(FluentIcons.more_horizontal_20_regular),
              semanticLabel: 'More',
              appearance: FluentButtonAppearance.subtle,
              size: FluentButtonSize.small,
              onPressed: () => pressed++,
            ),
          ),
        ),
      );

      expect(find.byType(FluentButton), findsOneWidget);
      await tester.tap(find.byType(FluentButton));
      await tester.pumpAndSettle();
      expect(pressed, 1);
    });

    testWidgets('focus is drawn by FluentFocusRing, not a bespoke border', (
      tester,
    ) async {
      await pump(tester, FluentTree(items: tree()));
      expect(find.byType(FluentFocusRing), findsNWidgets(2));
      expect(find.byType(FluentInteractive), findsNWidgets(2));
    });
  });

  group('keyboard', () {
    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    /// Which row currently holds primary focus.
    String? focused(WidgetTester tester) {
      for (final label in <String>[
        'Branch',
        'Leaf',
        'Zebra',
        'Zulu',
        'Sibling',
      ]) {
        if (rowOf(label).evaluate().isEmpty) continue;
        final node = tester
            .widget<FluentInteractive>(
              find.ancestor(
                of: rowOf(label),
                matching: find.byType(FluentInteractive),
              ),
            )
            .focusNode;
        if (node != null && node.hasPrimaryFocus) return label;
      }
      return null;
    }

    testWidgets('Down and Up walk the visible rows only', (tester) async {
      await pump(tester, FluentTree(items: tree()));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(focused(tester), 'Branch');

      // The branch is closed, so Down skips its children entirely.
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(focused(tester), 'Sibling');
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(focused(tester), 'Branch');
    });

    testWidgets('Right opens, then descends; Left ascends, then closes', (
      tester,
    ) async {
      await pump(tester, FluentTree(items: tree()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(find.text('Leaf'), findsOneWidget);
      expect(focused(tester), 'Branch');

      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(focused(tester), 'Leaf');

      // On a leaf, Left goes to the parent rather than closing anything.
      await press(tester, LogicalKeyboardKey.arrowLeft);
      expect(focused(tester), 'Branch');
      expect(find.text('Leaf'), findsOneWidget);

      await press(tester, LogicalKeyboardKey.arrowLeft);
      expect(find.text('Leaf'), findsNothing);
    });

    testWidgets('Home and End jump to the ends of the visible list', (
      tester,
    ) async {
      await pump(
        tester,
        FluentTree(items: tree(), defaultOpenItems: const <Object>{'branch'}),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await press(tester, LogicalKeyboardKey.end);
      expect(focused(tester), 'Sibling');
      await press(tester, LogicalKeyboardKey.home);
      expect(focused(tester), 'Branch');
    });

    testWidgets('Space toggles the focused branch', (tester) async {
      await pump(tester, FluentTree(items: tree()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await press(tester, LogicalKeyboardKey.space);
      expect(find.text('Leaf'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.space);
      expect(find.text('Leaf'), findsNothing);
    });

    testWidgets('typeahead jumps to the next matching visible row', (
      tester,
    ) async {
      await pump(
        tester,
        FluentTree(items: tree(), defaultOpenItems: const <Object>{'branch'}),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // One key searches forward from the focused row and wraps.
      await press(tester, LogicalKeyboardKey.keyZ);
      expect(focused(tester), 'Zebra');

      // A second key inside the window extends the prefix rather than starting
      // over: 'zu' can only reach Zulu, and a reset buffer holding 'u' would
      // match nothing and leave focus on Zebra.
      await press(tester, LogicalKeyboardKey.keyU);
      expect(focused(tester), 'Zulu');

      // A prefix that matches nothing leaves focus alone rather than jumping.
      await press(tester, LogicalKeyboardKey.keyQ);
      expect(focused(tester), 'Zulu');
    });

    testWidgets('the whole tree is one tab stop', (tester) async {
      await pump(
        tester,
        FluentTree(items: tree(), defaultOpenItems: const <Object>{'branch'}),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final traversable = <String>[
        for (final label in <String>[
          'Branch',
          'Leaf',
          'Zebra',
          'Zulu',
          'Sibling',
        ])
          if (!tester
              .widget<FluentInteractive>(
                find.ancestor(
                  of: rowOf(label),
                  matching: find.byType(FluentInteractive),
                ),
              )
              .focusNode!
              .skipTraversal)
            label,
      ];
      expect(traversable, <String>['Branch']);
    });

    testWidgets('RTL mirrors Right and Left', (tester) async {
      await pump(
        tester,
        FluentTree(items: tree()),
        direction: TextDirection.rtl,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Left is "further into the tree" when the tree reads right to left.
      await press(tester, LogicalKeyboardKey.arrowLeft);
      expect(find.text('Leaf'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(find.text('Leaf'), findsNothing);
    });

    testWidgets('arrows skip disabled rows', (tester) async {
      await pump(
        tester,
        const FluentTree(
          items: <FluentTreeItem>[
            FluentTreeItem(value: 'a', label: Text('Alpha')),
            FluentTreeItem(value: 'b', label: Text('Bravo'), enabled: false),
            FluentTreeItem(value: 'c', label: Text('Charlie')),
          ],
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowDown);

      final node = tester
          .widget<FluentInteractive>(
            find.ancestor(
              of: rowOf('Charlie'),
              matching: find.byType(FluentInteractive),
            ),
          )
          .focusNode!;
      expect(node.hasPrimaryFocus, isTrue);
    });
  });

  group('semantics', () {
    testWidgets('expanded, selected, enabled and the level are announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentTree(
          items: tree(),
          semanticLabel: 'Files',
          defaultOpenItems: const <Object>{'branch'},
          selectedItems: const <Object>{'leaf'},
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Files')).role,
        SemanticsRole.list,
      );

      final branch = tester.getSemantics(rowOf('Branch'));
      expect(branch.role, SemanticsRole.listItem);
      expect(branch.flagsCollection.isExpanded, Tristate.isTrue);
      expect(branch.identifier, 'fluent-tree-item-level-1');

      final leaf = tester.getSemantics(rowOf('Leaf'));
      expect(leaf.identifier, 'fluent-tree-item-level-2');
      expect(leaf.flagsCollection.isSelected, Tristate.isTrue);
      // A leaf has nothing to expand, so it claims neither expanded nor
      // collapsed rather than lying about being closed.
      expect(leaf.flagsCollection.isExpanded, Tristate.none);

      handle.dispose();
    });

    testWidgets('a collapsed branch reports collapsed, not absent', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, FluentTree(items: tree()));
      final branch = tester.getSemantics(rowOf('Branch'));
      expect(branch.flagsCollection.isExpanded, Tristate.isFalse);
      handle.dispose();
    });
  });

  group('motion', () {
    testWidgets('the chevron rotates on durationNormal / easyEaseMax', (
      tester,
    ) async {
      await pump(tester, FluentTree(items: tree()));

      double turns() => tester
          .widget<FluentAnimatedStyle<double>>(
            find.byType(FluentAnimatedStyle<double>),
          )
          .value;

      expect(turns(), 0);
      await tester.tap(rowOf('Branch'));
      await tester.pump();
      expect(turns(), 0.25);

      // Mid-flight the painted rotation is between the two endpoints, which is
      // the whole claim: the glyph turns rather than swapping.
      await tester.pump(FluentDuration.normal ~/ 2);
      final mid = tester
          .widget<Transform>(
            find.descendant(
              of: rowOf('Branch'),
              matching: find.byType(Transform),
            ),
          )
          .transform;
      expect(mid.isIdentity(), isFalse);
      await tester.pumpAndSettle();

      final spec = tester
          .widget<FluentAnimatedStyle<double>>(
            find.byType(FluentAnimatedStyle<double>),
          )
          .spec;
      expect(spec.duration, FluentDuration.normal);
      expect(spec.curve, FluentCurve.easyEaseMax);
    });

    testWidgets('the surface itself is instant — upstream declares no '
        'transition on the row', (tester) async {
      await pump(tester, FluentTree(items: tree()));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: tester.getCenter(rowOf('Branch')));
      // One frame, not a settle: the hover fill has already arrived.
      await tester.pump();
      expect(
        surfaceOf(tester, 'Branch').color,
        light().colors.subtleBackgroundHover,
      );
    });

    testWidgets('reduced motion lands the chevron on the first frame', (
      tester,
    ) async {
      await pump(tester, FluentTree(items: tree()), reducedMotion: true);
      await tester.tap(rowOf('Branch'));
      await tester.pump();
      await tester.pump();

      final transform = tester
          .widget<Transform>(
            find.descendant(
              of: rowOf('Branch'),
              matching: find.byType(Transform),
            ),
          )
          .transform;
      final settled = Matrix4.rotationZ(0.25 * 2 * 3.141592653589793);
      for (var i = 0; i < 16; i++) {
        expect(transform.storage[i], closeTo(settled.storage[i], 1e-6));
      }
    });
  });

  group('theming', () {
    testWidgets('a subtree FluentThemeOverride reaches the rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(
            child: SizedBox(
              width: 280,
              child: FluentThemeOverride(
                colors: <FluentColorToken, Color>{
                  FluentColorToken.neutralForeground2:
                      dark().colors.neutralForeground2,
                },
                child: FluentTree(items: tree()),
              ),
            ),
          ),
        ),
      );

      final text = tester.widget<RichText>(
        find.descendant(
          of: find.text('Branch'),
          matching: find.byType(RichText),
        ),
      );
      expect(text.text.style!.color, dark().colors.neutralForeground2);
      expect(text.text.style!.color, isNot(light().colors.neutralForeground2));
    });

    testWidgets('FluentTreeItemTheme restyles a subtree and style wins', (
      tester,
    ) async {
      const themed = Color(0xFF102030);
      const own = Color(0xFF405060);

      await pump(
        tester,
        FluentTreeItemTheme(
          style: FluentTreeItemStyle.from(backgroundColor: themed),
          child: FluentTree(items: tree()),
        ),
      );
      expect(surfaceOf(tester, 'Branch').color, themed);

      await pump(
        tester,
        FluentTreeItemTheme(
          style: FluentTreeItemStyle.from(backgroundColor: themed),
          child: FluentTree(
            items: tree(),
            style: FluentTreeItemStyle.from(backgroundColor: own),
          ),
        ),
      );
      expect(surfaceOf(tester, 'Branch').color, own);
    });

    testWidgets('the three-function contract is separable', (tester) async {
      final state = resolveFluentTreeItemState(
        branch: true,
        expanded: true,
        level: 3,
        size: FluentTreeSize.small,
      );
      expect(state.indentSteps, 2);
      expect(
        resolveFluentTreeItemState(level: 3).indentSteps,
        3,
        reason: 'a leaf takes one extra step',
      );
      // A leaf can never report expanded, whatever was passed in.
      expect(resolveFluentTreeItemState(expanded: true).expanded, isFalse);

      final style = resolveFluentTreeItemStyle(state, light());
      expect(style.minimumSize!.resolve(const <WidgetState>{})!.height, 24);

      await pump(
        tester,
        Builder(
          builder: (context) =>
              buildFluentTreeItem(state, style, const <WidgetState>{}),
        ),
      );
      expect(find.byType(FluentFocusRing), findsOneWidget);
    });
  });

  group('high contrast', () {
    testWidgets('no foreground ever matches the surface it paints on', (
      tester,
    ) async {
      final theme = highContrast();
      final colors = theme.colors;

      // Every (row fill, label colour) and (row fill, chevron colour) pair the
      // component can actually resolve to, in high contrast. The bug this
      // guards against shipped for four waves: a token that renders invisible
      // while the layout and the border stay perfect.
      for (final appearance in FluentTreeAppearance.values) {
        for (final selected in <bool>[false, true]) {
          for (final states in <Set<WidgetState>>[
            <WidgetState>{},
            <WidgetState>{WidgetState.hovered},
            <WidgetState>{WidgetState.pressed},
            <WidgetState>{WidgetState.disabled},
          ]) {
            final style = resolveFluentTreeItemStyle(
              resolveFluentTreeItemState(appearance: appearance),
              theme,
            );
            final resolved = selected
                ? <WidgetState>{...states, WidgetState.selected}
                : states;
            var fill = style.backgroundColor!.resolve(resolved)!;
            // A transparent fill shows the page behind it, which is what the
            // foreground actually has to read against.
            if (fill.a == 0) fill = colors.neutralBackground1;

            final label = style.foregroundColor!.resolve(resolved)!;
            final chevron = style.expandIconColor!.resolve(resolved)!;
            final where = '$appearance selected=$selected states=$resolved';
            expect(
              label.toARGB32(),
              isNot(fill.toARGB32()),
              reason: 'label invisible on its own row: $where',
            );
            expect(
              chevron.toARGB32(),
              isNot(fill.toARGB32()),
              reason: 'chevron invisible on its own row: $where',
            );
          }
        }
      }
    });

    testWidgets('a rendered high-contrast row keeps its label readable', (
      tester,
    ) async {
      await pump(
        tester,
        FluentTree(
          appearance: FluentTreeAppearance.transparent,
          items: tree(),
          selectedItems: const <Object>{'branch'},
        ),
        theme: highContrast(),
      );

      final fill = surfaceOf(tester, 'Branch').color!;
      final label = tester
          .widget<RichText>(
            find.descendant(
              of: find.text('Branch'),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!
          .color!;
      final behind = fill.a == 0
          ? highContrast().colors.neutralBackground1
          : fill;
      expect(label.toARGB32(), isNot(behind.toARGB32()));
    });

    testWidgets('no transparent colour is hardcoded — every fill is a token', (
      tester,
    ) async {
      final theme = highContrast();
      final style = resolveFluentTreeItemStyle(
        resolveFluentTreeItemState(
          appearance: FluentTreeAppearance.transparent,
        ),
        theme,
      );
      // The interactive transparent tokens turn OPAQUE in high contrast. If any
      // of them had been written as `Colors.transparent` this would still be
      // zero-alpha, and the row would give a keyboard user no feedback at all.
      expect(
        style.backgroundColor!.resolve(const <WidgetState>{
          WidgetState.hovered,
        })!.a,
        greaterThan(0),
      );
      expect(
        style.backgroundColor!.resolve(const <WidgetState>{
          WidgetState.pressed,
        })!.a,
        greaterThan(0),
      );
    });
  });

  group('open state', () {
    testWidgets(
      'uncontrolled toggles on click, controlled never self-mutates',
      (tester) async {
        await pump(tester, FluentTree(items: tree()));
        await tester.tap(rowOf('Branch'));
        await tester.pumpAndSettle();
        expect(find.text('Leaf'), findsOneWidget);

        var reported = <Object>{};
        await pump(
          tester,
          FluentTree(
            items: tree(),
            openItems: const <Object>{},
            onOpenChange: (next) => reported = next,
          ),
        );
        await tester.tap(rowOf('Branch'));
        await tester.pumpAndSettle();
        expect(reported, <Object>{'branch'});
        // Controlled: the widget reported, and changed nothing itself.
        expect(find.text('Leaf'), findsNothing);
      },
    );

    testWidgets('clicking a leaf reports invocation without opening anything', (
      tester,
    ) async {
      final invoked = <Object>[];
      await pump(
        tester,
        FluentTree(
          items: tree(),
          defaultOpenItems: const <Object>{'branch'},
          onInvoke: invoked.add,
        ),
      );
      await tester.tap(rowOf('Leaf'));
      await tester.pumpAndSettle();
      expect(invoked, <Object>['leaf']);
      expect(find.text('Leaf'), findsOneWidget);
    });
  });
}
