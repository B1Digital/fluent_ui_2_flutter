import 'package:fluent_2/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2/src/charts/sankey_chart_style.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `useSankeyChartStyles.styles.ts:31-43` plus the inline presentation
/// attributes at `SankeyChart.tsx:764`, `:817` and `:826-856`.
void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  test('the resolved style matches the upstream stylesheet', () {
    final style = resolveFluentSankeyChartStyle(theme);
    const states = <WidgetState>{};
    expect(
      style.linkFillColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralBackground1.toARGB32(),
      reason:
          'useSankeyChartStyles.styles.ts:32 — the stream fill comes from the '
          "parent group's CSS because _fillStreamColors returns undefined",
    );
    expect(
      style.linkStrokeWidth!.resolve(states),
      2,
      reason:
          'SankeyChart.tsx:764 — the presentation attribute beats the 3px '
          'class at useSankeyChartStyles.styles.ts:33',
    );
    expect(
      style.nodeStrokeWidth!.resolve(states),
      2,
      reason: 'SankeyChart.tsx:817',
    );
    expect(
      style.nonSelectedColor!.resolve(states)!.toARGB32(),
      0xFF757575,
      reason: 'SankeyChart.tsx:40',
    );
    expect(
      style.nodeTextColor!.resolve(states)!.toARGB32(),
      0xFFFFFFFF,
      reason: 'SankeyChart.tsx:61 — the default and selected states draw white',
    );
    expect(
      style.nonSelectedNodeTextColor!.resolve(states)!.toARGB32(),
      0xFF323130,
      reason: 'SankeyChart.tsx:60 — grey text on the greyed-out nodes',
    );
    expect(
      style.nameTextStyle!.resolve(states)!.fontSize,
      10,
      reason: 'SankeyChart.tsx:836',
    );
    expect(
      style.nameTextStyle!.resolve(states)!.fontWeight,
      FontWeight.normal,
      reason:
          'SankeyChart.tsx:833 sets fontWeight="regular", which is not a valid '
          'CSS keyword and resolves to normal',
    );
    expect(
      style.weightTextStyle!.resolve(states)!.fontSize,
      14,
      reason: 'SankeyChart.tsx:853',
    );
    expect(
      style.weightTextStyle!.resolve(states)!.fontWeight,
      FontWeight.bold,
      reason: 'SankeyChart.tsx:850',
    );
    expect(
      style.weightMeasurementTextStyle!.resolve(states)!.fontWeight,
      FontWeight.normal,
      reason:
          'SankeyChart.tsx:622 measures the weight with no font override, so it '
          'inherits body1 at regular weight — parity with the measurement bug',
    );
    expect(
      style.titleTextStyle!.resolve(states),
      FluentChartTextStyles.of(theme).chartTitle,
      reason:
          'useSankeyChartStyles.styles.ts:63 assigns getChartTitleStyles(), '
          'which is utilities/Common.styles.ts:83-91',
    );
    expect(
      style.titleBackgroundColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralBackground1.toARGB32(),
      reason:
          'useSankeyChartStyles.styles.ts:64-65 — the svgTooltip slot handed '
          "to ChartTitle at SankeyChart.tsx:1166 fills the truncated title's "
          'backing rectangle',
    );
    expect(
      style.tooltipTextStyle!.resolve(states),
      FluentChartTextStyles.of(theme).tooltip,
      reason:
          'useSankeyChartStyles.styles.ts:44 assigns getTooltipStyle(), which '
          'spreads body1 at utilities/Common.styles.ts:38',
    );
    expect(
      style.tooltipBackgroundColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralBackground1.toARGB32(),
      reason: 'utilities/Common.styles.ts:44',
    );
  });

  test('merge layers only the non-null properties of the override', () {
    final base = resolveFluentSankeyChartStyle(theme);
    final merged = base.merge(
      const FluentSankeyChartStyle(
        nodeStrokeWidth: WidgetStatePropertyAll<double?>(5),
      ),
    );
    expect(
      merged.nodeStrokeWidth!.resolve(const <WidgetState>{}),
      5,
      reason: 'the override wins',
    );
    expect(
      merged.linkStrokeWidth!.resolve(const <WidgetState>{}),
      2,
      reason: 'the rest survives',
    );
  });

  test('copyWith replaces only what it is given', () {
    final copied = resolveFluentSankeyChartStyle(theme).copyWith(
      nonSelectedColor: const WidgetStatePropertyAll<Color?>(Color(0xFF102030)),
    );
    expect(
      copied.nonSelectedColor!.resolve(const <WidgetState>{})!.toARGB32(),
      0xFF102030,
      reason: 'the named property is replaced',
    );
    expect(
      copied.nodeStrokeWidth!.resolve(const <WidgetState>{}),
      2,
      reason: 'every other property is carried over',
    );
  });

  test('equal styles compare equal and hash equal', () {
    expect(
      resolveFluentSankeyChartStyle(theme),
      resolveFluentSankeyChartStyle(theme),
      reason: 'the resolver is deterministic',
    );
    expect(
      resolveFluentSankeyChartStyle(theme).hashCode,
      resolveFluentSankeyChartStyle(theme).hashCode,
      reason: 'hashCode agrees with ==',
    );
  });

  testWidgets('the theme is found from a descendant context', (tester) async {
    FluentSankeyChartStyle? found;
    await tester.pumpWidget(
      FluentApp(
        theme: theme,
        home: FluentSankeyChartTheme(
          style: const FluentSankeyChartStyle(
            nodeStrokeWidth: WidgetStatePropertyAll<double?>(4),
          ),
          child: Builder(
            builder: (context) {
              found = FluentSankeyChartTheme.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(
      found!.nodeStrokeWidth!.resolve(const <WidgetState>{}),
      4,
      reason: 'FluentSankeyChartTheme.maybeOf reaches the nearest ancestor',
    );
  });
}
