import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../model/chart_annotation.dart';
import '../d3/color.dart' as d3;
import 'json_guard.dart';

/// How one coordinate of a Plotly annotation is referenced.
///
/// Ports the `AxisRefType` union (`PlotlySchemaAdapter.ts:557`). Upstream's
/// fourth state is `undefined`, meaning "this reference names the other axis,
/// or a domain that is not ours" — a nullable of this enum carries it.
enum _RefType {
  /// `x`, `y`, `xaxis2`: a data coordinate on a named axis.
  axis,

  /// `paper` or `x domain`: a fraction of the plot area.
  relative,

  /// `pixel`: a pixel offset.
  pixel,
}

/// A parsed axis reference (`PlotlySchemaAdapter.ts:559-562`).
typedef _ParsedAxisRef = ({_RefType? refType, int axisId});

/// `PlotlySchemaAdapter.ts:564` — `^([xy])(axis)?(\d*)$`, the alias grammar
/// shared by `x`, `x2`, `xaxis`, and `xaxis2`.
final RegExp _axisAlias = RegExp(r'^([xy])(axis)?(\d*)$');

/// `PlotlySchemaAdapter.ts:665` — the shorthand-only grammar `resolveRefType`
/// re-tests with, which rejects the long `xaxis2` form the alias grammar takes.
final RegExp _axisShorthand = RegExp(r'^([xy])(\d*)$');

/// JavaScript truthiness for a decoded JSON value.
///
/// `PlotlySchemaAdapter.ts:917` and `:921` coerce with `!!`, and `:998`, `:1002`
/// and `:1027` test a string for emptiness the same way. Dart has no such
/// coercion, so the rule is written once: `false`, `0`, `''` and `null` are
/// falsey and everything else is truthy.
bool _isTruthy(Object? value) {
  if (value == null || value == false) {
    return false;
  }
  if (value is num) {
    return value != 0 && !value.isNaN;
  }
  if (value is String) {
    return value.isNotEmpty;
  }
  return true;
}

/// `PlotlySchemaAdapter.ts:550-556` — `Number(value)`, kept only when finite.
///
/// The empty-string arm is JavaScript's, not a convenience: `Number('')` is 0,
/// and dropping it would turn an empty `ax` into no offset instead of a zero
/// one. A `bool` returns null rather than JavaScript's 0/1, because no Plotly
/// numeric field is ever written as a boolean and a silent 1 would be worse
/// than a drop.
double? _toFiniteNumber(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.isFinite ? value.toDouble() : null;
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 0;
    }
    final parsed = double.tryParse(trimmed);
    return parsed != null && parsed.isFinite ? parsed : null;
  }
  return null;
}

/// Parses a Plotly axis reference into a reference type and an axis id.
///
/// `PlotlySchemaAdapter.ts:568-599`. `x`, `x2`, `xaxis2`, `paper`, `pixel` and
/// `x domain` all arrive here.
_ParsedAxisRef _parseAxisRef(String? ref, String axis) {
  if (ref == null || ref.isEmpty) {
    return (refType: _RefType.axis, axisId: 1);
  }

  final normalised = ref.toLowerCase().trim();
  if (normalised == 'pixel') {
    return (refType: _RefType.pixel, axisId: 1);
  }
  if (normalised == 'paper') {
    return (refType: _RefType.relative, axisId: 1);
  }
  if (normalised.endsWith(' domain')) {
    // `:580-582` — `x domain` is relative to the x plot area, and only to it;
    // a `y domain` read as an x reference resolves to nothing.
    return normalised.startsWith(axis)
        ? (refType: _RefType.relative, axisId: 1)
        : (refType: null, axisId: 1);
  }

  final match = _axisAlias.firstMatch(normalised);
  if (match == null || match.group(1) != axis) {
    return (refType: null, axisId: 1);
  }

  final suffix = match.group(3);
  if (suffix == null || suffix.isEmpty || suffix == '1') {
    return (refType: _RefType.axis, axisId: 1);
  }

  final parsed = int.tryParse(suffix);
  // `:597-598` — a non-finite or sub-1 index falls back to the first axis.
  return (
    refType: _RefType.axis,
    axisId: parsed != null && parsed >= 1 ? parsed : 1,
  );
}

