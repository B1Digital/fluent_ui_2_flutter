import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'radio_style.dart';

/// Where the label sits relative to the indicator. Figma's `Label position`
/// axis, and upstream's `labelPosition` prop.
enum FluentRadioLabelPosition {
  /// After the indicator in reading order. The default.
  after,

  /// Under the indicator, centred. What `FluentRadioGroupLayout.horizontalStacked`
  /// selects for every radio in the group.
  below,
}

/// Everything needed to resolve and render a radio.
///
/// Unlike `FluentButtonState` there is no separate base state, because a radio
/// has no design axis that rendering does not already read: `checked` decides
/// whether the dot is painted and `labelPosition` decides the layout, so both
/// have to reach [buildFluentRadio] anyway. Splitting them off would produce
/// two classes with identical fields.
@immutable
class FluentRadioState {
  /// Creates a resolved state.
  const FluentRadioState({
    required this.enabled,
    required this.checked,
    required this.labelPosition,
    this.label,
  });

  /// Whether the radio responds to input.
  final bool enabled;

  /// Whether this radio is the selected one in its group.
  ///
  /// A design axis, not a [WidgetState]: Fluent swaps the entire token family
  /// between checked and unchecked rather than adding a `*Selected` step to
  /// one. See the note on `FluentRadioStyle`.
  final bool checked;

  /// Where the label sits.
  final FluentRadioLabelPosition labelPosition;

  /// The label, if any. A radio with no label is indicator-only.
  final Widget? label;
}

