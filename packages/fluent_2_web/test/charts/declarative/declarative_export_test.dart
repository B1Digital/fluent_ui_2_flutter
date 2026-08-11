import 'dart:typed_data';

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/declarative_chart.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `DeclarativeChart.tsx:433-473` — the imperative export handle, exercised on a
/// MOUNTED widget rather than on the controller alone, because the controller
/// with nothing attached is exactly the failure the second test pins.
///
/// There is no captured DeclarativeChart export in Oracle B, so nothing here
/// asserts on pixels. What is checkable without one is the branch structure:
/// bytes come back at all, the caller's scale beats the resolved default, and a
/// two-cell figure exports through the same path as a one-cell figure.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: SizedBox(width: 700, height: 400, child: child)),
    ),
  );

  /// Runs the export outside the fake-async zone.
  ///
  /// `RenderRepaintBoundary.toImage` and `Image.toByteData` are serviced by the
  /// engine's task runner, which the widget tester's fake clock never pumps
  /// (`internal/image_export.dart` states the same constraint on
  /// `FluentChartImageExporter.toImage`).
  Future<Uint8List> exportOf(
    WidgetTester tester,
    FluentDeclarativeChartController controller, [
    FluentChartImageExportOptions? options,
  ]) async {
    final bytes = await tester.runAsync(
      () => controller.exportAsImage(options: options),
    );
    expect(bytes, isNotNull, reason: 'runAsync only returns null on failure');
    return bytes!;
  }

  const singlePlot = FluentPlotlySchema(
    plotlySchema: <String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>['a'],
          'y': <Object?>[1],
        },
      ],
    },
  );

  testWidgets('a single-plot figure exports as a png', (tester) async {
    final controller = FluentDeclarativeChartController();
    addTearDown(controller.dispose);
    await pump(
      tester,
      FluentDeclarativeChart(controller: controller, chartSchema: singlePlot),
    );
    final bytes = await exportOf(tester, controller);
    expect(
      bytes.isNotEmpty,
      isTrue,
      reason:
          'DeclarativeChart.tsx:445-451 exports the one plot; this port reads '
          'it off the same RepaintBoundary the grid is wrapped in.',
    );
    expect(
      bytes.sublist(0, 8),
      // The eight-byte PNG signature, so the assertion above cannot pass on an
      // arbitrary non-empty buffer.
      <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      reason: 'image-export-utils.ts:458 returns png bytes.',
    );
  });

  testWidgets('exporting before the first frame reports the upstream message', (
    tester,
  ) async {
    final controller = FluentDeclarativeChartController();
    addTearDown(controller.dispose);
    await expectLater(
      controller.exportAsImage(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Chart cannot be exported as image'),
        ),
      ),
      reason: 'DeclarativeChart.tsx:447.',
    );
  });

  testWidgets('the caller scale overrides the resolved default', (
    tester,
  ) async {
    final controller = FluentDeclarativeChartController();
    addTearDown(controller.dispose);
    await pump(
      tester,
      FluentDeclarativeChart(controller: controller, chartSchema: singlePlot),
    );
    final small = await exportOf(
      tester,
      controller,
      const FluentChartImageExportOptions(scale: 1),
    );
    final large = await exportOf(
      tester,
      controller,
      const FluentChartImageExportOptions(scale: 3),
    );
    expect(
      large.length,
      greaterThan(small.length),
      reason:
          'DeclarativeChart.tsx:439-443 spreads the caller options after the '
          'defaults, so an explicit scale wins over the fallback of 5.',
    );
  });

  testWidgets('the export survives the controller being swapped out', (
    tester,
  ) async {
    final first = FluentDeclarativeChartController();
    final second = FluentDeclarativeChartController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await pump(
      tester,
      FluentDeclarativeChart(controller: first, chartSchema: singlePlot),
    );
    await pump(
      tester,
      FluentDeclarativeChart(controller: second, chartSchema: singlePlot),
    );
    final bytes = await exportOf(tester, second);
    expect(
      bytes.isNotEmpty,
      isTrue,
      reason:
          'the new controller must have been attached by didUpdateWidget, or '
          'React would have re-run useImperativeHandle for nothing '
          '(DeclarativeChart.tsx:467-473).',
    );
    await expectLater(
      first.exportAsImage(),
      throwsA(isA<StateError>()),
      reason:
          'and the old one must have been detached, or two controllers would '
          'drive one chart.',
    );
  });

  testWidgets('a multi-plot export covers the whole grid and its legend', (
    tester,
  ) async {
    final controller = FluentDeclarativeChartController();
    addTearDown(controller.dispose);
    await pump(
      tester,
      FluentDeclarativeChart(
        controller: controller,
        chartSchema: const FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            'data': <Object?>[
              <String, Object?>{
                'type': 'bar',
                'xaxis': 'x',
                'name': 's1',
                'legendgroup': 'g1',
                'x': <Object?>['a'],
                'y': <Object?>[1],
              },
              <String, Object?>{
                'type': 'bar',
                'xaxis': 'x2',
                'name': 's2',
                'legendgroup': 'g2',
                'x': <Object?>['b'],
                'y': <Object?>[2],
              },
            ],
            'layout': <String, Object?>{
              'xaxis': <String, Object?>{
                'domain': <Object?>[0, 0.45],
                'anchor': 'y',
              },
              'xaxis2': <String, Object?>{
                'domain': <Object?>[0.55, 1],
                'anchor': 'y2',
              },
              'yaxis': <String, Object?>{
                'domain': <Object?>[0, 1],
                'anchor': 'x',
              },
              'yaxis2': <String, Object?>{
                'domain': <Object?>[0, 1],
                'anchor': 'x2',
              },
            },
          },
        ),
      ),
    );
    final bytes = await exportOf(
      tester,
      controller,
      const FluentChartImageExportOptions(scale: 1),
    );
    expect(
      bytes.isNotEmpty,
      isTrue,
      reason:
          'DeclarativeChart.tsx:453-462 composites the sparse cell grid and '
          'appends the legend beneath it; one boundary round the whole Column '
          'captures both at once.',
    );
  });
}
