import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../overlays/popover.dart';
import '../../overlays/popover_style.dart';
import '../axis/tick_format.dart';
import '../internal/snap_to_device_pixels.dart';
import '../model/callout_data.dart';
import 'chart_popover_style.dart';
import 'legend_shape.dart';

/// The reading a chart popover displays.
///
/// Ports `ChartPopoverProps` (`ChartPopover.types.ts:5-28`) minus the props
/// that only exist to configure the React positioning layer.
///
/// Every text field is already formatted by the chart. Upstream calls
/// `formatToLocaleString` inside the popover (`ChartPopover.tsx:80`, `:89`,
/// `:128`), but the frozen contract types these as `String?`, which moves the
/// call to the chart. [yValues] is the exception: its readings are still
/// numeric, so the multi-value body formats them itself, in [culture].
@immutable
class FluentChartPopoverData {
  /// Creates a popover reading.
  const FluentChartPopoverData({
    this.xValue,
    this.yValues,
    this.legend,
    this.color,
    this.yValue,
    this.ratio,
    this.descriptionMessage,
    this.isCalloutForStack = false,
    this.customContentBuilder,
    this.culture,
    this.isCartesian = true,
    this.contentMaxWidth,
  });

  /// The x reading, shown at the top. `ChartPopover.tsx:63`.
  final String? xValue;

  /// Every series' reading at this x, for the stacked body.
  final List<FluentYValueHover>? yValues;

  /// The series name. `ChartPopover.tsx:43` prefers `xCalloutValue` over
  /// `legend`, which the chart resolves before constructing this.
  final String? legend;

  /// The series colour. Paints the accent bar and the y reading.
  final Color? color;

  /// The y reading. `ChartPopover.tsx:44` prefers `yCalloutValue` over
  /// `YValue`, again resolved by the chart.
  final String? yValue;

  /// An optional `numerator / denominator` pair. `ChartPopover.tsx:92-104`.
  final (double, double)? ratio;

  /// A trailing message under a rule. `ChartPopover.tsx:106-108`.
  final String? descriptionMessage;

  /// Whether to render the multi-value body. `ChartPopover.tsx:57`.
  final bool isCalloutForStack;

  /// A replacement body. `ChartPopover.tsx:54` renders it *in addition to*
  /// nothing else — both other branches are gated on its absence at `:56` and
  /// `:60` — so it wins outright.
  final WidgetBuilder? customContentBuilder;

  /// BCP-47 locale the multi-value body formats [yValues] in, `props.culture`
  /// (`ChartPopover.tsx:189-190`, `:233`, `:259`). Null formats them in the
  /// default locale.
  final String? culture;

  /// Whether the y reading takes the cartesian class, `subtitle2Stronger`,
  /// rather than `title2` (`useChartPopoverStyles.styles.ts:147-151`).
  ///
  /// Only seven charts pass `isCartesian` — `LineChart.tsx:1895`,
  /// `VerticalBarChart.tsx:1142`, `AreaChart.tsx:1094`, `ScatterChart.tsx:697`,
  /// `GroupedVerticalBarChart.tsx:446`, `HorizontalBarChartWithAxis.tsx:893`
  /// and `VerticalStackedBarChart.tsx:1360` — so every other chart's popover
  /// reads `false`.
  final bool isCartesian;

  /// A cap on the body's width inside the surface padding: the `maxWidth` a
  /// chart puts on `calloutContentRoot` through the popover's `styles` prop,
  /// the one slot `useChartPopoverStyles.styles.ts:119` leaves live.
  /// HeatMapChart caps it at 238 (`HeatMapChart.tsx:781-783`,
  /// `useHeatMapChartStyles.styles.ts:35-37`).
  final double? contentMaxWidth;
}

/// Applies a [FluentChartPopoverStyle] to every chart popover below it.
class FluentChartPopoverTheme extends InheritedTheme {
  /// Applies [style] to every chart popover in [child].
  const FluentChartPopoverTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the theme-derived defaults.
  final FluentChartPopoverStyle style;

  /// The nearest chart popover style, or null.
  static FluentChartPopoverStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentChartPopoverTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentChartPopoverTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentChartPopoverTheme(style: style, child: child);
}

