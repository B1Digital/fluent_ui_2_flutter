import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import '../internal/text_context_menu.dart';
import '../l10n/l10n.dart';
import 'input.dart';
import 'search_box_style.dart';

/// How a search box is filled and outlined. Figma's `Style` axis.
///
/// The names are Figma's. Upstream React calls [FluentSearchBoxAppearance
/// .transparent] `underline`, which describes the same thing — no fill, a
/// bottom rule only.
enum FluentSearchBoxAppearance {
  /// `neutralBackground3`, no visible border. Figma's default variant.
  filledDarker,

  /// `neutralBackground1`, no visible border.
  filledLighter,

  /// `neutralBackground1` with a `neutralStroke1` border and a higher-contrast
  /// `neutralStrokeAccessible` bottom rule. The default, matching upstream's
  /// `appearance = 'outline'`.
  outline,

  /// No fill and no border — only the `neutralStrokeAccessible` bottom rule.
  transparent,
}

/// Control height and type ramp. Figma's `Size` axis.
enum FluentSearchBoxSize {
  /// 24 high, `caption1` type.
  small,

  /// 32 high, `body1` type. The default.
  medium,

  /// 40 high, `body2` type.
  large,
}

/// Which glyph [FluentSearchBoxGlyphPainter] draws.
enum FluentSearchBoxGlyph {
  /// `Search20Regular` — the leading magnifier.
  search,

  /// `Dismiss20Regular` — the trailing clear cross.
  dismiss,
}

/// The focus underline scaling **in**.
///
/// Transcribed from `useInputStyles.styles.ts`, `:focus-within::after`:
/// `transform: scaleX(1)`, `transitionProperty: transform`,
/// `transitionDuration: durationNormal`.
///
/// Upstream writes the easing into `transitionDelay` rather than
/// `transitionTimingFunction` — `transitionDelay: tokens.curveDecelerateMid` —
/// which a browser rejects, so the shipped animation runs on the CSS default
/// `ease`. The curve token is transcribed here as the easing it was plainly
/// meant to be; the duration is upstream's verbatim.
///
/// The bar itself is [FluentInputFocusUnderline], whose spec carries the same
/// two tokens off the same `::after` rule — so this is an alias rather than a
/// second copy of them.
const FluentMotionSpec fluentSearchBoxUnderlineEnter =
    fluentInputFocusUnderlineEnter;

/// The focus underline scaling **out**.
///
/// The same `::after` rule at rest: `transform: scaleX(0)` over
/// `durationUltraFast`, with `curveAccelerateMid` in the same misplaced
/// `transitionDelay` slot. Deliberately four times faster than
/// [fluentSearchBoxUnderlineEnter] — the asymmetry is upstream's.
///
/// An alias of [fluentInputFocusUnderlineExit], for the reason given on
/// [fluentSearchBoxUnderlineEnter].
const FluentMotionSpec fluentSearchBoxUnderlineExit =
    fluentInputFocusUnderlineExit;

/// Everything needed to render a search box, independent of appearance and
/// size.
///
/// [buildFluentSearchBox] takes this rather than [FluentSearchBoxState], which
/// is what makes "Fluent's state, my own styling, Fluent's rendering" a
/// supported path rather than a fork.
@immutable
class FluentSearchBoxBaseState {
  /// Creates a base state.
  const FluentSearchBoxBaseState({
    required this.enabled,
    required this.focused,
    required this.field,
    this.placeholder,
    this.icon,
    this.clear,
  });

  /// Whether the search box accepts input.
  final bool enabled;

  /// Whether focus is anywhere inside the control.
  ///
  /// This is upstream's `:focus-within`, **not** [WidgetState.focused]: a text
  /// field raises its underline whether focus arrived by click or by keyboard,
  /// so keyboard-visible focus is the wrong signal and is deliberately never
  /// put into the resolved state set.
  final bool focused;

  /// The text editor itself. Supplied by the caller so
  /// [buildFluentSearchBox] stays a pure function of widgets.
  final Widget field;

  /// Shown over [field] while the value is empty.
  final Widget? placeholder;

  /// The leading glyph. Null renders nothing in the leading slot.
  final Widget? icon;

  /// The trailing clear affordance. Null hides it, which is how "not focused"
  /// is expressed.
  final Widget? clear;
}

