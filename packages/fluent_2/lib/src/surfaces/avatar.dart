import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import 'avatar_style.dart';
import 'presence_badge.dart';

/// Avatar edge length. Figma's `Size` axis, and identical to upstream's
/// `AvatarSize` union minus `128`, which the design file does not draw.
enum FluentAvatarSize {
  /// 16 square.
  size16(16),

  /// 20 square.
  size20(20),

  /// 24 square.
  size24(24),

  /// 28 square.
  size28(28),

  /// 32 square. The default.
  size32(32),

  /// 36 square.
  size36(36),

  /// 40 square.
  size40(40),

  /// 48 square.
  size48(48),

  /// 56 square.
  size56(56),

  /// 64 square.
  size64(64),

  /// 72 square.
  size72(72),

  /// 96 square.
  size96(96),

  /// 120 square.
  size120(120);

  const FluentAvatarSize(this.edge);

  /// The avatar's width and height in logical pixels.
  final double edge;
}

/// Corner treatment. Figma's `Avatar shape` variable collection.
enum FluentAvatarShape {
  /// Fully rounded. The default.
  circular,

  /// `FluentRadius.small` at every size — see [resolveFluentAvatarStyle] for
  /// why this does not ramp the way React's does.
  square,
}

/// Which of Figma's 33 `Avatar color` modes an avatar paints in.
///
/// Thirty of the modes name a [FluentPaletteFamily] and resolve through the
/// palette layer; the other three are roles rather than hues. The five palette
/// families Fluent ships but the Avatar collection does not offer — berry, dark
/// orange, green, light green and yellow — are absent here on purpose, matching
/// upstream's own colour list exactly.
enum FluentAvatarColor {
  /// `Neutral/Background/6/Rest` under `Neutral/Foreground/3/Rest`. The default.
  neutral(null),

  /// The brand fill, with the on-brand foreground.
  brand(null),

  /// The `+3` tile at the end of an avatar group: a plain surface with a real
  /// `Neutral/Stroke/2/Rest` outline, which is the only mode whose inside
  /// stroke is visible outside high contrast.
  overflow(null),

  /// Dark red.
  darkRed(FluentPaletteFamily.darkRed),

  /// Cranberry.
  cranberry(FluentPaletteFamily.cranberry),

  /// Red.
  red(FluentPaletteFamily.red),

  /// Pumpkin.
  pumpkin(FluentPaletteFamily.pumpkin),

  /// Peach.
  peach(FluentPaletteFamily.peach),

  /// Marigold.
  marigold(FluentPaletteFamily.marigold),

  /// Gold.
  gold(FluentPaletteFamily.gold),

  /// Brass.
  brass(FluentPaletteFamily.brass),

  /// Brown.
  brown(FluentPaletteFamily.brown),

  /// Dark green.
  darkGreen(FluentPaletteFamily.darkGreen),

  /// Forest.
  forest(FluentPaletteFamily.forest),

  /// Seafoam.
  seafoam(FluentPaletteFamily.seafoam),

  /// Light teal.
  lightTeal(FluentPaletteFamily.lightTeal),

  /// Teal.
  teal(FluentPaletteFamily.teal),

  /// Steel.
  steel(FluentPaletteFamily.steel),

  /// Blue.
  blue(FluentPaletteFamily.blue),

  /// Royal blue. Figma calls the mode `Royal`.
  royalBlue(FluentPaletteFamily.royalBlue),

  /// Cornflower.
  cornflower(FluentPaletteFamily.cornflower),

  /// Navy.
  navy(FluentPaletteFamily.navy),

  /// Lavender. Figma spells the mode `Lavendar`.
  lavender(FluentPaletteFamily.lavender),

  /// Purple.
  purple(FluentPaletteFamily.purple),

  /// Grape.
  grape(FluentPaletteFamily.grape),

  /// Lilac.
  lilac(FluentPaletteFamily.lilac),

  /// Pink.
  pink(FluentPaletteFamily.pink),

