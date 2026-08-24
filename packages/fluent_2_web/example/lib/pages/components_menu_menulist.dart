import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The MenuList docs page.
///
/// Upstream's `MenuList` is a *permanent* menu surface — rows rendered inline,
/// with no trigger and nothing to open. `FluentMenu` only ever renders into an
/// overlay, so each demo composes the same surface from the package's public
/// recomposition functions: `resolveFluentMenuState`, `resolveFluentMenuStyle`
/// and `buildFluentMenu` for the card, their `FluentMenuItem` counterparts for
/// each row, and `FluentInteractive` for hover, press and the focus ring. Every
/// token, inset and ramp is Fluent's own.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
const DocsPage menuListPage = DocsPage(
  id: 'components-menu-menulist',
  folder: 'Menu',
  title: 'MenuList',
  description:
      'A menu list displays a list of actions. It is usually rendered inside '
      'of the Menu component.',
  source: 'lib/pages/components_menu_menulist.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-menu-menulist--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-menu-menulist--menu-list-with-nested-submenus',
      title: 'Menu List With Nested Submenus',
      description:
          'A permanent MenuList can also nest Menu components. This can be '
          'useful when embedding MenuList inside a custom temporary surface '
          'such as a popover dialog.',
      builder: _menuListWithNestedSubmenus,
    ),
    DocsSection(
      id: 'components-menu-menulist--checkbox-items',
      title: 'Checkbox Items',
      builder: _checkboxItems,
    ),
    DocsSection(
      id: 'components-menu-menulist--radio-items',
      title: 'Radio Items',
      builder: _radioItems,
    ),
    DocsSection(
      id: 'components-menu-menulist--controlled-checkbox-items',
      title: 'Controlled Checkbox Items',
      builder: _controlledCheckboxItems,
    ),
    DocsSection(
      id: 'components-menu-menulist--controlled-radio-items',
      title: 'Controlled Radio Items',
      builder: _controlledRadioItems,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'items',
      type: 'List<FluentMenuItem>',
      description:
          'The rows, in order. An empty list means the menu never opens.',
    ),
    PropRow(
      name: 'builder',
      type: 'FluentMenuTriggerBuilder',
      description: 'Builds the widget the menu hangs off.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentMenuStyle?',
      defaultValue: 'null',
      description:
          'Surface overrides layered over the theme defaults. Merged last, so '
          'it wins.',
    ),
    PropRow(
      name: 'itemStyle',
      type: 'FluentMenuItemStyle?',
      defaultValue: 'null',
      description:
          'Row overrides layered over the theme defaults. Merged last, so it '
          'wins.',
    ),
    PropRow(
      name: 'hoverDelay',
      type: 'Duration',
      defaultValue: 'fluentMenuHoverDelay',
      description:
          'How long a pointer rests on a row before its submenu opens.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: "Announced by assistive technology as the menu's own name.",
    ),
  ],
);

// #docregion components-menu-menulist--default
// A permanent menu surface. `FluentMenu` only renders into an overlay, so the
// card and its rows are composed from the package's public recomposition
// functions instead — same tokens, same geometry, no trigger.
Widget _default(BuildContext context) => _DefaultMenuList(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
    FluentMenuItem(label: const Text('Paste'), onPressed: () {}),
    FluentMenuItem(label: const Text('Edit'), onPressed: () {}),
  ],
);

class _DefaultMenuList extends StatelessWidget {
  const _DefaultMenuList({required this.items});

  final List<FluentMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    // One leading column for the whole list, so labels line up whether or not
    // their own row carries a glyph.
    final bool reserveLeading = items.any(
      (FluentMenuItem item) => item.icon != null || item.checked,
    );
    final FluentMenuState state = resolveFluentMenuState(
      children: <Widget>[
        for (final FluentMenuItem item in items)
          _row(theme, item, reserveLeading: reserveLeading),
      ],
    );
    return buildFluentMenu(
      state,
      resolveFluentMenuStyle(state, theme),
      const <WidgetState>{},
    );
  }

  Widget _row(
    FluentThemeData theme,
    FluentMenuItem item, {
    required bool reserveLeading,
  }) {
    final FluentMenuItemState state = resolveFluentMenuItemState(
      label: item.label,
      icon: item.icon,
      checked: item.checked,
      reserveLeading: reserveLeading,
    );
    final FluentMenuItemStyle style = resolveFluentMenuItemStyle(state, theme);
    return Semantics(
      button: true,
      checked: item.checked ? true : null,
      child: FluentInteractive(
        onPressed: item.onPressed,
        builder:
            (BuildContext context, Set<WidgetState> states, Widget? child) =>
                buildFluentMenuItem(state, style, states),
      ),
    );
  }
}
// #enddocregion components-menu-menulist--default

