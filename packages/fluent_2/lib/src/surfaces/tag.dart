import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import '../l10n/l10n.dart';
import 'tag_style.dart';

/// How a tag is filled and outlined. Figma's `Style` axis, verbatim.
enum FluentTagAppearance {
  /// Neutral fill with an invisible border. The default.
  filled,

  /// Transparent fill with a visible border.
  outline,

  /// Brand-tinted fill.
  brand,
}

/// Tag height and type ramp. Figma's `Size` axis.
enum FluentTagSize {
  /// 20 high, caption type, 12px glyphs.
  extraSmall,

  /// 24 high, caption type, 16px glyphs.
  small,

  /// 32 high, body type, 20px glyphs. The default, and the only size that
  /// accepts a second line.
  medium,
}

/// Everything needed to resolve a tag's style, independent of the design axes.
///
/// The Dart counterpart of upstream's `TagBaseState`. [buildFluentTag] takes
/// this rather than [FluentTagState], which is what makes "Fluent's state, my
/// own styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentTagBaseState {
  /// Creates a base state.
  const FluentTagBaseState({
    required this.enabled,
    this.label,
    this.secondaryLabel,
    this.media,
    this.icon,
    this.dismiss,
  });

  /// Whether the tag reads as active. A tag has no press behaviour of its own,
  /// so this only greys the surface and disables the dismiss affordance.
  final bool enabled;

  /// The primary line.
  final Widget? label;

  /// The second line. Only the medium size has a two-line layout.
  final Widget? secondaryLabel;

  /// Leading media — an avatar. Upstream's `media` slot: 1px inside the
  /// border, with the content inset between it and the label.
  final Widget? media;

  /// Leading icon, at the content inset. Upstream's `icon` slot.
  final Widget? icon;

  /// The trailing dismiss affordance, already wrapped in its own interaction
  /// surface by the caller. Null on a tag that cannot be dismissed.
  final Widget? dismiss;
}

/// A tag's fully resolved state, including the design axes.
@immutable
class FluentTagState extends FluentTagBaseState {
  /// Creates a resolved state.
  const FluentTagState({
    required super.enabled,
    required this.appearance,
    required this.size,
    required this.selected,
    super.label,
    super.secondaryLabel,
    super.media,
    super.icon,
    super.dismiss,
  });

  /// Fill and outline treatment.
  final FluentTagAppearance appearance;

  /// Height and type ramp.
  final FluentTagSize size;

  /// Whether the tag is chosen.
  ///
  /// Selected is *not* a [WidgetState] here. Fluent's selected tag collapses
  /// all three appearances onto the same brand-filled treatment and has to beat
  /// hover and press, which the `WidgetState` precedence order (disabled,
  /// pressed, hovered, selected) would not let it do.
  final bool selected;
}

