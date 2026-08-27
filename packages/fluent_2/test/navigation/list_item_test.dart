import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// Pinned against `test/fixtures/list_item.json` — the Figma `ListItem` set
/// (`9328:24865`, page `8995:4`), all 40 variants of
/// `Size` x `ListItem type` x `State` x `Active`.
///
/// Every axis is walked in the `spec` group: two sizes, one line and two,
/// five states and both `Active` values. `State=Focus` is asserted there too,
/// because this port draws the ring with `FluentFocusRing` rather than as a
/// variant of the row.
///
/// **Motion: none, and that is the spec.** `useListItemStyles.styles.ts` and
/// `useListStyles.styles.ts` on `microsoft/fluentui@master` declare no
/// `transition`, no `animation` and no `motionTokens` reference at all, so the
/// fill changes on the frame the pointer arrives. There is nothing for
/// `MediaQuery.disableAnimations` to shorten, which the reduced-motion test
/// below pins by producing a byte-identical tree.
void main() {
  final spec = loadSpec('list_item');
  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  const itemKey = Key('row-a');
  const otherKey = Key('row-b');
  const thirdKey = Key('row-c');

  const sizeNames = <FluentListItemSize, String>{
    FluentListItemSize.small: 'Small',
    FluentListItemSize.medium: 'Medium',
  };

  Widget list({
    FluentListItemSize size = FluentListItemSize.medium,
    FluentListSelection selection = FluentListSelection.none,
    Set<String> selected = const <String>{},
    ValueChanged<Set<String>>? onSelectionChange,
    bool twoLine = false,
    bool enabled = true,
    bool secondEnabled = true,
    bool withTertiary = true,
    bool withMedia = false,
    bool withTrailing = false,
    FluentListItemStyle? listStyle,
    FluentListItemStyle? itemStyle,
    String? semanticLabel,
    String? itemSemanticLabel,
  }) => FluentList<String>(
    size: size,
    selection: selection,
    selectedValues: selected,
    onSelectionChange: onSelectionChange ?? (_) {},
    style: listStyle,
    semanticLabel: semanticLabel,
    items: <FluentListItem<String>>[
      FluentListItem<String>(
        key: itemKey,
        value: 'a',
        enabled: enabled,
        style: itemStyle,
        semanticLabel: itemSemanticLabel,
        media: withMedia ? const SizedBox.square(dimension: 16) : null,
        tertiary: withTertiary ? const Text('9:41') : null,
        secondary: twoLine ? const Text('Sub') : null,
        trailing: withTrailing
            ? const SizedBox.square(dimension: 24, key: Key('trailing'))
            : null,
        child: const Text('Title'),
      ),
      FluentListItem<String>(
        key: otherKey,
        value: 'b',
        enabled: secondEnabled,
        secondary: twoLine ? const Text('Sub') : null,
        child: const Text('Second'),
      ),
      FluentListItem<String>(
        key: thirdKey,
        value: 'c',
        secondary: twoLine ? const Text('Sub') : null,
        child: const Text('Third'),
      ),
    ],
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FluentThemeData? theme,
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light,
      builder: reducedMotion
          ? (context, inner) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: inner!,
            )
          : null,
      home: Align(
        alignment: Alignment.topLeft,
        // Figma's frames are a fixed 340 wide; the widget hugs unless bounded,
        // so the width is pinned here and asserted like every other number.
        child: SizedBox(width: 340, child: child),
      ),
    ),
  );

  Iterable<DecoratedBox> boxesOf(WidgetTester tester, Finder of) =>
      tester.widgetList<DecoratedBox>(
        find.descendant(of: of, matching: find.byType(DecoratedBox)),
      );

  BoxDecoration surfaceOf(WidgetTester tester, {Finder? of}) =>
      boxesOf(tester, of ?? find.byKey(itemKey)).first.decoration
          as BoxDecoration;

  EdgeInsets paddingOf(WidgetTester tester, {Finder? of}) => tester
      .widgetList<Padding>(
        find.descendant(
          of: of ?? find.byKey(itemKey),
          matching: find.byType(Padding),
        ),
      )
      .first
      .padding
      .resolve(TextDirection.ltr);

  /// The style the given text actually painted with, read off [RichText]
  /// rather than [Text] because that is where the ambient `DefaultTextStyle`
  /// has already been merged in. Scoped to one row, since every row in the
  /// fixtures below carries the same placeholder strings.
  TextStyle textStyleOf(
    WidgetTester tester,
    String data, {
    Key key = itemKey,
  }) => tester
      .widget<RichText>(
        find
            .descendant(
              of: find.byKey(key),
              matching: find.byWidgetPredicate((w) {
                if (w is! RichText) return false;
                final span = w.text;
                return span is TextSpan && span.toPlainText() == data;
              }),
            )
            .first,
      )
      .text
      .style!;

  FluentFocusRingPainter ringOf(WidgetTester tester, Key key) =>
      tester
              .widgetList<CustomPaint>(
                find.descendant(
                  of: find.byKey(key),
                  matching: find.byType(CustomPaint),
                ),
              )
              .first
              .foregroundPainter!
          as FluentFocusRingPainter;

  /// Figma records a fully transparent token as transparent *white*
  /// (`#00FFFFFF`) because it cannot store a colour without an RGB triple;
  /// core stores CSS `transparent`, which is transparent black. Only the alpha
  /// is comparable — see `doc/token-divergences.md`.
  void expectFill(Color actual, Color? expected, String reason) {
    if (expected == null || expected.a == 0) {
      expect(actual.a, 0, reason: '$reason (alpha only: transparent token)');
      return;
    }
    expect(actual.toARGB32(), expected.toARGB32(), reason: reason);
  }

  void expectNumber(String where, double expected, double actual) =>
      expect(actual, closeTo(expected, 0.01), reason: where);

  group('spec', () {
    testWidgets('all 40 variants match Figma', (tester) async {
      final previous = FocusManager.instance.highlightStrategy;
      addTearDown(() => FocusManager.instance.highlightStrategy = previous);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;

      var covered = 0;
      for (final size in FluentListItemSize.values) {
        for (final twoLine in <bool>[false, true]) {
          for (final active in <bool>[false, true]) {
            for (final state in <String>[
              'Rest',
              'Hover',
              'Pressed',
              'Disabled',
              'Focus',
            ]) {
              final variant = spec.variant(<String, String>{
                'Size': sizeNames[size]!,
                'ListItem type': twoLine ? 'Two line' : 'One line',
                'State': state,
                'Active': active ? 'True' : 'False',
              });
              final where = variant.name;

              await pump(
                tester,
                list(
                  size: size,
                  twoLine: twoLine,
                  selected: active ? const <String>{'a'} : const <String>{},
                  enabled: state != 'Disabled',
                ),
              );
              await tester.pumpAndSettle();

              TestGesture? mouse;
              if (state == 'Hover' || state == 'Pressed') {
                mouse = await tester.createGesture(
                  kind: PointerDeviceKind.mouse,
                );
                await mouse.addPointer(location: Offset.zero);
                await tester.pump();
                await mouse.moveTo(tester.getCenter(find.byKey(itemKey)));
                await tester.pump();
                if (state == 'Pressed') {
                  await mouse.down(tester.getCenter(find.byKey(itemKey)));
                  await tester.pump();
                }
              }
              if (state == 'Focus') {
                // Tab rather than an arrow: `NextFocusIntent` lands on the
                // first focusable node deterministically, where a directional
                // arrow depends on the traversal policy's geometry.
                await tester.sendKeyEvent(LogicalKeyboardKey.tab);
                await tester.pump();
              }

              final size2 = tester.getSize(find.byKey(itemKey));
              expectNumber('$where: width', variant.size.width, size2.width);
              expectNumber('$where: height', variant.size.height, size2.height);

              final surface = surfaceOf(tester);
              expect(
                surface.borderRadius?.resolve(TextDirection.ltr),
                variant.radius,
                reason: '$where: radius',
              );
              expectFill(
                surface.color!,
                variant.fill,
                '$where: fill (token ${variant.token('fills')})',
              );

              final padding = paddingOf(tester);
              final expected = variant.padding!;
              expectNumber('$where: padding.top', expected.top, padding.top);
              expectNumber(
                '$where: padding.right',
                expected.right,
                padding.right,
              );
              expectNumber(
                '$where: padding.bottom',
                expected.bottom,
                padding.bottom,
              );
              expectNumber('$where: padding.left', expected.left, padding.left);

              // The variant-level text block is the first TEXT under the
              // frame, which is the title on every one of the 40 variants.
              final title = variant.text!;
              final titleStyle = textStyleOf(tester, 'Title');
              expectNumber(
                '$where: title.fontSize',
                title.fontSize,
                titleStyle.fontSize!,
              );
              expectNumber(
                '$where: title.lineHeight',
                title.lineHeight,
                titleStyle.height! * titleStyle.fontSize!,
              );
              expect(
                titleStyle.fontWeight,
                active ? FontWeight.w600 : FontWeight.w400,
                reason: '$where: Active steps the title to Semibold',
              );

              if (twoLine) {
                final secondary = variant.part('Secondary text').text!;
                final secondaryStyle = textStyleOf(tester, 'Sub');
                expectNumber(
                  '$where: secondary.fontSize',
                  secondary.fontSize,
                  secondaryStyle.fontSize!,
                );
                expectNumber(
                  '$where: secondary.lineHeight',
                  secondary.lineHeight,
                  secondaryStyle.height! * secondaryStyle.fontSize!,
                );
              } else {
                // `00:00 AM` is Figma's own placeholder for the trailing
                // metadata slot, and on a one-line row it is a real TEXT part
                // rather than a swap-area label.
                final tertiary = variant.part('00:00 AM').text!;
                final tertiaryStyle = textStyleOf(tester, '9:41');
                expectNumber(
                  '$where: tertiary.fontSize',
                  tertiary.fontSize,
                  tertiaryStyle.fontSize!,
                );
                expectNumber(
                  '$where: tertiary.lineHeight',
                  tertiary.lineHeight,
                  tertiaryStyle.height! * tertiaryStyle.fontSize!,
                );
              }

              // The 24px selection frame and its vertical inset, which is what
              // centres the affordance on the row.
              final selectionFrame = variant.part('Selection Container (24px)');
              expect(
                selectionFrame.size.width,
                24,
                reason: '$where: the selection frame is 24 at every size',
              );

              if (state == 'Focus') {
                expect(
                  ringOf(tester, itemKey).visible,
                  isTrue,
                  reason: '$where: the focus ring is drawn',
                );
              }

              if (mouse != null) {
                if (state == 'Pressed') await mouse.up();
                await mouse.removePointer();
                await tester.pump();
              }
              covered++;
            }
          }
        }
      }
      expect(covered, 40, reason: 'every variant of the set was asserted');
    });

    testWidgets('the selection frame inset centres the affordance', (
      tester,
    ) async {
      for (final size in FluentListItemSize.values) {
        for (final twoLine in <bool>[false, true]) {
          final variant = spec.variant(<String, String>{
            'Size': sizeNames[size]!,
            'ListItem type': twoLine ? 'Two line' : 'One line',
            'State': 'Rest',
            'Active': 'False',
          });
          final frame = variant.part('Selection Container (24px)');

          await pump(
            tester,
            list(
              size: size,
              twoLine: twoLine,
              selection: FluentListSelection.checkbox,
            ),
          );
          await tester.pumpAndSettle();

          final box = tester.getRect(
            find.descendant(
              of: find.byKey(itemKey),
              matching: find.byType(FluentCheckbox),
            ),
          );
          final row = tester.getRect(find.byKey(itemKey));
          expectNumber(
            '${variant.name}: selection top inset',
            frame.padding!.top,
            box.top - row.top,
          );
          expectNumber(
            '${variant.name}: selection box',
            frame.size.width,
            box.width,
          );
        }
      }
    });
  });

  group('composition', () {
    testWidgets('the affordance is the real FluentCheckbox / FluentRadio', (
      tester,
    ) async {
      await pump(tester, list(selection: FluentListSelection.checkbox));
      await tester.pumpAndSettle();
      expect(find.byType(FluentCheckbox), findsNWidgets(3));
      expect(find.byType(FluentRadio<bool>), findsNothing);

      await pump(tester, list(selection: FluentListSelection.radio));
      await tester.pumpAndSettle();
      expect(find.byType(FluentRadio<bool>), findsNWidgets(3));
      expect(find.byType(FluentCheckbox), findsNothing);

      await pump(tester, list());
      await tester.pumpAndSettle();
      expect(find.byType(FluentCheckbox), findsNothing);
      expect(find.byType(FluentRadio<bool>), findsNothing);
    });

    testWidgets('the composed control paints the row\'s checked state', (
      tester,
    ) async {
      await pump(
        tester,
        list(
          selection: FluentListSelection.checkbox,
          selected: const <String>{'a'},
        ),
      );
      await tester.pumpAndSettle();
      final checked = tester.widget<FluentCheckbox>(
        find
            .descendant(
              of: find.byKey(itemKey),
              matching: find.byType(FluentCheckbox),
            )
            .first,
      );
      expect(checked.checked, isTrue);
      final unchecked = tester.widget<FluentCheckbox>(
        find
            .descendant(
              of: find.byKey(otherKey),
              matching: find.byType(FluentCheckbox),
            )
            .first,
      );
      expect(unchecked.checked, isFalse);
    });

    testWidgets('the affordance is inert: one focus stop and one tap target', (
      tester,
    ) async {
      final picked = <Set<String>>[];
      await pump(
        tester,
        list(
          selection: FluentListSelection.checkbox,
          onSelectionChange: picked.add,
        ),
      );
      await tester.pumpAndSettle();

      // Tapping the checkbox reaches the row, not the checkbox: the row's own
      // toggle fires exactly once with the row's value.
      await tester.tap(
        find
            .descendant(
              of: find.byKey(itemKey),
              matching: find.byType(FluentCheckbox),
            )
            .first,
      );
      await tester.pump();
      expect(picked, <Set<String>>[
        <String>{'a'},
      ]);

      // And the checkbox contributes no focus stop of its own. It used to be
      // three rows, three traversable nodes; the list is now one composite tab
      // stop, so the assertion that the affordance adds nothing is that the
      // count is still exactly the list's own one — a focusable checkbox would
      // show up as a second.
      final scope = FocusScope.of(tester.element(find.byKey(itemKey)));
      expect(
        scope.traversalDescendants.length,
        1,
        reason: 'three rows, one roving tab stop, and no checkbox stop',
      );
    });
  });

  group('motion', () {
    testWidgets('the fill changes on the frame the pointer arrives', (
      tester,
    ) async {
      await pump(tester, list());
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color!.a, 0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(itemKey)));
      // A single pump, not pumpAndSettle: an animated surface would still be
      // part-way through the tween here.
      await tester.pump();
      expect(
        surfaceOf(tester).color,
        light.colors.subtleBackgroundHover,
        reason: 'upstream declares no transition on a list item',
      );
    });

    testWidgets('reduced motion changes nothing, because nothing animates', (
      tester,
    ) async {
      await pump(tester, list(selected: const <String>{'a'}));
      await tester.pumpAndSettle();
      final normal = surfaceOf(tester).color;

      await pump(
        tester,
        list(selected: const <String>{'a'}),
        reducedMotion: true,
      );
      // One pump, no settling: with animations disabled the row must already
      // be at its final colour.
      await tester.pump();
      expect(surfaceOf(tester).color, normal);
      expect(find.byType(FluentAnimatedStyle<Color>), findsNothing);
    });
  });

  group('style', () {
    testWidgets('theme, then subtree theme, then list, then item', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      const listLevel = Color(0xFF222222);
      const itemLevel = Color(0xFF333333);

      await pump(
        tester,
        FluentListItemTheme(
          style: FluentListItemStyle.from(backgroundColor: themed),
          child: list(),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, themed);

      await pump(
        tester,
        FluentListItemTheme(
          style: FluentListItemStyle.from(backgroundColor: themed),
          child: list(
            listStyle: FluentListItemStyle.from(backgroundColor: listLevel),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, listLevel);

      await pump(
        tester,
        FluentListItemTheme(
          style: FluentListItemStyle.from(backgroundColor: themed),
          child: list(
            listStyle: FluentListItemStyle.from(backgroundColor: listLevel),
            itemStyle: FluentListItemStyle.from(backgroundColor: itemLevel),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, itemLevel);
    });

    testWidgets('merge is per-property and copyWith round-trips', (
      tester,
    ) async {
      const a = FluentListItemStyle(
        backgroundColor: WidgetStatePropertyAll<Color?>(Color(0xFF010101)),
        selectionSize: WidgetStatePropertyAll<double?>(24),
      );
      const b = FluentListItemStyle(
        selectionSize: WidgetStatePropertyAll<double?>(32),
      );
      expect(a.merge(b).backgroundColor, a.backgroundColor);
      expect(a.merge(b).selectionSize, b.selectionSize);
      expect(a.merge(null), a);
      expect(a.copyWith(), a);
      expect(a.copyWith() == a, isTrue);
      expect(a.copyWith().hashCode, a.hashCode);
    });

    testWidgets('a FluentThemeOverride around the list reaches every row', (
      tester,
    ) async {
      const override = Color(0xFF123456);
      await pump(
        tester,
        FluentThemeOverride(
          colors: const <FluentColorToken, Color>{
            FluentColorToken.subtleBackgroundSelected: override,
          },
          child: list(selected: const <String>{'a'}),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, override);
    });
  });

  group('high contrast', () {
    testWidgets('no foreground ever matches the surface it paints on', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );

      Future<void> check(String where, {required bool selected}) async {
        final surface = surfaceOf(tester).color!;
        // A transparent row paints on whatever is behind it, which in this
        // theme is `neutralBackground1`.
        final behind = surface.a == 0
            ? theme.colors.neutralBackground1
            : surface;
        for (final data in <String>['Title', 'Sub', '9:41']) {
          final colour = textStyleOf(tester, data).color!;
          expect(
            colour.toARGB32(),
            isNot(behind.toARGB32()),
            reason: '$where: "$data" is invisible on its own surface',
          );
          expect(colour.a, 1.0, reason: '$where: "$data" is translucent');
        }
        expect(
          behind.a,
          1.0,
          reason: '$where: the resolved surface has to be opaque',
        );
        if (selected) {
          expect(
            textStyleOf(tester, 'Title').color,
            theme.colors.neutralForeground1Selected,
            reason:
                '$where: the selected row takes HighlightText, not the Rest '
                'foreground — Figma binds Rest, which is white on cyan here',
          );
        }
      }

      for (final selected in <bool>[false, true]) {
        for (final state in <String>['Rest', 'Hover', 'Pressed', 'Disabled']) {
          await pump(
            tester,
            list(
              twoLine: true,
              selected: selected ? const <String>{'a'} : const <String>{},
              enabled: state != 'Disabled',
            ),
            theme: theme,
          );
          await tester.pumpAndSettle();

          TestGesture? mouse;
          if (state == 'Hover' || state == 'Pressed') {
            mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
            await mouse.addPointer(location: Offset.zero);
            await tester.pump();
            await mouse.moveTo(tester.getCenter(find.byKey(itemKey)));
            await tester.pump();
            if (state == 'Pressed') {
              await mouse.down(tester.getCenter(find.byKey(itemKey)));
              await tester.pump();
            }
          }

          await check(
            'selected=$selected state=$state',
            selected: selected && state != 'Disabled',
          );

          if (mouse != null) {
            if (state == 'Pressed') await mouse.up();
            await mouse.removePointer();
            await tester.pump();
          }
        }
      }
    });

    testWidgets('the composed affordance collapses onto the Highlight fill', (
      tester,
    ) async {
      // Pinned, not fixed. In this theme `compoundBrandStroke`,
      // `compoundBrandForeground1`, `compoundBrandBackground` and
      // `subtleBackgroundSelected` are all the system Highlight, so a *checked*
      // FluentCheckbox or FluentRadio has nothing left to draw against a
      // selected row. That is a gap in those two components' own tone tables —
      // it reproduces on any Highlight surface, not just a list — and closing
      // it from here would mean forking their token tables through `style`,
      // which is the drift this port exists to avoid. Recorded so it is not
      // rediscovered as a `FluentListItem` bug.
      final c = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      ).colors;
      expect(c.compoundBrandStroke, c.subtleBackgroundSelected);
      expect(c.compoundBrandForeground1, c.subtleBackgroundSelected);
      expect(c.compoundBrandBackground, c.subtleBackgroundSelected);
      // The row's own three ramps are unaffected, which the test above proves.
      expect(c.neutralForeground1Selected, isNot(c.subtleBackgroundSelected));
    });

    testWidgets('the focus ring stays two-tone and opaque', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(tester, list(), theme: theme);
      await tester.pumpAndSettle();
      final ring = ringOf(tester, itemKey);
      expect(ring.outer.a, 1.0);
      expect(ring.inner.a, 1.0);
      expect(ring.outer, isNot(ring.inner));
    });
  });

  group('disabled', () {
    testWidgets('is a real state, not a treatment', (tester) async {
      final picked = <Set<String>>[];
      await pump(tester, list(enabled: false, onSelectionChange: picked.add));
      await tester.pumpAndSettle();

      expect(surfaceOf(tester).color, light.colors.neutralBackgroundDisabled);
      expect(
        textStyleOf(tester, 'Title').color,
        light.colors.neutralForegroundDisabled,
      );

      // No hover, whatever the pointer does.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(itemKey)));
      await tester.pump();
      expect(surfaceOf(tester).color, light.colors.neutralBackgroundDisabled);

      // No selection, and no focus.
      await tester.tap(find.byKey(itemKey));
      await tester.pump();
      expect(picked, isEmpty);
    });

    testWidgets('a list with no callback makes every row inert', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentList<String>(
          items: <FluentListItem<String>>[
            FluentListItem<String>(
              key: itemKey,
              value: 'a',
              child: Text('Title'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(itemKey)));
      await tester.pump();
      expect(surfaceOf(tester).color!.a, 0, reason: 'still at rest');
    });
  });

  group('keyboard', () {
    Future<void> pumpLive(
      WidgetTester tester, {
      FluentListSelection selection = FluentListSelection.checkbox,
      bool secondEnabled = true,
      Set<String> initial = const <String>{},
    }) async {
      final previous = FocusManager.instance.highlightStrategy;
      addTearDown(() => FocusManager.instance.highlightStrategy = previous);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      var selected = initial;
      await tester.pumpWidget(
        FluentApp(
          theme: light,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 340,
              child: StatefulBuilder(
                builder: (context, setState) => FluentList<String>(
                  selection: selection,
                  selectedValues: selected,
                  onSelectionChange: (values) =>
                      setState(() => selected = values),
                  items: <FluentListItem<String>>[
                    const FluentListItem<String>(
                      key: itemKey,
                      value: 'a',
                      child: Text('First'),
                    ),
                    FluentListItem<String>(
                      key: otherKey,
                      value: 'b',
                      enabled: secondEnabled,
                      child: const Text('Second'),
                    ),
                    const FluentListItem<String>(
                      key: thirdKey,
                      value: 'c',
                      child: Text('Third'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    bool focused(WidgetTester tester, Key key) => ringOf(tester, key).visible;

    /// Tab into the list, which is how a keyboard user arrives: the arrow and
    /// Home/End shortcuts are declared *inside* `FluentList`, so they only
    /// route once a row holds focus.
    Future<void> enter(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }

    testWidgets('arrows move focus and do not select', (tester) async {
      await pumpLive(tester);
      await enter(tester);
      expect(focused(tester, itemKey), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focused(tester, otherKey), isTrue);
      expect(focused(tester, itemKey), isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focused(tester, itemKey), isTrue);

      // Nothing has been selected by travelling.
      expect(
        tester
            .widget<FluentCheckbox>(
              find
                  .descendant(
                    of: find.byKey(itemKey),
                    matching: find.byType(FluentCheckbox),
                  )
                  .first,
            )
            .checked,
        isFalse,
      );
    });

    testWidgets('space toggles the focused row', (tester) async {
      await pumpLive(tester);
      await enter(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      FluentCheckbox boxIn(Key key) => tester.widget<FluentCheckbox>(
        find
            .descendant(
              of: find.byKey(key),
              matching: find.byType(FluentCheckbox),
            )
            .first,
      );
      expect(boxIn(itemKey).checked, isTrue);

      // Additive: a second row joins the first.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(boxIn(itemKey).checked, isTrue);
      expect(boxIn(otherKey).checked, isTrue);

      // And space again takes it back off.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(boxIn(otherKey).checked, isFalse);
    });

    testWidgets('radio mode is single-select and never deselects', (
      tester,
    ) async {
      await pumpLive(tester, selection: FluentListSelection.radio);
      await enter(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      FluentRadio<bool> radioIn(Key key) => tester.widget<FluentRadio<bool>>(
        find
            .descendant(
              of: find.byKey(key),
              matching: find.byType(FluentRadio<bool>),
            )
            .first,
      );
      expect(radioIn(itemKey).groupValue, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(radioIn(otherKey).groupValue, isTrue);
      expect(radioIn(itemKey).groupValue, isFalse, reason: 'single select');

      // Re-activating the selected row keeps it selected.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(radioIn(otherKey).groupValue, isTrue);
    });

    testWidgets('home and end jump, disabled rows are skipped, ends hold', (
      tester,
    ) async {
      await pumpLive(tester, secondEnabled: false);
      await enter(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(focused(tester, thirdKey), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(
        focused(tester, thirdKey),
        isTrue,
        reason: 'the end does not wrap',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(
        focused(tester, itemKey),
        isTrue,
        reason: 'the disabled middle row is skipped',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(
        focused(tester, itemKey),
        isTrue,
        reason: 'the start does not wrap',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(focused(tester, itemKey), isTrue);
    });
  });

  /// The WAI-ARIA composite-widget rule the `SemanticsRole.list` /
  /// `SemanticsRole.listItem` pair above already claims: the list is ONE stop
  /// in the Tab order, and the arrows move inside it.
  group('roving focus', () {
    /// The row that holds primary focus, by value.
    ///
    /// Read off the focus tree rather than off the ring, so it does not depend
    /// on the focus-visible heuristics the ring is gated on.
    String? focusedRow() => FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<FluentListItem<String>>()
        ?.value;

    /// The list between two ordinary buttons, which is what makes "Tab leaves"
    /// and "Tab comes back" observable at all.
    Widget roving({
      required FocusNode before,
      required FocusNode after,
      required ValueChanged<Set<String>>? onSelectionChange,
      bool secondEnabled = true,
    }) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FluentButton(
          focusNode: before,
          onPressed: () {},
          child: const Text('before'),
        ),
        FluentList<String>(
          onSelectionChange: onSelectionChange,
          items: <FluentListItem<String>>[
            const FluentListItem<String>(
              key: itemKey,
              value: 'a',
              child: Text('First'),
            ),
            FluentListItem<String>(
              key: otherKey,
              value: 'b',
              enabled: secondEnabled,
              child: const Text('Second'),
            ),
            const FluentListItem<String>(
              key: thirdKey,
              value: 'c',
              child: Text('Third'),
            ),
          ],
        ),
        FluentButton(
          focusNode: after,
          onPressed: () {},
          child: const Text('after'),
        ),
      ],
    );

    Future<void> pumpRoving(
      WidgetTester tester,
      Widget child, {
      FluentThemeData? theme,
    }) async {
      await tester.pumpWidget(
        FluentApp(
          theme: theme ?? light,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 340, child: child),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the whole list is one tab stop', (tester) async {
      final before = FocusNode(debugLabel: 'before');
      final after = FocusNode(debugLabel: 'after');
      addTearDown(before.dispose);
      addTearDown(after.dispose);

      await pumpRoving(
        tester,
        roving(before: before, after: after, onSelectionChange: (_) {}),
      );

      before.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(focusedRow(), 'a', reason: 'Tab enters at the first live row');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        focusedRow(),
        isNull,
        reason: 'the second row is not a second tab stop',
      );
      expect(after.hasFocus, isTrue, reason: 'Tab leaves the list');
    });

    testWidgets('arrowing inside the list does not add a stop', (tester) async {
      final before = FocusNode(debugLabel: 'before');
      final after = FocusNode(debugLabel: 'after');
      addTearDown(before.dispose);
      addTearDown(after.dispose);

      await pumpRoving(
        tester,
        roving(before: before, after: after, onSelectionChange: (_) {}),
      );

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(focusedRow(), 'b', reason: 'the arrows still move inside');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(after.hasFocus, isTrue, reason: 'and it is still one stop');
    });

    testWidgets('a Tab round trip returns to the row that was left', (
      tester,
    ) async {
      final before = FocusNode(debugLabel: 'before');
      final after = FocusNode(debugLabel: 'after');
      addTearDown(before.dispose);
      addTearDown(after.dispose);

      await pumpRoving(
        tester,
        roving(before: before, after: after, onSelectionChange: (_) {}),
      );

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(focusedRow(), 'c');

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(focusedRow(), 'c', reason: 'back to the row that was left');
    });

    testWidgets('disabling the row that holds the stop does not strand the '
        'list', (tester) async {
      final before = FocusNode(debugLabel: 'before');
      final after = FocusNode(debugLabel: 'after');
      addTearDown(before.dispose);
      addTearDown(after.dispose);
      final picked = <Set<String>>[];

      // A stable callback and const rows on purpose: with them the list's own
      // scope stops notifying, so a row only rebuilds when its own widget
      // changes. That is what leaves row 'a' holding the `skipTraversal: true`
      // it latched while its gate was shut, and makes the re-park below a real
      // test of the un-latch rather than of an incidental rebuild.
      await pumpRoving(
        tester,
        roving(before: before, after: after, onSelectionChange: picked.add),
      );

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(focusedRow(), 'b', reason: 'the stop is on the second row');

      await pumpRoving(
        tester,
        roving(
          before: before,
          after: after,
          onSelectionChange: picked.add,
          secondEnabled: false,
        ),
      );

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(
        focusedRow(),
        'a',
        reason: 'the stop re-parks on the first row that can hold it',
      );
    });

    testWidgets('a null onSelectionChange leaves no tab stop at all', (
      tester,
    ) async {
      final before = FocusNode(debugLabel: 'before');
      final after = FocusNode(debugLabel: 'after');
      addTearDown(before.dispose);
      addTearDown(after.dispose);

      await pumpRoving(
        tester,
        roving(before: before, after: after, onSelectionChange: null),
      );

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(
        after.hasFocus,
        isTrue,
        reason:
            'zero live rows means zero tab stops, not one forced onto a row '
            'nobody can operate',
      );
    });
  });

  group('semantics', () {
    testWidgets('a list of list items, each carrying its own state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        list(
          selection: FluentListSelection.checkbox,
          selected: const <String>{'a'},
          secondEnabled: false,
          semanticLabel: 'Messages',
        ),
      );
      await tester.pumpAndSettle();

      final selected = tester.getSemantics(find.byKey(itemKey));
      expect(selected.role, SemanticsRole.listItem);
      expect(
        selected,
        isSemantics(
          hasSelectedState: true,
          isSelected: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      final disabled = tester.getSemantics(find.byKey(otherKey));
      expect(
        disabled,
        isSemantics(
          hasSelectedState: true,
          isSelected: false,
          hasEnabledState: true,
          isEnabled: false,
          // A disabled row must not announce as activatable.
          hasTapAction: false,
        ),
      );

      // The composed checkbox is excluded, so the row announces once rather
      // than as "list item" containing "checkbox".
      expect(
        selected,
        isNot(isSemantics(hasCheckedState: true)),
        reason: 'the affordance contributes no node of its own',
      );

      final listNode = selected.parent!;
      expect(listNode.role, SemanticsRole.list);
      expect(listNode.label, 'Messages');
      handle.dispose();
    });

    testWidgets('a semantic label replaces the row text', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, list(itemSemanticLabel: 'Ada Lovelace, unread'));
      await tester.pumpAndSettle();
      // MergeSemantics folds the row's own text in after the label, so the
      // label is what a screen reader reads *first*.
      expect(
        tester.getSemantics(find.byKey(itemKey)).label,
        startsWith('Ada Lovelace, unread'),
      );
      handle.dispose();
    });
  });

  group('layout', () {
    testWidgets('every slot is placed, in reading order', (tester) async {
      await pump(
        tester,
        list(
          twoLine: true,
          selection: FluentListSelection.checkbox,
          withMedia: true,
          withTrailing: true,
        ),
      );
      await tester.pumpAndSettle();

      Rect inItem(Finder matching) => tester.getRect(
        find.descendant(of: find.byKey(itemKey), matching: matching).first,
      );

      final row = tester.getRect(find.byKey(itemKey));
      final indicator = inItem(find.byType(FluentCheckbox));
      final title = inItem(find.text('Title'));
      final tertiary = inItem(find.text('9:41'));
      final trailing = inItem(find.byKey(const Key('trailing')));
      final secondary = inItem(find.text('Sub'));

      expect(indicator.left, greaterThanOrEqualTo(row.left));
      expect(title.left, greaterThan(indicator.right));
      expect(tertiary.left, greaterThan(title.right));
      expect(trailing.left, greaterThanOrEqualTo(tertiary.right));
      expect(secondary.top, greaterThanOrEqualTo(title.bottom));
      expect(
        row.right - trailing.right,
        closeTo(FluentSpacing.s, 0.01),
        reason: 'the row is inset Spacing/Horizontal/S on its trailing edge',
      );
    });
  });
}