/// Builds the state a radio will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentRadioState resolveFluentRadioState({
  bool enabled = true,
  bool checked = false,
  FluentRadioLabelPosition labelPosition = FluentRadioLabelPosition.after,
  Widget? label,
}) => FluentRadioState(
  enabled: enabled,
  checked: checked,
  labelPosition: labelPosition,
  label: label,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract. Every value comes
/// from a Fluent token; nothing here computes a colour.
///
/// The ring's two colour families are genuinely disjoint rather than one family
/// with a selected step, which is why `checked` is branched on here:
///
/// * **unchecked** — ring `Neutral/Stroke/Accessible/*`.
/// * **checked** — ring `Brand/Stroke/Compound/*`, dot
///   `Brand/Foreground/Compound/*`.
/// * **disabled**, either way — ring and dot `Neutral/Foreground/Disabled`, a
///   real token, never the enabled colour at reduced opacity.
///
/// The **label does not branch**: Figma binds `Neutral/Foreground/1/Rest` on
/// every one of the 30 `Radio` variants, checked or not, hovered or not. React's
/// `useRadioStyles.styles.ts` instead ramps `colorNeutralForeground3` →
/// `2` → `1` across rest/hover/pressed while unchecked; Figma wins, so the
/// label is one flat token here. See `doc/token-divergences.md`.
FluentRadioStyle resolveFluentRadioStyle(
  FluentRadioState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Figma binds the disabled ring and dot to `Neutral/Foreground/Disabled/Rest`
  // (#BDBDBD), not to `Neutral/Stroke/Disabled` (#E0E0E0) as React does — and
  // the ring is the only thing marking an unchecked radio, so the more legible
  // of the two is also the right one.
  final ring = state.checked
      ? FluentStateColor.tokens(
          rest: c.compoundBrandStroke,
          hover: c.compoundBrandStrokeHover,
          pressed: c.compoundBrandStrokePressed,
          disabled: c.neutralForegroundDisabled,
        )
      : FluentStateColor.tokens(
          rest: c.neutralStrokeAccessible,
          hover: c.neutralStrokeAccessibleHover,
          pressed: c.neutralStrokeAccessiblePressed,
          disabled: c.neutralForegroundDisabled,
        );

  final dot = FluentStateColor.tokens(
    rest: c.compoundBrandForeground1,
    hover: c.compoundBrandForeground1Hover,
    pressed: c.compoundBrandForeground1Pressed,
    disabled: c.neutralForegroundDisabled,
  );

  final foreground = FluentStateColor.tokens(
    rest: c.neutralForeground1,
    disabled: c.neutralForegroundDisabled,
  );

  final labelPadding = switch (state.labelPosition) {
    // Figma's `.RadioBase` for `Icon+Label after`: itemSpacing XS between the
    // indicator and the label, paddingRight S on the base, and SNudge top and
    // bottom on the `Text container` — which is exactly the inset that keeps a
    // 20-high label inside the 32-high indicator block.
    FluentRadioLabelPosition.after => const EdgeInsets.fromLTRB(
      FluentSpacing.xs,
      FluentSpacing.sNudge,
      FluentSpacing.s,
      FluentSpacing.sNudge,
    ),
    // `Icon+Label below`: itemSpacing XS above the label, paddingBottom S, and
    // SNudge — not S — left and right. 6 + 33 + 6 is Figma's 45-wide frame.
    FluentRadioLabelPosition.below => const EdgeInsets.fromLTRB(
      FluentSpacing.sNudge,
      FluentSpacing.xs,
      FluentSpacing.sNudge,
      FluentSpacing.s,
    ),
  };

  return FluentRadioStyle(
    indicatorColor: ring,
    indicatorFillColor: dot,
    foregroundColor: foreground,
    textStyle: WidgetStatePropertyAll<TextStyle?>(theme.typography.body1),
    indicatorSize: const WidgetStatePropertyAll<double?>(FluentSize.size160),
    indicatorFillSize: const WidgetStatePropertyAll<double?>(
      FluentSize.size100,
    ),
    indicatorBorderWidth: const WidgetStatePropertyAll<double?>(
      FluentStroke.thin,
    ),
    indicatorPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(FluentSpacing.s),
    ),
    labelPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(labelPadding),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders a radio from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract.
///
/// **Nothing here animates.** `useRadioStyles.styles.ts` declares no transition
/// at all — not on the ring, not on the dot, not on the label — so checking a
/// radio lands on the frame it is clicked, the same deliberate instant swap
/// Checkbox makes. Do not wrap any of this in a `FluentAnimatedStyle`.
///
/// [states] is the live interaction set from [FluentInteractive]. The focus
/// ring surrounds the whole control including the label, matching upstream's
/// `createFocusOutlineStyle({ selector: 'focus-within' })` on the root.
Widget buildFluentRadio(
  FluentRadioState state,
  FluentRadioStyle style,
  Set<WidgetState> states,
) {
  final ring = style.indicatorColor?.resolve(states);
  final dot = style.indicatorFillColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);
  final size = style.indicatorSize?.resolve(states) ?? FluentSize.size160;
  final dotSize =
      style.indicatorFillSize?.resolve(states) ?? FluentSize.size100;
  final ringWidth =
      style.indicatorBorderWidth?.resolve(states) ?? FluentStroke.thin;
  final indicatorPadding =
      style.indicatorPadding?.resolve(states) ?? EdgeInsets.zero;
  final labelPadding = style.labelPadding?.resolve(states) ?? EdgeInsets.zero;
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;

  final indicator = Padding(
    padding: indicatorPadding,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: FluentRadioIndicatorPainter(
          ring: ring,
          ringWidth: ringWidth,
          dot: state.checked ? dot : null,
          dotSize: dotSize,
        ),
      ),
    ),
  );

  final label = state.label;
  final below = state.labelPosition == FluentRadioLabelPosition.below;
  final labelWidget = label == null
      ? null
      : Padding(
          padding: labelPadding,
          child: DefaultTextStyle.merge(
            style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
            textAlign: below ? TextAlign.center : null,
            child: label,
          ),
        );

  final Widget content = below
      ? Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[indicator, ?labelWidget],
        )
      // Upstream's root is `align-items: normal` and the indicator carries an
      // explicit `height: 16px`, so it stretches to nothing and stays at the
      // top; the label is the only child with `align-self: center`. With the
      // indicator's 8px padding making its block exactly as tall as a single
      // line of label, the two agree until the label wraps — where start is
      // what keeps the ring beside the FIRST line, as Checkbox already does.
      : Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[indicator, ?labelWidget],
        );

  return FluentFocusRing(
    visible: states.contains(WidgetState.focused),
    borderRadius: radius,
    child: content,
  );
}