/// Builds the state a tag will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentTagState resolveFluentTagState({
  bool enabled = true,
  FluentTagAppearance appearance = FluentTagAppearance.filled,
  FluentTagSize size = FluentTagSize.medium,
  bool selected = false,
  Widget? label,
  Widget? secondaryLabel,
  Widget? media,
  Widget? icon,
  Widget? dismiss,
}) => FluentTagState(
  enabled: enabled,
  appearance: appearance,
  size: size,
  selected: selected,
  label: label,
  secondaryLabel: secondaryLabel,
  media: media,
  icon: icon,
  dismiss: dismiss,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour is an explicit Fluent token;
/// nothing here computes one.
///
/// Token sources are the Figma `Tag` component set (`9112:9115`, 60 variants),
/// extracted into `test/fixtures/tag.json` and asserted variant-by-variant.
///
/// The surface is deliberately flat across rest, hover and press: all 60 Figma
/// variants bind the same fill and the same label colour in those three states.
/// Only the dismiss glyph ramps — see [FluentTagStyle.dismissForegroundColor].
FluentTagStyle resolveFluentTagStyle(
  FluentTagState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  final background = state.selected
      // Selected erases the appearance: Filled, Outline and Brand all bind
      // `Brand/Background/1/Rest` in the Figma file.
      ? FluentStateColor.tokens(
          rest: c.brandBackground,
          disabled: c.neutralBackgroundDisabled,
        )
      : switch (state.appearance) {
          FluentTagAppearance.filled => FluentStateColor.tokens(
            rest: c.neutralBackground3,
            disabled: c.neutralBackgroundDisabled,
          ),
          FluentTagAppearance.brand => FluentStateColor.tokens(
            rest: c.brandBackground2,
            disabled: c.neutralBackgroundDisabled,
          ),
          // Outline paints no fill at all, in any state — not even the disabled
          // grey the Filled and Brand variants take.
          FluentTagAppearance.outline => FluentStateColor.tokens(
            rest: c.transparentBackground,
          ),
        };

  final foreground = state.selected
      ? FluentStateColor.tokens(
          rest: c.neutralForegroundOnBrand,
          disabled: c.neutralForegroundDisabled,
        )
      : switch (state.appearance) {
          FluentTagAppearance.filled ||
          FluentTagAppearance.outline => FluentStateColor.tokens(
            rest: c.neutralForeground2,
            disabled: c.neutralForegroundDisabled,
          ),
          FluentTagAppearance.brand => FluentStateColor.tokens(
            rest: c.brandForeground2,
            disabled: c.neutralForegroundDisabled,
          ),
        };

  // The one ramped property. A tag is inert, so the Figma `State` axis
  // describes hovering the DISMISS glyph — which is why the fill and the label
  // hold still while this goes brand.
  //
  // React wins over Figma here: `useTagStyles.styles.ts` (useDismissIconStyles)
  // writes `colorCompoundBrandForeground1Hover` / `Pressed` for all three
  // appearances, and the storybook's tag--dismiss reads #115EA3 / #0F548C.
  // Figma binds `Neutral/Foreground/2/Brand/Hover` (#0F6CBD / #115EA3).
  final dismissForeground = state.selected
      ? FluentStateColor.tokens(
          rest: c.neutralForegroundOnBrand,
          disabled: c.neutralForegroundDisabled,
        )
      : FluentStateColor.tokens(
          rest: state.appearance == FluentTagAppearance.brand
              ? c.brandForeground2
              : c.neutralForeground2,
          hover: c.compoundBrandForeground1Hover,
          pressed: c.compoundBrandForeground1Pressed,
          disabled: c.neutralForegroundDisabled,
        );

  final border =
      state.appearance == FluentTagAppearance.outline && !state.selected
      ? FluentStateColor.tokens(
          rest: c.neutralStroke1,
          disabled: c.neutralStrokeDisabled,
        )
      // Invisible in light and dark, opaque in high contrast — which is the
      // only thing outlining a filled tag there. Never Colors.transparent.
      : FluentStateColor.tokens(rest: c.transparentStroke);

  final (padding, gap, iconSize, height, text) = fluentTagGeometry(
    state.size,
    theme,
    twoLine: state.secondaryLabel != null,
  );

  return FluentTagStyle(
    backgroundColor: background,
    foregroundColor: foreground,
    dismissForegroundColor: dismissForeground,
    borderColor: border,
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(text),
    secondaryTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.caption2,
    ),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(padding),
    gap: WidgetStatePropertyAll<double?>(gap),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.basic,
    ),
  );
}

