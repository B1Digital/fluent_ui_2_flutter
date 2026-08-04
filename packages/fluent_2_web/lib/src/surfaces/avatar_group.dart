import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'avatar.dart';
import 'avatar_group_style.dart';
import 'avatar_style.dart';

/// How the avatars in a group are arranged. Figma's `Layout` axis on
/// `Avatar/Avatar group`, plus the `Avatar/Avatar pie` set.
enum FluentAvatarGroupLayout {
  /// Laid out in a row with a positive gap. The default.
  spread,

  /// Overlapped, each avatar ringed so it still reads as separate.
  stack,

  /// Two or three avatars cut into one circle the size of a single avatar.
  pie,
}

/// Everything needed to render an avatar group, independent of size.
///
/// [layout] lives here rather than on [FluentAvatarGroupState] because it
/// decides the *structure*, not the styling — the same reason
/// `FluentButtonBaseState` carries `iconPosition`.
@immutable
class FluentAvatarGroupBaseState {
  /// Creates a base state.
  const FluentAvatarGroupBaseState({
    required this.layout,
    required this.children,
  });

  /// How the avatars are arranged.
  final FluentAvatarGroupLayout layout;

  /// The avatars, in reading order. The last one paints on top.
  final List<Widget> children;
}

/// An avatar group's fully resolved state, including the design axis.
@immutable
class FluentAvatarGroupState extends FluentAvatarGroupBaseState {
  /// Creates a resolved state.
  const FluentAvatarGroupState({
    required super.layout,
    required super.children,
    required this.size,
  });

  /// The edge length of one member.
  final FluentAvatarSize size;
}

/// Builds the state an avatar group will be styled and rendered from.
FluentAvatarGroupState resolveFluentAvatarGroupState({
  required List<Widget> children,
  FluentAvatarGroupLayout layout = FluentAvatarGroupLayout.spread,
  FluentAvatarSize size = FluentAvatarSize.size32,
}) => FluentAvatarGroupState(layout: layout, children: children, size: size);

/// Resolves the default style for [state] against [theme].
///
/// The spacing tables are Figma's `Avatar group size` collection verbatim, one
/// value per avatar size for each of `Spread` and `Stack`. Both disagree with
/// `useAvatarGroupItemStyles.styles.ts` in places and Figma wins; see
/// `doc/token-divergences.md`.
///
/// The stack **outline** has no counterpart in the design file at all — Figma
/// draws overlapping avatars with no separator — so it is upstream's
/// `boxShadow: 0 0 0 <width> colorNeutralBackground2` transcribed. Without it a
/// stacked group is an unreadable smear, which is the one case where silence in
/// Figma is read as an omission rather than a decision.
FluentAvatarGroupStyle resolveFluentAvatarGroupStyle(
  FluentAvatarGroupState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final edge = state.size.edge;

  final spacing = switch (state.layout) {
    FluentAvatarGroupLayout.spread => switch (state.size) {
      FluentAvatarSize.size16 => FluentSpacing.s,
      FluentAvatarSize.size20 ||
      FluentAvatarSize.size24 ||
      FluentAvatarSize.size28 => FluentSpacing.mNudge,
      FluentAvatarSize.size32 ||
      FluentAvatarSize.size36 ||
      FluentAvatarSize.size40 ||
      FluentAvatarSize.size48 ||
      FluentAvatarSize.size56 => FluentSpacing.m,
      FluentAvatarSize.size64 || FluentAvatarSize.size72 => FluentSpacing.l,
      FluentAvatarSize.size96 || FluentAvatarSize.size120 => FluentSpacing.xl,
    },
    FluentAvatarGroupLayout.stack => switch (state.size) {
      FluentAvatarSize.size16 || FluentAvatarSize.size20 => -FluentSpacing.xxs,
      FluentAvatarSize.size24 ||
      FluentAvatarSize.size28 ||
      FluentAvatarSize.size32 ||
      FluentAvatarSize.size36 ||
      FluentAvatarSize.size40 => -FluentSpacing.xs,
      FluentAvatarSize.size48 ||
      FluentAvatarSize.size56 ||
      FluentAvatarSize.size64 ||
      FluentAvatarSize.size72 => -FluentSpacing.s,
      FluentAvatarSize.size96 || FluentAvatarSize.size120 => -FluentSpacing.l,
    },
    // The pie is one avatar wide; its members do not sit beside each other.
    FluentAvatarGroupLayout.pie => 0.0,
  };

  // Upstream's stack/pie width ladder, shared by both because upstream shares
  // it: thick below 56, thicker below 72, thickest above.
  final outlineWidth = edge < 56
      ? FluentStroke.thick
      : edge < 72
      ? FluentStroke.thicker
      : FluentStroke.thickest;

  return FluentAvatarGroupStyle(
    spacing: WidgetStatePropertyAll<double?>(spacing),
    outlineColor: FluentStateColor.tokens(rest: c.neutralBackground2),
    outlineWidth: WidgetStatePropertyAll<double?>(
      state.layout == FluentAvatarGroupLayout.stack
          ? outlineWidth
          : FluentStroke.none,
    ),
    // Figma's `Divider` rectangle: `Neutral/Stroke/on Brand/1/Rest`, and 2 wide
    // at every one of the 26 pie variants. React ramps the width with size and
    // reveals `colorTransparentStroke` behind the slices instead.
    dividerColor: FluentStateColor.tokens(rest: c.neutralStrokeOnBrand),
    dividerWidth: WidgetStatePropertyAll<double?>(
      state.layout == FluentAvatarGroupLayout.pie
          ? FluentStroke.thick
          : FluentStroke.none,
    ),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allCircular,
    ),
    diameter: WidgetStatePropertyAll<double?>(edge),
  );
}

