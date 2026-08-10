import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

/// The style class carries only what upstream's CSS actually applies. Seven of
/// the nine `CartesianChartStyles` slots are commented out in
/// `useCartesianChartStyles.styles.ts:132-162`, so a style bag mirroring all
/// nine would be seven fields of theatre.
void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  T? resolve<T>(WidgetStateProperty<T?>? property) =>
      property?.resolve(const <WidgetState>{});

  group('resolveFluentCartesianChartStyle', () {
    final style = resolveFluentCartesianChartStyle(theme);

    test('grid and tick lines resolve to the axis line token at 0.2', () {
      expect(
        resolve(style.gridLineOpacity),
        0.2,
        reason: 'useCartesianChartStyles.styles.ts:68 and :84',
      );
      expect(
        resolve(style.gridLineColor)!.toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason: 'stroke: tokens.colorNeutralForeground1, :69 and :85',
      );
      expect(
        resolve(style.axisLineColor)!.toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason: 'the tick line uses the same token as the gridline',
      );
    });

    test('the legend row keeps the shell padding, not the legend padding', () {
      expect(
        resolve(style.legendRowPadding),
        const EdgeInsetsDirectional.only(
          top: FluentSpacing.s,
          start: FluentSpacing.xl,
        ),
        reason:
            'useCartesianChartStyles.styles.ts:103-104 — spacingVerticalS and '
            'spacingHorizontalXL, which is 20 and not the legend file own 12',
      );
    });

    test('dimming is opacity 0.1', () {
      expect(
        resolve(style.dimmedOpacity),
        0.1,
        reason: 'opacityChangeOnHover, useCartesianChartStyles.styles.ts:99',
      );
    });

    test('the tooltip surface uses borderRadiusSmall', () {
      expect(
        resolve(style.tooltipBorderRadius),
        const BorderRadius.all(FluentRadius.small),
        reason: 'getTooltipStyle, Common.styles.ts:45',
      );
      expect(
        resolve(style.tooltipBackgroundColor)!.toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason: 'Common.styles.ts:44',
      );
    });

    test('axis text resolves to caption2Strong', () {
      expect(
        resolve(style.axisTextStyle)!.fontSize,
        10,
        reason:
            'typographyStyles.caption2Strong is 10/14/semibold, matching the '
            "canvas fallback '600 10px \"Segoe UI\"' at utilities.ts:1267",
      );
    });

    test('high contrast still resolves every colour', () {
      final hc = resolveFluentCartesianChartStyle(
        FluentThemeData.highContrast(fontPlatform: FluentFontPlatform.web),
      );
      expect(
        resolve(hc.gridLineColor),
        isNotNull,
        reason:
            'a null here would silently erase the gridlines in the mode nobody '
            'looks at',
      );
    });
  });

  // A tick line is the `line` inside a d3-axis tick group, which is the only
  // `g` that also holds the tick's `text`. Selecting on opacity instead would
  // assert the expectation against itself, and selecting every `line` would
  // sweep in the line chart's series strokes and its white marker halos.
  bool isTickLine(OracleStory story, OracleElement line) {
    final group = story.parentOf(line);
    return group != null &&
        story.childrenOf(group).any((child) => child.tag == 'text');
  }

  group('against the Oracle B corpus', () {
    final style = resolveFluentCartesianChartStyle(theme);

    // Three cartesian stories from three different components: whatever the
    // shell resolves has to match all of them, or it is a per-chart constant
    // masquerading as a token.
    const storyIds = <String>[
      'charts-areachart--area-chart-multiple-negative',
      'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-basic',
      'charts-linechart--line-chart-basic',
    ];

    for (final storyId in storyIds) {
      test('$storyId draws its tick lines at the resolved token', () {
        final story = loadOracleStory(storyId);
        final ticks = story
            .byTag('line')
            .where((line) => isTickLine(story, line))
            .toList();
        expect(
          ticks,
          isNotEmpty,
          reason:
              '$storyId captured no axis tick lines, so the loop below would '
              'assert nothing',
        );
        for (final tick in ticks) {
          expect(
            tick.opacity,
            closeTo(resolve(style.gridLineOpacity)!, kOracleGeometryTolerance),
            reason:
                'the captured tick opacity is the style bag gridLineOpacity',
          );
          expectOracleColour(
            '$storyId tick stroke',
            resolve(style.axisLineColor),
            tick.stroke,
          );
        }
      });

      test('$storyId draws its tick labels at the resolved text style', () {
        final story = loadOracleStory(storyId);
        final resolved = resolve(style.axisTextStyle)!;
        final labels = story.byTag('text').where((text) {
          // Line chart's hover label is a `text` sitting straight under
          // the svg, with no tick group to belong to.
          final group = story.parentOf(text);
          return group != null &&
              story.childrenOf(group).any((sibling) => sibling.tag == 'line');
        }).toList();
        expect(
          labels,
          isNotEmpty,
          reason: '$storyId captured no tick labels to compare against',
        );
        for (final label in labels) {
          expect(
            label.fontSize,
            closeTo(resolved.fontSize!, kOracleGeometryTolerance),
            reason: 'caption2Strong is 10px in the capture and in the token',
          );
          expect(
            label.fontWeight,
            '${resolved.fontWeight!.value}',
            reason: 'caption2Strong is semibold — 600 — in both',
          );
          expectOracleColour(
            '$storyId tick label fill',
            resolve(style.axisTextStyle)?.color,
            label.fill,
          );
        }
      });
    }
  });

  group('the house style contract', () {
    test('merge takes the non-null properties of the argument', () {
      final base = FluentCartesianChartStyle.from(dimmedOpacity: 0.1);
      final merged = base.merge(
        FluentCartesianChartStyle.from(gridLineOpacity: 0.5),
      );
      expect(
        resolve(merged.dimmedOpacity),
        0.1,
        reason: 'merging is per property, not wholesale',
      );
      expect(
        resolve(merged.gridLineOpacity),
        0.5,
        reason: 'the argument wins where it is non-null',
      );
    });

    test('merge with null returns the receiver', () {
      final base = FluentCartesianChartStyle.from(dimmedOpacity: 0.1);
      expect(
        base.merge(null),
        same(base),
        reason: 'the FluentBadgeStyle contract',
      );
    });

    test('copyWith replaces only what it is given', () {
      final copy = FluentCartesianChartStyle.from(
        dimmedOpacity: 0.1,
        gridLineOpacity: 0.2,
      ).copyWith(dimmedOpacity: const WidgetStatePropertyAll<double?>(0.9));
      expect(resolve(copy.dimmedOpacity), 0.9, reason: 'the replaced property');
      expect(
        resolve(copy.gridLineOpacity),
        0.2,
        reason: 'the untouched property',
      );
    });

    test('equal styles compare equal and hash alike', () {
      final a = FluentCartesianChartStyle.from(dimmedOpacity: 0.1);
      final b = FluentCartesianChartStyle.from(dimmedOpacity: 0.1);
      expect(a == b, isTrue, reason: 'value equality across identical bags');
      expect(a.hashCode, b.hashCode, reason: 'hashCode must agree with ==');
      expect(
        a == FluentCartesianChartStyle.from(dimmedOpacity: 0.2),
        isFalse,
        reason: 'a differing property must break equality',
      );
    });
  });
}
