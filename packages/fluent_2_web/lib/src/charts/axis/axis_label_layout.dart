import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../internal/chart_text_measurer.dart';
import '../internal/d3/scale.dart' as d3;
import '../model/chart_value.dart';
import 'axis_types.dart';

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
    this.rotationTranslateY = 0,
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

  /// The distance every tick group is pushed down before it is rotated, in
  /// logical pixels; zero when [rotationRadians] is zero.
  ///
  /// `utilities.ts:1839` writes `translate(x, maxHeight / 2)rotate(-45)`, where
  /// `maxHeight` is the tallest rotated tick box **before** [reserveHeight]
  /// floors it. The two are therefore not interchangeable: `reserveHeight` is
  /// `floor(maxHeight / 1.414)` (`:1845`), and inverting that floor back through
  /// 1.414 costs up to 0.71 logical pixels — seventy times the geometry
  /// tolerance the Oracle B corpus is asserted at. So the un-rounded figure
  /// travels here rather than being re-derived downstream.
  final double rotationTranslateY;
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

/// Wraps or truncates x-axis tick labels and reports the height they cost.
///
/// Ports `createWrapOfXLabels` (`utilities.ts:1121-1190`).
///
/// * In tooltip mode the label becomes a single truncated line and the height
///   computation is skipped entirely (`:1156-1157`, `:1180`).
/// * Otherwise the label is greedily wrapped on whitespace, breaking only when
///   the accumulated line exceeds the width **and** holds more than one word
///   (`:1165`), so a single long word overflows rather than splitting.
/// * Each new line adds `1.1` ems to the base `dy` (`:1145`, `:1173`).
/// * The reserved height is `(maxLines - 1) * maxHeight` where `maxHeight`
///   starts at `12` and rises to the measured line height (`:1181-1187`).
///   Upstream samples the *first* tspan in the container rather than the tallest;
///   with one axis text style that is the same number, and the port measures the
///   resolved style once.
///
/// [width] is a `double` applied to every tick or a `List<double>` indexed by
/// tick, matching the upstream `number | number[]` union (`:127`, dispatched at
/// `:1159` and defaulted to `DEFAULT_WRAP_WIDTH` at `:1127`).
FluentXAxisLabelLayout wrapXLabels(
  List<String> labels, {
  required FluentChartTextMeasurer measurer,
  required TextStyle style,
  required int noOfCharsToTruncate,
  required bool showXAxisLabelsTooltip,
  Object width = kDefaultWrapWidth,
  double baseDyEm = 0.71,
}) {
  assert(
    width is double || width is List<double>,
    'width is the number | number[] union at utilities.ts:127.',
  );
  // 1.1 ems is the line height at utilities.ts:1145.
  const lineHeightEm = 1.1;

  var maxLines = 1;
  final laidOut = <FluentAxisTickLabel>[];

  for (final (tickIndex, label) in labels.indexed) {
    if (showXAxisLabelsTooltip) {
      // utilities.ts:1157 compares the whole length against the budget, so a
      // label of exactly noOfCharsToTruncate code units is left alone.
      final truncated = label.length > noOfCharsToTruncate;
      final text = truncated
          ? '${label.substring(0, noOfCharsToTruncate)}...'
          : label;
      laidOut.add(
        FluentAxisTickLabel(
          lines: <FluentAxisLabelLine>[
            FluentAxisLabelLine(text: text, dyEm: baseDyEm),
          ],
          fullText: label,
          truncated: truncated,
        ),
      );
      continue;
    }

    // utilities.ts:1159 indexes the array by tick and JavaScript yields
    // undefined past its end, which `labelWidth > undefined` turns into a
    // never-break comparison; the port falls back to the documented default
    // instead of wrapping on a NaN.
    final maxWidth = width is List<double>
        ? (tickIndex < width.length ? width[tickIndex] : kDefaultWrapWidth)
        : width as double;
    final words = label.split(RegExp(r'\s+'));
    final lines = <FluentAxisLabelLine>[];
    var current = <String>[];
    var lineNumber = 0;

    for (final word in words) {
      current.add(word);
      final candidate = current.join(' ');
      if (measurer.width(candidate, style) > maxWidth && current.length > 1) {
        current.removeLast();
        lines.add(
          FluentAxisLabelLine(
            text: current.join(' '),
            dyEm: lineNumber * lineHeightEm + baseDyEm,
          ),
        );
        lineNumber += 1;
        current = <String>[word];
      }
    }
    lines.add(
      FluentAxisLabelLine(
        text: current.join(' '),
        dyEm: lineNumber * lineHeightEm + baseDyEm,
      ),
    );

    maxLines = math.max(maxLines, lineNumber + 1);
    laidOut.add(
      FluentAxisTickLabel(
        lines: lines,
        fullText: label,
        // A wrapped label renders as several lines rather than the one string in
        // fullText, which is the difference utilities.ts:1301-1304 tests before
        // it attaches a tooltip.
        truncated: lines.length > 1,
      ),
    );
  }

  if (showXAxisLabelsTooltip) {
    return FluentXAxisLabelLayout(
      labels: laidOut,
      reserveHeight: 0,
      rotationRadians: 0,
    );
  }

  // 12 is the seed at utilities.ts:1181, described there as the value needed to
  // render correctly on the first pass.
  var maxHeight = 12.0;
  if (labels.isNotEmpty) {
    final boxHeight = measurer.measure(labels.first, style).height;
    if (boxHeight > maxHeight) {
      maxHeight = boxHeight;
    }
  }
  final removeVal = (maxLines - 1) * maxHeight;

  return FluentXAxisLabelLayout(
    labels: laidOut,
    // utilities.ts:1189 clamps the reservation at zero.
    reserveHeight: removeVal > 0 ? removeVal : 0,
    rotationRadians: 0,
  );
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
///
/// That arm is the port's *normal* path. Upstream guards its only call with
/// `props.showYAxisLablesTooltip` (`CartesianChart.tsx:396`) and then passes the
/// same flag back in as `truncateLabel` (`:404`), so the two can never disagree
/// and the blank-axis branch is unreachable there. `cartesian_painter.dart:137`
/// folds the guard into the argument and calls this unconditionally, because
/// the full label this returns when the flag is off is exactly the d3 tick text
/// upstream leaves standing when it skips the call.
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

/// Rotates x-axis tick labels by forty-five degrees and reports the height they
/// cost.
///
/// Ports `rotateXAxisLabels` (`utilities.ts:1801-1846`). Upstream measures the
/// *rendered* bounding box of each rotated tick group — which contains both the
/// tick line and the text — and returns `floor(maxHeight / 1.414)`, the vertical
/// extent of a label at forty-five degrees. The port re-derives that box: the
/// tick line runs from the origin to [tickSizeInner] and the text box sits at
/// `spacing = max(tickSizeInner, 0) + tickPadding` with the axis's base `dy`
/// (`d3-axis/src/axis.js:46` and `:72`, the same rule the kernel's
/// `FluentAxisGeometry.spacing` applies), centred on x because a bottom axis
/// anchors its text in the middle.
///
/// `getBoundingClientRect` maps an element's *object bounding box* through the
/// screen matrix, so the rotated extent is that of the whole enclosing
/// rectangle, corners included where no glyph sits. Oracle B story
/// `charts-verticalbarchart--vertical-bar-rotate-labels` settles it: its widest
/// tick group captured a `getBBox` of `[-89.59375, 0, 179.1875, 26.1]` and a
/// `translate(…, 72.58009338378906)`, and since upstream translates by
/// `maxHeight / 2` (`:1839`) the browser's `maxHeight` was `145.16018…`. The
/// rectangle gives `cos(45) * (179.1875 + 26.1) = 145.1597…`; taking the union
/// of the tick-line box and the text box instead gives `136.6`, which is wrong
/// by nine pixels. The plan's Step 3 listed the six union corners, so this is a
/// deliberate divergence from the plan in favour of the captured geometry.
///
/// There is no RTL branch upstream — the rotation is always `-45` degrees
/// (`:1820`, `:1839`).
FluentXAxisLabelLayout rotateXAxisLabels(
  List<String> labels, {
  required FluentChartTextMeasurer measurer,
  required TextStyle style,
  double tickSizeInner = 6,
  double tickPadding = 10,
  double baseDyEm = 0.71,
}) {
  const rotation = -math.pi / 4;
  final cosine = math.cos(rotation);
  // fontSize is null only for a style with no size at all; 10 is the axis-tick
  // size (`utilities.ts:1267`).
  final fontSize = style.fontSize ?? 10;
  final spacing = math.max(tickSizeInner, 0.0) + tickPadding;
  final baseline = spacing + baseDyEm * fontSize;

  var maxHeight = 0.0;
  final laidOut = <FluentAxisTickLabel>[];

  for (final label in labels) {
    final metrics = measurer.measure(label, style);
    // The tick group's local bounding rectangle: x spans the centred text box
    // and y spans the tick line together with the text's ascent and descent.
    final localWidth = metrics.width;
    final localHeight =
        math.max(tickSizeInner, baseline + metrics.descent) -
        math.min(0.0, baseline - metrics.ascent);
    // Rotating that rectangle by -45 degrees maps a corner to
    // `-x * cos(45) + y * cos(45)`, so the vertical spread between the extreme
    // corners is `cos(45) * (localWidth + localHeight)`.
    maxHeight = math.max(maxHeight, cosine * (localWidth + localHeight));

    laidOut.add(
      FluentAxisTickLabel(
        lines: <FluentAxisLabelLine>[
          FluentAxisLabelLine(text: label, dyEm: baseDyEm),
        ],
        fullText: label,
        truncated: false,
      ),
    );
  }

  // 1.414 is the divisor at utilities.ts:1845 — the tangent-inverse of 45
  // degrees, giving the vertical height of the rotated labels. Upstream writes
  // that literal rather than sqrt(2), so the port keeps it; it is confined to
  // reserveHeight, and the translate below carries the un-floored maxHeight so
  // no rounded intermediate reaches a geometry calculation.
  return FluentXAxisLabelLayout(
    labels: laidOut,
    reserveHeight: (maxHeight / 1.414).floorToDouble(),
    rotationRadians: rotation,
    // 2 is the halving at utilities.ts:1839.
    rotationTranslateY: maxHeight / 2,
  );
}

/// The widest tick label, measured after whatever transform the axis will apply.
///
/// Ports `_calcMaxLabelWidthWithTransform` (`CartesianChart.tsx:576-612`). The
/// four branches run in this order and the first match wins: rotated band labels
/// shrink by `cos(pi/4)`; tooltip mode measures the truncated form; wrapping mode
/// measures individual **words** and floors the answer at [kDefaultWrapWidth];
/// otherwise the labels are measured as they are. Every branch ceils.
double calcMaxLabelWidthWithTransform(
  List<String> labels, {
  required FluentChartTextMeasurer measurer,
  required TextStyle style,
  required FluentChartAxisType xAxisType,
  bool wrapXAxisLabels = false,
  bool rotateXAxisLabels = false,
  bool showXAxisLabelsTooltip = false,
  int noOfCharsToTruncate = 4,
}) {
  if (!wrapXAxisLabels &&
      rotateXAxisLabels &&
      xAxisType == FluentChartAxisType.category) {
    final longest = measurer.longestWidth(labels, style);
    return (longest * math.cos(math.pi / 4)).ceilToDouble();
  }

  if (showXAxisLabelsTooltip) {
    final truncated = <String>[
      // CartesianChart.tsx:587 compares the whole length against the budget, so
      // a label of exactly noOfCharsToTruncate code units is left alone.
      for (final label in labels)
        if (label.length > noOfCharsToTruncate)
          '${label.substring(0, noOfCharsToTruncate)}...'
        else
          label,
    ];
    return measurer.longestWidth(truncated, style).ceilToDouble();
  }

  if (wrapXAxisLabels) {
    // FIXME upstream: CartesianChart.tsx:596-597 notes this measures words
    // rather than wrapped lines, which is close enough because overflow only
    // happens when a single word exceeds the width.
    final words = <String>[
      for (final label in labels) ...label.split(RegExp(r'\s+')),
    ];
    return math.max(
      measurer.longestWidth(words, style).ceilToDouble(),
      kDefaultWrapWidth,
    );
  }

  return measurer.longestWidth(labels, style).ceilToDouble();
}

/// The centre of the mark for [index], which is the band centre on a band scale
/// and the plain scale position otherwise.
///
/// Ports the `getTickPosition` closures at `utilities.ts:2595-2597` and
/// `:2663-2665`. Note that these two *do* centre the band, while the
/// anti-collision sweep in `createStringXAxis` (`:610`) does not — an
/// inconsistency reproduced on both sides.
///
/// A continuous scale reports a bandwidth of zero, which is what upstream's
/// `'bandwidth' in scale` guard amounts to. A band-domain miss returns null,
/// and the `?? 0` mirrors upstream's own nullish coalescing.
double _tickCentre(d3.Scale scale, List<Object> tickValues, int index) {
  final position = scale(tickValues[index]) ?? 0.0;
  return position + scale.bandwidth / 2;
}

/// Truncates every label to its slot and staggers alternate labels onto a second
/// line.
///
/// Ports `truncateAndStaggerXAxisLabels` (`utilities.ts:2644-2694`). The slot is
/// `min(leftGap, rightGap) * 2 - 8` using the **full** inter-tick gaps — the
/// halving that [autoLayoutXAxisLabels] applies is deliberately absent here
/// (`:2675-2676`), because staggering means neighbouring labels no longer share
/// a line. Odd-indexed labels drop by `1.1` ems (`:2680` and `:2688`).
///
/// Upstream returns 0 outright when the axis node is missing (`:2652-2654`);
/// the port has no node, so that guard has no analogue.
FluentXAxisLabelLayout truncateAndStaggerXAxisLabels(
  List<Object> tickValues,
  List<String> tickLabels,
  d3.Scale scale,
  double containerWidth, {
  required FluentChartTextMeasurer measurer,
  required TextStyle style,
  double baseDyEm = 0.71,
}) {
  // 12 is the seed at utilities.ts:2656; 1.1 ems is the stagger at :2680;
  // 8 is the four-pixel padding on both sides at :2677.
  var maxHeight = 12.0;
  const lineHeightEm = 1.1;
  const slotPadding = 8.0;

  final range = scale.range;
  final isRtl = range.last - range.first < 0;
  final start = isRtl ? containerWidth : 0.0;
  final end = isRtl ? 0.0 : containerWidth;

  final laidOut = <FluentAxisTickLabel>[];
  for (var i = 0; i < tickValues.length; i++) {
    final position = _tickCentre(scale, tickValues, i);
    final leftSpace =
        (i > 0
                ? position - _tickCentre(scale, tickValues, i - 1)
                : position - start)
            .abs();
    final rightSpace =
        (i + 1 < tickValues.length
                ? _tickCentre(scale, tickValues, i + 1) - position
                : end - position)
            .abs();
    final maxAvailableWidth = math.min(leftSpace, rightSpace) * 2 - slotPadding;
    final label = tickLabels[i];
    final text = truncateTextToFitWidth(
      label,
      maxAvailableWidth,
      (candidate) => measurer.width(candidate, style),
    );
    maxHeight = math.max(maxHeight, measurer.measure(label, style).height);
    laidOut.add(
      FluentAxisTickLabel(
        lines: <FluentAxisLabelLine>[
          FluentAxisLabelLine(
            text: text,
            dyEm: (i.isOdd ? lineHeightEm : 0.0) + baseDyEm,
          ),
        ],
        fullText: label,
        truncated: text != label,
      ),
    );
  }

  return FluentXAxisLabelLayout(
    labels: laidOut,
    reserveHeight: tickValues.length > 1 ? maxHeight : 0,
    rotationRadians: 0,
  );
}

/// Decides between wrapping, truncating with a stagger, or leaving the labels
/// alone.
///
/// Ports `autoLayoutXAxisLabels` (`utilities.ts:2578-2642`), which runs when
/// `xAxis.tickLayout` is `'auto'` (`CartesianChart.tsx:282-290`). Each label gets
/// a slot of `min(halfLeftGap, halfRightGap) * 2 - 8`; a label wider than its
/// slot triggers wrapping if its longest word still fits, and truncation
/// otherwise. Truncation wins when both are needed (`:2623-2625`).
///
/// The halving at `:2605-2606` applies to the *interior* gaps only: the leading
/// tick's left gap and the trailing tick's right gap reach the container edge
/// and are taken whole, because `Math.abs` wraps the ternary rather than each
/// branch.
FluentXAxisLabelLayout autoLayoutXAxisLabels(
  List<Object> tickValues,
  List<String> tickLabels,
  d3.Scale scale,
  double containerWidth, {
  required FluentChartTextMeasurer measurer,
  required TextStyle style,
  double baseDyEm = 0.71,
}) {
  // 8 is the four-pixel padding on both sides at utilities.ts:2607.
  const slotPadding = 8.0;
  final range = scale.range;
  final isRtl = range.last - range.first < 0;
  final start = isRtl ? containerWidth : 0.0;
  final end = isRtl ? 0.0 : containerWidth;

  var requiresWrap = false;
  var requiresTruncate = false;
  final maxWidths = <double>[];

  for (var i = 0; i < tickValues.length; i++) {
    final position = _tickCentre(scale, tickValues, i);
    // 2 halves the interior gap so that two neighbouring labels sharing one
    // line cannot overlap (utilities.ts:2605).
    final leftSpace =
        (i > 0
                ? (position - _tickCentre(scale, tickValues, i - 1)) / 2
                : position - start)
            .abs();
    final rightSpace =
        (i + 1 < tickValues.length
                ? (_tickCentre(scale, tickValues, i + 1) - position) / 2
                : end - position)
            .abs();
    final maxAvailableWidth = math.min(leftSpace, rightSpace) * 2 - slotPadding;
    maxWidths.add(maxAvailableWidth);

    final label = tickLabels[i];
    if (measurer.width(label, style) > maxAvailableWidth) {
      final longestWordWidth = measurer.longestWidth(
        label.split(RegExp(r'\s+')),
        style,
      );
      if (longestWordWidth <= maxAvailableWidth) {
        requiresWrap = true;
      } else {
        requiresTruncate = true;
      }
    }
  }

  if (requiresTruncate) {
    return truncateAndStaggerXAxisLabels(
      tickValues,
      tickLabels,
      scale,
      containerWidth,
      measurer: measurer,
      style: style,
      baseDyEm: baseDyEm,
    );
  }

  if (requiresWrap) {
    // 100 is the noOfCharsToTruncate upstream passes here (utilities.ts:2633) —
    // effectively "never truncate", since the tooltip branch is off.
    return wrapXLabels(
      tickLabels,
      measurer: measurer,
      style: style,
      noOfCharsToTruncate: 100,
      showXAxisLabelsTooltip: false,
      width: maxWidths,
      baseDyEm: baseDyEm,
    );
  }

  return FluentXAxisLabelLayout(
    labels: <FluentAxisTickLabel>[
      for (final label in tickLabels)
        FluentAxisTickLabel(
          lines: <FluentAxisLabelLine>[
            FluentAxisLabelLine(text: label, dyEm: baseDyEm),
          ],
          fullText: label,
          truncated: false,
        ),
    ],
    reserveHeight: 0,
    rotationRadians: 0,
  );
}
