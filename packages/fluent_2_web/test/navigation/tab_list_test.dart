import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// Pinned against `test/fixtures/tab.json` (Figma `Horizontal Tab`, set
/// `9116:18470`, 80 variants) and `test/fixtures/vertical_tab.json` (Figma
/// `Vertical Tab`, `9116:17973`, 80 variants), both on page `8934:19`.
///
/// The two sets are the same table twice — `Selected` x `Style` x `Size` x
/// `State` — with only the geometry and the indicator's edge moving between
/// them. All 160 variants are asserted: the four states the widget expresses as
/// `WidgetState`s inside the fixture loop, and `State=Focus` separately,
/// because this port draws the ring with `FluentFocusRing` rather than as a
/// variant of the tab.
///
/// Motion is `useTabAnimatedIndicator.styles.ts` verbatim: `transform` only,
/// `durationSlow` on `curveDecelerateMax`, `transform-origin` left/top, and no
/// transition at all under `prefers-reduced-motion`. `useTabStyles.styles.ts`
/// declares no transition, so nothing else about a tab animates.
void main() {
  final horizontalSpec = loadSpec('tab');
  final verticalSpec = loadSpec('vertical_tab');
  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  const tabKey = Key('tab-a');
  const otherKey = Key('tab-b');

  const styleNames = <FluentTabAppearance, String>{
    FluentTabAppearance.transparent: 'Transparent',
    FluentTabAppearance.subtle: 'Subtle',
    FluentTabAppearance.filledCircular: 'Filled circular',
    FluentTabAppearance.subtleCircular: 'Subtle circular',
  };
  const sizeNames = <FluentTabSize, String>{
    FluentTabSize.medium: 'Medium',
    FluentTabSize.small: 'Small',
  };

  /// The label colour is stated in the fixture as a token name rather than a
  /// hex, so it is checked against the token itself — a stricter assertion than
  /// a colour match, since two tokens can share a value in one theme.
  Color labelColour(String token) => switch (token) {
    'Neutral/Foreground/1/Rest' => light.colors.neutralForeground1,
    'Neutral/Foreground/1/Hover' => light.colors.neutralForeground1Hover,
    'Neutral/Foreground/1/Pressed' => light.colors.neutralForeground1Pressed,
    'Neutral/Foreground/2/Rest' => light.colors.neutralForeground2,
    'Neutral/Foreground/2/Hover' => light.colors.neutralForeground2Hover,
    'Neutral/Foreground/2/Pressed' => light.colors.neutralForeground2Pressed,
    'Brand/Foreground/2/Rest' => light.colors.brandForeground2,
    'Brand/Foreground/2/Hover' => light.colors.brandForeground2Hover,
    'Brand/Foreground/2/Pressed' => light.colors.brandForeground2Pressed,
    'Neutral/Foreground/On Brand/Rest' => light.colors.neutralForegroundOnBrand,
    'Neutral/Foreground/Disabled/Rest' =>
      light.colors.neutralForegroundDisabled,
    _ => throw StateError('untranslated label token: $token'),
  };

  SpecFixture specFor(FluentTabOrientation orientation) =>
      orientation == FluentTabOrientation.horizontal
      ? horizontalSpec
      : verticalSpec;

  SpecPart? partNamed(SpecVariant variant, String name) {
    for (final part in variant.parts) {
      if (part.name == name) return part;
    }
    return null;
  }

  /// The last `IconTheme` an icon slot saw, so the glyph colour and size can be
  /// asserted without reading pixels.
  IconThemeData? seenIconTheme;

  Widget iconProbe() => Builder(
    builder: (context) {
      seenIconTheme = IconTheme.of(context);
      return const Icon(FluentIcons.calendar_20_regular);
    },
  );

  Widget list({
    FluentTabOrientation orientation = FluentTabOrientation.horizontal,
    FluentTabSize size = FluentTabSize.medium,
    FluentTabAppearance appearance = FluentTabAppearance.transparent,
    String? selected = 'a',
    bool enabled = true,
    bool secondEnabled = true,
    bool withIcon = true,
    bool withLabel = true,
    FluentTabStyle? listStyle,
    FluentTabStyle? tabStyle,
    ValueChanged<String>? onSelect,
    String? semanticLabel,
  }) => FluentTabList<String>(
    orientation: orientation,
    size: size,
    appearance: appearance,
    selectedValue: selected,
    onSelect: onSelect ?? (_) {},
    style: listStyle,
    semanticLabel: semanticLabel,
    tabs: <FluentTab<String>>[
      FluentTab<String>(
        key: tabKey,
        value: 'a',
        enabled: enabled,
        style: tabStyle,
        icon: withIcon ? iconProbe() : null,
        semanticLabel: withLabel ? null : 'Calendar',
        child: withLabel ? const Text('Tab') : null,
      ),
      FluentTab<String>(
        key: otherKey,
        value: 'b',
        enabled: secondEnabled,
        child: const Text('Longer tab'),
      ),
      const FluentTab<String>(value: 'c', child: Text('Third')),
    ],
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FluentThemeData? theme,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Directionality(
        textDirection: direction,
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );

  Iterable<DecoratedBox> boxesOf(WidgetTester tester, Finder of) =>
      tester.widgetList<DecoratedBox>(
        find.descendant(of: of, matching: find.byType(DecoratedBox)),
      );

  /// The tab's own surface: the first `DecoratedBox` in pre-order, which sits
  /// above the indicator in the `Stack`.
  BoxDecoration surfaceOf(WidgetTester tester, {Finder? of}) =>
      boxesOf(tester, of ?? find.byKey(tabKey)).first.decoration
          as BoxDecoration;

  /// The selection indicator, or null when the tab paints none.
  BoxDecoration? indicatorOf(WidgetTester tester, {Finder? of}) {
    final boxes = boxesOf(tester, of ?? find.byKey(tabKey)).toList();
    return boxes.length < 2 ? null : boxes.last.decoration as BoxDecoration;
  }

  Finder indicatorFinder([Finder? of]) => find
      .descendant(
        of: of ?? find.byKey(tabKey),
        matching: find.byType(DecoratedBox),
      )
      .last;

  EdgeInsets paddingOf(WidgetTester tester, {Finder? of}) => tester
      .widgetList<Padding>(
        find.descendant(
          of: of ?? find.byKey(tabKey),
          matching: find.byType(Padding),
        ),
      )
      .first
      .padding
      .resolve(TextDirection.ltr);

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
    if (expected == null) {
      // Figma paints no fill at all on the flat disabled variants. Whatever
      // token stands in for that has to be invisible too.
      expect(actual.a, 0, reason: '$reason: Figma paints no fill here');
      return;
    }
    if (expected.a == 0) {
      expect(actual.a, 0, reason: '$reason (alpha only: transparent token)');
      return;
    }
    expect(actual.toARGB32(), expected.toARGB32(), reason: reason);
  }

  group('spec', () {
    for (final orientation in FluentTabOrientation.values) {
      testWidgets('${orientation.name}: every variant matches Figma', (
        tester,
      ) async {
        final spec = specFor(orientation);
        final horizontal = orientation == FluentTabOrientation.horizontal;

        for (final appearance in FluentTabAppearance.values) {
          for (final size in FluentTabSize.values) {
            for (final selected in <bool>[true, false]) {
              for (final state in <String>[
                'Rest',
                'Hover',
                'Pressed',
                'Disabled',
              ]) {
                final variant = spec.variant(<String, String>{
                  'Selected': selected ? 'Yes' : 'No',
                  'Style': styleNames[appearance]!,
                  'Size': sizeNames[size]!,
                  'State': state,
                });
                final where = variant.name;

                await pump(
                  tester,
                  list(
                    orientation: orientation,
                    size: size,
                    appearance: appearance,
                    selected: selected ? 'a' : 'b',
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
                  await mouse.moveTo(tester.getCenter(find.byKey(tabKey)));
                  await tester.pump();
                  if (state == 'Pressed') {
                    await mouse.down(tester.getCenter(find.byKey(tabKey)));
                    await tester.pump();
                  }
                }

                final surface = surfaceOf(tester);

                expect(
                  tester.getSize(find.byKey(tabKey)).height,
                  closeTo(variant.size.height, 0.01),
                  reason: '$where: height',
                );
                expect(
                  paddingOf(tester),
                  variant.padding,
                  reason: '$where: padding',
                );
                expect(
                  surface.borderRadius?.resolve(TextDirection.ltr),
                  variant.radius,
                  reason: '$where: radius',
                );
                expectFill(surface.color!, variant.fill, '$where: fill');

                expect(
                  surface.border?.top.width ?? 0,
                  variant.strokeWidth,
                  reason: '$where: border width',
                );
                if (variant.stroke != null && variant.strokeWidth! > 0) {
                  expect(
                    surface.border!.top.color.toARGB32(),
                    variant.stroke!.toARGB32(),
                    reason:
                        '$where: border colour (${variant.token('strokes')})',
                  );
                }

                final text = resolvedTextStyleOf(tester, of: find.text('Tab'));
                expect(
                  text.fontSize,
                  variant.text!.fontSize,
                  reason: '$where: font size',
                );
                expect(
                  text.height! * text.fontSize!,
                  variant.text!.lineHeight,
                  reason: '$where: line height',
                );
                expect(
                  text.fontWeight,
                  selected ? FontWeight.w600 : FontWeight.w400,
                  reason: '$where: ${variant.text!.fontStyle} weight',
                );
                expect(
                  text.color,
                  labelColour(variant.text!.tokens['fills']!.single),
                  reason: '$where: label colour',
                );

                final glyph = partNamed(variant, 'Shape');
                expect(glyph, isNotNull, reason: '$where: no Shape part');
                expect(
                  seenIconTheme!.color!.toARGB32(),
                  glyph!.fill!.toARGB32(),
                  reason: '$where: icon colour (${glyph.token('fills')})',
                );

                final selector = partNamed(variant, 'Selector');
                final indicator = indicatorOf(tester);
                expect(
                  indicator != null,
                  selector != null,
                  reason: '$where: indicator presence',
                );
                if (selector != null) {
                  expect(
                    indicator!.color!.toARGB32(),
                    selector.fill!.toARGB32(),
                    reason:
                        '$where: indicator colour (${selector.token('fills')})',
                  );
                  expect(
                    indicator.borderRadius?.resolve(TextDirection.ltr),
                    FluentRadius.allCircular,
                    reason: '$where: indicator radius',
                  );

                  // Figma states the bar's own rectangle, so its thickness is
                  // read straight off the cross-axis extent.
                  //
                  // The inset is the bound token rather than
                  // `(frame - bar) / 2`: on `Selected=No, Size=Small` the
                  // horizontal frame hugs to 63 while its bar is still the 48
                  // of the selected twin, which would read as 7.5. React
                  // (`useTabStyles.styles.ts`) states the inset directly and
                  // lets the bar's length follow, which is what this port does.
                  final thickness = horizontal
                      ? selector.size.height
                      : selector.size.width;
                  final inset = horizontal
                      ? (size == FluentTabSize.medium
                            ? FluentSpacing.m
                            : FluentSpacing.s)
                      : (size == FluentTabSize.medium
                            ? FluentSpacing.s
                            : FluentSpacing.xs);

                  if (selected) {
                    // Where Figma's own frame is self-consistent — every
                    // selected variant — it must agree with that token.
                    expect(
                      horizontal
                          ? (variant.size.width - selector.size.width) / 2
                          : (variant.size.height - selector.size.height) / 2,
                      inset,
                      reason: '$where: Figma frame vs bound inset token',
                    );
                  }

                  final tabRect = tester.getRect(find.byKey(tabKey));
                  final barRect = tester.getRect(indicatorFinder());
                  if (horizontal) {
                    expect(
                      barRect.height,
                      thickness,
                      reason: '$where: indicator thickness',
                    );
                    expect(
                      barRect.bottom,
                      tabRect.bottom,
                      reason: '$where: indicator sits on the bottom edge',
                    );
                    expect(
                      barRect.left - tabRect.left,
                      closeTo(inset, 0.01),
                      reason: '$where: indicator start inset',
                    );
                    expect(
                      tabRect.right - barRect.right,
                      closeTo(inset, 0.01),
                      reason: '$where: indicator end inset',
                    );
                  } else {
                    expect(
                      barRect.width,
                      thickness,
                      reason: '$where: indicator thickness',
                    );
                    expect(
                      barRect.left,
                      tabRect.left,
                      reason: '$where: indicator sits on the leading edge',
                    );
                    expect(
                      barRect.top - tabRect.top,
                      closeTo(inset, 0.01),
                      reason: '$where: indicator start inset',
                    );
                    expect(
                      tabRect.bottom - barRect.bottom,
                      closeTo(inset, 0.01),
                      reason: '$where: indicator end inset',
                    );
                  }
                }

                if (mouse != null) {
                  if (state == 'Pressed') await mouse.up();
                  await mouse.removePointer();
                  await tester.pump();
                }
              }
            }
          }
        }
      });
    }

    testWidgets('an icon-only tab is as wide as the TabList frame says', (
      tester,
    ) async {
      // Figma's `Layout=Icon only` TabList variants (sets 9116:17888 and
      // 9116:17815) are 40 wide at medium and 32 at small in both
      // orientations — the padding plus a 20 (16 on a small pill) icon slot.
      const expected = <(FluentTabAppearance, FluentTabSize), double>{
        (FluentTabAppearance.transparent, FluentTabSize.medium): 40,
        (FluentTabAppearance.transparent, FluentTabSize.small): 32,
        (FluentTabAppearance.filledCircular, FluentTabSize.medium): 40,
        (FluentTabAppearance.filledCircular, FluentTabSize.small): 32,
      };

      for (final entry in expected.entries) {
        await pump(
          tester,
          list(appearance: entry.key.$1, size: entry.key.$2, withLabel: false),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(tabKey)).width,
          entry.value,
          reason: '${entry.key}',
        );
        expect(
          seenIconTheme!.size,
          entry.key.$1 == FluentTabAppearance.filledCircular &&
                  entry.key.$2 == FluentTabSize.small
              ? FluentSize.size160
              : FluentSize.size200,
          reason: '${entry.key}: icon slot',
        );
      }
    });

    testWidgets('State=Focus draws the ring at the radius Figma states', (
      tester,
    ) async {
      // Figma models focus as a frame carrying a single `Focus/2` stroke — the
      // tab is one of the three components (with vertical_tab and list_item)
      // where Figma draws one ring rather than two, and so agrees with React.
      //
      // DIVERGENCE, followed rather than reported: Figma drops the flat tab's
      // ring to `Corner radius/Small` (2) while its surface stays at Medium.
      // React hard-codes `borderRadiusMedium` for every focus indicator, and a
      // live probe of a focused flat tab on storybooks.fluentui.dev reads
      // `border-radius: 4px`. React wins here; the pill stays Circular in both.
      for (final appearance in FluentTabAppearance.values) {
        final pill =
            appearance == FluentTabAppearance.filledCircular ||
            appearance == FluentTabAppearance.subtleCircular;
        final variant = horizontalSpec.variant(<String, String>{
          'Selected': 'Yes',
          'Style': styleNames[appearance]!,
          'Size': 'Medium',
          'State': 'Focus',
        });

        await pump(tester, list(appearance: appearance));
        await tester.pumpAndSettle();

        expect(
          ringOf(tester, tabKey).borderRadius,
          pill ? variant.radius : FluentRadius.allMedium,
          reason: '${variant.name}: focus ring radius',
        );
        expect(
          ringOf(tester, tabKey).innerWidth,
          FluentStroke.none,
          reason: '${variant.name}: Figma and React both draw a single ring',
        );
        expect(
          ringOf(tester, tabKey).visible,
          isFalse,
          reason: 'nothing has keyboard focus yet',
        );
      }
    });

    testWidgets('the ring is raised by keyboard focus, not by a tap', (
      tester,
    ) async {
      final previous = FocusManager.instance.highlightStrategy;
      addTearDown(() => FocusManager.instance.highlightStrategy = previous);

      await pump(tester, list());
      await tester.pumpAndSettle();

      // No highlightStrategy poking: Flutter's highlight mode maps BOTH mouse
      // and key to `traditional`, so it can neither produce nor prevent this.
      // FluentInputModality is the real signal, and a real tap/keypress is the
      // only honest way to drive it.
      await tester.tap(find.byKey(tabKey));
      await tester.pumpAndSettle();
      expect(
        ringOf(tester, tabKey).visible,
        isFalse,
        reason: 'focus arriving by pointer must not raise a ring',
      );

      // Escape flips the modality without moving focus, so this asserts the
      // ring re-evaluates on the SAME focused node — keyborg's live behaviour.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        ringOf(tester, tabKey).visible,
        isTrue,
        reason: 'the same node, now in keyboard mode, shows the ring',
      );
    });

    testWidgets('the list gap is the one the TabList set states', (
      tester,
    ) async {
      // Figma TabList sets: itemSpacing 0 on the flat appearances,
      // `Spacing/Horizontal/S` (8) on a medium pill and `SNudge` (6) on a small
      // one. React's useTabListStyles.styles.ts agrees exactly.
      const expected = <(FluentTabAppearance, FluentTabSize), double>{
        (FluentTabAppearance.transparent, FluentTabSize.medium): 0,
        (FluentTabAppearance.subtle, FluentTabSize.small): 0,
        (FluentTabAppearance.filledCircular, FluentTabSize.medium): 8,
        (FluentTabAppearance.subtleCircular, FluentTabSize.small): 6,
      };

      for (final entry in expected.entries) {
        await pump(tester, list(appearance: entry.key.$1, size: entry.key.$2));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byKey(otherKey)).left -
              tester.getRect(find.byKey(tabKey)).right,
          entry.value,
          reason: '${entry.key}',
        );
      }
    });

    testWidgets('a vertical list stretches its tabs to a common width', (
      tester,
    ) async {
      // `useTabListStyles.styles.ts` — `vertical: { alignItems: 'stretch' }`.
      // A live probe of components-tablist--vertical measures all four tabs at
      // 97.94 despite their different labels. Neither Figma set states this:
      // the `Vertical Tab` variants are all one fixed width because they all
      // carry the same label, so there is no hug-vs-fill signal to weigh
      // against React.
      await pump(tester, list(orientation: FluentTabOrientation.vertical));
      await tester.pumpAndSettle();

      final short = tester.getRect(find.byKey(tabKey));
      final long = tester.getRect(find.byKey(otherKey));
      expect(short.width, long.width, reason: 'one width for the whole list');
      expect(
        short.width,
        greaterThan(0),
        reason: 'the widest label is what sets it',
      );
      // Stretched, the short tab's content must still start at the leading
      // edge rather than centre itself in the extra room.
      expect(
        tester.getRect(find.byType(Icon)).left - short.left,
        closeTo(10, 0.01),
        reason: "the vertical rule is justifyContent: 'start' plus 10 padding",
      );
    });
  });

  group('motion', () {
    /// Two tabs of deliberately different widths, so the flip has both a
    /// translation and a scale to carry.
    ///
    /// The selection lives in [selection] rather than in a local, so re-pumping
    /// the same app with a different `reducedMotion` does not silently reset it.
    Widget flipApp(List<String> selection, {bool reducedMotion = false}) =>
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          builder: reducedMotion
              ? (context, child) => MediaQuery(
                  data: const MediaQueryData(disableAnimations: true),
                  child: child!,
                )
              : null,
          home: Align(
            alignment: Alignment.topLeft,
            child: StatefulBuilder(
              builder: (context, setState) => FluentTabList<String>(
                selectedValue: selection.first,
                onSelect: (value) => setState(() => selection[0] = value),
                tabs: const <FluentTab<String>>[
                  FluentTab<String>(key: tabKey, value: 'a', child: Text('A')),
                  FluentTab<String>(
                    key: otherKey,
                    value: 'b',
                    child: Text('Much longer B'),
                  ),
                ],
              ),
            ),
          ),
        );

    Finder flipFinder() => find.descendant(
      of: find.byKey(otherKey),
      matching: find.byType(Transform),
    );

    Matrix4 flipMatrix(WidgetTester tester) =>
        tester.widget<Transform>(flipFinder()).transform;

    testWidgets('the spec is durationSlow on curveDecelerateMax', (
      tester,
    ) async {
      // useTabAnimatedIndicator.styles.ts: transitionProperty 'transform',
      // transitionDuration tokens.durationSlow, transitionTimingFunction
      // tokens.curveDecelerateMax.
      expect(FluentMotionSpec.tabIndicator.duration, FluentDuration.slow);
      expect(FluentMotionSpec.tabIndicator.curve, FluentCurve.decelerateMax);
      expect(FluentDuration.slow, const Duration(milliseconds: 300));
    });

    testWidgets('the indicator flips from the outgoing tab and lands', (
      tester,
    ) async {
      await tester.pumpWidget(flipApp(<String>['a']));
      await tester.pumpAndSettle();

      // Both rects are read BEFORE the tap, because that is the layout the
      // flip is computed off: it is measured synchronously in didUpdateWidget
      // so that no frame paints the bar at its destination. A selected tab
      // draws its label in the Strong weight, so the row reflows by a fraction
      // of a pixel as the selection moves — after the tap these numbers are no
      // longer the ones the flip saw.
      final from = tester.getRect(find.byKey(tabKey));
      final to = tester.getRect(find.byKey(otherKey));
      expect(
        find.descendant(
          of: find.byKey(tabKey),
          matching: find.byType(Transform),
        ),
        findsNothing,
        reason: 'a settled indicator carries no transform',
      );

      await tester.tap(find.byKey(otherKey));
      await tester.pump(); // the selection lands, and the flip with it

      final translation = from.left - to.left;
      expect(translation, isNot(0));

      expect(
        flipMatrix(tester).storage[12],
        closeTo(translation, 0.01),
        reason: 'the bar starts on the outgoing tab',
      );

      await tester.pump(const Duration(milliseconds: 150));
      final done = FluentCurve.decelerateMax.transform(0.5);
      expect(
        flipMatrix(tester).storage[12].abs(),
        closeTo(translation.abs() * (1 - done), translation.abs() * 0.15),
        reason:
            'decelerateMax is ${(done * 100).round()}% through at the halfway '
            'point, where a linear curve would be at 50%',
      );

      await tester.pumpAndSettle();
      expect(
        flipFinder(),
        findsNothing,
        reason: 'the flip is released once it lands',
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('the indicator does not flash at the new tab before flipping', (
      tester,
    ) async {
      await tester.pumpWidget(flipApp(<String>['a']));
      await tester.pumpAndSettle();

      final from = tester.getRect(find.byKey(tabKey));
      final to = tester.getRect(find.byKey(otherKey));
      await tester.tap(find.byKey(otherKey));
      // Exactly one frame. No frame may show the bar sitting under 'b' at its
      // final position and size: the offset must already be on.
      await tester.pump();

      expect(
        flipMatrix(tester).storage[12],
        closeTo(from.left - to.left, 0.01),
        reason: 'the outgoing offset must be applied on the first frame',
      );

      await tester.pumpAndSettle();
    });

    testWidgets('the flip scales the bar as well as moving it', (tester) async {
      await tester.pumpWidget(flipApp(<String>['a']));
      await tester.pumpAndSettle();

      // Pre-tap, for the reason spelled out above: the flip is measured
      // against the layout as it stood when the selection changed.
      final from = tester.getRect(find.byKey(tabKey));
      final to = tester.getRect(find.byKey(otherKey));
      await tester.tap(find.byKey(otherKey));
      await tester.pump();

      const inset = FluentSpacing.m;
      final matrix = flipMatrix(tester);
      expect(
        matrix.storage[0],
        closeTo((from.width - 2 * inset) / (to.width - 2 * inset), 0.01),
        reason: 'the x scale is the ratio of the two bars, not of the two tabs',
      );
      expect(
        matrix.storage[5],
        1,
        reason: 'a horizontal flip must not touch the cross axis',
      );
      expect(
        tester.widget<Transform>(flipFinder()).alignment,
        Alignment.centerLeft,
        reason: "upstream's transform-origin is left when horizontal",
      );
    });

    testWidgets('a vertical flip runs on Y from the top', (tester) async {
      var selected = 'a';
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Align(
            alignment: Alignment.topLeft,
            child: StatefulBuilder(
              builder: (context, setState) => FluentTabList<String>(
                orientation: FluentTabOrientation.vertical,
                selectedValue: selected,
                onSelect: (value) => setState(() => selected = value),
                tabs: const <FluentTab<String>>[
                  FluentTab<String>(key: tabKey, value: 'a', child: Text('A')),
                  FluentTab<String>(
                    key: otherKey,
                    value: 'b',
                    child: Text('B'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final from = tester.getRect(find.byKey(tabKey));
      await tester.tap(find.byKey(otherKey));
      await tester.pump();
      await tester.pump();
      final to = tester.getRect(find.byKey(otherKey));

      final matrix = flipMatrix(tester);
      expect(matrix.storage[13], closeTo(from.top - to.top, 0.01));
      expect(matrix.storage[12], 0, reason: 'nothing moves on X');
      expect(
        tester.widget<Transform>(flipFinder()).alignment,
        Alignment.topCenter,
        reason: "upstream's transform-origin is top when vertical",
      );
    });

    testWidgets('reduced motion puts the indicator straight on the new tab', (
      tester,
    ) async {
      await tester.pumpWidget(flipApp(<String>['a'], reducedMotion: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(otherKey));
      await tester.pump();
      await tester.pump();

      expect(
        flipFinder(),
        findsNothing,
        reason: 'upstream drops the transition entirely, so there is no tween',
      );
      expect(
        tester.hasRunningAnimations,
        isFalse,
        reason: 'nothing may be left ticking',
      );

      final tabRect = tester.getRect(find.byKey(otherKey));
      final barRect = tester.getRect(indicatorFinder(find.byKey(otherKey)));
      expect(barRect.left - tabRect.left, closeTo(FluentSpacing.m, 0.01));
      expect(barRect.bottom, tabRect.bottom);
    });

    testWidgets('turning reduced motion on mid-flight lands the bar', (
      tester,
    ) async {
      final selection = <String>['a'];
      await tester.pumpWidget(flipApp(selection));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(otherKey));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(flipFinder(), findsOneWidget);

      // Same tree, same State — only the MediaQuery changes, which is what a
      // user flipping the OS setting mid-animation looks like.
      await tester.pumpWidget(flipApp(selection, reducedMotion: true));
      await tester.pump();
      await tester.pump();
      expect(
        flipFinder(),
        findsNothing,
        reason: 'whatever was in flight lands on this frame',
      );
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('keyboard', () {
    Future<void> focusFirst(WidgetTester tester) async {
      await tester.tap(find.byKey(tabKey));
      await tester.pumpAndSettle();
    }

    /// A list whose selection actually moves, for the walks that take more than
    /// one step.
    Future<void> pumpLive(WidgetTester tester, List<String> picked) {
      final selection = <String>['a'];
      return tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Align(
            alignment: Alignment.topLeft,
            child: StatefulBuilder(
              builder: (context, setState) => list(
                selected: selection.first,
                onSelect: (value) {
                  picked.add(value);
                  setState(() => selection[0] = value);
                },
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('arrows move the selection along the list axis', (
      tester,
    ) async {
      final picked = <String>[];
      await pumpLive(tester, picked);
      await focusFirst(tester);
      picked.clear();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(picked, <String>['b']);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(picked, <String>['b', 'a']);

      // The cross-axis arrows belong to the page, not to a horizontal list.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(picked, <String>['b', 'a']);
    });

    testWidgets('a vertical list answers the vertical arrows', (tester) async {
      final picked = <String>[];
      await pump(
        tester,
        list(orientation: FluentTabOrientation.vertical, onSelect: picked.add),
      );
      await focusFirst(tester);
      picked.clear();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(picked, <String>['b']);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(picked, <String>['b'], reason: 'horizontal arrows are not ours');
    });

    testWidgets('Home and End jump to the ends', (tester) async {
      final picked = <String>[];
      await pump(tester, list(selected: 'b', onSelect: picked.add));
      await tester.tap(find.byKey(otherKey));
      await tester.pumpAndSettle();
      picked.clear();

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(picked, <String>['c']);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(picked, <String>['c', 'a']);
    });

    testWidgets('the ends wrap', (tester) async {
      // `useTabList` builds its arrow handling with
      // `useArrowNavigationGroup({ circular: true })`, and a live probe of
      // components-tablist--appearance walks off the last tab onto the first.
      // Neither Figma set states keyboard behaviour, so there is nothing to
      // weigh React against here.
      final picked = <String>[];
      await pump(tester, list(onSelect: picked.add));
      await focusFirst(tester);
      picked.clear();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(picked, <String>[
        'c',
      ], reason: 'left off the first tab lands last');

      await pump(tester, list(selected: 'c', onSelect: picked.add));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(picked, <String>[
        'c',
        'a',
      ], reason: 'right off the last tab lands first');
    });

    testWidgets('wrapping stops when nothing else is enabled', (tester) async {
      final picked = <String>[];
      await pump(
        tester,
        FluentTabList<String>(
          selectedValue: 'a',
          onSelect: picked.add,
          tabs: const <FluentTab<String>>[
            FluentTab<String>(key: tabKey, value: 'a', child: Text('Tab')),
            FluentTab<String>(value: 'b', enabled: false, child: Text('B')),
          ],
        ),
      );
      await focusFirst(tester);
      picked.clear();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(picked, isEmpty, reason: 'one lap, no self-selection');
    });

    testWidgets('a disabled tab is stepped over', (tester) async {
      final picked = <String>[];
      await pump(tester, list(secondEnabled: false, onSelect: picked.add));
      await focusFirst(tester);
      picked.clear();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(picked, <String>['c'], reason: 'b is disabled');
    });

    testWidgets('right-to-left mirrors the horizontal arrows', (tester) async {
      final picked = <String>[];
      await pump(
        tester,
        list(onSelect: picked.add),
        direction: TextDirection.rtl,
      );
      await focusFirst(tester);
      picked.clear();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(picked, <String>['b'], reason: 'left runs forward in RTL');
    });

    testWidgets('focus follows the selection, so the ring lands on it', (
      tester,
    ) async {
      final previous = FocusManager.instance.highlightStrategy;
      addTearDown(() => FocusManager.instance.highlightStrategy = previous);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;

      var selected = 'a';
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Align(
            alignment: Alignment.topLeft,
            child: StatefulBuilder(
              builder: (context, setState) => FluentTabList<String>(
                selectedValue: selected,
                onSelect: (value) => setState(() => selected = value),
                tabs: const <FluentTab<String>>[
                  FluentTab<String>(key: tabKey, value: 'a', child: Text('A')),
                  FluentTab<String>(
                    key: otherKey,
                    value: 'b',
                    child: Text('B'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(tabKey));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(ringOf(tester, otherKey).visible, isTrue);
      expect(ringOf(tester, tabKey).visible, isFalse);
    });
  });

  group('behaviour', () {
    testWidgets('a tap selects, and a disabled tab does nothing at all', (
      tester,
    ) async {
      final picked = <String>[];
      await pump(tester, list(selected: 'b', onSelect: picked.add));
      await tester.tap(find.byKey(tabKey));
      await tester.pump();
      expect(picked, <String>['a']);

      await pump(
        tester,
        list(selected: 'b', enabled: false, onSelect: picked.add),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(tabKey), warnIfMissed: false);
      await tester.pump();
      expect(picked, <String>['a'], reason: 'a disabled tab does not fire');

      // Disabled is a state, not a look: it must also refuse hover.
      final resting = surfaceOf(tester).color;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(tabKey)));
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, resting);
      expect(
        indicatorOf(tester),
        isNull,
        reason: 'no hover bar while disabled',
      );
    });

    testWidgets('a null onSelect disables the whole list', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: const Align(
            alignment: Alignment.topLeft,
            child: FluentTabList<String>(
              selectedValue: 'a',
              tabs: <FluentTab<String>>[
                FluentTab<String>(key: tabKey, value: 'a', child: Text('A')),
                FluentTab<String>(key: otherKey, value: 'b', child: Text('B')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byKey(tabKey)),
        isSemantics(
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('selection reports WidgetState.selected to a custom style', (
      tester,
    ) async {
      const marker = Color(0xFF00FF00);
      await pump(
        tester,
        list(
          tabStyle: FluentTabStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) => states.contains(WidgetState.selected)
                  ? marker
                  : const Color(0xFF0000FF),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, marker);
    });

    testWidgets('style resolution runs defaults, theme, list, then tab', (
      tester,
    ) async {
      await pump(
        tester,
        FluentTabTheme(
          style: FluentTabStyle.from(backgroundColor: const Color(0xFF111111)),
          child: list(
            listStyle: FluentTabStyle.from(
              backgroundColor: const Color(0xFF222222),
            ),
            tabStyle: FluentTabStyle.from(
              backgroundColor: const Color(0xFF333333),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        surfaceOf(tester).color,
        const Color(0xFF333333),
        reason: "the tab's own style wins",
      );

      await pump(
        tester,
        FluentTabTheme(
          style: FluentTabStyle.from(backgroundColor: const Color(0xFF111111)),
          child: list(
            listStyle: FluentTabStyle.from(
              backgroundColor: const Color(0xFF222222),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        surfaceOf(tester).color,
        const Color(0xFF222222),
        reason: 'the list beats the subtree theme',
      );
    });

    testWidgets('a FluentThemeOverride around the list reaches every tab', (
      tester,
    ) async {
      // The overlay-parity check for a component that has no overlay: the theme
      // a tab resolves against must be the one nearest the list, not the app's.
      const override = Color(0xFF123456);
      await pump(
        tester,
        FluentThemeOverride(
          colors: const <FluentColorToken, Color>{
            FluentColorToken.compoundBrandStroke: override,
          },
          child: list(),
        ),
      );
      await tester.pumpAndSettle();
      expect(indicatorOf(tester)!.color, override);
    });
  });

  group('semantics', () {
    testWidgets('the list is a tab bar of tabs, each carrying its state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, list(secondEnabled: false, semanticLabel: 'Sections'));
      await tester.pumpAndSettle();

      final selected = tester.getSemantics(find.byKey(tabKey));
      expect(selected.role, SemanticsRole.tab);
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
      expect(disabled.role, SemanticsRole.tab);
      expect(
        disabled,
        isSemantics(
          hasSelectedState: true,
          isSelected: false,
          hasEnabledState: true,
          isEnabled: false,
          // A disabled tab must not announce as activatable.
          hasTapAction: false,
        ),
      );

      // Reached through the tab rather than through the list's own finder:
      // `getSemantics` walks *up* from an element, and the tab bar's node is a
      // descendant of FluentTabList, not an ancestor.
      final bar = selected.parent!;
      expect(bar.role, SemanticsRole.tabBar);
      expect(bar.label, 'Sections');
      handle.dispose();
    });

    testWidgets('an icon-only tab announces its semantic label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, list(withLabel: false));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.byKey(tabKey)).label, 'Calendar');
      handle.dispose();
    });
  });

  group('high contrast', () {
    testWidgets('nothing that carries meaning goes invisible', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );

      // A flat selected tab: the indicator is the only mark it makes.
      await pump(tester, list(), theme: theme);
      await tester.pumpAndSettle();
      expect(indicatorOf(tester), isNotNull);
      expect(indicatorOf(tester)!.color!.a, 1.0);

      // The selected subtle pill: its outline is what separates it from the
      // page, and it must be opaque.
      await pump(
        tester,
        list(appearance: FluentTabAppearance.subtleCircular),
        theme: theme,
      );
      await tester.pumpAndSettle();
      final border = surfaceOf(tester).border;
      expect(border, isNotNull);
      expect(border!.top.color.a, 1.0);
      expect(border.top.width, FluentStroke.thin);

      // An unselected flat tab at rest paints no border and no bar, so nothing
      // can turn opaque behind the label and bury it.
      await pump(tester, list(selected: 'b'), theme: theme);
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).border, isNull);
      expect(indicatorOf(tester), isNull);
    });
  });
}
