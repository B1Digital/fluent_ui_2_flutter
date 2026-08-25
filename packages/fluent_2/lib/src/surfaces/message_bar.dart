import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../buttons/button.dart';
import '../buttons/button_style.dart';
import '../internal/interaction.dart';
import '../l10n/l10n.dart';
import 'message_bar_style.dart';

/// What the message is about. Figma's `MessageBar status` variable collection.
///
/// The one axis that is **not** a variant property: the Figma component set has
/// only a `Layout` axis, and the four intents are the four modes of a
/// component-scoped variable collection that a consumer pins on an instance.
/// Each mode aliases one background token, one stroke token and one glyph, and
/// those aliases are the fixture's `aliases` block.
///
/// Note the family names do not follow the axis names: `Error` binds the
/// **Danger** family, and `Informational` is not a status family at all.
enum FluentMessageBarIntent {
  /// Figma `Informational (Default)`. Neutral throughout — background
  /// `Neutral/Background/3/Rest`, border `Neutral/Stroke/1/Rest`, glyph
  /// `Neutral/Foreground/3/Rest`. There is no `statusInfo*` family.
  info,

  /// Figma `Success`. The `Status/Success/*` family.
  success,

  /// Figma `Warning`. The `Status/Warning/*` family.
  warning,

  /// Figma `Error`. The `Status/**Danger**/*` family — the axis value and the
  /// token family genuinely differ, exactly as they do on
  /// `FluentStatusIndicator`.
  error;

  /// The glyph Figma and React both draw for this intent.
  ///
  /// `Info` is the only regular-weight glyph of the four; the rest are filled,
  /// which is what makes a warning or an error read at a glance.
  IconData get glyph => switch (this) {
    FluentMessageBarIntent.info => FluentIcons.info_20_regular,
    FluentMessageBarIntent.success => FluentIcons.checkmark_circle_20_filled,
    FluentMessageBarIntent.warning => FluentIcons.warning_20_filled,
    FluentMessageBarIntent.error => FluentIcons.error_circle_20_filled,
  };
}

/// How the bar arranges its glyph, body and actions. Figma's `Layout` axis.
enum FluentMessageBarLayout {
  /// Figma `Single line (Default)`. One 36-high row; the body never wraps and
  /// the actions sit inline before the dismiss button.
  singleLine,

  /// Figma `Multi line`. The body wraps and the actions move to a second,
  /// right-aligned row.
  multiLine,
}

/// Corner treatment.
///
/// Figma binds `Message bar/Container` to the shared `Shape` collection, whose
/// third mode is `Circular`. Neither the component set nor React exposes it —
/// React's `shape` prop is `'rounded' | 'square'` — so it is not offered here.
/// `style.borderRadius` covers anyone who wants it.
enum FluentMessageBarShape {
  /// `FluentRadius.medium`. Figma `Shape=Rounded`. The default.
  rounded,

  /// Square corners. Figma `Shape=Square`.
  square,
}

/// Everything needed to render a message bar, independent of intent, layout and
/// shape.
///
/// The Dart counterpart of upstream's `MessageBarState` minus its design axes.
/// [buildFluentMessageBar] takes this rather than [FluentMessageBarState],
/// which is what makes "Fluent's state, my own styling, Fluent's rendering" a
/// supported path rather than a fork.
///
/// [multiline] is the one axis-derived value that lives here, for the same
/// reason `FluentButtonBaseState.iconPosition` does: it decides the shape of
/// the widget tree rather than the values in the style, so rendering cannot be
/// done without it.
@immutable
class FluentMessageBarBaseState {
  /// Creates a base state.
  const FluentMessageBarBaseState({
    required this.body,
    required this.multiline,
    this.icon,
    this.title,
    this.actions = const <Widget>[],
    this.dismiss,
  });

  /// The message. Required — a message bar with no message is a coloured rule.
  final Widget body;

  /// Whether the body wraps and the actions take a row of their own.
  final bool multiline;

  /// The status glyph, already resolved from the intent. Null draws no glyph
  /// and no gap.
  final Widget? icon;

  /// The lead-in, set in the strong ramp and flowed **inline** before [body].
  final Widget? title;

  /// Action affordances, laid out in order.
  final List<Widget> actions;

  /// The dismiss affordance, already built. Null renders nothing.
  final Widget? dismiss;
}

/// A message bar's fully resolved state, including the design axes.
///
/// The counterpart of `FluentButtonState`: base state plus exactly `intent`,
/// `layout` and `shape`.
@immutable
class FluentMessageBarState extends FluentMessageBarBaseState {
  /// Creates a resolved state.
  const FluentMessageBarState({
    required super.body,
    required super.multiline,
    required this.intent,
    required this.layout,
    required this.shape,
    super.icon,
    super.title,
    super.actions,
    super.dismiss,
  });