/// Renders an avatar group from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentAvatarGroupBaseState], so it never reads the size axis.
///
/// Spread and stack are the same layout with a different sign on the gap: a
/// row `n * diameter + (n - 1) * spacing` wide, later avatars painting over
/// earlier ones. The pie is its own thing — see [FluentAvatarPiePainter].
Widget buildFluentAvatarGroup(
  FluentAvatarGroupBaseState state,
  FluentAvatarGroupStyle style,
  Set<WidgetState> states,
) {
  final diameter = style.diameter?.resolve(states) ?? FluentSize.size320;
  final radius =
      style.borderRadius?.resolve(states) ?? FluentRadius.allCircular;

  if (state.layout == FluentAvatarGroupLayout.pie) {
    return _pie(state.children, style, states, diameter, radius);
  }

  final spacing = style.spacing?.resolve(states) ?? 0;
  final outlineColor = style.outlineColor?.resolve(states);
  final outlineWidth = style.outlineWidth?.resolve(states) ?? FluentStroke.none;
  final children = state.children;
  if (children.isEmpty) return SizedBox(height: diameter);

  return SizedBox(
    height: diameter,
    width: children.length * diameter + (children.length - 1) * spacing,
    child: Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (var i = 0; i < children.length; i++)
          Positioned(
            left: i * (diameter + spacing),
            top: 0,
            width: diameter,
            height: diameter,
            child: outlineWidth > 0 && outlineColor != null
                ? CustomPaint(
                    painter: FluentAvatarRingPainter(
                      borderRadius: radius,
                      color: outlineColor,
                      width: outlineWidth,
                    ),
                    child: children[i],
                  )
                : children[i],
          ),
      ],
    ),
  );
}