/// Builds the default single-value popover body. `ChartPopover.tsx:60-110`.
///
/// [fallbackForeground] is `colorNeutralForeground1`, the false arm of
/// `ChartPopover.tsx:85`.
Widget buildFluentChartPopoverSingleValue(
  FluentChartPopoverData data,
  FluentChartPopoverStyle style,
  Color fallbackForeground,
) {
  const states = <WidgetState>{};
  final accentColour = data.color ?? fallbackForeground;
  final xValue = data.xValue;

  final block = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _popoverLegend(data.legend, style),
      Text(
        data.yValue ?? '',
        style: _withInlineFontSize(
          style.valueTextStyle!.resolve(states)!,
          style.valueFontSize!.resolve(states)!,
        ).copyWith(color: accentColour),
      ),
    ],
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // ChartPopover.tsx:62-66 renders `{props.XValue} `: a lone reading in a
      // flex row whose `space-between` has nothing to spread. Without a
      // reading the div holds only collapsible whitespace, which lays out no
      // line box, so HorizontalBarChart, DonutChart and HeatMapChart callouts
      // start at the accent bar.
      if (xValue != null && xValue.isNotEmpty)
        Text(xValue, style: style.xTextStyle!.resolve(states)),
      Padding(
        padding: EdgeInsets.only(
          top: style.accentBarMarginTop!.resolve(states)!,
        ),
        // ChartPopover.tsx:74 puts the 4px border on calloutInfoContainer
        // itself, so it spans the container however tall its children make it.
        // A Flutter child can only match its siblings' height under
        // CrossAxisAlignment.stretch, which in turn needs a bounded cross
        // extent — hence IntrinsicHeight.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                key: const ValueKey<String>('popover-accent-bar'),
                width: style.accentBarWidth!.resolve(states),
                decoration: BoxDecoration(color: accentColour),
              ),
              // useChartPopoverStyles.styles.ts:104 — spacingHorizontalS is 8.
              const SizedBox(width: FluentSpacing.s),
              // A Row lays a non-flexible child out with an unbounded main
              // axis, so a long legend would run past the surface rather than
              // wrap. Upstream wraps it: calloutBlockContainer is a block-level
              // div (useChartPopoverStyles.styles.ts:49-52) whose grid root
              // clips (`overflow: hidden`, :35) and whose surface is capped at
              // the available box by `autoSize: 'always'` (ChartPopover.tsx:48).
              Flexible(child: block),
              if (data.ratio != null)
                // ChartPopover.tsx:70-73 — a ratio switches the container to
                // `alignItems: flex-end`. The block is the tallest child, so
                // the only visible effect is the ratio dropping to the bottom.
                Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: style.ratioMarginStart!.resolve(states)!,
                    ),
                    child: DefaultTextStyle.merge(
                      style: style.ratioTextStyle!.resolve(states),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _trimTrailingZero(data.ratio!.$1),
                            style: style.ratioPartTextStyle!.resolve(states),
                          ),
                          const Text('/'),
                          Text(
                            _trimTrailingZero(data.ratio!.$2),
                            style: style.ratioPartTextStyle!.resolve(states),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (data.descriptionMessage != null)
        Container(
          key: const ValueKey<String>('popover-description-rule'),
          margin: EdgeInsets.only(top: style.descriptionGap!.resolve(states)!),
          padding: EdgeInsets.only(top: style.descriptionGap!.resolve(states)!),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: style.descriptionDividerColor!.resolve(states)!,
                // useChartPopoverStyles.styles.ts:90 — a 1px rule.
                width: FluentStroke.thin,
              ),
            ),
          ),
          child: Text(
            data.descriptionMessage!,
            style: style.descriptionTextStyle!.resolve(states),
          ),
        ),
    ],
  );
}

/// A series name over its 4px gap to the reading below.
///
/// `calloutLegendText` carries `marginBottom: spacingVerticalXS`
/// (`useChartPopoverStyles.styles.ts:70-75`). An empty one keeps that margin
/// and nothing else, because a div with no text lays out no line box — the
/// Funnel and Sankey link callouts have no legend.
Widget _popoverLegend(String? legend, FluentChartPopoverStyle style) => Padding(
  padding: const EdgeInsets.only(bottom: FluentSpacing.xs),
  child: legend == null || legend.isEmpty
      ? null
      : Text(
          legend,
          style: style.legendTextStyle!.resolve(const <WidgetState>{}),
        ),
);

