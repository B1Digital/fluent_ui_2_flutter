import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import '../internal/text_context_menu.dart';
import 'input.dart';
import 'textarea_style.dart';

/// How a textarea is filled and outlined. Figma's `Style` axis.
enum FluentTextareaAppearance {
  /// `neutralBackground1` behind a full neutral border, with a heavier
  /// accessible rule along the bottom edge. The default.
  outline,

  /// `neutralBackground3`, no visible border and no bottom rule.
  filledDarker,

  /// `neutralBackground1`, no visible border and no bottom rule.
  filledLighter,
}

/// Type ramp and inset. Figma's `Size` axis.
enum FluentTextareaSize {
  /// `caption1` (12/16). Content inset 4 + 4 horizontally.
  small,

  /// `body1` (14/20). The default. Content inset 10 + 2 horizontally.
  medium,

  /// `body2` (16/22). Content inset 12 + 2 horizontally.
  large,
}

/// The focus underline sliding in, verified against
/// `useTextareaStyles.styles.ts` — `:focus-within::after` transitions
/// `transform` over `durationNormal` on `curveDecelerateMid`.
///
/// Upstream writes that curve into `transitionDelay` rather than
/// `transitionTimingFunction`, which a browser rejects; the *intent* is
/// unambiguous and is what is ported here. The 0.01ms
/// `prefers-reduced-motion` clamp upstream pairs it with is handled centrally
/// by [FluentAnimatedStyle].
///
/// The bar itself is [FluentInputFocusUnderline], whose spec carries the same
/// two tokens off the same `::after` rule — so this is an alias rather than a
/// second copy of them.
const FluentMotionSpec fluentTextareaFocusUnderlineEnter =
    fluentInputFocusUnderlineEnter;

/// The focus underline leaving. Upstream's resting `::after` rule transitions
/// `transform` over `durationUltraFast` on `curveAccelerateMid` — four times
/// faster than [fluentTextareaFocusUnderlineEnter], and accelerating rather
/// than decelerating. The asymmetry is upstream's; do not "tidy" it.
///
/// An alias of [fluentInputFocusUnderlineExit], for the reason given on
/// [fluentTextareaFocusUnderlineEnter].
const FluentMotionSpec fluentTextareaFocusUnderlineExit =
    fluentInputFocusUnderlineExit;

/// Identifies the resting bottom rule inside a textarea's chrome.
///
/// Public so a test — or a caller wrapping [buildFluentTextarea] — can find the
/// rule without matching on colour.
const Key fluentTextareaUnderlineKey = Key('fluent-textarea-underline');

/// Identifies the brand focus rule — the [FluentInputFocusUnderline] that
/// scales in on focus.
const Key fluentTextareaFocusUnderlineKey = Key(
  'fluent-textarea-focus-underline',
);

/// Everything needed to style and render a textarea, independent of appearance
/// and size.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentTextarea] takes this
/// rather than [FluentTextareaState], which is what makes "Fluent's state, my
/// own styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentTextareaBaseState {
  /// Creates a base state.
  const FluentTextareaBaseState({
    required this.enabled,
    required this.readOnly,
    required this.invalid,
    required this.focused,
  });

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether the field shows its content but refuses edits.
  final bool readOnly;

  /// Whether the field is in the error state.
  final bool invalid;

  /// Whether the field holds focus.
  ///
  /// Deliberately a field rather than `WidgetState.focused`. Two reasons, and
  /// both are load-bearing:
  ///
  /// * `WidgetState.focused` means *keyboard-visible* focus everywhere else in
  ///   this package, and a textarea's brand underline is not keyboard-gated —
  ///   upstream keys it off `:focus-within`, so clicking into the field raises
  ///   it too.
  /// * The underline does not swap colour on focus, it *animates in* by
  ///   scaling horizontally. That is a transition between two builds, which no
  ///   [WidgetStateProperty] can express.
  ///
  /// A textarea draws no focus ring at all — `:focus-within` sets
  /// `outlineColor: 'transparent'` upstream and no Figma variant paints one —
  /// so nothing here depends on the keyboard-visible distinction.
  final bool focused;
}

/// A textarea's fully resolved state, including the design axes.
@immutable
class FluentTextareaState extends FluentTextareaBaseState {
  /// Creates a resolved state.
  const FluentTextareaState({
    required super.enabled,
    required super.readOnly,
    required super.invalid,
    required super.focused,
    required this.appearance,
    required this.size,
  });

