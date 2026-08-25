import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'checkbox_style.dart';

/// Indicator box edge length and glyph size.
///
/// **Upstream-only.** The Figma `Checkbox` set has no Size axis at all — its
/// single size is [FluentCheckboxSize.medium], verified value-by-value against
/// `test/fixtures/checkbox.json`. [FluentCheckboxSize.large] comes from
/// `useCheckboxStyles.styles.ts` and has no Figma variant to arbitrate it.
enum FluentCheckboxSize {
  /// 16 box holding a 12 glyph. The default, and the only size Figma draws.
  medium,

  /// 20 box holding a 16 glyph. Upstream-only; see [FluentCheckboxSize].
  large,
}

/// Corner treatment of the indicator box. Figma's `Style` axis.
enum FluentCheckboxShape {
  /// `FluentRadius.small`. Figma `Style=Standard`. The default.
  square,

  /// Fully rounded. Figma `Style=Circular`. Upstream recommends this only in a
  /// checklist, where it cannot be mistaken for a radio item.
  circular,
}

/// Which side of the indicator the label sits on.
enum FluentCheckboxLabelPosition {
  /// Before the indicator in reading order.
  before,

  /// After the indicator in reading order. The default.
  after,
}

/// Which glyph the indicator draws.
///
/// Resolved once by [resolveFluentCheckboxState] from the checked value and the
/// shape, exactly as upstream's `useCheckbox_unstable` picks the icon component
/// before styling runs. Keeping it on the base state is what lets
/// [buildFluentCheckbox] render without knowing the design axes.
enum FluentCheckboxGlyph {
  /// Nothing is drawn. The unchecked state.
  none,

  /// `Checkmark12Filled` / `Checkmark16Filled`.
  checkmark,

  /// `Square12Filled` / `Square16Filled` — the mixed state of a square
  /// checkbox. A filled rounded square, not a dash: Fluent 2 differs from
  /// Material here.
  square,

  /// `CircleFilled` — the mixed state of a circular checkbox.
  circle,
}

/// Everything needed to render a checkbox, independent of size and shape.
///
/// The Dart counterpart of upstream's `CheckboxBaseState`, which is likewise
/// `CheckboxState` minus `shape` and `size`. [buildFluentCheckbox] takes this
/// rather than [FluentCheckboxState], which is what makes "Fluent's state, my
/// own styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentCheckboxBaseState {
  /// Creates a base state.
  const FluentCheckboxBaseState({
    required this.enabled,
    required this.checked,
    required this.glyph,
    required this.labelPosition,
    this.label,
  });

  /// Whether the checkbox responds to input.
  final bool enabled;

  /// The tri-state value: `true`, `false`, or null for mixed.
  ///
  /// Null rather than a third enum value because that is how Flutter spells a
  /// tri-state control everywhere else, and because [Semantics] takes the same
  /// shape.
  final bool? checked;

  /// The glyph the indicator draws, already resolved from [checked] and the
  /// shape.
  final FluentCheckboxGlyph glyph;

  /// Which side the label sits on.
  final FluentCheckboxLabelPosition labelPosition;

  /// The label, if any. Null renders the indicator alone.
  final Widget? label;

  /// Whether this is the mixed (indeterminate) state.
  bool get mixed => checked == null;
}

/// A checkbox's fully resolved state, including the design axes.
///
/// The counterpart of upstream's `CheckboxState`: base state plus exactly
/// `size` and `shape`.
@immutable
class FluentCheckboxState extends FluentCheckboxBaseState {
  /// Creates a resolved state.
  const FluentCheckboxState({
    required super.enabled,
    required super.checked,
    required super.glyph,
    required super.labelPosition,
    required this.size,
    required this.shape,
    super.label,
  });

  /// Indicator box and glyph size.
  final FluentCheckboxSize size;

  /// Corner treatment of the indicator box.
  final FluentCheckboxShape shape;
}