/// [base] at [fontSize], keeping its line height in pixels.
///
/// `ChartPopover.tsx:86` sets `fontSize` inline and leaves `line-height` to
/// the class, which the ramp states in pixels: 22 for `subtitle2Stronger`, 36
/// for `title2`. A Flutter height is a multiple of the font size and would
/// scale with it — 1.375 turns the cartesian 22px line into 38.5.
TextStyle _withInlineFontSize(TextStyle base, double fontSize) {
  final height = base.height;
  final size = base.fontSize;
  return base.copyWith(
    fontSize: fontSize,
    height: height == null || size == null ? null : height * size / fontSize,
  );
}

/// Whether any reading carries a subcount breakdown rather than a plain string.
///
/// `_yValueHoverSubCountsExists` (`ChartPopover.tsx:167-179`). The upstream
/// test is `yAxisCalloutData && typeof yAxisCalloutData !== 'string'`
/// (`:176`); the contract splits that union into `yAxisCalloutText` and
/// `yAxisCalloutBreakdown`, so the test is simply whether the latter is set.
bool fluentChartPopoverHasSubCounts(List<FluentYValueHover>? values) =>
    values?.any((value) => value.yAxisCalloutBreakdown != null) ?? false;

/// The marker for a series at [index] in the multi-value popover.
///
/// `ChartPopover.tsx:216` is `Points[index % Object.keys(pointTypes).length]`.
/// `pointTypes` has exactly eight keys (`utilities.ts:1747-1772`), so the
/// modulus is 8 and `dottedLine` — a `CustomPoints` member (`utilities.ts:1725`)
/// with no `pointTypes` entry — is unreachable from here.
FluentChartLegendShape fluentChartPopoverShapeForIndex(int index) =>
    // The eight Points members, in their declared ordinal order
    // (utilities.ts:1714-1721).
    const <FluentChartLegendShape>[
      FluentChartLegendShape.circle,
      FluentChartLegendShape.square,
      FluentChartLegendShape.triangle,
      FluentChartLegendShape.diamond,
      FluentChartLegendShape.pyramid,
      FluentChartLegendShape.hexagon,
      FluentChartLegendShape.pentagon,
      FluentChartLegendShape.octagon,
    ][index % 8];

/// Builds the stacked popover body. `ChartPopover.tsx:116-165`.
///
/// [fallbackForeground] is `colorNeutralForeground1`, the false arm of
/// `ChartPopover.tsx:257`.
Widget buildFluentChartPopoverMultiValue(
  FluentChartPopoverData data,
  FluentChartPopoverStyle style,
  Color fallbackForeground,
) {
  const states = <WidgetState>{};
  final values = data.yValues ?? const <FluentYValueHover>[];
  final hasSubCounts = fluentChartPopoverHasSubCounts(values);

  final rows = <Widget>[
    for (var index = 0; index < values.length; index++)
      _popoverRow(
        values[index],
        style,
        fallbackForeground,
        popoverColour: data.color,
        culture: data.culture,
        hasSubCounts: hasSubCounts,
        // ChartPopover.tsx:187 — every column but the last carries a 16px
        // trailing margin.
        isLast: index == values.length - 1,
      ),
  ];

  // ChartPopover.tsx:128 formats `hoverXValue`, which upstream's charts hand
  // over raw. Here the chart has already formatted it, as it has every text
  // field, and formatting it again would read a de-DE `15.000` back as 15.
  final xValue = data.xValue ?? '';

  // `calloutContentRoot` is a grid (useChartPopoverStyles.styles.ts:34), so
  // every block in it — each row wrapper included — is as wide as the widest,
  // and a row's bottom rule runs the full width of the body.
  return IntrinsicWidth(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          // ChartPopover.tsx:122 — 11px below the date container, but only
          // when subcounts exist. The same 11 as the single-value accent bar
          // margin. An empty reading lays out no line box, as at :63.
          padding: EdgeInsets.only(
            bottom: hasSubCounts ? kChartPopoverAccentBarMarginTop : 0,
          ),
          child: xValue.isEmpty
              ? null
              : Text(xValue, style: style.xTextStyle!.resolve(states)),
        ),
        // ChartPopover.tsx:131 — subcounts lay the rows out as a flex row;
        // otherwise they stack.
        if (hasSubCounts)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: rows,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: rows,
          ),
        // ChartPopover.tsx:161 renders the description INSIDE the row wrapper
        // here, unlike the single-value path where it is a sibling at :106.
        if (data.descriptionMessage != null)
          Text(
            data.descriptionMessage!,
            style: style.descriptionTextStyle!.resolve(states),
          ),
      ],
    ),
  );
}

