import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'avatar.dart';
import 'persona_style.dart';
import 'presence_badge.dart';

/// Persona size. Figma's `Size` axis, widened to upstream's six-step ramp.
///
/// The Figma `Persona` set draws only three of these — `Small (Badge only)`,
/// `Medium` and `Large` — but the two variable collections it pins,
/// `Persona avatar size` (6 modes) and `Persona badge size` (5), state the
/// whole ramp, and they line up with upstream's `PersonaProps['size']` value
/// for value. The three drawn variants are [extraSmall], [medium] and
/// [extraLarge] respectively; `test/fixtures/persona.json` is asserted against
/// exactly those three.
///
/// The number attached to each step is the **avatar** edge, which is what makes
/// the mapping checkable: Figma's mode names are the pixel sizes themselves.
enum FluentPersonaSize {
  /// 20 avatar, 6 presence badge. Figma's `Small (Badge only)`.
  extraSmall(FluentAvatarSize.size20, FluentPresenceBadgeSize.tiny),

  /// 28 avatar, 10 presence badge.
  small(FluentAvatarSize.size28, FluentPresenceBadgeSize.extraSmall),

  /// 32 avatar, 12 presence badge. Figma's `Medium`, and the default.
  medium(FluentAvatarSize.size32, FluentPresenceBadgeSize.small),

  /// 36 avatar, 16 presence badge.
  large(FluentAvatarSize.size36, FluentPresenceBadgeSize.medium),

  /// 40 avatar, 20 presence badge. Figma's `Large`.
  extraLarge(FluentAvatarSize.size40, FluentPresenceBadgeSize.large),

  /// 56 avatar, 20 presence badge — the badge ramp stops before the avatar's
  /// does, so [extraLarge] and [huge] share a badge.
  huge(FluentAvatarSize.size56, FluentPresenceBadgeSize.large);

  const FluentPersonaSize(this.avatarSize, this.presenceSize);

  /// The [FluentAvatar] size this step composes. Not a copy of the avatar's own
  /// token table — the ramp is picked here and handed to the real component.
  final FluentAvatarSize avatarSize;

  /// The [FluentPresenceBadge] size this step composes when the persona shows a
  /// badge instead of an avatar.
  final FluentPresenceBadgeSize presenceSize;
}

/// Where the text block sits relative to the avatar. Figma's `Layout` axis.
enum FluentPersonaTextPosition {
  /// Text after the avatar in reading order. The default.
  after,

  /// Text before the avatar in reading order.
  before,

  /// Text under the avatar, both centred.
  below,
}

/// How the avatar lines up with the text. Figma's `Alignment` axis.
enum FluentPersonaTextAlignment {
  /// Avatar centred against the whole text block. Figma's `Center`, and the
  /// default — upstream defaults to [start] instead.
  center,

  /// Avatar aligned to the top of the text block. Figma's `Top`.
  ///
  /// A presence badge is the exception: it centres on the *first line* rather
  /// than sitting at the very top, which is what Figma's `Presence container`
  /// inset and upstream's `alignToPrimary` both produce.
  start,
}

/// Everything needed to render a persona, independent of size.
///
/// The counterpart of upstream's `PersonaBaseState`. The composed avatar or
/// presence badge is already built here rather than in the style, because which
/// component appears and how large it is are content decisions — see
/// [resolveFluentPersonaState].
@immutable
class FluentPersonaBaseState {
  /// Creates a base state.
  const FluentPersonaBaseState({
    required this.textPosition,
    required this.textAlignment,
    required this.alignMediaToPrimaryLine,
    required this.textLineCount,
    this.media,
    this.primary,
    this.secondary,
    this.tertiary,
    this.quaternary,
  });

  /// Where the text sits relative to [media].
  final FluentPersonaTextPosition textPosition;

  /// How [media] lines up with the text.
  final FluentPersonaTextAlignment textAlignment;

  /// Whether [media] centres on the first text line under
  /// [FluentPersonaTextAlignment.start] instead of sitting flush with its top.
  /// True for a presence badge, false for an avatar.
  final bool alignMediaToPrimaryLine;

  /// How many of the four text slots are filled. Upstream's `numTextLines`, and
  /// read by [resolveFluentPersonaStyle] for exactly one rule.
  final int textLineCount;