/// Flips Plotly's bottom-origin relative y into the top-origin space the
/// annotation layer paints in (`PlotlySchemaAdapter.ts:601-609`).
double? _transformRelativeYForChart(double? value) {
  if (value == null || !value.isFinite) {
    return null;
  }
  // `:608` — the plot area is one unit tall in both spaces, so the flip is a
  // subtraction from 1 rather than a scale.
  return 1 - value;
}

/// `PlotlySchemaAdapter.ts:611-622` — `left`, `center`, `right`.
FluentChartAnnotationAlign? _mapHorizontalAlign(Object? anchor) {
  return switch (anchor is String ? anchor.toLowerCase() : '') {
    'left' => FluentChartAnnotationAlign.start,
    'center' => FluentChartAnnotationAlign.center,
    'right' => FluentChartAnnotationAlign.end,
    _ => null,
  };
}

/// `PlotlySchemaAdapter.ts:624-635` — `top`, `middle`, `bottom`, unchanged.
FluentChartAnnotationVerticalAlign? _mapVerticalAlign(Object? anchor) {
  return switch (anchor is String ? anchor.toLowerCase() : '') {
    'top' => FluentChartAnnotationVerticalAlign.top,
    'middle' => FluentChartAnnotationVerticalAlign.middle,
    'bottom' => FluentChartAnnotationVerticalAlign.bottom,
    _ => null,
  };
}

/// `PlotlySchemaAdapter.ts:637-651`, retyped.
///
/// Upstream returns a CSS length string, because its consumer is a `style`
/// object; [FluentChartAnnotationStyle] takes a `double` and an [EdgeInsets],
/// so the `${value}px` round-trip collapses into the one number the caller
/// wanted. The string arm at `:643-645` therefore parses instead of passing
/// through, which also drops the CSS keywords (`auto`, `inherit`) that a
/// Flutter length cannot express.
double? _pixels(Object? value) {
  if (value is num) {
    return value.isFinite ? value.toDouble() : null;
  }
  if (value is String) {
    final parsed = double.tryParse(value.trim().replaceAll('px', ''));
    return parsed != null && parsed.isFinite ? parsed : null;
  }
  return null;
}

/// Maps an axis reference onto one of the three coordinate modes
/// (`PlotlySchemaAdapter.ts:653-667`).
///
/// The second, narrower regex at `:665-666` is deliberate upstream behaviour and
/// not a redundancy: `parseAxisRef` accepts `xaxis2`, and this re-test rejects
/// it, so only the shorthand `x`/`x2` forms resolve as an annotation anchor.
_RefType? _resolveRefType(Object? ref, String axis) {
  if (ref is! String || ref.isEmpty) {
    return _RefType.axis;
  }
  final parsed = _parseAxisRef(ref, axis);
  if (parsed.refType != _RefType.axis) {
    return parsed.refType;
  }
  final match = _axisShorthand.firstMatch(ref.toLowerCase().trim());
  return match != null && match.group(1) == axis ? _RefType.axis : null;
}

/// The layout section an annotation's axis reference names
/// (`PlotlySchemaAdapter.ts:669-686`).
Map<String, Object?>? _getAxisLayoutByRef(
  Map<String, Object?>? layout,
  Object? ref,
  String axis,
) {
  if (layout == null) {
    return null;
  }
  final parsed = _parseAxisRef(ref is String ? ref : null, axis);
  final key = parsed.refType != _RefType.axis || parsed.axisId == 1
      // `:681-683` — anything that is not a numbered data axis reads the
      // default `xaxis`/`yaxis` section.
      ? '${axis}axis'
      : '${axis}axis${parsed.axisId}';
  final section = layout[key];
  return section is Map<String, Object?> ? section : null;
}

