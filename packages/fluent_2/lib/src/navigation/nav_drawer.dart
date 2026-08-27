import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import '../overlays/drawer.dart';
import '../overlays/drawer_style.dart';

/// Width of a nav drawer whose [FluentNavDrawer.size] is left unset.
///
/// `navItemTokens.defaultDrawerWidth`. Not one of [FluentDrawerSize]'s three
/// widths — 320 / 592 / 940 — which is why it lives here rather than in that
/// enum's table.
const double fluentNavDrawerWidth = 260;

/// A [FluentDrawer] shaped for a `FluentNav`.
///
/// Upstream fuses the two — `NavDrawerProps = DrawerProps & NavProps` — so the
/// app writes one component rather than composing two and re-deriving the
/// gutters. This is the same idea with the composition kept visible: pass a
/// `FluentNav` as [child].
///
/// ```dart
/// FluentNavDrawer(
///   open: open,
///   type: FluentDrawerType.inline,
///   header: <Widget>[
///     FluentHamburger(
///       onPressed: () => setState(() => open = !open),
///       expanded: open,
///       semanticLabel: 'Collapse navigation',
///     ),
///   ],
///   child: FluentNav(children: <Widget>[…]),
/// )
/// ```
///
/// ## What this does not ship, and why
///
/// There is no `FluentNavDrawerBody`. Its two jobs upstream were the 10/4
/// gutters — carried here by the preset's [FluentDrawerStyle.bodyPadding] — and
/// a 2px row gap, which `FluentNav` already emits. A body widget applying it
/// again would double-space every nav.
///
/// There is no `FluentNavDrawerFooter`. Upstream's footer padding is a
/// five-value CSS string: invalid, dropped by every browser, and absent from
/// every react-nav story. There is nothing to port. Use [footer].
///
/// There is no `FluentNavDrawerStyle`. [FluentDrawerStyle] already covers every
/// field one would carry.
///
/// ## Divergence
///
/// Upstream sets `role="navigation"` on the panel. Here that role lives on the
/// `FluentNav` passed as [child], and only when *it* is given a semantic label.
/// The panel's own node already carries [semanticLabel] and the drawer's route
/// semantics; a second labelled node wrapped around it would only announce the
/// drawer twice.
class FluentNavDrawer extends StatelessWidget {
  /// Creates a nav drawer around [child].
  const FluentNavDrawer({
    super.key,
    required this.child,
    this.open = false,
    this.onDismiss,
    this.type = FluentDrawerType.overlay,
    this.size,
    this.position = FluentDrawerPosition.start,
    this.header = const <Widget>[],
    this.footer = const <Widget>[],
    this.separator = false,
    this.style,
    this.semanticLabel,
  });

  /// The nav.
  final Widget child;

  /// Whether the drawer is showing. Changing it runs the transition.
  final bool open;

  /// Invoked when the user asks to close: Escape, or a tap on the scrim.
  final VoidCallback? onDismiss;

  /// Overlay or inline. Overlay matches upstream's default.
  final FluentDrawerType type;

  /// Width, and the transition length that goes with it.
  ///
  /// Null — the default — is [fluentNavDrawerWidth] at
  /// [FluentDrawerSize.small]'s duration, reproducing upstream's
  /// `!size && styles.defaultWidth`. Pass a size and that size's own width and
  /// duration apply instead.
  final FluentDrawerSize? size;

  /// Which edge the drawer is anchored to, in reading order.
  final FluentDrawerPosition position;

  /// Header children, stacked in a column. Empty means no header.
  final List<Widget> header;

  /// Footer children, laid out in a row. Empty means no footer.
  final List<Widget> footer;

  /// Whether an inline drawer draws the rule between itself and the page.
  final bool separator;

  /// Overrides layered over the nav preset and the ambient
  /// [FluentDrawerTheme]. Merged last, so it wins.
  final FluentDrawerStyle? style;

  /// Announced by assistive technology as the name of the drawer.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = FluentTheme.of(context).colors;

    final preset = FluentDrawerStyle(
      // `useNavDrawerStyles`: the panel is Background4, the same surface every
      // nav row paints. FluentDrawer's own default is Background1, which would
      // leave the panel and its rows mismatched in every theme.
      backgroundColor: FluentStateColor.tokens(rest: c.neutralBackground4),
      // `useNavDrawerBodyStyles`: 10 inline-start, 4 inline-end, no block
      // padding. The row gap that rule also declares is already emitted by
      // FluentNav itself.
      bodyPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
        EdgeInsetsDirectional.fromSTEB(
          FluentSpacing.mNudge,
          FluentSpacing.none,
          FluentSpacing.xs,
          FluentSpacing.none,
        ),
      ),
      // `useNavDrawerHeaderStyles` writes these as literal px rather than
      // tokens — `paddingInlineStart: 14px; paddingBlock: 5px` — so they are
      // reproduced as literals here rather than rounded to the nearest token.
      headerPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
        EdgeInsetsDirectional.fromSTEB(14, 5, 14, 5),
      ),
      // Null means "inherit the size table". `buildFluentDrawer` only applies a
      // SizedBox for a finite width, so leaving this null falls through to
      // `resolveFluentDrawerStyle`'s own 320/592/940 entry.
      width: size == null
          ? const WidgetStatePropertyAll<double?>(fluentNavDrawerWidth)
          : null,
    );

    return FluentDrawer(
      open: open,
      onDismiss: onDismiss,
      type: type,
      size: size ?? FluentDrawerSize.small,
      position: position,
      header: header,
      footer: footer,
      separator: separator,
      semanticLabel: semanticLabel,
      // FluentDrawer resolves defaults -> FluentDrawerTheme -> style, so
      // handing it a bare preset as `style` would put the preset ABOVE an
      // ambient theme and a consumer could never reach it. Looking the theme up
      // here and re-merging it above the preset gives the intended order:
      // defaults -> preset -> theme -> caller. The theme lands twice; the
      // higher one wins.
      style: preset.merge(FluentDrawerTheme.maybeOf(context)).merge(style),
      child: child,
    );
  }
}
