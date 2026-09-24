import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import '../internal/text_context_menu.dart';
import '../internal/text_selection_dismiss.dart';
import 'input_style.dart';

/// How an input is filled and outlined. Figma's `Style` axis.
enum FluentInputAppearance {
  /// Neutral fill, a border on all four sides, and an accessible-contrast rule
  /// along the bottom edge. The default.
  outline,

  /// No fill and no box border — only the bottom rule.
  underline,

  /// `neutralBackground3` fill with an invisible border.
  filledDarker,

  /// `neutralBackground1` fill with an invisible border.
  filledLighter,
}

/// Input height and type ramp. Figma's `Size` axis.
enum FluentInputSize {
  /// 24 high, `caption1`.
  small,

  /// 32 high, `body1`. The default.
  medium,

  /// 40 high, `body2`.
  large,
}

/// The focus bar growing in, measured on the live storybook.
///
/// Upstream's `:focus-within::after` sets `transform: scaleX(1)`,
/// `transitionProperty: transform` and `transitionDuration: durationNormal`.
///
/// **The easing is CSS `ease`, not a Fluent curve.** The same block writes
/// `transitionDelay: tokens.curveDecelerateMid` — a curve in the *delay* slot.
/// That is invalid at computed-value time, so Chrome computes
/// `transition-delay: 0s` and leaves `transition-timing-function` at its
/// initial `ease`. `document.getAnimations()` reports exactly that (`200ms`,
/// `ease`, delay 0), and the sampled scale at 20ms steps is `0, .095, .295,
/// .513, .683, .802, …` — [FluentCssCubic.ease], which is CSS's
/// `cubic-bezier(.25, .1, .25, 1)`. Every sibling that reuses this bar
/// (Textarea, SearchBox, Dropdown, Combobox, TagPicker, SpinButton, DatePicker,
/// TimePicker) ships the same typo and the same `ease`. This ports what
/// renders, not what the typo suggests was meant.
const FluentMotionSpec fluentInputFocusUnderlineEnter = FluentMotionSpec(
  duration: FluentDuration.normal,
  curve: FluentCssCubic.ease,
);

/// The focus bar shrinking out.
///
/// Upstream's base `::after` rule: `transform: scaleX(0)` at
/// `durationUltraFast`, four times quicker than the entrance, on `ease` for the
/// same reason as [fluentInputFocusUnderlineEnter].
const FluentMotionSpec fluentInputFocusUnderlineExit = FluentMotionSpec(
  duration: FluentDuration.ultraFast,
  curve: FluentCssCubic.ease,
);

/// Everything needed to render an input, independent of appearance and size.
///
/// The Dart counterpart of upstream's `InputState` minus its two design axes.
/// [buildFluentInput] takes this rather than [FluentInputState], which is what
/// makes "Fluent's state, my own styling, Fluent's rendering" a supported path
/// rather than a fork.
@immutable
class FluentInputBaseState {
  /// Creates a base state.
  const FluentInputBaseState({
    required this.enabled,
    required this.readOnly,
    required this.error,
    required this.focused,
    required this.controller,
    required this.focusNode,
    required this.editableTextKey,
    this.placeholder,
    this.contentBefore,
    this.contentAfter,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.autofillHints,
  });

  /// Whether the field accepts input at all.
  final bool enabled;

  /// Whether the value can be selected and copied but not edited.
  ///
  /// A separate axis from [enabled]: a read-only field still takes focus.
  final bool readOnly;

  /// Whether the field is showing a validation error. Figma's `State=Error`,
  /// upstream's `aria-invalid="true"`.
  final bool error;

  /// Whether the field currently holds focus.
  ///
  /// **Not** `WidgetState.focused`, which in this package means
  /// *keyboard-visible* focus. A text field's brand underline has to appear
  /// when focus arrives by click as well, so real focus is an axis on the state
  /// rather than an interaction state — the same call
  /// `FluentTag` makes about `selected`.
  final bool focused;

  /// The value being edited.
  final TextEditingController controller;

  /// The node this field's focus is tracked on.
  final FocusNode focusNode;

  /// Identifies the [EditableText] for the selection gesture machinery.
  final GlobalKey<EditableTextState> editableTextKey;

  /// Shown while the value is empty.
  final Widget? placeholder;

  /// Slot before the field in reading order — an icon, a prefix, a button.
  final Widget? contentBefore;

  /// Slot after the field in reading order.
  final Widget? contentAfter;

  /// Whether characters are replaced by the obscuring character.
  final bool obscureText;

  /// Maximum rendered lines, or null to grow without bound.
  final int? maxLines;

  /// Minimum rendered lines.
  final int? minLines;

  /// Which soft keyboard to request.
  final TextInputType? keyboardType;

  /// The soft keyboard's action key.
  final TextInputAction? textInputAction;

  /// Invoked on every edit.
  final ValueChanged<String>? onChanged;

  /// Invoked when the action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Autofill categories for this field, e.g. `[AutofillHints.username]`.
  ///
  /// On web these become the `autocomplete` attribute of the DOM input the
  /// engine creates, which is the only thing a browser password manager keys
  /// off. Wrap the fields in an [AutofillGroup] as well: the engine only emits
  /// a real `<form>` — and browsers only offer to fill or save a credential
  /// PAIR — when the fields share one.
  final Iterable<String>? autofillHints;

  /// Whether the placeholder should be painted, as of this instant.
  ///
  /// A snapshot, not a subscription: [buildFluentInput] watches [controller]
  /// instead, because the widgets that own their own controller do not rebuild
  /// on every keystroke.
  bool get placeholderVisible => placeholder != null && controller.text.isEmpty;
}

