import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../chrome/legend.dart';
import '../chrome/legend_style.dart';
import '../model/chart_common.dart';
import 'chart_text_measurer.dart';
import 'chart_utils.dart';

// Title-casing is NOT declared here. `capitalizeLegendLabel` lives in
// `chart_utils.dart` (plan 02), which homed it there precisely because it has
// two callers — `chrome/legend.dart` and this file. Spec §5.4's parity claim is
// that the exported strip matches the on-screen legend's layout, and that is
// only checkable if both capitalise identically.

/// One legend entry in the exported strip.
@immutable
class FluentSynthesisedLegendItem {
  /// Creates a placed legend entry.
  const FluentSynthesisedLegendItem({
    required this.label,
    required this.color,
    required this.isActive,
    required this.swatchRect,
    required this.textTopLeft,
  });

  /// The capitalised label.
  final String label;

  /// The series colour — the swatch stroke, and its fill when active.
  final Color color;

  /// Whether the legend is selected, or nothing is selected at all
  /// (`image-export-utils.ts:329`).
  final bool isActive;

  /// The 13x13 square (`image-export-utils.ts:332-339`).
  final Rect swatchRect;

  /// Top-left of the label, since the text hangs from its top edge
  /// (`image-export-utils.ts:345`).
  final Offset textTopLeft;
}

/// The laid-out legend strip an exported image carries beneath the chart.
@immutable
class FluentSynthesisedLegendLayout {
  /// Creates a laid-out strip.
  const FluentSynthesisedLegendLayout({
    required this.items,
    required this.size,
  });

  /// Every legend, in input order — there is no overflow menu.
  final List<FluentSynthesisedLegendItem> items;

  /// Size of the strip.
  final Size size;

  /// Lays the strip out.
  ///
  /// Ports `cloneLegendsToSVG` (`image-export-utils.ts:280-393`) exactly,
  /// including the `legendLine.length > 1` guard that stops a single over-wide
  /// legend from wrapping, and the RTL and centring passes that translate whole
  /// lines afterwards.
  static FluentSynthesisedLegendLayout compute({
    required List<FluentChartLegendItem> legends,
    required double svgWidth,
    required FluentChartTextMeasurer measurer,
    required TextStyle textStyle,
    Set<String> selectedLegends = const <String>{},
    bool centerLegends = false,
    bool isRtl = false,
  }) {
    // `:295-301` — no legends means a null node and a zero box.
    if (legends.isEmpty) {
      return const FluentSynthesisedLegendLayout(
        items: <FluentSynthesisedLegendItem>[],
        size: Size.zero,
      );
    }
    // `:313` — 8 + 13 + 8.
    const textOffset =
        kLegendPadding + kLegendShapeSize + kLegendShapeMarginEnd;
    // `:305` — a centred strip starts each line at 0 and is translated later.
    final lineStart = centerLegends ? 0.0 : kLegendContainerMarginStart;
    var legendX = lineStart;
    var legendY = kLegendContainerMarginTop;
    // `:310`.
    final noLegendsSelected = selectedLegends.isEmpty;

    // Per line: the items on it and their widths, so the second pass can
    // translate each item by the slack its whole line carries.
    final lines = <List<(FluentSynthesisedLegendItem, double)>>[];
    final lineWidths = <double>[];
    var line = <(FluentSynthesisedLegendItem, double)>[];

    for (final legend in legends) {
      // `:314` measures through `measureTextWithDOM`, which copies
      // `text-transform` (`utilities.ts:2137-2144`), so the measured width is
      // the capitalised one. `:347` then draws the raw title through the same
      // capitalising class, so the drawn glyphs are capitalised too.
      final label = capitalizeLegendLabel(legend.title);
      // `:315`.
      final legendWidth =
          textOffset + measurer.width(label, textStyle) + kLegendPadding;
      // `:318-319` — the item is pushed BEFORE the test, so `length > 1` reads
      // "there is already something else on this line".
      final wraps = legendX + legendWidth > svgWidth && line.isNotEmpty;
      if (wraps) {
        // `:320-326`.
        lines.add(line);
        lineWidths.add(legendX);
        line = <(FluentSynthesisedLegendItem, double)>[];
        legendX = lineStart;
        legendY += kLegendHeight;
      }
      // `:329`.
      final isActive =
          selectedLegends.contains(legend.title) || noLegendsSelected;
      line.add((
        FluentSynthesisedLegendItem(
          label: label,
          color: legend.color,
          isActive: isActive,
          swatchRect: Rect.fromLTWH(
            // `:333`.
            legendX +
                (isRtl
                    ? legendWidth - kLegendPadding - kLegendShapeSize
                    : kLegendPadding),
            // `:334`.
            legendY + kLegendPadding,
            // `:335-336` — always 13 x 13, never the legend's real shape.
            kLegendShapeSize,
            kLegendShapeSize,
          ),
          textTopLeft: Offset(
            // `:343`.
            legendX + (isRtl ? legendWidth - textOffset : textOffset),
            // `:344-345` — `dominant-baseline: hanging`, so the same y as the
            // swatch top anchors the text's top edge.
            legendY + kLegendPadding,
          ),
        ),
        legendWidth,
      ));
      // `:350`.
      legendX += legendWidth;
    }
    // `:353-355`.
    lines.add(line);
    lineWidths.add(legendX);
    legendY += kLegendHeight;

    // `:383`.
    final w1 = <double>[svgWidth, ...lineWidths].reduce(math.max);
    final items = <FluentSynthesisedLegendItem>[];
    for (var i = 0; i < lines.length; i++) {
      if (centerLegends) {
        // `:357-368` — the whole line shifts right by half its slack.
        final lineOffsetX = math.max((svgWidth - lineWidths[i]) / 2, 0.0);
        var remLineWidth = lineWidths[i];
        var itemOffsetX = 0.0;
        for (final (item, width) in lines[i]) {
          final dx =
              lineOffsetX + (isRtl ? remLineWidth - width - itemOffsetX : 0.0);
          items.add(_translate(item, dx));
          remLineWidth -= width;
          itemOffsetX += width;
        }
      } else if (isRtl) {
        // `:369-381` — each item is reflected within the strip.
        var remLineWidth = w1 - kLegendContainerMarginStart;
        var itemOffsetX = kLegendContainerMarginStart;
        for (final (item, width) in lines[i]) {
          items.add(_translate(item, remLineWidth - width - itemOffsetX));
          remLineWidth -= width;
          itemOffsetX += width;
        }
      } else {
        for (final (item, _) in lines[i]) {
          items.add(item);
        }
      }
    }
    // `:384, 390-391`.
    return FluentSynthesisedLegendLayout(items: items, size: Size(w1, legendY));
  }