/// Paints a radio's ring and, when checked, its dot.
///
/// A [CustomPaint] rather than two nested [DecoratedBox]es because that is two
/// render objects and a `BoxDecoration` per state for what is two `drawCircle`
/// calls — and because the resolved tokens stay readable off the painter, so a
/// test asserts colours directly instead of diffing pixels.
///
/// Every input is a public field for exactly that reason.
class FluentRadioIndicatorPainter extends CustomPainter {
  /// Creates a painter for the given tones and widths.
  const FluentRadioIndicatorPainter({
    required this.ring,
    required this.ringWidth,
    required this.dotSize,
    this.dot,
  });

  /// Ring colour. Null paints no ring at all, which is not a state Fluent has.
  final Color? ring;

  /// Ring width. [FluentStroke.thin] upstream.
  final double ringWidth;

  /// Dot colour, or null when the radio is unchecked.
  final Color? dot;

  /// Dot diameter.
  final double dotSize;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    if (ring != null && ringWidth > 0) {
      // Upstream's indicator is `boxSizing: border-box`, so the 1px border eats
      // into the 16px box rather than growing it. A stroke is centred on its
      // path, so that is the box radius pulled in by half a width.
      canvas.drawCircle(
        centre,
        size.shortestSide / 2 - ringWidth / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringWidth
          ..color = ring!,
      );
    }
    if (dot != null) {
      canvas.drawCircle(centre, dotSize / 2, Paint()..color = dot!);
    }
  }

  @override
  bool shouldRepaint(FluentRadioIndicatorPainter oldDelegate) =>
      oldDelegate.ring != ring ||
      oldDelegate.ringWidth != ringWidth ||
      oldDelegate.dot != dot ||
      oldDelegate.dotSize != dotSize;
}

/// Overrides the radio style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentRadioTheme extends InheritedTheme {
  /// Applies [style] to every `FluentRadio` in [child].
  const FluentRadioTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the checked and label-position defaults.
  final FluentRadioStyle style;

  /// The nearest radio style, or null.
  static FluentRadioStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentRadioTheme>()?.style;

  @override
  bool updateShouldNotify(FluentRadioTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentRadioTheme(style: style, child: child);
}

/// Carries a `FluentRadioGroup`'s selection down to the radios inside it.
///
/// Public because a `FluentRadio` is free to live anywhere under the group —
/// inside a card, a row, someone else's layout widget — so the link has to be
/// an inherited one rather than a constructor argument the group passes down.
///
/// Generic over the same `T` as the group, so two nested groups of different
/// value types do not see each other.
class FluentRadioGroupScope<T> extends InheritedWidget {
  /// Creates a scope. Normally created by `FluentRadioGroup`.
  const FluentRadioGroupScope({
    super.key,
    required this.value,
    required this.onChanged,
    required this.disabled,
    required this.labelPosition,
    required super.child,
  });

  /// The group's selected value, or null when nothing is selected.
  final T? value;

  /// Invoked with the newly selected value. Null disables the whole group.
  final ValueChanged<T>? onChanged;

  /// Whether every radio in the group is disabled.
  final bool disabled;

  /// The label position the group's layout implies.
  final FluentRadioLabelPosition labelPosition;

  /// The nearest enclosing group scope for `T`, or null.
  static FluentRadioGroupScope<T>? maybeOf<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentRadioGroupScope<T>>();

  @override
  bool updateShouldNotify(FluentRadioGroupScope<T> oldWidget) =>
      value != oldWidget.value ||
      onChanged != oldWidget.onChanged ||
      disabled != oldWidget.disabled ||
      labelPosition != oldWidget.labelPosition;
}