/// An input's fully resolved state, including the design axes.
@immutable
class FluentInputState extends FluentInputBaseState {
  /// Creates a resolved state.
  const FluentInputState({
    required super.enabled,
    required super.readOnly,
    required super.error,
    required super.focused,
    required super.controller,
    required super.focusNode,
    required super.editableTextKey,
    required this.appearance,
    required this.size,
    super.placeholder,
    super.contentBefore,
    super.contentAfter,
    super.obscureText,
    super.maxLines,
    super.minLines,
    super.keyboardType,
    super.textInputAction,
    super.onChanged,
    super.onSubmitted,
    super.autofocus,
    super.autofillHints,
  });

  /// Fill and outline treatment.
  final FluentInputAppearance appearance;

  /// Height and type ramp.
  final FluentInputSize size;
}

/// Builds the state an input will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentInputState resolveFluentInputState({
  required TextEditingController controller,
  required FocusNode focusNode,
  required GlobalKey<EditableTextState> editableTextKey,
  bool enabled = true,
  bool readOnly = false,
  bool error = false,
  bool focused = false,
  FluentInputAppearance appearance = FluentInputAppearance.outline,
  FluentInputSize size = FluentInputSize.medium,
  Widget? placeholder,
  Widget? contentBefore,
  Widget? contentAfter,
  bool obscureText = false,
  int? maxLines = 1,
  int? minLines,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  bool autofocus = false,
  Iterable<String>? autofillHints,
}) => FluentInputState(
  enabled: enabled,
  readOnly: readOnly,
  error: error,
  focused: focused,
  controller: controller,
  focusNode: focusNode,
  editableTextKey: editableTextKey,
  appearance: appearance,
  size: size,
  placeholder: placeholder,
  contentBefore: contentBefore,
  contentAfter: contentAfter,
  obscureText: obscureText,
  maxLines: maxLines,
  minLines: minLines,
  keyboardType: keyboardType,
  textInputAction: textInputAction,
  onChanged: onChanged,
  onSubmitted: onSubmitted,
  autofocus: autofocus,
  autofillHints: autofillHints,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// The oracle is upstream as it renders — `useInputStyles.styles.ts` measured
/// in Chrome on the live storybook — not the Figma `Input` set. Where the two
/// disagree, upstream wins:
///
/// * **Read only has no styling.** Upstream passes `readOnly` straight to the
///   `<input>`; the root keeps every interactive rule. Only
///   [FluentInputBaseState.enabled] changes the ramp.
/// * **Focus moves the outline border.** `outlineInteractive` writes
///   `:active,:focus-within` as one rule, which Griffel sorts after `:hover`,
///   so a focused field shows `Stroke1Pressed` / `StrokeAccessiblePressed`
///   whether or not it is hovered.
/// * **The bottom border is a border.** 1px in every state, joined to the sides
///   on the CSS corner diagonal by [FluentInputBorderPainter].
/// * **Invalid is `colorPaletteRedBorder2`**, not the status danger token.
FluentInputStyle resolveFluentInputStyle(
  FluentInputState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final disabled = !state.enabled;
  final focused = state.focused;
  final filled =
      state.appearance == FluentInputAppearance.filledDarker ||
      state.appearance == FluentInputAppearance.filledLighter;
  final underline = state.appearance == FluentInputAppearance.underline;
  // `colorPaletteRedBorder2`. The palette layer knows nothing of high contrast,
  // where the status token is the system text colour instead.
  final danger = c is FluentHighContrastColors
      ? c.statusDangerBorder2
      : c.palette.stroke2Rest(FluentPaletteFamily.red)!;

  final background = switch (state.appearance) {
    _ when disabled => c.transparentBackground,
    FluentInputAppearance.underline => c.transparentBackground,
    FluentInputAppearance.filledDarker => c.neutralBackground3,
    FluentInputAppearance.outline ||
    FluentInputAppearance.filledLighter => c.neutralBackground1,
  };

  // The box outline. Underline has none at all — its only rule is the bottom
  // one below, which is why `borderWidth` goes to zero rather than the colour
  // going transparent: a zero-width border cannot reappear in high contrast.
  //
  // The error branch is gated on focus because upstream gates it:
  // `useInputStyles.styles.ts` writes the danger colour under
  // `':not(:focus-within),:hover:not(:focus-within)'`, so a focused invalid
  // field falls back to the ordinary ramp and the brand bar is what marks it.
  final WidgetStateProperty<Color>? border;
  if (underline) {
    border = null;
  } else if (disabled) {
    border = FluentStateColor.tokens(rest: c.neutralStrokeDisabled);
  } else if (state.error && !focused) {
    border = FluentStateColor.tokens(rest: danger);
  } else if (filled) {
    // `filledInteractive` moves both `:hover` and `:focus-within` (and
    // therefore `:active`) to the Interactive token.
    border = FluentStateColor.tokens(
      rest: focused ? c.transparentStrokeInteractive : c.transparentStroke,
      hover: c.transparentStrokeInteractive,
      pressed: c.transparentStrokeInteractive,
    );
  } else {
    // Focus holds the Pressed stop through a hover: see the doc comment.
    border = FluentStateColor.tokens(
      rest: focused ? c.neutralStroke1Pressed : c.neutralStroke1,
      hover: focused ? c.neutralStroke1Pressed : c.neutralStroke1Hover,
      pressed: c.neutralStroke1Pressed,
    );
  }

  // The bottom border. Filled appearances have none of their own — their
  // transparent box border runs round all four sides; on Outline it is the
  // accessible-contrast bottom side, on Underline it is the only side.
  final WidgetStateProperty<Color>? bottomBorder;
  if (filled) {
    bottomBorder = null;
  } else if (disabled) {
    bottomBorder = FluentStateColor.tokens(rest: c.neutralStrokeDisabled);
  } else if (state.error && !focused) {
    bottomBorder = FluentStateColor.tokens(rest: danger);
  } else {
    bottomBorder = FluentStateColor.tokens(
      rest: focused
          ? c.neutralStrokeAccessiblePressed
          : c.neutralStrokeAccessible,
      hover: focused
          ? c.neutralStrokeAccessiblePressed
          : c.neutralStrokeAccessibleHover,
      pressed: c.neutralStrokeAccessiblePressed,
    );
  }

  final (height, textStyle, inset, iconSize, gap) = switch (state.size) {
    FluentInputSize.small => (
      24.0,
      theme.typography.caption1,
      FluentSpacing.sNudge,
      FluentSize.size160,
      FluentSpacing.xxs,
    ),
    FluentInputSize.medium => (
      32.0,
      theme.typography.body1,
      FluentSpacing.mNudge,
      FluentSize.size200,
      FluentSpacing.xxs,
    ),
    FluentInputSize.large => (
      40.0,
      theme.typography.body2,
      FluentSpacing.m,
      FluentSize.size240,
      FluentSpacing.sNudge,
    ),
  };

  return FluentInputStyle(
    backgroundColor: WidgetStatePropertyAll<Color?>(background),
    borderColor: border,
    borderWidth: WidgetStatePropertyAll<double?>(
      underline ? FluentStroke.none : FluentStroke.thin,
    ),
    // Underline zeroes both the root's radius and the focus bar's
    // (`underlineInteractive`'s `::after { borderRadius: 0 }`): a flat rule
    // with square ends.
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(
      underline ? BorderRadius.zero : FluentRadius.allMedium,
    ),
    bottomBorderColor: bottomBorder,
    // 1px on every appearance and in every state: upstream recolours the
    // bottom border on press, it never thickens it. Unconditional, so a caller
    // colouring only the bottom of a filled field keeps its 1px; with no
    // bottom colour the side colour and width run round instead.
    bottomBorderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    // Upstream's disabled rule is `::after { content: unset }` — a disabled
    // field has no focus bar at all. Read only keeps one: it still takes focus.
    focusUnderlineColor: disabled
        ? null
        : FluentStateColor.tokens(
            rest: c.compoundBrandStroke,
            pressed: c.compoundBrandStrokePressed,
          ),
    foregroundColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground1,
    ),
    placeholderColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground4,
    ),
    contentColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground3,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: inset),
    ),
    // Upstream splits the inset per side — the `<input>` carries 8 / 12 / 18
    // on a side with no slot, and 2 / 2 / 6 plus a 6 / 10 / 12 root padding on
    // a side with one. Both sums are the same, so a symmetric root [padding]
    // plus this (equal to [gap]) lands the text and the slots on upstream's
    // pixels with or without content, inside the border.
    contentPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: gap),
    ),
    gap: WidgetStatePropertyAll<double?>(gap),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    cursorColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground1,
    ),
    // The one value Fluent does not specify: neither the Figma file nor
    // `useInputStyles.styles.ts` names a selection colour, so the browser's own
    // highlight is what upstream ships. `brandBackground2` is the palette's
    // subtle brand wash and is the closest real token; override it through
    // `style` if a host app has its own.
    selectionColor: FluentStateColor.tokens(rest: c.brandBackground2),
    mouseCursor: WidgetStatePropertyAll<MouseCursor?>(
      disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.text,
    ),
  );
}