// #docregion components-menu-menulist--menu-list-with-nested-submenus
// The permanent rows are composed by hand, as in every section here; the one
// row that owns a submenu hands its rendering to a real `FluentMenu`, which is
// what opens, positions and keyboard-drives the nested surface. `FluentMenu`
// anchors a root level under its trigger, so the submenu drops below the
// Preferences row rather than beside it.
Widget _menuListWithNestedSubmenus(BuildContext context) => _NestedMenuList(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
    FluentMenuItem(label: const Text('Paste'), onPressed: () {}),
    FluentMenuItem(label: const Text('Edit'), onPressed: () {}),
    FluentMenuItem(
      label: const Text('Preferences'),
      submenu: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
        FluentMenuItem(label: const Text('Paste'), onPressed: () {}),
        FluentMenuItem(label: const Text('Edit'), onPressed: () {}),
      ],
    ),
  ],
);

class _NestedMenuList extends StatelessWidget {
  const _NestedMenuList({required this.items});

  final List<FluentMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final bool reserveLeading = items.any(
      (FluentMenuItem item) => item.icon != null || item.checked,
    );
    final FluentMenuState state = resolveFluentMenuState(
      children: <Widget>[
        for (final FluentMenuItem item in items)
          _row(theme, item, reserveLeading: reserveLeading),
      ],
    );
    return buildFluentMenu(
      state,
      resolveFluentMenuStyle(state, theme),
      const <WidgetState>{},
    );
  }

  Widget _row(
    FluentThemeData theme,
    FluentMenuItem item, {
    required bool reserveLeading,
  }) {
    final FluentMenuItemState state = resolveFluentMenuItemState(
      label: item.label,
      icon: item.icon,
      checked: item.checked,
      hasSubmenu: item.hasSubmenu,
      reserveLeading: reserveLeading,
    );
    final FluentMenuItemStyle style = resolveFluentMenuItemStyle(state, theme);
    Widget row(VoidCallback? onPressed) => Semantics(
      button: true,
      checked: item.checked ? true : null,
      child: FluentInteractive(
        onPressed: onPressed,
        builder:
            (BuildContext context, Set<WidgetState> states, Widget? child) =>
                buildFluentMenuItem(state, style, states),
      ),
    );
    if (item.hasSubmenu) {
      return FluentMenu(
        items: item.submenu,
        builder: (BuildContext context, VoidCallback toggle) => row(toggle),
      );
    }
    return row(item.onPressed);
  }
}
// #enddocregion components-menu-menulist--menu-list-with-nested-submenus

// #docregion components-menu-menulist--checkbox-items
// `FluentMenuItem` has no checkbox variant: `checked` paints Fluent's checkmark
// in the row's single leading slot, so a checked row shows the tick where an
// unchecked one shows its icon. Upstream's `bundleIcon` pairs have no hook
// either, so each glyph keeps its regular weight in every state.
Widget _checkboxItems(BuildContext context) => const _CheckboxItems();

class _CheckboxItems extends StatefulWidget {
  const _CheckboxItems();

  @override
  State<_CheckboxItems> createState() => _CheckboxItemsState();
}

class _CheckboxItemsState extends State<_CheckboxItems> {
  // Upstream's `name="edit"` group, holding the `value` of every checked row.
  final Set<String> _edit = <String>{};

  void _toggle(String value) => setState(() {
    if (!_edit.remove(value)) _edit.add(value);
  });

  @override
  Widget build(BuildContext context) => _CheckboxMenuList(
    items: <FluentMenuItem>[
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Cut'),
        checked: _edit.contains('cut'),
        onPressed: () => _toggle('cut'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.clipboard_paste_20_regular),
        label: const Text('Paste'),
        checked: _edit.contains('paste'),
        onPressed: () => _toggle('paste'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.edit_20_regular),
        label: const Text('Edit'),
        checked: _edit.contains('edit'),
        onPressed: () => _toggle('edit'),
      ),
    ],
  );
}

class _CheckboxMenuList extends StatelessWidget {
  const _CheckboxMenuList({required this.items});