  /// What the message is about.
  final FluentMessageBarIntent intent;

  /// How the bar arranges itself.
  final FluentMessageBarLayout layout;

  /// Corner treatment.
  final FluentMessageBarShape shape;
}

/// Builds the state a message bar will be styled and rendered from.
///
/// The first of the three-function recomposition contract, and the only place
/// the default glyph is chosen: `icon` overrides
/// [FluentMessageBarIntent.glyph], and `showIcon: false` suppresses the glyph
/// altogether — the counterpart of passing `icon={null}` to the React slot.
FluentMessageBarState resolveFluentMessageBarState({
  required Widget body,
  FluentMessageBarIntent intent = FluentMessageBarIntent.info,
  FluentMessageBarLayout layout = FluentMessageBarLayout.singleLine,
  FluentMessageBarShape shape = FluentMessageBarShape.rounded,
  bool showIcon = true,
  Widget? icon,
  Widget? title,
  List<Widget> actions = const <Widget>[],
  Widget? dismiss,
}) => FluentMessageBarState(
  body: body,
  multiline: layout == FluentMessageBarLayout.multiLine,
  intent: intent,
  layout: layout,
  shape: shape,
  icon: showIcon ? (icon ?? Icon(intent.glyph)) : null,
  title: title,
  actions: actions,
  dismiss: dismiss,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Message bar` component set and the
/// `MessageBar status` variable collection, extracted into
/// `test/fixtures/message_bar.json` — the intent triples are the fixture's
/// `aliases` block, one mode per intent, and they are asserted against the
/// named alias getters in the tests rather than against hex.
///
/// Three divergences from `useMessageBarStyles.styles.ts`, all resolved toward
/// Figma:
///
/// * the type ramp is **`caption1Strong` over `caption1`** (12/16), where React
///   uses `body1Strong` over `body1` (14/20);
/// * the warning glyph takes `Status/Warning/Foreground/**1**/Rest`, where
///   React takes `colorStatusWarningForeground3` — identical in light, a full
///   ramp step apart in dark;
/// * the bar is padded `Spacing/Horizontal/M` on **both** sides, where React
///   pads only the left and leans on the dismiss button's own box.
FluentMessageBarStyle resolveFluentMessageBarStyle(
  FluentMessageBarState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Rest only. The Figma set has no State axis and React declares no hover,
  // pressed, selected or disabled rule, so there is no second token to select
  // between — but the ramp is still spelled through FluentStateColor so a
  // consumer who adds one gets the usual precedence for free.
  final (background, border, icon) = switch (state.intent) {
    FluentMessageBarIntent.info => (
      c.neutralBackground3,
      c.neutralStroke1,
      c.neutralForeground3,
    ),
    FluentMessageBarIntent.success => (
      c.statusSuccessBackground1,
      c.statusSuccessBorder1,
      c.statusSuccessForeground1,
    ),
    FluentMessageBarIntent.warning => (
      c.statusWarningBackground1,
      c.statusWarningBorder1,
      c.statusWarningForeground1,
    ),
    // Error binds the DANGER family. The axis name and the token family differ.
    FluentMessageBarIntent.error => (
      c.statusDangerBackground1,
      c.statusDangerBorder1,
      c.statusDangerForeground1,
    ),
  };

  final radius = switch (state.shape) {
    FluentMessageBarShape.rounded => FluentRadius.allMedium,
    FluentMessageBarShape.square => BorderRadius.zero,
  };

  // The glyph and the body sit 2 and 4 below the top of the multi-line content
  // row, which is (24 - 20) / 2 and (24 - 16) / 2 — i.e. both are centred
  // against the 24-high dismiss button. They are expressed as insets rather
  // than as CrossAxisAlignment.center because a body that wraps to three lines
  // must keep its glyph at the FIRST line, which is the whole point of the
  // multi-line layout.
  final (iconInset, bodyInset) = state.multiline
      ? (
          const EdgeInsets.only(top: FluentSpacing.xxs),
          const EdgeInsets.only(top: FluentSpacing.xs),
        )
      : (EdgeInsets.zero, EdgeInsets.zero);

  return FluentMessageBarStyle(
    backgroundColor: FluentStateColor.tokens(rest: background),
    foregroundColor: FluentStateColor.tokens(rest: c.neutralForeground1),
    borderColor: FluentStateColor.tokens(rest: border),
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(radius),
    iconColor: FluentStateColor.tokens(rest: icon),
    iconSize: const WidgetStatePropertyAll<double?>(FluentSize.size200),
    // 12/16 semibold over 12/16 regular, verbatim from the two styled runs of
    // the single Figma text node. React is a ramp step larger on both.
    titleTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.caption1Strong,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(theme.typography.caption1),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(
        horizontal: FluentSpacing.m,
        vertical: FluentSpacing.sNudge,
      ),
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    multilineGap: const WidgetStatePropertyAll<double?>(FluentSpacing.mNudge),
    iconPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(iconInset),
    bodyPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(bodyInset),
    minimumSize: const WidgetStatePropertyAll<Size?>(Size(0, 36)),
    // The dismiss button is a real FluentButton wearing the message bar's
    // geometry: a 24 square with a 2px inset around a 20 glyph, which is
    // narrower than any FluentButton size ramp produces on its own.
    dismissButtonStyle: const FluentButtonStyle(
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
        EdgeInsets.all(FluentSpacing.xxs),
      ),
      iconSize: WidgetStatePropertyAll<double?>(FluentSize.size200),
      minimumSize: WidgetStatePropertyAll<Size?>(
        Size(FluentSize.size240, FluentSize.size240),
      ),
    ),
  );
}

/// Renders a message bar from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentMessageBarBaseState] rather than [FluentMessageBarState] on purpose:
/// it never reads intent or shape, so a consumer can supply their own style and
/// still use Fluent's layout.
///
/// **Nothing animates, deliberately.** `useMessageBarStyles.styles.ts` contains
/// no `transition`, no `animation` and no `motionTokens` reference of any kind,
/// and neither do the Title, Body or Actions styles files. An intent change
/// lands on the frame it happens, which also makes this trivially correct under
/// `MediaQuery.disableAnimationsOf`: there is no animation to shorten. (React's
/// `MessageBarGroup` *does* animate bars in and out, but that is a different
/// component, and it animates the group's children rather than the bar itself.)
///
/// [states] is accepted for symmetry with the rest of the library and is always
/// empty here — see [FluentMessageBarStyle].
Widget buildFluentMessageBar(
  FluentMessageBarBaseState state,
  FluentMessageBarStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final iconColor = style.iconColor?.resolve(states);
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final titleTextStyle = style.titleTextStyle?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.s;
  final multilineGap =
      style.multilineGap?.resolve(states) ?? FluentSpacing.mNudge;
  final iconPadding = style.iconPadding?.resolve(states) ?? EdgeInsets.zero;
  final bodyPadding = style.bodyPadding?.resolve(states) ?? EdgeInsets.zero;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;

  final glyph = state.icon == null
      ? null
      : Padding(
          padding: iconPadding,
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: IconTheme.merge(
              data: IconThemeData(color: iconColor, size: iconSize),
              child: state.icon!,
            ),
          ),
        );

  // Title and body flow as one paragraph separated by a single space, which is
  // literally what upstream does: `useMessageBarTitleStyles` is body1Strong
  // plus `::after { content: " " }`. A Row would not wrap and a Column would
  // stack, so neither reproduces it — the title is an inline run.
  var body = state.title == null
      ? state.body
      : Text.rich(
          TextSpan(
            children: <InlineSpan>[
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: DefaultTextStyle.merge(
                  style: titleTextStyle,
                  child: state.title!,
                ),
              ),
              const TextSpan(text: ' '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: state.body,
              ),
            ],
          ),
        );

  body = DefaultTextStyle.merge(
    style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
    // Upstream's root is `white-space: nowrap`, flipped to `normal` by
    // `rootMultiline`. A single-line bar therefore overflows rather than
    // growing a second line, which is what keeps its height at 36.
    softWrap: state.multiline,
    overflow: TextOverflow.clip,
    child: Padding(padding: bodyPadding, child: body),
  );

  final content = state.multiline
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: state.actions.isEmpty ? 0 : multilineGap,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: gap,
              children: <Widget>[
                ?glyph,
                Expanded(child: body),
                ?state.dismiss,
              ],
            ),
            if (state.actions.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: gap,
                children: state.actions,
              ),
          ],
        )
      : Row(
          spacing: gap,
          children: <Widget>[
            ?glyph,
            Expanded(child: body),
            ...state.actions,
            ?state.dismiss,
          ],
        );

  return ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: minimumSize.height,
      minWidth: minimumSize.width,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: Padding(padding: padding, child: content),
    ),
  );
}

/// Overrides the message bar style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentMessageBarTheme extends InheritedTheme {
  /// Applies [style] to every `FluentMessageBar` in [child].
  const FluentMessageBarTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the intent, layout and shape defaults.
  final FluentMessageBarStyle style;

  /// The nearest message bar style, or null.
  static FluentMessageBarStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentMessageBarTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentMessageBarTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentMessageBarTheme(style: style, child: child);
}

/// A Fluent 2 message bar: a tinted strip reporting a condition, with optional
/// actions and a dismiss affordance.
///
/// ```dart
/// FluentMessageBar(
///   intent: FluentMessageBarIntent.error,
///   title: const Text('Descriptive title'),
///   onDismiss: () => setState(() => visible = false),
///   actions: <Widget>[
///     FluentButton(size: FluentButtonSize.small, onPressed: retry,
///         child: const Text('Retry')),
///   ],
///   child: const Text('Message providing information to the user.'),
/// )
/// ```
///
/// **The bar itself is not interactive.** It takes no callback of its own,
/// never reports hover, press or focus, and has no disabled rendering: the
/// Figma set has only a `Layout` axis and React declares no interaction rule,
/// so a hover or disabled treatment would be an invention rather than a port.
/// Everything keyboard-reachable inside it — the actions and the dismiss button
/// — is a real `FluentButton` with its own focus ring and semantics.
///
/// [intent] moves the surface, the border and the glyph together, in one step,
/// onto the alias-layer status family Figma binds. Note that
/// [FluentMessageBarIntent.error] selects the **Danger** family and
/// [FluentMessageBarIntent.info] selects no status family at all.
///
/// The bar announces itself as a live region, so assistive technology reads it
/// when it appears. React distinguishes `polite` from `assertive`; Flutter's
/// semantics has a single `liveRegion` flag, so both collapse onto
/// [liveRegion] here.
///
/// **Nothing animates.** See [buildFluentMessageBar].
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentMessageBarTheme] restyles a subtree; and for anything further,
/// [resolveFluentMessageBarState], [resolveFluentMessageBarStyle] and
/// [buildFluentMessageBar] are public so any one of them can be replaced
/// without forking this widget.
class FluentMessageBar extends StatelessWidget {
  /// Creates a message bar carrying [child] as its message.
  const FluentMessageBar({
    super.key,
    required this.child,
    this.intent = FluentMessageBarIntent.info,
    this.layout = FluentMessageBarLayout.singleLine,
    this.shape = FluentMessageBarShape.rounded,
    this.title,
    this.icon,
    this.showIcon = true,
    this.actions = const <Widget>[],
    this.onDismiss,
    this.dismissSemanticLabel,
    this.style,
    this.liveRegion = true,
    this.semanticLabel,
  });