/// Renders an input from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentInputBaseState] rather than [FluentInputState] on purpose: it never
/// reads appearance or size, so a consumer can supply their own style and still
/// use Fluent's layout, border and focus animation.
///
/// The result is *chrome plus an [EditableText]* — it carries no gesture
/// recognisers, so a caller placing it by hand must wrap it in a
/// [TextSelectionGestureDetectorBuilder] the way [FluentInput] does, or taps
/// will not move the caret.
///
/// It does carry a [TextFieldTapRegion] around the whole faceplate, so the
/// chrome counts as part of the field for tap-outside purposes. The selection
/// highlight is gated on [FluentInputBaseState.focused]; a caller driving this
/// function by hand must keep that flag honest or a blurred field will stay
/// lit.
///
/// [states] is the live interaction set: hovered, pressed and disabled.
Widget buildFluentInput(
  FluentInputBaseState state,
  FluentInputStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final background = style.backgroundColor?.resolve(states);
  final bottomColor = style.bottomBorderColor?.resolve(states);
  final bottomWidth =
      style.bottomBorderWidth?.resolve(states) ?? FluentStroke.none;
  final focusColor = style.focusUnderlineColor?.resolve(states);
  final focusWidth =
      style.focusUnderlineWidth?.resolve(states) ?? FluentStroke.thick;
  final foreground = style.foregroundColor?.resolve(states);
  final placeholderColor = style.placeholderColor?.resolve(states);
  final contentColor = style.contentColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states) ?? const TextStyle();
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final contentPadding =
      style.contentPadding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xxs;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  final cursorColor = style.cursorColor?.resolve(states);
  final selectionColor = style.selectionColor?.resolve(states);
  final mouseCursor = style.mouseCursor?.resolve(states);

  final valueStyle = textStyle.copyWith(color: foreground);

  Widget field = EditableText(
    key: state.editableTextKey,
    controller: state.controller,
    focusNode: state.focusNode,
    autofocus: state.autofocus,
    readOnly: state.readOnly || !state.enabled,
    obscureText: state.obscureText,
    style: valueStyle,
    // Fluent has no caret token, so the caret takes the text colour — which is
    // exactly what a browser does with no `caret-color` declared, and what
    // upstream therefore ships.
    cursorColor: cursorColor ?? foreground ?? const Color(0xFF000000),
    // The browser's caret is 1px; `EditableText`'s default is 2.
    cursorWidth: FluentStroke.thin,
    // iOS floating-cursor ghost. Deliberately the placeholder tone rather than
    // a computed grey.
    backgroundCursorColor: placeholderColor ?? const Color(0x00000000),
    // Gated on focus, because nulling this colour is the ONLY way Flutter stops
    // painting a selection: blur leaves `controller.selection` alone and the
    // highlight painter has no focus term, so an ungated colour keeps the
    // selection lit after the user has clicked away. `TextField` does the same
    // at `material/text_field.dart:1714`, `CupertinoTextField` at
    // `cupertino/text_field.dart:1597`.
    selectionColor: state.focused ? selectionColor : null,
    selectionControls: fluentTextSelectionControls,
    contextMenuBuilder: fluentTextContextMenuBuilder,
    enableInteractiveSelection: state.enabled,
    maxLines: state.maxLines,
    minLines: state.minLines,
    keyboardType: state.keyboardType,
    textInputAction: state.textInputAction,
    onChanged: state.onChanged,
    onSubmitted: state.onSubmitted,
    // The gesture detector built by `FluentInput` owns pointer handling.
    rendererIgnoresPointer: true,
    // `EditableText` installs a region of its own that defaults to the text
    // cursor, and the innermost region wins: without this a disabled field
    // showed `text` over its value where upstream shows `not-allowed`.
    mouseCursor: mouseCursor,
    showCursor: state.enabled && !state.readOnly,
    autofillHints: state.autofillHints,
  );

  if (state.placeholder != null) {
    field = Stack(
      children: <Widget>[
        field,
        Positioned.fill(
          child: IgnorePointer(
            // Subscribed to the controller rather than read once at build time.
            // Visibility is a function of live text, and only `FluentInput`
            // rebuilds on every keystroke — `FluentDatePicker` and
            // `FluentTimePicker` own their controller and do not, so a
            // build-time read left the placeholder painted over typed text.
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: state.controller,
              builder: (context, value, child) =>
                  value.text.isEmpty ? child! : const SizedBox.shrink(),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: DefaultTextStyle(
                  style: textStyle.copyWith(color: placeholderColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: state.placeholder!,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? slot(Widget? child) => child == null
      ? null
      : IconTheme.merge(
          data: IconThemeData(color: contentColor, size: iconSize),
          child: DefaultTextStyle.merge(
            style: textStyle.copyWith(color: contentColor),
            child: child,
          ),
        );

  final row = Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    spacing: gap,
    children: <Widget>[
      ?slot(state.contentBefore),
      Expanded(
        child: Padding(padding: contentPadding, child: field),
      ),
      ?slot(state.contentAfter),
    ],
  );

  // CSS box model: a border that exists takes space, so the content sits inside
  // it — 1px on every side for outline and the filled appearances (whose
  // transparent border still counts), the bottom only for underline. A null
  // colour is no border at all.
  final side = borderColor == null ? FluentStroke.none : borderWidth;
  final widths = EdgeInsets.fromLTRB(
    side,
    side,
    side,
    bottomColor == null ? side : bottomWidth,
  );
  final ruleRadius = BorderRadius.only(
    bottomLeft: radius.bottomLeft,
    bottomRight: radius.bottomRight,
  );

  // The chrome is built AROUND the `EditableText`, so it sits outside the
  // region `EditableText` installs for itself (`editable_text.dart:5849`).
  // Without this wrapper a pointer landing on the padding, the border or a
  // `contentBefore`/`contentAfter` slot reads as a tap *outside* the field and
  // `_EditableTextTapOutsideAction` drops focus on pointer-down — the gesture
  // detector then takes it back on pointer-up, so today it only flickers, but
  // an interactive trailing slot would unmount under the cursor between press
  // and release. `TextField` wraps its whole decorated field the same way
  // (`material/text_field.dart:1801`), and `textarea.dart`, `search_box.dart`
  // and `spin_button.dart` each carry the same wrapper around their own
  // faceplate. Every one of them uses the default group id — the `EditableText`
  // Type — so nesting is a no-op, which is what lets the pickers wrap this
  // result again for their popups.
  return TextFieldTapRegion(
    child: Stack(
      // Passthrough, so a parent's tight height stretches the box itself, as a
      // CSS `height` would. A loose Stack laid the box out at its own height and
      // pinned the bar to the bottom of the taller Stack, below it.
      fit: StackFit.passthrough,
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minimumSize.height,
            minWidth: minimumSize.width,
          ),
          // Background, then border, then content, then the focus bar below:
          // CSS's paint order for a root and its positioned `::after`.
          child: DecoratedBox(
            decoration: BoxDecoration(color: background, borderRadius: radius),
            child: CustomPaint(
              painter: FluentInputBorderPainter(
                radius: radius,
                borderColor: borderColor,
                borderWidth: side,
                bottomBorderColor: bottomColor,
                bottomBorderWidth: widths.bottom,
              ),
              child: Padding(padding: padding.add(widths), child: row),
            ),
          ),
        ),
        if (focusColor != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: focusWidth,
            child: FluentInputFocusUnderline(
              focused: state.focused,
              color: focusColor,
              thickness: focusWidth,
              borderRadius: ruleRadius,
            ),
          ),
      ],
    ),
  );
}

/// The brand bar that grows across the bottom of a focused input.
///
/// Upstream animates it as `transform: scaleX(0 → 1)` on the root's `::after`
/// pseudo-element, with a **different duration per direction**, which is why
/// this is a raw [AnimationController] rather than a [FluentAnimatedStyle]:
/// that widget carries one [FluentMotionSpec], and this needs two —
/// [fluentInputFocusUnderlineEnter] and [fluentInputFocusUnderlineExit].
///
/// A focus change mid-flight follows CSS transitions exactly: a new `ease`
/// transition starts from the current scale and runs for the direction's
/// duration times the distance left to cover (CSS's *reversing shortening
/// factor*, which is `|target − current|` for a 0↔1 property). Blurring 100ms
/// into the entrance, at scale .802, retracts over 40ms — as measured in
/// Chrome. [AnimationController.animateTo] computes the same duration.
///
/// Reduced motion collapses both to [Duration.zero], matching upstream's own
/// `prefers-reduced-motion` clamp to `0.01ms`.
class FluentInputFocusUnderline extends StatefulWidget {
  /// Creates a focus bar.
  const FluentInputFocusUnderline({
    super.key,
    required this.focused,
    required this.color,
    this.borderRadius = BorderRadius.zero,
    this.thickness = FluentStroke.thick,
  });

  /// Whether the field holds focus. The bar is fully grown while true.
  final bool focused;

  /// The bar's colour — `compoundBrandStroke`, or its Pressed sibling.
  final Color color;

  /// The bar's own corner radius: the container's two bottom corners.
  final BorderRadius borderRadius;

  /// The bar's own height. The painted rect is grown to at least the corner
  /// radius and clipped back to this, which is the only way a radius larger
  /// than the bar survives.
  final double thickness;

  @override
  State<FluentInputFocusUnderline> createState() =>
      _FluentInputFocusUnderlineState();
}

class _FluentInputFocusUnderlineState extends State<FluentInputFocusUnderline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.focused ? 1 : 0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set on every change, not only when reduced motion turns on, so turning it
    // back off restores the real durations.
    final reduced = MediaQuery.disableAnimationsOf(context);
    _controller
      ..duration = reduced
          ? Duration.zero
          : fluentInputFocusUnderlineEnter.duration
      ..reverseDuration = reduced
          ? Duration.zero
          : fluentInputFocusUnderlineExit.duration;
    // Setting `value` stops the ticker as well as jumping, so nothing is left
    // scheduled when reduced motion is switched on mid-flight.
    if (reduced && _controller.isAnimating) {
      _controller.value = widget.focused ? 1 : 0;
    }
  }

  @override
  void didUpdateWidget(FluentInputFocusUnderline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focused == oldWidget.focused) return;
    // Not forward()/reverse() on a CurvedAnimation: that retraces the old
    // curve backwards. These restart the curve from wherever the bar is.
    if (widget.focused) {
      _controller.animateTo(1, curve: fluentInputFocusUnderlineEnter.curve);
    } else {
      _controller.animateBack(0, curve: fluentInputFocusUnderlineExit.curve);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    // CSS `scaleX` has its origin at 50%, so the bar grows out from the middle
    // in both directions rather than sweeping in from one edge.
    builder: (context, child) =>
        Transform.scale(scaleX: _controller.value, child: child),
    child: FluentInputUnderline(
      color: widget.color,
      thickness: widget.thickness,
      borderRadius: widget.borderRadius,
    ),
  );
}

