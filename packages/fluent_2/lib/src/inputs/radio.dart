import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
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

/// Carries a `FluentRadioGroup`'s *presentation* down to the radios inside it.
///
/// The **selection** does not travel this way: it rides the framework's
/// [RadioGroup] / [RadioGroupRegistry] instead, which is what buys the group a
/// single tab stop and arrow-key navigation. This scope carries only the two
/// things `RadioGroup` has no concept of — Fluent's `disabled` axis and the
/// label position the group's layout implies.
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
    required this.disabled,
    required this.labelPosition,
    required super.child,
  });

  /// Whether every radio in the group is disabled.
  final bool disabled;

  /// The label position the group's layout implies.
  final FluentRadioLabelPosition labelPosition;

  /// The nearest enclosing group scope for `T`, or null.
  static FluentRadioGroupScope<T>? maybeOf<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentRadioGroupScope<T>>();

  @override
  bool updateShouldNotify(FluentRadioGroupScope<T> oldWidget) =>
      disabled != oldWidget.disabled ||
      labelPosition != oldWidget.labelPosition;
}

// A radio inside a framework `RadioGroup` would otherwise never see Space at
// all: `RadioGroup` installs a `Shortcuts.manager` that binds Space to its own
// `_toggleFocusedRadio` (`radio_group.dart:96` in the SDK), and that manager
// sits NEARER the focus node than `WidgetsApp`'s defaults, so it consumes the
// key before `ActivateIntent` is ever dispatched. Worse, `_toggleFocusedRadio`
// silently no-ops when the focused radio is already the selected one and is not
// tristate — which would quietly break the contract documented on
// [FluentRadio.onChanged], that re-selecting the selection still reports it.
//
// Re-binding Space here, one `Shortcuts` closer to the radio's focus node than
// `RadioGroup`'s, restores the documented behaviour. It is a no-op outside a
// group: it maps Space to exactly what `WidgetsApp` already maps it to.
const Map<ShortcutActivator, Intent> _spaceActivates =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    };

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
/// Inside a `FluentRadioGroup` the *whole group* is a single tab stop and the
/// arrow keys move the selection, wrapping at both ends — the WAI-ARIA radio
/// group pattern, supplied by the framework's [RadioGroup] via [RadioClient].
/// A radio that overrides [groupValue] or [onChanged] has opted out of the
/// enclosing group's selection model and is therefore left out of that
/// navigation; it keeps its own tab stop and reports only through its own
/// callback.
///
/// Nothing about a radio animates; see [buildFluentRadio].
///
/// Customisation follows the usual three rungs: [style] is merged last and
/// wins, [FluentRadioTheme] restyles a subtree, and [resolveFluentRadioState],
/// [resolveFluentRadioStyle] and [buildFluentRadio] are public so any one of
/// them can be replaced without forking this widget.
class FluentRadio<T> extends StatefulWidget {
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
  State<FluentRadio<T>> createState() => _FluentRadioState<T>();
}

/// Stateful only to be a [RadioClient]: the framework's [RadioGroupRegistry]
/// navigates by focus node, so it needs a long-lived object per radio that owns
/// one and can be registered and unregistered.
class _FluentRadioState<T> extends State<FluentRadio<T>> with RadioClient<T> {
  FocusNode? _internalNode;

  /// Owned here rather than left to [FluentInteractive] to create, because the
  /// registry asks each client which node it has and moves focus between them.
  @override
  FocusNode get focusNode =>
      widget.focusNode ??
      (_internalNode ??= FocusNode(debugLabel: 'FluentRadio'));

  @override
  T get radioValue => widget.value;

  /// A Fluent radio cannot be deselected by re-activating it, so the framework
  /// never takes its `onChanged(null)` path. See [FluentRadio.onChanged].
  @override
  bool get tristate => false;

  /// Only enabled radios are ever registered — see the registration in [build]
  /// — so a client the registry can see is by definition enabled.
  @override
  bool get enabled => registry != null;

