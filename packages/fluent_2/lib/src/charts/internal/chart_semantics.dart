import 'package:flutter/widgets.dart';

import '../../l10n/l10n.dart';
import '../model/chart_common.dart';
import '../model/chart_value.dart';

/// The accessible description of one painted mark.
///
/// Ports `getAccessibleDataObject` (`utilities.ts:1780-1799`). Upstream returns
/// a props bag with `role`, `data-is-focusable`, `aria-label`,
/// `aria-labelledby` and `aria-describedby`; of those, `role` is always `'text'`
/// at every call site and `aria-labelledby` has no Flutter analogue, so this
/// carries the three that survive.
@immutable
class FluentChartMarkSemantics {
  /// Creates a mark's accessible description.
  const FluentChartMarkSemantics({
    this.label,
    this.hint,
    this.focusable = true,
  });

  /// Builds a description from a caller's [props], falling back to
  /// [fallbackLabel] when they name no label.
  ///
  /// The fallback matters because a canvas-drawn mark produces no semantics
  /// node of its own: the label has to be supplied explicitly either way
  /// (spec section 5.7).
  factory FluentChartMarkSemantics.from(
    FluentChartSemantics? props, {
    String? fallbackLabel,
  }) => FluentChartMarkSemantics(
    // utilities.ts:1795.
    label: props?.label ?? fallbackLabel,
    // utilities.ts:1797 — aria-describedby. aria-labelledby (:1796) is an
    // element reference with no Flutter counterpart and is dropped.
    hint: props?.describedBy,
  );

  /// What assistive technology announces for this mark.
  final String? label;

  /// A supplementary description.
  final String? hint;

  /// Whether the mark takes keyboard focus.
  ///
  /// `data-is-focusable` defaults to true (`utilities.ts:1783`).
  final bool focusable;
}

/// The label a cartesian chart's root [Semantics] node carries.
///
/// Ports `_getChartDescription` (`CartesianChart.tsx:552-561`) and
/// `_getAxisTitle` (`:563-574`).
///
/// `// parity:` `:554` is `(props.chartTitle || 'Chart. ') + …`, so a real title
/// runs straight into the first axis clause with no separator between them,
/// while the `'Chart. '` fallback supplies one. That defect is reproduced.
///
/// [l10n] carries the wording. It is a parameter rather than a lookup because
/// this is a plain function with no [BuildContext]; callers inside the widget
/// tree pass `fluentL10n(context)`, and callers outside it pass
/// [fluentLocalizationsFallback].
String buildFluentCartesianChartDescription({
  required FluentChartAxisType xAxisType,
  required FluentChartAxisType yAxisType,
  required bool hasSecondaryScale,
  required FluentLocalizations l10n,
  String? chartTitle,
  String? xAxisTitle,
  String? yAxisTitle,
  String? secondaryYAxisTitle,
}) {
  // CartesianChart.tsx:567-572 — categories for a band axis, time for a date
  // axis, values for everything else.
  String subject(String? title, FluentChartAxisType type) =>
      title ??
      switch (type) {
        FluentChartAxisType.category => l10n.chartAxisCategories,
        FluentChartAxisType.date => l10n.chartAxisTime,
        FluentChartAxisType.numeric => l10n.chartAxisValues,
      };

  String clause(String axisLabel, String? title, FluentChartAxisType type) =>
      l10n.chartAxisDescription(axisLabel, subject(title, type));

  final buffer = StringBuffer(chartTitle ?? l10n.chartFallbackTitle)
    ..write(clause(l10n.chartAxisX, xAxisTitle, xAxisType))
    ..write(clause(l10n.chartAxisY, yAxisTitle, yAxisType));
  if (hasSecondaryScale) {
    // CartesianChart.tsx:558 passes YAxisType.NumericAxis outright, so a
    // secondary axis is always described as displaying values unless it is
    // titled.
    buffer.write(
      clause(
        l10n.chartAxisSecondaryY,
        secondaryYAxisTitle,
        FluentChartAxisType.numeric,
      ),
    );
  }
  return buffer.toString();
}
