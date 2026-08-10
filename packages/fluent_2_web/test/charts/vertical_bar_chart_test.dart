import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/vertical_bar_chart_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

void main() {
  const states = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  final palette = theme.colors.palette;

  group('FluentVerticalBarChartStyle', () {
    test('carries the five-token default palette in source order', () {
      final style = resolveFluentVerticalBarChartStyle(theme);
      final ramp = style.palette!.resolve(states)!;
      expect(
        ramp.length,
        5,
        reason: 'VerticalBarChart.tsx:306-312 lists exactly five tokens',
      );
      expect(
        ramp.first.toARGB32(),
        palette.foreground2Rest(FluentPaletteFamily.blue).toARGB32(),
        reason: 'the first default colour is colorPaletteBlueForeground2',
      );
      expect(
        ramp.last.toARGB32(),
        palette.foreground2Rest(FluentPaletteFamily.darkOrange).toARGB32(),
        reason:
            'the fifth and last is colorPaletteDarkOrangeForeground2 '
            '(VerticalBarChart.tsx:311)',
      );
    });

    test(
      'the line legend swatch colour differs from the drawn line colour',
      () {
        final style = resolveFluentVerticalBarChartStyle(theme);
        expect(
          style.lineColor!.resolve(states)!.toARGB32(),
          palette.background1Rest(FluentPaletteFamily.yellow)!.toARGB32(),
          reason:
              'parity: VerticalBarChart.tsx:165 draws with '
              'colorPaletteYellowBackground1',
        );
        expect(
          style.lineLegendSwatchColor!.resolve(states)!.toARGB32(),
          palette.foreground1Rest(FluentPaletteFamily.yellow)!.toARGB32(),
          reason:
              'parity: VerticalBarChart.tsx:826 uses '
              'colorPaletteYellowForeground1 for the swatch — a real upstream '
              'inconsistency, reproduced',
        );
      },
    );

    test('the line dot radii come in three values', () {
      final style = resolveFluentVerticalBarChartStyle(theme);
      expect(
        style.lineDotRadius!.resolve(<WidgetState>{WidgetState.hovered}),
        8.0,
        reason: 'VerticalBarChart.tsx:278 uses r 8 for the active x',
      );
      expect(
        style.lineDotRadius!.resolve(states),
        0.3,
        reason:
            'VerticalBarChart.tsx:282 keeps r 0.3 so the dot stays focusable',
      );
    });

    test('the rounded-corner radius is 3 and the dim opacity 0.1', () {
      final style = resolveFluentVerticalBarChartStyle(theme);
      expect(
        style.barCornerRadius!.resolve(states),
        3.0,
        reason: 'rx = 3 when roundCorners, VerticalBarChart.tsx:684',
      );
      expect(
        style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled}),
        0.1,
        reason: 'VerticalBarChart.tsx:683 dims to 0.1',
      );
    });

    test('merge lets the other style win field by field', () {
      final base = resolveFluentVerticalBarChartStyle(theme);
      final merged = base.merge(
        FluentVerticalBarChartStyle.from(barCornerRadius: 0),
      );
      expect(
        merged.barCornerRadius!.resolve(states),
        0.0,
        reason: 'roundCorners off is rx = 0, and merge must let it through',
      );
      expect(
        merged.lineStrokeWidth!.resolve(states),
        base.lineStrokeWidth!.resolve(states),
        reason: 'a null slot in the overlay keeps the derived default',
      );
      expect(
        base.copyWith(barCornerRadius: merged.barCornerRadius),
        merged,
        reason: 'copyWith and merge agree, so == and hashCode are structural',
      );
    });
  });

  group('FluentVerticalBarChartStyle against oracle B', () {
    // The label gaps and the minimum labelled bar width are the only style
    // slots the corpus paints: every VerticalBarChart story overrides the
    // series colours per point, so no capture exercises the default ramp.
    test(
      'bar labels sit 6 above a positive bar and 12 below a negative one',
      () {
        final style = resolveFluentVerticalBarChartStyle(theme);
        final above = style.barLabelGapAbove!.resolve(states)!;
        final below = style.barLabelGapBelow!.resolve(states)!;
        var positives = 0;
        var negatives = 0;
        for (final storyId in <String>[
          'charts-verticalbarchart--vertical-bar-default',
          'charts-verticalbarchart--vertical-bar-negative',
        ]) {
          final story = loadOracleStory(storyId);
          // Both stories draw 8 bars; the negative one also draws two wide
          // tooltip backgrounds, which the width filter drops.
          final bars = story
              .byTag('rect')
              .where((rect) => rect.width == 16)
              .toList();
          expect(
            bars.length,
            8,
            reason: '$storyId must contribute 8 bars, not an empty selection',
          );
          for (final bar in bars) {
            final group = story.parentOf(bar)!;
            final labels = story
                .childrenOf(group)
                .where((child) => child.tag == 'text')
                .toList();
            expect(
              labels.length,
              1,
              reason: '$storyId: each bar group holds exactly one bar label',
            );
            final label = labels.single;
            if (label.y! < bar.y!) {
              positives++;
              expect(
                bar.y! - label.y!,
                closeTo(above, kOracleGeometryTolerance),
                reason:
                    '$storyId: VerticalBarChart.tsx:965 places a positive '
                    "bar's label at yPoint - 6",
              );
            } else {
              negatives++;
              expect(
                label.y! - (bar.y! + bar.height!),
                closeTo(below, kOracleGeometryTolerance),
                reason:
                    '$storyId: VerticalBarChart.tsx:965 places a negative '
                    "bar's label at yPoint + 12, yPoint being the bar's foot",
              );
            }
          }
        }
        expect(
          positives,
          12,
          reason: 'both gaps must be measured, not just the positive one',
        );
        expect(
          negatives,
          4,
          reason: 'the negative story contributes four downward labels',
        );
      },
    );

    test('a bar narrower than the minimum carries no label at all', () {
      final style = resolveFluentVerticalBarChartStyle(theme);
      final minimum = style.minBarLabelWidth!.resolve(states)!;
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-dynamic',
      );
      final bars = story.byTag('rect');
      expect(bars.length, 5, reason: 'the dynamic story draws five bars');
      for (final bar in bars) {
        expect(
          bar.width,
          lessThan(minimum),
          reason: 'every dynamic-story bar is 4 wide, under the 16 threshold',
        );
      }
      final labelStyle = style.barLabelStyle!.resolve(states)!;
      expect(
        story
            .byTag('text')
            .where((text) => text.fontSize == labelStyle.fontSize)
            .toList(),
        isEmpty,
        reason:
            'VerticalBarChart.tsx:950 returns null below _barWidth 16, so no '
            'caption1Strong text is painted — only 10px axis ticks',
      );
    });

    test('the bar label is caption1Strong at colorNeutralForeground1', () {
      final labelStyle = resolveFluentVerticalBarChartStyle(
        theme,
      ).barLabelStyle!.resolve(states)!;
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-default',
      );
      final labels = story
          .byTag('text')
          .where((text) => text.fontSize == 12)
          .toList();
      expect(
        labels.length,
        8,
        reason: 'the default story labels all eight of its bars',
      );
      expect(
        labelStyle.fontSize,
        12.0,
        reason: 'the captured bar labels render at 12px (caption1Strong)',
      );
      expect(
        labelStyle.fontWeight,
        theme.typography.caption1Strong.fontWeight,
        reason: 'the captured bar labels render at font-weight 600',
      );
      expect(
        labels.first.fontWeight,
        '600',
        reason: 'guards the line above against a stale capture',
      );
      expect(
        labelStyle.color!.toARGB32(),
        labels.first.fill!.toARGB32(),
        reason:
            'Common.styles.ts:64-70 fills the label with '
            'colorNeutralForeground1, captured as rgb(36, 36, 36)',
      );
    });
  });
}
