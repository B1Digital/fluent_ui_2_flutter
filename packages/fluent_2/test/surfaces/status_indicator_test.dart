import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentStatusIndicator` is the first consumer of the ported STATUS token
/// layer, so these tests are as much a check on `theme.colors.status*` as on the
/// widget: every category asserts the exact alias getter its Figma variable
/// resolves to, rather than a hex value.
///
/// [expectSpec] is deliberately not used. The fixture's `size.width` is Figma's
/// frame width with Segoe UI placeholder text rather than the bundled Selawik
/// substitute, so width is unassertable here and every other property is
/// asserted explicitly instead.
void main() {
  const key = Key('status');

  /// Figma's `Size` values. Note `Medium (default)`: the designer typed the
  /// marker in lower case, so the extractor's ` (Default)` strip does not fire
  /// and the value carries it verbatim.
  const sizeNames = <FluentStatusIndicatorSize, String>{
    FluentStatusIndicatorSize.small: 'Small',
    FluentStatusIndicatorSize.medium: 'Medium (default)',
    FluentStatusIndicatorSize.large: 'Large',
  };

  const categoryNames = <FluentStatusIndicatorCategory, String>{
    FluentStatusIndicatorCategory.informational: 'Informational/Neutral',
    FluentStatusIndicatorCategory.success: 'Success',
    FluentStatusIndicatorCategory.error: 'Error',
    FluentStatusIndicatorCategory.active: 'Active/ In Progress',
    FluentStatusIndicatorCategory.warning: 'Warning',
  };

  const messageNames = <FluentStatusIndicatorMessage, String>{
    FluentStatusIndicatorMessage.archived: 'Archived',
    FluentStatusIndicatorMessage.cancelled: 'Cancelled',
    FluentStatusIndicatorMessage.draft: 'Draft',
    FluentStatusIndicatorMessage.failed: 'Failed',
    FluentStatusIndicatorMessage.inProgress: 'InProgress',
    FluentStatusIndicatorMessage.newItem: 'New',
    FluentStatusIndicatorMessage.notStarted: 'Not started',
    FluentStatusIndicatorMessage.pause: 'Pause',
    FluentStatusIndicatorMessage.pending: 'Pending',
    FluentStatusIndicatorMessage.scheduled: 'Scheduled',
    FluentStatusIndicatorMessage.success: 'Success',
    FluentStatusIndicatorMessage.synced: 'Synced',
    FluentStatusIndicatorMessage.syncing: 'Syncing',
    FluentStatusIndicatorMessage.unknown: 'Unknown',
    FluentStatusIndicatorMessage.warning: 'Warning',
    FluentStatusIndicatorMessage.genericInformation: 'Generic information',
  };

  Future<void> pump(
    WidgetTester tester,
    Widget indicator, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: indicator),
    ),
  );

  Widget indicator({
    FluentStatusIndicatorMessage message = FluentStatusIndicatorMessage.success,
    FluentStatusIndicatorCategory? category,
    FluentStatusIndicatorSize size = FluentStatusIndicatorSize.medium,
    FluentStatusIndicatorStyle? style,
  }) => FluentStatusIndicator(
    key: key,
    message: message,
    category: category,
    size: size,
    style: style,
    icon: const SizedBox.shrink(),
    label: const Text('Status'),
  );

  /// The icon tint and size the indicator actually pushed down to its glyph.
  IconThemeData iconThemeOf(WidgetTester tester) => tester
      .widgetList<IconTheme>(
        find.descendant(of: find.byKey(key), matching: find.byType(IconTheme)),
      )
      .last
      .data;

  Row rowOf(WidgetTester tester) => tester.widget<Row>(
    find.descendant(of: find.byKey(key), matching: find.byType(Row)),
  );

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('status_indicator');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 48);
      expect(spec.properties['Message']!.length, messageNames.length);
      expect(spec.properties['Size']!.length, sizeNames.length);
      expect(spec.properties['Category']!.length, categoryNames.length);
    });

    testWidgets('geometry and type ramp match every size', (tester) async {
      // Icon edge lengths are not in the fixture: the extractor records the
      // variant frame, and the icon is the `IconHolder > Shape` two levels down.
      // Measured read-only off nodes 9116:27474 / 27466 / 27470.
      const iconSizes = <FluentStatusIndicatorSize, double>{
        FluentStatusIndicatorSize.small: FluentSize.size120,
        FluentStatusIndicatorSize.medium: FluentSize.size160,
        FluentStatusIndicatorSize.large: FluentSize.size200,
      };

      for (final size in FluentStatusIndicatorSize.values) {
        final variant = spec.variant({
          'Message': 'Success',
          'Size': sizeNames[size]!,
          'Category': 'Success',
        });

        await pump(tester, indicator(size: size));

        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: '${size.name}: height',
        );
        expect(rowOf(tester).spacing, variant.gap, reason: '${size.name}: gap');
        expect(
          iconThemeOf(tester).size,
          iconSizes[size],
          reason: '${size.name}: icon size',
        );

        final padding = tester
            .widgetList<Padding>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Padding),
              ),
            )
            .first
            .padding
            .resolve(TextDirection.ltr);
        expect(padding, EdgeInsets.zero, reason: '${size.name}: padding');

        final text = variant.text!;
        final style = resolvedTextStyleOf(tester, of: find.byKey(key));
        expect(
          style.fontSize,
          text.fontSize,
          reason: '${size.name}: text.fontSize',
        );
        expect(
          style.height! * style.fontSize!,
          text.lineHeight,
          reason: '${size.name}: text.lineHeight',
        );
      }
    });

    test('every message carries the category Figma pairs it with', () {
      // Category is not a free axis: 16 messages x 3 sizes is exactly the 48
      // variants in the set, so each message ships under one category only.
      for (final variant in spec.variants) {
        final message = messageNames.entries
            .firstWhere((e) => e.value == variant.props['Message'])
            .key;
        final category = categoryNames.entries
            .firstWhere((e) => e.value == variant.props['Category'])
            .key;
        expect(message.category, category, reason: variant.name);
      }
    });

    test('the label token is neutralForeground1 on every variant', () {
      for (final variant in spec.variants) {
        expect(variant.text!.tokens['fills'], [
          'Neutral/Foreground/1/Rest',
        ], reason: variant.name);
      }
    });
  });

  group('category to token mapping', () {
    // The half of the spec the fixture cannot hold: the icon's bound variable.
    // Read read-only off the `IconHolder > Shape` vector of one variant per
    // category. Two of the five are NOT status tokens, which is the finding.
    testWidgets('each category selects the token Figma bound to it', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final expected = <FluentStatusIndicatorCategory, Color>{
        // Neutral/Foreground/3/Rest
        FluentStatusIndicatorCategory.informational:
            theme.colors.neutralForeground3,
        // Status/Success/Foreground/1/Rest
        FluentStatusIndicatorCategory.success:
            theme.colors.statusSuccessForeground1,
        // Status/Danger/Foreground/1/Rest
        FluentStatusIndicatorCategory.error:
            theme.colors.statusDangerForeground1,
        // Brand/Foreground/1/Rest
        FluentStatusIndicatorCategory.active: theme.colors.brandForeground1,
        // Status/Warning/Foreground/1/Rest
        FluentStatusIndicatorCategory.warning:
            theme.colors.statusWarningForeground1,
      };

      for (final entry in expected.entries) {
        await pump(tester, indicator(category: entry.key));
        expect(
          iconThemeOf(tester).color,
          entry.value,
          reason: '${entry.key.name}: icon colour',
        );
        expect(
          resolvedTextStyleOf(tester, of: find.byKey(key)).color,
          theme.colors.neutralForeground1,
          reason: '${entry.key.name}: label colour',
        );
      }
    });

    testWidgets('an explicit category overrides the message default', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        indicator(
          message: FluentStatusIndicatorMessage.success,
          category: FluentStatusIndicatorCategory.error,
        ),
      );
      expect(iconThemeOf(tester).color, theme.colors.statusDangerForeground1);
    });
  });

  group('motion', () {
    testWidgets('a category change is instant — Fluent specs no transition', (
      tester,
    ) async {
      // The Figma set has no State axis and upstream ships no StatusIndicator
      // transition, so the colour must land on the very next frame. This is the
      // same decision as Checkbox in FluentMotionSpec: absence, not oversight.
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        indicator(category: FluentStatusIndicatorCategory.success),
      );
      await tester.pumpAndSettle();
      expect(iconThemeOf(tester).color, theme.colors.statusSuccessForeground1);

      await pump(
        tester,
        indicator(category: FluentStatusIndicatorCategory.error),
      );
      await tester.pump();
      expect(
        iconThemeOf(tester).color,
        theme.colors.statusDangerForeground1,
        reason: 'must be instant, not mid-tween',
      );
      expect(tester.hasRunningAnimations, isFalse);
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
        FluentStatusIndicatorTheme(
          style: FluentStatusIndicatorStyle.from(iconColor: themed),
          child: indicator(
            style: FluentStatusIndicatorStyle.from(iconColor: explicit),
          ),
        ),
      );
      expect(iconThemeOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentStatusIndicatorTheme(
          style: FluentStatusIndicatorStyle.from(iconColor: themed),
          child: indicator(),
        ),
      );
      expect(iconThemeOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        indicator(style: FluentStatusIndicatorStyle.from(gap: 17)),
      );
      expect(rowOf(tester).spacing, 17);
      expect(
        iconThemeOf(tester).color,
        theme.colors.statusSuccessForeground1,
        reason: 'overriding the gap must not drop the status tint',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentStatusIndicatorBaseState(
        icon: SizedBox.shrink(),
        label: Text('S'),
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentStatusIndicator(
            base,
            FluentStatusIndicatorStyle.from(iconColor: mine, iconSize: 24),
            const <WidgetState>{},
          ),
        ),
      );
      expect(iconThemeOf(tester).color, mine);
      expect(iconThemeOf(tester).size, 24);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentStatusIndicatorState(
        message: FluentStatusIndicatorMessage.warning,
        icon: const SizedBox.shrink(),
        label: const Text('S'),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentStatusIndicatorStyle(
        state,
        theme,
      ).merge(FluentStatusIndicatorStyle.from(gap: 2));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentStatusIndicator(
            state,
            adjusted,
            const <WidgetState>{},
          ),
        ),
      );
      expect(iconThemeOf(tester).color, theme.colors.statusWarningForeground1);
      expect(rowOf(tester).spacing, 2);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the indicator', (
      tester,
    ) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.statusSuccessForeground1: magenta},
            child: Center(child: indicator()),
          ),
        ),
      );
      expect(iconThemeOf(tester).color, magenta);
    });

    testWidgets('high contrast paints every category opaquely', (tester) async {
      // Fluent drops status colour in high contrast: all five categories
      // collapse onto canvasText, so meaning has to come from the glyph and the
      // label. What must never happen is a tint that silently disappears.
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final category in FluentStatusIndicatorCategory.values) {
        await pump(tester, indicator(category: category), theme: theme);
        final icon = iconThemeOf(tester).color!;
        expect(icon.a, 1.0, reason: '${category.name}: icon must be opaque');
        expect(
          icon,
          theme.colors.neutralForeground1,
          reason: '${category.name}: high contrast has no status colour',
        );
        expect(
          resolvedTextStyleOf(tester, of: find.byKey(key)).color!.a,
          1.0,
          reason: '${category.name}: label must be opaque',
        );
      }
    });
  });

  group('behaviour', () {
    final spec = loadSpec('status_indicator');

    test('there is no disabled state to render', () {
      // Not a gap in the port: the Figma set has no State axis at all, so
      // disabled is not a visual treatment this component may invent.
      expect(spec.properties.keys, ['Message', 'Size', 'Category']);
    });

    testWidgets('it is non-interactive', (tester) async {
      await pump(tester, indicator());
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentInteractive),
        ),
        findsNothing,
        reason: 'a status indicator never takes hover, press or focus',
      );
    });

    testWidgets('a semantic label describes the glyph', (tester) async {
      await pump(
        tester,
        const FluentStatusIndicator(
          key: key,
          message: FluentStatusIndicatorMessage.failed,
          icon: SizedBox.shrink(),
          semanticLabel: 'Failed',
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(label: 'Failed'),
      );
    });
  });
}
