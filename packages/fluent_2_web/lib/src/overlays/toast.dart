import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../buttons/button.dart';
import '../buttons/button_style.dart';
import '../internal/interaction.dart';
import 'toast_style.dart';

/// What the toast is about. Figma's `Toast status` variable collection.
///
/// The one axis that is **not** a variant property: the Figma `Toast` is a
/// loose component with no variants at all, and the seven statuses are the
/// seven modes of a component-scoped variable collection that a consumer pins
/// on an instance. Each mode toggles the visibility of one layer inside the
/// 20-square status slot, which is why the fixture's `aliases` block records
/// them as booleans rather than as colour aliases — the *tokens* live on the
/// glyph vectors inside those hidden layers.
///
/// Note that [error] binds the **Danger** family: the mode name and the token
/// family genuinely differ, exactly as they do on `FluentMessageBar` and
/// `FluentStatusIndicator`.
///
/// Figma's remaining three modes — `Icon`, `Spinner` and `Avatar` — are all
/// [custom]: they differ only in which widget is dropped into the status slot,
/// and all three bind the same `Neutral/Foreground/2/Rest` tint. Pass a
/// `FluentSpinner` or a `FluentAvatar` as the toast's `icon` to reproduce the
/// other two.
enum FluentToastIntent {
  /// Figma `Informational (Default)`. Neutral throughout — the glyph takes
  /// `Neutral/Foreground/3/Rest`. There is no `statusInfo*` family.
  info,

  /// Figma `Success`. The `Status/Success/*` family.
  success,

  /// Figma `Warning`. The `Status/Warning/*` family.
  warning,

  /// Figma `Error`. The `Status/**Danger**/*` family.
  error,

  /// Figma `Icon`, `Spinner` and `Avatar`. No default glyph and no status
  /// family — supply your own widget through the toast's `icon`, tinted
  /// `Neutral/Foreground/2/Rest`.
  custom;

  /// The glyph Figma and React both draw for this status, or null for
  /// [custom], which has none.
  IconData? get glyph => switch (this) {
    FluentToastIntent.info => FluentIcons.info_20_regular,
    FluentToastIntent.success => FluentIcons.checkmark_circle_20_filled,
    FluentToastIntent.warning => FluentIcons.warning_20_filled,
    FluentToastIntent.error => FluentIcons.error_circle_20_filled,
    FluentToastIntent.custom => null,
  };

  /// Whether assistive technology should interrupt for this status.
  ///
  /// Upstream maps `error` and `warning` to `assertive` and everything else to
  /// `polite`. Flutter's semantics has a single `liveRegion` flag, so the
  /// distinction survives only as *whether* the toast announces at all.
  bool get assertive =>
      this == FluentToastIntent.error || this == FluentToastIntent.warning;
}

/// What sits in the toast's end slot. Figma's `Toast type` variable collection.
///
/// The three modes are mutually exclusive — the end slot is a single 20-square
/// — which is why this is an axis rather than three independent slots.
enum FluentToastType {
  /// Figma `Dismiss (Default)`. A dismiss button.
  dismiss,

  /// Figma `Timestamp`. A `caption1` label, right-aligned.
  timestamp,

  /// Figma `Action`. A link-coloured affordance, usually a `FluentLink`.
  action,
}

/// Everything needed to render a toast, independent of the intent.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentToast] takes this
/// rather than [FluentToastState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentToastBaseState {
  /// Creates a base state.
  const FluentToastBaseState({
    required this.title,
    this.icon,
    this.body,
    this.subtitle,
    this.footer = const <Widget>[],
    this.end,
  });

  /// The primary line. Required — a toast with no title is a coloured box.
  final Widget title;

  /// The status glyph, already resolved from the intent. Null draws no glyph
  /// and no gap, and un-indents the body.
  final Widget? icon;

  /// The secondary line, in the regular ramp.
  final Widget? body;

  /// The tertiary line, a ramp step smaller and quieter than [body].
  final Widget? subtitle;

  /// Action affordances on their own row under the body.
  final List<Widget> footer;

  /// The end slot's content, already built from the type.
  final Widget? end;
}

