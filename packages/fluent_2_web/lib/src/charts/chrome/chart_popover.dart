import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../model/callout_data.dart';
import 'chart_popover_style.dart';

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

/// Renders a whole-number double without its `.0`.
///
/// `ratio` is `[number, number]` upstream (`ChartPopover.types.ts:20`) and JS
/// prints `42`, not `42.0`, for an integral value.
String _trimTrailingZero(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';