/// Builds the state a checkbox will be styled and rendered from.
///
/// The first of the three-function recomposition contract, and the only place
/// the glyph is chosen: `mixed` draws a filled square, or a filled circle on a
/// circular checkbox, mirroring `useCheckbox_unstable`.
FluentCheckboxState resolveFluentCheckboxState({
  bool enabled = true,
  bool? checked = false,
  FluentCheckboxSize size = FluentCheckboxSize.medium,
  FluentCheckboxShape shape = FluentCheckboxShape.square,
  FluentCheckboxLabelPosition labelPosition = FluentCheckboxLabelPosition.after,
  Widget? label,
}) => FluentCheckboxState(
  enabled: enabled,
  checked: checked,
  glyph: switch ((checked, shape)) {
    (false, _) => FluentCheckboxGlyph.none,
    (null, FluentCheckboxShape.circular) => FluentCheckboxGlyph.circle,
    (null, _) => FluentCheckboxGlyph.square,
    (true, _) => FluentCheckboxGlyph.checkmark,
  },
  size: size,
  shape: shape,
  labelPosition: labelPosition,
  label: label,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// The Status axis is a **replacement**, not a modifier — upstream's
/// `useCheckboxStyles_unstable` picks `disabled` *instead of*
/// `checked`/`mixed`/`unchecked`, so a disabled checked checkbox loses its
/// brand fill entirely rather than dimming it. That is reproduced verbatim
/// below; it is the one behaviour most likely to be "fixed" by someone who has
/// only seen the enabled states.
///
/// The mixed state likewise never paints a fill: `useRootStyles.mixed` sets the
/// border and glyph variables and leaves the background variable unset.
///
/// Figma confirms both, variant by variant, in `test/fixtures/checkbox.json`:
/// `Status=Checked, State=Disabled` paints no fill and strokes
/// `Neutral/Stroke/Disabled/Rest`, and every `Status=Indeterminate` variant
/// carries a stroke and a glyph with no fill at all.
///
/// One deliberate divergence: Figma's checked indicator is a **filled node with
/// no stroke**, while this paints a `FluentStroke.thin` border in the same
/// compound-brand token as the fill. The pixels are identical — a border drawn
/// inside the box in the fill's own colour is invisible — and keeping the
/// border means the box still has an outline under a high-contrast theme, where
/// a fill-only box can vanish into the surface.
FluentCheckboxStyle resolveFluentCheckboxStyle(
  FluentCheckboxState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Every branch selects an explicit Rest/Hover/Pressed token. Disabled is a
  // separate ramp rather than a treatment applied to the others.
  final (background, border, glyph, foreground) = switch ((
    state.enabled,
    state.checked,
  )) {
    (false, _) => (
      FluentStateColor.tokens(rest: c.transparentBackground),
      FluentStateColor.tokens(rest: c.neutralStrokeDisabled),
      FluentStateColor.tokens(rest: c.neutralForegroundDisabled),
      FluentStateColor.tokens(rest: c.neutralForegroundDisabled),
    ),
    (true, true) => (
      FluentStateColor.tokens(
        rest: c.compoundBrandBackground,
        hover: c.compoundBrandBackgroundHover,
        pressed: c.compoundBrandBackgroundPressed,
      ),
      FluentStateColor.tokens(
        rest: c.compoundBrandBackground,
        hover: c.compoundBrandBackgroundHover,
        pressed: c.compoundBrandBackgroundPressed,
      ),
      // The tick walks its own ramp: Figma binds the glyph to
      // `Neutral/Foreground/Inverted/1/{Rest,Hover,Pressed}`, one token per
      // state, not a single Rest token reused.
      FluentStateColor.tokens(
        rest: c.neutralForegroundInverted,
        hover: c.neutralForegroundInvertedHover,
        pressed: c.neutralForegroundInvertedPressed,
      ),
      FluentStateColor.tokens(rest: c.neutralForeground1),
    ),
    (true, null) => (
      FluentStateColor.tokens(rest: c.transparentBackground),
      FluentStateColor.tokens(
        rest: c.compoundBrandStroke,
        hover: c.compoundBrandStrokeHover,
        pressed: c.compoundBrandStrokePressed,
      ),
      FluentStateColor.tokens(
        rest: c.compoundBrandForeground1,
        hover: c.compoundBrandForeground1Hover,
        pressed: c.compoundBrandForeground1Pressed,
      ),
      FluentStateColor.tokens(rest: c.neutralForeground1),
    ),
    (true, false) => (
      FluentStateColor.tokens(rest: c.transparentBackground),
      FluentStateColor.tokens(
        rest: c.neutralStrokeAccessible,
        hover: c.neutralStrokeAccessibleHover,
        pressed: c.neutralStrokeAccessiblePressed,
      ),
      // Unchecked draws no glyph, so this is never read. It is still a real
      // token rather than null so a caller that swaps the glyph in through
      // `style` gets a sane colour.
      FluentStateColor.tokens(rest: c.neutralForegroundInverted),
      FluentStateColor.tokens(
        rest: c.neutralForeground3,
        hover: c.neutralForeground2,
        pressed: c.neutralForeground1,
      ),
    ),
  };

  // Geometry, verbatim from useCheckboxStyles.styles.ts. The root height is the
  // indicator's own margin box: 8 + 16 + 8 = 32, and 8 + 20 + 8 = 36.
  final (indicator, glyphSize, height, labelInset) = switch (state.size) {
    FluentCheckboxSize.medium => (16.0, 12.0, 32.0, FluentSpacing.sNudge),
    FluentCheckboxSize.large => (20.0, 16.0, 36.0, FluentSpacing.s),
  };

  // Upstream pads the label 8 all round and then pulls it back with a negative
  // vertical margin of (indicator - lineHeightBase300) / 2, so the label box
  // ends up exactly as tall as the indicator box. `labelInset` above is that
  // arithmetic already done: 8 + (16 - 20) / 2 = 6 at medium, 8 + 0 = 8 at
  // large. Expressing the result rather than a negative margin keeps a wrapping
  // label correct without needing one.
  final labelPadding = switch (state.labelPosition) {
    FluentCheckboxLabelPosition.after => EdgeInsets.only(
      left: FluentSpacing.xs,
      right: FluentSpacing.s,
      top: labelInset,
      bottom: labelInset,
    ),
    FluentCheckboxLabelPosition.before => EdgeInsets.only(
      left: FluentSpacing.s,
      right: FluentSpacing.xs,
      top: labelInset,
      bottom: labelInset,
    ),
  };

  final radius = switch (state.shape) {
    FluentCheckboxShape.square => FluentRadius.allSmall,
    FluentCheckboxShape.circular => FluentRadius.allCircular,
  };

  return FluentCheckboxStyle(
    indicatorColor: glyph,
    indicatorBackgroundColor: background,
    indicatorBorderColor: border,
    foregroundColor: foreground,
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(radius),
    // Upstream sizes the label slot as `Label size="medium"` at BOTH checkbox
    // sizes — the Size axis moves the box, never the type ramp.
    textStyle: WidgetStatePropertyAll<TextStyle?>(theme.typography.body1),
    indicatorMargin: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(FluentSpacing.s),
    ),
    labelPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(labelPadding),
    indicatorSize: WidgetStatePropertyAll<double?>(indicator),
    glyphSize: WidgetStatePropertyAll<double?>(glyphSize),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders a checkbox from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentCheckboxBaseState] rather than [FluentCheckboxState] on purpose: it
/// never reads size or shape, so a consumer can supply their own style and
/// still use Fluent's layout, focus ring and glyph painting.
///
/// **Nothing animates, deliberately.** `useCheckboxStyles.styles.ts` contains
/// no `transition` of any kind — the box, the border and the glyph all change
/// on the frame the value changes, because a checkbox has to read as committed
/// the moment it is clicked. Adding a fade here would contradict upstream, and
/// it also makes this trivially correct under `MediaQuery.disableAnimationsOf`:
/// there is no animation to shorten.
///
/// [states] is the live interaction set from [FluentInteractive].
Widget buildFluentCheckbox(
  FluentCheckboxBaseState state,
  FluentCheckboxStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allSmall;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.indicatorBorderColor?.resolve(states);
  final background = style.indicatorBackgroundColor?.resolve(states);
  final glyphColor = style.indicatorColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);
  final indicatorSize = style.indicatorSize?.resolve(states) ?? 16;
  final glyphSize = style.glyphSize?.resolve(states) ?? 12;
  final indicatorMargin =
      style.indicatorMargin?.resolve(states) ?? EdgeInsets.zero;
  final labelPadding = style.labelPadding?.resolve(states) ?? EdgeInsets.zero;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;

  final indicator = Padding(
    padding: indicatorMargin,
    child: SizedBox(
      width: indicatorSize,
      height: indicatorSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: borderWidth > 0 && borderColor != null
              ? Border.all(color: borderColor, width: borderWidth)
              : null,
        ),
        child: Center(
          child: CustomPaint(
            size: Size.square(glyphSize),
            painter: FluentCheckboxGlyphPainter(
              glyph: state.glyph,
              color: glyphColor ?? const Color(0x00000000),
            ),
          ),
        ),
      ),
    ),
  );

  Widget? label = state.label == null
      ? null
      : Padding(padding: labelPadding, child: state.label);
  if (label != null && (textStyle != null || foreground != null)) {
    label = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: label,
    );
  }

  // Upstream aligns the indicator to flex-start and the label to center. With
  // the label box built to the indicator's own height above, those agree on a
  // single line and differ only when the label wraps — where start is what
  // keeps the box beside the FIRST line.
  final children = <Widget>[indicator, ?label];

  return FluentFocusRing(
    visible: states.contains(WidgetState.focused),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minimumSize.height,
        minWidth: minimumSize.width,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: state.labelPosition == FluentCheckboxLabelPosition.before
            ? children.reversed.toList()
            : children,
      ),
    ),
  );
}

