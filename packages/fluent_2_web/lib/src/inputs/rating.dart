import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'rating_style.dart';

/// Whether the rating takes input or only reports a value. Figma's `Type` axis.
enum FluentRatingType {
  /// Takes input: hover previews, click and arrow keys commit. The default.
  interactive,

  /// Inert. Reports a value and nothing else.
  display,
}

/// Shape box edge length. Figma's `Size` axis.
enum FluentRatingSize {
  /// 12.
  small,

  /// 16.
  medium,

  /// 20.
  large,

  /// 28. The default, matching upstream's `Rating`.
  extraLarge,
}

/// Which silhouette is drawn. Figma's `Shape` axis.
enum FluentRatingShape {
  /// A five-pointed star. The default.
  star,

  /// A circle.
  circle,

  /// A rounded square.
  square,
}

/// Which colour family the shapes take. Figma's `Rating color` collection.
enum FluentRatingColor {
  /// Neutral foreground. The default.
  neutral,

  /// The brand ramp.
  brand,

  /// The marigold palette family — the conventional "gold star".
  marigold,
}

/// Everything needed to render a rating, independent of type, size, shape and
/// colour.
///
/// The counterpart of upstream's `RatingBaseState`. [buildFluentRating] takes
/// this rather than [FluentRatingState], which is what makes "Fluent's state,
/// my own styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentRatingBaseState {
  /// Creates a base state.
  ///
  /// [value] is expected to be already rounded to the nearest half — that is
  /// what [resolveFluentRatingState] does.
  const FluentRatingBaseState({
    required this.value,
    required this.max,
    required this.compact,
    required this.enabled,
    this.step = 1,
  });

  /// The rating being shown, rounded to the nearest half.
  final double value;

  /// How many shapes a full rating is worth.
  final int max;

  /// The granularity the control commits at: 1, or 0.5 for half values.
  final double step;

  /// Whether a single filled shape stands in for the whole row.
  final bool compact;

  /// Whether the rating responds to input.
  final bool enabled;

  /// How many shapes are actually drawn.
  ///
  /// Compact draws one, whatever [max] says — upstream's `RatingDisplay`
  /// renders a single `RatingItem` and puts the number beside it.
  int get itemCount => compact ? 1 : max;

  /// How much of the shape at [index] is filled: 0, 0.5 or 1.
  ///
  /// Transcribed from `useRatingItemBase_unstable`: compact is always full,
  /// otherwise the shape is full at or above its own ordinal, half within half
  /// a point of it, and empty below.
  double fillOf(int index) {
    if (compact) return 1;
    final ordinal = index + 1;
    if (value >= ordinal) return 1;
    if (value >= ordinal - 0.5) return 0.5;
    return 0;
  }
}

/// A rating's fully resolved state, including the design axes.
///
/// The counterpart of upstream's `RatingState`: base state plus exactly `type`,
/// `size`, `shape` and `color`.
@immutable
class FluentRatingState extends FluentRatingBaseState {
  /// Creates a resolved state.
  const FluentRatingState({
    required super.value,
    required super.max,
    required super.compact,
    required super.enabled,
    required this.type,
    required this.size,
    required this.shape,
    required this.color,
    super.step,
  });

  /// Whether the rating takes input.
  final FluentRatingType type;

  /// Shape box edge length.
  final FluentRatingSize size;

  /// Which silhouette is drawn.
  final FluentRatingShape shape;

  /// Which colour family the shapes take.
  final FluentRatingColor color;
}