/// Coerces an annotation coordinate against the axis type it is drawn on
/// (`PlotlySchemaAdapter.ts:688-714`).
///
/// [axisType] is the raw `type` string from the layout's axis section, which is
/// what `:834` reads. It is deliberately not `getAxisType` from `axis.dart`:
/// that function infers a type from the traces, and this converter is handed no
/// traces (see [getChartAnnotationsFromLayout]).
Object? _convertAnnotationDataValue(Object? value, String axisType) {
  if (value == null) {
    return null;
  }

  if (axisType == 'date') {
    if (value is DateTime) {
      return value;
    }
    // `:692` is `new Date(value)`: a number is epoch milliseconds and a string
    // is parsed. Dart reads a bare `2020-03-01` as local midnight where
    // JavaScript reads it as UTC; local is the reading the rest of this port
    // uses, so a date annotation lands on the same tick as its axis.
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.round());
    }
    return value is String ? DateTime.tryParse(value) : null;
  }

  if (axisType == 'linear' || axisType == 'log') {
    return _toFiniteNumber(value);
  }

  // `:709-713` — a category-like axis keeps its raw string, so no date
  // heuristic can rewrite a label that merely looks like a year.
  if (value is DateTime || value is num || value is String) {
    return value;
  }
  return null;
}

/// A stable id for the annotation at [index], slugged from [text].
///
/// `PlotlySchemaAdapter.ts:716-729`.
String createAnnotationId(String text, int index) {
  final normalised = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalised.isNotEmpty) {
    final hyphenated = normalised
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    // `:723` — 32 is upstream's cap, and the trim above runs before it, so a
    // cut that lands on a separator keeps a trailing hyphen. Faithful: the id
    // is an identity, and a prettier one here would not match the id any React
    // consumer of the same schema produced.
    const idSlugLength = 32;
    final slug = hyphenated.length <= idSlugLength
        ? hyphenated
        : hyphenated.substring(0, idSlugLength);
    if (slug.isNotEmpty) {
      return 'annotation-$index-$slug';
    }
  }
  return 'annotation-$index';
}

/// How far an arrowed annotation sits above its anchor when it names no offset.
///
/// `DEFAULT_ARROW_OFFSET` (`PlotlySchemaAdapter.ts:731`). Negative because the
/// annotation layer's y grows downwards.
const double kDefaultArrowOffset = -40;

/// Which ends of the connector carry an arrow head
/// (`PlotlySchemaAdapter.ts:733-763`).
///
/// Both spellings are read, and they union rather than override: `arrowside` is
/// a substring test over `start`/`end`, and a positive `arrowhead` or
/// `startarrowhead` adds its own end on top.
FluentChartAnnotationArrowHead mapArrowsideToArrow(
  Map<String, Object?> annotation,
) {
  var includeStart = false;
  var includeEnd = false;

  final side = annotation['arrowside'];
  if (side is String && side.isNotEmpty) {
    final normalised = side.toLowerCase();
    includeStart = normalised.contains('start');
    includeEnd = normalised.contains('end');
  }

  // `:746-751` — only a positive head index draws one; Plotly's 0 is "no head".
  final endHead = _toFiniteNumber(annotation['arrowhead']);
  final startHead = _toFiniteNumber(annotation['startarrowhead']);
  if (endHead != null && endHead > 0) {
    includeEnd = true;
  }
  if (startHead != null && startHead > 0) {
    includeStart = true;
  }

  if (includeStart && includeEnd) {
    return FluentChartAnnotationArrowHead.both;
  }
  if (includeStart) {
    return FluentChartAnnotationArrowHead.start;
  }
  if (includeEnd) {
    return FluentChartAnnotationArrowHead.end;
  }
  return FluentChartAnnotationArrowHead.none;
}

/// `PlotlySchemaAdapter.ts:786` — a bare dash list such as `4 2` or `4,2`,
/// which is passed through rather than mapped.
final RegExp _numericDashList = RegExp(r'^\d+(\s|,)*\d*$');

