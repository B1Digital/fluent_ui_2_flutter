import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Menu docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Upstream composes a menu out of `Menu`, `MenuTrigger`, `MenuPopover`,
/// `MenuList` and a family of `MenuItem*` elements. [FluentMenu] collapses that
/// into one widget: `items` is the list, and `builder` is the trigger. So every
/// section here is a single [FluentMenu] rather than a five-element tree, and
/// `hasIcons` / `hasCheckmarks` have no counterpart because the menu already
/// reserves the leading column whenever any row needs one.
const DocsPage menuPage = DocsPage(
  id: 'components-menu-menu',
  folder: 'Menu',
  title: 'Menu',
  description:
      'A menu displays a list of actions. The Menu component handles the state '
      'management of the passed in list of actions. See also MenuButton',
  source: 'lib/pages/components_menu_menu.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-menu-menu--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-menu-menu--interaction',
      title: 'Interaction',
      description:
          'Each sub component of the Menu that renders DOM elements can be '
          'assigned HTML event listeners. You can simply add an onClick '
          'listener to individual MenuItem without needing to control the '
          'entire component. Special handling is required for checkboxes and '
          'radio items inside a Menu, read the further examples below to see '
          'how to handle those variants.',
      builder: _interaction,
    ),
    DocsSection(
      id: 'components-menu-menu--menu-item-link-navigation',
      title: 'Menu Item Link Navigation',
      description:
          'To implement a navigation menu, simply use the MenuItemLink '
          'component that provides the correct semantics for link based '
          'navigation.',
      builder: _menuItemLinkNavigation,
    ),
    DocsSection(
      id: 'components-menu-menu--menu-items-with-icons',
      title: 'Menu Items With Icons',
      builder: _menuItemsWithIcons,
    ),
    DocsSection(
      id: 'components-menu-menu--aligning-with-icons',
      title: 'Aligning With Icons',
      description:
          'The hasIcons prop will align menu items if only a subset of menu '
          'items contain an icon. When separation of menu items is only for '
          'visual aesthetics, the MenuDivider component can be used by itself '
          'as it has no accessible markup features.',
      builder: _aligningWithIcons,
    ),
    DocsSection(
      id: 'components-menu-menu--aligning-with-selectable-items',
      title: 'Aligning With Selectable Items',
      description:
          'The hasCheckmarks prop will align menu items if only a subset of '
          'menu items are selectable.',
      builder: _aligningWithSelectableItems,
    ),
    DocsSection(
      id: 'components-menu-menu--secondary-content-for-menu-items',
      title: 'Secondary Content For Menu Items',
      builder: _secondaryContentForMenuItems,
    ),
    DocsSection(
      id: 'components-menu-menu--multiline-items',
      title: 'Multiline Items',
      builder: _multilineItems,
    ),
    DocsSection(
      id: 'components-menu-menu--controlling-open-and-close',
      title: 'Controlling Open And Close',
      description:
          'The opening and close of the Menu can be controlled with your own '
          'state. The onOpenChange callback will provide the hints for the '
          'state and triggers based on the appropriate event. When controlling '
          'the open state of the Menu, extra effort is required to ensure that '
          'interactions are still appropriate and that keyboard accessibility '
          'does not degrade.',
      builder: _controllingOpenAndClose,
    ),
    DocsSection(
      id: 'components-menu-menu--grouping-items',
      title: 'Grouping Items',
      description:
          'A menu can be divided in to separate groups, using the MenuGroup '
          'and MenuGroupHeader components. This ensures the correct accessible '
          'markup is rendered for screen reader users.',
      builder: _groupingItems,
    ),
    DocsSection(
      id: 'components-menu-menu--visual-divider-only',
      title: 'Visual Divider Only',
      description:
          'If a divider is needed only for visual aesthetics, the MenuDivider '
          'component can be used separately. When items should be logically '
          'groupped, use the MenuGroup and MenuGroupHeader components for '
          'correct accessible markup.',
      builder: _visualDividerOnly,
    ),
    DocsSection(
      id: 'components-menu-menu--checkbox-items',
      title: 'Checkbox Items',
      description:
          'A variant of MenuItem that handles checkbox like selection. The '
          'name and value props are are used similar to HTML checkboxes with '
          'input',
      builder: _checkboxItems,
    ),
    DocsSection(
      id: 'components-menu-menu--switch-item',
      title: 'Switch Item',
      description:
          'A variant of MenuItemCheckbox that displays selection using a '
          "switch design. This is commonly used for menus that don't really "
          'have strong selection function but needs to support an exceptional '
          'selected option.',
      builder: _switchItem,
    ),
    DocsSection(
      id: 'components-menu-menu--radio-items',
      title: 'Radio Items',
      description:
          'A variant of MenuItem that handles radio like selection. The name '
          'and value props are are used similar to HTML checkboxes with input',
      builder: _radioItems,
    ),
    DocsSection(
      id: 'components-menu-menu--controlled-checkbox-items',
      title: 'Controlled Checkbox Items',
      builder: _controlledCheckboxItems,
    ),
    DocsSection(
      id: 'components-menu-menu--controlled-radio-items',
      title: 'Controlled Radio Items',
      builder: _controlledRadioItems,
    ),
    DocsSection(
      id: 'components-menu-menu--selection-group',
      title: 'Selection Group',
      description:
          'Both menu item checkboxes and radio items can be used in the same '
          'menu surface. Different selection areas should be grouped to '
          'provide clear expectations for users.',
      builder: _selectionGroup,
    ),
    DocsSection(
      id: 'components-menu-menu--nested-submenus',
      title: 'Nested Submenus',
      description:
          'Menus can be nested within each other to render application '
          'submenus. Submenus are a complex control for any app, make sure you '
          'need them. Try and limit nesting to 2 levels. Creating submenus as '
          'separate components will result in more maintainable code.',
      builder: _nestedSubmenus,
    ),
    DocsSection(
      id: 'components-menu-menu--nested-submenus-controlled',
      title: 'Nested Submenus Controlled',
      description:
          'Menus can be nested within each other to render application '
          'submenus. Submenus are a complex control for any app, make sure you '
          'need them. Try and limit nesting to 2 levels. Creating submenus as '
          'separate components will result in more maintainable code.',
      builder: _nestedSubmenusControlled,
    ),
    DocsSection(
      id: 'components-menu-menu--nested-submenus-responsiveness',
      title: 'Nested Submenus Responsiveness',
      description:
          'Nested submenus have some limited responsiveness built in. If the '
          'boundaries of the container/viewport get smaller, nested submenus '
          'will try to position themselves accordingly. Below is the order or '
          'fallbacks that will happen: Move alignment of the nested menu '
          'higher Flip the position of the nested menu Position the nested '
          'menu above the parent menu You can use the resizable container '
          'below to try this out. (Click outside the resizable area to dismiss '
          'the menus)',
      builder: _nestedSubmenusResponsiveness,
    ),
    DocsSection(
      id: 'components-menu-menu--anchor-to-custom-target',
      title: 'Anchor To Custom Target',
      description:
          'A Menu can be used without a trigger and anchored to any DOM '
          'element. This can be useful if a Menu instance needs to be reused '
          'in different places. Not using a MenuTrigger will require more work '
          'to make sure your scenario is accessible such as implementing '
          'accessible markup and keyboard interactions for your trigger',
      builder: _anchorToCustomTarget,
    ),
    DocsSection(
      id: 'components-menu-menu--custom-trigger',
      title: 'Custom Trigger',
      description:
          'Native elements and Fluent components have first class support as '
          'children of MenuTrigger so they will be injected automatically with '
          'the correct props for interactions and accessibility attributes. It '
          'is possible to use your own custom React component as a child of '
          'MenuTrigger. These components should use ref forwarding with '
          'React.forwardRef',
      builder: _customTrigger,
    ),
    DocsSection(
      id: 'components-menu-menu--render-function-trigger',
      title: 'Render Function Trigger',
      description:
          'When a function is passed as the children of MenuTrigger, the '
          'actual trigger can be customized to be an inner part of the '
          'function.',
      builder: _renderFunctionTrigger,
    ),
    DocsSection(
      id: 'components-menu-menu--memoized-menu-items',
      title: 'Memoized Menu Items',
      description:
          'Rerendering menu items is a cheap operation and React philosophy '
          'encourages rerenders. Memoization is not free, so use it only when '
          'there are concrete benefits to doing so. Memoized menu items can be '
          'created using React.memo to optimize rerenders of menu items if '
          'their props have not changed. Can be useful for selectable items, '
          'since each selection will rerender all items in the menu by default.',
      builder: _memoizedMenuItems,
    ),
    DocsSection(
      id: 'components-menu-menu--split-menu-item',
      title: 'Split Menu Item',
      description:
          'A menu item can be split into a main action and a trigger that '
          'opens a submenu. Use this pattern sparingly. Make sure to add an '
          'aria-label to the trigger for screen reader users.',
      builder: _splitMenuItem,
    ),
    DocsSection(
      id: 'components-menu-menu--menu-trigger-with-tooltip',
      title: 'Menu Trigger With Tooltip',
      description: 'A trigger for Menu can also have a tooltip.',
      builder: _menuTriggerWithTooltip,
    ),
    DocsSection(
      id: 'components-menu-menu--motion-custom',
      title: 'Motion Custom',
      description:
          'Menu animations can be customized using the Motion APIs, together '
          'with the surfaceMotion slot.',
      builder: _motionCustom,
    ),
    DocsSection(
      id: 'components-menu-menu--motion-disabled',
      title: 'Motion Disabled',
      description:
          'To disable the Menu transition animation, set the surfaceMotion '
          'prop to null.',
      builder: _motionDisabled,
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

// #docregion components-menu-menu--default
Widget _default(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('New '), onPressed: () {}),
    FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
    const FluentMenuItem(label: Text('Open File'), enabled: false),
    FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
);
// #enddocregion components-menu-menu--default

