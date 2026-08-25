import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../overlays/popover.dart';
import '../internal/chart_text_styles.dart';

/// Gap between the cursor and the popover surface. `ChartPopover.tsx:48`.
///
/// `FluentPopover` defaults its own offset to `FluentSpacing.none`
/// (`overlays/popover.dart:239`), so this cannot be inherited.
const double kChartPopoverAnchorOffset = 20;

/// Width of the series-coloured bar down the popover's inline start.
/// `ChartPopover.tsx:74`.
const double kChartPopoverAccentBarWidth = 4;

/// Top margin above the accent-barred block. `ChartPopover.tsx:75`.
const double kChartPopoverAccentBarMarginTop = 11;

/// Font size of the single-value Y reading. `ChartPopover.tsx:86`.
///
/// `fontSizeHero700` is 28px. The inline style beats `calloutContentY`'s own
/// class, which would otherwise be `subtitle2Stronger` for a cartesian chart or
/// `title2` for a non-cartesian one
/// (`useChartPopoverStyles.styles.ts:79-84`). The multi-value path does **not**
/// set it (`ChartPopover.tsx:229`).
const double kChartPopoverValueFontSize = 28;

/// Font size of a subcount group header. `ChartPopover.tsx:195`, `:245`.
///
/// The source says `12pt`; a CSS point is 1/72 inch against a 96dpi reference
/// pixel, so `12 * 96 / 72 = 16`. The `ms-fontWeight-semibold` class beside it
/// is a v8 name with no v9 rule, so only the size lands.
const double kChartPopoverSubHeaderFontSize = 16;

/// Gap between multi-value columns. `ChartPopover.tsx:187`.
const double kChartPopoverColumnGap = 16;

/// Top margin inside a multi-value row. `ChartPopover.tsx:226`.
///
/// Written as `marginTop: xValue ? '13px' : 'unset'`, and `xValue` is the row's
/// own datum, which is always truthy — so it is always 13.
const double kChartPopoverRowMarginTop = 13;

/// Padding below a multi-value row that draws its bottom rule.
/// `ChartPopover.tsx:147`.
const double kChartPopoverRowPaddingBottom = 10;