  /// The message.
  final Widget child;

  /// What the message is about. Moves the surface, border and glyph together.
  final FluentMessageBarIntent intent;

  /// How the bar arranges its glyph, body and actions.
  final FluentMessageBarLayout layout;

  /// Corner treatment.
  final FluentMessageBarShape shape;

  /// A lead-in flowed inline before [child], in the strong ramp.
  final Widget? title;

  /// Overrides the glyph [intent] would otherwise select.
  final Widget? icon;

  /// Whether a glyph is drawn at all. False removes it and its gap.
  final bool showIcon;

  /// Action affordances. Usually small `FluentButton`s.
  final List<Widget> actions;

  /// Invoked by the dismiss button. Null renders no dismiss button.
  final VoidCallback? onDismiss;

  /// Announced by assistive technology for the dismiss button, which has no
  /// text of its own.
  ///
  /// Null takes the wording from the ambient [FluentLocalizations],
  /// which falls back to English when no delegate is installed.
  final String? dismissSemanticLabel;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentMessageBarStyle? style;

  /// Whether assistive technology announces the bar when it appears.
  final bool liveRegion;

  /// Announced by assistive technology in place of the subtree's own reading of
  /// the title and body.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // Resolved before the state, because the dismiss button is built from the
    // resolved style and then handed to the state as a plain widget — which is
    // what keeps buildFluentMessageBar free of any knowledge of FluentButton.
    // The style reads only intent, shape and multiline, so the state it is
    // resolved against carries no slots.
    final resolved = resolveFluentMessageBarStyle(
      resolveFluentMessageBarState(
        body: child,
        intent: intent,
        layout: layout,
        shape: shape,
        showIcon: false,
      ),
      FluentTheme.of(context),
      // Lowest to highest: defaults, subtree theme, then the caller's own style.
    ).merge(FluentMessageBarTheme.maybeOf(context)).merge(style);

    final state = resolveFluentMessageBarState(
      body: child,
      intent: intent,
      layout: layout,
      shape: shape,
      showIcon: showIcon,
      icon: icon,
      title: title,
      actions: actions,
      dismiss: onDismiss == null
          ? null
          : FluentButton.icon(
              appearance: FluentButtonAppearance.transparent,
              size: FluentButtonSize.small,
              semanticLabel:
                  dismissSemanticLabel ?? fluentL10n(context).dismiss,
              onPressed: onDismiss,
              style: resolved.dismissButtonStyle,
              icon: const Icon(FluentIcons.dismiss_20_regular),
            ),
    );

    return Semantics(
      container: true,
      liveRegion: liveRegion,
      label: semanticLabel,
      child: buildFluentMessageBar(state, resolved, const <WidgetState>{}),
    );
  }
}