  static FluentSynthesisedLegendItem _translate(
    FluentSynthesisedLegendItem item,
    double dx,
  ) => FluentSynthesisedLegendItem(
    label: item.label,
    color: item.color,
    isActive: item.isActive,
    swatchRect: item.swatchRect.translate(dx, 0),
    textTopLeft: item.textTopLeft.translate(dx, 0),
  );
}

/// Paints the strip `cloneLegendsToSVG` synthesises for an exported image.
///
/// Not the on-screen legend: always a 13x13 square regardless of
/// [FluentChartLegendItem.shape], never a stripe pattern, never the 4px line
/// legend, and a **transparent** fill when dimmed rather than
/// `colorNeutralBackground1`. Spec §5.4 — the export is a reproduction, and
/// reproducing it faithfully means reproducing where it is poorer than the live
/// legend.
class FluentSynthesisedLegendPainter extends CustomPainter {
  /// Creates a synthesised-legend painter.
  FluentSynthesisedLegendPainter({
    required this.layout,
    required this.textStyle,
    required this.measurer,
  });

  /// The laid-out strip.
  final FluentSynthesisedLegendLayout layout;

  /// Label text style.
  final TextStyle textStyle;

  /// Text measurer, so the painted text is configured exactly as the width the
  /// layout reserved was measured with.
  final FluentChartTextMeasurer measurer;

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in layout.items) {
      canvas.drawRect(
        item.swatchRect,
        Paint()
          ..style = PaintingStyle.fill
          // `:337` — literally `transparent`, not a theme surface. Fully
          // transparent black is the CSS keyword's computed value.
          ..color = item.isActive ? item.color : const Color(0x00000000),
      );
      canvas.drawRect(
        item.swatchRect,
        Paint()
          ..style = PaintingStyle.stroke
          // `:338-339` — the border is the series colour and is never dimmed.
          ..strokeWidth = kLegendShapeBorder
          ..color = item.color,
      );
      // `:346` — the dimmed label drops to 0.67, which is NOT the swatch's 0.6.
      final opacity = item.isActive ? 1.0 : kInactiveLegendTextOpacity;
      final style = textStyle.copyWith(
        // Opaque black is `TextStyle`'s own default when no colour is supplied
        // (`text_style.dart`), so falling back to it changes nothing but makes
        // the alpha multiplication expressible.
        color: (textStyle.color ?? const Color(0xFF000000)).withValues(
          alpha: opacity,
        ),
      );
      final painter = measurer.layoutPainter(item.label, style);
      // `:345` — `dominant-baseline: hanging`, so the anchor is the text's top
      // edge, which is exactly what `TextPainter.paint` takes.
      painter.paint(canvas, item.textTopLeft);
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(FluentSynthesisedLegendPainter oldDelegate) =>
      oldDelegate.layout != layout || oldDelegate.textStyle != textStyle;
}