  final List<FluentMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final bool reserveLeading = items.any(
      (FluentMenuItem item) => item.icon != null || item.checked,
    );
    final FluentMenuState state = resolveFluentMenuState(
      children: <Widget>[
        for (final FluentMenuItem item in items)
          _row(theme, item, reserveLeading: reserveLeading),
      ],
    );
    return buildFluentMenu(
      state,
      resolveFluentMenuStyle(state, theme),
      const <WidgetState>{},
    );
  }

  Widget _row(
    FluentThemeData theme,
    FluentMenuItem item, {
    required bool reserveLeading,
  }) {
    final FluentMenuItemState state = resolveFluentMenuItemState(
      label: item.label,
      icon: item.icon,
      checked: item.checked,
      reserveLeading: reserveLeading,
    );
    final FluentMenuItemStyle style = resolveFluentMenuItemStyle(state, theme);
    return Semantics(
      button: true,
      checked: item.checked,
      child: FluentInteractive(
        onPressed: item.onPressed,
        builder:
            (BuildContext context, Set<WidgetState> states, Widget? child) =>
                buildFluentMenuItem(state, style, states),
      ),
    );
  }
}
// #enddocregion components-menu-menulist--checkbox-items

// #docregion components-menu-menulist--radio-items
// One `name="font"` group: picking a row replaces the selection rather than
// adding to it. `FluentMenuItem` has no radio variant, so the checked row is
// marked with Fluent's checkmark in its leading slot.
Widget _radioItems(BuildContext context) => const _RadioItems();

class _RadioItems extends StatefulWidget {
  const _RadioItems();

  @override
  State<_RadioItems> createState() => _RadioItemsState();
}

class _RadioItemsState extends State<_RadioItems> {
  String? _font;

  void _select(String value) => setState(() => _font = value);

  @override
  Widget build(BuildContext context) => _RadioMenuList(
    items: <FluentMenuItem>[
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Segoe'),
        checked: _font == 'segoe',
        onPressed: () => _select('segoe'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.clipboard_paste_20_regular),
        label: const Text('Calibri'),
        checked: _font == 'calibri',
        onPressed: () => _select('calibri'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.edit_20_regular),
        label: const Text('Arial'),
        checked: _font == 'arial',
        onPressed: () => _select('arial'),
      ),
    ],
  );
}

class _RadioMenuList extends StatelessWidget {
  const _RadioMenuList({required this.items});

  final List<FluentMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final bool reserveLeading = items.any(
      (FluentMenuItem item) => item.icon != null || item.checked,
    );
    final FluentMenuState state = resolveFluentMenuState(
      children: <Widget>[
        for (final FluentMenuItem item in items)
          _row(theme, item, reserveLeading: reserveLeading),
      ],
    );
    return buildFluentMenu(
      state,
      resolveFluentMenuStyle(state, theme),
      const <WidgetState>{},
    );
  }

  Widget _row(
    FluentThemeData theme,
    FluentMenuItem item, {
    required bool reserveLeading,
  }) {
    final FluentMenuItemState state = resolveFluentMenuItemState(
      label: item.label,
      icon: item.icon,
      checked: item.checked,
      reserveLeading: reserveLeading,
    );
    final FluentMenuItemStyle style = resolveFluentMenuItemStyle(state, theme);
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: item.checked,
      child: FluentInteractive(
        onPressed: item.onPressed,
        builder:
            (BuildContext context, Set<WidgetState> states, Widget? child) =>
                buildFluentMenuItem(state, style, states),
      ),
    );
  }
}
// #enddocregion components-menu-menulist--radio-items

// #docregion components-menu-menulist--controlled-checkbox-items
// Upstream's `checkedValues` / `onCheckedValueChange` pair. `FluentMenuItem`'s
// `checked` is always caller-owned, so a controlled list is written exactly
// like the uncontrolled one above — the only difference is that this one starts
// with `cut` and `paste` already in the `edit` group.
Widget _controlledCheckboxItems(BuildContext context) =>
    const _ControlledCheckboxItems();

class _ControlledCheckboxItems extends StatefulWidget {
  const _ControlledCheckboxItems();

  @override
  State<_ControlledCheckboxItems> createState() =>
      _ControlledCheckboxItemsState();
}

class _ControlledCheckboxItemsState extends State<_ControlledCheckboxItems> {
  final Set<String> _edit = <String>{'cut', 'paste'};