// #docregion components-menu-menu--interaction
// Upstream calls `alert()` from each row's `onClick`. Flutter has no `alert`,
// so the same three strings land in local state and render under the trigger —
// the point of the section is that a row carries its own callback, and that
// part is unchanged.
//
// Upstream's `bundleIcon` also swaps the filled glyph in on hover; a
// `FluentMenuItem` icon has no per-state hook, so the regular glyph stays.
Widget _interaction(BuildContext context) => const _Interaction();

class _Interaction extends StatefulWidget {
  const _Interaction();

  @override
  State<_Interaction> createState() => _InteractionState();
}

class _InteractionState extends State<_Interaction> {
  String? _message;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentMenu(
        items: <FluentMenuItem>[
          FluentMenuItem(
            icon: const Icon(FluentIcons.cut_20_regular),
            label: const Text('Cut'),
            onPressed: () => setState(() => _message = 'Cut to clipboard'),
          ),
          FluentMenuItem(
            icon: const Icon(FluentIcons.copy_20_regular),
            label: const Text('Copy'),
            onPressed: () => setState(() => _message = 'Copied to clipboard'),
          ),
          FluentMenuItem(
            icon: const Icon(FluentIcons.clipboard_paste_20_regular),
            label: const Text('Paste'),
            onPressed: () => setState(() => _message = 'Pasted from clipboard'),
          ),
        ],
        builder: (BuildContext context, VoidCallback toggle) =>
            FluentButton(onPressed: toggle, child: const Text('Edit content')),
      ),
      if (_message != null) ...<Widget>[
        const SizedBox(height: 12),
        Text(_message!),
      ],
    ],
  );
}
// #enddocregion components-menu-menu--interaction

