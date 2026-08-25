/// The primary y axis's tick labels, as the shell actually paints them.
///
/// `CartesianChart.tsx:396-406` runs `createYAxisLabels` over `yScalePrimary`
/// whenever `props.showYAxisLablesTooltip` is set, and `:150-160` sizes the left
/// margin off the *truncated* text. A port that reserves the truncated width and
/// then paints the full label puts its y labels outside the chart, so these
/// tests read the painted origins rather than the helper's return value.
library;

import 'dart:ui' as ui;

import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_painter.dart';
import 'package:fluent_2/src/charts/horizontal_bar_chart_with_axis.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// One `drawParagraph`, with the translation in force when it was issued.
typedef _PaintedText = ({Offset origin, Offset translation, double width});

/// Records every paragraph the painter draws together with the accumulated
/// translation, so a label can be attributed to the axis group that emitted it.
///
/// [FluentCartesianChartPainter] wraps each axis in `save`/`translate`/`restore`
/// (`cartesian_painter.dart:195-216`), which is the analogue of upstream's
/// `<g transform="translate(...)">` axis groups (`CartesianChart.tsx:762`,
/// `:836`), so the active translation identifies the group.
class _RecordingCanvas implements Canvas {
  final List<_PaintedText> texts = <_PaintedText>[];

  Offset _translation = Offset.zero;
  final List<Offset> _stack = <Offset>[];

  @override
  void save() => _stack.add(_translation);

  @override
  void restore() {
    if (_stack.isNotEmpty) {
      _translation = _stack.removeLast();
    }
  }

  @override
  void translate(double dx, double dy) => _translation += Offset(dx, dy);

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) => texts.add((
    origin: offset,
    translation: _translation,
    // `longestLine` is the inked advance width of the widest line, which is
    // zero for an empty paragraph and grows with every kept character.
    width: paragraph.longestLine,
  ));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  /// Long enough that four characters plus an ellipsis is a visible cut.
  const categories = <String>[
    'Alpha Category One',
    'Beta Category Two',
    'Gamma Category Three',
  ];

  Future<void> pump(
    WidgetTester tester, {
    required bool showYAxisLablesTooltip,
  }) => tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(
        child: SizedBox(
          width: 800,
          height: 350,
          child: FluentHorizontalBarChartWithAxis(
            data: <FluentHorizontalBarChartWithAxisDataPoint>[
              for (final category in categories)
                // 10 is an arbitrary non-zero bar length; no assertion here
                // reads it.
                FluentHorizontalBarChartWithAxisDataPoint(x: 10, y: category),
            ],
            props: FluentCartesianChartProps(
              showYAxisLables: true,
              showYAxisLablesTooltip: showYAxisLablesTooltip,
              // 4 is the default `noOfCharsToTruncate` upstream falls back to at
              // CartesianChart.tsx:403.
              noOfCharsToTruncate: 4,
            ),
          ),
        ),
      ),
    ),
  );

  /// Replays the mounted chart's painter onto [_RecordingCanvas] and returns the
  /// paragraphs the primary y-axis group emitted.
  List<_PaintedText> yAxisTexts(WidgetTester tester) {
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((c) => c.painter)
        .whereType<FluentCartesianChartPainter>()
        .single;
    final canvas = _RecordingCanvas();
    painter.paint(canvas, painter.layout.size);
    final group = Offset(painter.layout.yAxisTranslateX, 0);
    return <_PaintedText>[
      for (final text in canvas.texts)
        if (text.translation == group) text,
    ];
  }

  testWidgets('showYAxisLablesTooltip paints its y labels inside the chart', (
    tester,
  ) async {
    await pump(tester, showYAxisLablesTooltip: true);
    final texts = yAxisTexts(tester);
    expect(
      texts,
      hasLength(categories.length),
      reason: 'one paragraph per band tick of the primary y axis',
    );
    for (final text in texts) {
      expect(
        text.translation.dx + text.origin.dx,
        greaterThanOrEqualTo(0),
        // 0 is the chart's own left edge.
        reason:
            'CartesianChart.tsx:150-160 sizes the left margin from '
            'truncateString(label, noOfCharsToTruncate), so a label painted '
            'untruncated runs off the left edge of the chart',
      );
    }
  });

  testWidgets('showYAxisLablesTooltip narrows the painted y labels', (
    tester,
  ) async {
    await pump(tester, showYAxisLablesTooltip: false);
    final full = <double>[for (final text in yAxisTexts(tester)) text.width];
    await pump(tester, showYAxisLablesTooltip: true);
    final truncated = <double>[
      for (final text in yAxisTexts(tester)) text.width,
    ];
    expect(
      truncated,
      hasLength(full.length),
      reason: 'the tick count does not change with the flag',
    );
    for (final (i, width) in truncated.indexed) {
      expect(
        width,
        lessThan(full[i]),
        reason:
            'utilities.ts:1227 cuts "${categories[i]}" to four characters plus '
            'an ellipsis, so the painted advance width must shrink',
      );
    }
  });

  testWidgets('a chart without the tooltip flag still paints y label text', (
    tester,
  ) async {
    await pump(tester, showYAxisLablesTooltip: false);
    for (final text in yAxisTexts(tester)) {
      expect(
        text.width,
        greaterThan(0),
        // 0 is the advance width of an empty paragraph.
        reason:
            'utilities.ts:1226-1228 sets the tspan text only inside the '
            'truncateLabel branch, so reproducing it literally would blank the '
            'y axis — spec section 5.2, exception 2 fixes that instead',
      );
    }
  });
}