Widget _popoverRow(
  FluentYValueHover value,
  FluentChartPopoverStyle style,
  Color fallbackForeground, {
  required Color? popoverColour,
  required String? culture,
  required bool hasSubCounts,
  required bool isLast,
}) {
  const states = <WidgetState>{};
  // ChartPopover.tsx:188.
  final toDrawShape = value.index != null && value.index != -1;
  final colour = value.color ?? fallbackForeground;
  // ChartPopover.tsx:189-190.
  final y = formatToLocaleString(value.y, culture: culture);
  final reading = value.yAxisCalloutText ?? y;
  // ChartPopover.tsx:196 and :246 both render `{legend} ({y})`.
  final header = Text(
    '${value.legend ?? ''} ($y)',
    style: style.valueTextStyle!
        .resolve(states)!
        .copyWith(
          fontSize: kChartPopoverSubHeaderFontSize,
          // ChartPopover.tsx:195 and :245 pair the size with
          // `ms-fontWeight-semibold`, a v8 class name that has no v9 rule, so the
          // weight never lands. // parity: not applied.
        ),
  );

  final body = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // ChartPopover.tsx:228 renders ` {xValue.legend}`, whose leading space
      // collapses. Without a shape the block around it is a plain block box, so
      // an empty legend's 4px margin collapses into the row's 13px one and
      // leaves nothing; the shape arm's `inline-grid`
      // (useChartPopoverStyles.styles.ts:66) keeps it.
      if (toDrawShape || (value.legend?.isNotEmpty ?? false))
        _popoverLegend(value.legend, style),
      // ChartPopover.tsx:229 — `direction: ltr; unicode-bidi: isolate` keeps
      // numbers left-to-right under an RTL chart. The multi-value path does NOT
      // apply the 28px inline size the single-value path does.
      Directionality(
        textDirection: TextDirection.ltr,
        child: Text(reading, style: style.valueTextStyle!.resolve(states)),
      ),
    ],
  );

  final marker = Row(
    // The accent bar is a border on the container itself (ChartPopover.tsx:205),
    // so it spans however tall the block makes the row — which in Flutter needs
    // stretch over an IntrinsicHeight, exactly as the single-value path does.
    crossAxisAlignment: toDrawShape
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      if (toDrawShape)
        // A replaced svg, so Chromium paints it from a whole device pixel, as
        // it does the legend's.
        SnapToDevicePixels(
          child: SizedBox(
            // `ChartPopover.tsx:211-217` renders the same `<Shape>` the legend
            // does, and that component sizes its own svg (`shape.tsx:39-40`,
            // `:46-49`) — so the box is the shape viewport, not the legend
            // row's border box. The two coincide at 14 only because
            // `useLegendsStyles.styles.ts:14` makes the swatch border 1px.
            width: kLegendShapeViewportSize,
            height: kLegendShapeViewportSize,
            child: CustomPaint(
              painter: FluentChartLegendShapePainter(
                // ChartPopover.tsx:216 derives the marker from the index alone
                // and never consults `yValue.shape`.
                shape: fluentChartPopoverShapeForIndex(value.index!),
                fill: colour,
                stroke: colour,
                // ChartPopover.tsx:215 passes fill only — no stroke, unlike the
                // legend swatch at Legends.tsx:365.
                strokeWidth: 0,
              ),
            ),
          ),
        )
      else
        // ChartPopover.tsx:205 — no marker means a 4px accent bar instead.
        Container(
          key: const ValueKey<String>('popover-row-accent-bar'),
          width: style.accentBarWidth!.resolve(states),
          decoration: BoxDecoration(color: colour),
        ),
      // useChartPopoverStyles.styles.ts:68 on the shape and :63 on the barred
      // block — spacingHorizontalS is 8 either way.
      const SizedBox(width: FluentSpacing.s),
      // Flexible for the same reason the single-value block is: the row is the
      // only thing that can be arbitrarily wide, and upstream wraps it.
      Flexible(child: body),
    ],
  );

  final withMarker = Padding(
    // ChartPopover.tsx:226 — `marginTop: xValue ? 13px : unset`, and the row is
    // the truthiness test's own subject, so it is always 13. The margin is on
    // the inner block, but the barred block around it (:199-208) has no top
    // border or padding, so it collapses through and the bar starts at the
    // legend: 13px gaps between 42px bars, not bars that touch.
    padding: EdgeInsets.only(top: style.rowMarginTop!.resolve(states)!),
    child: toDrawShape ? marker : IntrinsicHeight(child: marker),
  );

  final subcounts = value.yAxisCalloutBreakdown;
  final content = subcounts == null
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // ChartPopover.tsx:194-198 — the string arm still gets the header
            // when any OTHER row carries subcounts.
            if (hasSubCounts) header,
            withMarker,
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            header,
            for (final entry in subcounts.entries)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _popoverLegend(entry.key, style),
                  // ChartPopover.tsx:257 —
                  // `props.color ? props.color : tokens.colorNeutralForeground1`.
                  // That is the POPOVER-level colour, not the row's: in a
                  // stacked popover every subcount reading takes one colour,
                  // rather than each row's own. The plan specified the row's,
                  // which agrees only when there is a single row or the popover
                  // carries no colour; upstream wins under the bug-fidelity
                  // rule (spec §5.2).
                  Text(
                    formatToLocaleString(entry.value, culture: culture),
                    style: style.valueTextStyle!
                        .resolve(states)!
                        .copyWith(color: popoverColour ?? fallbackForeground),
                  ),
                ],
              ),
          ],
        );

  final row = Padding(
    // ChartPopover.tsx:193 applies marginStyle only under subcounts; the
    // subcount arm at :244 always does, and reaching it implies subcounts.
    padding: EdgeInsetsDirectional.only(
      end: hasSubCounts && !isLast ? style.columnGap!.resolve(states)! : 0,
    ),
    child: content,
  );
  // ChartPopover.tsx:135 — never under the last row.
  if (!value.shouldDrawBorderBottom || isLast) return row;
  // ChartPopover.tsx:144-153 — a 1px colorNeutralStroke2 rule, 10px below the
  // row, on the wrapper that holds it.
  //
  // The ruled wrappers are siblings in the body's Column, and a stack callout
  // can rule several line rows, so the finder key sits one level down where
  // it is unique to its row.
  return Container(
    padding: EdgeInsets.only(bottom: style.rowPaddingBottom!.resolve(states)!),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: style.rowDividerColor!.resolve(states)!,
          width: FluentStroke.thin,
        ),
      ),
    ),
    child: KeyedSubtree(key: kChartPopoverRowRuleKey, child: row),
  );
}