// #docregion components-menu-menu--menu-item-link-navigation
// Upstream's `MenuItemLink` renders an `<a href>`. `fluent_2` deliberately
// ships no URL launcher — `FluentLink` has an `onPressed`, not an `href` — so
// each row keeps its label and its callback is where the navigation to
// 'https://www.microsoft.com' would go.
Widget _menuItemLinkNavigation(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('Home'), onPressed: () {}),
    FluentMenuItem(label: const Text('Online shop'), onPressed: () {}),
    FluentMenuItem(label: const Text('Contact us'), onPressed: () {}),
    FluentMenuItem(label: const Text('About'), onPressed: () {}),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Navigation menu')),
);
// #enddocregion components-menu-menu--menu-item-link-navigation

// #docregion components-menu-menu--menu-items-with-icons
Widget _menuItemsWithIcons(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(
      icon: const Icon(FluentIcons.cut_20_regular),
      label: const Text('Cut'),
      onPressed: () {},
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.clipboard_paste_20_regular),
      label: const Text('Paste'),
      onPressed: () {},
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.edit_20_regular),
      label: const Text('Edit'),
      onPressed: () {},
    ),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
);
// #enddocregion components-menu-menu--menu-items-with-icons

// #docregion components-menu-menu--aligning-with-icons
// There is no `hasIcons` flag to set: `FluentMenu` reserves the leading column
// for the whole surface as soon as any one row carries an icon or a checkmark,
// so 'Cut' and 'Edit' line up with 'Paste' on their own.
Widget _aligningWithIcons(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('Cut'), onPressed: () {}),
    FluentMenuItem(
      icon: const Icon(FluentIcons.clipboard_paste_20_regular),
      label: const Text('Paste'),
      onPressed: () {},
    ),
    FluentMenuItem(label: const Text('Edit'), onPressed: () {}),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
);
// #enddocregion components-menu-menu--aligning-with-icons

// #docregion components-menu-menu--aligning-with-selectable-items
// `hasCheckmarks` has no counterpart either — see 'Aligning With Icons'. The
// selectable row reserves the column and the two plain rows follow it.
Widget _aligningWithSelectableItems(BuildContext context) =>
    const _AligningWithSelectableItems();

class _AligningWithSelectableItems extends StatefulWidget {
  const _AligningWithSelectableItems();

  @override
  State<_AligningWithSelectableItems> createState() =>
      _AligningWithSelectableItemsState();
}

class _AligningWithSelectableItemsState
    extends State<_AligningWithSelectableItems> {
  // Upstream's row is `name="edit" value="cut"`: the `edit` group is just the
  // set of values the caller has checked.
  final Set<String> _edit = <String>{};

  @override
  Widget build(BuildContext context) => FluentMenu(
    items: <FluentMenuItem>[
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Checkbox item'),
        checked: _edit.contains('cut'),
        onPressed: () => setState(() {
          if (!_edit.remove('cut')) _edit.add('cut');
        }),
      ),
      FluentMenuItem(label: const Text('Menu item'), onPressed: () {}),
      FluentMenuItem(label: const Text('Menu item'), onPressed: () {}),
    ],
    builder: (BuildContext context, VoidCallback toggle) =>
        FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
  );
}
// #enddocregion components-menu-menu--aligning-with-selectable-items

// #docregion components-menu-menu--secondary-content-for-menu-items
// Upstream's `secondaryContent` is the trailing shortcut, which is
// `FluentMenuItem.trailing` here. Its `subText` — the second line under the
// label — is `FluentMenuItem.secondary`; see 'Multiline Items'.
Widget _secondaryContentForMenuItems(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(
      label: const Text('New File'),
      trailing: const Text('Ctrl+N'),
      onPressed: () {},
    ),
    FluentMenuItem(
      label: const Text('New Window'),
      trailing: const Text('Ctrl+Shift+N'),
      onPressed: () {},
    ),
    const FluentMenuItem(
      label: Text('New Tab'),
      trailing: Text('Ctrl+T'),
      enabled: false,
    ),
    FluentMenuItem(
      label: const Text('Open File'),
      trailing: const Text('Ctrl+O'),
      onPressed: () {},
    ),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
);
// #enddocregion components-menu-menu--secondary-content-for-menu-items