/// Paints the indicator glyph: the checkmark, the mixed square or the mixed
/// circle.
///
/// A painter rather than three icon widgets because the glyphs are single
/// shapes and this package does not ship Fluent's icon font. The geometry is
/// transcribed from `microsoft/fluentui-system-icons`, normalised against the
/// glyph box so it scales with `fontSize` the way the icon components do.
///
/// Every input is a public field so tests can assert the resolved glyph and
/// tone directly instead of diffing pixels.
class FluentCheckboxGlyphPainter extends CustomPainter {
  /// Creates a painter for one glyph and tone.
  const FluentCheckboxGlyphPainter({required this.glyph, required this.color});

  /// Which shape to draw. [FluentCheckboxGlyph.none] paints nothing.
  final FluentCheckboxGlyph glyph;

  /// The glyph tone. `neutralForegroundInverted` when checked, the compound
  /// brand foreground when mixed — never derived from the box fill.
  final Color color;

  // `Checkmark12Filled` and `Checkmark16Filled` are separately drawn glyphs,
  // not scaled copies of one another: the 16px tick is proportionally wider and
  // sits lower. Both polylines are the centrelines of the shipped SVG outlines,
  // divided by their own viewBox, and are chosen off the glyph box below.
  static const List<Offset> _check12 = <Offset>[
    Offset(0.229166, 0.5),
    Offset(0.416666, 0.6875),
    Offset(0.770833, 0.3125),
  ];
  static const List<Offset> _check16 = <Offset>[
    Offset(0.171875, 0.546875),
    Offset(0.343750, 0.718750),
    Offset(0.843750, 0.250000),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (glyph == FluentCheckboxGlyph.none) return;
    final paint = Paint()..color = color;

    switch (glyph) {
      case FluentCheckboxGlyph.none:
        return;
      case FluentCheckboxGlyph.checkmark:
        final points = size.width >= 16 ? _check16 : _check12;
        canvas.drawPath(
          Path()
            ..moveTo(points[0].dx * size.width, points[0].dy * size.height)
            ..lineTo(points[1].dx * size.width, points[1].dy * size.height)
            ..lineTo(points[2].dx * size.width, points[2].dy * size.height),
          paint
            ..style = PaintingStyle.stroke
            // 1.5 in BOTH glyphs — the tick does not get heavier at large.
            ..strokeWidth = FluentStroke.width15
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      case FluentCheckboxGlyph.square:
        // Square12Filled insets 2 in a 12 box and Square16Filled insets 2 in a
        // 16 box — the inset is absolute, not proportional. The radius is NOT
        // inset with it: the Figma glyph (`Size=12, Theme=Filled`, an 8x8 path
        // at 4,4 inside the 16 indicator) has corner radius 2 on the inset
        // rect, so deflating an RRect — which shrinks the radii too — flattened
        // the corners to square.
        // ponytail: the 16px glyph's corner is 2.5 upstream, half a pixel more
        // than FluentRadius.small. Figma has no large size to arbitrate it;
        // split the radius per size if a fixture ever disagrees.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            (Offset.zero & size).deflate(FluentSpacing.xxs),
            FluentRadius.small,
          ),
          paint,
        );
      case FluentCheckboxGlyph.circle:
        canvas.drawCircle(
          size.center(Offset.zero),
          // The same absolute inset as the square: Figma's circular mixed dot
          // is 8 across inside a 16 indicator, i.e. 8 inside the 12 glyph box.
          // Proportional scaling (the old `* 0.375`) came from Circle16Filled
          // and drew a 9px dot at medium.
          (size.width - 2 * FluentSpacing.xxs) / 2,
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(FluentCheckboxGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}

/// Overrides the checkbox style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentCheckboxTheme extends InheritedTheme {
  /// Applies [style] to every `FluentCheckbox` in [child].
  const FluentCheckboxTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size, shape and status defaults.
  final FluentCheckboxStyle style;

  /// The nearest checkbox style, or null.
  static FluentCheckboxStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentCheckboxTheme>()?.style;

  @override
  bool updateShouldNotify(FluentCheckboxTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentCheckboxTheme(style: style, child: child);
}

/// A Fluent 2 checkbox, with the mixed (indeterminate) state.
///
/// ```dart
/// FluentCheckbox(
///   checked: agreed,
///   label: const Text('I agree'),
///   onChanged: (value) => setState(() => agreed = value),
/// )
/// ```
///
/// [checked] is tri-state: `true`, `false`, or **null for mixed**. Mixed is a
/// value a parent sets to report partially-selected children; the control never
/// reports it back, so tapping a mixed checkbox reports `true`, matching
/// upstream, where the browser's own `indeterminate` input resolves the same
/// way.
///
/// Pass `onChanged: null` to disable it — disabled is a real state here, not a
/// visual treatment: the checkbox stops reporting hover and press, refuses
/// focus, never invokes the callback, and swaps to the disabled token ramp
/// wholesale rather than fading the enabled one.
///
/// **Nothing animates.** See [buildFluentCheckbox].
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentCheckboxTheme] restyles a subtree; and for anything further,
/// [resolveFluentCheckboxState], [resolveFluentCheckboxStyle] and
/// [buildFluentCheckbox] are public so any one of them can be replaced without
/// forking this widget.
class FluentCheckbox extends StatelessWidget {
  /// Creates a checkbox with an optional [label].
  const FluentCheckbox({
    super.key,
    this.checked = false,
    this.onChanged,
    this.label,
    this.size = FluentCheckboxSize.medium,
    this.shape = FluentCheckboxShape.square,
    this.labelPosition = FluentCheckboxLabelPosition.after,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The tri-state value. Null is the mixed state.
  final bool? checked;

  /// Invoked with the next value on tap and on Space or Enter. Null disables
  /// the checkbox.
  ///
  /// The next value is `true` from both `false` and mixed, and `false` from
  /// `true` — the control never reports mixed.
  final ValueChanged<bool?>? onChanged;

  /// The label. Null renders the indicator alone, in which case
  /// [semanticLabel] carries the meaning.
  final Widget? label;

  /// Indicator box and glyph size.
  final FluentCheckboxSize size;

  /// Corner treatment of the indicator box.
  final FluentCheckboxShape shape;

  /// Which side the label sits on.
  final FluentCheckboxLabelPosition labelPosition;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentCheckboxStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Announced by assistive technology alongside the checked state.
  ///
  /// Required in practice for a checkbox with no [label]: the indicator alone
  /// announces nothing.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentCheckboxState(
      enabled: onChanged != null,
      checked: checked,
      size: size,
      shape: shape,
      labelPosition: labelPosition,
      label: label,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentCheckboxStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentCheckboxTheme.maybeOf(context)).merge(style);

    final checkbox = FluentInteractive(
      onPressed: onChanged == null ? null : () => onChanged!(checked != true),
      enabled: onChanged != null,
      focusNode: focusNode,
      autofocus: autofocus,
      mouseCursor:
          resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
          SystemMouseCursors.click,
      builder: (context, states, _) =>
          buildFluentCheckbox(state, resolved, states),
    );

    return Semantics(
      // `checked` and `mixed` are the pair Flutter's own tri-state controls
      // report: checked is false while mixed, and mixed carries the third
      // state. Spelling it any other way silences the state entirely.
      checked: checked ?? false,
      mixed: checked == null,
      enabled: onChanged != null,
      label: semanticLabel,
      child: checkbox,
    );
  }
}
