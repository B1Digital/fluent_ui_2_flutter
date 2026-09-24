import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'label_style.dart';

/// Label type ramp step. Figma's `Size` axis.
enum FluentLabelSize {
  /// 12/16 caption type.
  small,

  /// 14/20 body type. The default.
  medium,

  /// 16/22 subtitle type.
  large,
}

/// Label font weight. Figma's `Type` axis, values verbatim.
enum FluentLabelWeight {
  /// Regular (400). The default.
  regular,

  /// Semibold (600), for the field name above an input.
  semibold,
}

/// Everything needed to resolve a label's style, independent of size and
/// weight.
///
/// The Dart counterpart of upstream's `LabelState` minus its design axes.
/// [buildFluentLabel] takes this rather than [FluentLabelState], which is what
/// makes "Fluent's state, my own styling, Fluent's rendering" a supported path
/// rather than a fork.
@immutable
class FluentLabelBaseState {
  /// Creates a base state.
  const FluentLabelBaseState({
    required this.enabled,
    this.required = false,
    this.label,
  });

  /// Whether the label renders in its enabled colour.
  ///
  /// A label is not interactive, so this is the only interaction state it has —
  /// and it is a real one: [resolveFluentLabelStyle] selects
  /// `neutralForegroundDisabled` for it rather than fading the enabled colour.
  final bool enabled;

  /// Whether the required-field asterisk is rendered after the label.
  final bool required;

  /// The label text, if any.
  final Widget? label;
}

/// A label's fully resolved state, including the design axes.
///
/// The counterpart of upstream's `LabelState`: base state plus exactly `size`
/// and `weight`.
@immutable
class FluentLabelState extends FluentLabelBaseState {
  /// Creates a resolved state.
  const FluentLabelState({
    required super.enabled,
    required this.size,
    required this.weight,
    super.required,
    super.label,
  });

  /// Type ramp step.
  final FluentLabelSize size;

  /// Font weight.
  final FluentLabelWeight weight;
}

/// Builds the state a label will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentLabelState resolveFluentLabelState({
  bool enabled = true,
  FluentLabelSize size = FluentLabelSize.medium,
  FluentLabelWeight weight = FluentLabelWeight.regular,
  bool required = false,
  Widget? label,
}) => FluentLabelState(
  enabled: enabled,
  size: size,
  weight: weight,
  required: required,
  label: label,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour — in particular, disabled is
/// `neutralForegroundDisabled`, never the enabled colour at reduced opacity.
///
/// Token sources are the Figma `Label` component set, extracted into
/// `test/fixtures/label.json` and asserted variant-by-variant in the tests.
FluentLabelStyle resolveFluentLabelStyle(
  FluentLabelState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final t = theme.typography;

  // The whole component, really: six ramp steps from two axes. Figma binds
  // Typography/Font size/{200,300,400} against the matching Line height and
  // Weight variable, which is exactly one ramp style each.
  //
  // Large + Regular is the one pair Figma does not ship (the set has 10
  // variants, not 12) — Large exists only as Semibold. `body2` is the 16/22
  // regular step, so the extrapolation is unambiguous, but it IS an
  // extrapolation; the tests say so out loud.
  final textStyle = switch ((state.size, state.weight)) {
    (FluentLabelSize.small, FluentLabelWeight.regular) => t.caption1,
    (FluentLabelSize.small, FluentLabelWeight.semibold) => t.caption1Strong,
    (FluentLabelSize.medium, FluentLabelWeight.regular) => t.body1,
    (FluentLabelSize.medium, FluentLabelWeight.semibold) => t.body1Strong,
    (FluentLabelSize.large, FluentLabelWeight.regular) => t.body2,
    (FluentLabelSize.large, FluentLabelWeight.semibold) => t.subtitle2,
  };

  return FluentLabelStyle(
    foregroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      disabled: c.neutralForegroundDisabled,
    ),
    // Upstream's `colorPaletteRedForeground3`, which Chrome paints #d13438 in
    // web-light and #e37d80 in web-dark. Figma binds
    // `Status/Danger/Foreground/3` (#c50f1f); the rendered upstream wins. The
    // palette layer knows nothing of high contrast, where the status token is
    // the system text colour. Disabled greys it with the label, as upstream
    // does.
    requiredColor: FluentStateColor.tokens(
      rest: c is FluentHighContrastColors
          ? c.statusDangerForeground3
          : c.palette.foreground3Rest(FluentPaletteFamily.red)!,
      disabled: c.neutralForegroundDisabled,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.xs),
  );
}