  /// Fill and outline treatment.
  final FluentTextareaAppearance appearance;

  /// Type ramp and inset.
  final FluentTextareaSize size;
}

/// Builds the state a textarea will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentTextareaState resolveFluentTextareaState({
  bool enabled = true,
  bool readOnly = false,
  bool invalid = false,
  bool focused = false,
  FluentTextareaAppearance appearance = FluentTextareaAppearance.outline,
  FluentTextareaSize size = FluentTextareaSize.medium,
}) => FluentTextareaState(
  enabled: enabled,
  readOnly: readOnly,
  invalid: invalid,
  focused: focused,
  appearance: appearance,
  size: size,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Textarea` component set (63 variants over
/// `Style`, `Size` and `State`), extracted into `test/fixtures/textarea.json`
/// and asserted variant-by-variant in the tests.
///
/// ## Disabled and read-only erase the appearance
///
/// Both swap to a transparent fill and the disabled stroke *wholesale*, on all
/// three appearances — a disabled `filledDarker` textarea loses its grey fill
/// rather than dimming it. All 18 of Figma's Disabled and Read-only variants
/// bind the identical pair, and `useTextareaStyles.styles.ts` agrees. The two
/// differ only in the text: read-only content reads at full
/// `neutralForeground1` contrast, because it is content the user is meant to
/// read rather than a control they are meant to ignore.
FluentTextareaStyle resolveFluentTextareaStyle(
  FluentTextareaState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final inert = !state.enabled || state.readOnly;
  // The invalid treatment is gated on focus because upstream gates it:
  // `useTextareaStyles.styles.ts` writes `colorPaletteRedBorder2` under
  // `':not(:focus-within),:hover:not(:focus-within)'`, so a focused invalid
  // textarea falls back to the ordinary ramp and the brand bar marks it
  // instead. Figma cannot contradict this — Error and Focus are two values of
  // one `State` axis there, so the file has no Error-while-focused variant.
  final invalid = state.invalid && !state.focused;

  // `body2` is the step ABOVE `body1` on the Web and Windows ramps, but the
  // step BELOW it on the Apple and Android ones — Fluent's mobile specs put
  // Body1 at 16/17 and Body2 at 14/15, which is faithful and not a bug in the
  // ramps. So the size axis cannot name `body2` directly; it has to order the
  // pair by size. Binding `large` straight to `body2` renders Large in SMALLER
  // type than Medium on every mobile ramp, and a textarea has no height floor
  // — its box is two lines plus a flat inset — so the inversion arrives as a
  // Large field visibly SHORTER than the Medium one above it.
  // fontSize is null only for a supplied ramp with no size at all; 0 then
  // leaves the Web order, which is the one Figma is drawn against.
  final rampsUpToBody2 =
      (theme.typography.body1.fontSize ?? 0) <=
      (theme.typography.body2.fontSize ?? 0);
  final mediumBody = rampsUpToBody2
      ? theme.typography.body1
      : theme.typography.body2;
  final largeBody = rampsUpToBody2
      ? theme.typography.body2
      : theme.typography.body1;

  final background = inert
      ? FluentStateColor.tokens(rest: c.transparentBackground)
      : switch (state.appearance) {
          FluentTextareaAppearance.outline ||
          FluentTextareaAppearance.filledLighter => FluentStateColor.tokens(
            rest: c.neutralBackground1,
          ),
          FluentTextareaAppearance.filledDarker => FluentStateColor.tokens(
            rest: c.neutralBackground3,
          ),
        };

  // Figma binds one fill token per appearance across Rest, Hover, Pressed and
  // Focus alike — the surface never moves, which is why every branch above is a
  // single Rest token rather than a ramp.
  final border = switch ((inert, invalid, state.appearance)) {
    (true, _, _) => FluentStateColor.tokens(rest: c.neutralStrokeDisabled),
    (false, true, _) => FluentStateColor.tokens(rest: c.statusDangerBorder2),
    (false, false, FluentTextareaAppearance.outline) => FluentStateColor.tokens(
      rest: c.neutralStroke1,
      hover: c.neutralStroke1Hover,
      pressed: c.neutralStroke1Pressed,
    ),
    // Figma paints NO stroke on either filled appearance. React does, in the
    // transparent tokens, and React wins here for the same reason it does on
    // the Switch's checked track: a transparent Fluent token turns OPAQUE in
    // high contrast, and this border is the only thing that would outline a
    // filled textarea there.
    (false, false, _) => FluentStateColor.tokens(
      rest: c.transparentStroke,
      hover: c.transparentStrokeInteractive,
      pressed: c.transparentStrokeInteractive,
    ),
  };

  // The resting bottom rule. Only Outline draws one, and only while the field
  // is live: Figma's Error, Disabled and Read-only variants carry a uniform
  // four-sided border and no extra rule at all.
  final underline =
      !inert && !invalid && state.appearance == FluentTextareaAppearance.outline
      ? FluentStateColor.tokens(
          rest: c.neutralStrokeAccessible,
          hover: c.neutralStrokeAccessibleHover,
          pressed: c.neutralStrokeAccessiblePressed,
        )
      : null;

  return FluentTextareaStyle(
    backgroundColor: background,
    borderColor: border,
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    underlineColor: underline,
    // Figma's Pressed variants swap the 1px "Thin underline" for a 2px "Thick
    // underline"; Rest and Hover keep 1. React declares a flat 1px
    // border-bottom in every state, so this ramp is Figma's alone.
    underlineThickness: const WidgetStateProperty<double?>.fromMap(
      <WidgetStatesConstraint, double?>{
        WidgetState.pressed: FluentStroke.thick,
        WidgetState.any: FluentStroke.thin,
      },
    ),
    focusUnderlineColor: inert && !state.readOnly
        ? null
        : FluentStateColor.tokens(
            rest: c.compoundBrandStroke,
            pressed: c.compoundBrandStrokePressed,
          ),
    focusUnderlineThickness: const WidgetStatePropertyAll<double?>(
      FluentStroke.thick,
    ),
    foregroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      disabled: c.neutralForegroundDisabled,
    ),
    placeholderColor: FluentStateColor.tokens(
      rest: c.neutralForeground4,
      disabled: c.neutralForegroundDisabled,
    ),
    // Fluent names no caret token and upstream sets no `caret-color`, so the
    // browser paints the caret in the text colour. That is what this reproduces
    // rather than inventing a brand caret.
    cursorColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      disabled: c.neutralForegroundDisabled,
    ),
    // Nor is there a selection token anywhere in the file. `brandBackground2`
    // is the one brand surface that keeps `neutralForeground1` legible in BOTH
    // themes — a pale tint in light, a deep navy in dark — which is the whole
    // requirement for a selection wash.
    selectionColor: FluentStateColor.tokens(rest: c.brandBackground2),
    textStyle: WidgetStatePropertyAll<TextStyle?>(switch (state.size) {
      FluentTextareaSize.small => theme.typography.caption1,
      FluentTextareaSize.medium => mediumBody,
      FluentTextareaSize.large => largeBody,
    }),
    // Figma splits this across two frames: `Contents` insets 6/10/12 with the
    // size, and the nested `.Text` adds a flat 2 horizontally and 6 vertically
    // at EVERY size. React's horizontal `calc(spacingHorizontal* + XXS)` agrees
    // exactly; its vertical ramp (4/6/8) does not, and Figma's flat 6 wins.
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(
        horizontal:
            switch (state.size) {
              FluentTextareaSize.small => FluentSpacing.sNudge,
              FluentTextareaSize.medium => FluentSpacing.mNudge,
              FluentTextareaSize.large => FluentSpacing.m,
            } +
            FluentSpacing.xxs,
        vertical: FluentSpacing.sNudge,
      ),
    ),
    mouseCursor: const WidgetStateProperty<MouseCursor?>.fromMap(
      <WidgetStatesConstraint, MouseCursor?>{
        WidgetState.disabled: SystemMouseCursors.basic,
        WidgetState.any: SystemMouseCursors.text,
      },
    ),
  );
}

/// Renders a textarea's chrome around an already-built [field].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentTextareaBaseState] rather than [FluentTextareaState] on purpose: it
/// never reads appearance or size, so a consumer can supply their own style and
/// still get Fluent's layout and its underline animation.
///
/// [field] is a slot rather than a member of the state — unlike a button's
/// label, a textarea's editable subtree has to be built *from* the resolved
/// style (it needs the type ramp, the caret colour and the selection colour),
/// so it cannot exist before the style does.
///
/// [states] carries `hovered`, `pressed` and `disabled` only. Focus lives on
/// [FluentTextareaBaseState.focused]; see its doc.
Widget buildFluentTextarea(
  FluentTextareaBaseState state,
  FluentTextareaStyle style,
  Set<WidgetState> states,
  Widget field,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;

  final underlineColor = style.underlineColor?.resolve(states);
  final underlineThickness =
      style.underlineThickness?.resolve(states) ?? FluentStroke.none;
  final focusColor = style.focusUnderlineColor?.resolve(states);
  final focusThickness =
      style.focusUnderlineThickness?.resolve(states) ?? FluentStroke.none;

  final surface = DecoratedBox(
    decoration: BoxDecoration(
      color: style.backgroundColor?.resolve(states),
      borderRadius: radius,
      border: borderWidth > 0 && borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
    ),
    child: Padding(padding: padding, child: field),
  );

  // Both rules paint OVER the bottom border rather than under it, which is
  // Figma's arrangement: the underline rectangles are siblings of the bordered
  // `Contents` frame, drawn last, at the full frame width. React's `::after`
  // reaches 1px outside the border box to the same effect.
  return Stack(
    children: <Widget>[
      surface,
      if (underlineColor != null && underlineThickness > 0)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: SizedBox(
              height: underlineThickness,
              child: ColoredBox(
                key: fluentTextareaUnderlineKey,
                color: underlineColor,
              ),
            ),
          ),
        ),
      if (focusColor != null && focusThickness > 0)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: focusThickness,
          child: IgnorePointer(
            child: FluentInputFocusUnderline(
              key: fluentTextareaFocusUnderlineKey,
              focused: state.focused,
              color: focusColor,
              thickness: focusThickness,
              // Figma's `InFocus` rectangle rounds its bottom corners to the
              // field's own radius and leaves the top square.
              borderRadius: BorderRadius.only(
                bottomLeft: radius.bottomLeft,
                bottomRight: radius.bottomRight,
              ),
            ),
          ),
        ),
    ],
  );
}

/// Overrides the textarea style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentTextareaTheme extends InheritedTheme {
  /// Applies [style] to every [FluentTextarea] in [child].
  const FluentTextareaTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentTextareaStyle style;

  /// The nearest textarea style, or null.
  static FluentTextareaStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentTextareaTheme>()?.style;

  @override
  bool updateShouldNotify(FluentTextareaTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentTextareaTheme(style: style, child: child);
}

/// A Fluent 2 multi-line text input.
///
/// ```dart
/// FluentTextarea(
///   placeholder: 'Tell us what happened',
///   onChanged: (value) => setState(() => _draft = value),
/// )
/// ```
///
/// ## No resize handle
///
/// The Figma set this is ported from has three axes — `Style`, `Size` and
/// `State` — and **no `Resize` axis**. Upstream's `resize` prop is a
/// pass-through to the CSS `resize` property, which is a browser affordance
/// with no counterpart in Flutter: there is no grippy in the corner of a
/// Flutter text field to expose. Rather than fake one, this widget omits it.
/// Size the field with [minLines] and [maxLines], or wrap it in whatever your
/// app already uses to make a box draggable.
///
/// ## Disabled and read-only are different, and both are real states
///
/// [enabled] `false` refuses focus, refuses edits, drops the appearance to the
/// disabled ramp and greys the text. [readOnly] refuses edits and drops to the
/// same chrome, but keeps the text at full contrast and stays focusable and
/// selectable — that is Figma's `State=Read only`, which React has no styling
/// for at all.
///
/// ## Built on [EditableText]
///
/// `package:flutter/material.dart` is not available to this package, so there
/// is no `TextField` to lean on. Selection gestures come from
/// [TextSelectionGestureDetectorBuilder] (which lives in the widgets layer,
/// not in Material) and handles from `FluentTextSelectionControls`.
///
/// This is also the one component in the package that does **not** wrap itself
/// in `FluentInteractive`. That widget owns a [FocusNode] and binds
/// `ActivateIntent` to a press callback, which is right for a button and wrong
/// here twice over: [EditableText] attaches the field's own [FocusNode] to a
/// [Focus] widget of its own, so the two would fight over one node, and an
/// enabled `FocusableActionDetector` around the field would add a second Tab
/// stop in front of it. Hover and press are therefore read from a
/// [MouseRegion] and a [Listener] directly — the reported set is still the
/// framework's own [WidgetState] values, and every colour still comes from
/// `FluentStateColor`.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentTextareaTheme] restyles a subtree; and for anything further,
/// [resolveFluentTextareaState], [resolveFluentTextareaStyle] and
/// [buildFluentTextarea] are public so any one of them can be replaced without
/// forking this widget.
class FluentTextarea extends StatefulWidget {
  /// Creates a multi-line text input.
  const FluentTextarea({
    super.key,
    this.controller,
    this.focusNode,
    this.appearance = FluentTextareaAppearance.outline,
    this.size = FluentTextareaSize.medium,
    this.placeholder,
    this.enabled = true,
    this.readOnly = false,
    this.invalid = false,
    this.autofocus = false,
    this.obscureText = false,
    this.minLines = 2,
    this.maxLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.selectionControls,
    this.contextMenuBuilder,
    this.style,
    this.semanticLabel,
  }) : assert(
         !obscureText || maxLines == 1,
         'obscureText needs maxLines: 1 — an obscured field cannot wrap.',
       ),
       assert(
         maxLines == null || minLines == null || maxLines >= minLines,
         'maxLines must be at least minLines, which defaults to 2 here — pass '
         'minLines: 1 for a single-line field.',
       );

  /// The text being edited. One is created internally when omitted.
  final TextEditingController? controller;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Fill and outline treatment.
  final FluentTextareaAppearance appearance;

  /// Type ramp and inset.
  final FluentTextareaSize size;

  /// Shown while the field is empty. Figma's `Placeholder text` layer.
  final String? placeholder;

  /// Whether the field accepts input. False is a real state, not a treatment.
  final bool enabled;

  /// Whether the field refuses edits while staying focusable and selectable.
  final bool readOnly;

  /// Whether to paint the error border. Figma's `State=Error`.
  final bool invalid;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Whether to replace every glyph with a bullet. Requires `maxLines: 1`.
  final bool obscureText;

  /// Smallest number of lines the field occupies.
  ///
  /// Two by default, which is the height Figma's 52px medium frame draws.
  final int? minLines;

  /// Largest number of lines before the field scrolls internally. Null grows
  /// without bound.
  final int? maxLines;

  /// Hard cap on the number of characters, enforced by an input formatter.
  final int? maxLength;

  /// Soft keyboard type. Defaults to multiline, or plain text at `maxLines: 1`.
  final TextInputType? keyboardType;

  /// What the soft keyboard's action key does. Defaults to inserting a newline
  /// on a multi-line field.
  final TextInputAction? textInputAction;

  /// Automatic capitalisation applied by the soft keyboard.
  final TextCapitalization textCapitalization;

  /// Invoked on every edit.
  final ValueChanged<String>? onChanged;

  /// Invoked when the user submits from the soft keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Applied to every edit, in order, before [onChanged].
  final List<TextInputFormatter>? inputFormatters;

  /// Selection handles. Defaults to the shared
  /// `fluentTextSelectionControls`, so every text control draws the same ones.
  final TextSelectionControls? selectionControls;

  /// Builds the selection context menu. Null shows none — Fluent's menu surface
  /// is not ported yet.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentTextareaStyle? style;

  /// Announced by assistive technology in place of the placeholder.
  final String? semanticLabel;

  @override
  State<FluentTextarea> createState() => _FluentTextareaState();
}

class _FluentTextareaState extends State<FluentTextarea>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  late final TextSelectionGestureDetectorBuilder _gestures =
      TextSelectionGestureDetectorBuilder(delegate: this);

  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;
  final WidgetStatesController _statesController = WidgetStatesController();
  bool _focused = false;

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool get _enabled => widget.enabled;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => _enabled;

  @override
  void initState() {
    super.initState();
    _statesController
      ..update(WidgetState.disabled, !_enabled)
      ..addListener(_onStatesChanged);
    _focusNode.addListener(_onFocusChanged);
    _focused = _focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(FluentTextarea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(
        _onFocusChanged,
      );
      _focusNode.addListener(_onFocusChanged);
      _focused = _focusNode.hasFocus;
    }
    if (!_enabled) {
      // Clear the pointer states rather than leaving a stale hover behind when
      // the field is disabled mid-gesture.
      _statesController
        ..update(WidgetState.hovered, false)
        ..update(WidgetState.pressed, false);
    }
    _statesController.update(WidgetState.disabled, !_enabled);
  }

  @override
  void dispose() {
    (widget.focusNode ?? _internalFocusNode)?.removeListener(_onFocusChanged);
    _statesController
      ..removeListener(_onStatesChanged)
      ..dispose();
    _internalFocusNode?.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _onStatesChanged() => setState(() {});

  void _onFocusChanged() {
    if (_focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  void _set(WidgetState state, {required bool value}) {
    if (!_enabled && value) return;
    _statesController.update(state, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final state = resolveFluentTextareaState(
      enabled: _enabled,
      readOnly: widget.readOnly,
      invalid: widget.invalid,
      focused: _focused,
      appearance: widget.appearance,
      size: widget.size,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentTextareaStyle(
      state,
      theme,
    ).merge(FluentTextareaTheme.maybeOf(context)).merge(widget.style);

    final states = _statesController.value;
    final textStyle = (resolved.textStyle?.resolve(states) ?? const TextStyle())
        .copyWith(color: resolved.foregroundColor?.resolve(states));

    // Refusing focus is what makes `enabled: false` a state rather than a
    // treatment: a disabled field is skipped by Tab, not merely greyed.
    _focusNode.canRequestFocus = _enabled;

    final editable = EditableText(
      key: editableTextKey,
      controller: _controller,
      focusNode: _focusNode,
      style: textStyle,
      cursorColor:
          resolved.cursorColor?.resolve(states) ??
          theme.colors.neutralForeground1,
      // The floating (iOS drag) caret. Fluent has no token for it either; the
      // muted placeholder tone is the closest honest choice.
      backgroundCursorColor: theme.colors.neutralForeground4,
      selectionColor: resolved.selectionColor?.resolve(states),
      selectionControls:
          widget.selectionControls ?? fluentTextSelectionControls,
      showSelectionHandles: true,
      contextMenuBuilder:
          widget.contextMenuBuilder ?? fluentTextContextMenuBuilder,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly || !_enabled,
      obscureText: widget.obscureText,
      enableInteractiveSelection: _enabled,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType:
          widget.keyboardType ??
          (widget.maxLines == 1 ? TextInputType.text : TextInputType.multiline),
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: <TextInputFormatter>[
        if (widget.maxLength != null)
          LengthLimitingTextInputFormatter(widget.maxLength),
        ...?widget.inputFormatters,
      ],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      // The gesture detector below owns the pointer; without this the render
      // object would compete with it for taps.
      rendererIgnoresPointer: true,
      cursorWidth: FluentStroke.thick,
    );

    final placeholder = widget.placeholder;
    final field = placeholder == null
        ? editable
        : Stack(
            children: <Widget>[
              // Painted under the editable so the caret stays on top, and
              // rebuilt only when the value changes between empty and not.
              Positioned.fill(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) => value.text.isEmpty
                      ? Align(
                          alignment: AlignmentDirectional.topStart,
                          child: Text(
                            placeholder,
                            style: textStyle.copyWith(
                              color: resolved.placeholderColor?.resolve(states),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              editable,
            ],
          );

    final chrome = buildFluentTextarea(
      state,
      resolved,
      states,
      _gestures.buildGestureDetector(
        behavior: HitTestBehavior.translucent,
        child: field,
      ),
    );

    return Semantics(
      enabled: _enabled,
      readOnly: widget.readOnly,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor:
            resolved.mouseCursor?.resolve(states) ?? SystemMouseCursors.text,
        onEnter: (_) => _set(WidgetState.hovered, value: true),
        onExit: (_) => _set(WidgetState.hovered, value: false),
        child: Listener(
          onPointerDown: (_) => _set(WidgetState.pressed, value: true),
          onPointerUp: (_) => _set(WidgetState.pressed, value: false),
          onPointerCancel: (_) => _set(WidgetState.pressed, value: false),
          child: IgnorePointer(ignoring: !_enabled, child: chrome),
        ),
      ),
    );
  }
}
