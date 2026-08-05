import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentCalendar`.
///
/// Shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed and disabled values live on the
/// property rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the view defaults derived from the theme
/// 2. the nearest `FluentCalendarTheme`
/// 3. the widget's own `style`
///
/// ## Three cell colour families, not one
///
/// A day cell has three mutually exclusive roles — selected, today, and
/// ordinary — and upstream gives each its own ramp rather than one ramp with a
/// selected mode. Folding them into a single property would mean either
/// inventing values or writing a bespoke precedence helper; keeping them apart
/// means the renderer picks the *family* by role and plain
/// `FluentStateColor.tokens` resolves hover and pressed inside it. A hovered
/// selected day therefore resolves [selectedBackgroundColor] with
/// [WidgetState.hovered] in the set and lands on the right token with no
/// special case.
///
/// This is `FluentDataGridStyle`'s own argument applied one level down.
@immutable
class FluentCalendarStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentCalendarStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.shadow,
    this.padding,
    this.gap,
    this.dividerColor,
    this.dividerWidth,
    this.headerTextStyle,
    this.headerForegroundColor,
    this.headerBackgroundColor,
    this.headerPadding,
    this.headerBorderRadius,
    this.headerHeight,
    this.navButtonSize,
    this.navButtonForegroundColor,
    this.navButtonBackgroundColor,
    this.navButtonBorderRadius,
    this.navIconSize,
    this.weekdayTextStyle,
    this.weekdayForegroundColor,
    this.cellSize,
    this.cellSpacing,
    this.rowSpacing,
    this.dayButtonSize,
    this.cellBorderRadius,
    this.cellTextStyle,
    this.cellBackgroundColor,
    this.cellForegroundColor,
    this.outOfPageForegroundColor,
    this.todayBackgroundColor,
    this.todayForegroundColor,
    this.todayMarkerSize,
    this.selectedBackgroundColor,
    this.selectedForegroundColor,
    this.selectedBorderColor,
    this.selectedBorderWidth,
    this.goToTodayTextStyle,
    this.goToTodayForegroundColor,
    this.mouseCursor,
  });

  /// Fill behind the whole calendar.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Colour of the rule around the calendar.
  ///
  /// Never `Colors.transparent`: Fluent's stroke tokens turn opaque in high
  /// contrast, where this rule is the only thing bounding the surface.
  final WidgetStateProperty<Color?>? borderColor;

  /// Thickness of the rule around the calendar.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius of the calendar surface.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Elevation cast by the calendar surface.
  ///
  /// Empty by default. A calendar hosted in a `FluentDatePicker` popup already
  /// sits on an elevated surface, and a standalone one reads as a card off
  /// [borderColor] alone; two shadows stacked is the more common mistake.
  final WidgetStateProperty<List<BoxShadow>?>? shadow;

  /// Inset between the calendar surface and its header and grid.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between the header row and the grid below it.
  final WidgetStateProperty<double?>? gap;

  /// Colour of the rule between two panels.
  ///
  /// Upstream draws it as a `borderRight` on the day picker
  /// (`useDividerStyles`), which is why it is a token rather than a gap.
  final WidgetStateProperty<Color?>? dividerColor;

  /// Thickness of the rule between two panels.
  final WidgetStateProperty<double?>? dividerWidth;

  /// Type ramp of the caption — `March 2026`, `2026`, `2020 - 2031`. Its colour
  /// is overridden by [headerForegroundColor].
  final WidgetStateProperty<TextStyle?>? headerTextStyle;

  /// Caption colour.
  final WidgetStateProperty<Color?>? headerForegroundColor;

  /// Caption fill. Transparent at rest — the caption only reads as a button
  /// once it is hovered.
  final WidgetStateProperty<Color?>? headerBackgroundColor;

  /// Inset inside the caption button. Asymmetric upstream: the caption is
  /// inset further from the left edge than from the chevrons it sits beside.
  final WidgetStateProperty<EdgeInsetsGeometry?>? headerPadding;

  /// Corner radius of the caption button.
  final WidgetStateProperty<BorderRadius?>? headerBorderRadius;

  /// Height of the header row, chevrons included.
  final WidgetStateProperty<double?>? headerHeight;

  /// Edge lengths of a previous/next chevron button.
  final WidgetStateProperty<Size?>? navButtonSize;

  /// Chevron glyph colour. Null when the chevron is out of bounds resolves
  /// through [WidgetState.disabled], not by hiding the button — upstream keeps
  /// it in the tab order so focus is not lost when it becomes disabled after a
  /// click.
  final WidgetStateProperty<Color?>? navButtonForegroundColor;

  /// Chevron button fill.
  final WidgetStateProperty<Color?>? navButtonBackgroundColor;

  /// Corner radius of a chevron button.
  final WidgetStateProperty<BorderRadius?>? navButtonBorderRadius;

  /// Edge length of the chevron glyph inside its button.
  final WidgetStateProperty<double?>? navIconSize;

  /// Type ramp of the weekday header row. Its colour is overridden by
  /// [weekdayForegroundColor].
  final WidgetStateProperty<TextStyle?>? weekdayTextStyle;

  /// Weekday header colour.
  final WidgetStateProperty<Color?>? weekdayForegroundColor;

  /// The grid slot one cell occupies, spacing excluded.
  final WidgetStateProperty<Size?>? cellSize;

  /// Horizontal space between grid slots. Zero in the month view, where the
  /// day cells tile edge to edge and their own padding provides the gap.
  final WidgetStateProperty<double?>? cellSpacing;

  /// Vertical space between grid rows. Upstream sets this independently of
  /// [cellSpacing] in the year and decade views, so the two are separate.
  final WidgetStateProperty<double?>? rowSpacing;

  /// Edge lengths of the painted surface inside a month-view day cell.
  ///
  /// Smaller than [cellSize]: upstream pads the cell and paints only the inner
  /// button, so adjacent days do not touch. Ignored in the year and decade
  /// views, where the painted surface fills the whole slot.
  final WidgetStateProperty<Size?>? dayButtonSize;

  /// Corner radius of a cell's painted surface.
  final WidgetStateProperty<BorderRadius?>? cellBorderRadius;

  /// Type ramp of a cell's label. Its colour is overridden by the foreground
  /// property of whichever role the cell is in.
  final WidgetStateProperty<TextStyle?>? cellTextStyle;

  /// Fill of an ordinary cell — neither selected nor today.
  final WidgetStateProperty<Color?>? cellBackgroundColor;

  /// Label colour of an ordinary cell.
  final WidgetStateProperty<Color?>? cellForegroundColor;

  /// Label colour of a cell belonging to an adjacent month or decade.
  ///
  /// A separate token, never a dimmed [cellForegroundColor]: Fluent ships an
  /// explicit ramp for this and computing one with opacity would be the wrong
  /// value in high contrast.
  final WidgetStateProperty<Color?>? outOfPageForegroundColor;

  /// Fill of the marker drawn behind today's label.
  final WidgetStateProperty<Color?>? todayBackgroundColor;

  /// Label colour of today.
  final WidgetStateProperty<Color?>? todayForegroundColor;

  /// Edge lengths of the circular marker behind today's label. Smaller than
  /// [dayButtonSize] — upstream draws a disc inside the button, not a filled
  /// square.
  final WidgetStateProperty<Size?>? todayMarkerSize;

  /// Fill of the selected cell.
  final WidgetStateProperty<Color?>? selectedBackgroundColor;

  /// Label colour of the selected cell.
  final WidgetStateProperty<Color?>? selectedForegroundColor;

  /// Colour of the ring around the selected cell. Upstream draws this in
  /// addition to the fill, so a selected day survives high contrast where the
  /// fill flattens.
  final WidgetStateProperty<Color?>? selectedBorderColor;

  /// Thickness of the ring around the selected cell.
  final WidgetStateProperty<double?>? selectedBorderWidth;

  /// Type ramp of the "go to today" link. Its colour is overridden by
  /// [goToTodayForegroundColor].
  final WidgetStateProperty<TextStyle?>? goToTodayTextStyle;

  /// Colour of the "go to today" link.
  final WidgetStateProperty<Color?>? goToTodayForegroundColor;

  /// Cursor over a selectable cell.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [cellSize] keeps
  /// every resolved colour.
  FluentCalendarStyle merge(FluentCalendarStyle? other) {
    if (other == null) return this;
    return FluentCalendarStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      shadow: other.shadow ?? shadow,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      dividerColor: other.dividerColor ?? dividerColor,
      dividerWidth: other.dividerWidth ?? dividerWidth,
      headerTextStyle: other.headerTextStyle ?? headerTextStyle,
      headerForegroundColor:
          other.headerForegroundColor ?? headerForegroundColor,
      headerBackgroundColor:
          other.headerBackgroundColor ?? headerBackgroundColor,
      headerPadding: other.headerPadding ?? headerPadding,
      headerBorderRadius: other.headerBorderRadius ?? headerBorderRadius,
      headerHeight: other.headerHeight ?? headerHeight,
      navButtonSize: other.navButtonSize ?? navButtonSize,
      navButtonForegroundColor:
          other.navButtonForegroundColor ?? navButtonForegroundColor,
      navButtonBackgroundColor:
          other.navButtonBackgroundColor ?? navButtonBackgroundColor,
      navButtonBorderRadius:
          other.navButtonBorderRadius ?? navButtonBorderRadius,
      navIconSize: other.navIconSize ?? navIconSize,
      weekdayTextStyle: other.weekdayTextStyle ?? weekdayTextStyle,
      weekdayForegroundColor:
          other.weekdayForegroundColor ?? weekdayForegroundColor,
      cellSize: other.cellSize ?? cellSize,
      cellSpacing: other.cellSpacing ?? cellSpacing,
      rowSpacing: other.rowSpacing ?? rowSpacing,
      dayButtonSize: other.dayButtonSize ?? dayButtonSize,
      cellBorderRadius: other.cellBorderRadius ?? cellBorderRadius,
      cellTextStyle: other.cellTextStyle ?? cellTextStyle,
      cellBackgroundColor: other.cellBackgroundColor ?? cellBackgroundColor,
      cellForegroundColor: other.cellForegroundColor ?? cellForegroundColor,
      outOfPageForegroundColor:
          other.outOfPageForegroundColor ?? outOfPageForegroundColor,
      todayBackgroundColor: other.todayBackgroundColor ?? todayBackgroundColor,
      todayForegroundColor: other.todayForegroundColor ?? todayForegroundColor,
      todayMarkerSize: other.todayMarkerSize ?? todayMarkerSize,
      selectedBackgroundColor:
          other.selectedBackgroundColor ?? selectedBackgroundColor,
      selectedForegroundColor:
          other.selectedForegroundColor ?? selectedForegroundColor,
      selectedBorderColor: other.selectedBorderColor ?? selectedBorderColor,
      selectedBorderWidth: other.selectedBorderWidth ?? selectedBorderWidth,
      goToTodayTextStyle: other.goToTodayTextStyle ?? goToTodayTextStyle,
      goToTodayForegroundColor:
          other.goToTodayForegroundColor ?? goToTodayForegroundColor,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentCalendarStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<List<BoxShadow>?>? shadow,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<Color?>? dividerColor,
    WidgetStateProperty<double?>? dividerWidth,
    WidgetStateProperty<TextStyle?>? headerTextStyle,
    WidgetStateProperty<Color?>? headerForegroundColor,
    WidgetStateProperty<Color?>? headerBackgroundColor,
    WidgetStateProperty<EdgeInsetsGeometry?>? headerPadding,
    WidgetStateProperty<BorderRadius?>? headerBorderRadius,
    WidgetStateProperty<double?>? headerHeight,
    WidgetStateProperty<Size?>? navButtonSize,
    WidgetStateProperty<Color?>? navButtonForegroundColor,
    WidgetStateProperty<Color?>? navButtonBackgroundColor,
    WidgetStateProperty<BorderRadius?>? navButtonBorderRadius,
    WidgetStateProperty<double?>? navIconSize,
    WidgetStateProperty<TextStyle?>? weekdayTextStyle,
    WidgetStateProperty<Color?>? weekdayForegroundColor,
    WidgetStateProperty<Size?>? cellSize,
    WidgetStateProperty<double?>? cellSpacing,
    WidgetStateProperty<double?>? rowSpacing,
    WidgetStateProperty<Size?>? dayButtonSize,
    WidgetStateProperty<BorderRadius?>? cellBorderRadius,
    WidgetStateProperty<TextStyle?>? cellTextStyle,
    WidgetStateProperty<Color?>? cellBackgroundColor,
    WidgetStateProperty<Color?>? cellForegroundColor,
    WidgetStateProperty<Color?>? outOfPageForegroundColor,
    WidgetStateProperty<Color?>? todayBackgroundColor,
    WidgetStateProperty<Color?>? todayForegroundColor,
    WidgetStateProperty<Size?>? todayMarkerSize,
    WidgetStateProperty<Color?>? selectedBackgroundColor,
    WidgetStateProperty<Color?>? selectedForegroundColor,
    WidgetStateProperty<Color?>? selectedBorderColor,
    WidgetStateProperty<double?>? selectedBorderWidth,
    WidgetStateProperty<TextStyle?>? goToTodayTextStyle,
    WidgetStateProperty<Color?>? goToTodayForegroundColor,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentCalendarStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    shadow: shadow ?? this.shadow,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    dividerColor: dividerColor ?? this.dividerColor,
    dividerWidth: dividerWidth ?? this.dividerWidth,
    headerTextStyle: headerTextStyle ?? this.headerTextStyle,
    headerForegroundColor: headerForegroundColor ?? this.headerForegroundColor,
    headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
    headerPadding: headerPadding ?? this.headerPadding,
    headerBorderRadius: headerBorderRadius ?? this.headerBorderRadius,
    headerHeight: headerHeight ?? this.headerHeight,
    navButtonSize: navButtonSize ?? this.navButtonSize,
    navButtonForegroundColor:
        navButtonForegroundColor ?? this.navButtonForegroundColor,
    navButtonBackgroundColor:
        navButtonBackgroundColor ?? this.navButtonBackgroundColor,
    navButtonBorderRadius: navButtonBorderRadius ?? this.navButtonBorderRadius,
    navIconSize: navIconSize ?? this.navIconSize,
    weekdayTextStyle: weekdayTextStyle ?? this.weekdayTextStyle,
    weekdayForegroundColor:
        weekdayForegroundColor ?? this.weekdayForegroundColor,
    cellSize: cellSize ?? this.cellSize,
    cellSpacing: cellSpacing ?? this.cellSpacing,
    rowSpacing: rowSpacing ?? this.rowSpacing,
    dayButtonSize: dayButtonSize ?? this.dayButtonSize,
    cellBorderRadius: cellBorderRadius ?? this.cellBorderRadius,
    cellTextStyle: cellTextStyle ?? this.cellTextStyle,
    cellBackgroundColor: cellBackgroundColor ?? this.cellBackgroundColor,
    cellForegroundColor: cellForegroundColor ?? this.cellForegroundColor,
    outOfPageForegroundColor:
        outOfPageForegroundColor ?? this.outOfPageForegroundColor,
    todayBackgroundColor: todayBackgroundColor ?? this.todayBackgroundColor,
    todayForegroundColor: todayForegroundColor ?? this.todayForegroundColor,
    todayMarkerSize: todayMarkerSize ?? this.todayMarkerSize,
    selectedBackgroundColor:
        selectedBackgroundColor ?? this.selectedBackgroundColor,
    selectedForegroundColor:
        selectedForegroundColor ?? this.selectedForegroundColor,
    selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
    selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
    goToTodayTextStyle: goToTodayTextStyle ?? this.goToTodayTextStyle,
    goToTodayForegroundColor:
        goToTodayForegroundColor ?? this.goToTodayForegroundColor,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state — which, for a calendar, is
  /// most of the colours.
  static FluentCalendarStyle from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    EdgeInsetsGeometry? padding,
    double? gap,
    Color? dividerColor,
    double? dividerWidth,
    TextStyle? headerTextStyle,
    Color? headerForegroundColor,
    Color? headerBackgroundColor,
    EdgeInsetsGeometry? headerPadding,
    BorderRadius? headerBorderRadius,
    double? headerHeight,
    Size? navButtonSize,
    Color? navButtonForegroundColor,
    Color? navButtonBackgroundColor,
    BorderRadius? navButtonBorderRadius,
    double? navIconSize,
    TextStyle? weekdayTextStyle,
    Color? weekdayForegroundColor,
    Size? cellSize,
    double? cellSpacing,
    double? rowSpacing,
    Size? dayButtonSize,
    BorderRadius? cellBorderRadius,
    TextStyle? cellTextStyle,
    Color? cellBackgroundColor,
    Color? cellForegroundColor,
    Color? outOfPageForegroundColor,
    Color? todayBackgroundColor,
    Color? todayForegroundColor,
    Size? todayMarkerSize,
    Color? selectedBackgroundColor,
    Color? selectedForegroundColor,
    Color? selectedBorderColor,
    double? selectedBorderWidth,
    TextStyle? goToTodayTextStyle,
    Color? goToTodayForegroundColor,
    MouseCursor? mouseCursor,
  }) => FluentCalendarStyle(
    backgroundColor: _all(backgroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    shadow: _all(shadow),
    padding: _all(padding),
    gap: _all(gap),
    dividerColor: _all(dividerColor),
    dividerWidth: _all(dividerWidth),
    headerTextStyle: _all(headerTextStyle),
    headerForegroundColor: _all(headerForegroundColor),
    headerBackgroundColor: _all(headerBackgroundColor),
    headerPadding: _all(headerPadding),
    headerBorderRadius: _all(headerBorderRadius),
    headerHeight: _all(headerHeight),
    navButtonSize: _all(navButtonSize),
    navButtonForegroundColor: _all(navButtonForegroundColor),
    navButtonBackgroundColor: _all(navButtonBackgroundColor),
    navButtonBorderRadius: _all(navButtonBorderRadius),
    navIconSize: _all(navIconSize),
    weekdayTextStyle: _all(weekdayTextStyle),
    weekdayForegroundColor: _all(weekdayForegroundColor),
    cellSize: _all(cellSize),
    cellSpacing: _all(cellSpacing),
    rowSpacing: _all(rowSpacing),
    dayButtonSize: _all(dayButtonSize),
    cellBorderRadius: _all(cellBorderRadius),
    cellTextStyle: _all(cellTextStyle),
    cellBackgroundColor: _all(cellBackgroundColor),
    cellForegroundColor: _all(cellForegroundColor),
    outOfPageForegroundColor: _all(outOfPageForegroundColor),
    todayBackgroundColor: _all(todayBackgroundColor),
    todayForegroundColor: _all(todayForegroundColor),
    todayMarkerSize: _all(todayMarkerSize),
    selectedBackgroundColor: _all(selectedBackgroundColor),
    selectedForegroundColor: _all(selectedForegroundColor),
    selectedBorderColor: _all(selectedBorderColor),
    selectedBorderWidth: _all(selectedBorderWidth),
    goToTodayTextStyle: _all(goToTodayTextStyle),
    goToTodayForegroundColor: _all(goToTodayForegroundColor),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentCalendarStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.shadow == shadow &&
      other.padding == padding &&
      other.gap == gap &&
      other.dividerColor == dividerColor &&
      other.dividerWidth == dividerWidth &&
      other.headerTextStyle == headerTextStyle &&
      other.headerForegroundColor == headerForegroundColor &&
      other.headerBackgroundColor == headerBackgroundColor &&
      other.headerPadding == headerPadding &&
      other.headerBorderRadius == headerBorderRadius &&
      other.headerHeight == headerHeight &&
      other.navButtonSize == navButtonSize &&
      other.navButtonForegroundColor == navButtonForegroundColor &&
      other.navButtonBackgroundColor == navButtonBackgroundColor &&
      other.navButtonBorderRadius == navButtonBorderRadius &&
      other.navIconSize == navIconSize &&
      other.weekdayTextStyle == weekdayTextStyle &&
      other.weekdayForegroundColor == weekdayForegroundColor &&
      other.cellSize == cellSize &&
      other.cellSpacing == cellSpacing &&
      other.rowSpacing == rowSpacing &&
      other.dayButtonSize == dayButtonSize &&
      other.cellBorderRadius == cellBorderRadius &&
      other.cellTextStyle == cellTextStyle &&
      other.cellBackgroundColor == cellBackgroundColor &&
      other.cellForegroundColor == cellForegroundColor &&
      other.outOfPageForegroundColor == outOfPageForegroundColor &&
      other.todayBackgroundColor == todayBackgroundColor &&
      other.todayForegroundColor == todayForegroundColor &&
      other.todayMarkerSize == todayMarkerSize &&
      other.selectedBackgroundColor == selectedBackgroundColor &&
      other.selectedForegroundColor == selectedForegroundColor &&
      other.selectedBorderColor == selectedBorderColor &&
      other.selectedBorderWidth == selectedBorderWidth &&
      other.goToTodayTextStyle == goToTodayTextStyle &&
      other.goToTodayForegroundColor == goToTodayForegroundColor &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    shadow,
    padding,
    gap,
    dividerColor,
    dividerWidth,
    headerTextStyle,
    headerForegroundColor,
    headerBackgroundColor,
    headerPadding,
    headerBorderRadius,
    headerHeight,
    navButtonSize,
    navButtonForegroundColor,
    navButtonBackgroundColor,
    navButtonBorderRadius,
    navIconSize,
    weekdayTextStyle,
    weekdayForegroundColor,
    cellSize,
    cellSpacing,
    rowSpacing,
    dayButtonSize,
    cellBorderRadius,
    cellTextStyle,
    cellBackgroundColor,
    cellForegroundColor,
    outOfPageForegroundColor,
    todayBackgroundColor,
    todayForegroundColor,
    todayMarkerSize,
    selectedBackgroundColor,
    selectedForegroundColor,
    selectedBorderColor,
    selectedBorderWidth,
    goToTodayTextStyle,
    goToTodayForegroundColor,
    mouseCursor,
  ]);
}
