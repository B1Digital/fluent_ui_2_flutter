import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'swatch_style.dart';

/// What a swatch is showing. Figma's `Style` axis plus the two `State` values
/// that are really content rather than interaction.
///
/// `Style=Icon` is not a member: the Figma icon variants are a colour swatch
/// with a glyph laid over it, identical in fill, ring and size to their
/// `Style=Color` twins, so an icon is a slot on [FluentSwatch] rather than a
/// kind of its own.
enum FluentSwatchKind {
  /// A flat colour. Figma `Style=Color`, and `Style=Icon` with a glyph.
  color,

  /// An image, painted `BoxFit.cover`. Figma `Style=Image`.
  image,

  /// The "no colour chosen yet" slot: a dashed outline over nothing.
  /// Figma `State=Empty`.
  empty,

  /// The "no colour" choice: an outlined square struck through with a
  /// diagonal bar. Figma `State=Transparent`.
  ///
  /// Not a checkerboard — the Fluent 2 file draws a single red bar corner to
  /// corner, and the checkerboard belongs to other design systems.
  transparent,
}

/// Swatch footprint. Figma's `Size` axis.
enum FluentSwatchSize {
  /// 20 square, 16 icon.
  extraSmall,

  /// 24 square, 16 icon.
  small,

  /// 28 square, 20 icon. The default.
  medium,

  /// 32 square, 24 icon.
  large,
}

/// Corner treatment. Figma's `Shape` variable collection, whose
/// `Swatch/Default` entry resolves Rounded to `Corner radius/Medium`, Circular
/// to `Corner radius/Circular` and Square to `Corner radius/None`.
enum FluentSwatchShape {
  /// `FluentRadius.medium`.
  rounded,

  /// A circle.
  circular,

  /// Square corners. **The default** — the Figma component set pins the
  /// `Shape` collection to its `Square` mode, and upstream's
  /// `useColorSwatchStyles` likewise defaults `shape` to `'square'`.
  square,
}

/// Everything needed to resolve a swatch's style, independent of size and
/// shape.
///
/// [buildFluentSwatch] takes this rather than [FluentSwatchState], which is
/// what makes "Fluent's state, my own styling, Fluent's rendering" a supported
/// path rather than a fork.
@immutable
class FluentSwatchBaseState {
  /// Creates a base state.
  const FluentSwatchBaseState({
    required this.enabled,
    required this.selected,
    required this.kind,
    this.color,
    this.image,
    this.icon,
  });

  /// Whether the swatch responds to input.
  final bool enabled;

  /// Whether this swatch is the chosen one.
  ///
  /// A real Fluent Selected state, not a stand-in for focus: a swatch picker
  /// is a radio group and the selection ring outlives the focus ring.
  final bool selected;

  /// What the swatch is showing.
  final FluentSwatchKind kind;

  /// The colour on offer. Null for every kind but [FluentSwatchKind.color].
  final Color? color;

  /// The image on offer. Null for every kind but [FluentSwatchKind.image].
  final DecorationImage? image;

  /// A glyph laid over the surface — Figma's `Style=Icon`, and the mark a
  /// disabled swatch is struck through with.
  final Widget? icon;
}

/// A swatch's fully resolved state, including the design axes.
@immutable
class FluentSwatchState extends FluentSwatchBaseState {
  /// Creates a resolved state.
  const FluentSwatchState({
    required super.enabled,
    required super.selected,
    required super.kind,
    required this.size,
    required this.shape,
    super.color,
    super.image,
    super.icon,
  });

  /// Footprint and icon ramp.
  final FluentSwatchSize size;

  /// Corner treatment.
  final FluentSwatchShape shape;
}

/// Builds the state a swatch will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentSwatchState resolveFluentSwatchState({
  bool enabled = true,
  bool selected = false,
  FluentSwatchKind kind = FluentSwatchKind.color,
  FluentSwatchSize size = FluentSwatchSize.medium,
  FluentSwatchShape shape = FluentSwatchShape.square,
  Color? color,
  DecorationImage? image,
  Widget? icon,
}) => FluentSwatchState(
  enabled: enabled,
  selected: selected,
  kind: kind,
  size: size,
  shape: shape,
  color: color,
  image: image,
  icon: icon,
);