/// The SVG `stroke-dasharray` for a Plotly [dash] name
/// (`PlotlySchemaAdapter.ts:765-791`).
String? mapArrowDashToPattern(String? dash) {
  if (dash == null || dash.isEmpty) {
    return null;
  }

  final normalised = dash.trim().toLowerCase();
  final collapsed = normalised.replaceAll(RegExp(r'\s+'), ' ');
  return switch (normalised) {
    // `:773-774` — solid is the absence of a pattern, not a pattern of one dash.
    'solid' => null,
    'dot' => '1, 5',
    'dash' => '5, 5',
    'longdash' => '10, 5',
    'dashdot' => '5, 5, 1, 5',
    'longdashdot' => '10, 5, 1, 5',
    // `:789` returns the ORIGINAL string, not the normalised one, so an unknown
    // pattern reaches the painter exactly as the schema wrote it.
    _ => _numericDashList.hasMatch(collapsed) ? collapsed : dash,
  };
}

/// `PlotlySchemaAdapter.ts:795-797`.
FluentCoordinateSpace _mapRefTypeToCoordinateSpace(_RefType refType) {
  return switch (refType) {
    _RefType.axis => FluentCoordinateSpace.data,
    _RefType.relative => FluentCoordinateSpace.relative,
    _RefType.pixel => FluentCoordinateSpace.pixel,
  };
}

/// `PlotlySchemaAdapter.ts:799-807` — only a data coordinate may be a string or
/// a date; a relative or pixel one has to be a finite number.
Object? _normaliseCoordinateValueForSpace(
  FluentCoordinateSpace space,
  Object value,
) {
  if (space == FluentCoordinateSpace.data) {
    return value;
  }
  return value is num && value.isFinite ? value : null;
}

/// One axis's annotation coordinate, in the space [refType] names
/// (`PlotlySchemaAdapter.ts:809-837`).
Object? _getAnnotationCoordinateValue(
  String axis,
  _RefType refType,
  Map<String, Object?> annotation,
  Map<String, Object?>? layout,
) {
  final rawValue = annotation[axis];
  if (refType == _RefType.axis) {
    final axisLayout = _getAxisLayoutByRef(
      layout,
      annotation['${axis}ref'],
      axis,
    );
    final declaredType = axisLayout?['type'];
    // `:834` — an axis with no declared type is read as a category, so a label
    // survives as itself.
    final axisType = declaredType is String ? declaredType : 'category';
    return _convertAnnotationDataValue(rawValue, axisType);
  }

  final numericValue = _toFiniteNumber(rawValue);
  if (numericValue == null) {
    return null;
  }

  if (refType == _RefType.relative) {
    return axis == 'y'
        ? _transformRelativeYForChart(numericValue)
        : numericValue;
  }

  return numericValue;
}

/// A CSS colour string as a [Color], or null when it is not one.
///
/// `PlotlySchemaAdapter.ts:998-1004`, `:1027-1029` and `:1057` all hand a raw
/// CSS string to a `style` object. Flutter has no such stringly-typed edge, so
/// the parse happens here, through the same `d3.color` the colour adapter uses
/// — there is no second colour grammar in this package.
Color? _parseColour(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  final parsed = d3.color(value)?.rgb();
  if (parsed == null) {
    return null;
  }
  // d3 leaves its channels unclamped and 0-255 (`d3/color.dart:225-245`);
  // Color takes bytes, and an alpha of 0-1 scales by 255.
  int channel(double raw) => raw.isNaN ? 0 : raw.round().clamp(0, 255);
  return Color.fromARGB(
    channel((parsed.a.isNaN ? 1.0 : parsed.a) * 255),
    channel(parsed.r),
    channel(parsed.g),
    channel(parsed.b),
  );
}

/// A Plotly font weight as a [FontWeight] (`PlotlySchemaAdapter.ts:1034-1036`).
///
/// Plotly writes a CSS weight, which is either one of the nine hundreds or the
/// `normal`/`bold` keywords CSS defines as 400 and 700.
FontWeight? _parseFontWeight(Object? value) {
  final keyword = value is String ? value.trim().toLowerCase() : null;
  final numeric = switch (keyword) {
    'normal' => 400.0,
    'bold' => 700.0,
    _ => _toFiniteNumber(value),
  };
  if (numeric == null) {
    return null;
  }
  // FontWeight.values is w100..w900 in order, so the hundreds digit minus one
  // is the index. Anything outside the CSS range clamps to an end of it.
  final index = (numeric / 100).round() - 1;
  return FontWeight.values[index.clamp(0, FontWeight.values.length - 1)];
}