/// A rule pinned to a field's bottom edge that keeps the field's corner radius.
///
/// This is the body of the 2px focus accent that [FluentInputFocusUnderline]
/// animates, and that is its only use: every field's resting bottom border is
/// painted by [FluentInputBorderPainter], joined to the sides the way CSS
/// joins them. The rule cannot simply draw a rounded box, because a corner
/// radius larger than the rule is thick cannot survive on its own — Skia
/// scales every radius by `min(edge / sum-of-radii-on-that-edge)`, so a 4px
/// corner on a 2px bar ships as 2, half of that is lost to the bar's own
/// height, and the ends read square against a rounded field.
///
/// React hits the identical CSS clamp and answers it the same way
/// (`useDropdownStyles.styles.ts:45`): draw the pseudo-element at
/// `max(strokeWidthThick, borderRadiusMedium)` tall, put the radii on its
/// bottom corners, then trim it back with
/// `clipPath: inset(calc(100% - 2px) 0 0 0)`. The source comment there says
/// why outright — *"Use the whole border-radius as the height ... Otherwise the
/// radius would be automatically reduced to fit available space."*
///
/// The parent keeps the layout slot at [thickness]; only the painted rect grows.
class FluentInputUnderline extends StatelessWidget {
  /// Creates a rule [thickness] tall that paints on [borderRadius].
  const FluentInputUnderline({
    super.key,
    required this.color,
    required this.thickness,
    this.borderRadius = BorderRadius.zero,
  });

