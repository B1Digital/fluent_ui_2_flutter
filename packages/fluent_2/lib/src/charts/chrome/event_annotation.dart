import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../internal/chart_text_measurer.dart';
import '../internal/chart_text_styles.dart';
import '../internal/d3/scale.dart';
import '../model/chart_annotation.dart';

/// Slack added to the label width before packing. `EventAnnotation.tsx:20`.
const double kEventAnnotationTextPadding = 5;

/// Line height of a wrapped event label, in raw pixels.
///
/// `EventAnnotation.tsx:21`. `Textbox.tsx:40` uses it as a bare `dy` attribute
/// rather than an em value, and `:44` lifts the whole block by
/// `-numLines * 18`, which is what bottom-aligns it.
const double kEventAnnotationLineHeight = 18;

/// Default label width. `EventAnnotation.tsx:17`.
///
/// The packer is fed `labelWidth + kEventAnnotationTextPadding` (`:37`), so its
/// working width is 110 — a different number that must not be confused with
/// this one.
const double kEventAnnotationDefaultLabelWidth = 105;

/// How far above the plot top the label baseline sits.
/// `EventAnnotation.tsx:18`.
const double kEventAnnotationTextTopOffset = 20;

/// How far above the plot top each dashed rule starts.
///
/// `EventAnnotation.tsx:19` is `textY + 7`, and `textY` is `chartYTop - 20`, so
/// the rule begins 13 above the plot.
const double kEventAnnotationLineTopOffset = 13;

/// Dash pattern of the vertical rules. `EventAnnotation.tsx:34`.
///
/// SVG's `stroke-dasharray="8"` is a single value, which means 8 on and 8 off.
const List<double> kEventAnnotationDashArray = <double>[8];

/// Which end of an event label sits on its rule.
enum FluentEventLabelAnchor {
  /// The label extends to the right of its rule. `EventAnnotation.tsx:81`.
  start,

  /// The label extends to the left of its rule. `EventAnnotation.tsx:79`.
  end,
}

/// One packed event label.
@immutable
class FluentEventLabelPlacement {
  /// Creates a placement.
  const FluentEventLabelPlacement({
    required this.x,
    required this.anchor,
    required this.aggregatedIndices,
  });

  /// The rule this label sits on.
  final double x;

  /// Which side of [x] the text extends.
  final FluentEventLabelAnchor anchor;

  /// Every event index this label speaks for.
  ///
  /// More than one means the label reads `mergedLabel(count)` instead of a
  /// single event's own text (`LabelLink.tsx:66-70`).
  final List<int> aggregatedIndices;
}

/// Packs event labels along the x axis without overprinting.
///
/// Ports `calculateLabels` (`EventAnnotation.tsx:61-119`) — a recursive greedy
/// packer. [positions] must already be sorted ascending by date
/// (`:27`). [textWidth] is the label width **plus**
/// [kEventAnnotationTextPadding], as `:37` passes it.
///
/// Written iteratively rather than recursively: the upstream `backtrack` always
/// tail-calls `calculateLabel` and unshifts onto the result, so the recursion is
/// a loop with an accumulator and a 500-event series would otherwise blow the
/// stack.
List<FluentEventLabelPlacement> fluentPackEventAnnotationLabels(
  List<double> positions,
  double textWidth,
  double maxX,
  double minX,
) {
  final placements = <FluentEventLabelPlacement>[];
  var lastX = minX;
  var index = 0;

  while (index < positions.length) {
    final x = positions[index];
    final leftBoundary = x - textWidth;

    // EventAnnotation.tsx:72-74 — cannot render on top of the previous label.
    if (x < lastX) {
      break;
    }

    // EventAnnotation.tsx:77-85 — the last event has no successor to fold into.
    if (index == positions.length - 1) {
      if (lastX < leftBoundary) {
        placements.add(
          FluentEventLabelPlacement(
            x: x,
            anchor: FluentEventLabelAnchor.end,
            aggregatedIndices: <int>[index],
          ),
        );
      } else if (x + textWidth < maxX) {
        placements.add(
          FluentEventLabelPlacement(
            x: x,
            anchor: FluentEventLabelAnchor.start,
            aggregatedIndices: <int>[index],
          ),
        );
      }
      break;
    }

    // EventAnnotation.tsx:87-93.
    final anchor = lastX < leftBoundary
        ? FluentEventLabelAnchor.end
        : FluentEventLabelAnchor.start;
    // EventAnnotation.tsx:97 — the boundary the next label must clear.
    final boundary = anchor == FluentEventLabelAnchor.end ? x : x + textWidth;

    // EventAnnotation.tsx:99-106 — the first later event with room of its own.
    var next = positions.length;
    for (var scan = index + 1; scan < positions.length; scan++) {
      final candidate = positions[scan];
      if (candidate > boundary &&
          (candidate - textWidth >= boundary || candidate + textWidth < maxX)) {
        next = scan;
        break;
      }
    }

    placements.add(
      FluentEventLabelPlacement(
        x: x,
        anchor: anchor,
        // EventAnnotation.tsx:108-111.
        aggregatedIndices: <int>[for (var i = index; i < next; i++) i],
      ),
    );
    lastX = boundary;
    index = next;
  }

  return placements;
}