// #docregion components-menu-menu--multiline-items
Widget _multilineItems(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(
      icon: const Icon(FluentIcons.cut_20_regular),
      label: const Text('Cut'),
      secondary: const Text('Cut to clipboard'),
      onPressed: () {},
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.clipboard_paste_20_regular),
      label: const Text('Paste'),
      secondary: const Text('Paste from clipboard'),
      onPressed: () {},
    ),
    const FluentMenuItem(
      icon: Icon(FluentIcons.edit_20_regular),
      label: Text('Edit'),
      secondary: Text('Edit file'),
      enabled: false,
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.delete_20_regular),
      label: const Text('Delete'),
      secondary: const Text('Delete file'),
      onPressed: () {},
    ),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Multiline items')),
);
// #enddocregion components-menu-menu--multiline-items

// #docregion components-menu-menu--controlling-open-and-close
// `FluentMenu` is uncontrolled: it owns its open state and hands the trigger a
// `toggle` callback instead of taking an `open` bool. So the checkbox holds the
// state it *asks* for and calls the same `toggle` the button does. Dismissing
// the menu by clicking outside closes it without telling the checkbox — that is
// the part an `onOpenChange` would carry and we have no hook for.
Widget _controllingOpenAndClose(BuildContext context) =>
    const _ControllingOpenAndClose();

class _ControllingOpenAndClose extends StatefulWidget {
  const _ControllingOpenAndClose();

  @override
  State<_ControllingOpenAndClose> createState() =>
      _ControllingOpenAndCloseState();
}

class _ControllingOpenAndCloseState extends State<_ControllingOpenAndClose> {
  bool _open = false;
  VoidCallback? _toggle;

  void _setOpen(bool next) {
    if (next == _open) return;
    setState(() => _open = next);
    _toggle?.call();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentCheckbox(
        label: const Text('Open'),
        checked: _open,
        onChanged: (bool? checked) => _setOpen(checked ?? false),
      ),
      const SizedBox(height: 12),
      FluentMenu(
        items: <FluentMenuItem>[
          FluentMenuItem(label: const Text('New '), onPressed: () {}),
          FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
          const FluentMenuItem(label: Text('Open File'), enabled: false),
          FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
        ],
        builder: (BuildContext context, VoidCallback toggle) {
          _toggle = toggle;
          return FluentButton(
            onPressed: () => _setOpen(!_open),
            child: const Text('Toggle menu'),
          );
        },
      ),
    ],
  );
}
// #enddocregion components-menu-menu--controlling-open-and-close

// #docregion components-menu-menu--grouping-items
// `MenuGroup` + `MenuGroupHeader` is `FluentMenuItem.header` here: the header is
// a row of the same flat list, and the menu skips it in keyboard navigation the
// way the upstream markup does.
Widget _groupingItems(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    const FluentMenuItem.header(label: Text('Section header')),
    FluentMenuItem(
      icon: const Icon(FluentIcons.cut_20_regular),
      label: const Text('Cut'),
      onPressed: () {},
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.clipboard_paste_20_regular),
      label: const Text('Paste'),
      onPressed: () {},
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.edit_20_regular),
      label: const Text('Edit'),
      onPressed: () {},
    ),
    const FluentMenuItem.divider(),
    const FluentMenuItem.header(label: Text('Section header')),
    FluentMenuItem(
      icon: const Icon(FluentIcons.cut_20_regular),
      label: const Text('Cut'),
      onPressed: () {},
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.clipboard_paste_20_regular),
      label: const Text('Paste'),
      onPressed: () {},
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.edit_20_regular),
      label: const Text('Edit'),
      onPressed: () {},
    ),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
);
// #enddocregion components-menu-menu--grouping-items

// #docregion components-menu-menu--visual-divider-only
Widget _visualDividerOnly(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(
      icon: const Icon(FluentIcons.cut_20_regular),
      label: const Text('Cut'),
      onPressed: () {},
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.clipboard_paste_20_regular),
      label: const Text('Paste'),
      onPressed: () {},
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.edit_20_regular),
      label: const Text('Edit'),
      onPressed: () {},
    ),
    const FluentMenuItem.divider(),
    FluentMenuItem(
      icon: const Icon(FluentIcons.cut_20_regular),
      label: const Text('Cut'),
      onPressed: () {},
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.clipboard_paste_20_regular),
      label: const Text('Paste'),
      onPressed: () {},
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.edit_20_regular),
      label: const Text('Edit'),
      onPressed: () {},
    ),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
);
// #enddocregion components-menu-menu--visual-divider-only

// #docregion components-menu-menu--checkbox-items
// There is no `MenuItemCheckbox` widget: a `FluentMenuItem` has a `checked`
// flag and an `onPressed`, so checkbox behaviour is the caller's `Set`. The
// checkmark shares the leading slot with the icon — Fluent paints one or the
// other, never both — so a checked row shows the tick in place of its glyph.
Widget _checkboxItems(BuildContext context) => const _CheckboxItems();

class _CheckboxItems extends StatefulWidget {
  const _CheckboxItems();

  @override
  State<_CheckboxItems> createState() => _CheckboxItemsState();
}

class _CheckboxItemsState extends State<_CheckboxItems> {
  final Set<String> _checked = <String>{};

  void _toggleValue(String value) => setState(() {
    if (!_checked.remove(value)) _checked.add(value);
  });

  @override
  Widget build(BuildContext context) => FluentMenu(
    items: <FluentMenuItem>[
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Cut'),
        checked: _checked.contains('cut'),
        onPressed: () => _toggleValue('cut'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.clipboard_paste_20_regular),
        label: const Text('Paste'),
        checked: _checked.contains('paste'),
        onPressed: () => _toggleValue('paste'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.edit_20_regular),
        label: const Text('Edit'),
        checked: _checked.contains('edit'),
        onPressed: () => _toggleValue('edit'),
      ),
    ],
    builder: (BuildContext context, VoidCallback toggle) =>
        FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
  );
}
// #enddocregion components-menu-menu--checkbox-items