/// The geometry ramp both tag components share, verbatim from Figma: content
/// padding, item gap, glyph size, height, and the primary type step.
///
/// Public because `FluentInteractionTag` resolves against the same numbers, and
/// because a consumer replacing [resolveFluentTagStyle] should not have to
/// re-transcribe them.
///
/// The second line is always `caption2` (10/14), so only the *primary* step
/// moves — and a two-line medium tag drops its primary from `body1` to
/// `caption1` so the pair still fits the same 32.
(EdgeInsets, double, double, double, TextStyle) fluentTagGeometry(
  FluentTagSize size,
  FluentThemeData theme, {
  bool twoLine = false,
}) => switch (size) {
  FluentTagSize.extraSmall => (
    const EdgeInsets.symmetric(horizontal: FluentSpacing.sNudge),
    FluentSpacing.xxs,
    FluentSize.size120,
    20.0,
    theme.typography.caption1,
  ),
  FluentTagSize.small => (
    const EdgeInsets.symmetric(horizontal: FluentSpacing.sNudge),
    FluentSpacing.xxs,
    FluentSize.size160,
    24.0,
    theme.typography.caption1,
  ),
  FluentTagSize.medium => (
    const EdgeInsets.symmetric(horizontal: FluentSpacing.s),
    FluentSpacing.xs,
    FluentSize.size200,
    32.0,
    twoLine ? theme.typography.caption1 : theme.typography.body1,
  ),
};

/// Renders a tag from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentTagBaseState] rather than [FluentTagState] on purpose: it never reads
/// appearance, size or selected, so a consumer can supply their own style and
/// still use Fluent's rendering.
///
/// [states] is the surface's own state set — `{}` or `{disabled}` for a plain
/// tag, and the live set from [FluentInteractive] for an interaction tag's
/// pressable half. [borderRadius] overrides the style's, which is how an
/// interaction tag's halves each round one end only.
Widget buildFluentTag(
  FluentTagBaseState state,
  FluentTagStyle style,
  Set<WidgetState> states, {
  BorderRadius? borderRadius,
}) {
  final radius =
      borderRadius ??
      style.borderRadius?.resolve(states) ??
      FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xxs;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  final textStyle = style.textStyle?.resolve(states);
  final secondaryTextStyle = style.secondaryTextStyle?.resolve(states);

  Widget line(Widget child, TextStyle? lineStyle) => DefaultTextStyle.merge(
    style: (lineStyle ?? const TextStyle()).copyWith(color: foreground),
    child: child,
  );

  final content = Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (state.label != null) line(state.label!, textStyle),
      if (state.secondaryLabel != null)
        line(state.secondaryLabel!, secondaryTextStyle),
    ],
  );

  Widget body = Padding(
    padding: padding,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: gap,
      children: <Widget>[
        if (state.icon != null)
          IconTheme.merge(
            data: IconThemeData(
              color: style.iconColor?.resolve(states) ?? foreground,
              size: iconSize,
            ),
            child: state.icon!,
          ),
        // Upstream pads the text slot `0 XXS XXS`: the bottom 2px lifts a
        // single line 1px off centre (Chrome). A second line drops it.
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: FluentSpacing.xxs,
            end: FluentSpacing.xxs,
            bottom: state.secondaryLabel == null ? FluentSpacing.xxs : 0,
          ),
          child: content,
        ),
        if (state.dismiss != null) state.dismiss!,
      ],
    ),
  );

  // Upstream's media slot is `padding: 0 S 0 1px` (SNudge below medium) in
  // place of the root's start padding: the avatar sits 1px inside the border,
  // and the content inset lands between it and the label instead.
  if (state.media != null) {
    body = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: FluentSpacing.xxs),
          child: IconTheme.merge(
            data: IconThemeData(color: foreground, size: iconSize),
            child: state.media!,
          ),
        ),
        body,
      ],
    );
  }

  return ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: minimumSize.height,
      minWidth: minimumSize.width,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: style.backgroundColor?.resolve(states),
        borderRadius: radius,
        // Uniform on purpose: Flutter refuses to paint a rounded rect whose
        // sides disagree, so an interaction tag's one-edge divider is a
        // separate square-cornered overlay rather than a fourth border side.
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: body,
    ),
  );
}

/// Overrides the tag style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentTagTheme extends InheritedTheme {
  /// Applies [style] to every [FluentTag] in [child].
  const FluentTagTheme({super.key, required this.style, required super.child});

  /// The style layered over the appearance and size defaults.
  final FluentTagStyle style;

  /// The nearest tag style, or null.
  static FluentTagStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentTagTheme>()?.style;

  @override
  bool updateShouldNotify(FluentTagTheme oldWidget) => style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentTagTheme(style: style, child: child);
}