/// A packed label with its resolved text, ready to paint.
@immutable
class FluentEventLabel {
  /// Creates a resolved label.
  const FluentEventLabel({
    required this.text,
    required this.x,
    required this.anchor,
  });

  /// The label text: one event's own, or `mergedLabel(count)`.
  final String text;

  /// The rule the label sits on.
  final double x;

  /// Which side of [x] the text extends.
  final FluentEventLabelAnchor anchor;
}

/// Paints LineChart's event annotations: dashed rules and their labels.
///
/// The labels wrap and are **bottom-aligned**: `Textbox.tsx:44` lifts the whole
/// block by `-numLines * lineHeight` so it grows upwards from its baseline,
/// which is what keeps it clear of the plot as it gains lines.
class FluentEventAnnotationPainter extends CustomPainter {
  /// Creates a painter.
  const FluentEventAnnotationPainter({
    required this.rules,
    required this.labels,
    required this.lineTop,
    required this.lineBottom,
    required this.textBaseline,
    required this.labelWidth,
    required this.strokeColor,
    required this.labelColor,
    required this.textStyle,
  });

  /// One offset per deduplicated rule; only `dx` is meaningful.
  final List<Offset> rules;

  /// The packed labels.
  final List<FluentEventLabel> labels;

  /// Top of every rule: `chartTop - 13`.
  final double lineTop;

  /// Bottom of every rule: `chartBottom`.
  final double lineBottom;

  /// Baseline the labels sit on: `chartTop - 20`.
  final double textBaseline;

  /// Width the labels wrap at.
  final double labelWidth;

  /// Rule colour.
  final Color strokeColor;

  /// Label colour.
  final Color labelColor;

  /// Label text style — `10pt`, which is 13.33 logical pixels
  /// (`EventAnnotation.tsx:22`).
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      // EventAnnotation.tsx:34 gives no stroke-width, so SVG's default of 1
      // applies.
      ..strokeWidth = 1;

    for (final rule in rules) {
      _dashedLine(
        canvas,
        Offset(rule.dx, lineTop),
        Offset(rule.dx, lineBottom),
        paint,
      );
    }

    // Built here rather than held by the widget because nothing is cached: a
    // wrapping label is laid out through [FluentChartTextMeasurer.layoutPainter]
    // and never through the string-keyed [FluentChartTextMeasurer.measure]. The
    // factory stays the only place a `TextPainter` is constructed, so the labels
    // are drawn with the configuration every other chart painter measures with.
    final measurer = FluentChartTextMeasurer();
    final labelStyle = textStyle.copyWith(color: labelColor);

    for (final label in labels) {
      final painter = measurer.layoutPainter(label.text, labelStyle)
        // The factory is a single-line one; `Textbox.tsx:21-42` wraps on
        // whitespace at the label width.
        ..maxLines = null
        // LabelLink.tsx:81 puts the packed anchor on `text-anchor`.
        ..textAlign = label.anchor == FluentEventLabelAnchor.end
            ? TextAlign.right
            : TextAlign.left
        ..layout(maxWidth: labelWidth);

      final lines = painter.computeLineMetrics().length;
      // Textbox.tsx:44 — bottom alignment by lifting the block.
      final top = textBaseline - lines * kEventAnnotationLineHeight;
      final left = label.anchor == FluentEventLabelAnchor.end
          ? label.x - painter.width
          : label.x;
      painter
        ..paint(canvas, Offset(left, top))
        ..dispose();
    }
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final total = (to - from).distance;
    if (total == 0) {
      return;
    }
    final unit = (to - from) / total;
    var travelled = 0.0;
    var drawing = true;
    while (travelled < total) {
      final step = math.min(kEventAnnotationDashArray.first, total - travelled);
      if (drawing) {
        canvas.drawLine(
          from + unit * travelled,
          from + unit * (travelled + step),
          paint,
        );
      }
      travelled += step;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(FluentEventAnnotationPainter oldDelegate) =>
      !listEquals(oldDelegate.rules, rules) ||
      oldDelegate.labels.length != labels.length ||
      oldDelegate.lineTop != lineTop ||
      oldDelegate.lineBottom != lineBottom ||
      oldDelegate.textBaseline != textBaseline ||
      oldDelegate.labelWidth != labelWidth ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.textStyle != textStyle;
}

/// LineChart's event annotation overlay: a dashed rule per date, with packed
/// labels above the plot.
///
/// Ports `EventsAnnotation` (`EventAnnotation.tsx`), `LabelLink` and `Textbox`.
///
/// Clicking a label does nothing, deliberately: `LabelLink.tsx:35-59` is a
/// commented-out v8 `Callout` block with `callout = null` beside a
/// `TODO - need to replace callout with popover`, and `onRenderCard` is
/// collected and never rendered. [FluentEventAnnotation.cardBuilder] is
/// therefore accepted and ignored. `// parity:` `LabelLink.tsx:35-59` —
/// implementing it would be new behaviour, not a port.
class FluentEventAnnotationLayer extends StatelessWidget {
  /// Creates an event annotation overlay.
  const FluentEventAnnotationLayer({
    required this.events,
    required this.xScale,
    required this.chartTop,
    required this.chartBottom,
    required this.mergedLabel,
    super.key,
    this.strokeColor,
    this.labelColor,
    this.labelHeight = kEventAnnotationLineHeight,
    // EventAnnotation.tsx:17 — 105, not the 110 the packer works in.
    this.labelWidth = kEventAnnotationDefaultLabelWidth,
  });