/// The visual configuration of a chart popover.
///
/// Upstream's own `styles` prop is 14/15 dead — every slot except
/// `calloutContentRoot` has its `props.styles?.*` argument commented out
/// (`useChartPopoverStyles.styles.ts:123-160`). The Dart port exposes the whole
/// surface anyway, because a live style hook costs nothing here and a dead one
/// is a bug waiting to be reported.
@immutable
class FluentChartPopoverStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentChartPopoverStyle({
    this.surfacePadding,
    this.surfaceColor,
    this.surfaceBorderColor,
    this.surfaceBorderWidth,
    this.surfaceRadius,
    this.surfaceShadow,
    this.anchorOffset,
    this.accentBarWidth,
    this.accentBarMarginTop,
    this.xTextStyle,
    this.legendTextStyle,
    this.valueTextStyle,
    this.valueFontSize,
    this.ratioTextStyle,
    this.ratioPartTextStyle,
    this.ratioMarginStart,
    this.descriptionTextStyle,
    this.descriptionDividerColor,
    this.descriptionGap,
    this.columnGap,
    this.rowMarginTop,
    this.rowDividerColor,
    this.rowPaddingBottom,
  });

  /// Padding inside the popover surface.
  final WidgetStateProperty<EdgeInsetsGeometry?>? surfacePadding;

  /// Surface fill.
  final WidgetStateProperty<Color?>? surfaceColor;

  /// Surface border colour.
  final WidgetStateProperty<Color?>? surfaceBorderColor;

  /// Surface border width.
  final WidgetStateProperty<double?>? surfaceBorderWidth;

  /// Surface corner radius.
  final WidgetStateProperty<BorderRadius?>? surfaceRadius;

  /// Surface elevation.
  final WidgetStateProperty<List<BoxShadow>?>? surfaceShadow;

  /// Gap between the cursor and the surface.
  final WidgetStateProperty<double?>? anchorOffset;

  /// Width of the series-coloured accent bar.
  final WidgetStateProperty<double?>? accentBarWidth;

  /// Top margin above the accent-barred block.
  final WidgetStateProperty<double?>? accentBarMarginTop;

  /// The x reading at the top of the surface.
  final WidgetStateProperty<TextStyle?>? xTextStyle;

  /// The series name.
  final WidgetStateProperty<TextStyle?>? legendTextStyle;

  /// The y reading.
  final WidgetStateProperty<TextStyle?>? valueTextStyle;

  /// Inline font-size override for the single-value y reading.
  final WidgetStateProperty<double?>? valueFontSize;

  /// The `numerator / denominator` wrapper.
  final WidgetStateProperty<TextStyle?>? ratioTextStyle;

  /// The numerator and denominator themselves.
  final WidgetStateProperty<TextStyle?>? ratioPartTextStyle;

  /// Inline-start margin before the ratio.
  final WidgetStateProperty<double?>? ratioMarginStart;

  /// The trailing description message.
  final WidgetStateProperty<TextStyle?>? descriptionTextStyle;

  /// Colour of the rule above the description.
  final WidgetStateProperty<Color?>? descriptionDividerColor;

  /// Space above and below that rule.
  final WidgetStateProperty<double?>? descriptionGap;

  /// Gap between multi-value columns.
  final WidgetStateProperty<double?>? columnGap;

  /// Top margin inside a multi-value row.
  final WidgetStateProperty<double?>? rowMarginTop;

  /// Colour of a multi-value row's bottom rule.
  final WidgetStateProperty<Color?>? rowDividerColor;

  /// Padding below a multi-value row that draws its rule.
  final WidgetStateProperty<double?>? rowPaddingBottom;

  /// This style with the non-null properties of [other] layered on top.
  FluentChartPopoverStyle merge(FluentChartPopoverStyle? other) {
    if (other == null) return this;
    return FluentChartPopoverStyle(
      surfacePadding: other.surfacePadding ?? surfacePadding,
      surfaceColor: other.surfaceColor ?? surfaceColor,
      surfaceBorderColor: other.surfaceBorderColor ?? surfaceBorderColor,
      surfaceBorderWidth: other.surfaceBorderWidth ?? surfaceBorderWidth,
      surfaceRadius: other.surfaceRadius ?? surfaceRadius,
      surfaceShadow: other.surfaceShadow ?? surfaceShadow,
      anchorOffset: other.anchorOffset ?? anchorOffset,
      accentBarWidth: other.accentBarWidth ?? accentBarWidth,
      accentBarMarginTop: other.accentBarMarginTop ?? accentBarMarginTop,
      xTextStyle: other.xTextStyle ?? xTextStyle,
      legendTextStyle: other.legendTextStyle ?? legendTextStyle,
      valueTextStyle: other.valueTextStyle ?? valueTextStyle,
      valueFontSize: other.valueFontSize ?? valueFontSize,
      ratioTextStyle: other.ratioTextStyle ?? ratioTextStyle,
      ratioPartTextStyle: other.ratioPartTextStyle ?? ratioPartTextStyle,
      ratioMarginStart: other.ratioMarginStart ?? ratioMarginStart,
      descriptionTextStyle: other.descriptionTextStyle ?? descriptionTextStyle,
      descriptionDividerColor:
          other.descriptionDividerColor ?? descriptionDividerColor,
      descriptionGap: other.descriptionGap ?? descriptionGap,
      columnGap: other.columnGap ?? columnGap,
      rowMarginTop: other.rowMarginTop ?? rowMarginTop,
      rowDividerColor: other.rowDividerColor ?? rowDividerColor,
      rowPaddingBottom: other.rowPaddingBottom ?? rowPaddingBottom,
    );
  }

  /// This style with the given properties replaced.
  ///
  /// Twenty-three named parameters, one per field, in declaration order.
  FluentChartPopoverStyle copyWith({
    WidgetStateProperty<EdgeInsetsGeometry?>? surfacePadding,
    WidgetStateProperty<Color?>? surfaceColor,
    WidgetStateProperty<Color?>? surfaceBorderColor,
    WidgetStateProperty<double?>? surfaceBorderWidth,
    WidgetStateProperty<BorderRadius?>? surfaceRadius,
    WidgetStateProperty<List<BoxShadow>?>? surfaceShadow,
    WidgetStateProperty<double?>? anchorOffset,
    WidgetStateProperty<double?>? accentBarWidth,
    WidgetStateProperty<double?>? accentBarMarginTop,
    WidgetStateProperty<TextStyle?>? xTextStyle,
    WidgetStateProperty<TextStyle?>? legendTextStyle,
    WidgetStateProperty<TextStyle?>? valueTextStyle,
    WidgetStateProperty<double?>? valueFontSize,
    WidgetStateProperty<TextStyle?>? ratioTextStyle,
    WidgetStateProperty<TextStyle?>? ratioPartTextStyle,
    WidgetStateProperty<double?>? ratioMarginStart,
    WidgetStateProperty<TextStyle?>? descriptionTextStyle,
    WidgetStateProperty<Color?>? descriptionDividerColor,
    WidgetStateProperty<double?>? descriptionGap,
    WidgetStateProperty<double?>? columnGap,
    WidgetStateProperty<double?>? rowMarginTop,
    WidgetStateProperty<Color?>? rowDividerColor,
    WidgetStateProperty<double?>? rowPaddingBottom,
  }) => merge(
    FluentChartPopoverStyle(
      surfacePadding: surfacePadding,
      surfaceColor: surfaceColor,
      surfaceBorderColor: surfaceBorderColor,
      surfaceBorderWidth: surfaceBorderWidth,
      surfaceRadius: surfaceRadius,
      surfaceShadow: surfaceShadow,
      anchorOffset: anchorOffset,
      accentBarWidth: accentBarWidth,
      accentBarMarginTop: accentBarMarginTop,
      xTextStyle: xTextStyle,
      legendTextStyle: legendTextStyle,
      valueTextStyle: valueTextStyle,
      valueFontSize: valueFontSize,
      ratioTextStyle: ratioTextStyle,
      ratioPartTextStyle: ratioPartTextStyle,
      ratioMarginStart: ratioMarginStart,
      descriptionTextStyle: descriptionTextStyle,
      descriptionDividerColor: descriptionDividerColor,
      descriptionGap: descriptionGap,
      columnGap: columnGap,
      rowMarginTop: rowMarginTop,
      rowDividerColor: rowDividerColor,
      rowPaddingBottom: rowPaddingBottom,
    ),
  );

  /// Convenience for the common case of one value across every state.
  static FluentChartPopoverStyle from({
    EdgeInsetsGeometry? surfacePadding,
    Color? surfaceColor,
    Color? surfaceBorderColor,
    double? surfaceBorderWidth,
    BorderRadius? surfaceRadius,
    List<BoxShadow>? surfaceShadow,
    double? anchorOffset,
    double? accentBarWidth,
    double? accentBarMarginTop,
    TextStyle? xTextStyle,
    TextStyle? legendTextStyle,
    TextStyle? valueTextStyle,
    double? valueFontSize,
    TextStyle? ratioTextStyle,
    TextStyle? ratioPartTextStyle,
    double? ratioMarginStart,
    TextStyle? descriptionTextStyle,
    Color? descriptionDividerColor,
    double? descriptionGap,
    double? columnGap,
    double? rowMarginTop,
    Color? rowDividerColor,
    double? rowPaddingBottom,
  }) => FluentChartPopoverStyle(
    surfacePadding: _all(surfacePadding),
    surfaceColor: _all(surfaceColor),
    surfaceBorderColor: _all(surfaceBorderColor),
    surfaceBorderWidth: _all(surfaceBorderWidth),
    surfaceRadius: _all(surfaceRadius),
    surfaceShadow: _all(surfaceShadow),
    anchorOffset: _all(anchorOffset),
    accentBarWidth: _all(accentBarWidth),
    accentBarMarginTop: _all(accentBarMarginTop),
    xTextStyle: _all(xTextStyle),
    legendTextStyle: _all(legendTextStyle),
    valueTextStyle: _all(valueTextStyle),
    valueFontSize: _all(valueFontSize),
    ratioTextStyle: _all(ratioTextStyle),
    ratioPartTextStyle: _all(ratioPartTextStyle),
    ratioMarginStart: _all(ratioMarginStart),
    descriptionTextStyle: _all(descriptionTextStyle),
    descriptionDividerColor: _all(descriptionDividerColor),
    descriptionGap: _all(descriptionGap),
    columnGap: _all(columnGap),
    rowMarginTop: _all(rowMarginTop),
    rowDividerColor: _all(rowDividerColor),
    rowPaddingBottom: _all(rowPaddingBottom),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  List<Object?> get _fields => <Object?>[
    surfacePadding,
    surfaceColor,
    surfaceBorderColor,
    surfaceBorderWidth,
    surfaceRadius,
    anchorOffset,
    accentBarWidth,
    accentBarMarginTop,
    xTextStyle,
    legendTextStyle,
    valueTextStyle,
    valueFontSize,
    ratioTextStyle,
    ratioPartTextStyle,
    ratioMarginStart,
    descriptionTextStyle,
    descriptionDividerColor,
    descriptionGap,
    columnGap,
    rowMarginTop,
    rowDividerColor,
    rowPaddingBottom,
    // `surfaceShadow` is spread rather than listed: WidgetStatePropertyAll
    // compares its value with `==`, and a `List` has no value equality, so two
    // separately resolved styles would never be equal. A BoxShadow is a value
    // type, so the shadows themselves compare and hash fine. A popover surface
    // has no interaction states (`overlays/popover.dart:183-185`), which is why
    // resolving against the empty set loses nothing.
    ...?surfaceShadow?.resolve(const <WidgetState>{}),
  ];

  @override
  bool operator ==(Object other) =>
      other is FluentChartPopoverStyle && listEquals(other._fields, _fields);

  // Twenty-three fields exceed Object.hash's twenty-argument ceiling.
  @override
  int get hashCode => Object.hashAll(_fields);
}

