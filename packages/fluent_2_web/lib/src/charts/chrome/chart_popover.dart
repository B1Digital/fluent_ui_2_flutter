import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../../overlays/popover.dart';
import '../../overlays/popover_style.dart';
import '../axis/tick_format.dart';
import '../model/callout_data.dart';
import 'chart_popover_style.dart';
import 'legend_shape.dart';

/// The reading a chart popover displays.
///
/// Ports `ChartPopoverProps` (`ChartPopover.types.ts:5-28`) minus the props
/// that only exist to configure the React positioning layer.
///
/// Every text field is already formatted by the chart. Upstream calls
/// `formatToLocaleString` inside the popover (`ChartPopover.tsx:80`, `:89`),
/// but the frozen contract types these as `String?`, which moves the call to
/// the chart. [yValues] is the exception: its readings are still numeric, so
/// the multi-value body formats them itself.
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

  final block = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(data.legend ?? '', style: style.legendTextStyle!.resolve(states)),
      Text(
        data.yValue ?? '',
        style: style.valueTextStyle!
            .resolve(states)!
            .copyWith(
              color: accentColour,
              fontSize: style.valueFontSize!.resolve(states),
            ),
      ),
    ],
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // ChartPopover.tsx:62-66 — a row that would space its children apart if
      // the commented-out time reading at :65 were ever restored.
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(data.xValue ?? '', style: style.xTextStyle!.resolve(states)),
        ],
      ),
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
              block,
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
        hasSubCounts: hasSubCounts,
        // ChartPopover.tsx:187 — every column but the last carries a 16px
        // trailing margin.
        isLast: index == values.length - 1,
      ),
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Padding(
        // ChartPopover.tsx:122 — 11px below the date container, but only when
        // subcounts exist. The same 11 as the single-value accent bar margin.
        padding: EdgeInsets.only(
          bottom: hasSubCounts ? kChartPopoverAccentBarMarginTop : 0,
        ),
        child: Text(
          data.xValue ?? '',
          style: style.xTextStyle!.resolve(states),
        ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
  );
}

Widget _popoverRow(
  FluentYValueHover value,
  FluentChartPopoverStyle style,
  Color fallbackForeground, {
  required Color? popoverColour,
  required bool hasSubCounts,
  required bool isLast,
}) {
  const states = <WidgetState>{};
  // ChartPopover.tsx:188.
  final toDrawShape = value.index != null && value.index != -1;
  final colour = value.color ?? fallbackForeground;
  final reading = value.yAxisCalloutText ?? formatToLocaleString(value.y);
  // ChartPopover.tsx:196 and :246 both render `{legend} ({y})`.
  final header = Text(
    '${value.legend ?? ''} (${formatToLocaleString(value.y)})',
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
      Text(value.legend ?? '', style: style.legendTextStyle!.resolve(states)),
      // ChartPopover.tsx:229 — `direction: ltr; unicode-bidi: isolate` keeps
      // numbers left-to-right under an RTL chart. The multi-value path does NOT
      // apply the 28px inline size the single-value path does.
      Directionality(
        textDirection: TextDirection.ltr,
        child: Text(reading, style: style.valueTextStyle!.resolve(states)),
      ),
    ],
  );

  final inner = Padding(
    // ChartPopover.tsx:226 — `marginTop: xValue ? 13px : unset`, and the row is
    // the truthiness test's own subject, so it is always 13.
    padding: EdgeInsets.only(top: style.rowMarginTop!.resolve(states)!),
    child: body,
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
        SizedBox(
          // `ChartPopover.tsx:211-217` renders the same `<Shape>` the legend
          // does, and that component sizes its own svg (`shape.tsx:39-40`,
          // `:46-49`) — so the box is the shape viewport, not the legend row's
          // border box. The two coincide at 14 only because
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
      inner,
    ],
  );

  final withMarker = toDrawShape ? marker : IntrinsicHeight(child: marker);

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
                  Text(
                    entry.key,
                    style: style.legendTextStyle!.resolve(states),
                  ),
                  // ChartPopover.tsx:257 —
                  // `props.color ? props.color : tokens.colorNeutralForeground1`.
                  // That is the POPOVER-level colour, not the row's: in a
                  // stacked popover every subcount reading takes one colour,
                  // rather than each row's own. The plan specified the row's,
                  // which agrees only when there is a single row or the popover
                  // carries no colour; upstream wins under the bug-fidelity
                  // rule (spec §5.2).
                  Text(
                    formatToLocaleString(entry.value),
                    style: style.valueTextStyle!
                        .resolve(states)!
                        .copyWith(color: popoverColour ?? fallbackForeground),
                  ),
                ],
              ),
          ],
        );

  return Padding(
    // ChartPopover.tsx:193 applies marginStyle only under subcounts; the
    // subcount arm at :244 always does, and reaching it implies subcounts.
    padding: EdgeInsetsDirectional.only(
      end: hasSubCounts && !isLast ? style.columnGap!.resolve(states)! : 0,
    ),
    child: content,
  );
}

