import 'dart:async';

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../docs_metrics.dart';
import '../showroom_scope.dart';
import '../theme_variants.dart';

/// The bar above a story canvas.
///
/// Upstream's is 40px tall with 12px/700 labels in `#73828C`, and carries the
/// preview-level controls: zoom, a background grid, a surface toggle, the theme
/// and the text direction. Measured off the live canvas rather than copied by
/// eye.
///
/// Four of upstream's buttons have no counterpart and are not drawn: "measure"
/// and "outlines" are DOM inspectors, "vision simulator" filters the rendered
/// page, and "React strict mode" is a React runtime flag. Drawing dead controls
/// to fill the row would be worse than a shorter row.
class CanvasToolbar extends StatelessWidget {
  /// Creates the bar.
  const CanvasToolbar({
    super.key,
    required this.zoom,
    required this.onZoom,
    required this.grid,
    required this.onGrid,
    required this.surface,
    required this.onSurface,
    required this.onCopyLink,
  });

  /// Current preview scale.
  final double zoom;

  /// Called with the next scale, or null to reset.
  final ValueChanged<double?> onZoom;

  /// Whether the background grid is drawn.
  final bool grid;

  /// Toggles the grid.
  final VoidCallback onGrid;

  /// Whether the canvas paints the theme surface behind the story.
  final bool surface;

  /// Toggles the surface.
  final VoidCallback onSurface;

  /// Puts the canvas URL on the clipboard.
  final VoidCallback onCopyLink;

  static const Color _ink = Color(0xFF73828C);
  static const double _height = 40;

  static TextStyle get _label => TextStyle(
    fontFamily: DocsMetrics.fontFamily,
    fontFamilyFallback: DocsMetrics.fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: _ink,
  );

  @override
  Widget build(BuildContext context) {
    final ShowroomScope scope = ShowroomScope.of(context);
    final bool rtl = scope.textDirection == TextDirection.rtl;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DocsMetrics.canvas,
        border: Border(bottom: BorderSide(color: DocsMetrics.rule)),
      ),
      child: SizedBox(
        height: _height,
        child: Row(
          children: <Widget>[
            const SizedBox(width: 10),
            _IconItem(
              icon: FluentIcons.zoom_in_20_regular,
              tooltip: 'Zoom in',
              onPressed: () => onZoom(zoom * 1.25),
            ),
            _IconItem(
              icon: FluentIcons.zoom_out_20_regular,
              tooltip: 'Zoom out',
              onPressed: () => onZoom(zoom / 1.25),
            ),
            _IconItem(
              icon: FluentIcons.arrow_reset_20_regular,
              tooltip: 'Reset zoom',
              onPressed: () => onZoom(null),
            ),
            const _Divider(),
            _IconItem(
              icon: FluentIcons.grid_20_regular,
              tooltip: 'Toggle grid',
              selected: grid,
              onPressed: onGrid,
            ),
            _IconItem(
              icon: FluentIcons.image_20_regular,
              tooltip: 'Toggle background',
              selected: surface,
              onPressed: onSurface,
            ),
            const _Divider(),
            _MenuItem(
              label: 'Theme: ${scope.variant.label}',
              tooltip: 'Change Fluent theme',
              items: <FluentMenuItem>[
                for (final ThemeVariant variant in ThemeVariant.values)
                  FluentMenuItem(
                    label: Text(variant.label),
                    checked: variant == scope.variant,
                    onPressed: () => scope.onVariantChanged(variant),
                  ),
              ],
            ),
            _MenuItem(
              label: 'Direction: ${rtl ? 'RTL' : 'LTR'}',
              tooltip: 'Change Direction',
              items: <FluentMenuItem>[
                FluentMenuItem(
                  label: const Text('LTR'),
                  checked: !rtl,
                  onPressed: () =>
                      scope.onTextDirectionChanged(TextDirection.ltr),
                ),
                FluentMenuItem(
                  label: const Text('RTL'),
                  checked: rtl,
                  onPressed: () =>
                      scope.onTextDirectionChanged(TextDirection.rtl),
                ),
              ],
            ),
            const Spacer(),
            _IconItem(
              icon: FluentIcons.link_20_regular,
              tooltip: 'Copy canvas link',
              onPressed: onCopyLink,
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    child: ColoredBox(
      color: DocsMetrics.rule,
      child: SizedBox(width: 1, height: double.infinity),
    ),
  );
}

class _IconItem extends StatelessWidget {
  const _IconItem({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return FluentTooltip(
      content: Text(tooltip),
      child: FluentButton.icon(
        icon: Icon(
          icon,
          size: 16,
          color: selected ? DocsMetrics.sidebarSelected : CanvasToolbar._ink,
        ),
        semanticLabel: tooltip,
        appearance: FluentButtonAppearance.transparent,
        size: FluentButtonSize.small,
        onPressed: onPressed,
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.tooltip,
    required this.items,
  });

  final String label;
  final String tooltip;
  final List<FluentMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return FluentMenu(
      items: items,
      builder: (BuildContext context, VoidCallback toggle) => FluentTooltip(
        content: Text(tooltip),
        child: FluentButton(
          appearance: FluentButtonAppearance.transparent,
          size: FluentButtonSize.small,
          onPressed: toggle,
          child: Text(label, style: CanvasToolbar._label),
        ),
      ),
    );
  }
}

/// Paints the checkerboard the grid button toggles.
class CanvasGrid extends StatelessWidget {
  /// Draws a grid behind [child] when [enabled].
  const CanvasGrid({super.key, required this.enabled, required this.child});

  /// Whether to paint.
  final bool enabled;

  /// The canvas content.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      enabled ? CustomPaint(painter: _GridPainter(), child: child) : child;
}

class _GridPainter extends CustomPainter {
  static const double _step = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = DocsMetrics.rule
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += _step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += _step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

/// Puts [text] on the clipboard, for a synchronous tap handler.
void copyToClipboard(String text) {
  unawaited(Clipboard.setData(ClipboardData(text: text)));
}
