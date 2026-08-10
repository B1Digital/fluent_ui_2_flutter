import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/line_chart_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Resolves [property] in the states given, as a painter would.
T? _resolve<T>(WidgetStateProperty<T?>? property, Set<WidgetState> states) =>
    property?.resolve(states);

void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  final style = resolveFluentLineChartStyle(theme);
  const selected = <WidgetState>{WidgetState.selected};
  const none = <WidgetState>{};

  group('resolveFluentLineChartStyle scalars', () {
    test('carries the LineChart.tsx literals', () {
      expect(
        _resolve(style.strokeWidth, none),
        4,
        reason: 'DEFAULT_LINE_STROKE_SIZE, LineChart.tsx:71',
      );
      expect(
        _resolve(style.markerStrokeWidthEngineB, none),
        1,
        reason: 'the large-dataset marker stroke, LineChart.tsx:803',
      );
      expect(
        _resolve(style.staticHighlightRadius, none),
        5.5,
        reason: 'the static highlight circle r, LineChart.tsx:758',
      );
      expect(
        _resolve(style.latchRadius, none),
        8,
        reason: 'the hover latch circle r, LineChart.tsx:1165',
      );
      expect(
        _resolve(style.markerLabelGap, none),
        12,
        reason: 'the marker label offset below the radius, LineChart.tsx:929',
      );
      expect(
        _resolve(style.hoverLineTailOffset, none),
        5,
        reason: 'y2 = lineHeight - 5 - yScale(y), LineChart.tsx:1674',
      );
      expect(
        _resolve(style.fillBarYPadding, none),
        3,
        reason: 'FILL_Y_PADDING, LineChart.tsx:1381',
      );
      expect(
        _resolve(style.stripeTileSize, none),
        16,
        reason: 'the pattern tile is 16 by 16, LineChart.tsx:1422-1423',
      );
      expect(
        _resolve(style.stripeStrokeWidth, none),
        1.25,
        reason: 'the stripe stroke, LineChart.tsx:1427',
      );
      expect(
        _resolve(style.eventLabelHeight, none),
        36,
        reason: 'eventLabelHeight, LineChart.tsx:165',
      );
      expect(
        kFluentLineFillBarPatternedOpacity,
        1,
        reason: 'a patterned colour fill bar, LineChart.tsx:1829',
      );
    });

    test('the hover line is the literal #323130, not a token', () {
      expect(
        _resolve(style.hoverLineColor, none),
        const Color(0xFF323130),
        reason:
            'LineChart.tsx:1940 hard-codes the hex, so the hover line does '
            'not follow the theme',
      );
      expect(
        _resolve(style.hoverLineDashPattern, none),
        <double>[5, 5],
        reason: "strokeDasharray='5,5', LineChart.tsx:1943",
      );
    });

    test('the line border falls back to colorNeutralBackground1', () {
      expect(
        _resolve(style.lineBorderColor, none),
        theme.colors.neutralBackground1,
        reason: 'LineChart.tsx:712',
      );
    });
  });

  group('resolveFluentLineChartStyle selection states', () {
    test('an unselected line, marker and fill bar are dimmed', () {
      expect(
        _resolve(style.lineOpacity, selected),
        1,
        reason: 'LineChart.tsx:1293-1306',
      );
      expect(
        _resolve(style.lineOpacity, none),
        0.1,
        reason: 'LineChart.tsx:1307',
      );
      expect(
        _resolve(style.pointOpacity, selected),
        1,
        reason: 'LineChart.tsx:909',
      );
      expect(
        _resolve(style.pointOpacity, none),
        0.01,
        reason:
            'LineChart.tsx:909 dims to 0.01 rather than 0 so the marker keeps '
            'its hit area and accessible name',
      );
      expect(
        _resolve(style.fillBarOpacity, selected),
        0.4,
        reason: 'a plain, undimmed colour fill bar, LineChart.tsx:1829',
      );
      expect(
        _resolve(style.fillBarOpacity, none),
        0.1,
        reason: 'LineChart.tsx:1398',
      );
    });
  });

  group('FluentLineChartStyle template members', () {
    test('merge layers only the non-null properties of the argument', () {
      final merged = style.merge(FluentLineChartStyle.from(strokeWidth: 7));
      expect(
        _resolve(merged.strokeWidth, none),
        7,
        reason: 'the override wins',
      );
      expect(
        _resolve(merged.latchRadius, none),
        8,
        reason: 'an omitted property inherits',
      );
      expect(
        style.merge(null),
        same(style),
        reason: 'merging nothing allocates nothing',
      );
    });

    test('copyWith replaces exactly the named property', () {
      final copy = style.copyWith(
        eventLabelHeight: const WidgetStatePropertyAll<double?>(48),
      );
      expect(_resolve(copy.eventLabelHeight, none), 48, reason: 'replaced');
      expect(
        copy.stripeTileSize,
        style.stripeTileSize,
        reason: 'every other property is shared, not rebuilt',
      );
    });

    test('equal field sets compare and hash equal', () {
      final other = resolveFluentLineChartStyle(theme);
      expect(other, style, reason: 'the same theme resolves the same style');
      expect(
        other.hashCode,
        style.hashCode,
        reason: 'hashCode must agree with ==',
      );
      expect(
        style.copyWith(latchRadius: const WidgetStatePropertyAll<double?>(9)),
        isNot(style),
        reason: 'one changed field breaks equality',
      );
    });
  });
}