  @override
  void dispose() {
    registry = null;
    _internalNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = FluentRadioGroupScope.maybeOf<T>(context);
    // Read unconditionally, register conditionally: a DISABLED radio still has
    // to know the group's selection so it can paint the checked-and-disabled
    // tokens. Only the `registry` assignment below is gated.
    final group = RadioGroup.maybeOf<T>(context);

    final selection = widget.groupValue ?? group?.groupValue;
    // `RadioGroupRegistry.onChanged` is `ValueChanged<T?>` because `RawRadio`
    // may be toggleable; ours never is, so the nullable parameter is simply
    // wider than needed and Dart's contravariance accepts it here. The public
    // API stays non-nullable.
    final callback = widget.onChanged ?? group?.onChanged;
    final enabled =
        !widget.disabled && !(scope?.disabled ?? false) && callback != null;
    final checked = selection == widget.value;

    // Three traps ride on this one line.
    //
    // 1. `enabled` — the SDK's `_SkipUnselectedRadioPolicy` skips every radio
    //    except the SELECTED one, and does *not* filter on enabled. Registering
    //    a disabled radio that happens to be the selection therefore leaves the
    //    group with one focus candidate that refuses focus, i.e. entirely
    //    unreachable by Tab. Unregistered, it is invisible to the policy, which
    //    falls back to the first registered radio in reading order.
    // 2. The overrides — a radio carrying its own `groupValue` or `onChanged`
    //    is not part of this group's mutually exclusive set, and the registry's
    //    keyboard paths (`_toggleFocusedRadio`, `_selectRadioInDirection`) all
    //    report through the GROUP's callback, which would bypass the override.
    //    Staying out of the registry keeps the override authoritative.
    // 3. `group` being null — a standalone `FluentRadio` (a tree row, a list
    //    item, a data-grid selector) has no `RadioGroup` above it and keeps
    //    working exactly as before, unregistered.
    registry = enabled && widget.groupValue == null && widget.onChanged == null
        ? group
        : null;

    final state = resolveFluentRadioState(
      enabled: enabled,
      checked: checked,
      labelPosition:
          widget.labelPosition ??
          scope?.labelPosition ??
          FluentRadioLabelPosition.after,
      label: widget.label,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentRadioStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentRadioTheme.maybeOf(context)).merge(widget.style);

    final radio = Shortcuts(
      // No semantics of its own: this node exists only to intercept a key, and
      // a `focusable: false` annotation between the radio's own `Semantics` and
      // its `FocusableActionDetector` would split the radio into two nodes.
      includeSemantics: false,
      shortcuts: _spaceActivates,
      child: FluentInteractive(
        enabled: enabled,
        // Re-selecting the selected radio still reports the value. Harmless and
        // idempotent, and it keeps the callback contract "this is the selection
        // now" rather than "the selection changed", which is what a caller
        // assigning straight to state wants.
        onPressed: enabled ? () => callback(widget.value) : null,
        focusNode: focusNode,
        autofocus: widget.autofocus,
        mouseCursor:
            resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
            SystemMouseCursors.click,
        builder: (context, states, _) =>
            buildFluentRadio(state, resolved, states),
      ),
    );

    final semantics = Semantics(
      inMutuallyExclusiveGroup: true,
      checked: checked,
      enabled: enabled,
      label: widget.semanticLabel,
      child: radio,
    );

    // A fourth consequence of the same opt-out. `RadioGroup` contributes a
    // `SemanticsRole.radioGroup` node, and the framework validates it: two
    // checked `inMutuallyExclusiveGroup` descendants under one radiogroup throw
    // "Radio groups must not have multiple checked children"
    // (`semantics.dart:338` at 3.41, from the assert at `semantics.dart:4011`).
    // A radio with its own `groupValue` can be checked at the same time as the
    // group's own selection, so before this the documented override crashed any
    // debug build with a screen reader running.
    //
    // The validator is not wrong — it is wrong ARIA — so give the opted-out
    // radio the nested radiogroup it actually is. That is also exactly what the
    // validator looks for to stop descending (`semantics.dart:328`).
    if (group == null || widget.groupValue == null) return semantics;
    return Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      child: semantics,
    );
  }
}
