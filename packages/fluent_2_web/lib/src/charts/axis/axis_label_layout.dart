import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../internal/chart_text_measurer.dart';

/// One rendered line of a tick label.
///
/// Upstream a line is a `<tspan>` whose vertical offset is expressed in ems
/// relative to the tick's own baseline (`utilities.ts:1148-1154` for the first
/// line, `:1169-1174` for each wrapped one); [dyEm] carries that offset
/// unchanged so the painter can multiply it by the resolved font size.
@immutable
class FluentAxisLabelLine {
  /// Creates one line of a tick label.
  const FluentAxisLabelLine({required this.text, required this.dyEm});

  /// The text of this line.
  final String text;

  /// The baseline offset in ems, including the axis's own base `dy`.
  final double dyEm;
}

/// A tick label after wrapping, staggering or truncation.
@immutable
class FluentAxisTickLabel {
  /// Creates a laid-out tick label.
  const FluentAxisTickLabel({
    required this.lines,
    required this.fullText,
    required this.truncated,
  });

  /// The rendered lines, in painting order.
  final List<FluentAxisLabelLine> lines;

  /// The untransformed label, which the axis-label tooltip shows on hover.
  ///
  /// Upstream stashes it on a `data-full` attribute (`utilities.ts:1150` for the
  /// x axis, `:1220` for the y axis).
  final String fullText;

  /// Whether the rendered lines differ from [fullText], which is the condition
  /// upstream uses to decide whether to attach a tooltip at all
  /// (`utilities.ts:1301-1304`).
  final bool truncated;
}

/// The laid-out x-axis label set plus the height it costs the plot.
@immutable
class FluentXAxisLabelLayout {
  /// Creates an x-axis label layout.
  const FluentXAxisLabelLayout({
    required this.labels,
    required this.reserveHeight,
    required this.rotationRadians,
  });

  /// One entry per tick, in tick order.
  final List<FluentAxisTickLabel> labels;

  /// The pixels to subtract from the plot height.
  ///
  /// Upstream calls this `_removalValueForTextTuncate` and only reaches it on
  /// the *next* React render (`CartesianChart.tsx:209`, `:298`); the port solves
  /// it eagerly in one pass.
  final double reserveHeight;

  /// The rotation applied to every tick group, in radians. `-pi / 4` when the
  /// labels are rotated (`utilities.ts:1820`), otherwise zero.
  final double rotationRadians;
}

/// The longest prefix of [text] that fits [maxWidth] once an ellipsis is added.
///
/// Ports `truncateTextToFitWidth` (`utilities.ts:2696-2716`). The search seeds
/// `lo` at `1`, so the shortest possible answer is one character plus the
/// ellipsis even when that still overflows.
String truncateTextToFitWidth(
  String text,
  double maxWidth,
  double Function(String) measure,
) {
  if (measure(text) <= maxWidth) {
    return text;
  }
  var lo = 1;
  var hi = text.length;
  while (lo < hi) {
    // utilities.ts:2705 — the +1 biases the midpoint upwards, which is what
    // keeps the loop from stalling when hi is exactly lo + 1.
    final mid = ((lo + hi + 1) / 2).floor();
    final candidate = '${text.substring(0, mid)}...';
    if (measure(candidate) <= maxWidth) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return '${text.substring(0, lo)}...';
}

/// Shortens [content] one code unit at a time until it fits [maxWidth].
///
/// Ports `wrapContent` (`utilities.ts:1232-1248`), which serves axis titles and
/// axis annotations through `SVGTooltipText`. The first measurement has no
/// ellipsis and every later one does, which is why this is **not**
/// interchangeable with [truncateTextToFitWidth]: on a proportional font the two
/// land on different cut points. One UTF-16 code unit per step matches
/// JavaScript's `slice(0, -1)`, and Dart strings are UTF-16 too, so the parity
/// is free.
///
/// Upstream cuts a code unit *before* it measures the ellipsised string
/// (`:1242-1243`), so a `content` that overflows on its own but fits once the
/// ellipsis replaces its last character loses that character upstream and keeps
/// it here. The plan specifies this shape, so it is what ships; the divergence
/// is one code unit on one input class and is recorded rather than silently
/// smoothed over.
({String text, bool overflowed}) shrinkToFit(
  String content,
  TextStyle style,
  double maxWidth,
  FluentChartTextMeasurer measurer,
) {
  if (measurer.width(content, style) <= maxWidth) {
    return (text: content, overflowed: false);
  }
  var shortened = content;
  while (shortened.isNotEmpty &&
      measurer.width('$shortened...', style) > maxWidth) {
    shortened = shortened.substring(0, shortened.length - 1);
  }
  return (text: '$shortened...', overflowed: true);
}

/// Lays out y-axis tick labels, truncating them when asked.
///
/// Ports `createYAxisLabels` (`utilities.ts:1196-1230`). The ellipsis goes on
/// the leading side under RTL (`:1211-1213`). `CartesianChart.tsx:400-406` is
/// the only call site, and it defaults [noOfCharsToTruncate] to four.
///
/// Upstream sets the tspan text only inside the `truncateLabel` branch
/// (`:1226-1228`), so a call with `truncateLabel: false` renders an empty y
/// axis. That is an accessibility defect rather than a visual quirk, so the port
/// fills in the full label instead — spec section 5.2, exception 2.
List<FluentAxisTickLabel> createYAxisLabels(
  List<String> labels,
  int noOfCharsToTruncate, {
  required bool truncateLabel,
  required bool isRtl,
}) {
  return <FluentAxisTickLabel>[
    for (final label in labels)
      () {
        // utilities.ts:1227 compares the whole length against the budget, so a
        // label of exactly noOfCharsToTruncate code units is left alone.
        final needsTruncating =
            truncateLabel && label.length > noOfCharsToTruncate;
        final head = label.substring(
          0,
          // JavaScript's slice clamps a too-long end index; Dart's substring
          // throws, hence the min.
          math.min(noOfCharsToTruncate, label.length),
        );
        final text = needsTruncating
            ? (isRtl ? '...$head' : '$head...')
            : label;
        return FluentAxisTickLabel(
          lines: <FluentAxisLabelLine>[
            // 0.32 is d3-axis's own dy for a left or right axis
            // (`d3-axis/src/axis.js:72`, the same literal the kernel's
            // FluentAxisTickGeometry.baselineDyEm returns), which
            // utilities.ts:1217 reads off the tick text and :1224 copies onto
            // the tspan unchanged.
            FluentAxisLabelLine(text: text, dyEm: 0.32),
          ],
          fullText: label,
          truncated: needsTruncating,
        );
      }(),
  ];
}