  /// The composed `FluentAvatar` or `FluentPresenceBadge`.
  final Widget? media;

  /// The first and largest line. Usually the person's name.
  final Widget? primary;

  /// The second line.
  final Widget? secondary;

  /// The third line.
  final Widget? tertiary;

  /// The fourth line.
  final Widget? quaternary;
}

/// A persona's fully resolved state, including the design axes.
@immutable
class FluentPersonaState extends FluentPersonaBaseState {
  /// Creates a resolved state.
  const FluentPersonaState({
    required super.textPosition,
    required super.textAlignment,
    required super.alignMediaToPrimaryLine,
    required super.textLineCount,
    required this.size,
    required this.presenceOnly,
    super.media,
    super.primary,
    super.secondary,
    super.tertiary,
    super.quaternary,
  });

  /// Avatar, badge and type ramp step.
  final FluentPersonaSize size;

  /// Whether a presence badge replaces the avatar. Figma's
  /// `Style=Presence badge`.
  final bool presenceOnly;
}

/// Builds the state a persona will be styled and rendered from.
///
/// The first of the three-function recomposition contract, and the one that
/// composes: it builds a real [FluentAvatar] — or, with [presenceOnly], a real
/// [FluentPresenceBadge] — at the size [size] names, and hands it on as opaque
/// content. Neither component's token table is duplicated anywhere in this
/// file; the `Size` axis only *chooses* a [FluentAvatarSize] or a
/// [FluentPresenceBadgeSize].
///
/// [primary] defaults to [name] rendered as text, matching upstream. [name] is
/// deliberately *not* also handed to the composed avatar as a semantic label:
/// the primary line already carries it, and doing both makes a screen reader
/// announce the person twice.
FluentPersonaState resolveFluentPersonaState({
  String? name,
  Widget? primary,
  Widget? secondary,
  Widget? tertiary,
  Widget? quaternary,
  bool presenceOnly = false,
  FluentPersonaSize size = FluentPersonaSize.medium,
  FluentPersonaTextPosition textPosition = FluentPersonaTextPosition.after,
  FluentPersonaTextAlignment textAlignment = FluentPersonaTextAlignment.center,
  ImageProvider<Object>? image,
  String? initials,
  Widget? icon,
  FluentAvatarColor color = FluentAvatarColor.neutral,
  FluentAvatarShape shape = FluentAvatarShape.circular,
  FluentAvatarActive active = FluentAvatarActive.unset,
  FluentPresenceStatus? status,
  bool outOfOffice = false,
}) {
  final firstLine = primary ?? (name == null ? null : Text(name));
  final media = presenceOnly
      ? (status == null
            ? null
            : FluentPresenceBadge(
                status: status,
                outOfOffice: outOfOffice,
                size: size.presenceSize,
              ))
      : FluentAvatar(
          image: image,
          initials: initials,
          icon: icon,
          color: color,
          size: size.avatarSize,
          shape: shape,
          active: active,
          status: status,
          outOfOffice: outOfOffice,
        );

  return FluentPersonaState(
    size: size,
    presenceOnly: presenceOnly,
    textPosition: textPosition,
    textAlignment: textAlignment,
    alignMediaToPrimaryLine: presenceOnly,
    textLineCount: <Widget?>[
      firstLine,
      secondary,
      tertiary,
      quaternary,
    ].whereType<Widget>().length,
    media: media,
    primary: firstLine,
    secondary: secondary,
    tertiary: tertiary,
    quaternary: quaternary,
  );
}

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes.
///
/// Four things here are worth reading rather than skimming:
///
/// * the **gap** table is shared by the avatar and the badge. Upstream keeps
///   two, overriding only `small`; Figma's `Persona avatar size` collection
///   puts the 28 avatar on `SNudge` where upstream puts it on `S`, which
///   collapses the two tables into one.
/// * the **second line** steps up to `body1` at [FluentPersonaSize.extraLarge],
///   not just at [FluentPersonaSize.huge] as upstream has it.
/// * the **content padding** is `Spacing/Vertical/XXS` only when there *is* a
///   second line. Figma's single-line variant carries no `Content` wrapper at
///   all, so it states no inset.
/// * the **line overlap** is a real −2, from Figma's `itemSpacing: -2` and
///   upstream's `marginTop: -2px`. It is not a Figma text-box compensation; both
///   renderers ask for it.
FluentPersonaStyle resolveFluentPersonaStyle(
  FluentPersonaState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final t = theme.typography;

  // Upstream's one conditional ramp: an extra-small presence-only persona with
  // nothing but a name drops to caption1. Figma's `Small (Badge only)` variant
  // is exactly that case and agrees.
  final captionPrimary =
      state.size == FluentPersonaSize.extraSmall &&
      state.presenceOnly &&
      state.textLineCount <= 1;

  final primaryText = captionPrimary
      ? t.caption1
      : switch (state.size) {
          FluentPersonaSize.extraLarge || FluentPersonaSize.huge => t.subtitle2,
          _ => t.body1,
        };

  final secondaryText = switch (state.size) {
    FluentPersonaSize.extraLarge || FluentPersonaSize.huge => t.body1,
    _ => t.caption1,
  };

  final gap = switch (state.size) {
    FluentPersonaSize.extraSmall ||
    FluentPersonaSize.small => FluentSpacing.sNudge,
    FluentPersonaSize.medium => FluentSpacing.s,
    FluentPersonaSize.large ||
    FluentPersonaSize.extraLarge => FluentSpacing.mNudge,
    FluentPersonaSize.huge => FluentSpacing.m,
  };

  final hasSubtext =
      state.secondary != null ||
      state.tertiary != null ||
      state.quaternary != null;

  return FluentPersonaStyle(
    primaryTextStyle: WidgetStatePropertyAll<TextStyle?>(primaryText),
    secondaryTextStyle: WidgetStatePropertyAll<TextStyle?>(secondaryText),
    primaryColor: FluentStateColor.tokens(rest: c.neutralForeground1),
    secondaryColor: FluentStateColor.tokens(rest: c.neutralForeground2),
    gap: WidgetStatePropertyAll<double?>(gap),
    contentPadding: WidgetStatePropertyAll<EdgeInsets?>(
      hasSubtext
          ? const EdgeInsets.symmetric(vertical: FluentSpacing.xxs)
          : EdgeInsets.zero,
    ),
    lineOverlap: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
  );
}