/// Builds the state a rating will be styled and rendered from.
///
/// The first of the three-function recomposition contract. The one decision it
/// makes is the rounding: upstream computes `Math.round(value * 2) / 2` before
/// anything else looks at the number, so a 2.7 rating draws as 2.5 rather than
/// as two-and-seven-tenths of a shape.
FluentRatingState resolveFluentRatingState({
  required double value,
  int max = 5,
  double step = 1,
  bool compact = false,
  bool enabled = true,
  FluentRatingType type = FluentRatingType.interactive,
  FluentRatingSize size = FluentRatingSize.extraLarge,
  FluentRatingShape shape = FluentRatingShape.star,
  FluentRatingColor color = FluentRatingColor.neutral,
}) => FluentRatingState(
  value: (value * 2).roundToDouble() / 2,
  max: max,
  step: step,
  compact: compact,
  enabled: enabled,
  type: type,
  size: size,
  shape: shape,
  color: color,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// The unselected treatment is the part worth reading. Upstream picks the
/// appearance from interactivity, not from a prop:
/// `appearance = interactive ? 'outline' : 'filled'`.
///
/// * **Interactive** draws the unselected shapes as *outlines* in the item's
///   own colour, with no fill whatsoever.
/// * **Display** draws them as solid shapes in a muted token — Figma's
///   `Background Display`: `neutralStroke2`, `brandStroke2` or the marigold
///   `Palette/Marigold/Background/2/Rest` — outlined in `transparentStroke`.
///   That outline is invisible in light and dark and becomes the canvas text
///   colour in high contrast, which is upstream's `@media (forced-colors)`
///   rule (`color: Canvas; stroke: CanvasText`) arriving for free through the
///   token layer.
FluentRatingStyle resolveFluentRatingStyle(
  FluentRatingState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final interactive = state.type == FluentRatingType.interactive;

  final accent = switch (state.color) {
    FluentRatingColor.neutral => c.neutralForeground1,
    FluentRatingColor.brand => c.brandForeground1,
    FluentRatingColor.marigold => c.palette.strokeActiveRest(
      FluentPaletteFamily.marigold,
    ),
  };

  // Upstream has no hover or pressed colour at all — hovering previews the
  // VALUE, it does not restyle the shape — so only the disabled token differs
  // from rest. Disabled is neutral for every colour, as it is on every other
  // Fluent control.
  final selected = FluentStateColor.tokens(
    rest: accent,
    disabled: c.neutralForegroundDisabled,
  );

  // Figma's `Rating color` collection, variable `Background Display`. Note it
  // is a STROKE token for neutral and brand and a BACKGROUND token only for
  // marigold — upstream React reaches for colorNeutralBackground6 and
  // colorBrandBackground2 instead, and Figma wins. See
  // doc/token-divergences.md.
  //
  // Except under forced colors, which the design file does not model at all:
  // there every stroke token collapses onto CanvasText, so an unselected shape
  // would come out the same colour as a selected one and the rating would say
  // nothing. Upstream's `@media (forced-colors)` block is the authority for
  // that one case — `color: Canvas` — and neutralBackground6 is the token that
  // resolves to it. Same identity test as `resolveFluentAcrylicStyle`.
  final forcedColors = c is FluentHighContrastColors;
  final unselectedFill = switch (state.color) {
    FluentRatingColor.neutral ||
    FluentRatingColor.brand when forcedColors => c.neutralBackground6,
    FluentRatingColor.neutral => c.neutralStroke2,
    FluentRatingColor.brand => c.brandStroke2,
    FluentRatingColor.marigold => c.palette.background2Rest(
      FluentPaletteFamily.marigold,
    ),
  };

  return FluentRatingStyle(
    itemSize: WidgetStatePropertyAll<double?>(switch (state.size) {
      FluentRatingSize.small => FluentSize.size120,
      FluentRatingSize.medium => FluentSize.size160,
      FluentRatingSize.large => FluentSize.size200,
      FluentRatingSize.extraLarge => FluentSize.size280,
    }),
    shape: WidgetStatePropertyAll<FluentRatingShape?>(state.shape),
    // Figma's shape row is an auto-layout frame with itemSpacing bound to
    // `Spacing/Horizontal/XXS`, at every size: five 28 boxes plus four 2 gaps
    // measure the 148 the XLarge row reports. Upstream's React root is a bare
    // `display: flex` with no gap at all — Figma wins.
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
    selectedColor: selected,
    // Null, not a transparent token: an outlined shape has no fill to turn
    // opaque in high contrast.
    unselectedColor: interactive
        ? null
        : FluentStateColor.tokens(rest: unselectedFill),
    unselectedStrokeColor: interactive
        ? selected
        : FluentStateColor.tokens(rest: c.transparentStroke),
    strokeWidth: WidgetStatePropertyAll<double?>(
      // The outline glyph's own stroke measures ~1.25 at the 20px size; the
      // transparent keyline on the filled glyph is a hairline. Both are token
      // selections rather than measurements carried across.
      interactive ? FluentStroke.width15 : FluentStroke.thin,
    ),
    mouseCursor: WidgetStatePropertyAll<MouseCursor?>(
      interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
    ),
  );
}

/// Renders a rating from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentRatingBaseState] rather than [FluentRatingState] on purpose: it never
/// reads type, size, shape or colour — those have already become numbers and
/// tokens on the style — so a consumer can supply their own style and still use
/// Fluent's rendering and focus ring.
///
/// The whole row is one [CustomPaint]. Three shapes, half fills and a clip per
/// shape are cheaper and more exact as paths than as a row of composed widgets,
/// and it keeps the half-value boundary on a pixel Fluent chose rather than
/// wherever a nested clip happened to land.
///
/// There is **no transition** here: upstream's Rating, RatingItem and
/// RatingDisplay styles declare none, so a value change lands on the frame.
///
/// [states] is the live interaction set from [FluentInteractive].
Widget buildFluentRating(
  FluentRatingBaseState state,
  FluentRatingStyle style,
  Set<WidgetState> states,
) {
  final itemSize = style.itemSize?.resolve(states) ?? FluentSize.size280;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xxs;
  final shape = style.shape?.resolve(states) ?? FluentRatingShape.star;
  final count = state.itemCount;

  // The ring belongs to the *item*, not to the row: `useRatingItemStyles`'
  // root carries `createFocusOutlineStyle({ selector: 'focus-within' })` while
  // `useRatingStyles`' root is a bare `display: flex; flex-wrap: wrap` with no
  // indicator at all. The live control confirms it — only the focused
  // `.fui-RatingItem` grows an `::after`, and the other four have none. So this
  // is one item square, not a 152x32 box around all five.
  //
  // With a single focus node for the whole control, the item the ring lands on
  // is the one the value sits on.
  final focused = count <= 1 ? 0 : (state.value.ceil() - 1).clamp(0, count - 1);

  return Stack(
    // The ring paints 2px outside its item, which at either end of the row is
    // outside the Stack too.
    clipBehavior: Clip.none,
    children: <Widget>[
      SizedBox(
        width: count * itemSize + (count - 1) * gap,
        height: itemSize,
        child: CustomPaint(
          painter: FluentRatingPainter(
            shape: shape,
            itemSize: itemSize,
            gap: gap,
            fills: <double>[for (var i = 0; i < count; i++) state.fillOf(i)],
            selected: style.selectedColor?.resolve(states),
            unselected: style.unselectedColor?.resolve(states),
            unselectedStroke: style.unselectedStrokeColor?.resolve(states),
            strokeWidth:
                style.strokeWidth?.resolve(states) ?? FluentStroke.none,
          ),
        ),
      ),
      Positioned(
        left: focused * (itemSize + gap),
        top: 0,
        width: itemSize,
        height: itemSize,
        // `createFocusOutlineStyle`'s `::after` carries a flat
        // `border-radius: 4px` at inset -2, and the concentric painter adds its
        // own 2px width back, so 2 going in is the 4 the browser reports.
        child: FluentFocusRing(
          visible: states.contains(WidgetState.focused),
          borderRadius: FluentRadius.allSmall,
          child: const SizedBox.expand(),
        ),
      ),
    ],
  );
}

/// Paints a row of rating shapes, each filled by its own fraction.
///
/// Every input is a public field so tests can assert the resolved tokens and
/// fill fractions directly instead of diffing pixels.
///
/// ## Where the three silhouettes come from
///
/// Their proportions are traced from the Fluent System Icons the React
/// component uses; their **ink width is measured per ramp size** off the Figma
/// vectors recorded in `test/fixtures/rating.json`. That distinction matters:
/// Fluent's icons are drawn optically at each size, so 28 is not 20 scaled up —
/// a circle fills 10 of a 12 box but 24 of a 28 one, and the rounded square's
/// corner goes 2, 2.5, 3, 3.75 rather than staying a fixed fraction.
///
/// * **Star** — `ic_fluent_star_*_filled`. Its inner vertices are exact in the
///   20px path (`10.0011 15.5119` is the bottom one), fixing the centre 0.7
///   below the box centre and the inner radius at 4.8115/8.38 of the outer one.
///   The outer radius is then solved from the measured ink width, because the
///   icon's tips are heavily rounded and this painter's are not — matching the
///   ink beats matching the construction. Figma's star is 0.5–2% taller than
///   the polygon at the same width; that residue is the rounding.
/// * **Circle** — `ic_fluent_circle_*_filled`, centred.
/// * **Square** — `ic_fluent_square_*_filled`, centred.
class FluentRatingPainter extends CustomPainter {
  /// Creates a painter for the given shapes, fills and tones.
  const FluentRatingPainter({
    required this.shape,
    required this.itemSize,
    required this.gap,
    required this.fills,
    required this.selected,
    required this.unselected,
    required this.unselectedStroke,
    required this.strokeWidth,
  });

  /// Which silhouette every shape in the row takes.
  final FluentRatingShape shape;

  /// Edge length of one shape's box.
  final double itemSize;

  /// Space between two boxes.
  final double gap;

  /// One fraction per shape: 0, 0.5 or 1.
  final List<double> fills;

  /// Fill of the selected portion.
  final Color? selected;

  /// Fill of the unselected portion, or null when it is drawn as an outline
  /// with no fill at all.
  final Color? unselected;

  /// Outline of the unselected portion.
  final Color? unselectedStroke;

  /// Outline width. Zero suppresses the outline entirely.
  final double strokeWidth;

  // See the class doc for provenance.

  /// The star's vertical centre as a fraction of the box edge. Constant across
  /// the ramp; only the ink width is adjusted per size.
  static const double _starCentreY = 10.7033 / 20;

  /// Inner radius as a fraction of the outer one.
  static const double _starInnerRatio = 4.8115 / 8.38;

  /// A five-pointed star's ink spans `2 * outerRadius * cos(18°)`, its widest
  /// pair of vertices sitting 18 degrees off the horizontal.
  static const double _starWidthPerRadius = 2 * 0.9510565162951535;

  /// Ink width of each silhouette at the four ramp sizes, from the Figma
  /// vectors, as `(box edge, ink)` pairs. Read through [_ramp], which scales
  /// the nearest step for a size Fluent does not define. Pairs rather than a
  /// map because a `double` key has no primitive equality and so cannot be
  /// const.
  static const List<(double, double)> _starInk = <(double, double)>[
    (12, 10.0017),
    (16, 13.0019),
    (20, 16.0021),
    (28, 22.5031),
  ];
  static const List<(double, double)> _circleInk = <(double, double)>[
    (12, 10),
    (16, 12),
    (20, 16),
    (28, 24),
  ];
  static const List<(double, double)> _squareInk = <(double, double)>[
    (12, 8),
    (16, 12),
    (20, 14),
    (28, 22),
  ];

  /// The rounded square's corner radius at the same four sizes.
  static const List<(double, double)> _squareCorner = <(double, double)>[
    (12, 2),
    (16, 2.5),
    (20, 3),
    (28, 3.75),
  ];

  /// [ramp] read at [edge], scaling the nearest ramp step proportionally when
  /// [edge] is not one of Fluent's four.
  static double _ramp(List<(double, double)> ramp, double edge) {
    var nearest = ramp.first;
    for (final step in ramp) {
      if ((step.$1 - edge).abs() < (nearest.$1 - edge).abs()) nearest = step;
    }
    return nearest.$2 / nearest.$1 * edge;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < fills.length; i++) {
      final box = Rect.fromLTWH(i * (itemSize + gap), 0, itemSize, itemSize);
      final path = pathFor(shape, box);

      final fill = unselected;
      if (fill != null) {
        canvas.drawPath(path, Paint()..color = fill);
      }
      final stroke = unselectedStroke;
      if (stroke != null && strokeWidth > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..color = stroke,
        );
      }

      final fraction = fills[i];
      final tint = selected;
      if (fraction <= 0 || tint == null) continue;
      // Clipping the whole shape rather than building a half path is what
      // upstream does too: the selected icon is a complete glyph in a box with
      // `overflow: hidden` and `right: 50%`.
      canvas
        ..save()
        ..clipRect(
          Rect.fromLTWH(box.left, box.top, box.width * fraction, box.height),
        )
        ..drawPath(path, Paint()..color = tint)
        ..restore();
    }
  }

  /// The outline of [shape] inscribed in [box].
  ///
  /// Public so a consumer drawing their own rating — or a test asserting the
  /// silhouette — does not have to re-derive the geometry.
  static Path pathFor(FluentRatingShape shape, Rect box) {
    final edge = box.shortestSide;
    switch (shape) {
      case FluentRatingShape.star:
        final outer = _ramp(_starInk, edge) / _starWidthPerRadius;
        final centre = Offset(box.center.dx, box.top + edge * _starCentreY);
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final radius = i.isEven ? outer : outer * _starInnerRatio;
          // Vertex 0 is the top point; every subsequent vertex alternates
          // outer/inner every 36 degrees.
          final angle = -math.pi / 2 + i * math.pi / 5;
          final point =
              centre + Offset(math.cos(angle), math.sin(angle)) * radius;
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        return path..close();
      case FluentRatingShape.circle:
        return Path()..addOval(
          Rect.fromCircle(
            center: box.center,
            radius: _ramp(_circleInk, edge) / 2,
          ),
        );
      case FluentRatingShape.square:
        final side = _ramp(_squareInk, edge);
        return Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: box.center, width: side, height: side),
            Radius.circular(_ramp(_squareCorner, edge)),
          ),
        );
    }
  }

  @override
  bool shouldRepaint(FluentRatingPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.itemSize != itemSize ||
      oldDelegate.gap != gap ||
      !listEquals(oldDelegate.fills, fills) ||
      oldDelegate.selected != selected ||
      oldDelegate.unselected != unselected ||
      oldDelegate.unselectedStroke != unselectedStroke ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Overrides the rating style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentRatingTheme extends InheritedTheme {
  /// Applies [style] to every `FluentRating` in [child].
  const FluentRatingTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the type, size, shape and colour defaults.
  final FluentRatingStyle style;

  /// The nearest rating style, or null.
  static FluentRatingStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentRatingTheme>()?.style;

  @override
  bool updateShouldNotify(FluentRatingTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentRatingTheme(style: style, child: child);
}

/// A Fluent 2 rating.
///
/// ```dart
/// FluentRating(
///   value: rating,
///   step: 0.5,
///   color: FluentRatingColor.marigold,
///   onChanged: (value) => setState(() => rating = value),
/// )
/// ```
///
/// Interactive by default: hovering previews the value under the pointer,
/// clicking commits it, and the arrow keys move by one [step] once the control
/// has keyboard focus. Pass `type: FluentRatingType.display` for the inert
/// rendering, which reports a value and takes no input at all.
///
/// `onChanged: null` disables it — a real state, not a visual treatment: the
/// rating stops previewing on hover, refuses focus, ignores the arrow keys and
/// resolves the disabled token.
///
/// ## Fidelity note
///
/// Verified against the Figma `Rating` set (36 variants) via
/// `test/fixtures/rating.json`. Three things Figma states differently from
/// `microsoft/fluentui@master`, and Figma won each: the shapes sit 2 apart
/// rather than flush, and a display rating's unselected shapes take
/// `neutralStroke2` / `brandStroke2` rather than `neutralBackground6` /
/// `brandBackground2`. The behaviour — half-value rounding, hover preview,
/// arrow keys, the absence of any transition — still comes from `useRating.tsx`
/// and has no counterpart in the design file. See `doc/token-divergences.md`.
class FluentRating extends StatefulWidget {
  /// Creates a rating showing [value].
  const FluentRating({
    super.key,
    required this.value,
    this.onChanged,
    this.max = 5,
    this.step = 1,
    this.compact = false,
    this.type = FluentRatingType.interactive,
    this.size = FluentRatingSize.extraLarge,
    this.shape = FluentRatingShape.star,
    this.color = FluentRatingColor.neutral,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : assert(max > 1, 'A rating needs at least two shapes.'),
       assert(step == 1 || step == 0.5, 'Fluent allows only 1 or 0.5.');

  /// The rating being shown. Rounded to the nearest half before it is drawn.
  final double value;

  /// Invoked with the new value on click and on the arrow keys. Null disables
  /// the rating.
  final ValueChanged<double>? onChanged;

  /// How many shapes a full rating is worth.
  final int max;

  /// The granularity the control commits at: 1, or 0.5 for half values.
  final double step;

  /// Whether a single filled shape stands in for the whole row.
  final bool compact;

  /// Whether the rating takes input.
  final FluentRatingType type;

  /// Shape box edge length.
  final FluentRatingSize size;

  /// Which silhouette is drawn.
  final FluentRatingShape shape;

  /// Which colour family the shapes take.
  final FluentRatingColor color;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentRatingStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Announced by assistive technology alongside the value.
  final String? semanticLabel;

  @override
  State<FluentRating> createState() => _FluentRatingState();
}

class _FluentRatingState extends State<FluentRating> {
  /// The value under the pointer, previewed instead of the real one.
  double? _hovered;

  /// The value the pointer went down on, committed when the tap completes.
  double? _pending;

  /// The resolved geometry of the last build, so the pointer handlers can map
  /// an offset onto a shape. Style resolution happens in `build`, and this is
  /// the only place its numbers are needed outside it.
  double _itemSize = FluentSize.size280;
  double _gap = FluentSpacing.xxs;

  bool get _enabled =>
      widget.type == FluentRatingType.interactive && widget.onChanged != null;

  int get _itemCount => widget.compact ? 1 : widget.max;

  /// The rating the pointer at [local] is pointing at.
  double _valueAt(Offset local) {
    final extent = _itemSize + _gap;
    final index = (local.dx / extent).floor().clamp(0, _itemCount - 1);
    final within = (local.dx - index * extent) / _itemSize;
    return widget.step == 0.5 && within < 0.5 ? index + 0.5 : index + 1;
  }

  void _commit(double value) {
    if (!_enabled || value == widget.value) return;
    widget.onChanged!(value);
  }

  void _commitPending() {
    final pending = _pending;
    _pending = null;
    if (pending != null) _commit(pending);
  }

  void _adjust(double delta) {
    if (!_enabled) return;
    final stepped =
        ((widget.value + delta) / widget.step).roundToDouble() * widget.step;
    _commit(stepped.clamp(0, widget.max.toDouble()));
  }

  void _setHovered(double? value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  String _announce(double value) =>
      '${_format(value)} of ${_format(widget.max.toDouble())}';

  static String _format(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentRatingState(
      // Hovering previews the value; it never changes the colours.
      value: _hovered ?? widget.value,
      max: widget.max,
      step: widget.step,
      compact: widget.compact,
      enabled: _enabled,
      type: widget.type,
      size: widget.size,
      shape: widget.shape,
      color: widget.color,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentRatingStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentRatingTheme.maybeOf(context)).merge(widget.style);

    const forStates = <WidgetState>{};
    _itemSize = resolved.itemSize?.resolve(forStates) ?? FluentSize.size280;
    _gap = resolved.gap?.resolve(forStates) ?? FluentSpacing.xxs;

    if (!_enabled) {
      final painted = buildFluentRating(
        state,
        resolved,
        widget.type == FluentRatingType.display
            ? const <WidgetState>{}
            : const <WidgetState>{WidgetState.disabled},
      );
      // A display rating is not a disabled control, so it carries no enabled
      // state at all — upstream gives it `role="img"`.
      return widget.type == FluentRatingType.display
          ? Semantics(
              label: widget.semanticLabel ?? _announce(state.value),
              image: true,
              container: true,
              child: painted,
            )
          : Semantics(
              slider: true,
              enabled: false,
              label: widget.semanticLabel,
              value: _announce(state.value),
              container: true,
              child: painted,
            );
    }

    final interactive = FluentInteractive(
      enabled: true,
      onPressed: _commitPending,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor:
          resolved.mouseCursor?.resolve(forStates) ?? SystemMouseCursors.click,
      builder: (context, states, _) => MouseRegion(
        onHover: (event) => _setHovered(_valueAt(event.localPosition)),
        onExit: (_) => _setHovered(null),
        // A Listener rather than another GestureDetector: this only needs the
        // position the press landed on, and it must not compete in the gesture
        // arena with the tap FluentInteractive already recognises.
        child: Listener(
          onPointerDown: (event) => _pending = _valueAt(event.localPosition),
          child: buildFluentRating(state, resolved, states),
        ),
      ),
    );

    // Arrow keys would otherwise reach the framework's own
    // DirectionalFocusIntent and move focus off the control. Binding them
    // closer to the focused node than WidgetsApp's defaults takes them back.
    return Semantics(
      slider: true,
      enabled: true,
      label: widget.semanticLabel,
      value: _announce(state.value),
      increasedValue: _announce(
        (widget.value + widget.step).clamp(0, widget.max.toDouble()),
      ),
      decreasedValue: _announce(
        (widget.value - widget.step).clamp(0, widget.max.toDouble()),
      ),
      onIncrease: () => _adjust(widget.step),
      onDecrease: () => _adjust(-widget.step),
      container: true,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowRight): _AdjustIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowUp): _AdjustIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _AdjustIntent(-1),
          SingleActivator(LogicalKeyboardKey.arrowDown): _AdjustIntent(-1),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _AdjustIntent: CallbackAction<_AdjustIntent>(
              onInvoke: (intent) {
                _adjust(intent.direction * widget.step);
                return null;
              },
            ),
          },
          child: interactive,
        ),
      ),
    );
  }
}

/// Move the rating by one step in [direction].
class _AdjustIntent extends Intent {
  const _AdjustIntent(this.direction);

  /// 1 to increase, -1 to decrease. Multiplied by the widget's own step, so a
  /// half-step rating moves by a half.
  final double direction;
}
