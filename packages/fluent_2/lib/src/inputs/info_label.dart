import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'info_button.dart';
import 'info_label_style.dart';
import 'label.dart';

/// Everything needed to render an info label, independent of size.
///
/// The Dart counterpart of upstream's `InfoLabelState` minus its design axis.
/// [buildFluentInfoLabel] takes this rather than [FluentInfoLabelState], which
/// is what makes "Fluent's state, my own styling, Fluent's rendering" a
/// supported path rather than a fork.
///
/// Both slots arrive as finished widgets. That is the point: the renderer puts
/// a label beside a trigger and does nothing else, so a consumer can pass their
/// own trigger — or none — without this component growing a passthrough
/// argument per `FluentInfoButton` property.
@immutable
class FluentInfoLabelBaseState {
  /// Creates a base state.
  const FluentInfoLabelBaseState({
    required this.enabled,
    required this.label,
    this.infoButton,
  });

  /// Whether the label renders in its enabled colour and the trigger responds
  /// to input.
  final bool enabled;

  /// The label slot, already built.
  final Widget label;

  /// The info button slot, or null for a label with nothing to explain — which
  /// is what upstream renders when its `info` prop is absent.
  final Widget? infoButton;
}

/// An info label's fully resolved state, including the design axis.
///
/// The counterpart of `FluentButtonState`: base state plus exactly `size`.
@immutable
class FluentInfoLabelState extends FluentInfoLabelBaseState {
  /// Creates a resolved state.
  const FluentInfoLabelState({
    required super.enabled,
    required super.label,
    required this.size,
    super.infoButton,
  });

  /// Type ramp step, shared with the label it wraps.
  final FluentLabelSize size;
}

/// Builds the state an info label will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentInfoLabelState resolveFluentInfoLabelState({
  required Widget label,
  bool enabled = true,
  FluentLabelSize size = FluentLabelSize.medium,
  Widget? infoButton,
}) => FluentInfoLabelState(
  enabled: enabled,
  size: size,
  label: label,
  infoButton: infoButton,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract. It reads the design
/// axis and finds that nothing depends on it: all three Figma `InfoLabel`
/// variants set `itemSpacing: 0` and no padding, so the gap is size-invariant.
/// The label's and the trigger's own resolvers own everything else.
FluentInfoLabelStyle resolveFluentInfoLabelStyle(
  FluentInfoLabelState state,
  FluentThemeData theme,
) => const FluentInfoLabelStyle(
  gap: WidgetStatePropertyAll<double?>(FluentSpacing.none),
);

/// Renders an info label from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentInfoLabelBaseState] rather than [FluentInfoLabelState] on purpose: it
/// never reads the size, so a consumer can supply their own style and still use
/// Fluent's layout.
///
/// The trigger is taller than the label at every size — 24 against a 20 line
/// box at medium — and Figma lets it win: the variant frame is 24 tall with the
/// label centred in it. Upstream instead pulls the button in with a negative
/// `marginTop`/`marginBottom` so it never grows the line box. Figma wins, as it
/// does everywhere else in this port.
///
/// Nothing here animates. Neither `useInfoLabelStyles.styles.ts` nor Figma
/// declares a transition on InfoLabel.
Widget buildFluentInfoLabel(
  FluentInfoLabelBaseState state,
  FluentInfoLabelStyle style,
  Set<WidgetState> states,
) {
  final infoButton = state.infoButton;
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    spacing: infoButton == null
        ? FluentSpacing.none
        : style.gap?.resolve(states) ?? FluentSpacing.none,
    children: <Widget>[state.label, ?infoButton],
  );
}

/// Overrides the info label style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentInfoLabelTheme extends InheritedTheme {
  /// Applies [style] to every [FluentInfoLabel] in [child].
  const FluentInfoLabelTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the defaults, including the two nested slot
  /// styles.
  final FluentInfoLabelStyle style;

  /// The nearest info label style, or null.
  static FluentInfoLabelStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentInfoLabelTheme>()?.style;

  @override
  bool updateShouldNotify(FluentInfoLabelTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentInfoLabelTheme(style: style, child: child);
}