/// The bar drawn across a transparent swatch.
///
/// The one value in the whole `Swatch` set that Figma binds **no variable
/// to** — the `TransparentSwatch-line` layer carries a raw `#DB0000`. There is
/// therefore no Fluent token to select here and none is invented; the literal
/// is lifted verbatim and exposed so a consumer can replace it through
/// `FluentSwatchStyle.markColor`. It is a sign rather than a surface: mid-red
/// reads on the light, dark and high-contrast canvases alike.
const Color kFluentSwatchTransparentMark = Color(0xFFDB0000);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour comes from a Fluent token;
/// nothing here computes one.
///
/// Token sources are the Figma `Swatch` component set, extracted into
/// `test/fixtures/swatch.json` and asserted variant-by-variant in the tests.
FluentSwatchStyle resolveFluentSwatchStyle(
  FluentSwatchState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Geometry, verbatim from the Figma Swatch set. The icon ramp is upstream's
  // (16/16/20/24); Figma states it only on the two variants whose icon frame
  // carries auto-layout, and both agree — Small insets 4 into 24 and Medium 4
  // into 28.
  final (dimension, iconSize) = switch (state.size) {
    FluentSwatchSize.extraSmall => (FluentSize.size200, FluentSize.size160),
    FluentSwatchSize.small => (FluentSize.size240, FluentSize.size160),
    FluentSwatchSize.medium => (FluentSize.size280, FluentSize.size200),
    FluentSwatchSize.large => (FluentSize.size320, FluentSize.size240),
  };

  // ExtraSmall carries the whole ring one step thinner than its siblings.
  final thinnest = state.size == FluentSwatchSize.extraSmall;
  // Upstream's `selectedSmall`: the two small sizes have no room for the wide
  // selected ring.
  final compact = thinnest || state.size == FluentSwatchSize.small;

  final radius = switch (state.shape) {
    FluentSwatchShape.rounded => FluentRadius.allMedium,
    FluentSwatchShape.circular => FluentRadius.allCircular,
    FluentSwatchShape.square => BorderRadius.zero,
  };

  // Only a colour swatch has a surface of its own. The other three paint
  // Fluent's transparent token rather than `Colors.transparent`, so a high
  // contrast theme can turn them opaque.
  final background = state.kind == FluentSwatchKind.color
      ? state.color ?? c.transparentBackground
      : c.transparentBackground;

  // The resting outline. Invisible on a colour or image swatch in a normal
  // theme and opaque in high contrast; a real grey rule on the empty and
  // transparent kinds.
  final restStroke = switch (state.kind) {
    FluentSwatchKind.empty => c.neutralForeground4,
    // Figma binds the global palette entry rather than an alias here, so this
    // one does not follow the theme. Carried through as the file states it.
    FluentSwatchKind.transparent => FluentGrey.at(50),
    FluentSwatchKind.color || FluentSwatchKind.image => c.transparentStroke,
  };

  // A swatch's focus indicator is drawn *inside* the box, which is the one
  // documented exception to this package's outward ring:
  // `useColorSwatchStyles`' reset kills the border and the outline outright and
  // replaces them with `inset 0 0 0 strokeWidthThick strokeFocus2,
  // inset 0 0 0 strokeWidthThicker strokeFocus1` — a 2px focus band flush with
  // the edge and a 1px `strokeFocus1` hairline inside it, going 3px + 2px when
  // the swatch is also selected. The live picker confirms it: the swatch stays
  // 28 square and the neighbour pitch stays 32, where an outward ring would
  // have grown both. Figma's `State` axis has no Focus variant at all, so
  // React is the sole authority here, exactly as it is for the selected band.
  bool focused(Set<WidgetState> states) =>
      states.contains(WidgetState.focused) &&
      !states.contains(WidgetState.disabled);

  final band = FluentStateColor.tokens(
    rest: restStroke,
    hover: c.compoundBrandStroke,
    pressed: c.compoundBrandStrokePressed,
    selected: c.brandStroke1,
    disabled: restStroke,
  );

  return FluentSwatchStyle(
    backgroundColor: FluentStateColor.tokens(rest: background),
    borderColor: WidgetStateProperty.resolveWith<Color?>(
      (states) => focused(states) ? c.strokeFocus2 : band.resolve(states),
    ),
    borderWidth: WidgetStateProperty.resolveWith<double?>((states) {
      if (states.contains(WidgetState.disabled)) return FluentStroke.thin;
      if (focused(states)) {
        return states.contains(WidgetState.selected)
            ? FluentStroke.thicker
            : FluentStroke.thick;
      }
      if (states.contains(WidgetState.pressed)) {
        return thinnest ? FluentStroke.thick : FluentStroke.thicker;
      }
      if (states.contains(WidgetState.hovered)) {
        return thinnest ? FluentStroke.thin : FluentStroke.thick;
      }
      if (states.contains(WidgetState.selected)) {
        return compact ? FluentStroke.thick : FluentStroke.thicker;
      }
      return FluentStroke.thin;
    }),
    // Upstream stacks a second inset shadow under the selected ring so the
    // brand band never touches the swatch colour. Figma has no Selected
    // variant at all, so this band is the one part of the component the React
    // source is the sole authority for — and the focus indicator above stacks
    // its own hairline the same way.
    innerBorderColor: WidgetStateProperty.resolveWith<Color?>(
      (states) =>
          (focused(states) ||
              (states.contains(WidgetState.selected) &&
                  !states.contains(WidgetState.disabled)))
          ? c.strokeFocus1
          : null,
    ),
    innerBorderWidth: WidgetStateProperty.resolveWith<double?>((states) {
      if (focused(states)) {
        // 3px total minus the 2px focus band, and 5 minus 3 when selected.
        return states.contains(WidgetState.selected)
            ? FluentStroke.thick
            : FluentStroke.thin;
      }
      if (!states.contains(WidgetState.selected) ||
          states.contains(WidgetState.disabled)) {
        return FluentStroke.none;
      }
      // 5px total minus the 3px outer band, and 3 minus 2 when compact.
      return compact ? FluentStroke.thin : FluentStroke.thick;
    }),
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(radius),
    size: WidgetStatePropertyAll<Size?>(Size.square(dimension)),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    // Figma binds `Colors/Neutral/White` on both the icon glyph and the
    // disabled mark; the alias that means "white on a filled surface" — and
    // that keeps meaning it in dark and high contrast — is this one.
    iconColor: WidgetStatePropertyAll<Color?>(c.neutralForegroundInverted),
    markColor: const WidgetStatePropertyAll<Color?>(
      kFluentSwatchTransparentMark,
    ),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders a swatch from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentSwatchBaseState] rather than [FluentSwatchState] on purpose: it
/// never reads size or shape, so a consumer can supply their own style and
/// still use Fluent's rendering and focus ring.
///
/// [states] is the live interaction set from [FluentInteractive].
Widget buildFluentSwatch(
  FluentSwatchBaseState state,
  FluentSwatchStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? BorderRadius.zero;
  final size = style.size?.resolve(states) ?? const Size.square(28);
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final innerWidth =
      style.innerBorderWidth?.resolve(states) ?? FluentStroke.none;
  final innerColor = style.innerBorderColor?.resolve(states);
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final iconColor = style.iconColor?.resolve(states);

  // Upstream draws the empty swatch's rule `1px dashed`, which no
  // `BoxDecoration` can express — so on the states that keep it, the outline
  // moves to the painter and the decoration draws none. Hover, press and
  // selection replace it with a solid brand band.
  final dashed =
      state.kind == FluentSwatchKind.empty &&
      !states.contains(WidgetState.hovered) &&
      !states.contains(WidgetState.pressed) &&
      !states.contains(WidgetState.selected);
  final slashed = state.kind == FluentSwatchKind.transparent;

  Widget? content = state.icon == null
      ? null
      : Center(
          child: IconTheme.merge(
            data: IconThemeData(color: iconColor, size: iconSize),
            child: state.icon!,
          ),
        );

  if (innerWidth > 0 && innerColor != null) {
    content = Padding(
      padding: EdgeInsets.all(borderWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _deflate(radius, borderWidth),
          border: Border.all(color: innerColor, width: innerWidth),
        ),
        child: content,
      ),
    );
  }

  Widget surface = DecoratedBox(
    decoration: BoxDecoration(
      color: style.backgroundColor?.resolve(states),
      image: state.image,
      borderRadius: radius,
      border: !dashed && borderWidth > 0 && borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
    ),
    child: content,
  );

  if (dashed || slashed) {
    surface = CustomPaint(
      foregroundPainter: FluentSwatchMarkPainter(
        borderRadius: radius,
        dashColor: dashed ? borderColor : null,
        dashWidth: borderWidth,
        slashColor: slashed ? style.markColor?.resolve(states) : null,
      ),
      child: surface,
    );
  }

  // No `FluentFocusRing`. A swatch is the one component whose focus indicator
  // upstream draws *inside* the box — `useColorSwatchStyles`' custom indicator
  // is a pair of inset shadows with `border: none; outline: none` — so the two
  // bands come out of `borderColor`/`innerBorderColor` above and the 20/24/28/32
  // square never grows. Wrapping this in the outward ring would both widen the
  // swatch's footprint and drop the `strokeFocus1` hairline.
  return SizedBox.fromSize(size: size, child: surface);
}