/// A search box's fully resolved state, including the design axes.
@immutable
class FluentSearchBoxState extends FluentSearchBoxBaseState {
  /// Creates a resolved state.
  const FluentSearchBoxState({
    required super.enabled,
    required super.focused,
    required super.field,
    required this.appearance,
    required this.size,
    super.placeholder,
    super.icon,
    super.clear,
  });

  /// Fill and outline treatment.
  final FluentSearchBoxAppearance appearance;

  /// Height and type ramp.
  final FluentSearchBoxSize size;
}

/// Builds the state a search box will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentSearchBoxState resolveFluentSearchBoxState({
  required Widget field,
  bool enabled = true,
  bool focused = false,
  FluentSearchBoxAppearance appearance = FluentSearchBoxAppearance.outline,
  FluentSearchBoxSize size = FluentSearchBoxSize.medium,
  Widget? placeholder,
  Widget? icon,
  Widget? clear,
}) => FluentSearchBoxState(
  enabled: enabled,
  focused: focused,
  field: field,
  appearance: appearance,
  size: size,
  placeholder: placeholder,
  icon: icon,
  clear: clear,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `SearchBox` component set (`9315:3026`, 36
/// variants over `Style`, `Size` and `State`), extracted into
/// `test/fixtures/search_box.json`, reconciled against
/// `useSearchBoxStyles.styles.ts` and `useInputStyles.styles.ts`.
///
/// Three things worth knowing before "correcting" anything below:
///
/// * **Focus does not move the border.** All twelve Figma `State=Focus`
///   variants bind `Neutral/Stroke/1/Rest`, where React's `:focus-within`
///   selects `colorNeutralStroke1Pressed`. Figma wins; the focus signal is the
///   2px `compoundBrandStroke` underline and nothing else.
/// * **The filled appearances keep a transparent border.** Figma paints no
///   stroke on them at all — it binds `Stroke width/Thin` and leaves the paint
///   empty — but Fluent's transparent stroke tokens turn *opaque* in high
///   contrast, and that border is the only thing outlining a filled search box
///   there. This is the same call `FluentSwitch` makes about its checked track.
/// * **Disabled comes from React alone.** The Figma set has no `Disabled`
///   variant, so the whole disabled ramp is `useInputStyles.styles.ts`
///   verbatim: a transparent fill, `neutralStrokeDisabled` all round, no
///   bottom rule and no focus underline.
FluentSearchBoxStyle resolveFluentSearchBoxStyle(
  FluentSearchBoxState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final disabled = !state.enabled;

  final background = switch (state.appearance) {
    _ when disabled => FluentStateColor.tokens(rest: c.transparentBackground),
    FluentSearchBoxAppearance.filledDarker => FluentStateColor.tokens(
      rest: c.neutralBackground3,
    ),
    FluentSearchBoxAppearance.filledLighter ||
    FluentSearchBoxAppearance.outline => FluentStateColor.tokens(
      rest: c.neutralBackground1,
    ),
    // Figma paints nothing here; upstream's `underline` sets
    // colorTransparentBackground, which is a real token and turns opaque in
    // high contrast where a bare surface would not.
    FluentSearchBoxAppearance.transparent => FluentStateColor.tokens(
      rest: c.transparentBackground,
    ),
  };

  final border = switch (state.appearance) {
    _ when disabled => FluentStateColor.tokens(rest: c.neutralStrokeDisabled),
    FluentSearchBoxAppearance.outline => FluentStateColor.tokens(
      rest: c.neutralStroke1,
      hover: c.neutralStroke1Hover,
    ),
    FluentSearchBoxAppearance.filledDarker ||
    FluentSearchBoxAppearance.filledLighter => FluentStateColor.tokens(
      rest: c.transparentStroke,
      hover: c.transparentStrokeInteractive,
    ),
    // Upstream's `underline` strips the top, left and right borders outright.
    FluentSearchBoxAppearance.transparent => null,
  };

  // The 1px rule Figma draws across the bottom as its own full-width rectangle
  // rather than as a border side.
  //
  // Figma's `Style=Transparent, State=Hover` variants bind
  // `Neutral/Stroke/Accessible/Rest` where their `Style=Outline` twins bind
  // `.../Hover` — Figma disagreeing with itself about the same physical rule,
  // on the one appearance where that rule is the entire component. React ramps
  // both (`underlineInteractive`), so both ramp here.
  final bottomBorder = switch (state.appearance) {
    _ when disabled => null,
    FluentSearchBoxAppearance.outline ||
    FluentSearchBoxAppearance.transparent => FluentStateColor.tokens(
      rest: c.neutralStrokeAccessible,
      hover: c.neutralStrokeAccessibleHover,
    ),
    FluentSearchBoxAppearance.filledDarker ||
    FluentSearchBoxAppearance.filledLighter => null,
  };

  // Geometry, verbatim from the Figma SearchBox set. The `padding` is the
  // `Contents` frame's horizontal inset; `gap` is the `Icon-Text-stack`'s
  // itemSpacing plus the `.Text` slot's own XXS inset; `contentGap` is the
  // `Contents` itemSpacing plus the `Icon after container`'s XXS inset.
  final (
    padding,
    height,
    textStyle,
    iconSize,
    clearIconSize,
  ) = switch (state.size) {
    FluentSearchBoxSize.small => (
      FluentSpacing.sNudge,
      24.0,
      theme.typography.caption1,
      16.0,
      // 12, not React's 16. Figma draws both trailing glyphs at 12 in every
      // small variant.
      12.0,
    ),
    FluentSearchBoxSize.medium => (
      FluentSpacing.s,
      32.0,
      theme.typography.body1,
      20.0,
      20.0,
    ),
    FluentSearchBoxSize.large => (
      FluentSpacing.mNudge,
      40.0,
      theme.typography.body2,
      24.0,
      24.0,
    ),
  };

  return FluentSearchBoxStyle(
    backgroundColor: background,
    borderColor: border,
    bottomBorderColor: bottomBorder,
    // `disabled` sets `::after { content: unset }` upstream: the focus bar is
    // removed outright, not merely never scaled up. The Pressed stop is
    // React's alone — `':focus-within:active::after'` moves the bar to
    // `colorCompoundBrandStrokePressed`, and Figma's SearchBox set has no
    // Pressed state to disagree with. `FluentInput` and `FluentTextarea`
    // already carry it.
    focusUnderlineColor: disabled
        ? null
        : FluentStateColor.tokens(
            rest: c.compoundBrandStroke,
            pressed: c.compoundBrandStrokePressed,
          ),
    borderWidth: WidgetStatePropertyAll<double?>(
      border == null ? FluentStroke.none : FluentStroke.thin,
    ),
    // `Corner-radius/Input/Small` and `Corner-radius/Input/Medium` both resolve
    // to 4, so one radius covers every size — as React's hard-coded
    // borderRadiusMedium does.
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    foregroundColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground1,
    ),
    placeholderColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground4,
    ),
    iconColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground3,
    ),
    cursorColor: FluentStateColor.tokens(rest: c.neutralForeground1),
    // Fluent names no selection token on any platform — upstream declares no
    // `::selection` rule and lets the user agent decide. `brandBackground2` is
    // the brand tint Office surfaces use for the same job, and it is a real
    // token rather than a computed wash.
    selectionColor: FluentStateColor.tokens(rest: c.brandBackground2),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: padding),
    ),
    gap: const WidgetStatePropertyAll<double?>(
      FluentSpacing.xs + FluentSpacing.xxs,
    ),
    contentGap: const WidgetStatePropertyAll<double?>(
      FluentSpacing.mNudge + FluentSpacing.xxs,
    ),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    clearIconSize: WidgetStatePropertyAll<double?>(clearIconSize),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    // Upstream caps every size at 468px, which is also the width of all 36
    // Figma variant frames.
    maximumSize: const WidgetStatePropertyAll<Size?>(
      Size(468, double.infinity),
    ),
    mouseCursor: WidgetStatePropertyAll<MouseCursor?>(
      disabled ? SystemMouseCursors.basic : SystemMouseCursors.text,
    ),
  );
}