/// Marks the row inside each ruled wrapper, so a test can find the rule as
/// that row's [Container] ancestor.
@visibleForTesting
const Key kChartPopoverRowRuleKey = ValueKey<String>('popover-row-rule');

/// Renders a whole-number double without its `.0`.
///
/// `ratio` is `[number, number]` upstream (`ChartPopover.types.ts:20`) and JS
/// prints `42`, not `42.0`, for an integral value.
String _trimTrailingZero(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

/// Positions a chart popover surface the way `@fluentui/react-positioning`
/// positions `ChartPopover`'s.
///
/// `ChartPopover.tsx:48` passes `autoSize: 'always'`, `offset: 20` and
/// `coverTarget: false`, and no `position`, so Popover's defaults of `above`
/// and `center` apply (`usePopover.js:240-245`). This fills its box, which is
/// the boundary — upstream the chart root, whose `overflow: hidden` makes it
/// the surface's clipping ancestor (`useCartesianChartStyles.styles.ts:44`) —
/// and runs the middleware of `usePositioningOptions.js:78-104` in order:
///
/// 1. `resetMaxSize` (`middleware/maxSize.js:8-35`): the surface is measured
///    at its natural height. Its width is capped at the box's either way,
///    because `size` gives a shifted surface the whole boundary width.
/// 2. `offset` then `flip` with `fallbackStrategy: 'bestFit'`
///    (`middleware/flip.js:13-24`): above the target when it fits there,
///    below when only that fits, and otherwise on the side it overflows less,
///    above on a tie.
/// 3. `shift`: centred on the target, then pushed back inside the box.
/// 4. `maxSize` (`middleware/maxSize.js:46-63`): capped at the room on the
///    chosen side, so a surface that fits neither side is cut short instead of
///    being laid over its own target. [FluentChartPopover] clips its body to
///    match.
///
/// The offset is rounded to device pixels, as `writeContainerupdates.js:28-29`
/// rounds the transform.
class FluentChartPopoverLayout extends SingleChildRenderObjectWidget {
  /// Positions [child] against [target], clearing it by [offset].
  const FluentChartPopoverLayout({
    super.key,
    required this.target,
    required this.offset,
    super.child,
  });

  /// The element the surface positions against, in this box's coordinates.
  ///
  /// A zero-size rect is the virtual element `ChartPopover.tsx:23-34` builds
  /// at the cursor; a hovered mark's bounds are `positioning.target`
  /// (`:35-40`).
  final Rect target;

  /// Clearance between the target and the surface.
  final double offset;

  @override
  RenderFluentChartPopoverLayout createRenderObject(BuildContext context) =>
      RenderFluentChartPopoverLayout(
        target: target,
        offset: offset,
        devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderFluentChartPopoverLayout renderObject,
  ) {
    renderObject
      ..target = target
      ..offset = offset
      ..devicePixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
  }
}

/// The render object behind [FluentChartPopoverLayout].
///
/// A `SingleChildLayoutDelegate` fixes the child's constraints before it has
/// measured the child, so it cannot cap the surface at the room on whichever
/// side the surface's own height picked.
class RenderFluentChartPopoverLayout extends RenderShiftedBox {
  /// Creates the render object.
  RenderFluentChartPopoverLayout({
    required this._target,
    required this._offset,
    required this._devicePixelRatio,
    RenderBox? child,
  }) : super(child);

  /// See [FluentChartPopoverLayout.target].
  Rect get target => _target;
  Rect _target;
  set target(Rect value) {
    if (value == _target) return;
    _target = value;
    markNeedsLayout();
  }

  /// See [FluentChartPopoverLayout.offset].
  double get offset => _offset;
  double _offset;
  set offset(double value) {
    if (value == _offset) return;
    _offset = value;
    markNeedsLayout();
  }

  /// The pixel grid the surface's offset snaps to.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsLayout();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;

    child.layout(BoxConstraints(maxWidth: size.width), parentUsesSize: true);
    final natural = child.size.height;
    final roomAbove = _target.top - _offset;
    final roomBelow = size.height - _target.bottom - _offset;
    // flip.js:13-24 tries `top`, then its opposite, then keeps whichever
    // overflows its main side less; the cross-axis overflow is the same for
    // both, so it never decides.
    final above =
        natural <= roomAbove || (natural > roomBelow && roomAbove >= roomBelow);
    final room = clampDouble(above ? roomAbove : roomBelow, 0, size.height);
    if (natural > room) {
      child.layout(
        BoxConstraints(maxWidth: size.width, maxHeight: room),
        parentUsesSize: true,
      );
    }

    final childSize = child.size;
    // floating-ui's clamp is `max(start, min(value, end))`, so a surface wider
    // than the box keeps its left edge on the box's.
    final dx = math.max(
      0.0,
      math.min(
        _target.center.dx - childSize.width / 2,
        size.width - childSize.width,
      ),
    );
    final dy = above
        ? _target.top - _offset - childSize.height
        : _target.bottom + _offset;
    (child.parentData! as BoxParentData).offset = Offset(_snap(dx), _snap(dy));
  }

  double _snap(double value) =>
      (value * _devicePixelRatio).roundToDouble() / _devicePixelRatio;
}