/// Renders a persona from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentPersonaBaseState] rather than [FluentPersonaState] on purpose: it
/// never reads the size or the presence-only flag, so a consumer can supply
/// their own style and still get Fluent's layout, line overlap and badge
/// alignment.
///
/// There is **no transition** here. `usePersonaStyles.styles.ts` declares no
/// `transition`, no `animation` and no `motionTokens` reference at all, and the
/// Figma set has no `State` axis — so a persona lands on the frame and there is
/// nothing for `MediaQuery.disableAnimations` to shorten.
Widget buildFluentPersona(
  FluentPersonaBaseState state,
  FluentPersonaStyle style,
  Set<WidgetState> states,
) {
  final primaryTextStyle = style.primaryTextStyle?.resolve(states);
  final secondaryTextStyle = style.secondaryTextStyle?.resolve(states);
  final primaryColor = style.primaryColor?.resolve(states);
  final secondaryColor = style.secondaryColor?.resolve(states);
  final gap = style.gap?.resolve(states) ?? FluentSpacing.s;
  final padding = style.contentPadding?.resolve(states) ?? EdgeInsets.zero;
  final overlap = style.lineOverlap?.resolve(states) ?? 0;

  final below = state.textPosition == FluentPersonaTextPosition.below;
  // Figma's `Content` and `Subtext` frames are counter-axis MIN in every
  // horizontal variant and CENTER in the two stacked ones.
  final cross = below ? CrossAxisAlignment.center : CrossAxisAlignment.start;

  final subtext = <Widget>[
    if (state.secondary != null) state.secondary!,
    if (state.tertiary != null) state.tertiary!,
    if (state.quaternary != null) state.quaternary!,
  ];

  final lines = <Widget>[
    if (state.primary != null)
      DefaultTextStyle.merge(
        style: (primaryTextStyle ?? const TextStyle()).copyWith(
          color: primaryColor,
        ),
        child: state.primary!,
      ),
    if (subtext.isNotEmpty)
      _LineOverlap(
        // The overlap describes the seam between the first line and the rest.
        // With no first line there is no seam.
        overlap: state.primary == null ? 0 : overlap,
        child: DefaultTextStyle.merge(
          style: (secondaryTextStyle ?? const TextStyle()).copyWith(
            color: secondaryColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: cross,
            children: subtext,
          ),
        ),
      ),
  ];

  final content = lines.isEmpty
      ? null
      : Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: cross,
            children: lines,
          ),
        );

  var media = state.media;
  if (media != null &&
      state.alignMediaToPrimaryLine &&
      state.textAlignment == FluentPersonaTextAlignment.start &&
      !below) {
    // Figma wraps the badge in a `Presence container` whose vertical inset is
    // exactly what centres it inside the first line's box, top padding
    // included: 5 around a 12 badge under a 20 line, 2 around a 20 badge under
    // a 22 one, and nothing at all around a 6 badge that has no wrapper to be
    // inset from. Expressing it as the box rather than the inset reproduces all
    // five of the collection's stops without restating them.
    final lineHeight =
        (primaryTextStyle?.fontSize ?? 0) * (primaryTextStyle?.height ?? 1);
    media = SizedBox(
      height: padding.top + lineHeight,
      child: Center(child: media),
    );
  }

  final children = <Widget>[?media, ?content];
  final ordered = state.textPosition == FluentPersonaTextPosition.before
      ? children.reversed.toList()
      : children;

  if (below) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: gap,
      children: ordered,
    );
  }

  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: state.textAlignment == FluentPersonaTextAlignment.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    spacing: gap,
    children: ordered,
  );
}