/// Renders a search box from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentSearchBoxBaseState] rather than [FluentSearchBoxState] on purpose: it
/// never reads appearance or size.
///
/// ## What animates, and what does not
///
/// Exactly one thing: the 2px focus underline scales on X from the centre,
/// [fluentSearchBoxUnderlineEnter] in and [fluentSearchBoxUnderlineExit] out.
/// `useSearchBoxStyles.styles.ts` declares no transition of its own at all —
/// the whole animation lives in `useInputStyles.styles.ts`'s `::after` rule,
/// which is the only `transition` either file contains. Fills, borders and the
/// clear button appearing all change on the frame they change, and reduced
/// motion is handled inside [FluentInputFocusUnderline], which is the bar.
///
/// The bottom rule is drawn as a square-cornered overlay rather than a
/// [BorderSide], for two reasons: Flutter refuses a rounded rectangle whose
/// border sides disagree in colour, and Figma models it the same way — a
/// full-width `Thin underline` rectangle laid over the `Contents` frame.
///
/// [states] is the resolved interaction set: hovered and disabled only. See
/// [FluentSearchBoxBaseState.focused] for why focus is not in it.
Widget buildFluentSearchBox(
  FluentSearchBoxBaseState state,
  FluentSearchBoxStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final bottomBorderColor = style.bottomBorderColor?.resolve(states);
  final underlineColor = style.focusUnderlineColor?.resolve(states);
  final iconColor = style.iconColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final placeholderColor = style.placeholderColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states) ?? const TextStyle();
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.sNudge;
  final contentGap = style.contentGap?.resolve(states) ?? FluentSpacing.m;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final clearIconSize =
      style.clearIconSize?.resolve(states) ?? FluentSize.size200;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  final maximumSize =
      style.maximumSize?.resolve(states) ??
      const Size(double.infinity, double.infinity);

  final field = state.placeholder == null
      ? state.field
      : Stack(
          alignment: AlignmentDirectional.centerStart,
          children: <Widget>[
            // Behind the editor and never hit-testable, so a tap lands on the
            // field rather than on the hint.
            IgnorePointer(
              child: DefaultTextStyle.merge(
                style: textStyle.copyWith(color: placeholderColor),
                overflow: TextOverflow.clip,
                softWrap: false,
                child: state.placeholder!,
              ),
            ),
            state.field,
          ],
        );

  final row = Row(
    children: <Widget>[
      if (state.icon != null)
        IconTheme.merge(
          data: IconThemeData(color: iconColor, size: iconSize),
          child: SizedBox(width: iconSize, height: iconSize, child: state.icon),
        ),
      if (state.icon != null) SizedBox(width: gap),
      Expanded(child: field),
      if (state.clear != null) ...<Widget>[
        SizedBox(width: contentGap),
        IconTheme.merge(
          data: IconThemeData(color: iconColor, size: clearIconSize),
          child: SizedBox(
            width: clearIconSize,
            height: clearIconSize,
            child: state.clear,
          ),
        ),
      ],
    ],
  );

  final surface = DecoratedBox(
    decoration: BoxDecoration(
      color: style.backgroundColor?.resolve(states),
      borderRadius: radius,
      border: borderWidth > 0 && borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
    ),
    child: Padding(
      padding: padding,
      child: DefaultTextStyle.merge(
        style: textStyle.copyWith(color: foreground),
        child: row,
      ),
    ),
  );

  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maximumSize.width),
    child: Stack(
      children: <Widget>[
        // The minimum has to reach the DECORATED box, not the Stack.
        // RenderStack lays non-positioned children out with StackFit.loose,
        // which drops minHeight to 0 — so a ConstrainedBox wrapped around the
        // Stack leaves the surface to size to its 20px content and strands both
        // bottom-pinned overlays a dozen pixels below it. FluentInput already
        // nests it this way.
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minimumSize.height,
            minWidth: minimumSize.width,
          ),
          child: surface,
        ),
        if (bottomBorderColor != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            // Figma's `Thin underline` is its own 1px rectangle rather than a
            // border side, so it does not follow `borderWidth` — the
            // Transparent appearance has no border at all and still draws it.
            height: FluentStroke.thin,
            // Rounded like the accent below it: a bare rectangle here runs
            // past the field's curve at both ends. See FluentInputUnderline.
            child: FluentInputUnderline(
              color: bottomBorderColor,
              thickness: FluentStroke.thin,
              borderRadius: BorderRadius.only(
                bottomLeft: radius.bottomLeft,
                bottomRight: radius.bottomRight,
              ),
            ),
          ),
        if (underlineColor != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: FluentStroke.thick,
            child: FluentInputFocusUnderline(
              focused: state.focused && state.enabled,
              color: underlineColor,
              borderRadius: BorderRadius.only(
                bottomLeft: radius.bottomLeft,
                bottomRight: radius.bottomRight,
              ),
            ),
          ),
      ],
    ),
  );
}

