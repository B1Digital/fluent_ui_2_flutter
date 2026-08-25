import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import 'chart_table_style.dart';
import 'chrome/chart_title.dart';
import 'internal/chart_colors.dart';

/// One cell of a [FluentChartTable].
///
/// Upstream types the cell as `{value, style?: React.CSSProperties}`
/// (`ChartTable.types.ts:9-20`), but only `color` and `backgroundColor` are
/// ever read (`ChartTable.tsx:137-139`, `:159-161`), so arbitrary CSS is not
/// modelled.
@immutable
class FluentChartTableCell {
  /// Creates a cell.
  const FluentChartTableCell({
    this.value,
    this.textStyle,
    this.backgroundColor,
  });

  /// The displayed value. `String`, `num`, `bool` and null are all accepted;
  /// null and `false` render as nothing, matching React.
  final Object? value;

  /// Per-cell text style. Only its [TextStyle.color] participates in the
  /// contrast passes.
  final TextStyle? textStyle;

  /// Requested background. Runs through [fluentChartTableSafeBackground]
  /// before it is painted.
  final Color? backgroundColor;

  @override
  bool operator ==(Object other) =>
      other is FluentChartTableCell &&
      other.value == value &&
      other.textStyle == textStyle &&
      other.backgroundColor == backgroundColor;

  @override
  int get hashCode => Object.hash(value, textStyle, backgroundColor);
}

/// Ports `getSafeBackgroundColor` (`ChartTable.tsx:23-47`).
///
/// Returns [background] when it already reaches a contrast of 3 against
/// [foreground]; otherwise the per-channel inversion `255 - c`
/// (`ChartTable.tsx:14-21`) when that reaches 3; otherwise
/// [FluentColors.neutralBackground1] out of [colors].
///
/// Upstream's final fallback returns the raw token *string*
/// `tokens.colorNeutralBackground1`, which outside a `var()` context is an
/// invalid CSS colour and paints transparent. That is a defect, not a rendering
/// rule, and reproducing "transparent" would remove the contrast guarantee the
/// whole function exists to provide — so this port returns the resolved
/// colour.
// ponytail: fixed rather than reproduced; ChartTable.tsx:47 returns an invalid
// CSS value and the bug removes an accessibility guarantee.
Color fluentChartTableSafeBackground({
  required Color? foreground,
  required Color? background,
  required FluentColors colors,
}) {
  // ChartTable.tsx:24-25, :30-31 — a missing side is the neutral token, not a
  // skipped measurement.
  final fg = foreground ?? colors.neutralForeground1;
  final bg = background ?? colors.neutralBackground1;
  // ChartTable.tsx:40 — threshold 3, not the WCAG text threshold of 4.5.
  if (fluentColorContrast(fg, bg) >= 3) {
    return bg;
  }
  // 255 is the 8-bit channel maximum `d3.rgb` inverts against
  // (`ChartTable.tsx:20`).
  final inverted = Color.fromARGB(
    0xFF,
    255 - (bg.r * 255).round(),
    255 - (bg.g * 255).round(),
    255 - (bg.b * 255).round(),
  );
  return fluentColorContrast(fg, inverted) >= 3
      ? inverted
      : colors.neutralBackground1;
}

/// The outcome of upstream's shared-header-background pass
/// (`ChartTable.tsx:60-91`).
@immutable
class FluentChartTableHeaderColours {
  const FluentChartTableHeaderColours._({
    required this.shared,
    required this.useShared,
  });

