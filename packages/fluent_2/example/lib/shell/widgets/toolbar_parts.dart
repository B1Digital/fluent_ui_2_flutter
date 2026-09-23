import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../docs_metrics.dart';

/// Storybook's `.sb-bar` palette, as the Fluent manager theme resolves it.
///
/// Read off Storybook 9.1.17 (`Button.tsx:82-250` inside `.sb-bar`,
/// `theming/create.ts:23-33`) and re-measured on the live bar with a real
/// mouse — rest, hover, pressed, active and active + hover all computed-style
/// probed. Literals rather than theme tokens for the reason [DocsMetrics]
/// gives: this is Storybook chrome, and it must not follow the preview's theme.
abstract final class ToolbarColors {
  /// `barTextColor`: every control at rest, on a transparent fill.
  static const Color rest = Color(0xFF73828C);

  /// `barHoverColor`. Fluent's `theme.js` never overrides it, so it stays
  /// Storybook's own blue rather than Fluent's.
  static const Color hover = Color(0xFF029CFD);

  /// `rgba(2,156,253,.14)` behind a hovered control.
  static const Color hoverFill = Color(0x24029CFD);

  /// `barSelectedColor`: a toggled-on control, and a pressed one.
  static const Color active = Color(0xFF0078D4);

  /// `transparentize(0.9, #73828C)` behind a toggled-on control.
  static const Color activeFill = Color(0x1A73828C);

  /// `rgba(0,120,212,.10)` behind a control while the button is held (`:active`).
  static const Color pressedFill = Color(0x1A0078D4);

  /// The bar's bottom hairline and the separator. `#e0e0e0`, two values off
  /// [DocsMetrics.rule] — measured, not reused.
  static const Color rule = Color(0xFFE0E0E0);
}

/// The one style every bar control shares: Storybook's `IconButton` in
/// `.sb-bar` — 28 tall, `padding: 0 7px`, radius 4, `gap: 6px`,
/// `700 12px/12px`, 14px glyphs (`IconButton.tsx:7`, `Button.tsx:82-250`).
///
/// Colour precedence is upstream's cascade: `:active` beats `:hover` beats the
/// `active` prop beats rest — so a toggled-on control still lights up blue on
/// hover, which the live probe confirmed. There is deliberately no colour on
/// [FluentButtonStyle.textStyle]: `buildFluentButton` pushes the resolved
/// foreground into both `IconTheme` and `DefaultTextStyle`
/// (`packages/fluent_2/lib/src/buttons/button.dart:331-360`), so an explicit
/// colour anywhere below would pin that one child to a single state.
///
/// ponytail: no focus colour. Upstream adds `#029CFD 0 0 0 1px inset` on
/// `:focus` — after a mouse click too — where FluentButton draws its own
/// keyboard-only Fluent ring; add a `WidgetState.focused` branch to a border
/// here if that ring ever has to match.
FluentButtonStyle toolbarButtonStyle({required bool active}) =>
    FluentButtonStyle.from(
      borderWidth: 0,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      gap: 6,
      iconSize: 14,
      minimumSize: const Size(28, 28),
      textStyle: const TextStyle(
        fontFamily: DocsMetrics.fontFamily,
        fontFamilyFallback: DocsMetrics.fontFamilyFallback,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    ).copyWith(
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.pressed)
            ? ToolbarColors.active
            : states.contains(WidgetState.hovered)
            ? ToolbarColors.hover
            : active
            ? ToolbarColors.active
            : ToolbarColors.rest,
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.pressed)
            ? ToolbarColors.pressedFill
            : states.contains(WidgetState.hovered)
            ? ToolbarColors.hoverFill
            : active
            ? ToolbarColors.activeFill
            : const Color(0x00000000),
      ),
    );