// #docregion components-menu-menu--switch-item
// There is no `MenuItemSwitch`. The nearest thing is a row whose trailing slot
// holds a real `FluentSwitch` for the switch design, with the row itself
// carrying the interaction — the switch is deliberately inert, because upstream
// tells you not to put a focusable control inside a menu item.
Widget _switchItem(BuildContext context) => const _SwitchItem();

class _SwitchItem extends StatefulWidget {
  const _SwitchItem();

  @override
  State<_SwitchItem> createState() => _SwitchItemState();
}

class _SwitchItemState extends State<_SwitchItem> {
  final Set<String> _checked = <String>{};

  @override
  Widget build(BuildContext context) => FluentMenu(
    items: <FluentMenuItem>[
      FluentMenuItem(label: const Text('New'), onPressed: () {}),
      FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
      const FluentMenuItem(label: Text('Open File'), enabled: false),
      FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
      FluentMenuItem(
        label: const Text('Try V2'),
        trailing: ExcludeFocus(
          child: IgnorePointer(
            child: FluentSwitch(
              checked: _checked.contains('new-explorer'),
              onChanged: (bool _) {},
            ),
          ),
        ),
        onPressed: () => setState(() {
          if (!_checked.remove('new-explorer')) _checked.add('new-explorer');
        }),
      ),
    ],
    builder: (BuildContext context, VoidCallback toggle) =>
        FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
  );
}
// #enddocregion components-menu-menu--switch-item

// #docregion components-menu-menu--radio-items
// There is no `MenuItemRadio` either — radio behaviour is one nullable value in
// the caller's state instead of a `Set`, and the same `checked` flag paints it.
Widget _radioItems(BuildContext context) => const _RadioItems();

class _RadioItems extends StatefulWidget {
  const _RadioItems();

  @override
  State<_RadioItems> createState() => _RadioItemsState();
}

class _RadioItemsState extends State<_RadioItems> {
  String? _font;

  @override
  Widget build(BuildContext context) => FluentMenu(
    items: <FluentMenuItem>[
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Segoe'),
        checked: _font == 'segoe',
        onPressed: () => setState(() => _font = 'segoe'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.clipboard_paste_20_regular),
        label: const Text('Calibri'),
        checked: _font == 'calibri',
        onPressed: () => setState(() => _font = 'calibri'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.edit_20_regular),
        label: const Text('Arial'),
        checked: _font == 'arial',
        onPressed: () => setState(() => _font = 'arial'),
      ),
    ],
    builder: (BuildContext context, VoidCallback toggle) =>
        FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
  );
}
// #enddocregion components-menu-menu--radio-items

// #docregion components-menu-menu--controlled-checkbox-items
// Upstream's `checkedValues` / `onCheckedValueChange` pair is what every
// selectable `FluentMenu` already does: the caller owns the set, so "controlled"
// is the only mode there is. This one just starts with two rows ticked.
Widget _controlledCheckboxItems(BuildContext context) =>
    const _ControlledCheckboxItems();

class _ControlledCheckboxItems extends StatefulWidget {
  const _ControlledCheckboxItems();

  @override
  State<_ControlledCheckboxItems> createState() =>
      _ControlledCheckboxItemsState();
}

class _ControlledCheckboxItemsState extends State<_ControlledCheckboxItems> {
  final Set<String> _checked = <String>{'cut', 'paste'};

  void _toggleValue(String value) => setState(() {
    if (!_checked.remove(value)) _checked.add(value);
  });

  @override
  Widget build(BuildContext context) => FluentMenu(
    items: <FluentMenuItem>[
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Cut'),
        checked: _checked.contains('cut'),
        onPressed: () => _toggleValue('cut'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.clipboard_paste_20_regular),
        label: const Text('Paste'),
        checked: _checked.contains('paste'),
        onPressed: () => _toggleValue('paste'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.edit_20_regular),
        label: const Text('Edit'),
        checked: _checked.contains('edit'),
        onPressed: () => _toggleValue('edit'),
      ),
    ],
    builder: (BuildContext context, VoidCallback toggle) =>
        FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
  );
}
// #enddocregion components-menu-menu--controlled-checkbox-items

// #docregion components-menu-menu--controlled-radio-items
// As with the checkbox variant, the caller already owns the value — this one
// starts on 'calibri'.
Widget _controlledRadioItems(BuildContext context) =>
    const _ControlledRadioItems();

class _ControlledRadioItems extends StatefulWidget {
  const _ControlledRadioItems();

  @override
  State<_ControlledRadioItems> createState() => _ControlledRadioItemsState();
}

class _ControlledRadioItemsState extends State<_ControlledRadioItems> {
  String _font = 'calibri';

  @override
  Widget build(BuildContext context) => FluentMenu(
    items: <FluentMenuItem>[
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Segoe'),
        checked: _font == 'segoe',
        onPressed: () => setState(() => _font = 'segoe'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.clipboard_paste_20_regular),
        label: const Text('Calibri'),
        checked: _font == 'calibri',
        onPressed: () => setState(() => _font = 'calibri'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.edit_20_regular),
        label: const Text('Arial'),
        checked: _font == 'arial',
        onPressed: () => setState(() => _font = 'arial'),
      ),
    ],
    builder: (BuildContext context, VoidCallback toggle) =>
        FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
  );
}
// #enddocregion components-menu-menu--controlled-radio-items

