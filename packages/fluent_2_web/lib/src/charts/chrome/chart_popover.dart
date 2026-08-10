import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../axis/tick_format.dart';
import '../model/callout_data.dart';
import 'chart_popover_style.dart';
import 'legend_shape.dart';
import 'legend_style.dart';

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
/// modulus is 8 and `dottedLine` — a `CustomPoints` member (`utilities.ts:1724`)
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
          width: kLegendSwatchBoxSize,
          height: kLegendSwatchBoxSize,
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
                  Text(
                    formatToLocaleString(entry.value),
                    style: style.valueTextStyle!
                        .resolve(states)!
                        .copyWith(color: colour),
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
