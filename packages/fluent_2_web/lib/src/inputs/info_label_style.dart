import 'package:flutter/widgets.dart';

import 'info_button_style.dart';
import 'label_style.dart';

/// The visual configuration of a `FluentInfoLabel`.
///
/// An InfoLabel is a composition — a `FluentLabel` beside a
/// `FluentInfoButton` — and so is its style. [gap] is the only number the
/// component owns outright; [labelStyle] and [infoButtonStyle] are handed
/// straight to the two parts, which is what lets a single `style:` argument
/// reach either of them without the caller having to wrap the widget in a
/// `FluentLabelTheme` and a `FluentInfoButtonTheme` as well.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the defaults derived from the theme
/// 2. the nearest `FluentInfoLabelTheme`
/// 3. the widget's own `style`
///
/// The consumer's own style therefore wins, matching upstream's rule that
/// `props.className` is passed last to `mergeClasses`.
@immutable
class FluentInfoLabelStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentInfoLabelStyle({this.gap, this.labelStyle, this.infoButtonStyle});

  /// Space between the label and the info button.
  ///
  /// Zero in Figma at every size — the trigger's own 2 or 4 of padding is the
  /// whole separation.
  final WidgetStateProperty<double?>? gap;

  /// Layered over the label's own resolved style.
  final FluentLabelStyle? labelStyle;

  /// Layered over the info button's own resolved style.
  final FluentInfoButtonStyle? infoButtonStyle;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// The two nested styles merge *per property* as well, so overriding the
  /// label's colour through [other] keeps whatever this style said about the
  /// info button.
  FluentInfoLabelStyle merge(FluentInfoLabelStyle? other) {
    if (other == null) return this;
    return FluentInfoLabelStyle(
      gap: other.gap ?? gap,
      labelStyle: labelStyle?.merge(other.labelStyle) ?? other.labelStyle,
      infoButtonStyle:
          infoButtonStyle?.merge(other.infoButtonStyle) ??
          other.infoButtonStyle,
    );
  }

  /// This style with the given properties replaced.
  ///
  /// Replaced, not merged: use [merge] to layer a partial nested style.
  FluentInfoLabelStyle copyWith({
    WidgetStateProperty<double?>? gap,
    FluentLabelStyle? labelStyle,
    FluentInfoButtonStyle? infoButtonStyle,
  }) => FluentInfoLabelStyle(
    gap: gap ?? this.gap,
    labelStyle: labelStyle ?? this.labelStyle,
    infoButtonStyle: infoButtonStyle ?? this.infoButtonStyle,
  );

  /// Convenience for the common case of one value across every state.
  static FluentInfoLabelStyle from({
    double? gap,
    FluentLabelStyle? labelStyle,
    FluentInfoButtonStyle? infoButtonStyle,
  }) => FluentInfoLabelStyle(
    gap: gap == null ? null : WidgetStatePropertyAll<double?>(gap),
    labelStyle: labelStyle,
    infoButtonStyle: infoButtonStyle,
  );

  @override
  bool operator ==(Object other) =>
      other is FluentInfoLabelStyle &&
      other.gap == gap &&
      other.labelStyle == labelStyle &&
      other.infoButtonStyle == infoButtonStyle;

  @override
  int get hashCode => Object.hash(gap, labelStyle, infoButtonStyle);
}