  /// The events to mark.
  final List<FluentEventAnnotation> events;

  /// The chart's x scale.
  final Scale xScale;

  /// Top of the plot area.
  final double chartTop;

  /// Bottom of the plot area.
  final double chartBottom;

  /// Rule colour, or null for `colorNeutralForeground1`.
  /// `EventAnnotation.tsx:29-31`.
  final Color? strokeColor;

  /// Label colour, or null for `colorNeutralForeground1`.
  /// `LabelLink.tsx:62-64`.
  final Color? labelColor;

  /// Line height of a wrapped label.
  ///
  /// `EventsAnnotationProps.labelHeight` (`LineChart.types.ts:106`) is declared
  /// upstream and never read; `EventAnnotation.tsx:21` hard-codes 18 instead.
  /// ponytail: wired to the real line height here, because a dead prop on a
  /// public API is worse than a live one and the default is unchanged.
  final double labelHeight;

  /// Width the labels wrap at.
  final double labelWidth;

  /// The text for a label speaking for several events.
  /// `LineChart.types.ts:108` — required, with no default.
  final String Function(int count) mergedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    // EventAnnotation.tsx:27 — ascending by date, before anything else.
    final sorted = List<FluentEventAnnotation>.of(events)
      ..sort((a, b) => a.date.compareTo(b.date));
    final positions = <double>[
      for (final event in sorted) xScale(event.date.millisecondsSinceEpoch)!,
    ];

    // EventAnnotation.tsx:33 — the RULES are deduplicated by date, but the
    // labels still see every event.
    final seen = <int>{};
    final rules = <Offset>[
      for (var i = 0; i < sorted.length; i++)
        if (seen.add(sorted[i].date.millisecondsSinceEpoch))
          Offset(positions[i], 0),
    ];

    final range = xScale.range;
    final placements = fluentPackEventAnnotationLabels(
      positions,
      // EventAnnotation.tsx:37 — textWidth + textPadding.
      labelWidth + kEventAnnotationTextPadding,
      range.last,
      range.first,
    );

    return IgnorePointer(
      child: CustomPaint(
        painter: FluentEventAnnotationPainter(
          rules: rules,
          labels: <FluentEventLabel>[
            for (final placement in placements)
              FluentEventLabel(
                // LabelLink.tsx:66-70.
                text: placement.aggregatedIndices.length == 1
                    ? sorted[placement.aggregatedIndices.single].event
                    : mergedLabel(placement.aggregatedIndices.length),
                x: placement.x,
                anchor: placement.anchor,
              ),
          ],
          lineTop: chartTop - kEventAnnotationLineTopOffset,
          lineBottom: chartBottom,
          textBaseline: chartTop - kEventAnnotationTextTopOffset,
          labelWidth: labelWidth,
          strokeColor: strokeColor ?? theme.colors.neutralForeground1,
          labelColor: labelColor ?? theme.colors.neutralForeground1,
          // EventAnnotation.tsx:22 — '10pt', which is 10 * 96 / 72 = 13.33px.
          textStyle: FluentChartTextStyles.of(theme).markerLabel.copyWith(
            fontSize: 10 * 96 / 72,
            height: labelHeight / (10 * 96 / 72),
          ),
        ),
      ),
    );
  }
}