// #docregion components-menu-menu--selection-group
// Two selection areas in one surface, separated by a header and a divider —
// `FluentMenuItem.header` and `FluentMenuItem.divider` standing in for
// `MenuGroup` / `MenuGroupHeader` / `MenuDivider`.
Widget _selectionGroup(BuildContext context) => const _SelectionGroup();

class _SelectionGroup extends StatefulWidget {
  const _SelectionGroup();

  @override
  State<_SelectionGroup> createState() => _SelectionGroupState();
}

class _SelectionGroupState extends State<_SelectionGroup> {
  final Set<String> _checked = <String>{};
  String? _font;

  void _toggleValue(String value) => setState(() {
    if (!_checked.remove(value)) _checked.add(value);
  });

  @override
  Widget build(BuildContext context) => FluentMenu(
    items: <FluentMenuItem>[
      const FluentMenuItem.header(label: Text('Checkbox group')),
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Show Menu Bar'),
        trailing: const Text('Ctrl+N'),
        checked: _checked.contains('cut'),
        onPressed: () => _toggleValue('cut'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.clipboard_paste_20_regular),
        label: const Text('Show Side Bar'),
        trailing: const Text('Ctrl+Shift+N'),
        checked: _checked.contains('paste'),
        onPressed: () => _toggleValue('paste'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.edit_20_regular),
        label: const Text('Show Status Bar'),
        trailing: const Text('Ctrl+Shift+O'),
        checked: _checked.contains('edit'),
        onPressed: () => _toggleValue('edit'),
      ),
      // Upstream parks this row in its own `disabled` group, which is its way
      // of saying a greyed checkbox can never join the `edit` selection.
      const FluentMenuItem(
        icon: Icon(FluentIcons.edit_20_regular),
        label: Text('Show Debug Panel'),
        enabled: false,
      ),
      const FluentMenuItem.divider(),
      const FluentMenuItem.header(label: Text('Radio group')),
      FluentMenuItem(
        icon: const Icon(FluentIcons.cut_20_regular),
        label: const Text('Segoe'),
        trailing: const Text('Ctrl+N'),
        checked: _font == 'segoe',
        onPressed: () => setState(() => _font = 'segoe'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.clipboard_paste_20_regular),
        label: const Text('Caliri'),
        trailing: const Text('Ctrl+Shift+N'),
        checked: _font == 'calibri',
        onPressed: () => setState(() => _font = 'calibri'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.edit_20_regular),
        label: const Text('Arial'),
        trailing: const Text('Ctrl+Shift+N'),
        checked: _font == 'arial',
        onPressed: () => setState(() => _font = 'arial'),
      ),
    ],
    builder: (BuildContext context, VoidCallback toggle) =>
        FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
  );
}
// #enddocregion components-menu-menu--selection-group

// #docregion components-menu-menu--nested-submenus
// Upstream nests a whole `Menu` inside a `MenuItem` and pulls each level out
// into its own component. A `FluentMenuItem` carries its own `submenu` list, so
// the nesting is data — the three lists below are upstream's three components.
Widget _nestedSubmenus(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('New '), onPressed: () {}),
    FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
    const FluentMenuItem(label: Text('Open File'), enabled: false),
    FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
    FluentMenuItem(
      label: const Text('Preferences'),
      submenu: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Settings'), onPressed: () {}),
        FluentMenuItem(
          label: const Text('Online Services Settings'),
          onPressed: () {},
        ),
        FluentMenuItem(label: const Text('Extensions'), onPressed: () {}),
        FluentMenuItem(
          label: const Text('Appearance'),
          submenu: <FluentMenuItem>[
            FluentMenuItem(
              label: const Text('Centered Layout'),
              onPressed: () {},
            ),
            FluentMenuItem(label: const Text('Zen'), onPressed: () {}),
            const FluentMenuItem(label: Text('Zoom In'), enabled: false),
            FluentMenuItem(label: const Text('Zoom Out'), onPressed: () {}),
          ],
        ),
        FluentMenuItem(
          label: const Text('Editor Layout'),
          submenu: <FluentMenuItem>[
            FluentMenuItem(label: const Text('Split Up'), onPressed: () {}),
            FluentMenuItem(label: const Text('Split Down'), onPressed: () {}),
            FluentMenuItem(label: const Text('Single'), onPressed: () {}),
          ],
        ),
      ],
    ),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
);
// #enddocregion components-menu-menu--nested-submenus