/// Fluent's dismiss glyph, drawn rather than imported.
///
/// Painted from upstream's own `DismissRegular` path by
/// [FluentTagDismissPainter], so the ink matches the React tag's at every size.
///
/// Takes its colour and its box from the ambient [IconTheme], exactly as an
/// `Icon` would, so passing a real Fluent `Dismiss` icon instead changes
/// nothing else.
class FluentTagDismissGlyph extends StatelessWidget {
  /// Creates a dismiss glyph.
  const FluentTagDismissGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    final size = icon.size ?? FluentSize.size200;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: FluentTagDismissPainter(
          color: icon.color ?? const Color(0xFF000000),
        ),
      ),
    );
  }
}

/// Paints [FluentTagDismissGlyph]'s cross.
///
/// Upstream's own glyph, `DismissRegular` from `@fluentui/react-icons`: its
/// 20-unit path, transcribed command for command and scaled to the box, as the
/// browser scales the `1em` svg — 7.5 of ink in a 12 box, 10 in 16, 12 in 20.
class FluentTagDismissPainter extends CustomPainter {
  /// Creates a painter for the given tone.
  const FluentTagDismissPainter({required this.color});

  /// The fill colour. Never derived — it comes from a Fluent token.
  final Color color;

  static final Path _dismissRegular = Path()
    ..moveTo(4.09, 4.22)
    ..relativeLineTo(0.06, -0.07)
    ..relativeArcToPoint(const Offset(0.63, -0.06), radius: _r)
    ..relativeLineTo(0.07, 0.06)
    ..lineTo(10, 9.29)
    ..relativeLineTo(5.15, -5.14)
    ..relativeArcToPoint(const Offset(0.63, -0.06), radius: _r)
    ..relativeLineTo(0.07, 0.06)
    ..relativeCubicTo(0.18, 0.17, 0.2, 0.44, 0.06, 0.63)
    ..relativeLineTo(-0.06, 0.07)
    ..lineTo(10.71, 10)
    ..relativeLineTo(5.14, 5.15)
    ..relativeCubicTo(0.18, 0.17, 0.2, 0.44, 0.06, 0.63)
    ..relativeLineTo(-0.06, 0.07)
    ..relativeArcToPoint(const Offset(-0.63, 0.06), radius: _r)
    ..relativeLineTo(-0.07, -0.06)
    ..lineTo(10, 10.71)
    ..relativeLineTo(-5.15, 5.14)
    ..relativeArcToPoint(const Offset(-0.63, 0.06), radius: _r)
    ..relativeLineTo(-0.07, -0.06)
    ..relativeArcToPoint(const Offset(-0.06, -0.63), radius: _r)
    ..relativeLineTo(0.06, -0.07)
    ..lineTo(9.29, 10)
    ..lineTo(4.15, 4.85)
    ..relativeArcToPoint(const Offset(-0.06, -0.63), radius: _r)
    ..relativeLineTo(0.06, -0.07)
    ..relativeLineTo(-0.06, 0.07)
    ..close();