  void _toggle(String value) => setState(() {
    if (!_edit.remove(value)) _edit.add(value);
  });

  @override
  Widget build(BuildContext context) => _ControlledCheckboxMenuList(
    items: <FluentMenuItem>[
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Cut'),
        checked: _edit.contains('cut'),
        onPressed: () => _toggle('cut'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.clipboard_paste_20_regular),
        label: const Text('Paste'),
        checked: _edit.contains('paste'),
        onPressed: () => _toggle('paste'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.edit_20_regular),
        label: const Text('Edit'),
        checked: _edit.contains('edit'),
        onPressed: () => _toggle('edit'),
      ),
    ],
  );
}

class _ControlledCheckboxMenuList extends StatelessWidget {
  const _ControlledCheckboxMenuList({required this.items});

  final List<FluentMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final bool reserveLeading = items.any(
      (FluentMenuItem item) => item.icon != null || item.checked,
    );
    final FluentMenuState state = resolveFluentMenuState(
      children: <Widget>[
        for (final FluentMenuItem item in items)
          _row(theme, item, reserveLeading: reserveLeading),
      ],
    );
    return buildFluentMenu(
      state,
      resolveFluentMenuStyle(state, theme),
      const <WidgetState>{},
    );
  }

  Widget _row(
    FluentThemeData theme,
    FluentMenuItem item, {
    required bool reserveLeading,
  }) {
    final FluentMenuItemState state = resolveFluentMenuItemState(
      label: item.label,
      icon: item.icon,
      checked: item.checked,
      reserveLeading: reserveLeading,
    );
    final FluentMenuItemStyle style = resolveFluentMenuItemStyle(state, theme);
    return Semantics(
      button: true,
      checked: item.checked,
      child: FluentInteractive(
        onPressed: item.onPressed,
        builder:
            (BuildContext context, Set<WidgetState> states, Widget? child) =>
                buildFluentMenuItem(state, style, states),
      ),
    );
  }
}
// #enddocregion components-menu-menulist--controlled-checkbox-items

// #docregion components-menu-menulist--controlled-radio-items
// The controlled counterpart of the radio list: the `font` group starts on
// `calibri`, and every press replaces the value the caller holds.
Widget _controlledRadioItems(BuildContext context) =>
    const _ControlledRadioItems();

class _ControlledRadioItems extends StatefulWidget {
  const _ControlledRadioItems();

  @override
  State<_ControlledRadioItems> createState() => _ControlledRadioItemsState();
}

class _ControlledRadioItemsState extends State<_ControlledRadioItems> {
  String _font = 'calibri';

  void _select(String value) => setState(() => _font = value);

  @override
  Widget build(BuildContext context) => _ControlledRadioMenuList(
    items: <FluentMenuItem>[
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Segoe'),
        checked: _font == 'segoe',
        onPressed: () => _select('segoe'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.clipboard_paste_20_regular),
        label: const Text('Calibri'),
        checked: _font == 'calibri',
        onPressed: () => _select('calibri'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.edit_20_regular),
        label: const Text('Arial'),
        checked: _font == 'arial',
        onPressed: () => _select('arial'),
      ),
    ],
  );
}

class _ControlledRadioMenuList extends StatelessWidget {
  const _ControlledRadioMenuList({required this.items});

  final List<FluentMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final bool reserveLeading = items.any(
      (FluentMenuItem item) => item.icon != null || item.checked,
    );
    final FluentMenuState state = resolveFluentMenuState(
      children: <Widget>[
        for (final FluentMenuItem item in items)
          _row(theme, item, reserveLeading: reserveLeading),
      ],
    );
    return buildFluentMenu(
      state,
      resolveFluentMenuStyle(state, theme),
      const <WidgetState>{},
    );
  }

  Widget _row(
    FluentThemeData theme,
    FluentMenuItem item, {
    required bool reserveLeading,
  }) {
    final FluentMenuItemState state = resolveFluentMenuItemState(
      label: item.label,
      icon: item.icon,
      checked: item.checked,
      reserveLeading: reserveLeading,
    );
    final FluentMenuItemStyle style = resolveFluentMenuItemStyle(state, theme);
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: item.checked,
      child: FluentInteractive(
        onPressed: item.onPressed,
        builder:
            (BuildContext context, Set<WidgetState> states, Widget? child) =>
                buildFluentMenuItem(state, style, states),
      ),
    );
  }
}

// #enddocregion components-menu-menulist--controlled-radio-items
