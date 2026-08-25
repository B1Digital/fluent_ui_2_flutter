import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// One column of trees, in the order the Figma axes vary: `Size`, then `Style`,
/// then the states a static image can hold — Selected and Disabled — then the
/// two composed slots, `FluentCheckbox` and a `FluentButton` in `Quick actions`.
///
/// The indent ramp is the thing to look at when a diff appears: every level is
/// 24 further in, and a leaf sits one step deeper than a branch at the same
/// level because it has no chevron to fill.
void main() {
  List<FluentTreeItem> items({bool enabled = true, Widget? actions}) =>
      <FluentTreeItem>[
        FluentTreeItem(
          value: 'src',
          label: const Text('src'),
          icon: const Icon(FluentIcons.folder_20_regular),
          enabled: enabled,
          actions: actions,
          children: <FluentTreeItem>[
            FluentTreeItem(
              value: 'widgets',
              label: const Text('widgets'),
              icon: const Icon(FluentIcons.folder_20_regular),
              enabled: enabled,
              children: const <FluentTreeItem>[
                FluentTreeItem(value: 'tree', label: Text('tree.dart')),
              ],
            ),
            FluentTreeItem(
              value: 'main',
              label: const Text('main.dart'),
              enabled: enabled,
            ),
          ],
        ),
        FluentTreeItem(
          value: 'readme',
          label: const Text('README.md'),
          enabled: enabled,
        ),
      ];

  Widget cell(FluentTree tree) => SizedBox(width: 280, child: tree);

  const open = <Object>{'src', 'widgets'};

  goldenGridTest(
    'tree',
    () => goldenGrid(<Widget>[
      // Size: 32-high body1 rows against 24-high caption1 rows.
      for (final size in FluentTreeSize.values)
        cell(FluentTree(size: size, items: items(), defaultOpenItems: open)),
      // Style: the three fills. Only Subtle and Subtle alpha differ from
      // Transparent once a row is hovered, which a static image cannot show —
      // the Selected row below is what makes the ramps visible.
      for (final appearance in FluentTreeAppearance.values)
        cell(
          FluentTree(
            appearance: appearance,
            items: items(),
            defaultOpenItems: open,
            selectedItems: const <Object>{'main'},
          ),
        ),
      // Disabled is a real state: the whole foreground family swaps, chevron
      // included.
      cell(FluentTree(items: items(enabled: false), defaultOpenItems: open)),
      // Composed: FluentCheckbox in the selector slot.
      cell(
        FluentTree(
          selectionMode: FluentTreeSelectionMode.multiple,
          items: items(),
          defaultOpenItems: open,
          selectedItems: const <Object>{'main'},
          onSelectionChange: (_) {},
        ),
      ),
      // Composed: FluentRadio in the selector slot.
      cell(
        FluentTree(
          selectionMode: FluentTreeSelectionMode.single,
          items: items(),
          defaultOpenItems: open,
          selectedItems: const <Object>{'main'},
          onSelectionChange: (_) {},
        ),
      ),
      // Composed: a real FluentButton in Figma's `Quick actions` slot.
      cell(
        FluentTree(
          items: items(
            actions: FluentButton.icon(
              icon: const Icon(FluentIcons.more_horizontal_20_regular),
              semanticLabel: 'More',
              appearance: FluentButtonAppearance.subtle,
              size: FluentButtonSize.small,
              onPressed: () {},
            ),
          ),
          defaultOpenItems: open,
        ),
      ),
    ], columns: 3),
    surfaceSize: const Size(1400, 1400),
  );
}
