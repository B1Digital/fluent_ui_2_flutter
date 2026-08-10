import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../chrome/legend.dart';
import '../chrome/legend_style.dart';
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
