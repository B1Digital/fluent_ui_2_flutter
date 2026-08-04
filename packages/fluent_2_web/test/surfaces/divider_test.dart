import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentDivider` is the first non-interactive component in the set, so these
/// tests assert the *absence* of the interaction machinery as deliberately as
/// they assert the geometry: no `FluentInteractive`, no focus ring, and — the
/// part most likely to be "improved" later — no transition at all.
///
/// The Figma set carries only two variant axes (`Layout`, `Vertical`). The other
/// two axes are Figma **variable collection modes** bound onto the component
/// rather than variant properties: `Divider appearance` (Default / Subtle /
/// Strong / Brand) and `Divider padding` (Full / Inset). They are real API
/// surface — React ships both as props — so they are covered here too.
void main() {
  const key = Key('divider');
  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  /// Pumps [divider] into a box that is bounded on exactly the axis Fluent
  /// stretches along: width for a horizontal rule, height for a vertical one.
  /// The other axis stays loose so the component's own hug is observable.
  Future<void> pump(
    WidgetTester tester,
    Widget divider, {
    FluentThemeData? theme,
    bool vertical = false,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(
        child: SizedBox(
          width: vertical ? null : 280,
          height: vertical ? 84 : null,
          child: divider,
        ),
      ),
    ),
  );

  /// The rules themselves. Each is a [ColoredBox] inside a [SizedBox]; the
  /// divider paints nothing else.
  Finder rules() =>
      find.descendant(of: find.byKey(key), matching: find.byType(ColoredBox));

  List<Rect> ruleRects(WidgetTester tester) => <Rect>[
    for (var i = 0; i < rules().evaluate().length; i++)
      tester.getRect(rules().at(i)),
  ];

  List<Color> ruleColors(WidgetTester tester) =>
      tester.widgetList<ColoredBox>(rules()).map((b) => b.color).toList();

  List<EdgeInsets> paddingsOf(WidgetTester tester) => tester
      .widgetList<Padding>(
        find.descendant(of: find.byKey(key), matching: find.byType(Padding)),
      )
      .map((p) => p.padding.resolve(TextDirection.ltr))
      .toList();

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('divider');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 6);
      expect(spec.properties.keys, containsAll(<String>['Layout', 'Vertical']));
    });

    testWidgets('every Layout x Vertical variant lays its rules out as Figma '
        'does', (tester) async {
      for (final variant in spec.variants) {
        final vertical = variant.props['Vertical'] == 'True';
        final alignment = switch (variant.props['Layout']) {
          'Start' => FluentDividerAlignment.start,
          'End' => FluentDividerAlignment.end,
          _ => FluentDividerAlignment.center,
        };

        await pump(
          tester,
          FluentDivider(
            key: key,
            vertical: vertical,
            alignment: alignment,
            child: const Text('Text'),
          ),
          vertical: vertical,
        );

        final rects = ruleRects(tester);
        expect(rects.length, 2, reason: '${variant.name}: a rule either side');

        // Figma node 9000:6133 — RECTANGLE "Divider line", one hairline thick,
        // fill bound to the `Stroke color` component variable.
        for (final rect in rects) {
          expect(
            vertical ? rect.width : rect.height,
            FluentStroke.thin,
            reason: '${variant.name}: rule thickness',
          );
        }

        final leading = vertical ? rects.first.height : rects.first.width;
        final trailing = vertical ? rects.last.height : rects.last.width;

        // Layout=Start pins the leading rule to a fixed 8 and lets the trailing
        // one grow; Layout=End is the mirror; Layout=Center grows both.
        switch (alignment) {
          case FluentDividerAlignment.start:
            expect(
              leading,
              FluentSpacing.s,
              reason: '${variant.name}: leading stub',
            );
            expect(
              trailing,
              greaterThan(leading),
              reason: '${variant.name}: trailing rule fills',
            );
          case FluentDividerAlignment.end:
            expect(
              trailing,
              FluentSpacing.s,
              reason: '${variant.name}: trailing stub',
            );
            expect(
              leading,
              greaterThan(trailing),
              reason: '${variant.name}: leading rule fills',
            );
          case FluentDividerAlignment.center:
            expect(
              leading,
              trailing,
              reason: '${variant.name}: centred rules are equal',
            );
        }

        final size = tester.getSize(find.byKey(key));
        if (vertical) {
          // Vertical stretches along the axis it is given, which is what the
          // 84-high Figma frame records.
          expect(
            size.height,
            variant.size.height,
            reason: '${variant.name}: fills its height',
          );
        } else {
          expect(
            size.width,
            variant.size.width,
            reason: '${variant.name}: fills its width',
          );
          // 20, not 16: the horizontal Content frame is authored at a FIXED 20
          // so the band does not change height when the icon slot is empty.
          expect(
            size.height,
            variant.size.height,
            reason: '${variant.name}: label band height',
          );
        }
      }
    });

    testWidgets('the label uses the caption1 ramp', (tester) async {
      final variant = spec.variant(const {
        'Layout': 'Center',
        'Vertical': 'False',
      });
      await pump(
        tester,
        const FluentDivider(key: key, child: Text('Text')),
        theme: light,
      );

      final style = resolvedTextStyleOf(tester, of: find.byKey(key));
      expect(style.fontSize, variant.text!.fontSize);
      expect(style.height! * style.fontSize!, variant.text!.lineHeight);
    });

    testWidgets('the label box carries Figma\'s own padding and gap', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentDivider(
          key: key,
          icon: SizedBox(width: 20, height: 20),
          child: Text('Text'),
        ),
      );

      final paddings = paddingsOf(tester);
      // Divider padding = Full, the default mode: no outer inset.
      expect(paddings.first, EdgeInsets.zero, reason: 'outer inset');
      // Figma node 9000:6134 — FRAME "Content", paddingLeft/Right bound to
      // Spacing/Horizontal/M.
      expect(
        paddings.last,
        const EdgeInsets.symmetric(horizontal: FluentSpacing.m),
        reason: 'label box padding',
      );
      // ...and itemSpacing bound to Spacing/Horizontal/SNudge.
      expect(
        tester
            .widgetList<Row>(
              find.descendant(of: find.byKey(key), matching: find.byType(Row)),
            )
            .last
            .spacing,
        FluentSpacing.sNudge,
      );
    });

    testWidgets('inset switches the Divider padding collection to Inset', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentDivider(key: key, inset: true, child: Text('Text')),
      );
      expect(
        paddingsOf(tester).first,
        const EdgeInsets.symmetric(horizontal: FluentSpacing.m),
      );

      await pump(
        tester,
        const FluentDivider(
          key: key,
          inset: true,
          vertical: true,
          child: Text('Text'),
        ),
        vertical: true,
      );
      expect(
        paddingsOf(tester).first,
        const EdgeInsets.symmetric(vertical: FluentSpacing.m),
      );
    });

    testWidgets('each appearance selects the token pair Figma names', (
      tester,
    ) async {
      final pairs = <FluentDividerAppearance, (Color, Color)>{
        FluentDividerAppearance.standard: (
          light.colors.neutralStroke2,
          light.colors.neutralForeground2,
        ),
        FluentDividerAppearance.subtle: (
          light.colors.neutralStroke3,
          light.colors.neutralForeground3,
        ),
        FluentDividerAppearance.strong: (
          light.colors.neutralStroke1,
          light.colors.neutralForeground1,
        ),
        FluentDividerAppearance.brand: (
          light.colors.brandStroke1,
          light.colors.brandForeground1,
        ),
      };

      for (final entry in pairs.entries) {
        await pump(
          tester,
          FluentDivider(
            key: key,
            appearance: entry.key,
            child: const Text('Text'),
          ),
          theme: light,
        );
        expect(
          ruleColors(tester),
          everyElement(entry.value.$1),
          reason: '${entry.key.name}: rule colour',
        );
        expect(
          resolvedTextStyleOf(tester, of: find.byKey(key)).color,
          entry.value.$2,
          reason: '${entry.key.name}: label colour',
        );
      }
    });
  });

  group('motion', () {
    testWidgets('there is none: an appearance change lands on the next frame', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentDivider(key: key, child: Text('Text')),
        theme: light,
      );
      await tester.pumpAndSettle();
      expect(ruleColors(tester).first, light.colors.neutralStroke2);

      await pump(
        tester,
        const FluentDivider(
          key: key,
          appearance: FluentDividerAppearance.strong,
          child: Text('Text'),
        ),
        theme: light,
      );
      expect(
        ruleColors(tester).first,
        light.colors.neutralStroke1,
        reason: 'must be instant, not tweened',
      );
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'nothing may be left animating',
      );
      expect(
        find.byWidgetPredicate((w) => w is FluentAnimatedStyle<Color>),
        findsNothing,
        reason: 'upstream declares no transition on the Divider',
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
        FluentDividerTheme(
          style: FluentDividerStyle.from(lineColor: themed),
          child: FluentDivider(
            key: key,
            style: FluentDividerStyle.from(lineColor: explicit),
            child: const Text('Text'),
          ),
        ),
      );
      expect(ruleColors(tester), everyElement(explicit));
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentDividerTheme(
          style: FluentDividerStyle.from(lineColor: themed),
          child: const FluentDivider(key: key, child: Text('Text')),
        ),
      );
      expect(ruleColors(tester), everyElement(themed));
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentDivider(
          key: key,
          appearance: FluentDividerAppearance.brand,
          style: FluentDividerStyle.from(lineThickness: FluentStroke.thick),
          child: const Text('Text'),
        ),
        theme: light,
      );
      expect(ruleRects(tester).first.height, FluentStroke.thick);
      expect(
        ruleColors(tester),
        everyElement(light.colors.brandStroke1),
        reason: 'overriding thickness must not drop the brand stroke',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentDividerBaseState(
        vertical: false,
        alignment: FluentDividerAlignment.center,
        label: Text('Text'),
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentDivider(
            base,
            FluentDividerStyle.from(lineColor: mine, lineThickness: 3),
            const <WidgetState>{},
          ),
        ),
      );
      expect(ruleColors(tester), everyElement(mine));
      expect(ruleRects(tester).first.height, 3);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentDividerState(label: const Text('Text'));
      final adjusted = resolveFluentDividerStyle(
        state,
        light,
      ).merge(FluentDividerStyle.from(lineThickness: FluentStroke.thicker));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentDivider(state, adjusted, const <WidgetState>{}),
        ),
        theme: light,
      );
      expect(ruleColors(tester), everyElement(light.colors.neutralStroke2));
      expect(ruleRects(tester).first.height, FluentStroke.thicker);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the divider', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: const FluentThemeOverride(
            colors: {FluentColorToken.neutralStroke2: magenta},
            child: Center(
              child: SizedBox(
                width: 280,
                child: FluentDivider(key: key, child: Text('Text')),
              ),
            ),
          ),
        ),
      );
      expect(ruleColors(tester), everyElement(magenta));
    });

    testWidgets('high contrast paints an opaque rule for every appearance', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final appearance in FluentDividerAppearance.values) {
        await pump(
          tester,
          FluentDivider(
            key: key,
            appearance: appearance,
            child: const Text('Text'),
          ),
          theme: theme,
        );
        // Every Divider stroke token maps to canvasText in high contrast, so a
        // rule that is a faint grey in light mode must be fully opaque here.
        expect(
          ruleColors(tester).first.a,
          1.0,
          reason: '${appearance.name}: rule must not be invisible',
        );
      }
    });
  });

  group('behaviour', () {
    testWidgets('it is not interactive at all', (tester) async {
      await pump(tester, const FluentDivider(key: key, child: Text('Text')));
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentInteractive),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentFocusRing),
        ),
        findsNothing,
        reason: 'a separator is never a focus target, so it has no ring',
      );
      // Disabled is not a Divider state: there is nothing to disable, so the
      // component exposes no such flag and never resolves WidgetState.disabled.
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Focus)),
        findsNothing,
      );
    });

    testWidgets('a label-less divider is one uninterrupted rule', (
      tester,
    ) async {
      await pump(tester, const FluentDivider(key: key));
      expect(rules().evaluate().length, 1);
      expect(ruleRects(tester).single.width, 280);
      expect(ruleRects(tester).single.height, FluentStroke.thin);
    });
  });
}