// #docregion components-menu-menu--nested-submenus-controlled
// Upstream gives each nested level its own `open` / `onOpenChange` pair.
// `FluentMenu` owns the whole submenu chain itself — there is no per-level
// `open` to hand it — so this renders exactly as the uncontrolled version
// above, which is upstream's point: the controlled variant is meant to behave
// identically.
Widget _nestedSubmenusControlled(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('New '), onPressed: () {}),
    FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
    const FluentMenuItem(label: Text('Open File'), enabled: false),
    FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
    FluentMenuItem(
      label: const Text('Preferences'),
      submenu: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Settings'), onPressed: () {}),
        FluentMenuItem(
          label: const Text('Online Services Settings'),
          onPressed: () {},
        ),
        FluentMenuItem(label: const Text('Extensions'), onPressed: () {}),
        FluentMenuItem(
          label: const Text('Appearance'),
          submenu: <FluentMenuItem>[
            FluentMenuItem(
              label: const Text('Centered Layout'),
              onPressed: () {},
            ),
            FluentMenuItem(label: const Text('Zen'), onPressed: () {}),
            const FluentMenuItem(label: Text('Zoom In'), enabled: false),
            FluentMenuItem(label: const Text('Zoom Out'), onPressed: () {}),
          ],
        ),
        FluentMenuItem(
          label: const Text('Editor Layout'),
          submenu: <FluentMenuItem>[
            FluentMenuItem(label: const Text('Split Up'), onPressed: () {}),
            FluentMenuItem(label: const Text('Split Down'), onPressed: () {}),
            FluentMenuItem(label: const Text('Single'), onPressed: () {}),
          ],
        ),
      ],
    ),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
);
// #enddocregion components-menu-menu--nested-submenus-controlled

// #docregion components-menu-menu--nested-submenus-responsiveness
// Upstream's CSS `resize: both` handle becomes a drag grip in the corner, and
// its `overflowBoundary` / `flipBoundary` have no counterpart: `FluentMenu`
// flips and shifts against the window rather than an arbitrary element, so
// shrinking the box below repositions the menus only once it starts crowding
// the viewport.
Widget _nestedSubmenusResponsiveness(BuildContext context) =>
    const _NestedSubmenusResponsiveness();

class _NestedSubmenusResponsiveness extends StatefulWidget {
  const _NestedSubmenusResponsiveness();

  @override
  State<_NestedSubmenusResponsiveness> createState() =>
      _NestedSubmenusResponsivenessState();
}