/// Paints the leading magnifier and the trailing clear cross.
///
/// A painter rather than icon widgets because this package ships no icon font.
/// Both outlines are transcribed from `microsoft/fluentui-system-icons`
/// (`Search20Regular`, `Dismiss20Regular`) and normalised against their own
/// 20-unit viewBox, so they scale with the glyph box the way the icon
/// components do.
///
/// Every input is a public field so tests can assert the resolved glyph and
/// tone directly instead of diffing pixels.
class FluentSearchBoxGlyphPainter extends CustomPainter {
  /// Creates a painter for one glyph and tone.
  const FluentSearchBoxGlyphPainter({required this.glyph, required this.color});

  /// Which shape to draw.
  final FluentSearchBoxGlyph glyph;

  /// The glyph tone. `neutralForeground3`, or `neutralForegroundDisabled`.
  final Color color;

  // Search20Regular: a ring centred at (8.5, 8.5) whose outer radius is 5.5 and
  // inner radius 4 — a 1.5-wide stroke on a 4.75 centreline — plus a 1.5-wide
  // round-capped handle running out to (16.6, 16.6).
  static const double _ringCentre = 8.5 / 20;
  static const double _ringRadius = 4.75 / 20;
  static const double _handleStart = 11.86 / 20;
  static const double _handleEnd = 16.6 / 20;