  /// Magenta.
  magenta(FluentPaletteFamily.magenta),

  /// Plum.
  plum(FluentPaletteFamily.plum),

  /// Beige.
  beige(FluentPaletteFamily.beige),

  /// Mink.
  mink(FluentPaletteFamily.mink),

  /// Platinum.
  platinum(FluentPaletteFamily.platinum),

  /// Anchor.
  anchor(FluentPaletteFamily.anchor);

  const FluentAvatarColor(this.family);

  /// The palette family this mode aliases, or null for [neutral], [brand] and
  /// [overflow], which resolve to alias-layer tokens instead.
  final FluentPaletteFamily? family;
}

/// Whether the person is currently doing something, and therefore whether the
/// activity ring is drawn.
enum FluentAvatarActive {
  /// Activity is not being reported. No ring, and nothing to animate. The
  /// default.
  unset,

  /// Ring shown, avatar at full size.
  active,

  /// Ring collapsed and faded out, avatar scaled to 0.875 at 0.8 opacity.
  inactive,
}

/// The four transitions upstream's `useAvatarStyles.styles.ts` declares.
///
/// Transcribed rather than chosen. The root's `::before` — the ring — carries
/// `transition: margin, opacity` at `durationUltraSlow, durationSlower` on
/// `curveEasyEaseMax, curveLinear`, and the root itself carries
/// `transition: transform, opacity` at `durationUltraSlow, durationFaster` on
/// the same pair of curves. The `inactive` rule then swaps the first curve for
/// `curveDecelerateMin` in both, which is what [leave] is.
///
/// Reduced motion is handled by [FluentAnimatedStyle], not here; upstream's own
/// clamp is a `0.01ms` duration under `prefers-reduced-motion`.
abstract final class FluentAvatarMotion {
  /// Ring expansion and avatar scale, on the way *to* [FluentAvatarActive.active].
  static const FluentMotionSpec arrive = FluentMotionSpec(
    duration: FluentDuration.ultraSlow,
    curve: FluentCurve.easyEaseMax,
  );

  /// Ring collapse and avatar scale, on the way *to*
  /// [FluentAvatarActive.inactive]. Same duration, sharper curve.
  static const FluentMotionSpec leave = FluentMotionSpec(
    duration: FluentDuration.ultraSlow,
    curve: FluentCurve.decelerateMin,
  );

  /// Ring opacity. Linear, and slower than the avatar's own fade.
  static const FluentMotionSpec ringFade = FluentMotionSpec(
    duration: FluentDuration.slower,
    curve: FluentCurve.linear,
  );

  /// Avatar opacity. Linear, and the quickest of the four.
  static const FluentMotionSpec rootFade = FluentMotionSpec(
    duration: FluentDuration.faster,
    curve: FluentCurve.linear,
  );
}

/// Everything needed to render an avatar, independent of colour, size and
/// shape.
///
/// The counterpart of upstream's `AvatarState`. Content is already chosen here
/// rather than in the style: which person glyph a size uses, and how large the
/// presence badge is, are decided by [resolveFluentAvatarState].
@immutable
class FluentAvatarBaseState {
  /// Creates a base state.
  const FluentAvatarBaseState({
    required this.active,
    this.image,
    this.initials,
    this.icon,
    this.badge,
    this.semanticLabel,
  });

  /// Whether the activity ring is drawn, and how.
  final FluentAvatarActive active;

  /// The photo, drawn cover-fit and clipped to the avatar's own radius.
  final ImageProvider<Object>? image;

  /// One to three letters, drawn when there is no [image].
  final String? initials;

  /// The fallback glyph, drawn when there is neither [image] nor [initials].
  final Widget? icon;

  /// The presence badge, anchored to the bottom-right corner.
  final Widget? badge;

  /// Announced by assistive technology. Usually the person's name.
  final String? semanticLabel;
}

