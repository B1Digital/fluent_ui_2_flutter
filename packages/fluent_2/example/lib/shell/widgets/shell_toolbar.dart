import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../showroom_scope.dart';
import '../theme_variants.dart';
import 'preview_band.dart';
import 'toolbar_parts.dart';

/// The bar across the top of the docs pane: Storybook 9.1.17's docs-mode
/// toolbar.
///
/// Left to right, as the live bar lays it out (`docsTools`): "Show sidebar"
/// and a separator only while the sidebar is hidden (`menu.tsx`), then Grid,
/// Background, Outline, Theme, Direction and Strict mode, and Full screen
/// against the right edge (`Toolbar.tsx:32-72`). No viewport control and no
/// other separator: viewport is story-only (`viewport/manager.tsx:13`), and
/// the down arrow after Outline is the one inside the Theme button.
///
/// Every control reads and writes [ShowroomScope], so the same state drives
/// every preview and survives navigation.
class ShellToolbar extends StatelessWidget {
  /// Creates the bar.
  const ShellToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final ShowroomScope scope = ShowroomScope.of(context);
    // `shortcut.ts:11,146-147`: `⌥` where `navigator.platform` is Mac-like
    // (Mac, iPhone, iPod, iPad), `alt` elsewhere. Upstream disables the
    // shortcut itself site-wide (`enableShortcuts: false`), so none is bound.
    final String shortcut = switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.iOS => '⌥ F',
      _ => 'alt F',
    };
    final String fullScreen = scope.fullScreen
        ? 'Exit full screen'
        : 'Go full screen';

    return ToolbarFrame(
      start: <Widget>[
        if (!scope.sidebarVisible) ...<Widget>[
          ToolbarButton(
            icon: FluentIcons.line_horizontal_3_20_regular,
            tooltip: 'Show sidebar',
            onPressed: scope.onToggleSidebar,
          ),
          const ToolbarSeparator(),
        ],
        ToolbarButton(
          icon: FluentIcons.grid_20_regular,
          tooltip: 'Apply a grid to the preview',
          active: scope.grid,
          onPressed: scope.onToggleGrid,
        ),
        // `backgrounds/components/Tool.tsx:96-142`: "Reset background" first
        // only while one is set, then the options with a colour swatch each.
        ToolbarMenuButton(
          icon: FluentIcons.image_20_regular,
          tooltip: 'Change the background of the preview',
          active: scope.background != null,
          items: <FluentMenuItem>[
            if (scope.background != null)
              FluentMenuItem(
                icon: const Icon(FluentIcons.arrow_clockwise_20_regular),
                label: const Text('Reset background'),
                onPressed: () => scope.onBackgroundChanged(null),
              ),
            for (final PreviewBackground option in PreviewBackground.values)
              FluentMenuItem(
                icon: Icon(FluentIcons.circle_20_filled, color: option.color),
                label: toolbarItemLabel(
                  option.label,
                  chosen: option == scope.background,
                ),
                onPressed: () => scope.onBackgroundChanged(option),
              ),
          ],
        ),
        const OutlineTool(),
        const ThemeTool(),
        const DirectionTool(),
        const StrictModeTool(),
      ],
      end: <Widget>[
        // Never active: upstream swaps the glyph and the words instead.
        ToolbarButton(
          icon: scope.fullScreen
              ? FluentIcons.dismiss_circle_20_regular
              : FluentIcons.arrow_maximize_20_regular,
          tooltip: '$fullScreen [$shortcut]',
          semanticLabel: fullScreen,
          onPressed: scope.onToggleSidebar,
        ),
      ],
    );
  }
}

/// "Apply outlines to the preview" (`outline/OutlineSelector.tsx`): a toggle,
/// active while on.
///
/// Upstream's glyph is a dashed square with a centre dot. Fluent has no dotted
/// one; `square_hint` is its dashed square (`select_object` looks like the
/// obvious pick by name, but it draws a solid square with corner handles).
class OutlineTool extends StatelessWidget {
  /// Creates the control.
  const OutlineTool({super.key});