// ponytail: fixed caps, sized to the smallest limit a browser silently
// enforces rather than to any one GPU. 4096² is iOS Safari's canvas area limit
// and half Chromium's WebGL drawing-buffer cap (5760²); 8192 per side is under
// every desktop MAX_TEXTURE_SIZE and most mobile ones. Query the real
// `MAX_TEXTURE_SIZE` if exports ever need to go bigger.
const double _kMaxExportSide = 8192;
const double _kMaxExportPixels = 4096.0 * 4096.0;

/// [value] when it is a usable scale or length, null otherwise — the Dart
/// spelling of upstream's `value || fallback`, which reads 0 and NaN as unset.
double? _positive(double? value) =>
    value != null && value.isFinite && value > 0 ? value : null;

/// The largest ratio [size] can be rasterised at inside both caps.
double _maxRatio(Size size) => math.min(
  _kMaxExportSide / math.max(size.width, size.height),
  math.sqrt(_kMaxExportPixels / (size.width * size.height)),
);

/// Renders a chart and its synthesised legend into a PNG data URL.
///
/// Ports `exportChartsAsImage` + `svgToPng`
/// (`image-export-utils.ts:32-80, 400-459`) against a [RepaintBoundary]
/// instead of a cloned SVG. The grid is always one column: the chart on row 0
/// and, when there are legends, the strip on row 1 — which is exactly what
/// `:75` pushes.
///
/// There is no `RenderRepaintBoundary.toImage` precedent elsewhere in this
/// package; this class is the pattern every future chart export should follow.
/// Both `toImage` and [ui.Image.toByteData] are serviced by the engine, so a
/// widget test must call [toImage] inside `WidgetTester.runAsync`.
class FluentChartImageExporter {
  /// Creates an exporter over the boundary at [boundaryKey].
  FluentChartImageExporter({
    required this.boundaryKey,
    required this.legends,
    FluentChartTextMeasurer? measurer,
    this.legendTextStyle = const TextStyle(fontSize: 12),
    this.selectedLegends = const <String>{},
    this.centerLegends = false,
    this.isRtl = false,
    this.clipHeight,
    this.continuationKey,
    this.continuationX = 0,
  }) : measurer = measurer ?? FluentChartTextMeasurer();

  /// Key of the [RepaintBoundary] wrapping the painted chart.
  final GlobalKey boundaryKey;

  /// Logical height of [boundaryKey]'s box to keep, measured from its top.
  /// Null keeps all of it.
  ///
  /// This is how a figure whose live legend sits inside the boundary drops it:
  /// the legend is always the last thing down the chart, so cutting at its top
  /// edge leaves exactly the `<svg>` upstream clones, and [legends] redraws it
  /// in full below.
  final double? clipHeight;

  /// A second boundary, captured whole and drawn directly below the kept part
  /// of [boundaryKey], [continuationX] in from its left edge.
  ///
  /// This is how a scroll viewport exports its whole content rather than its
  /// visible window: [clipHeight] cuts the boundary at the viewport's top and
  /// this boundary, round the scrolled content, carries every row from there.
  final GlobalKey? continuationKey;

  /// Left edge of [continuationKey], in [boundaryKey]'s logical coordinates.
  ///
  /// Negative when the content overhangs the boundary's left edge, as a
  /// right-to-left viewport's does: it is anchored at the viewport's right.
  final double continuationX;

