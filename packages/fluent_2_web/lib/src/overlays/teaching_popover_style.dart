import 'package:flutter/widgets.dart';

import '../buttons/button_style.dart';

/// The visual configuration of a `FluentTeachingPopover`'s **content**.
///
/// Deliberately says nothing about the surface. A teaching popover is a
/// `FluentPopover` with a richer body, so the fill, border, corner radius,
/// padding, shadow and arrow all live on `FluentPopoverStyle` and are reached
/// through `FluentTeachingPopover.popoverStyle`. Duplicating them here would be
/// two sources of truth for one rectangle.
///
/// Shaped like `FluentButtonStyle` otherwise: every visual property is a
/// [WidgetStateProperty], so a state-dependent value lives on the property
/// rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance defaults derived from the theme
/// 2. the nearest `FluentTeachingPopoverTheme`
/// 3. the widget's own `style`
///
/// The two footer button slots are the exception to the "everything is a
/// [WidgetStateProperty]" rule: a [FluentButtonStyle] is already per-state on
/// every one of its own properties, so a second layer would buy nothing.
@immutable
class FluentTeachingPopoverStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentTeachingPopoverStyle({
    this.contentWidth,
    this.contentGap,
    this.headerGap,
    this.headerTextStyle,
    this.headerColor,
    this.dismissColor,
    this.dismissBackgroundColor,
    this.dismissPadding,
    this.dismissIconSize,
    this.dismissBorderRadius,
    this.mainGap,
    this.titleTextStyle,
    this.titleColor,
    this.bodyTextStyle,
    this.bodyColor,
    this.footerPadding,
    this.footerGap,
    this.dotColor,
    this.dotBackgroundColor,
    this.dotPadding,
    this.dotBorderRadius,
    this.dotSize,
    this.activeDotSize,
    this.pageCountColor,
    this.primaryButtonStyle,
    this.secondaryButtonStyle,
  });

  /// Width of the content column, inside the surface's padding.
  ///
  /// A fixed width rather than a minimum: Figma draws the content at exactly
  /// 288 in both variants — 320 less the surface's own 16 either side — and
  /// upstream's `useTeachingPopoverSurfaceStyles` pins `minWidth: '320px'` on
  /// the surface for the same reason. It is also what makes the footer's
  /// right alignment and its space-between mean anything: neither describes a
  /// row that hugs its own children.
  final WidgetStateProperty<double?>? contentWidth;

  /// Space between the header block, the main block and the footer.
  final WidgetStateProperty<double?>? contentGap;

  /// Space between the header row and the media below it.
  final WidgetStateProperty<double?>? headerGap;

  /// Header type ramp. Its colour is overridden by [headerColor].
  final WidgetStateProperty<TextStyle?>? headerTextStyle;

  /// Header colour.
  final WidgetStateProperty<Color?>? headerColor;

  /// Dismiss glyph colour.
  final WidgetStateProperty<Color?>? dismissColor;

  /// Dismiss button fill. Transparent at rest, and a real token rather than
  /// [Color] `0x00000000` — Fluent's transparent fills turn opaque in high
  /// contrast.
  final WidgetStateProperty<Color?>? dismissBackgroundColor;

  /// Inset around the dismiss glyph.
  final WidgetStateProperty<EdgeInsetsGeometry?>? dismissPadding;

  /// Dismiss glyph edge length.
  final WidgetStateProperty<double?>? dismissIconSize;

  /// Dismiss button corner radius.
  final WidgetStateProperty<BorderRadius?>? dismissBorderRadius;

  /// Space between the title and the body.
  final WidgetStateProperty<double?>? mainGap;

  /// Title type ramp. Its colour is overridden by [titleColor].
  final WidgetStateProperty<TextStyle?>? titleTextStyle;

  /// Title colour.
  final WidgetStateProperty<Color?>? titleColor;

  /// Body type ramp. Its colour is overridden by [bodyColor]. Also the ramp the
  /// carousel's page count is drawn in — Figma gives the two the same 14/20.
  final WidgetStateProperty<TextStyle?>? bodyTextStyle;

  /// Body colour.
  final WidgetStateProperty<Color?>? bodyColor;

  /// Inset above the footer row.
  final WidgetStateProperty<EdgeInsetsGeometry?>? footerPadding;

  /// Space between the footer's children.
  final WidgetStateProperty<double?>? footerGap;

  /// Carousel dot fill. One token for the selected and the unselected dot
  /// alike — Fluent tells the two apart by shape, not by tone.
  final WidgetStateProperty<Color?>? dotColor;

  /// Fill of a carousel dot's tap target, behind the dot itself.
  final WidgetStateProperty<Color?>? dotBackgroundColor;

  /// Inset around a carousel dot, which is what makes its tap target larger
  /// than the 8 logical pixels the dot draws.
  final WidgetStateProperty<EdgeInsetsGeometry?>? dotPadding;

  /// Carousel dot corner radius.
  final WidgetStateProperty<BorderRadius?>? dotBorderRadius;

  /// Size of an unselected carousel dot.
  final WidgetStateProperty<Size?>? dotSize;

  /// Size of the selected carousel dot, which Fluent draws as a pill.
  final WidgetStateProperty<Size?>? activeDotSize;

  /// Colour of the carousel's page count.
  final WidgetStateProperty<Color?>? pageCountColor;

  /// Layered over the primary action's own button style.
  ///
  /// Null on the neutral appearance, where a stock
  /// `FluentButtonAppearance.primary` already matches the design file.
  final FluentButtonStyle? primaryButtonStyle;

  /// Layered over the secondary action's own button style.
  ///
  /// Null on the neutral appearance, where a stock
  /// `FluentButtonAppearance.secondary` already matches the design file.
  final FluentButtonStyle? secondaryButtonStyle;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [titleColor] keeps
  /// every other resolved value. The two button slots merge per-property too,
  /// through [FluentButtonStyle.merge].
  FluentTeachingPopoverStyle merge(FluentTeachingPopoverStyle? other) {
    if (other == null) return this;
    return FluentTeachingPopoverStyle(
      contentWidth: other.contentWidth ?? contentWidth,
      contentGap: other.contentGap ?? contentGap,
      headerGap: other.headerGap ?? headerGap,
      headerTextStyle: other.headerTextStyle ?? headerTextStyle,
      headerColor: other.headerColor ?? headerColor,
      dismissColor: other.dismissColor ?? dismissColor,
      dismissBackgroundColor:
          other.dismissBackgroundColor ?? dismissBackgroundColor,
      dismissPadding: other.dismissPadding ?? dismissPadding,
      dismissIconSize: other.dismissIconSize ?? dismissIconSize,
      dismissBorderRadius: other.dismissBorderRadius ?? dismissBorderRadius,
      mainGap: other.mainGap ?? mainGap,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
      titleColor: other.titleColor ?? titleColor,
      bodyTextStyle: other.bodyTextStyle ?? bodyTextStyle,
      bodyColor: other.bodyColor ?? bodyColor,
      footerPadding: other.footerPadding ?? footerPadding,
      footerGap: other.footerGap ?? footerGap,
      dotColor: other.dotColor ?? dotColor,
      dotBackgroundColor: other.dotBackgroundColor ?? dotBackgroundColor,
      dotPadding: other.dotPadding ?? dotPadding,
      dotBorderRadius: other.dotBorderRadius ?? dotBorderRadius,
      dotSize: other.dotSize ?? dotSize,
      activeDotSize: other.activeDotSize ?? activeDotSize,
      pageCountColor: other.pageCountColor ?? pageCountColor,
      primaryButtonStyle:
          primaryButtonStyle?.merge(other.primaryButtonStyle) ??
          other.primaryButtonStyle,
      secondaryButtonStyle:
          secondaryButtonStyle?.merge(other.secondaryButtonStyle) ??
          other.secondaryButtonStyle,
    );
  }

  /// This style with the given properties replaced.
  FluentTeachingPopoverStyle copyWith({
    WidgetStateProperty<double?>? contentWidth,
    WidgetStateProperty<double?>? contentGap,
    WidgetStateProperty<double?>? headerGap,
    WidgetStateProperty<TextStyle?>? headerTextStyle,
    WidgetStateProperty<Color?>? headerColor,
    WidgetStateProperty<Color?>? dismissColor,
    WidgetStateProperty<Color?>? dismissBackgroundColor,
    WidgetStateProperty<EdgeInsetsGeometry?>? dismissPadding,
    WidgetStateProperty<double?>? dismissIconSize,
    WidgetStateProperty<BorderRadius?>? dismissBorderRadius,
    WidgetStateProperty<double?>? mainGap,
    WidgetStateProperty<TextStyle?>? titleTextStyle,
    WidgetStateProperty<Color?>? titleColor,
    WidgetStateProperty<TextStyle?>? bodyTextStyle,
    WidgetStateProperty<Color?>? bodyColor,
    WidgetStateProperty<EdgeInsetsGeometry?>? footerPadding,
    WidgetStateProperty<double?>? footerGap,
    WidgetStateProperty<Color?>? dotColor,
    WidgetStateProperty<Color?>? dotBackgroundColor,
    WidgetStateProperty<EdgeInsetsGeometry?>? dotPadding,
    WidgetStateProperty<BorderRadius?>? dotBorderRadius,
    WidgetStateProperty<Size?>? dotSize,
    WidgetStateProperty<Size?>? activeDotSize,
    WidgetStateProperty<Color?>? pageCountColor,
    FluentButtonStyle? primaryButtonStyle,
    FluentButtonStyle? secondaryButtonStyle,
  }) => FluentTeachingPopoverStyle(
    contentWidth: contentWidth ?? this.contentWidth,
    contentGap: contentGap ?? this.contentGap,
    headerGap: headerGap ?? this.headerGap,
    headerTextStyle: headerTextStyle ?? this.headerTextStyle,
    headerColor: headerColor ?? this.headerColor,
    dismissColor: dismissColor ?? this.dismissColor,
    dismissBackgroundColor:
        dismissBackgroundColor ?? this.dismissBackgroundColor,
    dismissPadding: dismissPadding ?? this.dismissPadding,
    dismissIconSize: dismissIconSize ?? this.dismissIconSize,
    dismissBorderRadius: dismissBorderRadius ?? this.dismissBorderRadius,
    mainGap: mainGap ?? this.mainGap,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    titleColor: titleColor ?? this.titleColor,
    bodyTextStyle: bodyTextStyle ?? this.bodyTextStyle,
    bodyColor: bodyColor ?? this.bodyColor,
    footerPadding: footerPadding ?? this.footerPadding,
    footerGap: footerGap ?? this.footerGap,
    dotColor: dotColor ?? this.dotColor,
    dotBackgroundColor: dotBackgroundColor ?? this.dotBackgroundColor,
    dotPadding: dotPadding ?? this.dotPadding,
    dotBorderRadius: dotBorderRadius ?? this.dotBorderRadius,
    dotSize: dotSize ?? this.dotSize,
    activeDotSize: activeDotSize ?? this.activeDotSize,
    pageCountColor: pageCountColor ?? this.pageCountColor,
    primaryButtonStyle: primaryButtonStyle ?? this.primaryButtonStyle,
    secondaryButtonStyle: secondaryButtonStyle ?? this.secondaryButtonStyle,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state — which, on this component,
  /// only the dismiss button's fill does.
  static FluentTeachingPopoverStyle from({
    double? contentWidth,
    double? contentGap,
    double? headerGap,
    TextStyle? headerTextStyle,
    Color? headerColor,
    Color? dismissColor,
    Color? dismissBackgroundColor,
    EdgeInsetsGeometry? dismissPadding,
    double? dismissIconSize,
    BorderRadius? dismissBorderRadius,
    double? mainGap,
    TextStyle? titleTextStyle,
    Color? titleColor,
    TextStyle? bodyTextStyle,
    Color? bodyColor,
    EdgeInsetsGeometry? footerPadding,
    double? footerGap,
    Color? dotColor,
    Color? dotBackgroundColor,
    EdgeInsetsGeometry? dotPadding,
    BorderRadius? dotBorderRadius,
    Size? dotSize,
    Size? activeDotSize,
    Color? pageCountColor,
    FluentButtonStyle? primaryButtonStyle,
    FluentButtonStyle? secondaryButtonStyle,
  }) => FluentTeachingPopoverStyle(
    contentWidth: _all(contentWidth),
    contentGap: _all(contentGap),
    headerGap: _all(headerGap),
    headerTextStyle: _all(headerTextStyle),
    headerColor: _all(headerColor),
    dismissColor: _all(dismissColor),
    dismissBackgroundColor: _all(dismissBackgroundColor),
    dismissPadding: _all(dismissPadding),
    dismissIconSize: _all(dismissIconSize),
    dismissBorderRadius: _all(dismissBorderRadius),
    mainGap: _all(mainGap),
    titleTextStyle: _all(titleTextStyle),
    titleColor: _all(titleColor),
    bodyTextStyle: _all(bodyTextStyle),
    bodyColor: _all(bodyColor),
    footerPadding: _all(footerPadding),
    footerGap: _all(footerGap),
    dotColor: _all(dotColor),
    dotBackgroundColor: _all(dotBackgroundColor),
    dotPadding: _all(dotPadding),
    dotBorderRadius: _all(dotBorderRadius),
    dotSize: _all(dotSize),
    activeDotSize: _all(activeDotSize),
    pageCountColor: _all(pageCountColor),
    primaryButtonStyle: primaryButtonStyle,
    secondaryButtonStyle: secondaryButtonStyle,
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentTeachingPopoverStyle &&
      other.contentWidth == contentWidth &&
      other.contentGap == contentGap &&
      other.headerGap == headerGap &&
      other.headerTextStyle == headerTextStyle &&
      other.headerColor == headerColor &&
      other.dismissColor == dismissColor &&
      other.dismissBackgroundColor == dismissBackgroundColor &&
      other.dismissPadding == dismissPadding &&
      other.dismissIconSize == dismissIconSize &&
      other.dismissBorderRadius == dismissBorderRadius &&
      other.mainGap == mainGap &&
      other.titleTextStyle == titleTextStyle &&
      other.titleColor == titleColor &&
      other.bodyTextStyle == bodyTextStyle &&
      other.bodyColor == bodyColor &&
      other.footerPadding == footerPadding &&
      other.footerGap == footerGap &&
      other.dotColor == dotColor &&
      other.dotBackgroundColor == dotBackgroundColor &&
      other.dotPadding == dotPadding &&
      other.dotBorderRadius == dotBorderRadius &&
      other.dotSize == dotSize &&
      other.activeDotSize == activeDotSize &&
      other.pageCountColor == pageCountColor &&
      other.primaryButtonStyle == primaryButtonStyle &&
      other.secondaryButtonStyle == secondaryButtonStyle;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    contentWidth,
    contentGap,
    headerGap,
    headerTextStyle,
    headerColor,
    dismissColor,
    dismissBackgroundColor,
    dismissPadding,
    dismissIconSize,
    dismissBorderRadius,
    mainGap,
    titleTextStyle,
    titleColor,
    bodyTextStyle,
    bodyColor,
    footerPadding,
    footerGap,
    dotColor,
    dotBackgroundColor,
    dotPadding,
    dotBorderRadius,
    dotSize,
    activeDotSize,
    pageCountColor,
    primaryButtonStyle,
    secondaryButtonStyle,
  ]);
}