/// Two or three avatars cut into one circle.
///
/// The first member shows its own middle vertical half in the left half of the
/// circle; a third member splits the right half into two quadrants, each a
/// half-scale avatar. That is upstream's `clipPath`/`transform` geometry, which
/// Figma reproduces by resizing instances — a shortcut that squashes a circular
/// avatar into an ellipse, so the crop is taken from React and the numbers
/// (half, quadrant, 2px rules) from Figma.
Widget _pie(
  List<Widget> children,
  FluentAvatarGroupStyle style,
  Set<WidgetState> states,
  double diameter,
  BorderRadius radius,
) {
  final dividerColor = style.dividerColor?.resolve(states);
  final dividerWidth = style.dividerWidth?.resolve(states) ?? FluentStroke.none;
  final members = children.length > 3 ? children.sublist(0, 3) : children;
  final half = diameter / 2;
  final quarter = diameter / 4;

  Widget slice(Widget child) => ClipRect(
    clipper: const _MiddleHalf(),
    child: SizedBox.square(dimension: diameter, child: child),
  );

  return SizedBox.square(
    dimension: diameter,
    child: ClipRRect(
      borderRadius: radius,
      // Upstream's `pie: { borderRadius: '0' }` on the avatar slot. A pie
      // member has to be a rectangle: it is the group's own clip that makes the
      // circle, and a member that kept its own rounding would leave a bite out
      // of every slice. Applied as a subtree theme, so a member's explicit
      // `style` still wins — the same precedence every other override obeys.
      child: FluentAvatarTheme(
        style: FluentAvatarStyle.from(borderRadius: BorderRadius.zero),
        child: CustomPaint(
          foregroundPainter: FluentAvatarPiePainter(
            color: dividerColor,
            width: dividerWidth,
            quartered: members.length > 2,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              if (members.isNotEmpty)
                Positioned(
                  left: members.length == 1 ? 0 : -quarter,
                  top: 0,
                  width: diameter,
                  height: diameter,
                  child: members.length == 1
                      ? members.first
                      : slice(members.first),
                ),
              if (members.length == 2)
                Positioned(
                  left: quarter,
                  top: 0,
                  width: diameter,
                  height: diameter,
                  child: slice(members[1]),
                ),
              if (members.length > 2) ...<Widget>[
                Positioned(
                  left: half,
                  top: 0,
                  width: half,
                  height: half,
                  child: FittedBox(fit: BoxFit.fill, child: members[1]),
                ),
                Positioned(
                  left: half,
                  top: half,
                  width: half,
                  height: half,
                  child: FittedBox(fit: BoxFit.fill, child: members[2]),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Keeps the middle vertical half of a square child, which is the slice a pie
/// member contributes to the left or right half of the circle.
class _MiddleHalf extends CustomClipper<Rect> {
  const _MiddleHalf();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(size.width / 4, 0, size.width / 2, size.height);

  @override
  bool shouldReclip(_MiddleHalf oldClipper) => false;
}

/// Paints the rules between pie slices.
///
/// One vertical rule down the middle always; a horizontal one from the middle
/// to the right edge when there are three members. Both are [width] wide and
/// centred on the seam, exactly as Figma's `Divider` rectangles are — the
/// caller clips them to the circle.
class FluentAvatarPiePainter extends CustomPainter {
  /// Creates a painter for the given rule.
  const FluentAvatarPiePainter({
    required this.quartered,
    this.color,
    this.width = 0,
  });

  /// Whether the right half is split in two, i.e. there are three members.
  final bool quartered;

  /// Rule colour. Figma's `Neutral/Stroke/on Brand/1/Rest`.
  final Color? color;

  /// Rule width. Figma binds `Stroke width/Thick` on all 26 pie variants.
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final tone = color;
    if (tone == null || width <= 0) return;
    final paint = Paint()..color = tone;
    final x = size.width / 2;
    final y = size.height / 2;
    canvas.drawRect(Rect.fromLTWH(x - width / 2, 0, width, size.height), paint);
    if (quartered) {
      canvas.drawRect(
        Rect.fromLTWH(
          x - width / 2,
          y - width / 2,
          size.width / 2 + width / 2,
          width,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FluentAvatarPiePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.width != width ||
      oldDelegate.quartered != quartered;
}

/// Overrides the avatar group style for a subtree.
class FluentAvatarGroupTheme extends InheritedTheme {
  /// Applies [style] to every `FluentAvatarGroup` in [child].
  const FluentAvatarGroupTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the layout and size defaults.
  final FluentAvatarGroupStyle style;

  /// The nearest avatar group style, or null.
  static FluentAvatarGroupStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentAvatarGroupTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentAvatarGroupTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentAvatarGroupTheme(style: style, child: child);
}

/// A Fluent 2 avatar group: several people shown as one unit.
///
/// ```dart
/// FluentAvatarGroup(
///   layout: FluentAvatarGroupLayout.stack,
///   size: FluentAvatarSize.size32,
///   children: const <Widget>[
///     FluentAvatar(initials: 'AL'),
///     FluentAvatar(initials: 'GH'),
///     FluentAvatar(initials: 'KZ'),
///   ],
/// )
/// ```
///
/// [size] is *not* pushed down into the children — each `FluentAvatar` still
/// declares its own, because a group whose members disagree with it is a bug
/// worth seeing rather than one worth hiding. Give every child the same size
/// you give the group.
///
/// The overflow tile at the end of a long group is an ordinary
/// `FluentAvatar(color: FluentAvatarColor.overflow, initials: '+3')`; this
/// widget does no counting or truncation of its own.
class FluentAvatarGroup extends StatelessWidget {
  /// Creates a group of [children].
  const FluentAvatarGroup({
    super.key,
    required this.children,
    this.layout = FluentAvatarGroupLayout.spread,
    this.size = FluentAvatarSize.size32,
    this.style,
  });

  /// The avatars, in reading order. The pie layout reads the first three.
  final List<Widget> children;

  /// How the avatars are arranged.
  final FluentAvatarGroupLayout layout;

  /// The edge length every member is expected to use.
  final FluentAvatarSize size;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentAvatarGroupStyle? style;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentAvatarGroupState(
      children: children,
      layout: layout,
      size: size,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentAvatarGroupStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentAvatarGroupTheme.maybeOf(context)).merge(style);

    return Semantics(
      container: true,
      child: buildFluentAvatarGroup(state, resolved, const <WidgetState>{}),
    );
  }
}