/// Clips a popover body at the surface's padding box.
///
/// `maxSize` gives a capped surface `overflow-y: auto`
/// (`middleware/maxSize.js:53-58`), and a scroll container clips at its
/// padding box, so the rows run on into the bottom padding before they are
/// cut.
class _PaddingBoxClipper extends CustomClipper<Rect> {
  const _PaddingBoxClipper(this.padding);

  final EdgeInsets padding;

  @override
  Rect getClip(Size size) => padding.inflateRect(Offset.zero & size);

  @override
  bool shouldReclip(_PaddingBoxClipper oldClipper) =>
      oldClipper.padding != padding;
}

/// The hover popover a chart shows for the datum under the cursor.
///
/// Ports `ChartPopover` (`ChartPopover.tsx`). It reuses
/// [buildFluentPopover] for the surface but **not** `FluentPopover` itself:
/// that widget creates a `FocusScopeNode` and requests focus a frame after
/// showing (`overlays/popover.dart:697-708`), is anchored to a child widget
/// through a `LayerLink`, and disables itself entirely without an
/// `onOpenChanged` (`:637`). The chart popover is the opposite on every count —
/// it never takes focus, has no dismiss, anchors to a point or a mark, and
/// stays mounted while open so a screen reader can narrate it
/// (`CartesianChart.tsx:923`).
///
/// It fills the box it is given and positions its surface inside it with
/// [FluentChartPopoverLayout], so that box is the positioning boundary: give
/// it the chart's root, legend included, as upstream's is.
///
/// Visibility is the chart's business, not this widget's: upstream is a pure
/// function of `isPopoverOpen` and `clickPosition`, both driven by hit-testing
/// (`CartesianChart.tsx:444-446`).
class FluentChartPopover extends StatelessWidget {
  /// Creates a popover for [data], anchored at [anchor], or at [anchorRect]
  /// when that is given.
  const FluentChartPopover({
    super.key,
    required this.data,
    this.anchor = Offset.zero,
    this.anchorRect,
    this.style,
  });

