import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Regression net for `FluentMenu`, one image per theme.
///
/// The surface and its rows are built through the public three-function
/// contract rather than by opening the real overlay: an [Overlay] paints into a
/// different branch of the tree, so it would never land inside the golden's
/// [RepaintBoundary]. Everything the images cover — tokens, geometry, the
/// checkmark and chevron slots, the divider — is the same code the widget runs.
void main() {
  /// Figma draws the menu surface 260 wide.
  const width = 260.0;

  Widget menuRow(
    BuildContext context,
    FluentMenuItem item,
    Set<WidgetState> states, {
    required bool reserveLeading,
  }) {
    final state = resolveFluentMenuItemState(
      label: item.label,
      enabled: item.enabled,
      checked: item.checked,
      hasSubmenu: item.hasSubmenu,
      reserveLeading: reserveLeading,
      type: item.type,
      icon: item.icon,
      secondary: item.secondary,
      trailing: item.trailing,
    );
    return buildFluentMenuItem(
      state,
      resolveFluentMenuItemStyle(state, FluentTheme.of(context)),
      states,
    );
  }

  Widget menu(List<(FluentMenuItem, Set<WidgetState>)> rows) => SizedBox(
    width: width,
    child: Builder(
      builder: (context) {
        final reserveLeading = rows.any(
          (row) => row.$1.icon != null || row.$1.checked,
        );
        final state = resolveFluentMenuState(
          children: <Widget>[
            for (final (item, states) in rows)
              menuRow(context, item, states, reserveLeading: reserveLeading),
          ],
        );
        return buildFluentMenu(
          state,
          resolveFluentMenuStyle(state, FluentTheme.of(context)),
          const <WidgetState>{},
        );
      },
    ),
  );

  /// Every slot a row can fill, in the order Figma stacks them.
  Widget slots() => menu(<(FluentMenuItem, Set<WidgetState>)>[
    (const FluentMenuItem.header(label: Text('Clipboard')), const {}),
    (
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Cut'),
        trailing: const Text('Ctrl+X'),
        onPressed: () {},
      ),
      const {},
    ),
    (
      FluentMenuItem(
        icon: const Icon(FluentIcons.copy_20_regular),
        label: const Text('Copy'),
        secondary: const Text('Keeps formatting'),
        onPressed: () {},
      ),
      const {},
    ),
    (const FluentMenuItem.divider(), const {}),
    (
      FluentMenuItem(
        label: const Text('Word wrap'),
        checked: true,
        onPressed: () {},
      ),
      const {},
    ),
    (
      FluentMenuItem(
        label: const Text('Paste special'),
        submenu: <FluentMenuItem>[
          FluentMenuItem(label: const Text('Values'), onPressed: () {}),
        ],
      ),
      const {},
    ),
    (
      const FluentMenuItem.header(label: Text('Unavailable'), enabled: false),
      const {},
    ),
    (
      FluentMenuItem(
        icon: const Icon(FluentIcons.delete_20_regular),
        label: const Text('Delete'),
        enabled: false,
        onPressed: () {},
      ),
      const {WidgetState.disabled},
    ),
  ]);

  /// The `Menu item` State axis, one row per value.
  Widget states() => menu(<(FluentMenuItem, Set<WidgetState>)>[
    (
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Rest'),
        onPressed: () {},
      ),
      const {},
    ),
    (
      FluentMenuItem(
        label: const Text('Checked'),
        checked: true,
        onPressed: () {},
      ),
      const {},
    ),
    (
      FluentMenuItem(label: const Text('Hover'), onPressed: () {}),
      const {WidgetState.hovered},
    ),
    (
      FluentMenuItem(label: const Text('Pressed'), onPressed: () {}),
      const {WidgetState.pressed},
    ),
    (
      FluentMenuItem(
        label: const Text('Selected'),
        checked: true,
        selected: true,
        onPressed: () {},
      ),
      const {WidgetState.selected},
    ),
    (
      FluentMenuItem(label: const Text('Active'), onPressed: () {}),
      const {WidgetState.focused},
    ),
    (
      FluentMenuItem(
        label: const Text('Disabled'),
        enabled: false,
        onPressed: () {},
      ),
      const {WidgetState.disabled},
    ),
    (
      FluentMenuItem(
        label: const Text('Disabled checked'),
        checked: true,
        enabled: false,
        onPressed: () {},
      ),
      const {WidgetState.disabled},
    ),
  ]);

  goldenGridTest(
    'menu',
    () => goldenGrid(<Widget>[slots(), states()], columns: 2),
    surfaceSize: const Size(900, 700),
  );
}
