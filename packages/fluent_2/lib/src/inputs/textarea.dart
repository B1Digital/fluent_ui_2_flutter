import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import '../internal/text_context_menu.dart';
import '../internal/text_selection_dismiss.dart';
import 'input.dart';
import 'textarea_style.dart';

/// How a textarea is filled and outlined. Figma's `Style` axis.
enum FluentTextareaAppearance {
  /// `neutralBackground1` behind a neutral border whose bottom side is the
  /// darker accessible stroke. The default.
  outline,

  /// `neutralBackground3` behind a transparent border, which only high contrast
  /// makes visible.
  filledDarker,

  /// `neutralBackground1` behind a transparent border, which only high contrast
  /// makes visible.
  filledLighter,
}

/// Type ramp, inset and minimum height. Upstream's `size` prop.
enum FluentTextareaSize {
  /// `caption1` (12/16). Text inset 4 vertically and 8 horizontally; 44 tall.
  small,

  /// `body1` (14/20). The default. Text inset 6 vertically and 12
  /// horizontally; 56 tall.
  medium,

  /// `body2` (16/22). Text inset 8 vertically and 14 horizontally; 68 tall.
  large,
}

/// The focus underline sliding in. `useTextareaStyles.styles.ts`'s
/// `:focus-within::after` transitions `transform` over `durationNormal`.
///
/// Upstream writes `curveDecelerateMid` into `transitionDelay` rather than
/// `transitionTimingFunction`. A browser drops it, so the bar runs on CSS
/// `ease` ([FluentCssCubic.ease]) with no delay — measured on the live
/// storybook, where every one of the fields that share this bar samples
/// identically. The port ports what renders, not what the typo suggests was
/// meant. The 0.01ms `prefers-reduced-motion` clamp upstream pairs it with is
/// handled inside [FluentInputFocusUnderline].
///
/// That widget's spec comes off the same `::after` rule — so this is an alias
/// rather than a second copy of it.
const FluentMotionSpec fluentTextareaFocusUnderlineEnter =
    fluentInputFocusUnderlineEnter;

/// The focus underline leaving. Upstream's resting `::after` rule transitions
/// `transform` over `durationUltraFast`, on `ease` for the same reason — four
/// times faster than [fluentTextareaFocusUnderlineEnter]. The asymmetry is
/// upstream's; do not "tidy" it.
///
/// An alias of [fluentInputFocusUnderlineExit], for the reason given on
/// [fluentTextareaFocusUnderlineEnter].
const FluentMotionSpec fluentTextareaFocusUnderlineExit =
    fluentInputFocusUnderlineExit;