  /// The rule's colour.
  final Color color;

  /// The rule's height in layout. The painted rect may be taller.
  final double thickness;

  /// The field's bottom corners, which the rule's ends follow.
  final BorderRadius borderRadius;

  /// How tall the rule is painted before the clip trims it back.
  double get _paintedHeight => math.max(thickness, _maxRadius(borderRadius));

  @override
  Widget build(BuildContext context) => ClipRect(
    child: OverflowBox(
      alignment: Alignment.bottomCenter,
      // Both bounds, not just the maximum: a childless [DecoratedBox] is a
      // [RenderProxyBox], which sizes to `constraints.smallest`, so a loose
      // maximum alone would leave it at the incoming thickness.
      minHeight: _paintedHeight,
      maxHeight: _paintedHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      ),
    ),
  );
}

/// Paints an input's box border the way a browser paints a CSS border whose
/// bottom side differs in colour from the other three.
///
/// Upstream's outline field is `border: 1px solid Stroke1` with
/// `borderBottomColor: StrokeAccessible` on a 4px radius. A browser splits two
/// adjacent border colours along the line from the corner of the border box to
/// the corner of the padding box — 45° when the widths match — so the darker
/// bottom colour climbs roughly half-way round each bottom arc. Flutter's
/// [Border] refuses a radius on sides of differing colour, and a thin strip
/// overlaid on a uniform border stops the bottom colour a pixel up the arc,
/// which is visible at every device pixel ratio.
///
/// Each colour is painted once, as the ring between the outer rounded
/// rectangle and the inner one (radii reduced per side by the border width,
/// as CSS does), clipped to its own side of the diagonals. Painting one colour
/// over the other would double-cover the anti-aliased edge pixels.
///
/// Public, with its fields, so tests can read the resolved tones directly —
/// the same reason `FluentRadioIndicatorPainter` is.
class FluentInputBorderPainter extends CustomPainter {
  /// Creates a border painter.
  const FluentInputBorderPainter({
    required this.radius,
    required this.borderColor,
    required this.borderWidth,
    required this.bottomBorderColor,
    required this.bottomBorderWidth,
  });