/// A Fluent 2 radio: one option in a mutually exclusive set.
///
/// ```dart
/// FluentRadioGroup<String>(
///   value: selected,
///   onChanged: (value) => setState(() => selected = value),
///   children: const <Widget>[
///     FluentRadio<String>(value: 'a', label: Text('Option A')),
///     FluentRadio<String>(value: 'b', label: Text('Option B')),
///   ],
/// )
/// ```
///
/// [groupValue] and [onChanged] can also be given per radio, in the shape
/// Material's `Radio` uses, for a set that has no enclosing group. Given both,
/// the radio's own values win.
///
/// [onChanged] takes a non-nullable `T` rather than Material's `T?`: a Fluent
/// radio cannot be deselected by clicking it, so the callback never has a null
/// to deliver.
///
/// Disabled is a real state, not a visual treatment: with no callback in reach
/// — or with `disabled: true`, or inside a disabled group — the radio stops
/// reporting hover and press, refuses focus, and resolves
/// `Neutral/Stroke/Disabled` rather than fading its enabled colour.
///
/// Nothing about a radio animates; see [buildFluentRadio].
///
/// Customisation follows the usual three rungs: [style] is merged last and
/// wins, [FluentRadioTheme] restyles a subtree, and [resolveFluentRadioState],
/// [resolveFluentRadioStyle] and [buildFluentRadio] are public so any one of
/// them can be replaced without forking this widget.
class FluentRadio<T> extends StatelessWidget {
  /// Creates a radio for [value].
  const FluentRadio({
    super.key,
    required this.value,
    this.groupValue,
    this.onChanged,
    this.label,
    this.labelPosition,
    this.disabled = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The value this radio selects.
  final T value;

  /// The group's current selection. Falls back to the enclosing
  /// `FluentRadioGroup`'s value.
  final T? groupValue;

  /// Invoked with [value] when this radio is chosen. Falls back to the
  /// enclosing `FluentRadioGroup`'s callback.
  final ValueChanged<T>? onChanged;

  /// The label. Null for an indicator-only radio, which needs a
  /// [semanticLabel].
  final Widget? label;

  /// Where the label sits. Defaults to the position the enclosing group's
  /// layout implies, and to [FluentRadioLabelPosition.after] outside a group.
  final FluentRadioLabelPosition? labelPosition;

  /// Whether this radio is disabled regardless of the callback in reach.
  ///
  /// Named after Figma's `Disabled` axis and upstream's `disabled` prop; the
  /// state object carries the inverse, `enabled`, like every other component.
  final bool disabled;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentRadioStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Announced by assistive technology in place of the label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scope = FluentRadioGroupScope.maybeOf<T>(context);
    final selection = groupValue ?? scope?.value;
    final callback = onChanged ?? scope?.onChanged;
    final enabled =
        !disabled && !(scope?.disabled ?? false) && callback != null;
    final checked = selection == value;

    final state = resolveFluentRadioState(
      enabled: enabled,
      checked: checked,
      labelPosition:
          labelPosition ??
          scope?.labelPosition ??
          FluentRadioLabelPosition.after,
      label: label,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentRadioStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentRadioTheme.maybeOf(context)).merge(style);

    final radio = FluentInteractive(
      enabled: enabled,
      // Re-selecting the selected radio still reports the value. Harmless and
      // idempotent, and it keeps the callback contract "this is the selection
      // now" rather than "the selection changed", which is what a caller
      // assigning straight to state wants.
      onPressed: enabled ? () => callback(value) : null,
      focusNode: focusNode,
      autofocus: autofocus,
      mouseCursor:
          resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
          SystemMouseCursors.click,
      builder: (context, states, _) =>
          buildFluentRadio(state, resolved, states),
    );

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: checked,
      enabled: enabled,
      label: semanticLabel,
      child: radio,
    );
  }
}