/// An avatar's fully resolved state, including the design axes.
@immutable
class FluentAvatarState extends FluentAvatarBaseState {
  /// Creates a resolved state.
  const FluentAvatarState({
    required super.active,
    required this.color,
    required this.size,
    required this.shape,
    super.image,
    super.initials,
    super.icon,
    super.badge,
    super.semanticLabel,
  });

  /// Which `Avatar color` mode to paint in.
  final FluentAvatarColor color;

  /// Edge length.
  final FluentAvatarSize size;

  /// Corner treatment.
  final FluentAvatarShape shape;
}

/// Builds the state an avatar will be styled and rendered from.
///
/// The first of the three-function recomposition contract, and the one that
/// makes the two content decisions:
///
/// * the fallback **glyph** is the `person` icon at the nominal size Figma
///   instances for this avatar — 12, 16, 20, 24, 28, 32 or 48, never the
///   avatar's own edge;
/// * the **badge** is a [FluentPresenceBadge] whose size comes from the same
///   Figma table, so a 32 avatar gets a 10 badge and a 120 avatar a 28.
///
/// Content precedence is image, then initials, then icon — upstream's order.
/// Note that initials are *not* derived from [semanticLabel]: upstream's
/// `getInitials` is a locale-sensitive parser, and guessing at it would be a
/// worse default than none.
FluentAvatarState resolveFluentAvatarState({
  FluentAvatarColor color = FluentAvatarColor.neutral,
  FluentAvatarSize size = FluentAvatarSize.size32,
  FluentAvatarShape shape = FluentAvatarShape.circular,
  FluentAvatarActive active = FluentAvatarActive.unset,
  ImageProvider<Object>? image,
  String? initials,
  Widget? icon,
  FluentPresenceStatus? status,
  bool outOfOffice = false,
  String? semanticLabel,
}) => FluentAvatarState(
  color: color,
  size: size,
  shape: shape,
  active: active,
  image: image,
  initials: image == null ? initials : null,
  icon: image == null && initials == null ? (icon ?? Icon(_glyph(size))) : null,
  badge: status == null
      ? null
      : FluentPresenceBadge(
          status: status,
          outOfOffice: outOfOffice,
          size: _badgeSize(size),
        ),
  semanticLabel: semanticLabel,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour is an explicit token: the palette
/// modes go through [FluentPaletteColors], the three role modes through the
/// alias layer.
///
/// Four values disagree with `useAvatarStyles.styles.ts`; Figma wins in all
/// four and `doc/token-divergences.md` records them. The two worth knowing
/// while reading this function are the **square radius**, which the
/// `Avatar shape` collection flattens to `Corner radius/Small` at every size
/// where React ramps small → medium → large → xLarge, and the **inside stroke
/// width**, which follows the avatar's own 1/2/3/4 ramp rather than React's
/// flat `strokeWidthThin`.
FluentAvatarStyle resolveFluentAvatarStyle(
  FluentAvatarState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final family = state.color.family;

  // `Avatar color` → Background / Foreground / Active stroke, resolved per mode.
  final (background, foreground, ring) = switch (state.color) {
    FluentAvatarColor.neutral => (
      c.neutralBackground6,
      c.neutralForeground3,
      c.brandStroke1,
    ),
    FluentAvatarColor.brand => (
      c.brandBackground,
      c.neutralForegroundOnBrand,
      c.neutralStrokeOnBrand,
    ),
    FluentAvatarColor.overflow => (
      c.neutralBackground1,
      c.neutralForeground1,
      c.transparentStroke,
    ),
    _ => (
      c.palette.background2Rest(family!),
      c.palette.foreground2Rest(family),
      c.palette.strokeActiveRest(family),
    ),
  };

  // `Avatar color` → Inside stroke. Transparent in every mode but Overflow —
  // and a Fluent transparent token turns OPAQUE in high contrast, which is why
  // this is a real token rather than a null border.
  final border = state.color == FluentAvatarColor.overflow
      ? c.neutralStroke2
      : c.transparentStroke;

  final edge = state.size.edge;

  // Figma's `Stroke width/*` binding on the variant frame and its `Fill` child.
  final borderWidth = switch (state.size) {
    FluentAvatarSize.size16 ||
    FluentAvatarSize.size20 ||
    FluentAvatarSize.size24 ||
    FluentAvatarSize.size28 ||
    FluentAvatarSize.size32 => FluentStroke.thin,
    FluentAvatarSize.size36 ||
    FluentAvatarSize.size40 ||
    FluentAvatarSize.size48 => FluentStroke.thick,
    FluentAvatarSize.size56 => FluentStroke.thicker,
    _ => FluentStroke.thickest,
  };

  // The hidden `Activity ring` rectangle: 2 up to 48, 3 from 56 up. React goes
  // on to `strokeWidthThickest` above 64; Figma never does.
  final ringWidth = edge <= 48 ? FluentStroke.thick : FluentStroke.thicker;

  final textStyle = switch (state.size) {
    FluentAvatarSize.size16 ||
    FluentAvatarSize.size20 ||
    FluentAvatarSize.size24 => theme.typography.caption2Strong,
    FluentAvatarSize.size28 => theme.typography.caption1Strong,
    FluentAvatarSize.size32 ||
    FluentAvatarSize.size36 ||
    FluentAvatarSize.size40 ||
    FluentAvatarSize.size48 => theme.typography.body1Strong,
    FluentAvatarSize.size56 => theme.typography.subtitle2,
    FluentAvatarSize.size64 ||
    FluentAvatarSize.size72 => theme.typography.subtitle1,
    FluentAvatarSize.size96 ||
    FluentAvatarSize.size120 => theme.typography.title3,
  };

  final radius = switch (state.shape) {
    FluentAvatarShape.circular => FluentRadius.allCircular,
    FluentAvatarShape.square => FluentRadius.allSmall,
  };

  return FluentAvatarStyle(
    backgroundColor: FluentStateColor.tokens(rest: background),
    foregroundColor: FluentStateColor.tokens(rest: foreground),
    borderColor: FluentStateColor.tokens(rest: border),
    borderWidth: WidgetStatePropertyAll<double?>(borderWidth),
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(radius),
    ringColor: FluentStateColor.tokens(rest: ring),
    ringGapColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    ringWidth: WidgetStatePropertyAll<double?>(ringWidth),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    iconSize: WidgetStatePropertyAll<double?>(_glyphSize(state.size)),
    diameter: WidgetStatePropertyAll<double?>(edge),
  );
}

/// Renders an avatar from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentAvatarBaseState] rather than [FluentAvatarState] on purpose: it never
/// reads colour, size or shape, so a consumer can supply their own style and
/// still get Fluent's ring, badge anchoring and activity motion.
///
/// The activity ring is a [CustomPaint] rather than a decoration because it has
/// to paint *outside* the avatar's box without changing what the avatar costs
/// in layout — the same reason `FluentFocusRing` is one.
///
/// With [FluentAvatarActive.unset] this returns the plain box: no ring, no
/// animated wrappers, nothing to settle.
Widget buildFluentAvatar(
  FluentAvatarBaseState state,
  FluentAvatarStyle style,
  Set<WidgetState> states,
) {
  final diameter = style.diameter?.resolve(states) ?? FluentSize.size320;
  final radius =
      style.borderRadius?.resolve(states) ?? FluentRadius.allCircular;
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final borderColor = style.borderColor?.resolve(states);
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final ringColor = style.ringColor?.resolve(states);
  final ringGapColor = style.ringGapColor?.resolve(states);
  final ringWidth = style.ringWidth?.resolve(states) ?? FluentStroke.none;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final textStyle = style.textStyle?.resolve(states);

  final content = switch (state) {
    FluentAvatarBaseState(initials: final String initials) => Text(
      initials,
      textAlign: TextAlign.center,
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
    ),
    FluentAvatarBaseState(icon: final Widget icon) => IconTheme.merge(
      data: IconThemeData(color: foreground, size: iconSize),
      child: icon,
    ),
    _ => null,
  };

  final image = state.image;
  final surface = DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: radius,
      image: image == null
          ? null
          : DecorationImage(image: image, fit: BoxFit.cover),
      border: borderWidth > 0 && borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
    ),
    // Initials and the fallback glyph are decoration, not content: upstream
    // marks both `aria-hidden` and lets the root's own label speak. Leaving
    // them in would announce "Ada Lovelace, AL".
    child: content == null
        ? null
        : Center(child: ExcludeSemantics(child: content)),
  );

  Widget box(double extent, double ringAlpha) {
    Widget avatar = CustomPaint(
      painter: FluentAvatarRingPainter(
        color: ringColor,
        gapColor: ringGapColor,
        // Collapsing the ring onto the avatar is upstream's `margin: 0`.
        width: ringWidth * extent,
        gap: ringWidth * extent,
        borderRadius: radius,
        opacity: ringAlpha,
      ),
      child: surface,
    );
    if (state.badge != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(child: avatar),
          Positioned(right: 0, bottom: 0, child: state.badge!),
        ],
      );
    }
    return SizedBox.square(dimension: diameter, child: avatar);
  }

  if (state.active == FluentAvatarActive.unset) return box(0, 0);

  final inactive = state.active == FluentAvatarActive.inactive;
  final target = inactive ? 0.0 : 1.0;

  return FluentAnimatedStyle<double>(
    value: target,
    // The destination's curve, as CSS does it: the `inactive` rule replaces
    // curveEasyEaseMax with curveDecelerateMin on the way in.
    spec: inactive ? FluentAvatarMotion.leave : FluentAvatarMotion.arrive,
    lerp: _lerpDouble,
    builder: (context, extent) => FluentAnimatedStyle<double>(
      value: target,
      spec: FluentAvatarMotion.ringFade,
      lerp: _lerpDouble,
      builder: (context, ringAlpha) => FluentAnimatedStyle<double>(
        value: target,
        spec: FluentAvatarMotion.rootFade,
        lerp: _lerpDouble,
        builder: (context, rootAlpha) => Opacity(
          opacity: _inactiveOpacity + (1 - _inactiveOpacity) * rootAlpha,
          child: Transform.scale(
            scale: _inactiveScale + (1 - _inactiveScale) * extent,
            child: box(extent, ringAlpha),
          ),
        ),
      ),
    ),
  );
}