/// Converts one Plotly annotation into a [FluentChartAnnotation], or null when
/// the schema does not describe one this chart can draw.
///
/// `PlotlySchemaAdapter.ts:839-1074`. [layout] supplies the axis types the data
/// coordinates are read against; [index] numbers the id.
FluentChartAnnotation? convertPlotlyAnnotation(
  Map<String, Object?> annotation,
  int index, {
  required Map<String, Object?>? layout,
}) {
  // `:844` is a strict `=== false`, so only the boolean hides an annotation.
  if (annotation['visible'] == false) {
    return null;
  }

  final xRefType = _resolveRefType(annotation['xref'], 'x');
  final yRefType = _resolveRefType(annotation['yref'], 'y');
  if (xRefType == null || yRefType == null) {
    return null;
  }

  final xValue = _getAnnotationCoordinateValue(
    'x',
    xRefType,
    annotation,
    layout,
  );
  final yValue = _getAnnotationCoordinateValue(
    'y',
    yRefType,
    annotation,
    layout,
  );
  if (xValue == null || yValue == null) {
    return null;
  }

  final xSpace = _mapRefTypeToCoordinateSpace(xRefType);
  final ySpace = _mapRefTypeToCoordinateSpace(yRefType);
  final normalisedX = _normaliseCoordinateValueForSpace(xSpace, xValue);
  final normalisedY = _normaliseCoordinateValueForSpace(ySpace, yValue);
  if (normalisedX == null || normalisedY == null) {
    return null;
  }

  final yRef = annotation['yref'];
  // `:869-871` — `y2` is the only reference that reaches the secondary scale;
  // `yaxis2` does not, because `resolveRefType` already rejected it.
  final yAxis =
      ySpace == FluentCoordinateSpace.data &&
          yRef is String &&
          yRef.toLowerCase() == 'y2'
      ? FluentAnnotationYAxis.secondary
      : FluentAnnotationYAxis.primary;

  final FluentChartAnnotationCoordinate coordinates;
  if (xSpace == FluentCoordinateSpace.data &&
      ySpace == FluentCoordinateSpace.data) {
    coordinates = FluentDataCoordinate(
      x: normalisedX,
      y: normalisedY,
      yAxis: yAxis,
    );
  } else if (xSpace == FluentCoordinateSpace.relative &&
      ySpace == FluentCoordinateSpace.relative) {
    coordinates = FluentRelativeCoordinate(
      x: (normalisedX as num).toDouble(),
      y: (normalisedY as num).toDouble(),
    );
  } else if (xSpace == FluentCoordinateSpace.pixel &&
      ySpace == FluentCoordinateSpace.pixel) {
    coordinates = FluentPixelCoordinate(
      x: (normalisedX as num).toDouble(),
      y: (normalisedY as num).toDouble(),
    );
  } else {
    coordinates = FluentMixedCoordinate(
      xSpace: xSpace,
      ySpace: ySpace,
      x: normalisedX,
      y: normalisedY,
      yAxis: yAxis,
    );
  }

  final rawText = annotation['text'];
  // The text arrives already entity-encoded because sanitizePlotlyJson ran on
  // the whole schema. Decode it here, once, at the only place the string
  // reaches a Flutter Text widget — `:907` encodes instead, because its
  // consumer is the DOM, which decodes on the way in.
  final text = decodePlotlyHtmlEntities(rawText == null ? '' : '$rawText');

  const layoutDefaults = FluentChartAnnotationLayout();
  const styleDefaults = FluentChartAnnotationStyle();
  const connectorDefaults = FluentChartAnnotationConnector();

  var hasLayout = false;
  var hasStyle = false;

  final showArrow = _isTruthy(annotation['showarrow']);

  // `clipToBounds` is deliberately tri-state. ChartAnnotationLayer.tsx:385
  // clamps the anchor point only when the flag is truthy, while :544 selects
  // the clamping viewport with `!= false` — so null behaves like neither true
  // nor false. The contract types it as `bool?`; do not collapse it.
  bool? clipToBounds;
  if (annotation.containsKey('cliponaxis')) {
    clipToBounds = _isTruthy(annotation['cliponaxis']);
    hasLayout = true;
  } else if (coordinates is FluentDataCoordinate) {
    clipToBounds = true;
    hasLayout = true;
  }

  // `:926-936` — `xanchor` wins, and `align` is the fallback, not an override.
  final align =
      _mapHorizontalAlign(annotation['xanchor']) ??
      _mapHorizontalAlign(annotation['align']);
  final verticalAlign =
      _mapVerticalAlign(annotation['yanchor']) ??
      _mapVerticalAlign(annotation['valign']);
  hasLayout = hasLayout || align != null || verticalAlign != null;

  var hasExplicitOffset = false;
  final offsetXComponents = <double>[];
  final ax = _toFiniteNumber(annotation['ax']);
  final axRef = annotation['axref'];
  final axRefNormalised = axRef is String ? axRef.toLowerCase() : null;
  // `:954` — an `ax` measured in axis units is a data coordinate, not a pixel
  // nudge, so it is dropped rather than misread as one.
  if (ax != null && (axRefNormalised == null || axRefNormalised == 'pixel')) {
    offsetXComponents.add(ax);
    hasExplicitOffset = true;
  }
  final xShift = _toFiniteNumber(annotation['xshift']);
  if (xShift != null) {
    offsetXComponents.add(xShift);
    hasExplicitOffset = true;
  }

  final offsetYComponents = <double>[];
  final ay = _toFiniteNumber(annotation['ay']);
  final ayRef = annotation['ayref'];
  final ayRefNormalised = ayRef is String ? ayRef.toLowerCase() : null;
  if (ay != null && (ayRefNormalised == null || ayRefNormalised == 'pixel')) {
    offsetYComponents.add(ay);
    hasExplicitOffset = true;
  }
  final yShift = _toFiniteNumber(annotation['yshift']);
  if (yShift != null) {
    offsetYComponents.add(yShift);
    hasExplicitOffset = true;
  }

  // `:963-987` — a sum of exactly zero is left unset, which is why the flag
  // above is tracked separately from the totals below.
  double? sumOrNull(List<double> components) {
    if (components.isEmpty) {
      return null;
    }
    final total = components.reduce((sum, value) => sum + value);
    return total == 0 ? null : total;
  }

  final offsetX = sumOrNull(offsetXComponents);
  var offsetY = sumOrNull(offsetYComponents);
  if (showArrow && !hasExplicitOffset && offsetY == null) {
    offsetY = kDefaultArrowOffset;
  }
  hasLayout = hasLayout || offsetX != null || offsetY != null;

  final maxWidth = _toFiniteNumber(annotation['width']);
  hasLayout = hasLayout || maxWidth != null;

  final backgroundColor = _parseColour(annotation['bgcolor']);
  final borderColor = _parseColour(annotation['bordercolor']);
  final borderWidth = _toFiniteNumber(annotation['borderwidth']);
  final borderPad = _pixels(annotation['borderpad']);
  final opacity = _toFiniteNumber(annotation['opacity']);

  final font = annotation['font'];
  final fontMap = font is Map<String, Object?> ? font : null;
  final textColor = _parseColour(fontMap?['color']);
  final fontSize = _pixels(fontMap?['size']);
  final fontWeight = _parseFontWeight(fontMap?['weight']);

  // `:1039-1047` — a numeric angle is taken as is, a numeric string is parsed,
  // and the `auto` keyword means "let the layer decide", so it sets nothing.
  final textAngle = annotation['textangle'];
  final rotation = textAngle is String && textAngle.toLowerCase() == 'auto'
      ? null
      : _toFiniteNumber(textAngle);

  hasStyle =
      backgroundColor != null ||
      borderColor != null ||
      borderWidth != null ||
      borderPad != null ||
      opacity != null ||
      textColor != null ||
      fontSize != null ||
      fontWeight != null ||
      rotation != null;

  FluentChartAnnotationConnector? connector;
  if (showArrow) {
    // `:1057` — the text colour is the arrow's fallback, so a recoloured
    // annotation does not keep a default-coloured tail.
    final arrowColour = _parseColour(annotation['arrowcolor']) ?? textColor;
    final arrowWidth = _toFiniteNumber(annotation['arrowwidth']);
    final endPadding = _toFiniteNumber(annotation['standoff']);
    final startPadding = _toFiniteNumber(annotation['startstandoff']);
    final arrowDash = annotation['arrowdash'];
    connector = FluentChartAnnotationConnector(
      strokeColor: arrowColour,
      strokeWidth: arrowWidth ?? connectorDefaults.strokeWidth,
      // `:1066-1067` — a negative standoff would pull the line past its own
      // anchor, so it clamps at 0.
      endPadding: endPadding == null
          ? connectorDefaults.endPadding
          : math.max(endPadding, 0),
      startPadding: startPadding == null
          ? connectorDefaults.startPadding
          : math.max(startPadding, 0),
      dashArray: mapArrowDashToPattern(arrowDash is String ? arrowDash : null),
      arrow: mapArrowsideToArrow(annotation),
    );
  }

  return FluentChartAnnotation(
    text: text,
    coordinates: coordinates,
    id: createAnnotationId(text, index),
    // `:1048-1054` — an untouched layout or style block is left off entirely,
    // so the annotation layer's own defaults apply rather than a copy of them.
    layout: hasLayout
        ? FluentChartAnnotationLayout(
            align: align ?? layoutDefaults.align,
            verticalAlign: verticalAlign ?? layoutDefaults.verticalAlign,
            offsetX: offsetX ?? layoutDefaults.offsetX,
            offsetY: offsetY ?? layoutDefaults.offsetY,
            maxWidth: maxWidth,
            clipToBounds: clipToBounds,
          )
        : null,
    style: hasStyle
        ? FluentChartAnnotationStyle(
            textColor: textColor,
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            borderWidth: borderWidth,
            borderRadius: styleDefaults.borderRadius,
            fontSize: fontSize,
            fontWeight: fontWeight,
            padding: borderPad == null ? null : EdgeInsets.all(borderPad),
            opacity: opacity ?? styleDefaults.opacity,
            rotation: rotation,
          )
        : null,
    connector: connector,
  );
}