/// Resolves the theme-derived chart popover defaults from [theme].
FluentChartPopoverStyle resolveFluentChartPopoverStyle(FluentThemeData theme) {
  final text = FluentChartTextStyles.of(theme);
  // ChartPopover.tsx:52 renders a bare `<PopoverSurface>`, so the surface
  // itself is the package's own medium popover.
  final surface = resolveFluentPopoverStyle(
    const FluentPopoverState(
      position: FluentPopoverPosition.below,
      align: FluentPopoverAlign.start,
      withArrow: false,
      content: SizedBox.shrink(),
      appearance: FluentPopoverAppearance.normal,
      size: FluentPopoverSize.medium,
    ),
    theme,
  );

  return FluentChartPopoverStyle(
    surfacePadding: surface.padding,
    // useChartPopoverStyles.styles.ts:36 paints the content root itself, which
    // sits flush inside the surface, so the two colours are the same token.
    surfaceColor: WidgetStatePropertyAll<Color?>(
      theme.colors.neutralBackground1,
    ),
    // Flattened rather than passed through: the package builds its border
    // colour with FluentStateColor.tokens, a resolveWith closure, and a closure
    // has no value equality. The surface has no interaction states
    // (`overlays/popover.dart:183-185`), so the rest value is the whole ramp.
    surfaceBorderColor: WidgetStatePropertyAll<Color?>(
      surface.borderColor?.resolve(const <WidgetState>{}),
    ),
    surfaceBorderWidth: surface.borderWidth,
    surfaceRadius: surface.borderRadius,
    surfaceShadow: surface.shadow,
    anchorOffset: const WidgetStatePropertyAll<double?>(
      kChartPopoverAnchorOffset,
    ),
    accentBarWidth: const WidgetStatePropertyAll<double?>(
      kChartPopoverAccentBarWidth,
    ),
    accentBarMarginTop: const WidgetStatePropertyAll<double?>(
      kChartPopoverAccentBarMarginTop,
    ),
    xTextStyle: WidgetStatePropertyAll<TextStyle?>(text.popoverX),
    legendTextStyle: WidgetStatePropertyAll<TextStyle?>(text.popoverLegend),
    valueTextStyle: WidgetStatePropertyAll<TextStyle?>(text.popoverY),
    valueFontSize: const WidgetStatePropertyAll<double?>(
      kChartPopoverValueFontSize,
    ),
    ratioTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.caption2,
    ),
    ratioPartTextStyle: WidgetStatePropertyAll<TextStyle?>(
      text.popoverRatioNumerator,
    ),
    // useChartPopoverStyles.styles.ts:94 — spacingHorizontalSNudge is 6.
    ratioMarginStart: const WidgetStatePropertyAll<double?>(
      FluentSpacing.sNudge,
    ),
    descriptionTextStyle: WidgetStatePropertyAll<TextStyle?>(
      text.popoverDescription,
    ),
    descriptionDividerColor: WidgetStatePropertyAll<Color?>(
      theme.colors.neutralStroke2,
    ),
    // useChartPopoverStyles.styles.ts:88-89 — spacingVerticalMNudge is 10, set
    // as both the margin and the padding, so the visual gap is 20 split by the
    // rule.
    descriptionGap: const WidgetStatePropertyAll<double?>(FluentSpacing.mNudge),
    columnGap: const WidgetStatePropertyAll<double?>(kChartPopoverColumnGap),
    rowMarginTop: const WidgetStatePropertyAll<double?>(
      kChartPopoverRowMarginTop,
    ),
    rowDividerColor: WidgetStatePropertyAll<Color?>(
      theme.colors.neutralStroke2,
    ),
    rowPaddingBottom: const WidgetStatePropertyAll<double?>(
      kChartPopoverRowPaddingBottom,
    ),
  );
}