/// Renders a label from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentLabelBaseState] rather than [FluentLabelState] on purpose: it never
/// reads size or weight, so a consumer can supply their own style and still use
/// Fluent's rendering.
///
/// [states] is the interaction set — for a label, `{WidgetState.disabled}` or
/// nothing at all.
///
/// Nothing here animates. Neither Figma nor upstream's `useLabelStyles`
/// declares a transition on Label, so the disabled colour lands on the frame
/// the state changes.
Widget buildFluentLabel(
  FluentLabelBaseState state,
  FluentLabelStyle style,
  Set<WidgetState> states,
) {
  final textStyle = style.textStyle?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final requiredColor = style.requiredColor?.resolve(states);
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xs;

  final label = state.label;
  final asterisk = state.required
      ? DefaultTextStyle.merge(
          style: TextStyle(color: requiredColor),
          // Excluded from semantics: "Label*" is not what a screen reader
          // should announce. Required-ness belongs to the field, which marks
          // itself, not to the text of its label.
          child: const ExcludeSemantics(child: Text('*')),
        )
      : null;

  // Upstream's `<label>` is inline flow: its text wraps at the width it is
  // given, and the `*` span flows on after the last word. So the label wraps
  // as it would alone, and the asterisk is placed at the end of its last line.
  // The label sits in the same slot either way, so toggling `required` keeps
  // the caller's widget and its state.
  var content = label == null
      ? asterisk ?? const SizedBox.shrink()
      : _TrailingAsterisk(gap: gap, label: label, asterisk: asterisk);

  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: content,
    );
  }
  return content;
}

enum _Slot { label, asterisk }

/// Lays [label] out at the width it is given and flows [asterisk] on after the
/// end of its last line, [gap] past the last glyph — where a browser puts
/// upstream's inline `*` span with its `paddingLeft: spacingHorizontalXS`.
///
/// The line end is read off the last [RenderParagraph] inside [label], so the
/// caller's own widget stays in the tree untouched. A label with no paragraph
/// in it gets the asterisk after its box, bottom-aligned. With no [asterisk]
/// it is the label alone.
///
/// ponytail: text in a fixed-size box of its own is a relayout boundary, so
/// changing that text alone leaves the asterisk where it was until the label
/// next lays out. Placing the asterisk at paint time would lift that.
class _TrailingAsterisk
    extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  const _TrailingAsterisk({
    required this.gap,
    required this.label,
    this.asterisk,
  });

  final double gap;
  final Widget label;
  final Widget? asterisk;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.label => label,
    _Slot.asterisk => asterisk,
  };

  @override
  _RenderTrailingAsterisk createRenderObject(BuildContext context) =>
      _RenderTrailingAsterisk(gap);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTrailingAsterisk renderObject,
  ) => renderObject.gap = gap;
}