/// Pulls every corner of [radius] in by [delta], clamped at zero so a square
/// corner stays square.
BorderRadius _deflate(BorderRadius radius, double delta) => BorderRadius.only(
  topLeft: _deflateCorner(radius.topLeft, delta),
  topRight: _deflateCorner(radius.topRight, delta),
  bottomLeft: _deflateCorner(radius.bottomLeft, delta),
  bottomRight: _deflateCorner(radius.bottomRight, delta),
);

Radius _deflateCorner(Radius radius, double delta) => Radius.elliptical(
  math.max(0, radius.x - delta),
  math.max(0, radius.y - delta),
);

/// Paints the two marks a `BoxDecoration` cannot: the empty swatch's dashed
/// outline and the transparent swatch's diagonal bar.
///
/// A foreground painter rather than more nested boxes, because both marks sit
/// *over* the surface and neither may change the swatch's 20/24/28/32 square.
/// Every input is a public field so tests can assert the tones and widths
/// directly instead of diffing pixels.
class FluentSwatchMarkPainter extends CustomPainter {
  /// Creates a painter. Passing null for a colour suppresses that mark.
  const FluentSwatchMarkPainter({
    required this.borderRadius,
    this.dashColor,
    this.dashWidth = FluentStroke.thin,
    this.dashPattern = const <double>[2, 2],
    this.slashColor,
    this.slashWidth = FluentStroke.thick,
  });