  // Dismiss20Regular: two 1.5-wide round-capped strokes across the box.
  static const double _crossMin = 4.5 / 20;
  static const double _crossMax = 15.5 / 20;

  // ponytail: one stroke width, scaled proportionally. Fluent draws separate
  // 12/16/24 glyphs whose ink is optically tuned rather than scaled; split this
  // into a per-size table if a fixture ever disagrees.
  static const double _strokeWidth = 1.5 / 20;

  @override
  void paint(Canvas canvas, Size size) {
    final edge = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth * edge
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (glyph) {
      case FluentSearchBoxGlyph.search:
        canvas
          ..drawCircle(
            Offset(_ringCentre * edge, _ringCentre * edge),
            _ringRadius * edge,
            paint,
          )
          ..drawLine(
            Offset(_handleStart * edge, _handleStart * edge),
            Offset(_handleEnd * edge, _handleEnd * edge),
            paint,
          );
      case FluentSearchBoxGlyph.dismiss:
        canvas
          ..drawLine(
            Offset(_crossMin * edge, _crossMin * edge),
            Offset(_crossMax * edge, _crossMax * edge),
            paint,
          )
          ..drawLine(
            Offset(_crossMax * edge, _crossMin * edge),
            Offset(_crossMin * edge, _crossMax * edge),
            paint,
          );
    }
  }

  @override
  bool shouldRepaint(FluentSearchBoxGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}

/// Overrides the search box style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentSearchBoxTheme extends InheritedTheme {
  /// Applies [style] to every `FluentSearchBox` in [child].
  const FluentSearchBoxTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentSearchBoxStyle style;

  /// The nearest search box style, or null.
  static FluentSearchBoxStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentSearchBoxTheme>()?.style;