  /// The field's outer corner radii.
  final BorderRadius radius;

  /// The top, left and right sides — and the bottom as well when
  /// [bottomBorderColor] is null. Null paints no sides.
  final Color? borderColor;

  /// Width of the top, left and right sides.
  final double borderWidth;

  /// The bottom side, or null when it matches [borderColor].
  final Color? bottomBorderColor;

  /// Width of the bottom side.
  final double bottomBorderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    // No colour is no border, whatever the width says.
    final side = borderColor == null ? 0.0 : borderWidth;
    // Scaled like CSS, so an oversized radius cannot overlap itself.
    final outer = radius.toRRect(bounds).scaleRadii();
    final inner = EdgeInsets.fromLTRB(
      side,
      side,
      side,
      bottomBorderWidth,
    ).deflateRRect(outer);
    void ring(Color? color) {
      if (color == null) return;
      canvas.drawDRRect(outer, inner, Paint()..color = color);
    }

    final bottom = bottomBorderColor;
    if (bottom == null || bottom == borderColor || bottomBorderWidth == 0) {
      ring(borderColor);
      return;
    }
    if (side == 0) {
      ring(bottom);
      return;
    }

    // The join runs along (side, -bottomBorderWidth) from each bottom
    // corner. It starts outside the box, so the outer anti-aliased edge is
    // never clipped, and rises until it clears the corner arc.
    final reach = math.max(
      1.0,
      math.max(outer.blRadiusY, outer.brRadiusY) / bottomBorderWidth,
    );
    final w = size.width;
    final h = size.height;
    // ponytail: the trapezoid self-intersects on a field narrower than
    // 2 × side × reach (8px at the defaults); nothing ships that small.
    final join = Path()
      ..addPolygon(<Offset>[
        Offset(-side, h + bottomBorderWidth),
        Offset(side * reach, h - bottomBorderWidth * reach),
        Offset(w - side * reach, h - bottomBorderWidth * reach),
        Offset(w + side, h + bottomBorderWidth),
      ], true);

    canvas
      ..save()
      ..clipPath(join);
    ring(bottom);
    canvas
      ..restore()
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(bounds.inflate(side + bottomBorderWidth))
          ..addPath(join, Offset.zero),
      );
    ring(borderColor);
    canvas.restore();
  }

  // Hit-testing stays with the rounded background box underneath; a painter
  // answers for its whole rectangle, corners included.
  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(FluentInputBorderPainter oldDelegate) =>
      radius != oldDelegate.radius ||
      borderColor != oldDelegate.borderColor ||
      borderWidth != oldDelegate.borderWidth ||
      bottomBorderColor != oldDelegate.bottomBorderColor ||
      bottomBorderWidth != oldDelegate.bottomBorderWidth;
}

/// The largest corner radius on [radius], which is how tall the bar has to be
/// painted for that corner to survive Skia's scaling.
double _maxRadius(BorderRadius radius) => math.max(
  math.max(radius.bottomLeft.y, radius.bottomRight.y),
  math.max(radius.topLeft.y, radius.topRight.y),
);

