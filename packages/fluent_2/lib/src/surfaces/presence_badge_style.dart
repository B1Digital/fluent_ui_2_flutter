import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentPresenceBadge`.
///
/// Shaped like `FluentBadgeStyle` — [WidgetStateProperty] per visual property,
/// nullable meaning "inherit" — but with the presence badge's own, much smaller
/// vocabulary. There is no padding, gap or text style here: a presence badge is
/// one glyph on one disc and has no label.
///
/// [backgroundColor] and [borderColor] are two separate Figma bindings that
/// happen to resolve to the same token, `Neutral/Background/1/Rest`. They are
/// kept apart because they do different jobs: the background is the disc *under*
/// the glyph, which is what makes the hollow out-of-office glyphs read against
/// an avatar, while the border is the cut-out ring painted *outside* the badge's
/// own box.
///
/// Resolution order, lowest to highest precedence:
///
/// 1. the status/size defaults derived from the theme
/// 2. the nearest `FluentPresenceBadgeTheme`
/// 3. the widget's own `style`
@immutable
class FluentPresenceBadgeStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentPresenceBadgeStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.diameter,
  });

  /// The disc painted behind the glyph.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// The status glyph colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// The cut-out ring painted outside the badge's box.
  final WidgetStateProperty<Color?>? borderColor;

  /// Ring width. Figma aligns this stroke OUTSIDE, so it costs no layout: a
  /// 16px badge with a 2px ring still occupies 16px and paints 20px.
  final WidgetStateProperty<double?>? borderWidth;

  /// The badge's edge length. The glyph is drawn at the same size.
  final WidgetStateProperty<double?>? diameter;

  /// This style with the non-null properties of [other] layered on top.
  FluentPresenceBadgeStyle merge(FluentPresenceBadgeStyle? other) {
    if (other == null) return this;
    return FluentPresenceBadgeStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      diameter: other.diameter ?? diameter,
    );
  }

  /// This style with the given properties replaced.
  FluentPresenceBadgeStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<double?>? diameter,
  }) => FluentPresenceBadgeStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    diameter: diameter ?? this.diameter,
  );

  /// Convenience for the common case of one value across every state.
  static FluentPresenceBadgeStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? borderWidth,
    double? diameter,
  }) => FluentPresenceBadgeStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    diameter: _all(diameter),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentPresenceBadgeStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.diameter == diameter;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderColor,
    borderWidth,
    diameter,
  );
}