class _RenderTrailingAsterisk extends RenderBox
    with SlottedContainerRenderObjectMixin<_Slot, RenderBox> {
  _RenderTrailingAsterisk(this._gap);

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  RenderBox get _label => childForSlot(_Slot.label)!;
  RenderBox? get _asterisk => childForSlot(_Slot.asterisk);

  static RenderParagraph? _lastParagraph(RenderObject node) {
    if (node is RenderParagraph) return node;
    RenderParagraph? last;
    node.visitChildren((child) => last = _lastParagraph(child) ?? last);
    return last;
  }

  static Offset _offsetOf(RenderBox child) =>
      (child.parentData! as BoxParentData).offset;

  @override
  void performLayout() {
    final label = _label
      ..layout(constraints.copyWith(minHeight: 0), parentUsesSize: true);
    final asterisk = _asterisk;
    if (asterisk == null) {
      (label.parentData! as BoxParentData).offset = Offset.zero;
      size = constraints.constrain(label.size);
      return;
    }
    asterisk.layout(const BoxConstraints(), parentUsesSize: true);
    final star = asterisk.size;

    // The end of the last line, and that line's bottom, in label coordinates.
    var end = Offset(label.size.width, 0);
    var bottom = label.size.height;
    var ltr = true;
    final paragraph = _lastParagraph(label);
    if (paragraph != null) {
      final position = TextPosition(
        offset: paragraph.text
            .toPlainText(includeSemanticsLabels: false)
            .length,
      );
      end = MatrixUtils.transformPoint(
        paragraph.getTransformTo(label),
        paragraph.getOffsetForCaret(position, Rect.zero),
      );
      bottom = end.dy + paragraph.getFullHeightForCaret(position);
      ltr = paragraph.textDirection == TextDirection.ltr;
    }

    var x = ltr ? end.dx + _gap : end.dx - _gap - star.width;
    var y = bottom - star.height;
    // Right to left, a label with room to spare moves right, so the asterisk
    // has space on its left.
    final shift = !ltr && x < 0 && label.size.width - x <= constraints.maxWidth
        ? -x
        : 0.0;
    x += shift;
    // ponytail: a last line too full for the asterisk sends the asterisk alone
    // to a new line, where CSS would carry the last word down with it.
    if (ltr ? x + star.width > constraints.maxWidth : x < 0) {
      x = ltr ? 0 : label.size.width - star.width;
      y = bottom;
    }
    (label.parentData! as BoxParentData).offset = Offset(shift, 0);
    (asterisk.parentData! as BoxParentData).offset = Offset(x, y);
    size = constraints.constrain(
      Size(
        math.max(shift + label.size.width, x + star.width),
        math.max(label.size.height, y + star.height),
      ),
    );
  }

  // Intrinsics and dry layout assume the asterisk fits on the last line.
  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _label.getMinIntrinsicWidth(height),
    _asterisk?.getMinIntrinsicWidth(height) ?? 0,
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _label.getMaxIntrinsicWidth(height) +
      (_asterisk == null ? 0 : _gap + _asterisk!.getMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _label.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _label.getMaxIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final label = _label.getDryLayout(constraints.copyWith(minHeight: 0));
    final star = _asterisk?.getDryLayout(const BoxConstraints());
    return constraints.constrain(
      Size(
        star == null
            ? label.width
            : math.min(label.width + _gap + star.width, constraints.maxWidth),
        label.height,
      ),
    );
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _label.getDistanceToActualBaseline(baseline);

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => _label.getDryBaseline(constraints.copyWith(minHeight: 0), baseline);

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(child, offset + _offsetOf(child));
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [?_asterisk, _label]) {
      final hit = result.addWithPaintOffset(
        offset: _offsetOf(child),
        position: position,
        hitTest: (result, local) => child.hitTest(result, position: local),
      );
      if (hit) return true;
    }
    return false;
  }
}

/// Overrides the label style for a subtree.
///
/// The counterpart of Material's `TextTheme` for one component, and the middle
/// rung of the resolution order: theme defaults, then this, then the widget's
/// own `style`.
class FluentLabelTheme extends InheritedTheme {
  /// Applies [style] to every `FluentLabel` in [child].
  const FluentLabelTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size and weight defaults.
  final FluentLabelStyle style;

  /// The nearest label style, or null.
  static FluentLabelStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentLabelTheme>()?.style;

  @override
  bool updateShouldNotify(FluentLabelTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentLabelTheme(style: style, child: child);
}

/// A Fluent 2 label — the text naming a form field.
///
/// ```dart
/// FluentLabel(
///   weight: FluentLabelWeight.semibold,
///   required: true,
///   child: Text('Email address'),
/// )
/// ```
///
/// Non-interactive, but [disabled] is a real state rather than a visual
/// treatment: the colour is resolved from `neutralForegroundDisabled`, so it
/// stays correct on any background and in high contrast, where fading the
/// enabled colour would not.
///
/// Customisation follows the same three rungs Microsoft documents for the React
/// original. [style] is merged last and wins; [FluentLabelTheme] restyles a
/// subtree; and for anything further, [resolveFluentLabelState],
/// [resolveFluentLabelStyle] and [buildFluentLabel] are public so any one of
/// them can be replaced without forking this widget.
class FluentLabel extends StatelessWidget {
  /// Creates a label for [child].
  const FluentLabel({
    super.key,
    required this.child,
    this.size = FluentLabelSize.medium,
    this.weight = FluentLabelWeight.regular,
    this.required = false,
    this.disabled = false,
    this.style,
  });

  /// The label text.
  final Widget child;

  /// Type ramp step.
  final FluentLabelSize size;

  /// Font weight.
  final FluentLabelWeight weight;

  /// Whether to render the required-field asterisk after [child].
  final bool required;

  /// Whether the label renders in its disabled colour.
  ///
  /// Named after Figma's `Disabled` axis and React's `disabled` prop. The
  /// state objects carry the inverse, `enabled`, matching every other Fluent
  /// component.
  final bool disabled;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentLabelStyle? style;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentLabelState(
      enabled: !disabled,
      size: size,
      weight: weight,
      required: required,
      label: child,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentLabelStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentLabelTheme.maybeOf(context)).merge(style);

    return buildFluentLabel(state, resolved, <WidgetState>{
      if (disabled) WidgetState.disabled,
    });
  }
}