  @override
  bool updateShouldNotify(FluentSearchBoxTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentSearchBoxTheme(style: style, child: child);
}

/// Clears the field. Bound to Escape, matching `<input type="search">`.
class _ClearIntent extends Intent {
  const _ClearIntent();
}

/// A Fluent 2 search box: a single-line text field with a leading magnifier and
/// a trailing clear button.
///
/// ```dart
/// FluentSearchBox(
///   placeholder: 'Search',
///   onChanged: (value) => setState(() => query = value),
///   onSubmitted: search,
/// )
/// ```
///
/// ## When the clear button shows
///
/// **While focus is inside the control**, which is what both sources say:
/// upstream collapses the whole `contentAfter` slot to zero size whenever
/// `!focused`, and Figma hides its `Icon after container` on every `Rest` and
/// `Hover` variant. It is not gated on the value being non-empty. Clearing
/// returns focus to the field, as upstream does.
///
/// ## Keyboard
///
/// Escape clears the field — the behaviour a browser gives
/// `<input type="search">` for free and which upstream inherits by setting that
/// type. The clear button itself is deliberately outside the tab order, again
/// matching upstream, which gives it `tabIndex: -1`.
///
/// ## Disabled
///
/// Pass `enabled: false` — a real state, not a visual treatment: the field
/// stops accepting input and reporting hover, refuses focus, hides the clear
/// button and the focus underline, and swaps to the disabled token ramp
/// wholesale.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentSearchBoxTheme] restyles a subtree; and for anything further,
/// [resolveFluentSearchBoxState], [resolveFluentSearchBoxStyle] and
/// [buildFluentSearchBox] are public so any one of them can be replaced without
/// forking this widget.
class FluentSearchBox extends StatefulWidget {
  /// Creates a search box.
  const FluentSearchBox({
    super.key,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.appearance = FluentSearchBoxAppearance.outline,
    this.size = FluentSearchBoxSize.medium,
    this.placeholder,
    this.icon,
    this.clearIcon,
    this.style,
    this.autofocus = false,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.search,
    this.selectionControls,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.semanticLabel,
    this.clearSemanticLabel,
  });

  /// The controller. One is created and disposed internally when omitted.
  final TextEditingController? controller;

  /// The focus node. One is created and disposed internally when omitted.
  final FocusNode? focusNode;

  /// Whether the search box accepts input. False is a real disabled state.
  final bool enabled;

  /// Fill and outline treatment.
  final FluentSearchBoxAppearance appearance;

  /// Height and type ramp.
  final FluentSearchBoxSize size;

  /// Hint shown while the value is empty.
  final String? placeholder;

  /// The leading glyph. Defaults to a painted `Search20Regular`; pass an empty
  /// `SizedBox` to drop the slot entirely.
  final Widget? icon;

  /// The trailing clear glyph. Defaults to a painted `Dismiss20Regular`.
  final Widget? clearIcon;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentSearchBoxStyle? style;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Whether to hide the value. Rare on a search box; wired for the components
  /// that reuse this editor.
  final bool obscureText;

  /// Whether the value can be selected but not edited.
  final bool readOnly;

  /// Soft-keyboard type.
  final TextInputType keyboardType;

  /// Soft-keyboard action key. Defaults to [TextInputAction.search].
  final TextInputAction textInputAction;

  /// Selection handles and toolbar.
  ///
  /// Null on purpose: this is the *web and desktop* rendering, where a text
  /// field shows a caret and a drag selection but no handles, and the context
  /// menu is the platform's. Pass the touch controls when embedding this on a
  /// touch surface.
  final TextSelectionControls? selectionControls;

  /// Called on every edit, including a clear.
  final ValueChanged<String>? onChanged;

  /// Called when the user commits with Enter.
  final ValueChanged<String>? onSubmitted;

  /// Called after the value is cleared, by the button or by Escape.
  final VoidCallback? onClear;

  /// Announced by assistive technology as the field's name.
  final String? semanticLabel;

  /// Announced by assistive technology for the clear button.
  ///
  /// Null takes the wording from the ambient [FluentLocalizations],
  /// which falls back to English when no delegate is installed.
  final String? clearSemanticLabel;