/// Lifts its child by [overlap] and reports a box that much shorter.
///
/// Flutter refuses both halves of the obvious spelling — `Flex.spacing` asserts
/// non-negative and so does `RenderPadding` — and `Transform.translate` moves
/// the pixels without moving the layout, which would leave every persona two
/// logical pixels too tall. Thirty lines of render object is the honest way to
/// say "negative margin".
class _LineOverlap extends SingleChildRenderObjectWidget {
  const _LineOverlap({required this.overlap, required super.child});

  final double overlap;

  @override
  _RenderLineOverlap createRenderObject(BuildContext context) =>
      _RenderLineOverlap(overlap);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLineOverlap renderObject,
  ) {
    renderObject.overlap = overlap;
  }
}

class _RenderLineOverlap extends RenderShiftedBox {
  _RenderLineOverlap(this._overlap) : super(null);

  double _overlap;

  double get overlap => _overlap;

  set overlap(double value) {
    if (value == _overlap) return;
    _overlap = value;
    markNeedsLayout();
  }

  Size _shrink(Size child) =>
      Size(child.width, math.max(0, child.height - _overlap));

  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(0, (child?.getMinIntrinsicHeight(width) ?? 0) - _overlap);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(0, (child?.getMaxIntrinsicHeight(width) ?? 0) - _overlap);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return constraints.constrain(_shrink(child.getDryLayout(constraints)));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    (child.parentData! as BoxParentData).offset = Offset(0, -_overlap);
    size = constraints.constrain(_shrink(child.size));
  }
}

/// Overrides the persona style for a subtree.
///
/// Only the persona's own layout and type ramp: the composed avatar and badge
/// keep answering to `FluentAvatarTheme` and `FluentPresenceBadgeTheme`, which
/// is the point of composing them rather than reimplementing them.
class FluentPersonaTheme extends InheritedTheme {
  /// Applies [style] to every `FluentPersona` in [child].
  const FluentPersonaTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size defaults.
  final FluentPersonaStyle style;

  /// The nearest persona style, or null.
  static FluentPersonaStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentPersonaTheme>()?.style;