/// A toast's fully resolved state, including the design axes.
///
/// The counterpart of `FluentButtonState`: base state plus exactly `intent`
/// and `type`.
@immutable
class FluentToastState extends FluentToastBaseState {
  /// Creates a resolved state.
  const FluentToastState({
    required super.title,
    required this.intent,
    required this.type,
    super.icon,
    super.body,
    super.subtitle,
    super.footer,
    super.end,
  });

  /// What the toast is about.
  final FluentToastIntent intent;

  /// What sits in the end slot.
  final FluentToastType type;
}

/// Builds the state a toast will be styled and rendered from.
///
/// The first of the three-function recomposition contract, and the only place
/// the default glyph is chosen: `icon` overrides [FluentToastIntent.glyph], and
/// `showIcon: false` suppresses the glyph altogether.
FluentToastState resolveFluentToastState({
  required Widget title,
  FluentToastIntent intent = FluentToastIntent.info,
  FluentToastType type = FluentToastType.dismiss,
  bool showIcon = true,
  Widget? icon,
  Widget? body,
  Widget? subtitle,
  List<Widget> footer = const <Widget>[],
  Widget? end,
}) {
  final glyph = intent.glyph;
  return FluentToastState(
    title: title,
    intent: intent,
    type: type,
    icon: showIcon ? (icon ?? (glyph == null ? null : Icon(glyph))) : null,
    body: body,
    subtitle: subtitle,
    footer: footer,
    end: end,
  );
}

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour comes from a Fluent token selected
/// through [FluentStateColor]; nothing here computes one.
///
/// Token sources are the Figma `Toast` component (`9116:16062`, page
/// `8934:22`), extracted into `test/fixtures/toast.json`, plus the seven hidden
/// status layers whose glyph tokens the traversal cannot reach — those are
/// transcribed in `test/overlays/toast_test.dart` and asserted against the
/// named alias getters rather than against hex.
///
/// Four divergences from `useToastStyles.styles.ts`, three resolved toward
/// Figma and one deliberately not:
///
/// * **Elevation is `shadow16`**, not React's `shadow8`. The Figma container
///   carries the `Shadow 16` effect style verbatim — ambient `(0,0)` blur 2
///   plus key `(0,8)` blur 16.
/// * **The status glyph is a 20 box**, not React's `fontSize: '16px'`. Figma's
///   status slot is a 20-square holding a 20px icon instance, the same call
///   `FluentMessageBar` makes.
/// * **The title is `body1Strong`** — 14/20 semibold — which is what both agree
///   on, but Figma states it as bound `Font size/300` + `Line height/300` +
///   `Weight/Semibold` rather than as three loose numbers.
/// * **The border is React's.** Figma paints *no stroke at all* on the
///   container, where React declares `1px solid colorTransparentStroke`. The
///   two are pixel-identical in a normal theme, but Fluent's transparent tokens
///   turn opaque in high contrast, where that border is the only thing
///   separating a `neutralBackground1` toast from a `neutralBackground1` page.
///   This is the same exception `FluentSwitch`'s checked track already makes.
///
/// The body block's internal spacing is React's as well, for a different
/// reason: Figma's `Toast body` frame ships **hidden**, so its auto-layout
/// numbers are stale (its stated 48 height matches none of its children's), and
/// a hidden frame is a silent design file rather than an authoritative one.
FluentToastStyle resolveFluentToastStyle(
  FluentToastState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Rest only. Neither the Figma component nor React declares a hover, pressed,
  // selected or disabled rule anywhere on the surface — the toast is a
  // notification, not a control — so each of these is a single-token set.
  final icon = switch (state.intent) {
    FluentToastIntent.info => c.neutralForeground3,
    FluentToastIntent.success => c.statusSuccessForeground1,
    FluentToastIntent.warning => c.statusWarningForeground1,
    // Error binds the DANGER family. The axis name and the token family differ.
    FluentToastIntent.error => c.statusDangerForeground1,
    FluentToastIntent.custom => c.neutralForeground2,
  };

  return FluentToastStyle(
    backgroundColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    foregroundColor: FluentStateColor.tokens(rest: c.neutralForeground1),
    subtitleColor: FluentStateColor.tokens(rest: c.neutralForeground2),
    // Transparent, not absent: this turns into canvasText in high contrast,
    // which is the only thing outlining the surface there.
    borderColor: FluentStateColor.tokens(rest: c.transparentStroke),
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    shadow: WidgetStatePropertyAll<List<BoxShadow>?>(
      theme.shadow(FluentElevation.shadow16),
    ),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(FluentSpacing.m),
    ),
    titleTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.body1Strong,
    ),
    bodyTextStyle: WidgetStatePropertyAll<TextStyle?>(theme.typography.body1),
    subtitleTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.caption1,
    ),
    timestampTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.caption1,
    ),
    iconColor: FluentStateColor.tokens(rest: icon),
    iconSize: const WidgetStatePropertyAll<double?>(FluentSize.size200),
    mediaGap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    endGap: const WidgetStatePropertyAll<double?>(FluentSpacing.m),
    // 20 (the glyph box) + 8 (the media gap), which is exactly the 28 Figma
    // pins as the `Toast body` frame's left inset.
    bodyIndent: const WidgetStatePropertyAll<double?>(
      FluentSize.size200 + FluentSpacing.s,
    ),
    bodyPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.only(top: FluentSpacing.sNudge),
    ),
    subtitlePadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.only(top: FluentSpacing.xs),
    ),
    footerPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.only(top: FluentSpacing.l),
    ),
    // ponytail: 14 is not a spacing token. `useToastFooterStyles` writes
    // `gap: '14px'` literally and Figma's own quick-action row is `L` (16); the
    // literal is kept because it is the only number either source states for
    // the row this widget actually renders.
    footerGap: const WidgetStatePropertyAll<double?>(14),
    // `useToasterStyles` pins `width: '292px'` on the toaster, and the Figma
    // frame measures 292 — the one number both sources state identically.
    width: const WidgetStatePropertyAll<double?>(292),
    stackGap: const WidgetStatePropertyAll<double?>(FluentSpacing.l),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.basic,
    ),
    // The dismiss button is a real FluentButton wearing the toast's geometry: a
    // 20 square around a 12 glyph, which is what Figma's `Dismiss` instance and
    // its 12x12 `Shape` vector measure. No FluentButton size ramp produces it.
    dismissButtonStyle: const FluentButtonStyle(
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(EdgeInsets.zero),
      iconSize: WidgetStatePropertyAll<double?>(FluentSize.size120),
      minimumSize: WidgetStatePropertyAll<Size?>(
        Size(FluentSize.size200, FluentSize.size200),
      ),
    ),
  );
}