/// Identifies the [CustomPaint] that draws a textarea's border, whose bottom
/// side is the resting bottom rule. Its painter is a
/// [FluentInputBorderPainter].
///
/// Public so a test — or a caller wrapping [buildFluentTextarea] — can find the
/// border without matching on colour.
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
  /// * The brand bar does not swap colour on focus, it *animates in* by
  ///   scaling horizontally. That is a transition between two builds, which no
  ///   [WidgetStateProperty] can express.
  ///
  /// A textarea draws no focus ring at all — `:focus-within` sets
  /// `outlineColor: 'transparent'` upstream — so nothing here depends on the
  /// keyboard-visible distinction.
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
/// The oracle is upstream as it renders — `useTextareaStyles.styles.ts`
/// measured in Chrome on the live storybook — not the Figma `Textarea` set.
/// Where the two disagree, upstream wins:
///
/// * **Read only has no styling.** Upstream passes `readOnly` straight to the
///   `<textarea>`; the root keeps every interactive rule. Only
///   [FluentTextareaBaseState.enabled] changes the ramp.
/// * **Hover wins over focus.** Unlike Input, `outlineInteractive` writes
///   `:focus-within` as its own rule, and Griffel sorts it before `:hover` and
///   `:active`. A focused outline field shows `Stroke1Pressed` sides and a
///   `compoundBrandStroke` bottom until the pointer moves over it, then the
///   Hover colours; a press shows the Pressed ones.
/// * **The bottom border is a border.** 1px in every state, joined to the sides
///   on the CSS corner diagonal by [FluentInputBorderPainter].
/// * **Invalid is `colorPaletteRedBorder2`**, not the status danger token.
/// * **Height is a floor, not a sum.** The `<textarea>` carries `min-height`
///   40 / 52 / 64 and the root a 2px `padding-bottom`, so the border box is
///   44 / 56 / 68 — Figma's 52px medium frame is 4 short.
FluentTextareaStyle resolveFluentTextareaStyle(
  FluentTextareaState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final disabled = !state.enabled;
  final focused = state.focused;
  // The invalid treatment is gated on focus because upstream gates it:
  // `useTextareaStyles.styles.ts` writes `colorPaletteRedBorder2` under
  // `':not(:focus-within),:hover:not(:focus-within)'`, so a focused invalid
  // textarea falls back to the ordinary ramp and the brand bar marks it
  // instead.
  final invalid = state.invalid && !focused;
  // `colorPaletteRedBorder2`. The palette layer knows nothing of high contrast,
  // where the status token is the system text colour instead.
  final danger = c is FluentHighContrastColors
      ? c.statusDangerBorder2
      : c.palette.stroke2Rest(FluentPaletteFamily.red)!;

  // `body2` is the step ABOVE `body1` on the Web and Windows ramps, but the
  // step BELOW it on the Apple and Android ones — Fluent's mobile specs put
  // Body1 at 16/17 and Body2 at 14/15, which is faithful and not a bug in the
  // ramps. So the size axis cannot name `body2` directly; it has to order the
  // pair by size. Binding `large` straight to `body2` renders Large in SMALLER
  // type than Medium on every mobile ramp.
  // fontSize is null only for a supplied ramp with no size at all; 0 then
  // leaves the Web order, which is the one upstream renders.
  final rampsUpToBody2 =
      (theme.typography.body1.fontSize ?? 0) <=
      (theme.typography.body2.fontSize ?? 0);
  final mediumBody = rampsUpToBody2
      ? theme.typography.body1
      : theme.typography.body2;
  final largeBody = rampsUpToBody2
      ? theme.typography.body2
      : theme.typography.body1;

  // One fill per appearance in every interactive state: upstream never moves
  // the surface. Disabled swaps it to transparent on all three appearances.
  final background = disabled
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

  final border = switch ((disabled, invalid, state.appearance)) {
    (true, _, _) => FluentStateColor.tokens(rest: c.neutralStrokeDisabled),
    (false, true, _) => FluentStateColor.tokens(rest: danger),
    // Hover stays unconditional: see the doc comment.
    (false, false, FluentTextareaAppearance.outline) => FluentStateColor.tokens(
      rest: focused ? c.neutralStroke1Pressed : c.neutralStroke1,
      hover: c.neutralStroke1Hover,
      pressed: c.neutralStroke1Pressed,
    ),
    // `filled` moves `:hover,:focus-within` to the Interactive token. Both are
    // transparent in light and dark; high contrast makes them opaque, and this
    // border is the only thing that outlines a filled textarea there.
    (false, false, _) => FluentStateColor.tokens(
      rest: focused ? c.transparentStrokeInteractive : c.transparentStroke,
      hover: c.transparentStrokeInteractive,
      pressed: c.transparentStrokeInteractive,
    ),
  };

  // The bottom side. Only a live, valid Outline field has its own; everywhere
  // else the box border runs round all four sides — the error colour
  // (`shorthands.borderColor`) and the disabled `border` both cover it.
  final underline =
      !disabled &&
          !invalid &&
          state.appearance == FluentTextareaAppearance.outline
      ? FluentStateColor.tokens(
          rest: focused ? c.compoundBrandStroke : c.neutralStrokeAccessible,
          hover: c.neutralStrokeAccessibleHover,
          pressed: c.neutralStrokeAccessiblePressed,
        )
      : null;

  final (vertical, horizontal, height) = switch (state.size) {
    FluentTextareaSize.small => (FluentSpacing.xs, FluentSpacing.sNudge, 44.0),
    FluentTextareaSize.medium => (
      FluentSpacing.sNudge,
      FluentSpacing.mNudge,
      56.0,
    ),
    FluentTextareaSize.large => (FluentSpacing.s, FluentSpacing.m, 68.0),
  };

  return FluentTextareaStyle(
    backgroundColor: background,
    borderColor: border,
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    underlineColor: underline,
    // 1px in every state: upstream recolours the bottom border on press, it
    // never thickens it.
    underlineThickness: const WidgetStatePropertyAll<double?>(
      FluentStroke.thin,
    ),
    // Upstream drops `interactive` — the `::after` bar included — when
    // disabled. Read only keeps it: it still takes focus.
    focusUnderlineColor: disabled
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
    // The `<textarea>`'s own padding — `spacingVertical{XS,SNudge,S}` and
    // `calc(spacingHorizontal{SNudge,MNudge,M} + XXS)` — plus the root's
    // `padding-bottom: strokeWidthThick`, which upstream sizes to the focus bar.
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.fromLTRB(
        horizontal + FluentSpacing.xxs,
        vertical,
        horizontal + FluentSpacing.xxs,
        vertical + FluentStroke.thick,
      ),
    ),
    // The `<textarea>`'s `min-height` (40 / 52 / 64) plus the 2px root padding
    // and the 1px border above and below. Two lines of Large's 22px type need
    // only 60, so on Large the floor, not the text, sets the height.
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    // `textareaStyles.disabled` sets `cursor: not-allowed`.
    mouseCursor: const WidgetStateProperty<MouseCursor?>.fromMap(
      <WidgetStatesConstraint, MouseCursor?>{
        WidgetState.disabled: SystemMouseCursors.forbidden,
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
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;

  final underlineColor = style.underlineColor?.resolve(states);
  final underlineThickness =
      style.underlineThickness?.resolve(states) ?? FluentStroke.none;
  final focusColor = style.focusUnderlineColor?.resolve(states);
  final focusThickness =
      style.focusUnderlineThickness?.resolve(states) ?? FluentStroke.none;

  // CSS box model: a border that exists takes space, so the text sits inside
  // it — 1px on every side, the filled appearances' transparent border
  // included. A null colour is no border at all.
  final side = borderColor == null ? FluentStroke.none : borderWidth;
  final widths = EdgeInsets.fromLTRB(
    side,
    side,
    side,
    underlineColor == null ? side : underlineThickness,
  );

  // Background, then border, then text, then the focus bar: CSS's paint order
  // for a root and its positioned `::after`, which spans the border box.
  return Stack(
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.backgroundColor?.resolve(states),
            borderRadius: radius,
          ),
          child: CustomPaint(
            key: fluentTextareaUnderlineKey,
            painter: FluentInputBorderPainter(
              radius: radius,
              borderColor: borderColor,
              borderWidth: side,
              bottomBorderColor: underlineColor,
              bottomBorderWidth: widths.bottom,
            ),
            child: Padding(padding: padding.add(widths), child: field),
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
              // `::after` rounds its bottom corners to the field's own radius
              // and leaves the top square.
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
/// Upstream's `resize` prop is a pass-through to the CSS `resize` property.
/// Its default, `'none'`, renders no handle, and that is what this widget
/// draws. The other values show the browser's own drag grip, which has no
/// counterpart in Flutter, so rather than fake one this widget omits the prop.
/// Size the field with [minLines] and [maxLines], or wrap it in whatever your
/// app already uses to make a box draggable.
///
/// ## Disabled and read-only are different, and both are real states
///
/// [enabled] `false` refuses focus, refuses edits, drops the appearance to the
/// disabled ramp and greys the text. [readOnly] only refuses edits: upstream
/// passes it to the `<textarea>` and styles nothing, so a read-only field looks
/// exactly like an editable one — hover, focus and all — and stays focusable
/// and selectable.
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

  /// Smallest number of lines the field occupies. Two by default: upstream
  /// renders `<textarea rows="2">`.
  ///
  /// The size's minimum height still applies, so two lines of Large's type
  /// leave room below them, as upstream's `min-height` does.
  final int? minLines;

  /// Largest number of lines the field grows to before it scrolls internally.
  /// Null holds it at [minLines], as `rows` does upstream: a `<textarea>` never
  /// grows with its text, it scrolls.
  ///
  /// Null for both grows without bound, and so does a [minLines] of 1:
  /// [EditableText]'s `maxLines: 1` is a single-line input that neither wraps
  /// nor keeps a newline. The text scrolls inside the padding rather than
  /// through it, and a mouse wheel over the padding does not scroll it, because
  /// [EditableText] has no padding of its own.
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
  bool _showHandles = false;

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
    collapseFluentSelectionOnBlur(_focusNode, _controller);
    setState(() => _focused = _focusNode.hasFocus);
  }

  // TextField's rule: the builder records whether the gesture that moved the
  // selection was a touch or a stylus, so a mouse and the keyboard never show
  // the touch handles.
  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    final show =
        _gestures.shouldShowSelectionHandles &&
        cause != SelectionChangedCause.keyboard &&
        !(widget.readOnly && selection.isCollapsed) &&
        (cause == SelectionChangedCause.longPress ||
            _controller.text.isNotEmpty);
    if (show != _showHandles) setState(() => _showHandles = show);
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
    // ponytail: a one-row field grows rather than scrolls. EditableText's
    // `maxLines: 1` is a single-line input that cannot wrap and strips
    // newlines; holding one wrapped row needs a height clamp in pixels.
    final maxLines =
        widget.maxLines ?? (widget.minLines == 1 ? null : widget.minLines);
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
      // Focus-gated: see the note on the same argument in `buildFluentInput`.
      // Nulling the colour is what dismisses the highlight on blur.
      selectionColor: _focused
          ? resolved.selectionColor?.resolve(states)
          : null,
      selectionControls:
          widget.selectionControls ?? fluentTextSelectionControls,
      showSelectionHandles: _showHandles,
      onSelectionChanged: _handleSelectionChanged,
      contextMenuBuilder:
          widget.contextMenuBuilder ?? fluentTextContextMenuBuilder,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly || !_enabled,
      obscureText: widget.obscureText,
      enableInteractiveSelection: _enabled,
      minLines: widget.minLines,
      maxLines: maxLines,
      keyboardType:
          widget.keyboardType ??
          (maxLines == 1 ? TextInputType.text : TextInputType.multiline),
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
      // The browser's caret is 1px; `EditableText`'s default is 2.
      cursorWidth: FluentStroke.thin,
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

    // The gesture detector wraps the whole chrome, as `FluentInput`'s does:
    // the padding is part of the `<textarea>` upstream, so a click there
    // focuses the field and places the caret.
    final chrome = _gestures.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: buildFluentTextarea(state, resolved, states, field),
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
        // Any button: a `<textarea>` takes `:active` from a right press too,
        // unlike the Combobox family (Chrome).
        child: Listener(
          onPointerDown: (_) => _set(WidgetState.pressed, value: true),
          onPointerUp: (_) => _set(WidgetState.pressed, value: false),
          onPointerCancel: (_) => _set(WidgetState.pressed, value: false),
          // The chrome is built around the `EditableText`, so it falls outside
          // the region `EditableText` installs for itself and a press on the
          // field's own padding read as a tap *outside* it — dropping focus on
          // pointer down, and taking the selection with it now that blur
          // collapses the range. `buildFluentInput` carries the same wrapper.
          child: IgnorePointer(
            ignoring: !_enabled,
            child: TextFieldTapRegion(child: chrome),
          ),
        ),
      ),
    );
  }
}
