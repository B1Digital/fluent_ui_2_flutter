import 'dart:math' as math;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// Pinned against `test/fixtures/accordion.json` — Figma component set
/// `9074:913`, 24 variants over `Size`, `State`, `Expanded` and `Chevron`.
///
/// Four values in here disagree with upstream's
/// `useAccordionHeaderStyles.styles.ts` / `useAccordionPanelStyles.styles.ts`.
/// Figma wins; `doc/token-divergences.md` records both readings. Anyone
/// "fixing" one of these back to the React value should read that first.
void main() {
  const item = Key('item');
  const panel = Key('panel');

  final spec = loadSpec('accordion');

  /// Figma spells the size axis out in prose; the enum does not.
  const figmaSize = <FluentAccordionSize, String>{
    FluentAccordionSize.small: 'Small',
    FluentAccordionSize.medium: 'Medium',
    FluentAccordionSize.large: 'Large',
    FluentAccordionSize.extraLarge: 'Extra large',
  };

  /// One collapsed header variant.
  SpecVariant header(
    FluentAccordionSize size, {
    String state = 'Rest',
    String chevron = 'Before',
  }) => spec.variant(<String, String>{
    'Size': figmaSize[size]!,
    'State': state,
    'Expanded': 'False',
    'Chevron': chevron,
  });

  /// A single-item accordion, given a bounded width — a Fluent header is a
  /// full-width row and has nothing to size itself against otherwise.
  Widget one({
    bool expanded = false,
    bool enabled = true,
    FluentAccordionSize size = FluentAccordionSize.medium,
    FluentAccordionExpandIconPosition position =
        FluentAccordionExpandIconPosition.start,
    Widget? icon,
    FluentAccordionItemStyle? style,
    double panelHeight = 100,
    FocusNode? focusNode,
  }) => SizedBox(
    width: 400,
    child: FluentAccordion(
      // `defaultOpenItems` seeds state exactly once, so a test that re-pumps
      // with a different value needs a new element, not a new widget.
      key: ValueKey<bool>(expanded),
      defaultOpenItems: expanded ? const <Object>{'a'} : const <Object>{},
      collapsible: true,
      children: <Widget>[
        FluentAccordionItem(
          key: item,
          value: 'a',
          size: size,
          expandIconPosition: position,
          enabled: enabled,
          icon: icon,
          style: style,
          focusNode: focusNode,
          header: const Text('Header'),
          child: SizedBox(key: panel, height: panelHeight),
        ),
      ],
    ),
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
        child: Center(child: child),
      ),
    ),
  );

  /// The header's own decorated surface, skipping the focus ring's CustomPaint.
  BoxDecoration headerDecoration(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(item),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.borderRadius != null);

  /// The chevron's rotation, in turns, read back off the live matrix.
  double chevronTurns(WidgetTester tester) {
    final transform = tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byKey(item),
            matching: find.byType(Transform),
          ),
        )
        .first
        .transform;
    return math.atan2(transform.storage[1], transform.storage[0]) /
        (2 * math.pi);
  }

  double itemHeight(WidgetTester tester) =>
      tester.getSize(find.byKey(item)).height;

  EdgeInsets headerPadding(WidgetTester tester, {TextDirection? direction}) =>
      tester
          .widgetList<Padding>(
            find.descendant(
              of: find.byKey(item),
              matching: find.byType(Padding),
            ),
          )
          .first
          .padding
          .resolve(direction ?? TextDirection.ltr);

  /// The label's style as it reaches the rasteriser. Scoped to the label
  /// itself: the chevron is an icon glyph and so is a [RichText] too.
  TextStyle headerTextStyle(WidgetTester tester) => tester
      .widget<RichText>(
        find.descendant(
          of: find.text('Header'),
          matching: find.byType(RichText),
        ),
      )
      .text
      .style!;

  /// The header's own semantics node, not the item's — the item is a plain
  /// [Column] and would resolve to whatever ancestor node contains it.
  SemanticsNode headerSemantics(WidgetTester tester) => tester.getSemantics(
    find
        .descendant(of: find.byKey(item), matching: find.byType(Semantics))
        .first,
  );

  Future<TestGesture> hover(WidgetTester tester, Finder target) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(target));
    return mouse;
  }

  group('variant axes', () {
    testWidgets('every Size matches its Figma header height and label', (
      tester,
    ) async {
      // Figma binds a whole type style per size, weight included. React
      // instead spreads typographyStyles.body1 and overrides only the size (and
      // the line height from large up), keeping the REGULAR weight throughout
      // and leaving small at 12/20. Figma says 12/16 and semibold from large.
      for (final entry in figmaSize.entries) {
        final variant = header(entry.key);
        final text = variant.text!;
        await pump(tester, one(size: entry.key));
        await tester.pumpAndSettle();

        expect(
          itemHeight(tester),
          variant.size.height,
          reason: '${variant.name}: height',
        );

        final style = headerTextStyle(tester);
        expect(
          style.fontSize,
          text.fontSize,
          reason: '${variant.name}: fontSize (${text.tokens['fontSize']})',
        );
        // The fixture's `Typography/Line height/500` still resolves to 28,
        // but the published Web ramp — https://fluent2.microsoft.design/typography
        // — specifies 20/26 for `subtitle1`, and that is what ships. Only that
        // one stop diverges, so the assertion stays exact everywhere else.
        expect(
          style.height! * style.fontSize!,
          text.fontSize == 20 ? 26 : text.lineHeight,
          reason: '${variant.name}: lineHeight (${text.tokens['lineHeight']})',
        );
        // The bound weight token is authoritative; `fontStyle` is only its
        // human name.
        final weightToken = text.tokens['fontStyle']!.single;
        expect(
          style.fontWeight,
          weightToken == 'Typography/Weight/Semibold'
              ? FluentFontWeight.semibold
              : FluentFontWeight.regular,
          reason: '${variant.name}: weight ($weightToken)',
        );
      }
    });

    testWidgets('every Size and Chevron pins the same 4px radius', (
      tester,
    ) async {
      for (final entry in figmaSize.entries) {
        final variant = header(entry.key);
        await pump(tester, one(size: entry.key));
        await tester.pumpAndSettle();
        expect(
          headerDecoration(tester).borderRadius,
          variant.radius,
          reason: '${variant.name}: Corner radius/Medium',
        );
      }
    });

    testWidgets('header padding is MNudge on BOTH sides, on every variant', (
      tester,
    ) async {
      // Figma binds Spacing/Horizontal/MNudge to paddingLeft AND paddingRight
      // on all 24 headers. React writes `0 spacingHorizontalM 0
      // spacingHorizontalMNudge` and then two chevron-at-end overrides
      // (buttonExpandIconEnd, buttonExpandIconEndNoIcon); neither exists in the
      // design file, so the chevron position moves nothing here.
      // The header row is the `Content` part; the variant frame itself is a
      // zero-padding wrapper around Content plus the panel.
      for (final chevron in const <String>['Before', 'After']) {
        for (final size in figmaSize.keys) {
          final variant = header(size, chevron: chevron);
          final content = variant.part('Content');
          expect(
            content.padding,
            const EdgeInsets.symmetric(horizontal: FluentSpacing.mNudge),
            reason: '${variant.name}: ${content.tokens['paddingLeft']}',
          );
          expect(
            content.size.height,
            variant.size.height,
            reason: '${variant.name}: the header row IS the 44px box',
          );
        }
      }

      for (final position in FluentAccordionExpandIconPosition.values) {
        for (final icon in <Widget?>[null, const SizedBox(width: 20)]) {
          await pump(tester, one(position: position, icon: icon));
          expect(
            headerPadding(tester),
            const EdgeInsets.symmetric(horizontal: FluentSpacing.mNudge),
            reason: '${position.name}, icon=${icon != null}',
          );
        }
      }
    });

    testWidgets('every Expanded value points the chevron where Figma does', (
      tester,
    ) async {
      // useAccordionHeader: start → 0 closed, 90 open; end → 90 closed,
      // -90 open. Values are turns here, so a quarter is 0.25.
      const cases = <(FluentAccordionExpandIconPosition, bool, double)>[
        (FluentAccordionExpandIconPosition.start, false, 0),
        (FluentAccordionExpandIconPosition.start, true, 0.25),
        (FluentAccordionExpandIconPosition.end, false, 0.25),
        (FluentAccordionExpandIconPosition.end, true, -0.25),
      ];

      for (final (position, expanded, turns) in cases) {
        await pump(tester, one(position: position, expanded: expanded));
        await tester.pumpAndSettle();
        expect(
          chevronTurns(tester),
          closeTo(turns, 1e-6),
          reason: '${position.name}, expanded=$expanded',
        );
      }
    });

    testWidgets('RTL mirrors the chevron rather than double-flipping it', (
      tester,
    ) async {
      // The glyph carries matchTextDirection, so it is already mirrored; the
      // turn is negated instead of adding upstream's extra 180 degrees.
      await pump(tester, one(expanded: true), direction: TextDirection.rtl);
      await tester.pumpAndSettle();
      expect(chevronTurns(tester), closeTo(-0.25, 1e-6));
    });

    testWidgets('every State resolves an explicitly named token', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final state = resolveFluentAccordionItemState();
      final style = resolveFluentAccordionItemStyle(state, theme);

      // Figma's State axis offers only Rest and Disabled — there is no Hover
      // or Pressed variant, and the header frame carries no fill in either
      // state. So Rest, Hover and Pressed are all colorTransparentBackground:
      // the header is flat by design, not by omission.
      expect(spec.properties['State'], <String>['Rest', 'Disabled']);
      for (final size in figmaSize.keys) {
        expect(
          header(size).fill,
          isNull,
          reason: 'Figma paints no header fill',
        );
      }
      for (final states in const <Set<WidgetState>>[
        <WidgetState>{},
        <WidgetState>{WidgetState.hovered},
        <WidgetState>{WidgetState.pressed},
      ]) {
        expect(style.backgroundColor!.resolve(states)!.a, 0, reason: '$states');
      }
      // The label token per state, straight off the fixture.
      expect(
        header(FluentAccordionSize.medium).text!.tokens['fills']!.single,
        'Neutral/Foreground/1/Rest',
      );
      expect(
        header(
          FluentAccordionSize.medium,
          state: 'Disabled',
        ).text!.tokens['fills']!.single,
        'Neutral/Foreground/Disabled/Rest',
      );
      expect(
        style.foregroundColor!.resolve(const <WidgetState>{}),
        theme.colors.neutralForeground1,
      );
      expect(
        style.foregroundColor!.resolve(const <WidgetState>{
          WidgetState.disabled,
        }),
        theme.colors.neutralForegroundDisabled,
      );
    });

    testWidgets('the panel is inset M each side AND M below', (tester) async {
      // Figma's `Panel` part binds Spacing/Horizontal/M to paddingLeft and
      // paddingRight and Spacing/Vertical/M to paddingBottom, with paddingTop
      // 0. React's useAccordionPanelStyles writes
      // `margin: 0 spacingHorizontalM` — no bottom at all — which is the value
      // this used to carry.
      final expanded = spec.variant(const <String, String>{
        'Size': 'Medium',
        'State': 'Rest',
        'Expanded': 'True',
        'Chevron': 'Before',
      });
      final inset = expanded.part('Panel').padding!;
      expect(
        inset,
        const EdgeInsets.only(
          left: FluentSpacing.m,
          right: FluentSpacing.m,
          bottom: FluentSpacing.m,
        ),
      );

      await pump(tester, one(expanded: true));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(panel)).width, 400 - inset.horizontal);
      // The gap between the panel content and the bottom of the item.
      expect(
        tester.getBottomLeft(find.byKey(item)).dy -
            tester.getBottomLeft(find.byKey(panel)).dy,
        inset.bottom,
      );
    });
  });

  group('motion', () {
    testWidgets('the panel collapses over 200ms on easyEaseMax', (
      tester,
    ) async {
      // Upstream wraps the panel in `Collapse`, whose defaults are
      // durationNormal (200ms) and curveEasyEaseMax — the pair
      // FluentMotionSpec.collapse holds.
      expect(FluentMotionSpec.collapse.duration, FluentDuration.normal);
      expect(FluentMotionSpec.collapse.curve, FluentCurve.easyEaseMax);

      await pump(tester, one());
      await tester.pumpAndSettle();
      final collapsed = itemHeight(tester);
      expect(collapsed, 44, reason: 'unmountOnExit: nothing below the header');

      await tester.tap(find.byKey(item));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final middle = itemHeight(tester);
      expect(middle, greaterThan(collapsed), reason: 'must be mid-tween');
      expect(middle, lessThan(156), reason: 'must not be instant');

      await tester.pumpAndSettle();
      expect(itemHeight(tester), 156, reason: '44 header + 100 panel + 12 M');
    });

    testWidgets('the chevron rotates over 200ms, decelerating', (tester) async {
      // useAccordionHeader.tsx: `transition: transform
      // ${motionTokens.durationNormal}ms ease-out` — a raw CSS ease-out,
      // cubic-bezier(0, 0, 0.58, 1), which starts at speed and decelerates.
      // decelerateMin is the ramp's nearest match; easyEase is symmetric and
      // eases IN, which is the wrong category, not a rounding difference.
      expect(FluentMotionSpec.accordionChevron.duration, FluentDuration.normal);
      expect(
        FluentMotionSpec.accordionChevron.curve,
        FluentCurve.decelerateMin,
      );

      await pump(tester, one());
      await tester.pumpAndSettle();
      expect(chevronTurns(tester), closeTo(0, 1e-6));

      await tester.tap(find.byKey(item));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final middle = chevronTurns(tester);
      expect(middle, greaterThan(0.0));
      expect(middle, lessThan(0.25), reason: 'must be mid-tween, not instant');

      await tester.pumpAndSettle();
      expect(chevronTurns(tester), closeTo(0.25, 1e-6));
    });

    testWidgets('reduced motion lands both on the first frame', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
          home: Center(child: one()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(item));
      await tester.pump();
      await tester.pump();
      expect(itemHeight(tester), 156);
      expect(chevronTurns(tester), closeTo(0.25, 1e-6));
    });

    testWidgets('the header surface changes INSTANTLY, with no transition', (
      tester,
    ) async {
      // useAccordionHeaderStyles declares no transition on the header root at
      // all — unlike Button, which transitions background/border/color. High
      // contrast is the only theme where the change is observable, because it
      // is the only one where the transparent hover token is not transparent.
      await pump(
        tester,
        one(),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      await tester.pumpAndSettle();
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      expect(
        headerDecoration(tester).color,
        theme.colors.transparentBackground,
      );

      await hover(tester, find.byKey(item));
      await tester.pump();
      expect(
        headerDecoration(tester).color,
        theme.colors.transparentBackgroundHover,
        reason: 'one frame, no tween',
      );
    });
  });

  group('expansion', () {
    testWidgets('single mode closes the previous panel', (tester) async {
      await pump(
        tester,
        SizedBox(
          width: 400,
          child: FluentAccordion(
            children: <Widget>[
              for (final v in <String>['a', 'b'])
                FluentAccordionItem(
                  key: Key(v),
                  value: v,
                  header: Text(v),
                  child: SizedBox(key: Key('panel-$v'), height: 40),
                ),
            ],
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('a')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('panel-a')), findsOneWidget);

      await tester.tap(find.byKey(const Key('b')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('panel-a')), findsNothing);
      expect(find.byKey(const Key('panel-b')), findsOneWidget);
    });

    testWidgets('multiple mode keeps both open', (tester) async {
      await pump(
        tester,
        SizedBox(
          width: 400,
          child: FluentAccordion(
            multiple: true,
            collapsible: true,
            children: <Widget>[
              for (final v in <String>['a', 'b'])
                FluentAccordionItem(
                  key: Key(v),
                  value: v,
                  header: Text(v),
                  child: SizedBox(key: Key('panel-$v'), height: 40),
                ),
            ],
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('b')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('panel-a')), findsOneWidget);
      expect(find.byKey(const Key('panel-b')), findsOneWidget);
    });

    testWidgets('collapsible false refuses to close the last open panel', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 400,
          child: FluentAccordion(
            defaultOpenItems: <Object>{'a'},
            children: <Widget>[
              FluentAccordionItem(
                key: item,
                value: 'a',
                header: Text('a'),
                child: SizedBox(key: panel, height: 40),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(item));
      await tester.pumpAndSettle();
      expect(find.byKey(panel), findsOneWidget);
    });

    testWidgets('a controlled accordion reports and obeys the caller', (
      tester,
    ) async {
      Set<Object>? reported;
      await pump(
        tester,
        SizedBox(
          width: 400,
          child: FluentAccordion(
            collapsible: true,
            openItems: const <Object>{},
            onToggle: (next) => reported = next,
            children: const <Widget>[
              FluentAccordionItem(
                key: item,
                value: 'a',
                header: Text('a'),
                child: SizedBox(key: panel, height: 40),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byKey(item));
      await tester.pumpAndSettle();
      expect(reported, const <Object>{'a'});
      expect(
        find.byKey(panel),
        findsNothing,
        reason: 'the caller owns the set; nothing opens until they say so',
      );
    });

    testWidgets('single mode keeps only the first default open item', (
      tester,
    ) async {
      await pump(
        tester,
        SizedBox(
          width: 400,
          child: FluentAccordion(
            defaultOpenItems: const <Object>{'a', 'b'},
            children: <Widget>[
              for (final v in <String>['a', 'b'])
                FluentAccordionItem(
                  key: Key(v),
                  value: v,
                  header: Text(v),
                  child: SizedBox(key: Key('panel-$v'), height: 40),
                ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('panel-a')), findsOneWidget);
      expect(find.byKey(const Key('panel-b')), findsNothing);
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
        FluentAccordionItemTheme(
          style: FluentAccordionItemStyle.from(backgroundColor: themed),
          child: one(
            style: FluentAccordionItemStyle.from(backgroundColor: explicit),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(headerDecoration(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentAccordionItemTheme(
          style: FluentAccordionItemStyle.from(backgroundColor: themed),
          child: one(),
        ),
      );
      await tester.pumpAndSettle();
      expect(headerDecoration(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        one(
          style: FluentAccordionItemStyle.from(
            borderRadius: FluentRadius.allCircular,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(headerDecoration(tester).borderRadius, FluentRadius.allCircular);
      expect(itemHeight(tester), 44, reason: 'the height must survive');
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentAccordionItemBaseState(
        enabled: true,
        expanded: false,
        expandIconPosition: FluentAccordionExpandIconPosition.start,
        header: Text('H'),
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        SizedBox(
          width: 400,
          child: KeyedSubtree(
            key: item,
            child: buildFluentAccordionItem(
              base,
              FluentAccordionItemStyle.from(
                backgroundColor: mine,
                borderRadius: FluentRadius.allLarge,
              ),
              const <WidgetState>{},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(headerDecoration(tester).color, mine);
      expect(headerDecoration(tester).borderRadius, FluentRadius.allLarge);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentAccordionItemState(
        size: FluentAccordionSize.small,
        header: const Text('H'),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentAccordionItemStyle(state, theme).merge(
        FluentAccordionItemStyle.from(borderRadius: FluentRadius.allCircular),
      );

      await pump(
        tester,
        SizedBox(
          width: 400,
          child: KeyedSubtree(
            key: item,
            child: buildFluentAccordionItem(
              state,
              adjusted,
              const <WidgetState>{},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(headerDecoration(tester).borderRadius, FluentRadius.allCircular);
      expect(
        itemHeight(tester),
        44,
        reason: 'every Figma size is 44 high, small included',
      );
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the item', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.neutralForeground1: magenta},
            child: Center(child: one()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(headerTextStyle(tester).color, magenta);
    });

    testWidgets('high contrast leaves nothing invisible', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(tester, one(expanded: true), theme: theme);
      await tester.pumpAndSettle();

      // The header paints no border at all — upstream declares none — so the
      // high-contrast risk here is the opposite one: a flat header that never
      // reacts. Fluent's transparent hover token is the opaque system highlight
      // in this theme, so the header does.
      expect(headerDecoration(tester).border, isNull);
      expect(theme.colors.transparentBackgroundHover.a, 1.0);
      expect(headerTextStyle(tester).color!.a, 1.0);
      expect(headerTextStyle(tester).color, theme.colors.neutralForeground1);
    });
  });

  group('behaviour', () {
    testWidgets('toggles on tap and on Enter', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, one(focusNode: node));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(item));
      await tester.pumpAndSettle();
      expect(find.byKey(panel), findsOneWidget);

      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        find.byKey(panel),
        findsNothing,
        reason: 'keyboard activation must work',
      );
    });

    testWidgets('disabled is a real state, not a visual treatment', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

      await pump(tester, one(enabled: false, focusNode: node));
      await tester.pumpAndSettle();
      expect(
        headerTextStyle(tester).color,
        theme.colors.neutralForegroundDisabled,
      );

      await tester.tap(find.byKey(item), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        find.byKey(panel),
        findsNothing,
        reason: 'the tap must do nothing',
      );

      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isFalse, reason: 'a disabled header refuses focus');

      await hover(tester, find.byKey(item));
      await tester.pump();
      expect(
        headerTextStyle(tester).color,
        theme.colors.neutralForegroundDisabled,
        reason: 'a disabled header must not adopt any interaction token',
      );
    });

    testWidgets('the header announces itself as an expandable button', (
      tester,
    ) async {
      await pump(tester, one());
      await tester.pumpAndSettle();
      expect(
        headerSemantics(tester),
        matchesSemantics(
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasEnabledState: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasExpandedState: true,
          isExpanded: false,
          label: 'Header',
        ),
      );

      await tester.tap(find.byKey(item));
      await tester.pumpAndSettle();
      expect(
        headerSemantics(tester),
        matchesSemantics(
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasEnabledState: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasExpandedState: true,
          isExpanded: true,
          label: 'Header',
        ),
      );
    });
  });
}