/// The 40px strip both the docs and the canvas bar sit in.
///
/// Upstream's `Toolbar.tsx:235-271`: white, a `#e0e0e0 0 -1px 0 0 inset`
/// hairline — a [BoxDecoration] border paints inside its box and moves no
/// child, which is the same thing — 10px in from each side, tools `gap: 6px`,
/// the two groups pushed apart (`justify-content: space-between`).
///
/// ponytail: one Row, so a bar narrower than its tools overflows where upstream
/// scrolls horizontally (and keeps `margin-left: 30px` before the end group).
/// Wrap the Row in a horizontal `SingleChildScrollView` if a narrow window ever
/// has to carry the whole canvas set.
class ToolbarFrame extends StatelessWidget {
  /// Lays [start] out from the leading edge and [end] against the trailing one.
  const ToolbarFrame({
    super.key,
    required this.start,
    this.end = const <Widget>[],
  });

  /// Upstream's bar height, hairline included.
  static const double height = 40;

  /// Tools from the leading edge, in order.
  final List<Widget> start;

  /// Tools against the trailing edge, in order.
  final List<Widget> end;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: DocsMetrics.canvas,
      border: Border(bottom: BorderSide(color: ToolbarColors.rule)),
    ),
    child: SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        // The Spacer takes a 6px gap on each side too; it is absorbed, so the
        // groups still meet the insets exactly.
        child: Row(
          spacing: 6,
          children: <Widget>[...start, const Spacer(), ...end],
        ),
      ),
    ),
  );
}

/// Wraps [child] with a bar tooltip that hides on pointer-down and stays
/// hidden until the pointer leaves [child], then shows again on the next
/// hover.
///
/// Upstream's toolbar tooltips are the browser's native `title` attribute,
/// which has no press state of its own — it just tracks hover, and Chrome
/// hides it on `mousedown` and does not re-show it until the pointer leaves
/// the control and comes back. A bare [FluentTooltip] only reacts to
/// hover/focus, and [FluentMenu] puts no barrier over its trigger, so
/// without this a bar control's tooltip is still "hovering" once its click
/// opens a menu below it: with a slow press it sits half under that menu,
/// and with a quick one (inside the 250ms show delay) the pending show fires
/// after the menu is already open and paints over its first row.
///
/// [FluentTooltip.enabled] going false tears its surface down at once and
/// cancels a pending show (`didUpdateWidget` -> `_syncNow`,
/// `fluent_2/lib/src/surfaces/tooltip.dart`), so flipping it false on
/// pointer-down is the whole fix.
class ToolbarTooltip extends StatefulWidget {
  /// Creates the wrapper.
  const ToolbarTooltip({super.key, required this.tooltip, required this.child});

  /// Upstream's `title`, verbatim.
  final String tooltip;

  /// The trigger.
  final Widget child;

  @override
  State<ToolbarTooltip> createState() => _ToolbarTooltipState();
}

class _ToolbarTooltipState extends State<ToolbarTooltip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => _pressed = true),
    child: MouseRegion(
      onExit: (_) => setState(() => _pressed = false),
      child: FluentTooltip(
        content: Text(widget.tooltip),
        enabled: !_pressed,
        child: widget.child,
      ),
    ),
  );
}