/// Renders a whole-number double without its `.0`.
///
/// `ratio` is `[number, number]` upstream (`ChartPopover.types.ts:20`) and JS
/// prints `42`, not `42.0`, for an integral value.
String _trimTrailingZero(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

/// Places a chart popover against a zero-size virtual target at the cursor.
///
/// `ChartPopover.tsx:23-34` builds a `getBoundingClientRect` returning a
/// zero-width, zero-height rect at `clickPosition` (`:31-32`), then positions
/// against it with `autoSize: 'always'`, `offset: 20` and `coverTarget: false`
/// (`:48`).
///
/// ponytail: flip-then-shift, below first. `@fluentui/react-positioning` is not
/// in the extracted source, so only its *configuration* is knowable — the flip
/// and shift policy is derived from `coverTarget: false` plus
/// `autoSize: 'always'`, not ported. Probe that settles it: capture
/// `charts-linechart--line-chart-basic` under Oracle B with the cursor near
/// each edge of the plot and record the surface's resolved position.
class FluentChartPopoverLayoutDelegate extends SingleChildLayoutDelegate {
  /// Creates a delegate anchored at [anchor], clearing it by [offset].
  const FluentChartPopoverLayoutDelegate({
    required this.anchor,
    required this.offset,
  });

  /// The cursor position, in the coordinate space of the box being laid out.
  final Offset anchor;

  /// Clearance between the anchor and the surface.
  final double offset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      // `autoSize: 'always'` caps the surface at the available box instead of
      // letting it overflow.
      BoxConstraints.loose(constraints.biggest);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Below the cursor first, because `coverTarget: false` forbids overlapping
    // the target and the default placement is the block-end side.
    var dy = anchor.dy + offset;
    if (dy + childSize.height > size.height) {
      final flipped = anchor.dy - offset - childSize.height;
      dy = flipped >= 0 ? flipped : size.height - childSize.height;
    }
    var dx = anchor.dx;
    if (dx + childSize.width > size.width) dx = size.width - childSize.width;
    if (dx < 0) dx = 0;
    if (dy < 0) dy = 0;
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(FluentChartPopoverLayoutDelegate oldDelegate) =>
      oldDelegate.anchor != anchor || oldDelegate.offset != offset;
}

/// The hover popover a chart shows for the datum under the cursor.
///
/// Ports `ChartPopover` (`ChartPopover.tsx`). It reuses
/// [buildFluentPopover] for the surface but **not** `FluentPopover` itself:
/// that widget creates a `FocusScopeNode` and requests focus a frame after
/// showing (`overlays/popover.dart:697-708`), is anchored to a child widget
/// through a `LayerLink`, and disables itself entirely without an
/// `onOpenChanged` (`:637`). The chart popover is the opposite on every count —
/// it never takes focus, has no dismiss, anchors to a point, and stays mounted
/// while open so a screen reader can narrate it
/// (`CartesianChart.tsx:923`).
///
/// Visibility is the chart's business, not this widget's: upstream is a pure
/// function of `isPopoverOpen` and `clickPosition`, both driven by hit-testing
/// (`CartesianChart.tsx:444-446`).
class FluentChartPopover extends StatelessWidget {
  /// Creates a popover for [data], anchored at [anchor].
  const FluentChartPopover({
    super.key,
    required this.data,
    required this.anchor,
    this.style,
  });

  /// The reading to display.
  final FluentChartPopoverData data;

  /// The cursor position, in the coordinate space of the box this fills.
  final Offset anchor;

  /// The highest-precedence style layer.
  final FluentChartPopoverStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final resolved = resolveFluentChartPopoverStyle(
      theme,
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

    // ChartPopover.tsx:52 renders a bare `<PopoverSurface>`, so the package's
    // own renderer draws it — the chart style's surface fields are the popover
    // style's, flattened by resolveFluentChartPopoverStyle so they stay
    // overridable.
    final surface = buildFluentPopover(
      FluentPopoverBaseState(
        // `coverTarget: false` with the default block-end placement.
        position: FluentPopoverPosition.below,
        align: FluentPopoverAlign.start,
        // ChartPopover.tsx:52 passes no `withArrow`.
        withArrow: false,
        content: body,
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

    return CustomSingleChildLayout(
      delegate: FluentChartPopoverLayoutDelegate(
        anchor: anchor,
        offset: resolved.anchorOffset!.resolve(states)!,
      ),
      // The popover is announced but never focusable — it is narration for a
      // hover, and stealing focus from the chart would break its own keyboard
      // traversal.
      child: ExcludeFocus(child: surface),
    );
  }
}