/// Every annotation a Plotly [layout] declares, converted.
///
/// `PlotlySchemaAdapter.ts:1076-1161`. Empty for a multi-plot figure, because
/// one layout's annotations cannot be attributed to one of several plots
/// (`:1081`).
///
/// Upstream additionally infers a missing axis `type` from the traces
/// (`:1085-1153`) so that a bar chart's date-like category labels are not
/// re-parsed as dates. That pass needs the trace list, which this signature does
/// not take; a layout that declares its axis types — every one this adapter
/// builds an axis from — is unaffected.
List<FluentChartAnnotation> getChartAnnotationsFromLayout(
  Map<String, Object?>? layout, {
  required bool isMultiPlot,
}) {
  final raw = layout?['annotations'];
  if (isMultiPlot || raw == null) {
    return const <FluentChartAnnotation>[];
  }

  // `:1155` — a lone annotation object is as valid as a list of them.
  final entries = raw is List<Object?> ? raw : <Object?>[raw];
  final converted = <FluentChartAnnotation>[];
  for (var index = 0; index < entries.length; index++) {
    final entry = entries[index];
    if (entry is! Map<String, Object?>) {
      continue;
    }
    // `:1156-1158` numbers with the source index and filters afterwards, so a
    // dropped annotation does not renumber the ones that survive it.
    final annotation = convertPlotlyAnnotation(entry, index, layout: layout);
    if (annotation != null) {
      converted.add(annotation);
    }
  }
  return converted;
}
