import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/polar_chart_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `usePolarChartStyles.styles.ts:36-53` is four rules: a base grid line, an
/// inner and an outer opacity, and the caption2Strong tick label.
void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  test('module constants come from PolarChart.tsx:38-45', () {
    expect(kPolarLabelWidth, 36, reason: 'PolarChart.tsx:39');
    expect(kPolarLabelHeight, 16, reason: 'PolarChart.tsx:40');
    expect(kPolarLabelOffset, 10, reason: 'PolarChart.tsx:41');
    expect(kPolarTickSize, 6, reason: 'PolarChart.tsx:42');
    expect(kPolarLegendHeight, 32, reason: 'PolarChart.tsx:38');
    expect(
      kPolarDefaultSize,
      200,
      reason: 'PolarChart.tsx:54-55 initialises both container axes to 200',
    );
  });

  test('the resolved style matches the upstream stylesheet', () {
    final style = resolveFluentPolarChartStyle(theme);
    const states = <WidgetState>{};
    expect(
      style.gridLineColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralForeground1.toARGB32(),
      reason: 'usePolarChartStyles.styles.ts:38',
    );
    expect(
      style.gridLineWidth!.resolve(states),
      1,
      reason: 'usePolarChartStyles.styles.ts:39 — strokeWidth 1px',
    );
    expect(
      style.gridLineInnerOpacity!.resolve(states),
      0.2,
      reason: 'usePolarChartStyles.styles.ts:43',
    );
    expect(
      style.gridLineOuterOpacity!.resolve(states),
      1,
      reason: 'usePolarChartStyles.styles.ts:47',
    );
    expect(
      style.areaFillOpacity!.resolve(states),
      0.7,
      reason: 'PolarChart.tsx:457 — the highlighted area fill opacity',
    );
    expect(
      style.dimmedOpacity!.resolve(states),
      0.1,
      reason: 'PolarChart.tsx:457, :480, :566 all dim to 0.1',
    );
    expect(
      style.lineStrokeWidth!.resolve(states),
      3,
      reason: 'PolarChart.tsx:481 — strokeWidth defaults to 3',
    );
    expect(
      style.activeMarkerFill!.resolve(states)!.toARGB32(),
      theme.colors.neutralBackground1.toARGB32(),
      reason: 'PolarChart.tsx:563 inverts the active marker fill',
    );
    expect(
      style.activeMarkerStrokeWidth!.resolve(states),
      2,
      reason: 'PolarChart.tsx:565',
    );
    expect(
      style.minMarkerRadius!.resolve(states),
      2,
      reason: 'PolarChart.tsx:43 — MIN_MARKER_SIZE_PX',
    );
    expect(
      style.minMarkerRadiusMarkersOnly!.resolve(states),
      4,
      reason: 'PolarChart.tsx:45 — MIN_MARKER_SIZE_PX_MARKERS_ONLY',
    );
    expect(
      style.maxMarkerRadius!.resolve(states),
      16,
      reason: 'PolarChart.tsx:44 — MAX_MARKER_SIZE_PX',
    );
    expect(
      style.tickSize!.resolve(states),
      kPolarTickSize,
      reason: 'PolarChart.tsx:42 — TICK_SIZE',
    );
    expect(
      style.labelOffset!.resolve(states),
      kPolarLabelOffset,
      reason: 'PolarChart.tsx:41 — LABEL_OFFSET',
    );
    expect(
      style.tickLabelStyle!.resolve(states)!.fontSize,
      10,
      reason:
          'usePolarChartStyles.styles.ts:51 — caption2Strong is 10/14 semibold',
    );
  });

  test('merge layers only the non-null properties of the override', () {
    final base = resolveFluentPolarChartStyle(theme);
    final merged = base.merge(
      const FluentPolarChartStyle(
        lineStrokeWidth: WidgetStatePropertyAll<double?>(7),
      ),
    );
    expect(
      merged.lineStrokeWidth!.resolve(const <WidgetState>{}),
      7,
      reason: 'the override wins for the property it sets',
    );
    expect(
      merged.dimmedOpacity!.resolve(const <WidgetState>{}),
      0.1,
      reason: 'every other resolved property survives the merge',
    );
  });

  test('copyWith replaces one property and keeps the rest', () {
    final copy = resolveFluentPolarChartStyle(
      theme,
    ).copyWith(maxMarkerRadius: const WidgetStatePropertyAll<double?>(20));
    expect(
      copy.maxMarkerRadius!.resolve(const <WidgetState>{}),
      20,
      reason: 'copyWith replaces the property it is given',
    );
    expect(
      copy.minMarkerRadius!.resolve(const <WidgetState>{}),
      2,
      reason: 'copyWith keeps every other property',
    );
  });

  test('equal styles compare equal and hash equal', () {
    final a = resolveFluentPolarChartStyle(theme);
    final b = resolveFluentPolarChartStyle(theme);
    expect(a, b, reason: 'the resolver is deterministic for one theme');
    expect(a.hashCode, b.hashCode, reason: 'hashCode agrees with ==');
  });

  testWidgets('the theme is found from a descendant context', (tester) async {
    FluentPolarChartStyle? found;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FluentPolarChartTheme(
          style: FluentPolarChartStyle.from(lineStrokeWidth: 9),
          child: Builder(
            builder: (context) {
              found = FluentPolarChartTheme.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(
      found!.lineStrokeWidth!.resolve(const <WidgetState>{}),
      9,
      reason: 'FluentPolarChartTheme.maybeOf reaches the nearest ancestor',
    );
  });
}
