import 'package:fluent_2_core/fluent_2_core.dart';
// For clampDouble, which widgets.dart does not re-export.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'color_picker_style.dart';

/// Corner treatment shared by every part of a colour picker. Upstream's
/// `shape` prop, which the picker pushes onto its children through
/// [FluentColorPickerScope].
enum FluentColorPickerShape {
  /// `borderRadiusMedium` on the colour area and every rail. The default.
  rounded,

  /// Square corners.
  square,
}

/// The colour a colour control shows when nothing else supplies one: white.
///
/// Upstream's `INITIAL_COLOR_HSV`, which is `tinycolor('#FFF').toHsv()`.
const HSVColor kFluentColorPickerInitialColor = HSVColor.fromAHSV(1, 0, 0, 1);

/// Builds a colour from raw channel numbers.
///
/// **The single construction boundary for this whole family.** Two things have
/// to happen at exactly one place, and this is it:
///
/// * **Clamping.** [HSVColor.fromAHSV] asserts `0 <= hue <= 360` and
///   `0 <= saturation, value, alpha <= 1`, so a hue slider sitting on 360 that
///   takes one more arrow press would throw in debug and be silently wrong in
///   release. Hue is *clamped*, never wrapped with `% 360`: wrapping would put
///   the maximum of the rail permanently out of reach.
/// * **Quantising.** [HSVColor] compares by exact float equality, so without a
///   shared step a drag either emits a stream of no-op changes or swallows real
///   ones. Hue lands on whole degrees and the other three on whole percent —
///   which is what a native `<input type="range">` reports and what upstream's
///   own `roundTwoDecimal` produces for the colour area.
///
/// Nothing in this family calls [HSVColor.fromAHSV] directly, and nothing calls
/// [HSVColor.fromColor]: a hue cannot survive a trip through RGB. Grey has no
/// hue to recover, so `fromColor` reports 0 for it, and upstream — which does
/// exactly that — turns its saturation and value rails red the moment you pick
/// white or black.
HSVColor fluentColorFrom({
  required double hue,
  required double saturation,
  required double value,
  required double alpha,
}) => HSVColor.fromAHSV(
  _percent(alpha),
  clampDouble(hue, 0, 360).roundToDouble(),
  _percent(saturation),
  _percent(value),
);

double _percent(double fraction) =>
    clampDouble(fraction * 100, 0, 100).roundToDouble() / 100;