  /// The reading to display.
  final FluentChartPopoverData data;

  /// The cursor position, in the coordinate space of the box this fills.
  ///
  /// The zero-size virtual element `ChartPopover.tsx:23-34` builds from
  /// `clickPosition`. Ignored when [anchorRect] is set.
  final Offset anchor;

  /// The hovered mark's bounds, in the same space, for a chart that hands
  /// `positioning.target` an element rather than a point
  /// (`ChartPopover.tsx:35-40`): GroupedVerticalBarChart's bar
  /// (`GroupedVerticalBarChart.tsx:437`), LineChart's active marker
  /// (`LineChart.tsx:1888-1892`), DonutChart's arc (`DonutChart.tsx:395-397`),
  /// GaugeChart's segment and FunnelChart's stage. The surface centres on it
  /// and clears its top or bottom edge.
  final Rect? anchorRect;

  /// The highest-precedence style layer.
  final FluentChartPopoverStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final resolved = resolveFluentChartPopoverStyle(
      theme,
      isCartesian: data.isCartesian,
    ).merge(FluentChartPopoverTheme.maybeOf(context)).merge(style);
    const states = <WidgetState>{};

    // ChartPopover.tsx:54-60 — the custom body wins outright, because both
    // default branches are gated on its absence.
    final Widget body;
    if (data.customContentBuilder != null) {
      body = Builder(builder: data.customContentBuilder!);
    } else if (data.isCalloutForStack) {
      body = buildFluentChartPopoverMultiValue(
        data,
        resolved,
        theme.colors.neutralForeground1,
      );
    } else {
      body = buildFluentChartPopoverSingleValue(
        data,
        resolved,
        theme.colors.neutralForeground1,
      );
    }

    final maxWidth = data.contentMaxWidth;
    final padding =
        resolved.surfacePadding
            ?.resolve(states)
            ?.resolve(Directionality.maybeOf(context) ?? TextDirection.ltr) ??
        EdgeInsets.zero;
    // The body keeps its natural height whatever the surface is capped at, so
    // an oversized stack of readings is cut off rather than overflowing the
    // column that holds it — however many rows a chart hands in.
    final content = ClipRect(
      clipper: _PaddingBoxClipper(padding),
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: double.infinity,
        fit: OverflowBoxFit.deferToChild,
        child: maxWidth == null
            ? body
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: body,
              ),
      ),
    );

    // ChartPopover.tsx:52 renders a bare `<PopoverSurface>`, so the package's
    // own renderer draws it — the chart style's surface fields are the popover
    // style's, flattened by resolveFluentChartPopoverStyle so they stay
    // overridable.
    final surface = buildFluentPopover(
      FluentPopoverBaseState(
        // Popover's defaults, which ChartPopover.tsx:48 leaves in place.
        position: FluentPopoverPosition.above,
        align: FluentPopoverAlign.center,
        // ChartPopover.tsx:52 passes no `withArrow`.
        withArrow: false,
        content: content,
      ),
      FluentPopoverStyle(
        backgroundColor: resolved.surfaceColor,
        borderColor: resolved.surfaceBorderColor,
        borderWidth: resolved.surfaceBorderWidth,
        borderRadius: resolved.surfaceRadius,
        shadow: resolved.surfaceShadow,
        padding: resolved.surfacePadding,
      ),
      states,
    );

    return FluentChartPopoverLayout(
      target: anchorRect ?? Rect.fromLTWH(anchor.dx, anchor.dy, 0, 0),
      offset: resolved.anchorOffset!.resolve(states)!,
      // The popover is announced but never focusable — it is narration for a
      // hover, and stealing focus from the chart would break its own keyboard
      // traversal.
      child: ExcludeFocus(child: surface),
    );
  }
}