/// One bar control: a [FluentButton] in [toolbarButtonStyle] under a
/// [ToolbarTooltip].
///
/// Give it an [icon], a [label], or both — the three shapes upstream's bar
/// uses (Grid; Direction; Theme's arrow-then-text). The glyph is a bare
/// `Icon(icon)`: size and colour come from the style, so it follows hover,
/// press and [active] with the label.
///
/// Upstream's tooltip is the native `title` attribute; this is a Fluent one,
/// and the only visible difference is where it lands.
class ToolbarButton extends StatelessWidget {
  /// Creates a control; at least one of [icon] and [label] is required.
  const ToolbarButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.label,
    this.semanticLabel,
    this.active = false,
  }) : assert(icon != null || label != null, 'a control needs a face');

  /// Upstream's `title`, verbatim — "Apply a grid to the preview".
  final String tooltip;

  /// Invoked on click, Space and Enter.
  final VoidCallback onPressed;

  /// The glyph, drawn at 14px in the state colour.
  final IconData? icon;

  /// The text face. Leave its colour unset so the state colour reaches it.
  final Widget? label;

  /// The accessible name, when [tooltip] carries more than the name — upstream's
  /// full-screen button titles itself "Go full screen [⌥ F]" but is labelled
  /// "Go full screen". An icon-only control falls back to [tooltip]; a labelled
  /// one to its own text.
  final String? semanticLabel;

  /// Whether the control reads as toggled on (upstream's `active` prop).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final FluentButtonStyle style = toolbarButtonStyle(active: active);
    final Widget? glyph = icon == null ? null : Icon(icon);
    return ToolbarTooltip(
      tooltip: tooltip,
      child: label == null
          ? FluentButton.icon(
              icon: glyph!,
              semanticLabel: semanticLabel ?? tooltip,
              appearance: FluentButtonAppearance.transparent,
              size: FluentButtonSize.small,
              style: style,
              onPressed: onPressed,
            )
          : FluentButton(
              icon: glyph,
              semanticLabel: semanticLabel,
              appearance: FluentButtonAppearance.transparent,
              size: FluentButtonSize.small,
              style: style,
              onPressed: onPressed,
              child: label!,
            ),
    );
  }
}

/// A [ToolbarButton] that opens a [FluentMenu] of [items].
///
/// Upstream's popovers (Background, Theme, Viewport, Vision) open below the
/// bar and close on a pick; FluentMenu does both. Mark the chosen row with
/// [toolbarItemLabel], not `checked:` — upstream draws no checkmark.
///
/// ponytail: [active] is the caller's global only. Upstream also highlights a
/// popover button while it is open; `FluentMenuTriggerBuilder` exposes no open
/// state (`menu.dart:238`), so that needs an `onOpenChanged` on FluentMenu.
class ToolbarMenuButton extends StatelessWidget {
  /// Creates a menu control; at least one of [icon] and [label] is required.
  const ToolbarMenuButton({
    super.key,
    required this.tooltip,
    required this.items,
    this.icon,
    this.label,
    this.active = false,
  });

  /// Upstream's `title`, verbatim.
  final String tooltip;

  /// The rows, in upstream's order.
  final List<FluentMenuItem> items;

  /// The glyph, drawn at 14px in the state colour.
  final IconData? icon;

  /// The text face. Leave its colour unset so the state colour reaches it.
  final Widget? label;

  /// Whether the control reads as toggled on.
  final bool active;

  @override
  Widget build(BuildContext context) => FluentMenu(
    items: items,
    builder: (BuildContext context, VoidCallback toggle) => ToolbarButton(
      tooltip: tooltip,
      icon: icon,
      label: label,
      active: active,
      onPressed: toggle,
    ),
  );
}

/// Upstream's `bar/separator.tsx:9-16`: a 1x20 `#e0e0e0` rule with `margin: 0
/// 2px`, centred by the bar's Row.
class ToolbarSeparator extends StatelessWidget {
  /// Creates the rule.
  const ToolbarSeparator({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 2),
    child: SizedBox(
      width: 1,
      height: 20,
      child: ColoredBox(color: ToolbarColors.rule),
    ),
  );
}

/// A popover row's label: `#0078D4` bold when [chosen], else plain.
///
/// Upstream marks the current value this way and draws no checkmark. An
/// explicit [Text] style is what wins here — the row wraps its label in
/// `DefaultTextStyle.merge` (`menu_item.dart:507`), which only fills gaps.
Widget toolbarItemLabel(String text, {bool chosen = false}) => Text(
  text,
  style: chosen
      ? const TextStyle(
          color: ToolbarColors.active,
          fontWeight: FontWeight.w700,
        )
      : null,
);
