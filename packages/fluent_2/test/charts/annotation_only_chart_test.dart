import 'package:fluent_2/src/charts/annotation_only_chart.dart';
import 'package:fluent_2/src/charts/annotation_only_chart_style.dart';
import 'package:fluent_2/src/charts/chrome/annotation_layer.dart';
import 'package:fluent_2/src/charts/model/chart_annotation.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The chart is a shell around `FluentChartAnnotationLayer`; what has to be
/// asserted here is the shell's own contract — the sizing fallbacks, the
/// margin-to-padding conversion, the label rules, and the fact that the
/// context supplies no scales so every data-space annotation is dropped.
///
/// There is no Oracle B corpus for this component: it is absent from the
/// storybook sidebar, so no story was ever captured
/// (`test/fixtures/charts/oracle_b/` has no `charts-annotationonlychart-*`).
/// Every number below is therefore cited to `AnnotationOnlyChart.tsx`.
void main() {
  const key = Key('annotations');
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  /// The default 800 x 600 surface is shorter than the chart's own 650 default,
  /// which would clamp the box under test; `Align` loosens the route's tight
  /// constraints so the shell picks its own size the way it does in a page.
  Future<void> pump(WidgetTester tester, Widget chart) {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      FluentApp(
        theme: theme,
        home: Align(alignment: Alignment.topLeft, child: chart),
      ),
    );
  }

  const relative = FluentChartAnnotation(
    text: 'Relative',
    coordinates: FluentRelativeCoordinate(x: 0.5, y: 0.5),
  );

  testWidgets('with no height the shell is 650 tall', (tester) async {
    await pump(
      tester,
      const FluentAnnotationOnlyChart(
        key: key,
        annotations: <FluentChartAnnotation>[relative],
      ),
    );
    expect(
      tester.getSize(find.byKey(key)).height,
      650.0,
      reason:
          'AnnotationOnlyChart.tsx:11 and :92 — DEFAULT_HEIGHT, applied '
          'through max(height ?? 650, 1).',
    );
  });

  testWidgets('a height of zero is clamped to one', (tester) async {
    await pump(
      tester,
      const FluentAnnotationOnlyChart(
        key: key,
        height: 0,
        annotations: <FluentChartAnnotation>[relative],
      ),
    );
    expect(
      tester.getSize(find.byKey(key)).height,
      1.0,
      reason: 'AnnotationOnlyChart.tsx:92 is Math.max(height ?? 650, 1).',
    );
  });

  testWidgets('unbounded width falls back to 400', (tester) async {
    await tester.pumpWidget(
      FluentApp(
        theme: theme,
        home: const Align(
          alignment: Alignment.topLeft,
          // A `Row` hands its non-flex children unbounded width, which is the
          // only way a Flutter shell reaches the unmeasured branch.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FluentAnnotationOnlyChart(
                key: key,
                height: 200,
                annotations: <FluentChartAnnotation>[relative],
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(key)).width,
      400.0,
      reason:
          'AnnotationOnlyChart.tsx:12 and :91 — FALLBACK_WIDTH stands in when '
          'nothing measured a width, which in Flutter is the unbounded case.',
    );
  });

  testWidgets('a margin becomes padding on all four sides', (tester) async {
    await pump(
      tester,
      const FluentAnnotationOnlyChart(
        key: key,
        width: 400,
        height: 200,
        margin: FluentChartMargins(top: 10, right: 20, bottom: 30, left: 40),
        annotations: <FluentChartAnnotation>[relative],
      ),
    );
    final padding = tester.widget<Padding>(
      find
          .descendant(of: find.byKey(key), matching: find.byType(Padding))
          .first,
    );
    expect(
      padding.padding,
      const EdgeInsets.fromLTRB(40, 10, 20, 30),
      reason:
          'AnnotationOnlyChart.tsx:14-29 emits '
          '`\${t}px \${r}px \${b}px \${l}px`, which is the CSS top-right-'
          'bottom-left order.',
    );
  });

  testWidgets('an all-zero margin produces no padding at all', (tester) async {
    await pump(
      tester,
      const FluentAnnotationOnlyChart(
        key: key,
        width: 400,
        height: 200,
        margin: FluentChartMargins(top: 0, right: 0, bottom: 0, left: 0),
        annotations: <FluentChartAnnotation>[relative],
      ),
    );
    expect(
      tester
          .widget<Padding>(
            find
                .descendant(of: find.byKey(key), matching: find.byType(Padding))
                .first,
          )
          .padding,
      EdgeInsets.zero,
      reason:
          'AnnotationOnlyChart.tsx:24-26 returns undefined for an all-zero '
          'margin, so no padding declaration is emitted.',
    );
  });

  testWidgets('description wins over chartTitle for the accessible name', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentAnnotationOnlyChart(
        key: key,
        chartTitle: 'Title',
        description: 'Description',
        annotations: <FluentChartAnnotation>[relative],
      ),
    );
    expect(
      tester.getSemantics(find.byKey(key)).label,
      'Description',
      reason: 'AnnotationOnlyChart.tsx:169 is `description ?? chartTitle`.',
    );
  });

  testWidgets('with no annotations there is no accessible name', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentAnnotationOnlyChart(
        key: key,
        chartTitle: 'Title',
        description: 'Description',
        annotations: <FluentChartAnnotation>[],
      ),
    );
    expect(
      tester.getSemantics(find.byKey(key)).label,
      isEmpty,
      reason:
          'AnnotationOnlyChart.tsx:169 gates the label on hasAnnotations, '
          'and :178-179 omits both role and aria-label without it.',
    );
  });

  testWidgets('the title is present but hidden from assistive technology', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentAnnotationOnlyChart(
        key: key,
        chartTitle: 'Title',
        annotations: <FluentChartAnnotation>[relative],
      ),
    );
    expect(
      find.text('Title'),
      findsOneWidget,
      reason: 'AnnotationOnlyChart.tsx:189-193 renders the title span.',
    );
    expect(
      tester.getSemantics(find.text('Title')).label,
      isEmpty,
      reason: 'AnnotationOnlyChart.tsx:190 marks it aria-hidden="true".',
    );
  });

  testWidgets('a data-space annotation is dropped for want of scales', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentAnnotationOnlyChart(
        key: key,
        annotations: <FluentChartAnnotation>[
          FluentChartAnnotation(
            text: 'Dropped',
            coordinates: FluentDataCoordinate(
              x: 5,
              y: 5,
              yAxis: FluentAnnotationYAxis.primary,
            ),
          ),
        ],
      ),
    );
    expect(
      find.text('Dropped'),
      findsNothing,
      reason:
          'AnnotationOnlyChart.tsx:139-143 supplies no xScale or yScale, '
          'so resolveDataCoordinate returns undefined '
          '(ChartAnnotationLayer.tsx:261-282) and the annotation is skipped '
          'silently at :474-477.',
    );
  });

  testWidgets('the layer receives a plot rect matching the resolved size', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentAnnotationOnlyChart(
        key: key,
        width: 400,
        height: 650,
        annotations: <FluentChartAnnotation>[relative],
      ),
    );
    final layer = tester.widget<FluentChartAnnotationLayer>(
      find.byType(FluentChartAnnotationLayer),
    );
    expect(
      layer.context.plotRect,
      const Rect.fromLTWH(0, 0, 400, 650),
      reason:
          'AnnotationOnlyChart.tsx:140 is '
          '{x: 0, y: 0, width: resolvedWidth, height: resolvedHeight}.',
    );
  });

  testWidgets('the widget style beats a nearer theme', (tester) async {
    const nearer = Color(0xFF102030);
    const own = Color(0xFF405060);
    await pump(
      tester,
      FluentAnnotationOnlyChartTheme(
        style: FluentAnnotationOnlyChartStyle.from(
          paperBackgroundColor: nearer,
        ),
        child: FluentAnnotationOnlyChart(
          key: key,
          width: 400,
          height: 200,
          style: FluentAnnotationOnlyChartStyle.from(paperBackgroundColor: own),
          annotations: const <FluentChartAnnotation>[relative],
        ),
      ),
    );
    expect(
      tester
          .widget<ColoredBox>(
            find
                .descendant(
                  of: find.byKey(key),
                  matching: find.byType(ColoredBox),
                )
                .first,
          )
          .color,
      own,
      reason:
          'The house precedence is derived < FluentXTheme < widget style, and '
          'this chart is the first shell to layer all three.',
    );
  });
}
