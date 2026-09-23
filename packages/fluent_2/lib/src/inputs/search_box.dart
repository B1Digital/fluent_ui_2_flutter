import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import '../internal/text_context_menu.dart';
import '../internal/text_selection_dismiss.dart';
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
/// `ease` ([FluentCssCubic.ease]) with no delay. The port ports what renders,
/// not what the typo suggests was meant; the duration is upstream's verbatim.
///
/// The bar itself is [FluentInputFocusUnderline], whose spec comes off the same
/// `::after` rule — so this is an alias rather than a second copy of it.
const FluentMotionSpec fluentSearchBoxUnderlineEnter =
    fluentInputFocusUnderlineEnter;

/// The focus underline scaling **out**.
///
/// The same `::after` rule at rest: `transform: scaleX(0)` over
/// `durationUltraFast`, with `curveAccelerateMid` in the same misplaced
/// `transitionDelay` slot, so on `ease` as well. Deliberately four times faster
/// than [fluentSearchBoxUnderlineEnter] — the asymmetry is upstream's.
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
    this.error = false,
    super.placeholder,
    super.icon,
    super.clear,
  });

  /// Fill and outline treatment.
  final FluentSearchBoxAppearance appearance;

  /// Whether the field is showing a validation error: upstream's
  /// `aria-invalid="true"`, which the root styles with Input's invalid rule.
  final bool error;

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
  bool error = false,
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
  error: error,
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
/// The oracle is upstream as it renders — `useSearchBoxStyles.styles.ts` over
/// `useInputStyles.styles.ts`, measured in Chrome on the live storybook
/// (`components-searchbox--default`) — not the Figma `SearchBox` set. The root
/// is a `.fui-Input`, so every border, radius, bar and invalid value is
/// Input's, and resolves exactly as [resolveFluentInputStyle] does:
///
/// * **Focus moves the border.** `outlineInteractive` writes
///   `:active,:focus-within` as one rule, which Griffel sorts after `:hover`,
///   so a focused box shows `Stroke1Pressed` / `StrokeAccessiblePressed`
///   whether or not it is hovered. A press held anywhere on the root shows the
///   same colours, focused or not.
/// * **The filled appearances keep a transparent border.** It takes up 1px
///   like any CSS border, and Fluent's transparent stroke tokens turn *opaque*
///   in high contrast, where it is the only thing outlining a filled box.
/// * **Read only has no styling.** Only [FluentSearchBoxBaseState.enabled]
///   changes the ramp.
/// * **Invalid is `colorPaletteRedBorder2`**, under
///   `:not(:focus-within)`: a focused invalid box falls back to the ordinary
///   ramp and the brand bar.
/// * **Disabled** is a transparent fill and `neutralStrokeDisabled` on every
///   side that exists — all four on Outline and the filled pair, the bottom
///   alone on Transparent — and no focus bar.
FluentSearchBoxStyle resolveFluentSearchBoxStyle(
  FluentSearchBoxState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final disabled = !state.enabled;
  final focused = state.focused;
  final invalid = state.error && !focused;
  final underline = state.appearance == FluentSearchBoxAppearance.transparent;
  // `colorPaletteRedBorder2`. The palette layer knows nothing of high contrast,
  // where the status token is the system text colour instead.
  final danger = c is FluentHighContrastColors
      ? c.statusDangerBorder2
      : c.palette.stroke2Rest(FluentPaletteFamily.red)!;

  final background = switch (state.appearance) {
    _ when disabled => FluentStateColor.tokens(rest: c.transparentBackground),
    FluentSearchBoxAppearance.filledDarker => FluentStateColor.tokens(
      rest: c.neutralBackground3,
    ),
    FluentSearchBoxAppearance.filledLighter ||
    FluentSearchBoxAppearance.outline => FluentStateColor.tokens(
      rest: c.neutralBackground1,
    ),
    // Upstream's `underline` sets colorTransparentBackground, which is a real
    // token and turns opaque in high contrast where a bare surface would not.
    FluentSearchBoxAppearance.transparent => FluentStateColor.tokens(
      rest: c.transparentBackground,
    ),
  };

  // The ordinary interactive ramp. Focus holds the Pressed stop through a
  // hover: see the doc comment.
  WidgetStateProperty<Color> ramp(Color rest, Color hover, Color pressed) =>
      FluentStateColor.tokens(
        rest: focused ? pressed : rest,
        hover: focused ? pressed : hover,
        pressed: pressed,
      );

  final border = switch (state.appearance) {
    // Upstream's `underline` strips the top, left and right borders outright,
    // disabled or not.
    FluentSearchBoxAppearance.transparent => null,
    _ when disabled => FluentStateColor.tokens(rest: c.neutralStrokeDisabled),
    _ when invalid => FluentStateColor.tokens(rest: danger),
    FluentSearchBoxAppearance.outline => ramp(
      c.neutralStroke1,
      c.neutralStroke1Hover,
      c.neutralStroke1Pressed,
    ),
    // `filledInteractive` moves `:hover` and `:focus-within` (and therefore
    // `:active`) to the Interactive token.
    FluentSearchBoxAppearance.filledDarker ||
    FluentSearchBoxAppearance.filledLighter => FluentStateColor.tokens(
      rest: focused ? c.transparentStrokeInteractive : c.transparentStroke,
      hover: c.transparentStrokeInteractive,
      pressed: c.transparentStrokeInteractive,
    ),
  };

  // The bottom border, in its own higher-contrast token. The filled pair have
  // none of their own: their transparent border runs round all four sides.
  final bottomBorder = switch (state.appearance) {
    FluentSearchBoxAppearance.filledDarker ||
    FluentSearchBoxAppearance.filledLighter => null,
    _ when disabled => FluentStateColor.tokens(rest: c.neutralStrokeDisabled),
    _ when invalid => FluentStateColor.tokens(rest: danger),
    FluentSearchBoxAppearance.outline ||
    FluentSearchBoxAppearance.transparent => ramp(
      c.neutralStrokeAccessible,
      c.neutralStrokeAccessibleHover,
      c.neutralStrokeAccessiblePressed,
    ),
  };

  // Upstream's box, inside the 1px border: root padding 6 / 8 / 10 on each
  // side; `gap` is the `<input>`'s own padding-left (SNudge; the root's
  // column-gap is 0); `contentGap` is the `contentAfter` slot's padding-left
  // (M). Both glyphs are 1em SVGs on the same 16 / 20 / 24 font-size ramp.
  final (padding, height, textStyle, iconSize) = switch (state.size) {
    FluentSearchBoxSize.small => (
      FluentSpacing.sNudge,
      24.0,
      theme.typography.caption1,
      FluentSize.size160,
    ),
    FluentSearchBoxSize.medium => (
      FluentSpacing.s,
      32.0,
      theme.typography.body1,
      FluentSize.size200,
    ),
    FluentSearchBoxSize.large => (
      FluentSpacing.mNudge,
      40.0,
      theme.typography.body2,
      FluentSize.size240,
    ),
  };

  return FluentSearchBoxStyle(
    backgroundColor: background,
    borderColor: border,
    bottomBorderColor: bottomBorder,
    // `disabled` sets `::after { content: unset }` upstream: the focus bar is
    // removed outright, not merely never scaled up.
    // `':focus-within:active::after'` moves it to the Pressed stop.
    focusUnderlineColor: disabled
        ? null
        : FluentStateColor.tokens(
            rest: c.compoundBrandStroke,
            pressed: c.compoundBrandStrokePressed,
          ),
    borderWidth: WidgetStatePropertyAll<double?>(
      border == null ? FluentStroke.none : FluentStroke.thin,
    ),
    // Underline zeroes both the root's radius and the focus bar's
    // (`underlineInteractive`'s `::after { borderRadius: 0 }`): a flat rule
    // with square ends. Every other appearance is borderRadiusMedium at every
    // size.
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(
      underline ? BorderRadius.zero : FluentRadius.allMedium,
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
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.sNudge),
    contentGap: const WidgetStatePropertyAll<double?>(FluentSpacing.m),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    clearIconSize: WidgetStatePropertyAll<double?>(iconSize),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    // Upstream caps every size at 468px.
    maximumSize: const WidgetStatePropertyAll<Size?>(
      Size(468, double.infinity),
    ),
    // The `<input>`'s cursor, which [buildFluentSearchBox] puts on the text
    // column. The root padding and the search icon show the arrow; disabled is
    // `not-allowed` everywhere.
    mouseCursor: WidgetStatePropertyAll<MouseCursor?>(
      disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.text,
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
/// The border is [FluentInputBorderPainter], shared with `FluentInput`: it
/// takes up space the way a CSS border does, and joins the bottom colour to
/// the sides on the CSS corner diagonal.
///
/// [states] is the resolved interaction set: hovered, pressed and disabled.
/// See [FluentSearchBoxBaseState.focused] for why focus is not in it.
Widget buildFluentSearchBox(
  FluentSearchBoxBaseState state,
  FluentSearchBoxStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final bottomColor = style.bottomBorderColor?.resolve(states);
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
  final mouseCursor = style.mouseCursor?.resolve(states) ?? MouseCursor.defer;

  // CSS box model: a border that exists takes space, so the content sits
  // inside it — 1px on every side for Outline and the filled pair (whose
  // transparent border still counts), the bottom alone for Transparent. The
  // bottom is 1px in every state: upstream recolours it, never thickens it.
  final side = borderColor == null ? FluentStroke.none : borderWidth;
  final widths = EdgeInsets.fromLTRB(
    side,
    side,
    side,
    bottomColor == null ? side : FluentStroke.thin,
  );

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

  // [end] is the `<input>`'s own padding-right; see the Builder below.
  Widget row(double end) => Row(
    children: <Widget>[
      if (state.icon != null)
        IconTheme.merge(
          data: IconThemeData(color: iconColor, size: iconSize),
          child: _SnapToPixel(
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: state.icon,
            ),
          ),
        ),
      // The `<input>`'s box: its padding-left (the gap) plus the text, the full
      // height of the content box. It is what shows the text cursor; the root
      // padding and the icon keep the arrow. The gap stays without an icon:
      // it is the input's own padding, not spacing after the glyph (storybook,
      // `contentBefore: null`, text at 15 of 200).
      Expanded(
        child: MouseRegion(
          cursor: mouseCursor,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, minimumSize.height - widths.vertical),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: gap, end: end),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                heightFactor: 1,
                child: field,
              ),
            ),
          ),
        ),
      ),
      if (state.clear != null) ...<Widget>[
        SizedBox(width: contentGap),
        IconTheme.merge(
          data: IconThemeData(color: iconColor, size: clearIconSize),
          child: _SnapToPixel(
            child: SizedBox(
              width: clearIconSize,
              height: clearIconSize,
              child: state.clear,
            ),
          ),
        ),
      ],
    ],
  );

  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maximumSize.width),
    child: Stack(
      children: <Widget>[
        // The minimum has to reach the DECORATED box, not the Stack.
        // RenderStack lays non-positioned children out with StackFit.loose,
        // which drops minHeight to 0 — so a ConstrainedBox wrapped around the
        // Stack leaves the surface to size to its 20px content and strands the
        // bottom-pinned bar a dozen pixels below it.
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minimumSize.height,
            minWidth: minimumSize.width,
          ),
          // Background, then border, then content, then the focus bar below:
          // CSS's paint order for a root and its positioned `::after`.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: style.backgroundColor?.resolve(states),
              borderRadius: radius,
            ),
            child: CustomPaint(
              painter: FluentInputBorderPainter(
                radius: radius,
                borderColor: borderColor,
                borderWidth: side,
                bottomBorderColor: bottomColor,
                bottomBorderWidth: widths.bottom,
              ),
              // Without the clear slot, upstream zeroes the root's
              // padding-right and gives the `<input>` the same padding
              // instead, so that strip belongs to the text column: text
              // cursor, and a click there focuses (storybook, x 195 of 200).
              child: Builder(
                builder: (context) {
                  final dir =
                      Directionality.maybeOf(context) ?? TextDirection.ltr;
                  final p = padding.resolve(dir);
                  final end = state.clear != null
                      ? 0.0
                      : dir == TextDirection.ltr
                      ? p.right
                      : p.left;
                  return Padding(
                    padding:
                        p +
                        widths -
                        EdgeInsetsDirectional.only(end: end).resolve(dir),
                    child: DefaultTextStyle.merge(
                      style: textStyle.copyWith(color: foreground),
                      child: row(end),
                    ),
                  );
                },
              ),
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

/// Paints [child] at its offset rounded to whole logical pixels.
///
/// Chrome paints an inline `<svg>` that way: on Transparent the glyphs are
/// centred 5.5px down a 31px content box (the bottom border alone insets it),
/// `getBoundingClientRect` reports 5.5, and the ink lands at 6 — measured at
/// every size in the storybook capture. Layout is untouched; only paint moves.
///
/// ponytail: rounds in the enclosing layer's coordinates, which are the
/// screen's unless a repaint boundary sits at a fractional offset.
class _SnapToPixel extends SingleChildRenderObjectWidget {
  const _SnapToPixel({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSnapToPixel();
}

class _RenderSnapToPixel extends RenderProxyBox {
  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    context.paintChild(
      child,
      Offset(offset.dx.roundToDouble(), offset.dy.roundToDouble()),
    );
  }
}

/// Paints the leading magnifier and the trailing clear cross.
///
/// A painter rather than icon widgets because this package ships no icon font.
/// Both are the `@fluentui/react-icons` `SearchRegular` and `DismissRegular`
/// paths verbatim — the SVGs upstream renders at 1em on a 20-unit viewBox —
/// filled and scaled to the glyph box, so they match Chrome's rendering at
/// 16, 20 and 24.
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

  // M12.73 13.44a6.5 6.5 0 1 1 .7-.7l3.42 3.4a.5.5 0 0 1-.63.77l-.07-.06
  // -3.42-3.41Zm-.71-.71A5.54 5.54 0 0 0 14 8.5a5.5 5.5 0 1 0-1.98 4.23Z
  static final Path _search = Path()
    ..moveTo(12.73, 13.44)
    ..relativeArcToPoint(
      const Offset(.7, -.7),
      radius: const Radius.circular(6.5),
      largeArc: true,
    )
    ..relativeLineTo(3.42, 3.4)
    ..relativeArcToPoint(
      const Offset(-.63, .77),
      radius: const Radius.circular(.5),
    )
    ..relativeLineTo(-.07, -.06)
    ..relativeLineTo(-3.42, -3.41)
    ..close()
    ..moveTo(12.02, 12.73)
    ..arcToPoint(
      const Offset(14, 8.5),
      radius: const Radius.circular(5.54),
      clockwise: false,
    )
    ..relativeArcToPoint(
      const Offset(-1.98, 4.23),
      radius: const Radius.circular(5.5),
      largeArc: true,
      clockwise: false,
    )
    ..close();

  // m4.09 4.22.06-.07a.5.5 0 0 1 .63-.06l.07.06L10 9.29l5.15-5.14a.5.5 0 0 1
  // .63-.06l.07.06c.18.17.2.44.06.63l-.06.07L10.71 10l5.14 5.15c.18.17.2.44.06
  // .63l-.06.07a.5.5 0 0 1-.63.06l-.07-.06L10 10.71l-5.15 5.14a.5.5 0 0 1-.63
  // .06l-.07-.06a.5.5 0 0 1-.06-.63l.06-.07L9.29 10 4.15 4.85a.5.5 0 0 1-.06
  // -.63l.06-.07-.06.07Z
  static final Path _dismiss = () {
    const r = Radius.circular(.5);
    return Path()
      ..moveTo(4.09, 4.22)
      ..relativeLineTo(.06, -.07)
      ..relativeArcToPoint(const Offset(.63, -.06), radius: r)
      ..relativeLineTo(.07, .06)
      ..lineTo(10, 9.29)
      ..relativeLineTo(5.15, -5.14)
      ..relativeArcToPoint(const Offset(.63, -.06), radius: r)
      ..relativeLineTo(.07, .06)
      ..relativeCubicTo(.18, .17, .2, .44, .06, .63)
      ..relativeLineTo(-.06, .07)
      ..lineTo(10.71, 10)
      ..relativeLineTo(5.14, 5.15)
      ..relativeCubicTo(.18, .17, .2, .44, .06, .63)
      ..relativeLineTo(-.06, .07)
      ..relativeArcToPoint(const Offset(-.63, .06), radius: r)
      ..relativeLineTo(-.07, -.06)
      ..lineTo(10, 10.71)
      ..relativeLineTo(-5.15, 5.14)
      ..relativeArcToPoint(const Offset(-.63, .06), radius: r)
      ..relativeLineTo(-.07, -.06)
      ..relativeArcToPoint(const Offset(-.06, -.63), radius: r)
      ..relativeLineTo(.06, -.07)
      ..lineTo(9.29, 10)
      ..lineTo(4.15, 4.85)
      ..relativeArcToPoint(const Offset(-.06, -.63), radius: r)
      ..relativeLineTo(.06, -.07)
      ..relativeLineTo(-.06, .07)
      ..close();
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 20;
    canvas
      ..save()
      ..scale(scale)
      ..drawPath(switch (glyph) {
        FluentSearchBoxGlyph.search => _search,
        FluentSearchBoxGlyph.dismiss => _dismiss,
      }, Paint()..color = color)
      ..restore();
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
/// ## Pointer
///
/// As in a browser, only the `<input>`'s box takes focus: the text column,
/// from the end of the search icon (the input's own padding-left) to the
/// clear button, at full height. Unfocused, it runs on to the border: upstream
/// then hands the root's padding-right to the input. The root padding and the
/// search icon are a plain `<span>` upstream; pressing them shows the Pressed
/// border while held and focuses nothing.
///
/// One difference is deliberate, and shared by every Fluent text field: a
/// press on that chrome while focused keeps focus, where Chrome blurs the
/// field, because the faceplate is a [TextFieldTapRegion].
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
    this.error = false,
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

  /// Whether to paint the validation-error treatment: a
  /// `colorPaletteRedBorder2` border while unfocused, as upstream styles
  /// `aria-invalid="true"`.
  final bool error;

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
  bool _pressed = false;

  /// The resolved [FluentSearchBoxStyle.gap] from the last build: the
  /// `<input>`'s padding-left, which belongs to its hit box.
  double _gap = 0;

  /// Where the current tap went down. A browser decides focus at mousedown, so
  /// a click that drifts off the `<input>` before release still focuses it.
  Offset? _tapDownAt;

  /// Mirrors the node, so a property-only notification is not read as a blur.
  bool _focused = false;

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  // Read only still selects, as a read-only `<input>` does; only disabled
  // stops it.
  @override
  bool get selectionEnabled => widget.enabled;

  bool get _interactive => widget.enabled && !widget.readOnly;

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _focusNode.addListener(_onFocusChanged);
    _focused = _focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(FluentSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalController)?.removeListener(_onChanged);
      _controller.addListener(_onChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(
        _onFocusChanged,
      );
      _focusNode.addListener(_onFocusChanged);
      _focused = _focusNode.hasFocus;
    }
    // Disabling mid-hover or mid-press must not leave either state behind.
    if (!widget.enabled) _hovered = _pressed = false;
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _focusNode.removeListener(_onFocusChanged);
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

  /// Focus splits off from [_onChanged] so that leaving a selection behind
  /// happens on blur only, never from inside the controller's own notification.
  ///
  /// Latched on a real transition: a [FocusNode] also notifies when properties
  /// like `canRequestFocus` are written, and `hasFocus` is still false on those,
  /// so an unguarded collapse would erase a selection a host had set on a field
  /// the user never focused.
  void _onFocusChanged() {
    if (_focused == _focusNode.hasFocus) return;
    _focused = _focusNode.hasFocus;
    collapseFluentSelectionOnBlur(_focusNode, _controller);
    _onChanged();
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

  void _setPressed(bool value) {
    if (_pressed == value || (value && !widget.enabled)) return;
    setState(() => _pressed = value);
  }

  /// A tap in the `<input>`'s box but off the text itself — its padding-left,
  /// or above or below the line — focuses it and puts the caret at the nearest
  /// position, as a browser does. Taps on the text are the selection gesture
  /// detector's; taps on the root padding or the search icon do nothing
  /// (upstream `extra.json`: `click_x4`, `click_x18` stay unfocused).
  void _handleTapUp(TapUpDetails details) {
    final editable = editableTextKey.currentState?.renderEditable;
    final at = _tapDownAt ?? details.globalPosition;
    if (!widget.enabled || editable == null) return;
    final x = editable.globalToLocal(at).dx;
    final width = editable.size.width;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Before the gap is the search icon and the root padding.
    if (rtl ? x > width + _gap : x < -_gap) return;
    // Past the text, a focused box has the clear slot and the root padding;
    // an unfocused one has the `<input>`'s own padding-right (and the 1px
    // border, too thin to matter).
    if (_focusNode.hasFocus && (rtl ? x < 0 : x > width)) return;
    editable.selectPositionAt(from: at, cause: SelectionChangedCause.tap);
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
      focused: _focusNode.hasFocus,
      error: widget.error,
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
      if (_pressed && widget.enabled) WidgetState.pressed,
    };

    final textStyle = resolved.textStyle?.resolve(states) ?? const TextStyle();
    final foreground = resolved.foregroundColor?.resolve(states);
    final iconColor = resolved.iconColor?.resolve(states);
    final clearIconSize =
        resolved.clearIconSize?.resolve(states) ?? FluentSize.size200;

    final Widget editable = EditableText(
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
      enableInteractiveSelection: widget.enabled,
      // The selection gesture detector around it owns pointers, which is
      // what makes drag-to-select and double-tap-to-select-word work.
      rendererIgnoresPointer: true,
      // `EditableText` puts its own I-beam over the text line, inside the
      // column's region; disabled is `not-allowed` there too.
      mouseCursor: resolved.mouseCursor?.resolve(states),
      style: textStyle.copyWith(color: foreground),
      cursorColor:
          resolved.cursorColor?.resolve(states) ??
          theme.colors.neutralForeground1,
      // The browser's caret is 1px; `EditableText`'s default is 2.
      cursorWidth: FluentStroke.thin,
      backgroundCursorColor: theme.colors.neutralForeground3,
      // Gated on focus, because nulling this colour is the only way Flutter
      // stops painting a selection: blur leaves `controller.selection`
      // alone. Read only still paints it; a read-only `<input>` selects.
      selectionColor: widget.enabled && _focusNode.hasFocus
          ? resolved.selectionColor?.resolve(states)
          : null,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
    // Only an enabled box recognises gestures, as `FluentInput` does: a
    // disabled one must leave the tap to whatever encloses it.
    final field = widget.enabled
        ? _selectionGestures.buildGestureDetector(
            behavior: HitTestBehavior.translucent,
            child: editable,
          )
        : editable;

    final showClear = widget.enabled && _focusNode.hasFocus;

    // The leading slot is a fixed `iconSize` box plus a gap, so an empty child
    // still reserves the full glyph well — only a null icon drops the slot in
    // `buildFluentSearchBox`. [FluentSearchBox.icon] documents an empty
    // `SizedBox` as the way to ask for that, and this is the last place that
    // can still tell "no icon" from "a glyph": below it every icon is a widget
    // whose emptiness is not known until layout has already reserved the well.
    final icon = widget.icon;
    final dropIcon =
        icon is SizedBox && (icon.width ?? 0) == 0 && (icon.height ?? 0) == 0;

    final state = resolveFluentSearchBoxState(
      field: field,
      enabled: widget.enabled,
      focused: _focusNode.hasFocus,
      error: widget.error,
      appearance: widget.appearance,
      size: widget.size,
      placeholder: _controller.text.isEmpty && widget.placeholder != null
          ? Text(widget.placeholder!, maxLines: 1)
          : null,
      icon: dropIcon
          ? null
          : icon ??
                CustomPaint(
                  painter: FluentSearchBoxGlyphPainter(
                    glyph: FluentSearchBoxGlyph.search,
                    color: iconColor ?? theme.colors.neutralForeground3,
                  ),
                ),
      clear: showClear
          // The button only exists while the field has focus, and
          // `EditableText`'s default tap-outside action drops that focus on
          // POINTER DOWN for every pointer kind on desktop and on web. Without
          // this region the button unmounts under the cursor between press and
          // release: the tap never resolves, the field is never cleared, and
          // the pointer-up still routed to the gone `FluentInteractive` writes
          // to its disposed states controller.
          ? TextFieldTapRegion(
              child: Semantics(
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
              ),
            )
          : null,
    );

    _gap = resolved.gap?.resolve(states) ?? FluentSpacing.sNudge;

    // Wrapped so the faceplate counts as part of the field: the chrome sits
    // outside the region `EditableText` installs for itself, so a press on the
    // leading glyph or the padding read as a tap outside and dropped focus on
    // pointer down. The clear button has carried its own region for this reason
    // since it was written; this is the same fix for the rest of the surface.
    Widget searchBox = TextFieldTapRegion(
      child: buildFluentSearchBox(state, resolved, states),
    );

    // The root's own cursor: the arrow, or `not-allowed` when disabled. The
    // text column carries [FluentSearchBoxStyle.mouseCursor] inside it.
    searchBox = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.forbidden,
      onEnter: (_) {
        if (widget.enabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      // `:active` holds on the root for a press anywhere inside it — padding,
      // icon, text or clear button — until release. Chrome sets it for the
      // primary and middle buttons, not for a right press (storybook).
      child: Listener(
        onPointerDown: (event) =>
            _setPressed(event.buttons != kSecondaryMouseButton),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          // Both null when disabled, so no recogniser joins the arena and an
          // ancestor's tap still wins.
          onTapDown: widget.enabled
              ? (details) => _tapDownAt = details.globalPosition
              : null,
          onTapUp: widget.enabled ? _handleTapUp : null,
          child: searchBox,
        ),
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