  /// Legends to synthesise. Empty means no strip is drawn at all, which is
  /// what `hideLegends` does at `hooks.ts:33` — the argument
  /// `hideLegends ? undefined : legendsRef.current?.toSVG`, which is what
  /// `exportChartsAsImage` receives in place of a legend cloner. `:32` is the
  /// chart-container argument above it.
  final List<FluentChartLegendItem> legends;

  /// Measurer for the legend labels.
  final FluentChartTextMeasurer measurer;

  /// Text style for the legend labels.
  final TextStyle legendTextStyle;

  /// Legends currently selected; empty means every legend is drawn active.
  final Set<String> selectedLegends;

  /// Whether the strip is centred under the chart.
  final bool centerLegends;

  /// Whether the strip lays out right to left.
  final bool isRtl;

  /// Renders the chart to a `data:image/png;base64,…` string.
  Future<String> toImage([
    FluentChartImageExportOptions options =
        const FluentChartImageExportOptions(),
  ]) async {
    final object = boundaryKey.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) {
      // `image-export-utils.ts:152-154`.
      throw StateError('Chart container is not defined');
    }
    final tail = continuationKey?.currentContext?.findRenderObject();
    final continuation = tail is RenderRepaintBoundary ? tail : null;
    // `getBoundingClientRect()` (`:249`) is a logical size. It is read from the
    // render objects, not from a captured image, because an image's pixel size
    // is `(size * pixelRatio).ceil()` and so not the logical size at all.
    final headHeight = clipHeight == null
        ? object.size.height
        : clipHeight!.clamp(0.0, object.size.height);
    // An end-aligned continuation can overhang the boundary's left edge, and
    // then everything shifts right by the overhang.
    final left = continuation == null ? 0.0 : math.min(0.0, continuationX);
    final chartSize = Size(
      math.max(
            object.size.width,
            continuation == null
                ? 0.0
                : continuationX + continuation.size.width,
          ) -
          left,
      headHeight + (continuation?.size.height ?? 0.0),
    );

    FluentSynthesisedLegendLayout? layout;
    var legendSize = Size.zero;
    if (legends.isNotEmpty) {
      // `:72` passes the widest row, which for a single chart is the chart
      // width.
      layout = FluentSynthesisedLegendLayout.compute(
        legends: legends,
        svgWidth: chartSize.width,
        measurer: measurer,
        textStyle: legendTextStyle,
        selectedLegends: selectedLegends,
        centerLegends: centerLegends,
        isRtl: isRtl,
      );
      legendSize = layout.size;
    }