class _NestedSubmenusResponsivenessState
    extends State<_NestedSubmenusResponsiveness> {
  double _width = 500;
  double _height = 400;

  @override
  Widget build(BuildContext context) {
    final FluentColors colors = FluentTheme.of(context).colors;
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.brandBackground, width: 2),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: ColoredBox(
              color: colors.brandBackground,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 1, 4, 1),
                child: Text(
                  'Resizable Area',
                  style: TextStyle(
                    color: colors.neutralForegroundOnBrand,
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: _width * 0.4,
            child: FluentMenu(
              items: <FluentMenuItem>[
                FluentMenuItem(label: const Text('New '), onPressed: () {}),
                FluentMenuItem(
                  label: const Text('New Window'),
                  onPressed: () {},
                ),
                const FluentMenuItem(label: Text('Open File'), enabled: false),
                FluentMenuItem(
                  label: const Text('Open Folder'),
                  onPressed: () {},
                ),
                FluentMenuItem(
                  label: const Text('Toggle menu'),
                  submenu: <FluentMenuItem>[
                    FluentMenuItem(label: const Text('New '), onPressed: () {}),
                    FluentMenuItem(
                      label: const Text('New Window'),
                      onPressed: () {},
                    ),
                    const FluentMenuItem(
                      label: Text('Open File'),
                      enabled: false,
                    ),
                    FluentMenuItem(
                      label: const Text('Open Folder'),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
              builder: (BuildContext context, VoidCallback toggle) =>
                  FluentButton(onPressed: toggle, child: const Text('Menu')),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeDownRight,
              child: GestureDetector(
                onPanUpdate: (DragUpdateDetails details) => setState(() {
                  _width = (_width + details.delta.dx).clamp(240, 900);
                  _height = (_height + details.delta.dy).clamp(200, 700);
                }),
                child: ColoredBox(
                  color: colors.brandBackground,
                  child: const SizedBox.square(dimension: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// #enddocregion components-menu-menu--nested-submenus-responsiveness

// #docregion components-menu-menu--anchor-to-custom-target
// `FluentMenu` always anchors to the widget its `builder` returns, so the
// upstream split — a button that opens the menu, and a *different* element the
// surface hangs off — becomes: the menu's builder renders 'Custom target', and
// 'Open menu' calls the same `toggle` from outside.
Widget _anchorToCustomTarget(BuildContext context) =>
    const _AnchorToCustomTarget();

class _AnchorToCustomTarget extends StatefulWidget {
  const _AnchorToCustomTarget();

  @override
  State<_AnchorToCustomTarget> createState() => _AnchorToCustomTargetState();
}

class _AnchorToCustomTargetState extends State<_AnchorToCustomTarget> {
  VoidCallback? _toggle;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: <Widget>[
      FluentButton(
        onPressed: () => _toggle?.call(),
        child: const Text('Open menu'),
      ),
      FluentMenu(
        items: <FluentMenuItem>[
          FluentMenuItem(label: const Text('New '), onPressed: () {}),
          FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
          const FluentMenuItem(label: Text('Open File'), enabled: false),
          FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
        ],
        builder: (BuildContext context, VoidCallback toggle) {
          _toggle = toggle;
          return FluentButton(
            onPressed: toggle,
            child: const Text('Custom target'),
          );
        },
      ),
    ],
  );
}
// #enddocregion components-menu-menu--anchor-to-custom-target

// #docregion components-menu-menu--custom-trigger
// Ref forwarding has no counterpart: `builder` hands `toggle` straight to
// whatever widget it returns, so a custom trigger is an ordinary widget that
// takes a `VoidCallback`.
Widget _customTrigger(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('New '), onPressed: () {}),
    FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
    const FluentMenuItem(label: Text('Open File'), enabled: false),
    FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      _CustomMenuTrigger(onPressed: toggle),
);

class _CustomMenuTrigger extends StatelessWidget {
  const _CustomMenuTrigger({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      FluentButton(onPressed: onPressed, child: const Text('Custom Trigger'));
}
// #enddocregion components-menu-menu--custom-trigger

// #docregion components-menu-menu--render-function-trigger
// `builder` *is* upstream's render-function trigger: it returns a whole
// subtree, and only the part that calls `toggle` opens the menu. The menu still
// anchors to everything the builder returned, which is the row below.
Widget _renderFunctionTrigger(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('New '), onPressed: () {}),
    FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
    const FluentMenuItem(label: Text('Open File'), enabled: false),
    FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
  ],
  builder: (BuildContext context, VoidCallback toggle) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentButton(
        size: FluentButtonSize.small,
        onPressed: () {},
        child: const Text('Custom Trigger'),
      ),
      FluentButton.icon(
        size: FluentButtonSize.small,
        semanticLabel: 'Custom Trigger',
        icon: const Icon(FluentIcons.chevron_down_20_regular, size: 16),
        onPressed: toggle,
      ),
    ],
  ),
);
// #enddocregion components-menu-menu--render-function-trigger

// #docregion components-menu-menu--memoized-menu-items
// `React.memo` has no counterpart, and needs none: a `FluentMenuItem` is an
// immutable description rather than a widget, so a selection change rebuilds
// the list but repaints only the rows whose description actually differs. The
// helper below stands in for upstream's `MemoCheckbox`.
Widget _memoizedMenuItems(BuildContext context) => const _MemoizedMenuItems();

class _MemoizedMenuItems extends StatefulWidget {
  const _MemoizedMenuItems();

  @override
  State<_MemoizedMenuItems> createState() => _MemoizedMenuItemsState();
}

class _MemoizedMenuItemsState extends State<_MemoizedMenuItems> {
  // Upstream's `MemoCheckbox` rows all share `name="font"`.
  final Set<String> _font = <String>{};

  FluentMenuItem _checkbox(String value, String label) => FluentMenuItem(
    icon: const Icon(FluentIcons.edit_20_regular),
    label: Text(label),
    checked: _font.contains(value),
    onPressed: () => setState(() {
      if (!_font.remove(value)) _font.add(value);
    }),
  );

  @override
  Widget build(BuildContext context) => FluentMenu(
    items: <FluentMenuItem>[
      _checkbox('segoe', 'Segoe'),
      _checkbox('calibri', 'Calibri'),
      _checkbox('arial', 'Arial'),
    ],
    builder: (BuildContext context, VoidCallback toggle) =>
        FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
  );
}
// #enddocregion components-menu-menu--memoized-menu-items

// #docregion components-menu-menu--split-menu-item
// `MenuSplitGroup` has no counterpart: a `FluentMenuItem` with a `submenu`
// opens that submenu and ignores its own `onPressed`, so 'Open' cannot be both
// a main action and a submenu trigger. The submenu wins, since that is the half
// the section is about — upstream's separate trigger would carry the
// 'Open on platform' label for screen readers.
Widget _splitMenuItem(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('New '), onPressed: () {}),
    FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
    FluentMenuItem(
      label: const Text('Open'),
      submenu: <FluentMenuItem>[
        FluentMenuItem(label: const Text('In browser'), onPressed: () {}),
        FluentMenuItem(label: const Text('In desktop app'), onPressed: () {}),
        FluentMenuItem(label: const Text('In mobile'), onPressed: () {}),
      ],
    ),
    FluentMenuItem(label: const Text('Preferences'), onPressed: () {}),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
);
// #enddocregion components-menu-menu--split-menu-item

// #docregion components-menu-menu--menu-trigger-with-tooltip
Widget _menuTriggerWithTooltip(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('New '), onPressed: () {}),
    FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
    const FluentMenuItem(label: Text('Open File'), enabled: false),
    FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
  ],
  builder: (BuildContext context, VoidCallback toggle) => FluentTooltip(
    content: const Text('This is a tooltip'),
    semanticLabel: 'This is a tooltip',
    child: FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
  ),
);
// #enddocregion components-menu-menu--menu-trigger-with-tooltip

// #docregion components-menu-menu--motion-custom
// `FluentMenu` has no `surfaceMotion` slot to swap. Its surface always arrives
// on `fluentMenuSurfaceEnter` — the same fade-and-slide pair upstream builds
// `MenuSurfaceMotion` out of — so this renders the default motion and the
// section keeps its place.
Widget _motionCustom(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('New'), onPressed: () {}),
    FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
    const FluentMenuItem(label: Text('Open File'), enabled: false),
    FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
);
// #enddocregion components-menu-menu--motion-custom

// #docregion components-menu-menu--motion-disabled
// There is no per-menu `surfaceMotion: null` either. The switch that does exist
// is the platform one: the surface builds inside the app's `Overlay`, and
// `MediaQuery.disableAnimationsOf` there clamps the entrance to zero — so
// turning off animations in the OS disables this menu's transition, and nothing
// on the call site does.
Widget _motionDisabled(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('New'), onPressed: () {}),
    FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
    const FluentMenuItem(label: Text('Open File'), enabled: false),
    FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
  ],
  builder: (BuildContext context, VoidCallback toggle) =>
      FluentButton(onPressed: toggle, child: const Text('Toggle menu')),
);
// #enddocregion components-menu-menu--motion-disabled