  @override
  bool updateShouldNotify(FluentPersonaTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentPersonaTheme(style: style, child: child);
}

/// A Fluent 2 persona: a [FluentAvatar] — or a [FluentPresenceBadge] — beside
/// up to four lines of text.
///
/// ```dart
/// FluentPersona(
///   name: 'Ada Lovelace',
///   initials: 'AL',
///   secondary: const Text('Available'),
///   status: FluentPresenceStatus.available,
///   size: FluentPersonaSize.extraLarge,
/// )
/// ```
///
/// The avatar is a real [FluentAvatar] and the badge a real
/// [FluentPresenceBadge]; [image], [initials], [icon], [color], [shape],
/// [active], [status] and [outOfOffice] are handed straight to whichever one is
/// showing. Only the **size** is decided here, from [FluentPersonaSize] — which
/// is why there is no avatar token table in this file to drift from the real
/// one.
///
/// Non-interactive, like the two components it composes. The Figma `Persona`
/// set has no `State` axis and upstream ships no hover, pressed, focus or
/// disabled rule, so there is no `onPressed` here and no state to disable: wrap
/// it in the control that owns the interaction instead.
///
/// Customisation follows the usual three rungs: [style] is merged last and
/// wins, [FluentPersonaTheme] restyles a subtree, and
/// [resolveFluentPersonaState], [resolveFluentPersonaStyle] and
/// [buildFluentPersona] are public for anything further.
class FluentPersona extends StatelessWidget {
  /// Creates a persona.
  const FluentPersona({
    super.key,
    this.name,
    this.primary,
    this.secondary,
    this.tertiary,
    this.quaternary,
    this.presenceOnly = false,
    this.size = FluentPersonaSize.medium,
    this.textPosition = FluentPersonaTextPosition.after,
    this.textAlignment = FluentPersonaTextAlignment.center,
    this.image,
    this.initials,
    this.icon,
    this.color = FluentAvatarColor.neutral,
    this.shape = FluentAvatarShape.circular,
    this.active = FluentAvatarActive.unset,
    this.status,
    this.outOfOffice = false,
    this.style,
  });

  /// The person's name, used as the default [primary] line.
  final String? name;

  /// The first and largest line. Defaults to [name] as plain text.
  final Widget? primary;

  /// The second line.
  final Widget? secondary;

  /// The third line.
  final Widget? tertiary;

  /// The fourth line.
  final Widget? quaternary;

  /// Shows a [FluentPresenceBadge] *instead of* the avatar. Figma's
  /// `Style=Presence badge`. Nothing is drawn unless [status] is also set.
  final bool presenceOnly;

  /// Avatar, badge and type ramp step.
  final FluentPersonaSize size;

  /// Where the text sits relative to the avatar.
  final FluentPersonaTextPosition textPosition;

  /// How the avatar lines up with the text.
  final FluentPersonaTextAlignment textAlignment;

  /// Photo for the composed [FluentAvatar].
  final ImageProvider<Object>? image;

  /// Initials for the composed [FluentAvatar].
  final String? initials;

  /// Replaces the composed [FluentAvatar]'s default `person` glyph.
  final Widget? icon;

  /// Which `Avatar color` mode the composed [FluentAvatar] paints in.
  final FluentAvatarColor color;

  /// Corner treatment of the composed [FluentAvatar].
  final FluentAvatarShape shape;

  /// Whether the composed [FluentAvatar] draws its activity ring.
  ///
  /// The ring paints *outside* the avatar's box, so it will overlap the text
  /// unless the persona is given room.
  final FluentAvatarActive active;

  /// The person's availability.
  ///
  /// With [presenceOnly] false this becomes the avatar's corner badge; with it
  /// true the badge replaces the avatar entirely.
  final FluentPresenceStatus? status;

  /// Whether the person is out of office. Only read when [status] is set.
  final bool outOfOffice;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentPersonaStyle? style;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentPersonaState(
      name: name,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      quaternary: quaternary,
      presenceOnly: presenceOnly,
      size: size,
      textPosition: textPosition,
      textAlignment: textAlignment,
      image: image,
      initials: initials,
      icon: icon,
      color: color,
      shape: shape,
      active: active,
      status: status,
      outOfOffice: outOfOffice,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentPersonaStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentPersonaTheme.maybeOf(context)).merge(style);

    // One node, not four plus a badge: a persona is a single unit of meaning,
    // and reading "Ada Lovelace", "Available" as separate stops is two swipes
    // for one row.
    return MergeSemantics(
      child: buildFluentPersona(state, resolved, const <WidgetState>{}),
    );
  }
}
