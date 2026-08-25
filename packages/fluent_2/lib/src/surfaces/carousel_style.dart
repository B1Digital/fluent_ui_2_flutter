import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentCarousel`.
///
/// Same shape as `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], every field is nullable and means "inherit", and the
/// resolution order lowest to highest is the theme defaults, then the nearest
/// `FluentCarouselTheme`, then the widget's own `style`.
///
/// The properties fall into three groups, which is worth knowing before
/// overriding one:
///
/// * **step** — the dot/pill indicator. `stepBackgroundColor` is the 24x24 hit
///   target behind the mark; `stepColor` is the mark itself.
/// * **preview** — the image-thumbnail indicator, used instead of the dots.
/// * **nav** — the gaps and insets that place the strip against the content.
@immutable
class FluentCarouselStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentCarouselStyle({
    this.stepColor,
    this.stepBackgroundColor,
    this.stepBorderRadius,
    this.stepPadding,
    this.activeStepPadding,
    this.stepSize,
    this.activeStepSize,
    this.indicatorBackgroundColor,
    this.indicatorBorderRadius,
    this.previewSize,
    this.selectedPreviewSize,
    this.previewBorderRadius,
    this.previewGap,
    this.navGap,
    this.controlGap,
    this.navSpacing,
    this.navInset,
    this.iconSize,
  });

  /// The dot or pill mark itself. Ramped rest/hover/pressed/disabled.
  final WidgetStateProperty<Color?>? stepColor;

  /// The step's 24x24 hit target. Fluent's transparent ramp, which is
  /// invisible in light and dark and **opaque** in high contrast.
  final WidgetStateProperty<Color?>? stepBackgroundColor;

  /// Corner radius of the step's hit target.
  final WidgetStateProperty<BorderRadius?>? stepBorderRadius;

  /// Inset around an inactive step's dot.
  final WidgetStateProperty<EdgeInsetsGeometry?>? stepPadding;

  /// Inset around the active step's pill. Narrower horizontally, because the
  /// pill is wider and the hit target stays square.
  final WidgetStateProperty<EdgeInsetsGeometry?>? activeStepPadding;

  /// Size of an inactive step's dot.
  final WidgetStateProperty<Size?>? stepSize;

  /// Size of the active step's pill.
  final WidgetStateProperty<Size?>? activeStepSize;

  /// Fill behind the whole indicator strip. Null in the `outsideContent`
  /// layout; a translucent wash when the strip sits over the slide.
  final WidgetStateProperty<Color?>? indicatorBackgroundColor;

  /// Corner radius of the indicator strip.
  final WidgetStateProperty<BorderRadius?>? indicatorBorderRadius;

  /// Size of an unselected image-preview thumbnail.
  final WidgetStateProperty<Size?>? previewSize;

  /// Size of the selected image-preview thumbnail.
  final WidgetStateProperty<Size?>? selectedPreviewSize;

  /// Corner radius of an image-preview thumbnail.
  final WidgetStateProperty<BorderRadius?>? previewBorderRadius;

  /// Gap between image-preview thumbnails.
  final WidgetStateProperty<double?>? previewGap;

  /// Gap between the chevron groups and the indicator strip.
  final WidgetStateProperty<double?>? navGap;

  /// Gap between the autoplay control and the previous-slide chevron.
  final WidgetStateProperty<double?>? controlGap;

  /// Gap between the slide and the nav strip.
  final WidgetStateProperty<double?>? navSpacing;

  /// Inset from the carousel's edges to the outermost chevron.
  final WidgetStateProperty<EdgeInsetsGeometry?>? navInset;

  /// Edge length of the chevron and autoplay glyphs.
  final WidgetStateProperty<double?>? iconSize;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Per-property, not wholesale: overriding only `stepColor` keeps every
  /// resolved size and gap.
  FluentCarouselStyle merge(FluentCarouselStyle? other) {
    if (other == null) return this;
    return FluentCarouselStyle(
      stepColor: other.stepColor ?? stepColor,
      stepBackgroundColor: other.stepBackgroundColor ?? stepBackgroundColor,
      stepBorderRadius: other.stepBorderRadius ?? stepBorderRadius,
      stepPadding: other.stepPadding ?? stepPadding,
      activeStepPadding: other.activeStepPadding ?? activeStepPadding,
      stepSize: other.stepSize ?? stepSize,
      activeStepSize: other.activeStepSize ?? activeStepSize,
      indicatorBackgroundColor:
          other.indicatorBackgroundColor ?? indicatorBackgroundColor,
      indicatorBorderRadius:
          other.indicatorBorderRadius ?? indicatorBorderRadius,
      previewSize: other.previewSize ?? previewSize,
      selectedPreviewSize: other.selectedPreviewSize ?? selectedPreviewSize,
      previewBorderRadius: other.previewBorderRadius ?? previewBorderRadius,
      previewGap: other.previewGap ?? previewGap,
      navGap: other.navGap ?? navGap,
      controlGap: other.controlGap ?? controlGap,
      navSpacing: other.navSpacing ?? navSpacing,
      navInset: other.navInset ?? navInset,
      iconSize: other.iconSize ?? iconSize,
    );
  }

  /// This style with the given properties replaced.
  FluentCarouselStyle copyWith({
    WidgetStateProperty<Color?>? stepColor,
    WidgetStateProperty<Color?>? stepBackgroundColor,
    WidgetStateProperty<BorderRadius?>? stepBorderRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? stepPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? activeStepPadding,
    WidgetStateProperty<Size?>? stepSize,
    WidgetStateProperty<Size?>? activeStepSize,
    WidgetStateProperty<Color?>? indicatorBackgroundColor,
    WidgetStateProperty<BorderRadius?>? indicatorBorderRadius,
    WidgetStateProperty<Size?>? previewSize,
    WidgetStateProperty<Size?>? selectedPreviewSize,
    WidgetStateProperty<BorderRadius?>? previewBorderRadius,
    WidgetStateProperty<double?>? previewGap,
    WidgetStateProperty<double?>? navGap,
    WidgetStateProperty<double?>? controlGap,
    WidgetStateProperty<double?>? navSpacing,
    WidgetStateProperty<EdgeInsetsGeometry?>? navInset,
    WidgetStateProperty<double?>? iconSize,
  }) => FluentCarouselStyle(
    stepColor: stepColor ?? this.stepColor,
    stepBackgroundColor: stepBackgroundColor ?? this.stepBackgroundColor,
    stepBorderRadius: stepBorderRadius ?? this.stepBorderRadius,
    stepPadding: stepPadding ?? this.stepPadding,
    activeStepPadding: activeStepPadding ?? this.activeStepPadding,
    stepSize: stepSize ?? this.stepSize,
    activeStepSize: activeStepSize ?? this.activeStepSize,
    indicatorBackgroundColor:
        indicatorBackgroundColor ?? this.indicatorBackgroundColor,
    indicatorBorderRadius: indicatorBorderRadius ?? this.indicatorBorderRadius,
    previewSize: previewSize ?? this.previewSize,
    selectedPreviewSize: selectedPreviewSize ?? this.selectedPreviewSize,
    previewBorderRadius: previewBorderRadius ?? this.previewBorderRadius,
    previewGap: previewGap ?? this.previewGap,
    navGap: navGap ?? this.navGap,
    controlGap: controlGap ?? this.controlGap,
    navSpacing: navSpacing ?? this.navSpacing,
    navInset: navInset ?? this.navInset,
    iconSize: iconSize ?? this.iconSize,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// Use the constructor directly when a property genuinely differs per state —
  /// which, on this component, only the two step colours do.
  static FluentCarouselStyle from({
    Color? stepColor,
    Color? stepBackgroundColor,
    BorderRadius? stepBorderRadius,
    EdgeInsetsGeometry? stepPadding,
    EdgeInsetsGeometry? activeStepPadding,
    Size? stepSize,
    Size? activeStepSize,
    Color? indicatorBackgroundColor,
    BorderRadius? indicatorBorderRadius,
    Size? previewSize,
    Size? selectedPreviewSize,
    BorderRadius? previewBorderRadius,
    double? previewGap,
    double? navGap,
    double? controlGap,
    double? navSpacing,
    EdgeInsetsGeometry? navInset,
    double? iconSize,
  }) => FluentCarouselStyle(
    stepColor: _all(stepColor),
    stepBackgroundColor: _all(stepBackgroundColor),
    stepBorderRadius: _all(stepBorderRadius),
    stepPadding: _all(stepPadding),
    activeStepPadding: _all(activeStepPadding),
    stepSize: _all(stepSize),
    activeStepSize: _all(activeStepSize),
    indicatorBackgroundColor: _all(indicatorBackgroundColor),
    indicatorBorderRadius: _all(indicatorBorderRadius),
    previewSize: _all(previewSize),
    selectedPreviewSize: _all(selectedPreviewSize),
    previewBorderRadius: _all(previewBorderRadius),
    previewGap: _all(previewGap),
    navGap: _all(navGap),
    controlGap: _all(controlGap),
    navSpacing: _all(navSpacing),
    navInset: _all(navInset),
    iconSize: _all(iconSize),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentCarouselStyle &&
      other.stepColor == stepColor &&
      other.stepBackgroundColor == stepBackgroundColor &&
      other.stepBorderRadius == stepBorderRadius &&
      other.stepPadding == stepPadding &&
      other.activeStepPadding == activeStepPadding &&
      other.stepSize == stepSize &&
      other.activeStepSize == activeStepSize &&
      other.indicatorBackgroundColor == indicatorBackgroundColor &&
      other.indicatorBorderRadius == indicatorBorderRadius &&
      other.previewSize == previewSize &&
      other.selectedPreviewSize == selectedPreviewSize &&
      other.previewBorderRadius == previewBorderRadius &&
      other.previewGap == previewGap &&
      other.navGap == navGap &&
      other.controlGap == controlGap &&
      other.navSpacing == navSpacing &&
      other.navInset == navInset &&
      other.iconSize == iconSize;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    stepColor,
    stepBackgroundColor,
    stepBorderRadius,
    stepPadding,
    activeStepPadding,
    stepSize,
    activeStepSize,
    indicatorBackgroundColor,
    indicatorBorderRadius,
    previewSize,
    selectedPreviewSize,
    previewBorderRadius,
    previewGap,
    navGap,
    controlGap,
    navSpacing,
    navInset,
    iconSize,
  ]);
}