  @override
  State<FluentSearchBox> createState() => _FluentSearchBoxState();
}

class _FluentSearchBoxState extends State<FluentSearchBox>
    implements TextSelectionGestureDetectorBuilderDelegate {
  late final TextSelectionGestureDetectorBuilder _selectionGestures =
      TextSelectionGestureDetectorBuilder(delegate: this);

  // Never traversed to, matching upstream's `tabIndex: -1` on the dismiss slot.
  // The clear button is a pointer affordance; Escape is the keyboard path.
  final FocusNode _clearFocusNode = FocusNode(
    skipTraversal: true,
    debugLabel: 'FluentSearchBox clear',
  );

  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;
  bool _hovered = false;

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => _interactive;

  bool get _interactive => widget.enabled && !widget.readOnly;

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _focusNode.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(FluentSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalController)?.removeListener(_onChanged);
      _controller.addListener(_onChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_onChanged);
      _focusNode.addListener(_onChanged);
    }
    // Disabling mid-hover must not leave a stale hover behind.
    if (!widget.enabled && _hovered) _hovered = false;
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _focusNode.removeListener(_onChanged);
    _internalController?.dispose();
    _internalFocusNode?.dispose();
    _clearFocusNode.dispose();
    super.dispose();
  }

  // One listener for both the value and the focus: the placeholder, the clear
  // button and the underline all depend on one or the other.
  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _clear() {
    if (_controller.text.isEmpty) return;
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
    // Upstream returns focus to the input after a dismiss click, so the user
    // can keep typing.
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    // Resolved twice over — once with the axes to get the defaults, then
    // layered — exactly as the button does.
    final probe = resolveFluentSearchBoxState(
      field: const SizedBox.shrink(),
      enabled: widget.enabled,
      appearance: widget.appearance,
      size: widget.size,
    );
    final resolved = resolveFluentSearchBoxStyle(
      probe,
      theme,
    ).merge(FluentSearchBoxTheme.maybeOf(context)).merge(widget.style);

    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (_hovered && widget.enabled) WidgetState.hovered,
    };

    final textStyle = resolved.textStyle?.resolve(states) ?? const TextStyle();
    final foreground = resolved.foregroundColor?.resolve(states);
    final iconColor = resolved.iconColor?.resolve(states);
    final clearIconSize =
        resolved.clearIconSize?.resolve(states) ?? FluentSize.size200;

    final field = _selectionGestures.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: EditableText(
        key: editableTextKey,
        controller: _controller,
        focusNode: _focusNode,
        readOnly: widget.readOnly || !widget.enabled,
        autofocus: widget.autofocus,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        selectionControls: widget.selectionControls,
        contextMenuBuilder: fluentTextContextMenuBuilder,
        enableInteractiveSelection: _interactive,
        // The gesture detector above owns pointers, which is what makes
        // drag-to-select and double-tap-to-select-word work.
        rendererIgnoresPointer: true,
        style: textStyle.copyWith(color: foreground),
        cursorColor:
            resolved.cursorColor?.resolve(states) ??
            theme.colors.neutralForeground1,
        backgroundCursorColor: theme.colors.neutralForeground3,
        selectionColor: _interactive
            ? resolved.selectionColor?.resolve(states)
            : null,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      ),
    );

    final showClear = widget.enabled && _focusNode.hasFocus;

    final state = resolveFluentSearchBoxState(
      field: field,
      enabled: widget.enabled,
      focused: _focusNode.hasFocus,
      appearance: widget.appearance,
      size: widget.size,
      placeholder: _controller.text.isEmpty && widget.placeholder != null
          ? Text(widget.placeholder!, maxLines: 1)
          : null,
      icon:
          widget.icon ??
          CustomPaint(
            painter: FluentSearchBoxGlyphPainter(
              glyph: FluentSearchBoxGlyph.search,
              color: iconColor ?? theme.colors.neutralForeground3,
            ),
          ),
      clear: showClear
          ? Semantics(
              button: true,
              label: widget.clearSemanticLabel ?? fluentL10n(context).clear,
              child: FluentInteractive(
                onPressed: _clear,
                focusNode: _clearFocusNode,
                builder: (context, _, _) =>
                    widget.clearIcon ??
                    CustomPaint(
                      size: Size.square(clearIconSize),
                      painter: FluentSearchBoxGlyphPainter(
                        glyph: FluentSearchBoxGlyph.dismiss,
                        color: iconColor ?? theme.colors.neutralForeground3,
                      ),
                    ),
              ),
            )
          : null,
    );

    var searchBox = buildFluentSearchBox(state, resolved, states);

    searchBox = MouseRegion(
      cursor: resolved.mouseCursor?.resolve(states) ?? SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.enabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        // Clicking the padding, the leading glyph or anywhere else that is not
        // itself interactive focuses the field, the way a browser focuses an
        // input when its wrapper is clicked.
        onTap: _interactive ? _focusNode.requestFocus : null,
        child: searchBox,
      ),
    );

    return Semantics(
      textField: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): _ClearIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _ClearIntent: CallbackAction<_ClearIntent>(
              onInvoke: (_) {
                if (_interactive) _clear();
                return null;
              },
            ),
          },
          child: searchBox,
        ),
      ),
    );
  }
}