/// Upstream's `inactive { opacity: 0.8 }`.
const double _inactiveOpacity = 0.8;

/// Upstream's `inactive { transform: scale(0.875) }`.
const double _inactiveScale = 0.875;

double? _lerpDouble(double? a, double? b, double t) =>
    a == null || b == null ? b : a + (b - a) * t;

/// Paints the activity ring — and, with [gap] left at zero, the flat outline an
/// avatar takes inside a stacked `FluentAvatarGroup`.
///
/// Figma draws the ring as a rectangle inflated by one ring-width with its
/// stroke aligned OUTSIDE, so the ring occupies the band from `+width` to
/// `+2 * width` beyond the avatar and the band from `0` to `+width` is
/// [gapColor]. That is the same geometry as upstream's
/// `::before { margin: calc(-2 * ringWidth); border-width: ringWidth }`.
///
/// Every input is a public field so tests can assert the resolved tokens rather
/// than diff pixels.
class FluentAvatarRingPainter extends CustomPainter {
  /// Creates a painter for the given tones and widths.
  const FluentAvatarRingPainter({
    required this.borderRadius,
    this.color,
    this.gapColor,
    this.width = 0,
    this.gap = 0,
    this.opacity = 1,
  });

  /// The avatar's own corner radius. The ring is concentric to it.
  final BorderRadius borderRadius;