    var totalWidth = math.max(chartSize.width, legendSize.width);
    var totalHeight = chartSize.height + legendSize.height;
    if (!(totalWidth > 0 && totalHeight > 0)) {
      // Upstream would divide by zero at `:426-427` and hand the canvas NaN.
      throw StateError('Chart cannot be exported as image');
    }
    // `:423-425` — `opts.scale || 1` and `opts.width || totalWidth`: zero is
    // "unset" there, and here too, since a zero ratio cannot be captured.
    final scale = _positive(options.scale) ?? 1.0;
    // `:426-429` — scaleX and scaleY are computed INDEPENDENTLY, so a target
    // with a different aspect ratio distorts. Parity, spec §5.4.
    var scaleX = scale * (_positive(options.width) ?? totalWidth) / totalWidth;
    var scaleY =
        scale * (_positive(options.height) ?? totalHeight) / totalHeight;
    // Upstream draws the SVG as a vector at the output size (`:449`), so every
    // edge is rendered at that resolution. The raster equivalent is to capture
    // at the output scale: a 1x capture stretched five times is a blur of 5x5
    // blocks. A layer can only be captured at one uniform ratio, so a target
    // whose axes scale differently is captured at the larger and the other
    // axis downsampled — never upsampled.
    final ratio = math.max(scaleX, scaleY);
    // The browser does not fail an oversized raster; it silently shrinks the
    // WebGL drawing buffer (Chromium caps it at 5760² px), which leaves a
    // transparent band across the image. The captures go through that same
    // surface, and are larger than the output when a target is stretched or a
    // big region is cut away. Every one of them scales with a single factor, so
    // one fit keeps them all inside the caps — a smaller sharp image over a
    // full-size corrupt or blurred one.
    final fit = <double>[
      1.0,
      _maxRatio(Size(totalWidth * scaleX, totalHeight * scaleY)),
      _maxRatio(object.size) / ratio,
      if (continuation != null) _maxRatio(continuation.size) / ratio,
    ].reduce(math.min);
    scaleX *= fit;
    scaleY *= fit;
    totalWidth *= scaleX;
    totalHeight *= scaleY;
    final pixelRatio = ratio * fit;
    // Both captures are taken before the first await, so no frame can dispose
    // or re-lay out either boundary between them.
    final captures = await Future.wait<ui.Image>(<Future<ui.Image>>[
      object.toImage(pixelRatio: pixelRatio),
      if (continuation != null) continuation.toImage(pixelRatio: pixelRatio),
    ], cleanUp: (image) => image.dispose());
    ui.Image? image;
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, totalWidth, totalHeight),
        Paint()..color = options.background,
      );
      // The cut is on a whole output row and the continuation starts on it, so
      // at a uniform scale both copy 1:1 instead of resampling half a row off.
      final cutY = (headHeight * scaleY).roundToDouble();
      void draw(ui.Image capture, double x, double y, double srcHeight) {
        // The destination is the capture's own pixels mapped back through the
        // same ratio, so a uniform scale is an exact 1:1 copy with no
        // resampling; the ceil'd spare column, if any, falls outside the
        // truncated canvas.
        canvas.drawImageRect(
          capture,
          Rect.fromLTWH(0, 0, capture.width.toDouble(), srcHeight),
          Rect.fromLTWH(
            x,
            y,
            capture.width * scaleX / pixelRatio,
            srcHeight * scaleY / pixelRatio,
          ),
          Paint()..filterQuality = FilterQuality.medium,
        );
      }

      draw(
        captures.first,
        (-left * scaleX).roundToDouble(),
        0,
        math.min(cutY * pixelRatio / scaleY, captures.first.height.toDouble()),
      );
      if (continuation != null) {
        draw(
          captures.last,
          ((continuationX - left) * scaleX).roundToDouble(),
          cutY,
          captures.last.height.toDouble(),
        );
      }
      if (layout != null) {
        // Painted as vectors at the output scale rather than rasterised at 1x
        // and stretched. The clip is the legend SVG's own viewport (`:385`).
        canvas
          ..save()
          ..translate(0, scaleY * chartSize.height)
          ..scale(scaleX, scaleY)
          ..clipRect(Offset.zero & legendSize);
        FluentSynthesisedLegendPainter(
          layout: layout,
          textStyle: legendTextStyle,
          measurer: measurer,
        ).paint(canvas, legendSize);
        canvas.restore();
      }
      // `:432-433` — assigning to `canvas.width` truncates towards zero rather
      // than rounding, and a zero-sized canvas is not representable here.
      image = await recorder.endRecording().toImage(
        math.max(1, totalWidth.toInt()),
        math.max(1, totalHeight.toInt()),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        // `toByteData` only returns null when the engine failed to encode.
        throw StateError('Chart image could not be encoded');
      }
      return 'data:image/png;base64,'
          '${base64Encode(bytes.buffer.asUint8List())}';
    } finally {
      // Only now: the composite picture refers to the captures until it has
      // been rasterised.
      for (final capture in captures) {
        capture.dispose();
      }
      image?.dispose();
    }
  }
}

/// The imperative handle a chart hands its caller.
///
/// Replaces upstream's `componentRef: Ref<Chart>` (`hooks.ts:23-41`). Attach it
/// to a chart with the widget's `controller` parameter, then call [toImage].
class FluentChartController implements FluentChartHandle {
  /// Creates a detached controller.
  FluentChartController();

  FluentChartImageExporter? _exporter;

  /// Whether a mounted chart has claimed this controller.
  bool get isAttached => _exporter != null;

  /// Called by a chart when it mounts or its export configuration changes.
  void attach(FluentChartImageExporter exporter) => _exporter = exporter;

  /// Called by a chart when it unmounts.
  void detach() => _exporter = null;

  // `async` rather than a plain `Future` return so an unattached controller
  // reports through the future like every other `toImage` failure does,
  // instead of throwing at the call site.
  @override
  Future<String> toImage([
    FluentChartImageExportOptions options =
        const FluentChartImageExportOptions(),
  ]) async {
    final exporter = _exporter;
    if (exporter == null) {
      throw StateError(
        'FluentChartController is not attached to a mounted chart',
      );
    }
    return exporter.toImage(options);
  }
}