/// Fluent's text selection handles.
///
/// Neither the Figma file nor `react-input` draws a selection handle — the web
/// uses the browser's own, and there is no Fluent asset to transcribe. This
/// draws the plainest thing that reads correctly: a filled
/// `compoundBrandStroke` disc hanging below the selection edge, anchored so it
/// points at the character boundary.
///
/// ponytail: a plain disc, not Material's teardrop. Give it a directional point
/// if a design ever specifies one.
/// The [TextSelectionHandleControls] mixin is load-bearing, not decoration.
/// `TextSelectionOverlay.showToolbar` branches on it: with plain
/// [TextSelectionControls] it takes the legacy path and builds the toolbar from
/// [buildToolbar], and `EditableText.contextMenuBuilder` — where Fluent's menu
/// actually lives — is never consulted. Painting handles but no toolbar has to
/// be declared by *type*; returning an empty widget from [buildToolbar] is not
/// enough, and leaves every Fluent text control with no context menu at all.
class FluentTextSelectionControls extends TextSelectionControls
    with TextSelectionHandleControls {
  /// Creates a handle painter. Prefer [fluentTextSelectionControls].
  FluentTextSelectionControls();

  /// Handle diameter.
  static const double handleSize = 16;

  @override
  Size getHandleSize(double textLineHeight) =>
      const Size(handleSize, handleSize);

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      switch (type) {
        // The left handle hangs off the left of its anchor and the right handle
        // off the right, so neither covers the character it marks.
        TextSelectionHandleType.left => const Offset(handleSize, 0),
        TextSelectionHandleType.right => Offset.zero,
        TextSelectionHandleType.collapsed => const Offset(handleSize / 2, 0),
      };

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    final color = FluentTheme.of(context).colors.compoundBrandStroke;
    return GestureDetector(
      onTapDown: (_) => onTap?.call(),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: handleSize,
        height: handleSize,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  // No `buildToolbar` override: the mixin already returns an empty widget, and
  // does it without reaching for a deprecated member. Fluent's context menu is
  // a Menu surface, not a text-selection toolbar, so it arrives through
  // `EditableText.contextMenuBuilder`.
}

/// The shared [FluentTextSelectionControls], mirroring Material's
/// `materialTextSelectionControls`.
///
/// One instance rather than a fresh object per build: [EditableText] compares
/// `selectionControls` by identity when deciding whether to rebuild its
/// selection overlay.
final FluentTextSelectionControls fluentTextSelectionControls =
    FluentTextSelectionControls();

/// Overrides the input style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentInputTheme extends InheritedTheme {
  /// Applies [style] to every `FluentInput` in [child].
  const FluentInputTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentInputStyle style;

  /// The nearest input style, or null.
  static FluentInputStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentInputTheme>()?.style;

  @override
  bool updateShouldNotify(FluentInputTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentInputTheme(style: style, child: child);
}

/// A Fluent 2 single-line text field.
///
/// ```dart
/// FluentInput(
///   controller: controller,
///   placeholder: const Text('Search'),
///   contentBefore: const Icon(FluentIcons.search_20_regular),
///   onSubmitted: search,
/// )
/// ```
///
/// Built directly on [EditableText] — `package:flutter/material.dart` is not a
/// dependency of this package, so `TextField` does not exist here. Caret
/// placement, drag selection, double-tap word selection and long-press come
/// from [TextSelectionGestureDetectorBuilder], the widgets-layer machinery
/// `TextField` itself uses; the handles come from
/// [FluentTextSelectionControls].
///
/// Pass `enabled: false` to disable it — disabled is a real state here, not a
/// visual treatment: the field stops reporting hover and press, refuses edits,
/// swaps to the disabled token ramp wholesale, and loses its focus bar
/// entirely, matching upstream's `::after { content: unset }`.
///
/// **There is no focus ring.** Upstream writes
/// `:focus-within { outline: 2px solid transparent }` — deliberately
/// suppressing the shared ring — and Figma's twelve `State=Focus` variants draw
/// only the brand bar. The growing underline *is* the focus indicator.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentInputTheme] restyles a subtree; and for anything further,
/// [resolveFluentInputState], [resolveFluentInputStyle] and [buildFluentInput]
/// are public so any one of them can be replaced without forking this widget.
class FluentInput extends StatefulWidget {
  /// Creates a text field.
  const FluentInput({
    super.key,
    this.controller,
    this.focusNode,
    this.appearance = FluentInputAppearance.outline,
    this.size = FluentInputSize.medium,
    this.placeholder,
    this.contentBefore,
    this.contentAfter,
    this.enabled = true,
    this.readOnly = false,
    this.error = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.autofillHints,
    this.style,
    this.semanticLabel,
  });

  /// The value being edited. One is created internally when omitted.
  final TextEditingController? controller;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Fill and outline treatment.
  final FluentInputAppearance appearance;

  /// Height and type ramp.
  final FluentInputSize size;

  /// Shown while the value is empty.
  final Widget? placeholder;

  /// Slot before the field in reading order — an icon, a prefix, a button.
  final Widget? contentBefore;

  /// Slot after the field in reading order.
  final Widget? contentAfter;

  /// Whether the field accepts input. False is a real disabled state.
  final bool enabled;

  /// Whether the value can be selected and copied but not edited.
  final bool readOnly;

  /// Whether to paint the validation-error treatment.
  final bool error;

  /// Whether characters are replaced by the obscuring character.
  final bool obscureText;

  /// Maximum rendered lines, or null to grow without bound.
  final int? maxLines;

  /// Minimum rendered lines.
  final int? minLines;

  /// Which soft keyboard to request.
  final TextInputType? keyboardType;

  /// The soft keyboard's action key.
  final TextInputAction? textInputAction;

  /// Invoked on every edit.
  final ValueChanged<String>? onChanged;

  /// Invoked when the action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Autofill categories for this field, e.g. `[AutofillHints.username]`.
  ///
  /// On web these become the `autocomplete` attribute of the DOM input the
  /// engine creates, which is the only thing a browser password manager keys
  /// off. Wrap the fields in an [AutofillGroup] as well: the engine only emits
  /// a real `<form>` — and browsers only offer to fill or save a credential
  /// PAIR — when the fields share one.
  final Iterable<String>? autofillHints;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentInputStyle? style;

  /// Announced by assistive technology. Use it when no visible label names the
  /// field — a placeholder is not a label.
  final String? semanticLabel;

  @override
  State<FluentInput> createState() => _FluentInputState();
}

class _FluentInputState extends State<FluentInput>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.enabled;

  late final TextSelectionGestureDetectorBuilder _gestures =
      TextSelectionGestureDetectorBuilder(delegate: this);

  final WidgetStatesController _states = WidgetStatesController();

  TextEditingController? _internalController;
  FocusNode? _internalNode;

  /// Mirrors the node, so a property-only notification is not read as a blur.
  bool _focused = false;

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _states
      ..update(WidgetState.disabled, !widget.enabled)
      ..addListener(_rebuild);
    _focusNode.addListener(_onFocusChanged);
    _focused = _focusNode.hasFocus;
    // The placeholder's visibility is a function of the value, so the field has
    // to rebuild on the first and last character typed.
    _controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(FluentInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalNode)?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
      _focused = _focusNode.hasFocus;
    }
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _internalController)?.removeListener(_rebuild);
      _controller.addListener(_rebuild);
    }
    if (!widget.enabled) {
      // Clear the interaction states rather than leaving a stale hover behind
      // when a field is disabled mid-gesture.
      _states
        ..update(WidgetState.hovered, false)
        ..update(WidgetState.pressed, false);
    }
    _states.update(WidgetState.disabled, !widget.enabled);
  }

  @override
  void dispose() {
    _states
      ..removeListener(_rebuild)
      ..dispose();
    (widget.focusNode ?? _internalNode)?.removeListener(_onFocusChanged);
    (widget.controller ?? _internalController)?.removeListener(_rebuild);
    _internalNode?.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// Focus needs its own listener rather than sharing [_rebuild] with the value
  /// and the interaction states: leaving a selection behind is a focus event,
  /// and running it on every keystroke would write to the caller's controller
  /// from inside that controller's own notification.
  ///
  /// Guarded on a real transition, because a [FocusNode] notifies for property
  /// writes too — `canRequestFocus`, `skipTraversal`, `descendantsAreFocusable`
  /// all reach `notifyListeners` — and on those `hasFocus` is simply still
  /// false. Without the guard, a host locking a never-focused field would erase
  /// a selection it had set itself. Every other Fluent text control latches the
  /// same way.
  void _onFocusChanged() {
    if (_focused == _focusNode.hasFocus) return;
    _focused = _focusNode.hasFocus;
    collapseFluentSelectionOnBlur(_focusNode, _controller);
    _rebuild();
  }

  void _set(WidgetState state, {required bool value}) {
    // A press released after `dispose` still reaches the detached `Listener`.
    if (!mounted) return;
    if (!widget.enabled && value) return;
    _states.update(state, value);
  }

  /// Chrome focuses a text field on mousedown — any button — with the caret
  /// where the press landed, so the focus bar grows under a held press.
  /// Flutter's text gestures focus on tap-down, which a middle press never
  /// reaches and which waits for the gesture arena whenever it is contested:
  /// the bar started a whole click late. This goes through the field's own
  /// selection path, as tap-down does, so desktop's select-all-on-focus stays
  /// out of it. A field that already has focus is left to the gestures, which
  /// keep a selection that a right press lands on for the context menu.
  void _focusOnPress(PointerDownEvent event) {
    if (!widget.enabled ||
        event.kind != PointerDeviceKind.mouse ||
        _focusNode.hasFocus) {
      return;
    }
    editableTextKey.currentState?.renderEditable.selectPositionAt(
      from: event.position,
      cause: SelectionChangedCause.tap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentInputState(
      controller: _controller,
      focusNode: _focusNode,
      editableTextKey: editableTextKey,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      error: widget.error,
      focused: _focusNode.hasFocus,
      appearance: widget.appearance,
      size: widget.size,
      placeholder: widget.placeholder,
      contentBefore: widget.contentBefore,
      contentAfter: widget.contentAfter,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
      autofillHints: widget.autofillHints,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentInputStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentInputTheme.maybeOf(context)).merge(widget.style);

    final states = <WidgetState>{..._states.value};

    // Not FluentInteractive, and that is deliberate. It owns a FocusNode
    // through FocusableActionDetector and binds ActivateIntent to a tap
    // callback — a text field needs its node to belong to the EditableText, and
    // needs Space and Enter to reach the input rather than "activate" the
    // control. Hover and press are wired the same way FluentInteractive wires
    // them, onto the same WidgetState vocabulary.
    Widget input = MouseRegion(
      cursor: resolved.mouseCursor?.resolve(states) ?? SystemMouseCursors.text,
      onEnter: (_) => _set(WidgetState.hovered, value: true),
      onExit: (_) => _set(WidgetState.hovered, value: false),
      // Every button presses, the right one included: unlike the Combobox
      // family's roots, Chrome sets `:active` on `.fui-Input` for a right press
      // too (storybook), so no `kSecondaryMouseButton` guard here.
      child: Listener(
        onPointerDown: (event) {
          _set(WidgetState.pressed, value: true);
          _focusOnPress(event);
        },
        onPointerUp: (_) => _set(WidgetState.pressed, value: false),
        onPointerCancel: (_) => _set(WidgetState.pressed, value: false),
        child: buildFluentInput(state, resolved, states),
      ),
    );

    if (widget.enabled) {
      input = _gestures.buildGestureDetector(
        behavior: HitTestBehavior.deferToChild,
        child: input,
      );
    }

    return Semantics(
      textField: true,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      label: widget.semanticLabel,
      child: input,
    );
  }
}
