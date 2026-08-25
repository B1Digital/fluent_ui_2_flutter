import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../docs_metrics.dart';
import '../showroom_scope.dart';
import '../theme_variants.dart';

/// The bar across the top of the content pane.
///
/// Measured off the live Storybook: 40px tall, 12px/700 labels in `#73828C`,
/// with a hairline under it. Left to right — the sidebar toggle, then grid,
/// background, outlines and preview size, then the theme and direction menus
/// and the interaction lock, and finally full screen pinned to the right.
///
/// One button has no honest Flutter counterpart. Upstream's padlock toggles
/// React strict mode, a React runtime flag; here it freezes pointer input to
/// the previews instead, which is the nearest thing a lock can actually do —
/// inspect a demo without driving it. The tooltip says so.
class ShellToolbar extends StatelessWidget {
  /// Creates the bar.
  const ShellToolbar({super.key});

  /// Upstream's height, and the hairline beneath it.
  static const double height = 40;

  static const Color _ink = Color(0xFF73828C);

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
        height: height,
        child: Row(
          children: <Widget>[
            const SizedBox(width: 8),
            // Only when the rail is hidden. With the sidebar on screen there is
            // nothing for it to restore, and upstream does not draw it either —
            // the way to close the rail is to drag its divider shut.
            if (!scope.sidebarVisible) ...<Widget>[
              _Icon(
                icon: FluentIcons.line_horizontal_3_20_regular,
                tooltip: 'Show sidebar',
                onPressed: scope.onToggleSidebar,
              ),
              const _Rule(),
            ],
            _Icon(
              icon: FluentIcons.grid_20_regular,
              tooltip: 'Apply a grid to the preview',
              selected: scope.grid,
              onPressed: scope.onToggleGrid,
            ),
            _Icon(
              icon: FluentIcons.image_20_regular,
              tooltip: 'Change the background of the preview',
              selected: scope.background,
              onPressed: scope.onToggleBackground,
            ),
            _Icon(
              icon: FluentIcons.scan_20_regular,
              tooltip: 'Apply outlines to the preview',
              selected: scope.outlines,
              onPressed: scope.onToggleOutlines,
            ),
            _Menu(
              tooltip: 'Change the size of the preview',
              selected: scope.viewport != PreviewViewport.responsive,
              icon: FluentIcons.arrow_down_20_regular,
              items: <FluentMenuItem>[
                for (final PreviewViewport size in PreviewViewport.values)
                  FluentMenuItem(
                    label: Text(size.label),
                    checked: size == scope.viewport,
                    onPressed: () => scope.onViewportChanged(size),
                  ),
              ],
            ),
            const _Rule(),
            _Menu(
              tooltip: 'Change Fluent theme',
              label: 'Theme: ${scope.variant.label}',
              items: <FluentMenuItem>[
                for (final ThemeVariant variant in ThemeVariant.values)
                  FluentMenuItem(
                    label: Text(variant.label),
                    checked: variant == scope.variant,
                    onPressed: () => scope.onVariantChanged(variant),
                  ),
              ],
            ),
            _Menu(
              tooltip: 'Change Direction',
              label: 'Direction: ${rtl ? 'RTL' : 'LTR'}',
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
            _Icon(
              icon: scope.locked
                  ? FluentIcons.lock_closed_20_regular
                  : FluentIcons.lock_open_20_regular,
              tooltip: 'Freeze interaction with the preview',
              selected: scope.locked,
              onPressed: scope.onToggleLocked,
            ),
            const Spacer(),
            _Icon(
              icon: scope.fullScreen
                  ? FluentIcons.full_screen_minimize_20_regular
                  : FluentIcons.full_screen_maximize_20_regular,
              tooltip: 'Go full screen',
              selected: scope.fullScreen,
              onPressed: scope.onToggleFullScreen,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    child: ColoredBox(
      color: DocsMetrics.rule,
      child: SizedBox(width: 1, height: double.infinity),
    ),
  );
}

class _Icon extends StatelessWidget {
  const _Icon({
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
          color: selected ? DocsMetrics.sidebarSelected : ShellToolbar._ink,
        ),
        semanticLabel: tooltip,
        appearance: FluentButtonAppearance.transparent,
        size: FluentButtonSize.small,
        onPressed: onPressed,
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({
    required this.tooltip,
    required this.items,
    this.label,
    this.icon,
    this.selected = false,
  });

  final String tooltip;
  final List<FluentMenuItem> items;
  final String? label;
  final IconData? icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color ink = selected
        ? DocsMetrics.sidebarSelected
        : ShellToolbar._ink;
    return FluentMenu(
      items: items,
      builder: (BuildContext context, VoidCallback toggle) => FluentTooltip(
        content: Text(tooltip),
        child: label == null
            ? FluentButton.icon(
                icon: Icon(icon, size: 16, color: ink),
                semanticLabel: tooltip,
                appearance: FluentButtonAppearance.transparent,
                size: FluentButtonSize.small,
                onPressed: toggle,
              )
            : FluentButton(
                appearance: FluentButtonAppearance.transparent,
                size: FluentButtonSize.small,
                onPressed: toggle,
                child: Text(
                  label!,
                  style: ShellToolbar._label.copyWith(color: ink),
                ),
              ),
      ),
    );
  }
}