/// A Fluent 2 info label — a [FluentLabel] with a [FluentInfoButton] after it.
///
/// ```dart
/// FluentInfoLabel(
///   weight: FluentLabelWeight.semibold,
///   info: const Text('Deleted items are kept for 30 days.'),
///   infoSemanticLabel: 'About the retention period',
///   child: const Text('Retention'),
/// )
/// ```
///
/// Omit [info] and this is a plain label: upstream renders no trigger when it
/// has nothing to explain, and neither does this.
///
/// [disabled] is a real state rather than a visual treatment: the label
/// resolves `neutralForegroundDisabled` and the trigger stops reporting hover
/// and press, refuses focus and closes an open tip. Figma has no Disabled axis
/// on either set, so the trigger's disabled foreground is this port's
/// extrapolation — see [resolveFluentInfoButtonStyle].
///
/// ## Size, and the weight Figma happens to draw
///
/// [size] drives both slots: the label's type ramp and the trigger's box. The
/// three Figma variants draw Small and Medium **regular** and Large
/// **semibold**, but that is the nested `Label` instance's own coverage — the
/// `Label` set ships no Large + Regular pair at all — not a rule about
/// InfoLabel. [weight] therefore defaults to regular at every size, as
/// `FluentLabel` does.
///
/// ## The tip is provisional
///
/// See [FluentInfoButton]: the surface is a plain [Overlay] entry until
/// `FluentPopover` lands in Wave 4.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins and reaches both slots through [FluentInfoLabelStyle.labelStyle] and
/// [FluentInfoLabelStyle.infoButtonStyle]; [FluentInfoLabelTheme] restyles a
/// subtree; and [resolveFluentInfoLabelState], [resolveFluentInfoLabelStyle]
/// and [buildFluentInfoLabel] are public so any one of them can be replaced
/// without forking this widget.
class FluentInfoLabel extends StatelessWidget {
  /// Creates an info label for [child], explained by [info].
  const FluentInfoLabel({
    super.key,
    required this.child,
    this.info,
    this.infoSemanticLabel,
    this.size = FluentLabelSize.medium,
    this.weight = FluentLabelWeight.regular,
    this.required = false,
    this.disabled = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onOpenChanged,
  }) : assert(
         info == null || infoSemanticLabel != null,
         'An info button is a glyph with no text: give infoSemanticLabel '
         'whenever info is set, or a screen reader announces an unlabelled '
         'button.',
       );

  /// The label text.
  final Widget child;

  /// The tip body. Null renders no trigger at all.
  final Widget? info;

  /// Announced by assistive technology for the trigger. Required whenever
  /// [info] is set.
  final String? infoSemanticLabel;

  /// Type ramp step, and the trigger's box with it.
  final FluentLabelSize size;

  /// Label font weight.
  final FluentLabelWeight weight;

  /// Whether to render the required-field asterisk after [child].
  final bool required;

  /// Whether the label renders in its disabled colour and the trigger stops
  /// responding.
  final bool disabled;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentInfoLabelStyle? style;

  /// Focus node for the trigger. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether the trigger takes focus on mount.
  final bool autofocus;

  /// Called with the new open state whenever the tip opens or closes.
  final ValueChanged<bool>? onOpenChanged;

  /// The trigger's box for a label of [size].
  static FluentInfoButtonSize infoButtonSizeFor(FluentLabelSize size) =>
      switch (size) {
        FluentLabelSize.small => FluentInfoButtonSize.small,
        FluentLabelSize.medium => FluentInfoButtonSize.medium,
        FluentLabelSize.large => FluentInfoButtonSize.large,
      };

  @override
  Widget build(BuildContext context) {
    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    // Resolved from the bare state, because the two slots below need the
    // resolved nested styles before they can be built.
    final resolved = resolveFluentInfoLabelStyle(
      resolveFluentInfoLabelState(label: child, size: size, enabled: !disabled),
      FluentTheme.of(context),
    ).merge(FluentInfoLabelTheme.maybeOf(context)).merge(style);

    final tip = info;
    final state = resolveFluentInfoLabelState(
      enabled: !disabled,
      size: size,
      label: FluentLabel(
        size: size,
        weight: weight,
        required: required,
        disabled: disabled,
        style: resolved.labelStyle,
        child: child,
      ),
      infoButton: tip == null
          ? null
          : FluentInfoButton(
              info: tip,
              semanticLabel: infoSemanticLabel!,
              size: infoButtonSizeFor(size),
              enabled: !disabled,
              style: resolved.infoButtonStyle,
              focusNode: focusNode,
              autofocus: autofocus,
              onOpenChanged: onOpenChanged,
            ),
    );

    return buildFluentInfoLabel(state, resolved, <WidgetState>{
      if (disabled) WidgetState.disabled,
    });
  }
}