  @override
  Widget build(BuildContext context) {
    final ShowroomScope scope = ShowroomScope.of(context);
    return ToolbarButton(
      icon: FluentIcons.square_hint_20_regular,
      tooltip: 'Apply outlines to the preview',
      active: scope.outlines,
      onPressed: scope.onToggleOutlines,
    );
  }
}

/// "Change Fluent theme" (`react-storybook-addon` `ThemePicker.tsx:77-80`):
/// one button holding `<ArrowDownIcon/>` then `<span style={{marginLeft: 5}}>
/// Theme: …</span>`, so the text starts 11px after the 14px arrow (the bar's
/// 6px gap plus that 5px). Active whenever the theme is not the default.
///
/// The menu is the seven themes, Web Light as "Web Light (Default)"
/// (`ThemePicker.tsx:29`), the current one marked by its label alone.
class ThemeTool extends StatelessWidget {
  /// Creates the control.
  const ThemeTool({super.key});

  @override
  Widget build(BuildContext context) {
    final ShowroomScope scope = ShowroomScope.of(context);
    return ToolbarMenuButton(
      icon: FluentIcons.arrow_down_20_regular,
      label: Padding(
        padding: const EdgeInsetsDirectional.only(start: 5),
        child: Text('Theme: ${scope.variant.label}'),
      ),
      tooltip: 'Change Fluent theme',
      active: scope.variant != ThemeVariant.webLight,
      items: <FluentMenuItem>[
        for (final ThemeVariant variant in ThemeVariant.values)
          FluentMenuItem(
            label: toolbarItemLabel(
              variant == ThemeVariant.webLight
                  ? '${variant.label} (Default)'
                  : variant.label,
              chosen: variant == scope.variant,
            ),
            onPressed: () => scope.onVariantChanged(variant),
          ),
      ],
    );
  }
}

/// "Change Direction" (`react-storybook-addon` `DirectionSwitch.tsx:9-31`):
/// ONE click flips LTR and RTL — no popover, never active.
///
/// Markup `Direction: <span>LTR</span>`, the value in the addon's monospace
/// stack at `letter-spacing: -0.05em` (-0.6px at the bar's 12px).
class DirectionTool extends StatelessWidget {
  /// Creates the control.
  const DirectionTool({super.key});

  static const TextStyle _value = TextStyle(
    fontFamily: 'Cascadia Code',
    fontFamilyFallback: <String>[
      'Menlo',
      'Courier New',
      'Courier',
      'monospace',
    ],
    letterSpacing: -0.6,
  );

  @override
  Widget build(BuildContext context) {
    final ShowroomScope scope = ShowroomScope.of(context);
    final bool rtl = scope.textDirection == TextDirection.rtl;
    return ToolbarButton(
      label: Text.rich(
        TextSpan(
          text: 'Direction: ',
          children: <InlineSpan>[
            TextSpan(text: rtl ? 'RTL' : 'LTR', style: _value),
          ],
        ),
      ),
      tooltip: 'Change Direction',
      onPressed: () => scope.onTextDirectionChanged(
        rtl ? TextDirection.ltr : TextDirection.rtl,
      ),
    );
  }
}

/// "Toggle React Strict mode" (`react-storybook-addon`
/// `ReactStrictMode.tsx`): the closed padlock whatever the state, active while
/// on.
///
/// Upstream wraps or unwraps each story in `<React.StrictMode>`
/// (`withReactStrictMode.tsx:18-20`); the element type changing is what
/// remounts it, and that remount is the only effect the live site shows. The
/// previews key their story on [ShowroomScope.strictMode] for the same effect.
class StrictModeTool extends StatelessWidget {
  /// Creates the control.
  const StrictModeTool({super.key});

  @override
  Widget build(BuildContext context) {
    final ShowroomScope scope = ShowroomScope.of(context);
    return ToolbarButton(
      icon: FluentIcons.lock_closed_20_regular,
      tooltip: 'Toggle React Strict mode',
      active: scope.strictMode,
      onPressed: scope.onToggleStrictMode,
    );
  }
}