  /// Runs the heuristic over [headers], falling back to [colors] for nothing —
  /// it only ever reports a colour a header asked for.
  ///
  /// The set is built from the *opaque* form of each header background, which
  /// is what `d3.color(bg)?.formatHex()` produces upstream — `formatHex`
  /// discards alpha. Insertion order is preserved, because
  /// `ChartTable.tsx:82` indexes the set by position: element `[0]` for a set
  /// of size 1 but element `[1]` — the **second** distinct colour encountered
  /// — for a set of size 2. A set of size 3 or more skips the heuristic
  /// entirely and upstream lets the contrast fail (`ChartTable.tsx:78-79`).
  static FluentChartTableHeaderColours resolve(
    List<FluentChartTableCell> headers,
    FluentColors colors,
  ) {
    final distinct = <int>{};
    final ordered = <Color>[];
    for (final header in headers) {
      final bg = header.backgroundColor;
      if (bg == null) {
        continue;
      }
      final opaque = bg.withValues(alpha: 1);
      if (distinct.add(opaque.toARGB32())) {
        ordered.add(opaque);
      }
    }
    // ChartTable.tsx:81 — sizes 1 and 2 only.
    if (ordered.length == 1 || ordered.length == 2) {
      final candidate = ordered.length == 1 ? ordered[0] : ordered[1];
      for (final header in headers) {
        final fg = header.textStyle?.color;
        // ChartTable.tsx:85-89 — first match wins and breaks the loop.
        if (fg != null && fluentColorContrast(fg, candidate) >= 3) {
          return FluentChartTableHeaderColours._(
            shared: candidate,
            useShared: true,
          );
        }
      }
    }
    return const FluentChartTableHeaderColours._(
      shared: null,
      useShared: false,
    );
  }

  /// The colour applied to every header cell when [useShared] is true.
  final Color? shared;

  /// Whether the heuristic found a candidate.
  final bool useShared;
}

/// Applies a [FluentChartTableStyle] to every [FluentChartTable] below it.
class FluentChartTableTheme extends InheritedTheme {
  /// Applies [style] to every [FluentChartTable] in `child`.
  const FluentChartTableTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the derived defaults.
  final FluentChartTableStyle style;

  /// The nearest chart-table style, or null.
  static FluentChartTableStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentChartTableTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentChartTableTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentChartTableTheme(style: style, child: child);
}

/// A column that takes its share of the table in proportion to its content.
///
/// This is `table-layout: auto` on a table whose declared width exceeds the
/// width its content needs (`ChartTable.tsx:127-131` puts a width on the
/// `<table>` itself, and `useChartTableStyles.styles.ts:28-30` leaves the
/// layout mode at its `auto` default). Chromium hands the surplus to the
/// columns in *proportion to* their max-content width, not in equal shares:
/// measured off the capture, the six columns of
/// `charts-charttable--chart-table-basic` come out 129/114/117/117/118/103,
/// where an equal split of the same surplus would be 123/117/117/117/117/108.
///
/// Reporting the max-content width as the column's [flex] is what makes
/// [RenderTable] do it. With every column flexed, step 2 of
/// `rendering/table.dart`'s `_computeColumnWidths` leaves `unflexedTableWidth`
/// at zero and assigns each column `targetWidth * flex / totalFlex` — i.e.
/// `targetWidth * maxContent / sumOfMaxContent`. Step 4 then shrinks the same
/// way if the table is squeezed below its content, which is also what CSS
/// does.
class _ProportionalColumnWidth extends TableColumnWidth {
  const _ProportionalColumnWidth();

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    var result = 0.0;
    for (final cell in cells) {
      result = math.max(result, cell.getMinIntrinsicWidth(double.infinity));
    }
    return result;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    var result = 0.0;
    for (final cell in cells) {
      result = math.max(result, cell.getMaxIntrinsicWidth(double.infinity));
    }
    return result;
  }

  @override
  double? flex(Iterable<RenderBox> cells) {
    final width = maxIntrinsicWidth(cells, double.infinity);
    // RenderTable asserts a flex is strictly positive. A column with nothing
    // in it has no share to claim, and a null flex contributes zero to both
    // sides of the proportion, so the remaining columns split the whole width
    // between them exactly as they would have.
    return width > 0 ? width : null;
  }
}

/// A Fluent 2 chart table: tabular data with the same title treatment and
/// contrast guarantees as the painted charts.
///
/// This is the one member of the family with no painter, and the grid lines
/// are laid out rather than drawn over the top. `border-collapse: collapse`
/// (`useChartTableStyles.styles.ts:29`) merges the two adjacent 2px cell edges
/// into ONE 2px line, and that line still *occupies space*: the capture's
/// six-column, five-row grid is 700x172, of which 14x12 is grid line — seven
/// verticals and six horizontals — on top of the padding and the text. So
/// every cell owns the line along its top and left edge as a real [Border],
/// and the grid owns the right and bottom edges that no cell covers.
///
/// [TableBorder] cannot express that. `RenderTable`'s border is paint-only —
/// it appears in neither `_computeColumnWidths` nor `performLayout` — so it
/// strokes each line centred on a boundary that reserved nothing, and every
/// boundary falls short by one line width for each row or column before it.
/// That was this widget's bug: a 32px row pitch against upstream's 34, and a
/// grid 160 tall against 172.
// ponytail: the border is layout, not decoration; a Border per cell is both
// shorter than a grid painter and the only version that measures right.
class FluentChartTable extends StatelessWidget {
  /// Creates a chart table.
  const FluentChartTable({
    super.key,
    required this.headers,
    this.rows,
    this.width,
    this.height,
    this.columnWidth,
    this.chartTitle,
    this.style,
  });