  /// Ring stroke colour. Figma's `Avatar color` → `Active stroke`.
  final Color? color;

  /// Fills the gap between the avatar and the ring. Null leaves it clear, which
  /// is what a stack outline wants.
  final Color? gapColor;

  /// Ring stroke width. Zero paints nothing at all.
  final double width;

  /// Clear space between the avatar's edge and the ring's inner edge.
  final double gap;

  /// Transition opacity, 0 to 1. Multiplies [color] and [gapColor]; it is a
  /// tween value, not a token, and is 1 whenever nothing is animating.
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0 || opacity <= 0) return;
    final rect = (Offset.zero & size).inflate(gap);

    final fill = gapColor;
    if (fill != null) {
      canvas.drawRRect(
        _shift(borderRadius, gap).toRRect(rect),
        Paint()..color = fill.withValues(alpha: fill.a * opacity),
      );
    }

    final stroke = color;
    if (stroke == null) return;
    // A stroke is centred on its path, so Figma's strokeAlign OUTSIDE for a
    // width-w stroke is the same path inflated by w/2 — radius included, which
    // is what keeps the ring concentric rather than merely nested.
    canvas.drawRRect(
      _shift(borderRadius, gap + width / 2).toRRect(rect.inflate(width / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = stroke.withValues(alpha: stroke.a * opacity),
    );
  }

  static BorderRadius _shift(BorderRadius radius, double delta) =>
      BorderRadius.only(
        topLeft: _corner(radius.topLeft, delta),
        topRight: _corner(radius.topRight, delta),
        bottomLeft: _corner(radius.bottomLeft, delta),
        bottomRight: _corner(radius.bottomRight, delta),
      );

  static Radius _corner(Radius radius, double delta) => Radius.elliptical(
    math.max(0, radius.x + delta),
    math.max(0, radius.y + delta),
  );

  @override
  bool shouldRepaint(FluentAvatarRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.gapColor != gapColor ||
      oldDelegate.width != width ||
      oldDelegate.gap != gap ||
      oldDelegate.opacity != opacity ||
      oldDelegate.borderRadius != borderRadius;
}

/// Overrides the avatar style for a subtree.
class FluentAvatarTheme extends InheritedTheme {
  /// Applies [style] to every `FluentAvatar` in [child].
  const FluentAvatarTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the colour, size and shape defaults.
  final FluentAvatarStyle style;

  /// The nearest avatar style, or null.
  static FluentAvatarStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentAvatarTheme>()?.style;

  @override
  bool updateShouldNotify(FluentAvatarTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentAvatarTheme(style: style, child: child);
}

/// A Fluent 2 avatar: a person or entity as a photo, their initials, or a
/// fallback glyph.
///
/// ```dart
/// FluentAvatar(
///   name: 'Ada Lovelace',
///   initials: 'AL',
///   color: FluentAvatarColor.cornflower,
///   size: FluentAvatarSize.size48,
///   status: FluentPresenceStatus.available,
/// )
/// ```
///
/// Non-interactive, like `FluentBadge` and `FluentPresenceBadge`: it takes no
/// hover, press or focus of its own, and there is no disabled state — the Figma
/// set has no `State` axis at all and upstream ships no disabled rule, so a
/// greyed avatar is not a treatment this component may invent. Put it inside a
/// button or a list item and *that* control owns the interaction.
///
/// The activity ring paints **outside** the widget's bounds, so an ancestor
/// clipping tightly to the avatar will shave it. Give it room, or leave
/// [active] at [FluentAvatarActive.unset], which draws no ring at all.
///
/// Customisation follows the usual three rungs: [style] is merged last and
/// wins, [FluentAvatarTheme] restyles a subtree, and
/// [resolveFluentAvatarState], [resolveFluentAvatarStyle] and
/// [buildFluentAvatar] are public for anything further.
class FluentAvatar extends StatelessWidget {
  /// Creates an avatar.
  ///
  /// Pass at most one of [image] and [initials]; whichever is given wins, in
  /// that order, and with neither the avatar falls back to [icon] or to the
  /// `person` glyph.
  const FluentAvatar({
    super.key,
    this.image,
    this.initials,
    this.icon,
    this.name,
    this.color = FluentAvatarColor.neutral,
    this.size = FluentAvatarSize.size32,
    this.shape = FluentAvatarShape.circular,
    this.active = FluentAvatarActive.unset,
    this.status,
    this.outOfOffice = false,
    this.style,
  });

  /// The photo, drawn cover-fit and clipped to the avatar's radius.
  final ImageProvider<Object>? image;

  /// One to three letters, drawn when there is no [image].
  ///
  /// Not derived from [name]: upstream's `getInitials` is locale-sensitive, and
  /// a guess would read worse than the glyph fallback.
  final String? initials;

  /// Replaces the default `person` glyph. Sized and tinted by the style.
  final Widget? icon;

  /// The person's name, announced by assistive technology.
  final String? name;

  /// Which `Avatar color` mode to paint in.
  final FluentAvatarColor color;

  /// Edge length.
  final FluentAvatarSize size;

  /// Corner treatment.
  final FluentAvatarShape shape;

  /// Whether the activity ring is drawn, and how.
  final FluentAvatarActive active;

  /// Shows a [FluentPresenceBadge] in the bottom-right corner, sized from the
  /// avatar.
  final FluentPresenceStatus? status;

  /// Whether the person is out of office. Only read when [status] is set.
  final bool outOfOffice;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentAvatarStyle? style;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentAvatarState(
      color: color,
      size: size,
      shape: shape,
      active: active,
      image: image,
      initials: initials,
      icon: icon,
      status: status,
      outOfOffice: outOfOffice,
      semanticLabel: name,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentAvatarStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentAvatarTheme.maybeOf(context)).merge(style);

    return Semantics(
      image: true,
      label: name,
      container: true,
      child: buildFluentAvatar(state, resolved, const <WidgetState>{}),
    );
  }
}

/// The nominal size Figma instances the `person` glyph at, per avatar size.
/// Identical to upstream's `icon12`…`icon48` ladder.
double _glyphSize(FluentAvatarSize size) => switch (size) {
  FluentAvatarSize.size16 => 12,
  FluentAvatarSize.size20 || FluentAvatarSize.size24 => 16,
  FluentAvatarSize.size28 ||
  FluentAvatarSize.size32 ||
  FluentAvatarSize.size36 ||
  FluentAvatarSize.size40 => 20,
  FluentAvatarSize.size48 => 24,
  FluentAvatarSize.size56 => 28,
  FluentAvatarSize.size64 || FluentAvatarSize.size72 => 32,
  FluentAvatarSize.size96 || FluentAvatarSize.size120 => 48,
};

IconData _glyph(FluentAvatarSize size) => switch (_glyphSize(size)) {
  12 => FluentIcons.person_12_filled,
  16 => FluentIcons.person_16_filled,
  20 => FluentIcons.person_20_filled,
  24 => FluentIcons.person_24_filled,
  28 => FluentIcons.person_28_filled,
  32 => FluentIcons.person_32_filled,
  _ => FluentIcons.person_48_filled,
};

/// The presence badge diameter Figma draws inside each avatar size.
FluentPresenceBadgeSize _badgeSize(FluentAvatarSize size) => switch (size) {
  FluentAvatarSize.size16 ||
  FluentAvatarSize.size20 ||
  FluentAvatarSize.size24 => FluentPresenceBadgeSize.tiny,
  FluentAvatarSize.size28 ||
  FluentAvatarSize.size32 ||
  FluentAvatarSize.size36 => FluentPresenceBadgeSize.extraSmall,
  FluentAvatarSize.size40 => FluentPresenceBadgeSize.small,
  FluentAvatarSize.size48 ||
  FluentAvatarSize.size56 => FluentPresenceBadgeSize.medium,
  FluentAvatarSize.size64 ||
  FluentAvatarSize.size72 => FluentPresenceBadgeSize.large,
  FluentAvatarSize.size96 ||
  FluentAvatarSize.size120 => FluentPresenceBadgeSize.extraLarge,
};
