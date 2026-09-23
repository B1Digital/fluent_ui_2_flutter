import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `DeclarativeChart.tsx:433-473` — the imperative export handle, exercised on a
/// MOUNTED widget rather than on the controller alone, because the controller
/// with nothing attached is exactly the failure the second test pins.
///
/// There is no captured DeclarativeChart export in Oracle B, so nothing here
/// compares against upstream's pixels. What is checkable without one is the
/// branch structure — bytes come back at all, the caller's scale beats the
/// resolved default, a two-cell figure exports through the same path as a
/// one-cell figure — and what the export must contain that the screen does not
/// show: every legend, every table row, and the selection on the strip.
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

  /// The PNG IHDR width and height.
  (int, int) pngSize(Uint8List bytes) {
    int be32(int at) =>
        (bytes[at] << 24) |
        (bytes[at + 1] << 16) |
        (bytes[at + 2] << 8) |
        bytes[at + 3];
    return (be32(16), be32(20));
  }

  Finder boundaryOf() => find
      .descendant(
        of: find.byType(FluentDeclarativeChart),
        matching: find.byType(RepaintBoundary),
      )
      .first;

  testWidgets('a legend collapsed to "+N more" on screen exports every entry', (
    tester,
  ) async {
    final labels = <String>[for (var i = 0; i < 22; i++) 'Series $i'];
    final controller = FluentDeclarativeChartController();
    addTearDown(controller.dispose);
    await pump(
      tester,
      FluentDeclarativeChart(
        controller: controller,
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            'data': <Object?>[
              <String, Object?>{
                'type': 'pie',
                'hole': 0.5,
                'labels': labels,
                'values': <Object?>[for (var i = 0; i < 22; i++) i + 1],
              },
            ],
          },
        ),
      ),
    );
    expect(
      find.byType(FluentMenu),
      findsOneWidget,
      reason: 'the precondition: the live legend is in its overflow form',
    );
    final boundaryTop = tester.getTopLeft(boundaryOf()).dy;
    final width = tester.getSize(boundaryOf()).width;
    final legendTop =
        tester.getTopLeft(find.byType(FluentChartLegend)).dy - boundaryTop;
    final strip = FluentSynthesisedLegendLayout.compute(
      legends: <FluentChartLegendItem>[
        for (final label in labels)
          FluentChartLegendItem(title: label, color: const Color(0xFF000000)),
      ],
      svgWidth: width,
      measurer: FluentChartTextMeasurer(),
      textStyle: resolveFluentChartLegendStyle(
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      ).labelTextStyle!.resolve(<WidgetState>{})!,
    );
    expect(
      strip.size.height,
      greaterThan(kLegendContainerMarginTop + kLegendHeight),
      reason: 'all 22 do not fit one line, so the full strip wraps',
    );
    final bytes = await exportOf(
      tester,
      controller,
      const FluentChartImageExportOptions(scale: 1),
    );
    expect(
      pngSize(bytes),
      (width.toInt(), (legendTop + strip.size.height).toInt()),
      reason:
          'hooks.ts:30-37 — the chart svg without its live legend, then '
          'cloneLegendsToSVG with every legend and no overflow menu',
    );
  });

  testWidgets('the exported strip carries the live selection', (tester) async {
    final controller = FluentDeclarativeChartController();
    addTearDown(controller.dispose);
    await pump(
      tester,
      FluentDeclarativeChart(
        controller: controller,
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            'data': <Object?>[
              for (final name in <String>['a', 'b', 'c'])
                <String, Object?>{
                  'type': 'scatter',
                  'mode': 'lines',
                  'fill': 'tonexty',
                  'name': name,
                  'x': const <Object?>[0, 1, 2],
                  'y': const <Object?>[1, 2, 3],
                },
            ],
          },
          selectedLegends: const <String>['a'],
        ),
      ),
    );
    final live = tester.widget<FluentChartLegend>(
      find.byType(FluentChartLegend),
    );
    final legendTop =
        tester.getTopLeft(find.byType(FluentChartLegend)).dy -
        tester.getTopLeft(boundaryOf()).dy;
    final strip = FluentSynthesisedLegendLayout.compute(
      legends: live.legends,
      svgWidth: tester.getSize(boundaryOf()).width,
      measurer: FluentChartTextMeasurer(),
      textStyle: resolveFluentChartLegendStyle(
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      ).labelTextStyle!.resolve(<WidgetState>{})!,
      centerLegends: live.centerLegends,
    );
    final bytes = await exportOf(
      tester,
      controller,
      const FluentChartImageExportOptions(scale: 1),
    );
    final pixels = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      final width = image.width;
      image.dispose();
      codec.dispose();
      return (width, data!);
    });
    final (width, data) = pixels!;
    Color swatchCentre(int index) {
      final centre = strip.items[index].swatchRect.center.translate(
        0,
        legendTop,
      );
      final rgba = data.getUint32(
        (centre.dy.floor() * width + centre.dx.floor()) * 4,
      );
      return Color((rgba & 0xFF) << 24 | rgba >> 8);
    }

    expect(
      swatchCentre(0),
      live.legends[0].color,
      reason: 'image-export-utils.ts:337 fills the selected legend',
    );
    expect(
      swatchCentre(1),
      isNot(live.legends[1].color),
      reason:
          'and leaves every other swatch transparent, as the screen dims it',
    );
  });

  testWidgets('a table scrolled inside its box exports every row', (
    tester,
  ) async {
    final controller = FluentDeclarativeChartController();
    addTearDown(controller.dispose);
    await pump(
      tester,
      FluentDeclarativeChart(
        controller: controller,
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            'data': <Object?>[
              <String, Object?>{
                'type': 'table',
                'header': const <String, Object?>{
                  'values': <Object?>['ID', 'Value'],
                },
                'cells': <String, Object?>{
                  'values': <Object?>[
                    <Object?>[for (var i = 1; i <= 50; i++) 'ID-$i'],
                    <Object?>[for (var i = 1; i <= 50; i++) '$i'],
                  ],
                },
              },
            ],
            'layout': const <String, Object?>{'height': 300},
          },
        ),
      ),
    );
    final viewport = find
        .descendant(
          of: find.byType(FluentChartTable),
          matching: find.byType(SingleChildScrollView),
        )
        .first;
    final content = find
        .ancestor(
          of: find.byType(Table),
          matching: find.byType(RepaintBoundary),
        )
        .first;
    expect(
      tester.getSize(content).height,
      greaterThan(tester.getSize(viewport).height),
      reason: 'the precondition: the rows overflow the viewport, which scrolls',
    );
    final boundary = tester.getRect(boundaryOf());
    final top = tester.getTopLeft(viewport).dy - boundary.top;
    final bytes = await exportOf(
      tester,
      controller,
      const FluentChartImageExportOptions(scale: 1),
    );
    expect(
      pngSize(bytes),
      (boundary.width.toInt(), (top + tester.getSize(content).height).toInt()),
      reason:
          'the title band down to the viewport, then the whole grid — past '
          'upstream, whose export stops at the box (ChartTable.tsx:119-125)',
    );
  });
}