/// Renders a toast from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentToastBaseState] rather than [FluentToastState] on purpose: it never
/// reads the intent or the type, so a consumer can supply their own style and
/// still use Fluent's layout.
///
/// **Nothing inside the surface animates.** `useToastStyles.styles.ts` contains
/// no `transition`, no `animation` and no `motionTokens` reference of any kind.
/// The only motion on a toast is the *container's* entrance and exit, which
/// belongs to `FluentToaster` — see `fluentToastEnter`.
///
/// [states] is accepted for symmetry with the rest of the library and is
/// normally empty; `FluentToaster` adds [WidgetState.focused] when the toast is
/// the keyboard's current target, which raises its focus ring.
Widget buildFluentToast(
  FluentToastBaseState state,
  FluentToastStyle style,
  Set<WidgetState> states,
) {
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final subtitleColor = style.subtitleColor?.resolve(states);
  final borderColor = style.borderColor?.resolve(states);
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final titleTextStyle = style.titleTextStyle?.resolve(states);
  final bodyTextStyle = style.bodyTextStyle?.resolve(states);
  final subtitleTextStyle = style.subtitleTextStyle?.resolve(states);
  final iconColor = style.iconColor?.resolve(states);
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final mediaGap = style.mediaGap?.resolve(states) ?? FluentSpacing.s;
  final endGap = style.endGap?.resolve(states) ?? FluentSpacing.m;
  final bodyIndent = style.bodyIndent?.resolve(states) ?? 0;
  final bodyPadding = style.bodyPadding?.resolve(states) ?? EdgeInsets.zero;
  final subtitlePadding =
      style.subtitlePadding?.resolve(states) ?? EdgeInsets.zero;
  final footerPadding = style.footerPadding?.resolve(states) ?? EdgeInsets.zero;
  final footerGap = style.footerGap?.resolve(states) ?? FluentSpacing.l;

  final glyph = state.icon == null
      ? null
      : SizedBox(
          width: iconSize,
          height: iconSize,
          child: IconTheme.merge(
            data: IconThemeData(color: iconColor, size: iconSize),
            child: state.icon!,
          ),
        );

  // Figma's `Toast header`: a `Status content` row (glyph + title, gap S)
  // taking the free width, then the `End container`, gap M.
  final header = Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: glyph == null ? 0 : mediaGap,
          children: <Widget>[
            ?glyph,
            Expanded(
              child: DefaultTextStyle.merge(
                style: (titleTextStyle ?? const TextStyle()).copyWith(
                  color: foreground,
                ),
                child: state.title,
              ),
            ),
          ],
        ),
      ),
      if (state.end != null) ...<Widget>[SizedBox(width: endGap), state.end!],
    ],
  );

  // The body block lines up under the TITLE, not under the glyph — Figma pins
  // `Toast body` at a 28 left inset, which is the glyph box plus its gap. With
  // no glyph there is nothing to clear, so the inset goes with it.
  final indent = glyph == null ? 0.0 : bodyIndent;
  final hasBody =
      state.body != null || state.subtitle != null || state.footer.isNotEmpty;

  return ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: style.width?.resolve(states) ?? double.infinity,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: style.shadow?.resolve(states),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            header,
            if (hasBody)
              Padding(
                padding: EdgeInsetsDirectional.only(start: indent),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (state.body != null)
                      Padding(
                        padding: bodyPadding,
                        child: DefaultTextStyle.merge(
                          style: (bodyTextStyle ?? const TextStyle()).copyWith(
                            color: foreground,
                          ),
                          child: state.body!,
                        ),
                      ),
                    if (state.subtitle != null)
                      Padding(
                        padding: subtitlePadding,
                        child: DefaultTextStyle.merge(
                          style: (subtitleTextStyle ?? const TextStyle())
                              .copyWith(color: subtitleColor),
                          child: state.subtitle!,
                        ),
                      ),
                    if (state.footer.isNotEmpty)
                      Padding(
                        padding: footerPadding,
                        child: Row(spacing: footerGap, children: state.footer),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Overrides the toast style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`. An [InheritedTheme], so `InheritedTheme.capture`
/// carries it across the [Overlay] boundary along with `FluentTheme` — which is
/// the whole reason a toaster mounted at the app root still honours a
/// `FluentToastTheme` wrapping the widget that raised the toast.
class FluentToastTheme extends InheritedTheme {
  /// Applies [style] to every [FluentToast] in [child].
  const FluentToastTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the intent defaults.
  final FluentToastStyle style;

  /// The nearest toast style, or null.
  static FluentToastStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentToastTheme>()?.style;

  @override
  bool updateShouldNotify(FluentToastTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentToastTheme(style: style, child: child);
}

/// A Fluent 2 toast: a raised notification surface with a status glyph, a
/// title, an optional body and an end affordance.
///
/// ```dart
/// FluentToast(
///   intent: FluentToastIntent.success,
///   title: const Text('Mail sent'),
///   body: const Text('Your message is on its way.'),
///   onDismiss: () => controller.dismiss(id),
/// )
/// ```
///
/// This is the **surface only**. It renders wherever you put it and does
/// nothing about queueing, positioning, stacking, entrance motion or the
/// auto-dismiss timer — all of that is `FluentToaster`, and `showFluentToast`
/// is the one-call path that goes through it. Rendering a toast inline is a
/// supported thing to do, and is what the goldens do.
///
/// **The surface itself is not interactive.** It takes no callback of its own,
/// never reports hover or press, and has no disabled rendering: the Figma
/// component has no `State` axis and React declares no interaction rule.
/// Everything keyboard-reachable inside it — the dismiss button, the footer
/// actions, an [FluentToastType.action] end slot — is a real focusable widget
/// with its own focus ring and semantics.
///
/// [intent] moves only the **glyph**, onto the alias-layer status family Figma
/// binds. The surface, the border and the text stay neutral in every intent,
/// which is the largest structural difference between this and
/// `FluentMessageBar`: a message bar tints its whole surface, a toast does not.
/// Note that [FluentToastIntent.error] selects the **Danger** family.
///
/// The toast announces itself as a live region, so assistive technology reads
/// it when it appears. React distinguishes `polite` from `assertive` per
/// intent; Flutter's semantics has a single [liveRegion] flag, so the
/// distinction survives only as [FluentToastIntent.assertive], which callers
/// can read.
///
/// **Nothing here animates.** See [buildFluentToast], and `fluentToastEnter`
/// for the container motion that does.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentToastTheme] restyles a subtree; and for anything further,
/// [resolveFluentToastState], [resolveFluentToastStyle] and [buildFluentToast]
/// are public so any one of them can be replaced without forking this widget.
class FluentToast extends StatelessWidget {
  /// Creates a toast titled [title].
  const FluentToast({
    super.key,
    required this.title,
    this.intent = FluentToastIntent.info,
    this.type = FluentToastType.dismiss,
    this.body,
    this.subtitle,
    this.footer = const <Widget>[],
    this.icon,
    this.showIcon = true,
    this.onDismiss,
    this.dismissSemanticLabel = 'Dismiss',
    this.timestamp,
    this.action,
    this.style,
    this.states = const <WidgetState>{},
    this.liveRegion = true,
    this.semanticLabel,
  });

  /// The primary line, in `body1Strong`.
  final Widget title;

  /// What the toast is about. Moves the glyph, and nothing else.
  final FluentToastIntent intent;

  /// What sits in the end slot.
  final FluentToastType type;

  /// The secondary line, in `body1`.
  final Widget? body;

  /// The tertiary line, in `caption1` and a ramp step quieter.
  final Widget? subtitle;

  /// Action affordances on their own row under the body.
  final List<Widget> footer;

  /// Overrides the glyph [intent] would otherwise select. Required for
  /// [FluentToastIntent.custom], which has none of its own.
  final Widget? icon;

  /// Whether a glyph is drawn at all. False removes it, its gap and the body's
  /// indent.
  final bool showIcon;

  /// Invoked by the dismiss button. Null renders no dismiss button, even when
  /// [type] is [FluentToastType.dismiss].
  final VoidCallback? onDismiss;

  /// Announced by assistive technology for the dismiss button, which has no
  /// text of its own.
  final String dismissSemanticLabel;

  /// The end slot's label when [type] is [FluentToastType.timestamp].
  final Widget? timestamp;

  /// The end slot's affordance when [type] is [FluentToastType.action].
  /// Usually a `FluentLink`.
  final Widget? action;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentToastStyle? style;

  /// Extra states to resolve the style against. `FluentToaster` passes
  /// [WidgetState.focused] here when the toast holds keyboard focus.
  final Set<WidgetState> states;

  /// Whether assistive technology announces the toast when it appears.
  final bool liveRegion;

  /// Announced by assistive technology in place of the subtree's own reading.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // Resolved before the state, because the dismiss button is built from the
    // resolved style and then handed to the state as a plain widget — which is
    // what keeps buildFluentToast free of any knowledge of FluentButton. The
    // style reads only the intent, so the state it is resolved against carries
    // no slots.
    final resolved = resolveFluentToastStyle(
      resolveFluentToastState(title: title, intent: intent, type: type),
      FluentTheme.of(context),
      // Lowest to highest: defaults, subtree theme, then the caller's own style.
    ).merge(FluentToastTheme.maybeOf(context)).merge(style);

    final end = switch (type) {
      FluentToastType.dismiss =>
        onDismiss == null
            ? null
            : FluentButton.icon(
                appearance: FluentButtonAppearance.transparent,
                size: FluentButtonSize.small,
                semanticLabel: dismissSemanticLabel,
                onPressed: onDismiss,
                style: resolved.dismissButtonStyle,
                icon: const Icon(FluentIcons.dismiss_20_regular),
              ),
      FluentToastType.timestamp =>
        timestamp == null
            ? null
            : DefaultTextStyle.merge(
                style:
                    (resolved.timestampTextStyle?.resolve(states) ??
                            const TextStyle())
                        .copyWith(
                          color: resolved.foregroundColor?.resolve(states),
                        ),
                child: timestamp!,
              ),
      FluentToastType.action => action,
    };

    final state = resolveFluentToastState(
      title: title,
      intent: intent,
      type: type,
      showIcon: showIcon,
      icon: icon,
      body: body,
      subtitle: subtitle,
      footer: footer,
      end: end,
    );

    return Semantics(
      container: true,
      liveRegion: liveRegion,
      label: semanticLabel,
      child: buildFluentToast(state, resolved, states),
    );
  }
}