  static const Radius _r = Radius.circular(0.5);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 20;
    canvas
      ..save()
      ..translate(
        (size.width - size.shortestSide) / 2,
        (size.height - size.shortestSide) / 2,
      )
      ..scale(scale)
      ..drawPath(_dismissRegular, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(FluentTagDismissPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A Fluent 2 tag.
///
/// ```dart
/// FluentTag(
///   appearance: FluentTagAppearance.brand,
///   onDismiss: () => remove(item),
///   child: const Text('Design'),
/// )
/// ```
///
/// A tag is **inert**: it labels something, it does not act. Its surface holds
/// still under the pointer, which is why there is no `onPressed` here — reach
/// for `FluentInteractionTag` when the tag itself is a control.
///
/// The one interactive part is the optional dismiss glyph. Supplying
/// [onDismiss] adds it, gives it its own focus ring and keyboard activation,
/// and lets it take brand colour on hover — the whole of the Figma set's
/// `State` axis.
///
/// Customisation follows the same three rungs as every other component in this
/// package: [style] is merged last and wins, [FluentTagTheme] restyles a
/// subtree, and [resolveFluentTagState], [resolveFluentTagStyle] and
/// [buildFluentTag] are public so any one of them can be replaced.
class FluentTag extends StatelessWidget {
  /// Creates a tag labelled [child].
  const FluentTag({
    super.key,
    required this.child,
    this.secondaryChild,
    this.media,
    this.icon,
    this.appearance = FluentTagAppearance.filled,
    this.size = FluentTagSize.medium,
    this.selected = false,
    this.enabled = true,
    this.onDismiss,
    this.dismissIcon,
    this.dismissSemanticLabel,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The primary line.
  final Widget child;

  /// The second line. Figma only draws two lines at [FluentTagSize.medium].
  final Widget? secondaryChild;

  /// Leading media — an avatar, 1px inside the border with the content inset
  /// after it. Upstream's `media` slot.
  final Widget? media;

  /// Leading icon, at the content inset. Upstream's `icon` slot.
  final Widget? icon;

  /// Fill and outline treatment.
  final FluentTagAppearance appearance;

  /// Height and type ramp.
  final FluentTagSize size;

  /// Whether the tag is chosen. Selected overrides [appearance]: all three
  /// render as a brand-filled tag.
  final bool selected;

  /// Whether the tag reads as active.
  final bool enabled;

  /// Invoked when the dismiss glyph is activated. Null omits the glyph.
  final VoidCallback? onDismiss;

  /// Replaces the built-in [FluentTagDismissGlyph].
  final Widget? dismissIcon;

  /// Announced for the dismiss affordance, which has no text of its own.
  ///
  /// Null takes the wording from the ambient [FluentLocalizations],
  /// which falls back to English when no delegate is installed.
  final String? dismissSemanticLabel;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentTagStyle? style;

  /// Focus node for the dismiss affordance. One is created internally when
  /// omitted.
  final FocusNode? focusNode;

  /// Whether the dismiss affordance takes focus on mount.
  final bool autofocus;

  /// Announced by assistive technology in place of the label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentTagStyle(
      resolveFluentTagState(
        enabled: enabled,
        appearance: appearance,
        size: size,
        selected: selected,
        label: child,
        secondaryLabel: secondaryChild,
        media: media,
        icon: icon,
      ),
      FluentTheme.of(context),
    ).merge(FluentTagTheme.maybeOf(context)).merge(style);

    // The surface never sees hover or press: a tag is inert, so its only live
    // state is whether it is disabled.
    final states = <WidgetState>{if (!enabled) WidgetState.disabled};
    final iconSize = resolved.iconSize?.resolve(states) ?? FluentSize.size200;

    final state = FluentTagBaseState(
      enabled: enabled,
      label: child,
      secondaryLabel: secondaryChild,
      media: media,
      icon: icon,
      dismiss: onDismiss == null
          ? null
          : FluentInteractive(
              onPressed: onDismiss,
              enabled: enabled,
              focusNode: focusNode,
              autofocus: autofocus,
              builder: (context, dismissStates, _) => Semantics(
                button: true,
                enabled: enabled,
                label: dismissSemanticLabel ?? fluentL10n(context).dismiss,
                child: FluentFocusRing(
                  visible: dismissStates.contains(WidgetState.focused),
                  borderRadius: FluentRadius.allSmall,
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: resolved.dismissForegroundColor?.resolve(
                        dismissStates,
                      ),
                      size: iconSize,
                    ),
                    child: dismissIcon ?? const FluentTagDismissGlyph(),
                  ),
                ),
              ),
            ),
    );

    return Semantics(
      container: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel,
      child: buildFluentTag(state, resolved, states),
    );
  }
}