  /// Header cells, left to right.
  final List<FluentChartTableCell> headers;

  /// Body rows. A null or empty list renders the header alone
  /// (`ChartTable.tsx:154`).
  final List<List<FluentChartTableCell>>? rows;

  /// Hard width. Null honours the incoming [BoxConstraints], which is the
  /// project rule; upstream's `'100%'` default (`ChartTable.tsx:96`) is the
  /// same intent.
  final double? width;

  /// Hard height. Null uses the style's `defaultHeight` of 650
  /// (`ChartTable.tsx:94`).
  final double? height;

  /// Fixed width of every column's own box, exclusive of the grid line it
  /// shares with its neighbour — so the pitch from one column to the next is
  /// this plus one border width, exactly as `border-collapse` gives in CSS.
  /// Null lets each column size to its content, which is what a `table` with
  /// no width does.
  final double? columnWidth;

  /// Optional title above the grid. Reserves the style's `titleHeight` of 30
  /// out of the total (`ChartTable.tsx:93`).
  final String? chartTitle;

  /// Style layered over the derived defaults and the nearest
  /// [FluentChartTableTheme].
  final FluentChartTableStyle? style;

  @override
  Widget build(BuildContext context) {
    // ChartTable.tsx:56-58 — plain text, no live region. Deliberately unlike
    // the other six charts in this plan.
    if (headers.isEmpty) {
      return Text(fluentL10n(context).chartNoDataAvailable);
    }

    final theme = FluentTheme.of(context);
    final resolved = resolveFluentChartTableStyle(
      theme,
    ).merge(FluentChartTableTheme.maybeOf(context)).merge(style);
    const states = <WidgetState>{};

    // useChartTableStyles.styles.ts:39-42 and :50-52 — under forced colours
    // the header fill becomes `Window`, both text colours become `WindowText`,
    // and no caller-supplied inline colour survives. So the whole contrast
    // pass is skipped rather than run against colours that will not be
    // painted.
    final isHighContrast = FluentChartColors.of(theme).isHighContrast;
    final headerColours = isHighContrast
        ? const FluentChartTableHeaderColours._(shared: null, useShared: false)
        : FluentChartTableHeaderColours.resolve(headers, theme.colors);
    final padding = resolved.cellPadding!.resolve(states)!;
    final headerText = resolved.headerTextStyle!.resolve(states)!;
    final bodyText = resolved.bodyTextStyle!.resolve(states)!;
    final headerBackground = resolved.headerBackgroundColor!.resolve(states);
    final borderWidth = resolved.borderWidth!.resolve(states)!;
    final gridLine = BorderSide(
      color: resolved.borderColor!.resolve(states)!,
      width: borderWidth,
    );

    Widget cell(
      FluentChartTableCell data, {
      required bool isHeader,
      required Color? background,
    }) {
      final content = data.value;
      // React renders null and false as nothing, but 0 and '' as themselves.
      final label = content == null || content == false
          ? ''
          : content.toString();
      final base = isHeader ? headerText : bodyText;
      Widget painted = Padding(
        padding: padding,
        child: Focus(
          child: Semantics(
            header: isHeader,
            child: Text(
              label,
              style: isHighContrast ? base : base.merge(data.textStyle),
            ),
          ),
        ),
      );
      if (background != null) {
        painted = ColoredBox(color: background, child: painted);
      }
      // The collapsed half of `border-collapse`: this cell's top and left
      // edges are the whole grid line it shares with the neighbour above and
      // to the left, so the neighbours declare nothing. `Container` turns the
      // border's own dimensions into layout padding, which is the part
      // [TableBorder] does not do — the fill starts *after* the line rather
      // than under it, and the line is what pushes the next row and column
      // along by its width.
      return Container(
        decoration: BoxDecoration(
          border: Border(top: gridLine, left: gridLine),
        ),
        child: painted,
      );
    }

    Color? cellBackground(FluentChartTableCell data, {required bool isHeader}) {
      if (isHighContrast) {
        return isHeader ? headerBackground : null;
      }
      // ChartTable.tsx:141-142 — the shared colour overrides every header's
      // own request, including a header that asked for a different one.
      if (isHeader && headerColours.useShared) {
        return headerColours.shared;
      }
      // ChartTable.tsx:143 and :162 gate the pass on `fg || bg`: a cell with
      // neither keeps the class default, which is `colorNeutralBackground3`
      // for a header (`useChartTableStyles.styles.ts:34`) and nothing at all
      // for a body cell (`:44-53` declares no background).
      if (data.backgroundColor == null && data.textStyle?.color == null) {
        return isHeader ? headerBackground : null;
      }
      return fluentChartTableSafeBackground(
        foreground: data.textStyle?.color,
        background: data.backgroundColor,
        colors: theme.colors,
      );
    }

    final table = Table(
      defaultColumnWidth: columnWidth == null
          ? const _ProportionalColumnWidth()
          // The shared line lives inside the column box now, so it is added
          // here to give the CSS pitch of cell width plus one collapsed
          // border.
          : FixedColumnWidth(columnWidth! + borderWidth),
      // A `<td>` is always as tall as its row, so the grid line down its left
      // edge runs the row's full height even when a neighbour wraps to two
      // lines. `intrinsicHeight` measures the cell first and then stretches it
      // to the row; `fill` skips the measuring pass and would leave every row
      // zero-high.
      defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
      children: <TableRow>[
        TableRow(
          children: <Widget>[
            for (final header in headers)
              cell(
                header,
                isHeader: true,
                background: cellBackground(header, isHeader: true),
              ),
          ],
        ),
        for (final row in rows ?? const <List<FluentChartTableCell>>[])
          TableRow(
            children: <Widget>[
              for (final item in row)
                cell(
                  item,
                  isHeader: false,
                  background: cellBackground(item, isHeader: false),
                ),
            ],
          ),
      ],
    );

    return SizedBox(
      width: width,
      height: height ?? resolved.defaultHeight!.resolve(states),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (chartTitle != null)
            SizedBox(
              height: resolved.titleHeight!.resolve(states),
              child: FluentChartTitle(
                title: chartTitle!,
                textStyle: resolved.titleTextStyle!.resolve(states),
                // ChartTable.tsx:97 — the tooltip trigger width is the table
                // width less 20; with no fixed width upstream passes
                // undefined and never truncates.
                maxWidth: width == null ? null : width! - 20,
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                // ChartTable.tsx:121-125 — overflow auto on both axes.
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    // ChartTable.tsx:127-131 — the width goes on the <table>,
                    // not on the root, and falls back to `100%`. Either way
                    // the grid fills the box it is given and only overflows —
                    // and so scrolls — when its own content will not fit,
                    // which is what a minimum rather than a fixed width buys.
                    // Without it the horizontal viewport hands the table an
                    // unbounded width and it shrink-wraps to its content:
                    // 376px against upstream's 700.
                    constraints: BoxConstraints(
                      minWidth: _gridMinWidth(constraints),
                    ),
                    child: Container(
                      // The other half of `border-collapse`: every cell owns
                      // its top and left line, so the grid's right and bottom
                      // edges are the two no cell covers.
                      decoration: BoxDecoration(
                        border: Border(right: gridLine, bottom: gridLine),
                      ),
                      child: table,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The width the grid is stretched to fill, given the box it sits in.
  ///
  /// `width` when the caller named one (`ChartTable.tsx:130`), the container
  /// otherwise (the `100%` on the same line). Zero — i.e. shrink-wrap — when
  /// [columnWidth] is set, because a caller who pinned a column width meant
  /// it, and when the container itself is unbounded and there is nothing to
  /// fill.
  double _gridMinWidth(BoxConstraints constraints) {
    if (columnWidth != null) {
      return 0;
    }
    return width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : 0);
  }
}