  /// The swatch's own corner radius. The dashed outline follows it.
  final BorderRadius borderRadius;

  /// Dashed outline colour, or null to draw no outline.
  final Color? dashColor;

  /// Dashed outline width. Figma: `Stroke width/Thin`.
  final double dashWidth;

  /// On/off run lengths. Figma's `dashPattern` on the `EmptySwatch` rectangle
  /// is `[2, 2]`, which is also upstream's plain CSS `dashed`.
  final List<double> dashPattern;

  /// Diagonal bar colour, or null to draw no bar.
  final Color? slashColor;

  /// Diagonal bar width. Figma: `Stroke width/Thick`.
  final double slashWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final slash = slashColor;
    if (slash != null) {
      // Figma draws the bar corner to corner across the swatch, bottom-left to
      // top-right, and clips it to the square. Its own layer is 4% shorter
      // than the full diagonal, which is the stroke cap being folded into the
      // measured length rather than an inset.
      canvas
        ..save()
        ..clipRRect(borderRadius.toRRect(rect))
        ..drawLine(
          Offset(0, size.height),
          Offset(size.width, 0),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = slashWidth
            ..color = slash,
        )
        ..restore();
    }

    final dash = dashColor;
    if (dash == null || dashWidth <= 0) return;
    // Inset by half the stroke so the outline lands inside the square, which
    // is what Figma's `strokeAlign: INSIDE` and CSS's border box both do.
    final inset = dashWidth / 2;
    final outline = Path()
      ..addRRect(_deflate(borderRadius, inset).toRRect(rect.deflate(inset)));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = dashWidth
      ..color = dash;
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      var index = 0;
      while (distance < metric.length) {
        final run = dashPattern[index % dashPattern.length];
        if (index.isEven) {
          canvas.drawPath(
            metric.extractPath(
              distance,
              math.min(distance + run, metric.length),
            ),
            paint,
          );
        }
        distance += run;
        index++;
      }
    }
  }

  @override
  bool shouldRepaint(FluentSwatchMarkPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.dashColor != dashColor ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashPattern != dashPattern ||
      oldDelegate.slashColor != slashColor ||
      oldDelegate.slashWidth != slashWidth;
}