/// Paints the disc that marks the selected colour on a colour area or a rail.
///
/// One function rather than a class because the thumb has no size of its own to
/// lay out — only a centre — and both painters already expose its inputs as
/// their own public fields, which is what the tests read.
///
/// Upstream builds it out of three concentric rings, and so does this
/// ([size] 22 at rest, 24 while focused, with `border` 1 and `inner` 2):
///
/// | radius | what |
/// | :-- | :-- |
/// | `size / 2 - border` … `size / 2` | [borderColor] — grey, or the focus stroke |
/// | … minus [innerWidth] | [innerColor] — the surface-coloured ring |
/// | everything inside | [fill] — the colour itself |
///
/// The rings are opaque, so [fill] is drawn as a full disc underneath them
/// rather than clipped to the middle: the visible result is identical and it is
/// one `drawCircle` instead of a saved layer.
void paintFluentColorThumb(
  Canvas canvas, {
  required Offset centre,
  required double size,
  required Color fill,
  Color? borderColor,
  double borderWidth = FluentStroke.none,
  Color? innerColor,
  double innerWidth = FluentStroke.none,
  List<BoxShadow> shadow = const <BoxShadow>[],
}) {
  final radius = size / 2;
  if (radius <= 0) return;

  for (final boxShadow in shadow) {
    canvas.drawCircle(
      centre + boxShadow.offset,
      radius + boxShadow.spreadRadius,
      // toPaint() drops the blur under `debugDisableShadows`, which is what
      // keeps the goldens reproducible.
      boxShadow.toPaint(),
    );
  }

  canvas.drawCircle(
    centre,
    (radius - borderWidth).clamp(0.0, radius),
    Paint()..color = fill,
  );

  if (innerWidth > 0 && innerColor != null) {
    canvas.drawCircle(
      centre,
      (radius - borderWidth - innerWidth / 2).clamp(0.0, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerWidth
        ..color = innerColor,
    );
  }

  if (borderWidth > 0 && borderColor != null) {
    canvas.drawCircle(
      centre,
      (radius - borderWidth / 2).clamp(0.0, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = borderColor,
    );
  }
}

/// Everything needed to lay a picker out, independent of the design axis.
///
/// [buildFluentColorPicker] takes this rather than [FluentColorPickerState],
/// which is what makes "Fluent's state, my own styling, Fluent's rendering" a
/// supported path rather than a fork.
@immutable
class FluentColorPickerBaseState {
  /// Creates a base state.
  const FluentColorPickerBaseState({required this.children});

  /// The colour controls, stacked in order.
  final List<Widget> children;
}

/// A picker's fully resolved state, including the design axis.
@immutable
class FluentColorPickerState extends FluentColorPickerBaseState {
  /// Creates a resolved state.
  const FluentColorPickerState({required super.children, required this.shape});

  /// The corner treatment pushed onto every control inside.
  final FluentColorPickerShape shape;
}

/// Builds the state a picker will be styled and laid out from.
///
/// The first of the three-function recomposition contract.
FluentColorPickerState resolveFluentColorPickerState({
  required List<Widget> children,
  FluentColorPickerShape shape = FluentColorPickerShape.rounded,
}) => FluentColorPickerState(children: children, shape: shape);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract.
///
/// There is exactly one value, because upstream's whole
/// `useColorPickerStyles.styles.ts` is `display: flex`, `flex-direction:
/// column` and `gap: spacingVerticalXS`. A colour picker has no surface of its
/// own — everything you can see belongs to a child.
FluentColorPickerStyle resolveFluentColorPickerStyle(
  FluentColorPickerState state,
  FluentThemeData theme,
) => const FluentColorPickerStyle(
  spacing: WidgetStatePropertyAll<double?>(FluentSpacing.xs),
);

/// Lays a picker out from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentColorPickerBaseState] rather than [FluentColorPickerState] on
/// purpose: it never reads the shape axis — that reaches the children through
/// [FluentColorPickerScope], not through the layout — so a consumer can supply
/// their own style and still use Fluent's arrangement.
///
/// Upstream's root is a flex column with `align-items: stretch`, so the rails
/// come out as wide as the colour area above them. `CrossAxisAlignment.stretch`
/// alone would not do it: a stretched child in Flutter is handed the *incoming*
/// maximum width, so a picker in a 984-wide article column would render a
/// 984-wide colour area, and one inside a `FluentPopover` — whose content is
/// laid out unbounded — would assert.
///
/// [IntrinsicWidth] is what closes the gap. The column becomes exactly as wide
/// as its widest child wants to be (the colour area's 300), and stretch then
/// takes the rails out to match. Three children make the extra layout pass
/// free, and it means a picker lays out correctly with no width from the
/// caller at all — tight, loose or unbounded.
Widget buildFluentColorPicker(
  FluentColorPickerBaseState state,
  FluentColorPickerStyle style,
  Set<WidgetState> states,
) => IntrinsicWidth(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: style.spacing?.resolve(states) ?? FluentSpacing.xs,
    children: state.children,
  ),
);

/// Carries the picker's colour, shape and change callback down to the controls
/// inside it.
///
/// The Flutter answer to upstream's React context. A plain [InheritedWidget]
/// and not an [InheritedTheme]: it holds a *value*, not a style, and a picker
/// and its children always share a subtree — capturing a stale colour into an
/// overlay would be a bug, not a feature.
///
/// Not an [InheritedModel] either. The dependency graph is dense — the alpha
/// rail depends on hue, saturation *and* value; the saturation and value rails
/// on hue; every control on the colour — so per-aspect notification would save
/// almost nothing and buy a whole class of bug where a forgotten aspect makes a
/// control quietly stop updating.
///
/// A rebuild costs three `build` calls, three style resolutions and three
/// `shouldRepaint` checks. The element types are stable, so nothing is
/// remounted and nothing re-lays-out.
class FluentColorPickerScope extends InheritedWidget {
  /// Publishes [color], [shape] and [onColorChanged] to [child].
  const FluentColorPickerScope({
    super.key,
    required this.color,
    required this.shape,
    required this.onColorChanged,
    required super.child,
  });

  /// The colour every control inside shows, unless it was given its own.
  final HSVColor color;

  /// The corner treatment every control inside takes, unless it was given its
  /// own.
  final FluentColorPickerShape shape;

  /// Called by a control inside with the colour it landed on. Null disables
  /// every control that has no callback of its own.
  final ValueChanged<HSVColor>? onColorChanged;

  /// The nearest picker scope, or null when a control stands alone.
  static FluentColorPickerScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentColorPickerScope>();

  @override
  bool updateShouldNotify(FluentColorPickerScope oldWidget) =>
      oldWidget.color != color ||
      oldWidget.shape != shape ||
      oldWidget.onColorChanged != onColorChanged;
}

/// Overrides the picker style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`. This carries the picker's *own* style only — the
/// controls inside have `FluentColorAreaTheme` and `FluentColorSliderTheme`.
class FluentColorPickerTheme extends InheritedTheme {
  /// Applies [style] to every [FluentColorPicker] in [child].
  const FluentColorPickerTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the theme defaults.
  final FluentColorPickerStyle style;

  /// The nearest picker style, or null.
  static FluentColorPickerStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentColorPickerTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentColorPickerTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentColorPickerTheme(style: style, child: child);
}

/// A Fluent 2 colour picker: a colour and a stack of controls that edit it.
///
/// ```dart
/// FluentColorPicker(
///   color: colour,
///   onColorChanged: (next) => setState(() => colour = next),
///   children: const <Widget>[
///     FluentColorArea(semanticLabel: 'Saturation and brightness'),
///     FluentColorSlider(semanticLabel: 'Hue'),
///     FluentAlphaSlider(semanticLabel: 'Alpha'),
///   ],
/// )
/// ```
///
/// The children take no `color` and no `onChanged` of their own: they read both
/// from here through [FluentColorPickerScope], which is why they can be `const`
/// and why all three always agree. Give a child its own `color` or `onChanged`
/// and that wins — the same precedence upstream's `props.color || ctx.color`
/// has.
///
/// Each control also works on its own, outside any picker; four of the eight
/// upstream stories use them that way.
///
/// ## Controlled, like every other input here
///
/// The picker never holds the colour. It renders the one you pass and reports
/// the one a gesture or a key landed on. There is deliberately no
/// `defaultColor`: upstream's uncontrolled mode gives each of the three
/// children its own copy of the value, and they drift apart the moment one of
/// them is dragged.
///
/// Pass `onColorChanged: null` to disable every control inside.
///
/// ## Give it a width
///
/// The colour area is 300 square at minimum and grows to the width it is given,
/// so a picker needs a bounded one — `SizedBox(width: 300)` is upstream's own
/// story layout.
///
/// Customisation follows the same three rungs as every other component here.
/// [style] is merged last and wins; [FluentColorPickerTheme] restyles a
/// subtree; and for anything further, [resolveFluentColorPickerState],
/// [resolveFluentColorPickerStyle] and [buildFluentColorPicker] are public so
/// any one of them can be replaced without forking this widget.
class FluentColorPicker extends StatelessWidget {
  /// Creates a picker over [children]. Omit [onColorChanged] to disable it.
  const FluentColorPicker({
    super.key,
    required this.color,
    required this.children,
    this.onColorChanged,
    this.shape = FluentColorPickerShape.rounded,
    this.style,
    this.semanticLabel,
  });

  /// The colour every control inside shows.
  final HSVColor color;

  /// The controls. Order is yours; upstream's is area, hue, alpha.
  final List<Widget> children;

  /// Called with the colour a gesture or a key landed on. Null disables every
  /// control inside.
  final ValueChanged<HSVColor>? onColorChanged;

  /// The corner treatment every control inside takes.
  final FluentColorPickerShape shape;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentColorPickerStyle? style;

  /// Announced by assistive technology as the group's name, if given.
  ///
  /// Upstream's root is a plain `div` with no role, so this is opt-in: a picker
  /// whose children are already labelled does not need a second announcement.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentColorPickerState(
      children: children,
      shape: shape,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentColorPickerStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentColorPickerTheme.maybeOf(context)).merge(style);

    final Widget picker = FluentColorPickerScope(
      color: color,
      shape: shape,
      onColorChanged: onColorChanged,
      child: buildFluentColorPicker(state, resolved, const <WidgetState>{}),
    );

    final label = semanticLabel;
    if (label == null) return picker;
    return Semantics(
      label: label,
      container: true,
      explicitChildNodes: true,
      child: picker,
    );
  }
}