/// Overrides the swatch style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then
/// the widget's own `style`. `FluentSwatchPicker` installs one of these to
/// push a single size and shape onto every swatch inside it.
class FluentSwatchTheme extends InheritedTheme {
  /// Applies [style] to every `FluentSwatch` in [child].
  const FluentSwatchTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the kind, size and shape defaults.
  final FluentSwatchStyle style;

  /// The nearest swatch style, or null.
  static FluentSwatchStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentSwatchTheme>()?.style;

  @override
  bool updateShouldNotify(FluentSwatchTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentSwatchTheme(style: style, child: child);
}

/// A Fluent 2 swatch: one selectable colour, image or "no colour" cell.
///
/// ```dart
/// FluentSwatch(
///   color: const Color(0xFFE3008C),
///   semanticLabel: 'Hot pink',
///   selected: value == 'hot-pink',
///   onPressed: () => setState(() => value = 'hot-pink'),
/// )
/// ```
///
/// Pass `onPressed: null` to disable it — disabled is a real state here, not a
/// visual treatment: the swatch stops reporting hover and press, refuses
/// focus, and never invokes the callback. A disabled swatch keeps its colour
/// and is struck through with [disabledIcon].
///
/// ## No motion
///
/// Nothing about a swatch animates. `react-swatch-picker` declares no
/// `transition` in any of its four styles files, so hover, press and selection
/// land on the frame they happen. That is a transcription, not an oversight —
/// see `FluentMotionSpec`'s note on the components upstream leaves instant.
///
/// ## Customisation
///
/// [style] is merged last and wins; [FluentSwatchTheme] restyles a subtree;
/// and for anything further, [resolveFluentSwatchState],
/// [resolveFluentSwatchStyle] and [buildFluentSwatch] are public so any one of
/// them can be replaced without forking this widget.
class FluentSwatch extends StatelessWidget {
  /// Creates a colour swatch, optionally with a glyph over it — Figma's
  /// `Style=Color` and `Style=Icon`.
  const FluentSwatch({
    super.key,
    required this.color,
    required this.semanticLabel,
    this.icon,
    this.onPressed,
    this.selected = false,
    this.size = FluentSwatchSize.medium,
    this.shape = FluentSwatchShape.square,
    this.disabledIcon,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : kind = FluentSwatchKind.color,
       image = null;

  /// Creates an image swatch — Figma's `Style=Image`. The image is painted
  /// `BoxFit.cover`, matching upstream's `background-size: cover`.
  const FluentSwatch.image({
    super.key,
    required ImageProvider<Object> this.image,
    required this.semanticLabel,
    this.onPressed,
    this.selected = false,
    this.size = FluentSwatchSize.medium,
    this.shape = FluentSwatchShape.square,
    this.disabledIcon,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : kind = FluentSwatchKind.image,
       color = null,
       icon = null;

  /// Creates the empty slot — a dashed outline over nothing. Figma's
  /// `State=Empty`.
  const FluentSwatch.empty({
    super.key,
    required this.semanticLabel,
    this.onPressed,
    this.selected = false,
    this.size = FluentSwatchSize.medium,
    this.shape = FluentSwatchShape.square,
    this.disabledIcon,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : kind = FluentSwatchKind.empty,
       color = null,
       image = null,
       icon = null;

  /// Creates the "no colour" choice — an outlined square struck through with a
  /// diagonal bar. Figma's `State=Transparent`.
  const FluentSwatch.transparent({
    super.key,
    required this.semanticLabel,
    this.onPressed,
    this.selected = false,
    this.size = FluentSwatchSize.medium,
    this.shape = FluentSwatchShape.square,
    this.disabledIcon,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : kind = FluentSwatchKind.transparent,
       color = null,
       image = null,
       icon = null;

  /// What this swatch is showing. Set by the constructor.
  final FluentSwatchKind kind;

  /// The colour on offer, for [FluentSwatch.new].
  final Color? color;

  /// The image on offer, for [FluentSwatch.image].
  final ImageProvider<Object>? image;

  /// A glyph laid over the colour — Figma's `Style=Icon`.
  final Widget? icon;

  /// The mark a disabled swatch is struck through with.
  ///
  /// Defaults to Fluent's `prohibited` glyph in `neutralForegroundInverted`,
  /// which is what both the Figma file and upstream's `disabledIcon` slot
  /// draw. Upstream reaches for `ProhibitedFilled`; `fluentui_system_icons`
  /// ships only the regular weight of that glyph, so that is what is used.
  /// Pass your own to replace it.
  final Widget? disabledIcon;

  /// Announced by assistive technology. Required: a swatch has no text of its
  /// own, so a colour name is the only thing a screen reader can say.
  final String semanticLabel;

  /// Invoked on tap and on Space or Enter. Null disables the swatch.
  final VoidCallback? onPressed;

  /// Whether this swatch is the chosen one.
  final bool selected;

  /// Footprint and icon ramp. Ignored when a `FluentSwatchPicker` ancestor
  /// sets one — see that class for why.
  final FluentSwatchSize size;

  /// Corner treatment. Ignored when a `FluentSwatchPicker` ancestor sets one.
  final FluentSwatchShape shape;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentSwatchStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final theme = FluentTheme.of(context);
    final provider = image;

    final state = resolveFluentSwatchState(
      enabled: enabled,
      selected: selected,
      kind: kind,
      size: size,
      shape: shape,
      color: color,
      image: provider == null
          ? null
          : DecorationImage(image: provider, fit: BoxFit.cover),
      icon: enabled
          ? icon
          : disabledIcon ?? const Icon(FluentIcons.prohibited_20_regular),
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentSwatchStyle(
      state,
      theme,
    ).merge(FluentSwatchTheme.maybeOf(context)).merge(style);

    return Semantics(
      label: semanticLabel,
      enabled: enabled,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      child: FluentInteractive(
        onPressed: onPressed,
        enabled: enabled,
        focusNode: focusNode,
        autofocus: autofocus,
        mouseCursor:
            resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
            SystemMouseCursors.click,
        builder: (context, states, _) => buildFluentSwatch(
          state,
          resolved,
          // FluentInteractive tracks hover, press, focus and disabled; a
          // swatch's selection is owned by whoever holds the value, so it is
          // folded in here rather than being another thing to wire up.
          selected ? <WidgetState>{...states, WidgetState.selected} : states,
        ),
      ),
    );
  }
}
