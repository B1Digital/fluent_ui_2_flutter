import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Tree docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage treePage = DocsPage(
  id: 'components-tree',
  title: 'Tree',
  description:
      'A hierarchical list structure component for displaying data in a '
      'collapsible and expandable way. Use this component when you need to '
      'present your users with a clear visual structure of content or data, '
      'allowing them to efficiently interact and navigate through the '
      'information. If the information is less hierarchical or node-based, '
      'consider using a list or table instead.',
  source: 'lib/pages/components_tree.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-tree--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-tree--size',
      title: 'Size',
      description:
          'A tree can be displayed in a small or medium (default) size.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-tree--appearance',
      title: 'Appearance',
      description:
          'A tree can have the following appearance variants: subtle: the '
          'default appearance. subtle-alpha: minimizes emphasis on hovered or '
          'focused states. transparent: no background color. Both '
          'TreeItemLayout and TreeItemPersonaLayout will respond to the '
          'appearance variants.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-tree--layouts',
      title: 'Layouts',
      description:
          'Tree items support two layout components: TreeItemLayout and '
          'TreeItemPersonaLayout. Both of these layouts come with specific '
          'sets of properties, making them suitable for different use cases. '
          'Please refer to the table at the top of this page for a detailed '
          'comparison of the properties available for both TreeItemLayout and '
          'TreeItemPersonaLayout. Notably, some properties like iconBefore, '
          'iconAfter, media, and description are unique to one layout or the '
          'other, enabling more specialized customization depending on your '
          'needs.',
      builder: _layouts,
    ),
    DocsSection(
      id: 'components-tree--expand-icon',
      title: 'Expand Icon',
      description:
          'Both tree item layouts can have a custom expand/collapse icon.',
      builder: _expandIcon,
    ),
    DocsSection(
      id: 'components-tree--icon-before-and-after',
      title: 'Icon Before And After',
      description:
          'TreeItemLayout component allows you to add icons before or after '
          'the content.',
      builder: _iconBeforeAndAfter,
    ),
    DocsSection(
      id: 'components-tree--aside',
      title: 'Aside',
      description:
          'Both tree item layouts supports aside content that is displayed on '
          'the right side of a tree item. It can be used to display additional '
          'information, such as a badge with notification count or an icon '
          'indicating importance.',
      builder: _aside,
    ),
    DocsSection(
      id: 'components-tree--actions',
      title: 'Actions',
      description:
          'In addition to aside slot, both tree item layouts support actions '
          'slot that can be used for tasks such as edit, rename, or triggering '
          'a menu. actions and aside slots are positioned on the exact same '
          "spot, so they won't be visible at the same time. aside slot is "
          'visible by default meanwhile actions slot are only visible when the '
          'tree item is active (by hovering or by navigating to it). actions '
          'slot supports a visible prop to force visibility of the actions. '
          'The actions slot has a role="toolbar" and ensures proper horizontal '
          'navigation with the keyboard by using useArrowNavigationGroup. '
          "Although actions are easy to navigate, they're not an expected "
          'pattern according to WAI-ARIA. providing a context menu with the '
          'same functionalities as the actions is recommended to ensure your '
          'tree item is accessible. In the example below, we compose on top of '
          'TreeItem component to include both a context menu and actions that '
          'provide the same amount of functionalities. We also provide an '
          'aria-description to the tree item to indicate that it has actions. '
          'This is a new behavior that the user might not be aware of, so you '
          'might need to explain somewhere else in the UI what does having '
          "actions refers to. Don't forget to add a proper description to "
          'TreeItem to ensure screen readers have enough information to '
          'understand the context. Actions are still experimental and user '
          'experience might change in the future.',
      builder: _actions,
    ),
    DocsSection(
      id: 'components-tree--navigation-mode-tree-grid',
      title: 'Navigation Mode Tree Grid',
      description:
          'If navigationMode is set to treegrid, the navigation pattern '
          'changes to allow navigation between tree items and their actions. '
          "1. If the treeitem is a branch and it's not expanded, pressing "
          'right arrow key will expand the treeitem. 2. If the treeitem is a '
          "branch and it's expanded, pressing right arrow key will navigate "
          'towards the actions of the treeitem. 3. If focused in the actions, '
          'pressing left arrow key will navigate back to the treeitem.',
      builder: _navigationModeTreeGrid,
    ),
    DocsSection(
      id: 'components-tree--default-open',
      title: 'Default Open',
      description:
          'Use the defaultOpenItems prop in the Tree component to set the '
          'default open or closed state for expandable tree item components. '
          'It takes an iterable (like an array or a set) of open IDs, opening '
          'only the TreeItem components with those IDs on initial render, '
          'while all others are closed.',
      builder: _defaultOpen,
    ),
    DocsSection(
      id: 'components-tree--open-items-controlled',
      title: 'Open Items Controlled',
      description:
          'You can also control the open/closed state of TreeItem components '
          "with the Tree component's openItems prop and onOpenChange callback. "
          'openItems takes an iterable (like an array or a set) of open IDs, '
          'and onOpenChange updates it as items are opened or closed.',
      builder: _openItemsControlled,
    ),
    DocsSection(
      id: 'components-tree--open-item-controlled',
      title: 'Open Item Controlled',
      description:
          'You can also control the open/closed state of a single TreeItem '
          'component directly. This will override the internal value of '
          'openItems in favor of the open property. Note: It\'s not '
          'recommended to use both openItems and open at the same time, as '
          'this can lead to unexpected behavior! Stick to one or the other.',
      builder: _openItemControlled,
    ),
    DocsSection(
      id: 'components-tree--customizing-interaction',
      title: 'Customizing Interaction',
      description:
          'By default, every expandable TreeItem responds to clicks on both '
          'content and the expand/collapse icon. To handle these separately, '
          'listen for the onOpenChange event in the Tree component. You can '
          'check the event type to determine whether the content or the icon '
          'was clicked, allowing you to override the default behavior.',
      builder: _customizingInteraction,
    ),
    DocsSection(
      id: 'components-tree--inline-styling-tree-item-level',
      title: 'Inline Styling Tree Item Level',
      description:
          'The tree component generates static styles for the first 10 nesting '
          'levels (for performance reasons) and automatically falls back to an '
          'inline CSS variable for deeper levels, so arbitrarily deep trees '
          'indent correctly out of the box. Below is an example of how to '
          'apply custom inline styles to create dynamic tree item levels, '
          'overriding the default static styles.',
      builder: _inlineStylingTreeItemLevel,
    ),
    DocsSection(
      id: 'components-tree--flat-tree',
      title: 'Flat Tree',
      description:
          'The FlatTree component is a simplified version of Tree. It enables '
          'a more efficient and flexible way to manage tree structures by '
          'representing them in a flattened format. Unlike nested trees, flat '
          'trees simplify many common tasks such as searching or '
          'adding/removing items, and they are essential for supporting '
          'features like virtualization. To ensure a FlatTree works '
          'accordingly a few more properties should be provided for each '
          'TreeItem: aria-posinset: the position of the treeitem in the '
          'current level of the tree. aria-setsize: the number of siblings in '
          'a level of the tree. aria-level: the current level of the treeitem. '
          'parentValue: the value property of the parent item of the current '
          'item. FlatTreeItem component is available to ensure those '
          "properties are properly provided (it's equivalent to TreeItem but "
          'with those properties listed above as required). Another limitation '
          "of the FlatTree is that it becomes the user's responsibility to "
          'ensure proper open items are visible, Since in a flat structure '
          "there's no proper way to assume if an item is visible or not by "
          'context. Take a look at the useHeadlessFlatTree hook to delegate '
          'the responsibility of filtering visible items and also to ensure '
          'proper properties are added to each TreeItem. If you need to '
          'utilize a nested tree with FlatTree, simply convert it to the flat '
          'format using the flattenTree helper.',
      builder: _flatTree,
    ),
    DocsSection(
      id: 'components-tree--use-headless-flat-tree',
      title: 'Use Headless Flat Tree',
      description:
          'The useHeadlessFlatTree hook provides all the properties and all '
          "the methods required to ensure a proper functioning of a flat tree. "
          "It's arguments are: 1. a list of items to be mapped into TreeItem "
          '2. an object with options that allows to control open and checked '
          'state openItems, defaultOpenItems and onOpenChange (controlling '
          'open state) checkedItems, defaultCheckedItems and onCheckedChange '
          '(controlling checked state)',
      builder: _useHeadlessFlatTree,
    ),
    DocsSection(
      id: 'components-tree--selection',
      title: 'Selection',
      description:
          'The tree component offers selectable functionality in both single '
          'and multi-selection modes. You can enable this feature by passing '
          'the selectionMode prop with either single or multiselect value. '
          'Tree: In nested tree, you are responsible for controlling the '
          'selection state, as it would be difficult to manage the state in an '
          'uncontrolled manner without knowing the items upfront. FlatTree: In '
          'flat tree, you can take advantage of an uncontrolled state for '
          'easier management, as the items are known upfront. It is also '
          'possible to use a controlled state if you need to manage the '
          'selection state externally. The selection process works similarly '
          'to how open/close state works. Use the defaultCheckedItems prop for '
          'default selections and the checkedItems prop and onCheckedChange '
          'callback to control the selected items.',
      builder: _selection,
    ),
    DocsSection(
      id: 'components-tree--manipulation',
      title: 'Manipulation',
      description:
          'With a flat tree structure, you can easily manipulate the tree and '
          'control its state. In the example below, you can add or remove tree '
          'items by working with the parentValue property, which ensures the '
          'correct parent-child relationships within the tree When '
          'manipulating tree items, ensure that continuity of keyboard '
          'navigation is preserved and prevent unexpected focus loss. This '
          'example demonstrates a method for maintaining user focus throughout '
          'interactions.',
      builder: _manipulation,
    ),
    DocsSection(
      id: 'components-tree--lazy-loading',
      title: 'Lazy Loading',
      description:
          'This example shows lazy loading in a flat tree, where data is '
          'loaded on-demand to optimize rendering time and performance. Items '
          'are dynamically loaded when necessary.',
      builder: _lazyLoading,
    ),
    DocsSection(
      id: 'components-tree--infinite-scrolling',
      title: 'Infinite Scrolling',
      description:
          'This example takes the previous lazy loading concept a step further '
          'by adding infinite scrolling. As the user navigates through the '
          'tree, additional items are loaded incrementally, enhancing the '
          'responsiveness and scalability of the tree.',
      builder: _infiniteScrolling,
    ),
    DocsSection(
      id: 'components-tree--virtualization',
      title: 'Virtualization',
      description:
          "A tree does not support virtualization by default. To enable it, "
          "you'll need to adopt a custom third-party virtualization library. "
          'By utilizing virtualization, the tree only renders the nodes that '
          'are currently visible on the screen. This significantly reduces the '
          'number of DOM nodes, leading to quicker interaction times for large '
          'trees. In this example of a flat tree with react-window for '
          'virtualization, two main adjustments are necessary: 1. Tree '
          'component must be recomposed using composition API to use '
          'FixedSizeList to wrap root content. 2. Navigation will break as '
          "some nodes will not be available on the DOM (since they'll be "
          'virtualized), to fix this we\'ll need to provide a custom '
          'navigation handler that will scroll to the correct node before '
          'calling the default handler.',
      builder: _virtualization,
    ),
    DocsSection(
      id: 'components-tree--drag-and-drop',
      title: 'Drag And Drop',
      description:
          'The tree component does not offer built-in drag-and-drop '
          "functionality. Yet, it's been designed with adaptability in mind, "
          'allowing for easy integration with third-party libraries to fulfill '
          'this need. In this example, the tree component is integrated with '
          'dnd-kit to enable drag-and-drop behavior within the tree. A few key '
          'steps are involved to achieve this: DndContext and SortableContext '
          'from dnd-kit set up the necessary environment for drag-and-drop '
          'throughout the tree. Following that, SortableTreeItem is a '
          'component that wraps TreeItem, leveraging the useSortable hook to '
          'add drag-and-drop capabilities. Lastly, the handleDragEnd function '
          'ensures items are rearranged correctly after dragging. By adopting '
          'this approach, users can easily drag and drop tree items, '
          'rearranging them as desired. The dnd-kit also supports '
          "virtualization. For an in-depth look and further customization "
          "options, check the dnd-kit's documentation.",
      builder: _dragAndDrop,
    ),
    DocsSection(
      id: 'components-tree--motion-custom',
      title: 'Motion Custom',
      description:
          "Tree's collapseMotion slot can directly take Collapse props, such "
          'as duration, easing, animateOpacity and others. The collapseMotion '
          'slot also supports the children render function, which allows '
          'replacing the default Collapse with a custom implementation. This '
          'story demonstrates the simpler direct prop approach. Note that '
          'collapseMotion must be set on each subtree Tree element — not the '
          'root — since the root tree does not animate:',
      builder: _motionCustom,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'items',
      type: 'List<FluentTreeItem>',
      description: 'The root nodes.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentTreeAppearance',
      defaultValue: 'FluentTreeAppearance.subtle',
      description: 'Fill treatment, applied to every row.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentTreeSize',
      defaultValue: 'FluentTreeSize.medium',
      description: 'Row height and type ramp, applied to every row.',
    ),
    PropRow(
      name: 'selectionMode',
      type: 'FluentTreeSelectionMode',
      defaultValue: 'FluentTreeSelectionMode.none',
      description: 'Which selection control the rows carry.',
    ),
    PropRow(
      name: 'openItems',
      type: 'Set<Object>?',
      defaultValue: 'null',
      description:
          'The open set. Non-null makes the tree controlled; the widget then '
          'never changes it itself.',
    ),
    PropRow(
      name: 'defaultOpenItems',
      type: 'Set<Object>',
      defaultValue: '{}',
      description: 'The initial open set for an uncontrolled tree.',
    ),
    PropRow(
      name: 'onOpenChange',
      type: 'ValueChanged<Set<Object>>?',
      defaultValue: 'null',
      description:
          'Reports the next open set. Required when openItems is non-null.',
    ),
    PropRow(
      name: 'selectedItems',
      type: 'Set<Object>',
      defaultValue: '{}',
      description:
          'The selected set, driving both the selection control and the '
          'Selected token ramp.',
    ),
    PropRow(
      name: 'onSelectionChange',
      type: 'ValueChanged<Set<Object>>?',
      defaultValue: 'null',
      description:
          'Reports the next selected set. Null renders the selection control '
          'disabled.',
    ),
    PropRow(
      name: 'onInvoke',
      type: 'ValueChanged<Object>?',
      defaultValue: 'null',
      description:
          'Invoked when a row is activated by click, Space or Enter, in '
          'addition to whatever the activation did to the open set.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentTreeItemStyle?',
      defaultValue: 'null',
      description: 'Overrides layered over the theme defaults.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Announced by assistive technology as the name of the tree.',
    ),
  ],
);

// #docregion components-tree--default
Widget _default(BuildContext context) => const FluentTree(
  semanticLabel: 'Default',
  items: <FluentTreeItem>[
    FluentTreeItem(
      value: '1',
      label: Text('level 1, item 1'),
      children: <FluentTreeItem>[
        FluentTreeItem(value: '1-1', label: Text('level 2, item 1')),
        FluentTreeItem(value: '1-2', label: Text('level 2, item 2')),
        FluentTreeItem(value: '1-3', label: Text('level 2, item 3')),
      ],
    ),
    FluentTreeItem(
      value: '2',
      label: Text('level 1, item 2'),
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: '2-1',
          label: Text('level 2, item 1'),
          children: <FluentTreeItem>[
            FluentTreeItem(value: '2-1-1', label: Text('level 3, item 1')),
          ],
        ),
      ],
    ),
    FluentTreeItem(value: '3', label: Text('level 1, item 3')),
  ],
);
// #enddocregion components-tree--default

// #docregion components-tree--size
Widget _size(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    FluentTree(
      size: FluentTreeSize.small,
      semanticLabel: 'Small Size Tree',
      items: <FluentTreeItem>[
        FluentTreeItem(
          value: '1',
          label: Text('Small size tree'),
          children: <FluentTreeItem>[
            FluentTreeItem(
              value: '1-1',
              label: Text('level 2, item 1'),
              children: <FluentTreeItem>[
                FluentTreeItem(value: '1-1-1', label: Text('level 3, item 1')),
              ],
            ),
            FluentTreeItem(value: '1-2', label: Text('level 2, item 2')),
            FluentTreeItem(value: '1-3', label: Text('level 2, item 3')),
          ],
        ),
      ],
    ),
    FluentTree(
      semanticLabel: 'Default Size Tree',
      items: <FluentTreeItem>[
        FluentTreeItem(
          value: '1',
          label: Text('Medium size tree'),
          children: <FluentTreeItem>[
            FluentTreeItem(
              value: '1-1',
              label: Text('level 2, item 1'),
              children: <FluentTreeItem>[
                FluentTreeItem(value: '1-1-1', label: Text('level 3, item 1')),
              ],
            ),
            FluentTreeItem(value: '1-2', label: Text('level 2, item 2')),
            FluentTreeItem(value: '1-3', label: Text('level 2, item 3')),
          ],
        ),
      ],
    ),
  ],
);
// #enddocregion components-tree--size

// #docregion components-tree--appearance
// Upstream's `TreeItemPersonaLayout` puts an `Avatar` in a `media` slot;
// `FluentTreeItem` has a leading `icon` slot that takes any widget, so the
// avatar goes there. `color="colorful"` picks a palette family from the name —
// `FluentAvatarColor` has the families but no auto-pick, so one is named per
// avatar, and `initials` is passed because `FluentAvatar` deliberately does not
// derive them from `name`.
Widget _appearance(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    const FluentTree(
      semanticLabel: 'Default Appearance',
      items: <FluentTreeItem>[
        FluentTreeItem(
          value: '1',
          label: Text('Default appearance'),
          children: _appearanceChildren,
        ),
      ],
    ),
    const FluentTree(
      appearance: FluentTreeAppearance.subtleAlpha,
      semanticLabel: 'Subtle Alpha Appearance',
      items: <FluentTreeItem>[
        FluentTreeItem(
          value: '1',
          label: Text('Subtle-alpha appearance'),
          children: _appearanceChildren,
        ),
      ],
    ),
    const FluentTree(
      appearance: FluentTreeAppearance.transparent,
      semanticLabel: 'Transparent Appearance',
      items: <FluentTreeItem>[
        FluentTreeItem(
          value: '1',
          label: Text('Transparent appearance'),
          children: _appearanceChildren,
        ),
      ],
    ),
    const FluentDivider(),
    FluentTree(
      semanticLabel: 'Default Appearance',
      items: <FluentTreeItem>[
        FluentTreeItem(
          value: '1',
          icon: Semantics(
            label: 'Default appearance avatar placeholder',
            child: FluentAvatar(
              name: 'Default',
              initials: 'D',
              color: FluentAvatarColor.cornflower,
            ),
          ),
          label: Text('Default appearance'),
          children: _appearancePersonaChildren,
        ),
      ],
    ),
    FluentTree(
      appearance: FluentTreeAppearance.subtleAlpha,
      semanticLabel: 'Subtle Alpha Appearance',
      items: <FluentTreeItem>[
        FluentTreeItem(
          value: '1',
          icon: Semantics(
            label: 'Subtle-alpha appearance avatar placeholder',
            child: FluentAvatar(
              name: 'Subtle Alpha',
              initials: 'SA',
              color: FluentAvatarColor.peach,
            ),
          ),
          label: Text('Subtle-alpha appearance'),
          children: _appearancePersonaChildren,
        ),
      ],
    ),
    FluentTree(
      appearance: FluentTreeAppearance.transparent,
      semanticLabel: 'Transparent Appearance',
      items: <FluentTreeItem>[
        FluentTreeItem(
          value: '1',
          icon: Semantics(
            label: 'Transparent appearance avatar placeholder',
            child: FluentAvatar(
              name: 'Transparent',
              initials: 'T',
              color: FluentAvatarColor.platinum,
            ),
          ),
          label: Text('Transparent appearance'),
          children: _appearancePersonaChildren,
        ),
      ],
    ),
  ],
);

const List<FluentTreeItem> _appearanceChildren = <FluentTreeItem>[
  FluentTreeItem(value: '1-1', label: Text('level 2, item 1')),
  FluentTreeItem(value: '1-2', label: Text('level 2, item 2')),
];

const List<FluentTreeItem> _appearancePersonaChildren = <FluentTreeItem>[
  FluentTreeItem(
    value: '1-1',
    icon: FluentAvatar(name: 'Avatar placeholder'),
    label: Text('level 2, item 1'),
  ),
  FluentTreeItem(
    value: '1-2',
    icon: FluentAvatar(name: 'Avatar placeholder'),
    label: Text('level 2, item 2'),
  ),
];
// #enddocregion components-tree--appearance

// #docregion components-tree--layouts
// `TreeItemLayout` is a plain `Text` label; `TreeItemPersonaLayout` is a
// `FluentPersona` label, which composes the avatar, the primary line and the
// `description` line. `presenceOnly` with no status is how a persona renders
// "without media": the media slot resolves to nothing at all.
Widget _layouts(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    FluentTree(
      semanticLabel: 'Default Layout',
      items: <FluentTreeItem>[
        FluentTreeItem(
          value: '1',
          label: Text('Tree using TreeItemLayout'),
          children: <FluentTreeItem>[
            FluentTreeItem(value: '1-1', label: Text('level 2, item 1')),
            FluentTreeItem(value: '1-2', label: Text('level 2, item 2')),
            FluentTreeItem(value: '1-3', label: Text('level 2, item 3')),
          ],
        ),
      ],
    ),
    FluentTree(
      semanticLabel: 'Persona Layout',
      items: <FluentTreeItem>[
        FluentTreeItem(
          value: '1',
          label: FluentPersona(
            primary: Text('Tree using TreeItemPersonaLayout'),
          ),
          children: <FluentTreeItem>[
            FluentTreeItem(
              value: '1-1',
              label: FluentPersona(
                primary: Text('level 2, item 1'),
                secondary: Text('with description'),
              ),
            ),
            FluentTreeItem(
              value: '1-2',
              label: FluentPersona(
                shape: FluentAvatarShape.square,
                primary: Text('level 2, item 2'),
                secondary: Text('square shape media'),
              ),
            ),
            FluentTreeItem(
              value: '1-3',
              label: FluentPersona(
                presenceOnly: true,
                primary: Text('level 2, item 3'),
                secondary: Text('without media'),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
// #enddocregion components-tree--layouts

// #docregion components-tree--expand-icon
// Upstream swaps `TreeItemLayout`'s `expandIcon` slot. `FluentTree` draws its
// own chevron and exposes no slot to replace it, so the plus/minus glyph goes
// in the leading `icon` slot and tracks the same controlled `openItems` set.
Widget _expandIcon(BuildContext context) => const _ExpandIcon();

class _ExpandIcon extends StatefulWidget {
  const _ExpandIcon();

  @override
  State<_ExpandIcon> createState() => _ExpandIconState();
}

class _ExpandIconState extends State<_ExpandIcon> {
  Set<Object> _openItems = <Object>{};

  Widget _icon(Object value) => Icon(
    _openItems.contains(value)
        ? FluentIcons.subtract_square_16_regular
        : FluentIcons.add_square_16_regular,
    size: 16,
  );

  @override
  Widget build(BuildContext context) => FluentTree(
    semanticLabel: 'Expand Icon',
    openItems: _openItems,
    onOpenChange: (Set<Object> next) => setState(() => _openItems = next),
    items: <FluentTreeItem>[
      FluentTreeItem(
        value: 'tree-item-2',
        icon: _icon('tree-item-2'),
        label: const Text('level 1, item 1'),
        children: <FluentTreeItem>[
          FluentTreeItem(
            value: 'tree-item-3',
            icon: _icon('tree-item-3'),
            label: const Text('level 2, item 1'),
            children: const <FluentTreeItem>[
              FluentTreeItem(value: '3-1', label: Text('level 3, item 1')),
            ],
          ),
        ],
      ),
      FluentTreeItem(
        value: 'tree-item-1',
        icon: _icon('tree-item-1'),
        label: const Text('level 1, item 2'),
        children: const <FluentTreeItem>[
          FluentTreeItem(value: '1-1', label: Text('level 2, item 1')),
          FluentTreeItem(value: '1-2', label: Text('level 2, item 2')),
        ],
      ),
    ],
  );
}
// #enddocregion components-tree--expand-icon

// #docregion components-tree--icon-before-and-after
// `iconBefore` is the row's leading `icon` slot. `iconAfter` has no counterpart
// — the nearest thing is the trailing `actions` slot, which sits at the end of
// the row rather than immediately after the label.
Widget _iconBeforeAndAfter(BuildContext context) => const FluentTree(
  semanticLabel: 'Icon Before & After',
  items: <FluentTreeItem>[
    FluentTreeItem(
      value: '1',
      icon: Icon(FluentIcons.image_20_regular),
      actions: Icon(FluentIcons.lock_closed_20_regular),
      label: Text('level 1, item 1'),
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: '1-1',
          icon: Icon(FluentIcons.person_20_regular),
          label: Text('icon before'),
        ),
        FluentTreeItem(
          value: '1-2',
          icon: Icon(FluentIcons.person_20_regular),
          label: Text('icon before'),
        ),
      ],
    ),
    FluentTreeItem(
      value: '2',
      icon: Icon(FluentIcons.image_20_regular),
      actions: Icon(FluentIcons.lock_closed_20_regular),
      label: Text('level 1, item 2'),
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: '2-1',
          actions: Icon(FluentIcons.warning_20_regular),
          label: Text('icon after'),
        ),
      ],
    ),
  ],
);
// #enddocregion components-tree--icon-before-and-after

// #docregion components-tree--aside
// The `aside` slot maps to `FluentTreeItem.actions` — one trailing slot rather
// than upstream's two that share a spot — and `CounterBadge` to a small danger
// `FluentBadge`. Upstream's `aria-description` lives on the tree item;
// `FluentTreeItem` has no description field, so it is passed to the aside and
// announced with it.
Widget _aside(BuildContext context) => const FluentTree(
  semanticLabel: 'Aside',
  items: <FluentTreeItem>[
    FluentTreeItem(
      value: '1',
      actions: _AsideContent(
        isImportant: true,
        messageCount: 3,
        description: 'Important, 3 message',
      ),
      label: Text('level 1, item 1'),
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: '1-1',
          actions: _AsideContent(isImportant: true, description: 'Important'),
          label: Text('level 2, item 1'),
        ),
        FluentTreeItem(
          value: '1-2',
          actions: _AsideContent(messageCount: 2, description: '2 messages'),
          label: Text('level 2, item 2'),
        ),
      ],
    ),
    FluentTreeItem(
      value: '2',
      actions: _AsideContent(
        isImportant: true,
        messageCount: 1,
        description: 'Important, 1 message',
      ),
      label: Text('level 1, item 2'),
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: '2-1',
          actions: _AsideContent(messageCount: 1, description: '1 message'),
          label: Text('level 2, item 1'),
          children: <FluentTreeItem>[
            FluentTreeItem(
              value: '2-1-1',
              actions: _AsideContent(),
              label: Text('level 3, item 1'),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _AsideContent extends StatelessWidget {
  const _AsideContent({
    this.isImportant = false,
    this.messageCount,
    this.description,
  });

  final bool isImportant;
  final int? messageCount;
  final String? description;

  @override
  Widget build(BuildContext context) => Semantics(
    label: description,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xs,
      children: <Widget>[
        if (isImportant)
          // Upstream sets `primaryFill: 'red'` on this glyph.
          const Icon(
            FluentIcons.important_16_regular,
            size: 16,
            color: Color(0xFFFF0000),
          ),
        if (messageCount != null && messageCount! > 0)
          FluentBadge(
            color: FluentBadgeColor.danger,
            size: FluentBadgeSize.small,
            child: Text('$messageCount'),
          ),
      ],
    ),
  );
}
// #enddocregion components-tree--aside

// #docregion components-tree--actions
// Upstream wraps every `TreeItem` in an `openOnContext` `Menu` so the same four
// commands are also reachable from a right-click, and marks the row with
// `aria-description="has actions"`. `FluentMenu` opens from its own trigger
// only and `FluentTreeItem` carries no description slot, so the row keeps the
// edit button and the overflow menu and drops the context menu.
Widget _actions(BuildContext context) => const FluentTree(
  semanticLabel: 'Actions',
  items: <FluentTreeItem>[
    FluentTreeItem(
      value: 'item 1',
      actions: _TreeItemActions(),
      label: Text('item 1'),
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: 'item 1-1',
          actions: _TreeItemActions(),
          label: Text('item 1-1'),
          children: <FluentTreeItem>[
            FluentTreeItem(
              value: 'item 1-1-1',
              actions: _TreeItemActions(),
              label: Text('item 1-1-1'),
            ),
            FluentTreeItem(
              value: 'item 1-1-2',
              actions: _TreeItemActions(),
              label: Text('item 1-1-2'),
            ),
            FluentTreeItem(
              value: 'item 1-1-3',
              actions: _TreeItemActions(),
              label: Text('item 1-1-3'),
            ),
          ],
        ),
        FluentTreeItem(
          value: 'item 1-2',
          actions: _TreeItemActions(),
          label: Text('item 1-2'),
        ),
        FluentTreeItem(
          value: 'item 1-3',
          actions: _TreeItemActions(),
          label: Text('item 1-3'),
        ),
      ],
    ),
    FluentTreeItem(
      value: 'item 2',
      actions: _TreeItemActions(),
      label: Text('item 2'),
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: 'item 2-1',
          actions: _TreeItemActions(),
          label: Text('item 2-1'),
          children: <FluentTreeItem>[
            FluentTreeItem(
              value: 'item 2-1-1',
              actions: _TreeItemActions(),
              label: Text('item 2-1-1'),
            ),
          ],
        ),
        FluentTreeItem(
          value: 'item 3',
          actions: _TreeItemActions(),
          label: Text('item 3'),
          children: <FluentTreeItem>[
            FluentTreeItem(
              value: 'item 3-1',
              actions: _TreeItemActions(),
              label: Text('item 3-1'),
            ),
            FluentTreeItem(
              value: 'item 3-2',
              actions: _TreeItemActions(),
              label: Text('item 3-2'),
            ),
            FluentTreeItem(
              value: 'item 3-3',
              actions: _TreeItemActions(),
              label: Text('item 3-3'),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _TreeItemActions extends StatelessWidget {
  const _TreeItemActions();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentButton.icon(
        icon: const Icon(FluentIcons.edit_20_regular),
        semanticLabel: 'Edit',
        appearance: FluentButtonAppearance.subtle,
        onPressed: () {},
      ),
      FluentMenu(
        items: <FluentMenuItem>[
          FluentMenuItem(label: const Text('New '), onPressed: () {}),
          FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
          const FluentMenuItem(label: Text('Open File'), enabled: false),
          FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
        ],
        builder: (BuildContext context, VoidCallback toggle) =>
            FluentButton.icon(
              icon: const Icon(FluentIcons.more_horizontal_20_regular),
              semanticLabel: 'More options',
              appearance: FluentButtonAppearance.subtle,
              onPressed: toggle,
            ),
      ),
    ],
  );
}
// #enddocregion components-tree--actions

// #docregion components-tree--navigation-mode-tree-grid
// `navigationMode="treegrid"` moves focus from a row into its actions with the
// right arrow key. `FluentTree` has a single navigation model — the arrow keys
// walk the visible rows and Tab reaches the actions — so the tree is the same
// one the Actions story renders and only the keyboard route differs.
Widget _navigationModeTreeGrid(BuildContext context) => const FluentTree(
  semanticLabel: 'Actions',
  items: <FluentTreeItem>[
    FluentTreeItem(
      value: 'item 1',
      actions: _TreeGridItemActions(),
      label: Text('item 1'),
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: 'item 1-1',
          actions: _TreeGridItemActions(),
          label: Text('item 1-1'),
          children: <FluentTreeItem>[
            FluentTreeItem(
              value: 'item 1-1-1',
              actions: _TreeGridItemActions(),
              label: Text('item 1-1-1'),
            ),
            FluentTreeItem(
              value: 'item 1-1-2',
              actions: _TreeGridItemActions(),
              label: Text('item 1-1-2'),
            ),
            FluentTreeItem(
              value: 'item 1-1-3',
              actions: _TreeGridItemActions(),
              label: Text('item 1-1-3'),
            ),
          ],
        ),
        FluentTreeItem(
          value: 'item 1-2',
          actions: _TreeGridItemActions(),
          label: Text('item 1-2'),
        ),
        FluentTreeItem(
          value: 'item 1-3',
          actions: _TreeGridItemActions(),
          label: Text('item 1-3'),
        ),
      ],
    ),
    FluentTreeItem(
      value: 'item 2',
      actions: _TreeGridItemActions(),
      label: Text('item 2'),
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: 'item 2-1',
          actions: _TreeGridItemActions(),
          label: Text('item 2-1'),
          children: <FluentTreeItem>[
            FluentTreeItem(
              value: 'item 2-1-1',
              actions: _TreeGridItemActions(),
              label: Text('item 2-1-1'),
            ),
          ],
        ),
        FluentTreeItem(
          value: 'item 3',
          actions: _TreeGridItemActions(),
          label: Text('item 3'),
          children: <FluentTreeItem>[
            FluentTreeItem(
              value: 'item 3-1',
              actions: _TreeGridItemActions(),
              label: Text('item 3-1'),
            ),
            FluentTreeItem(
              value: 'item 3-2',
              actions: _TreeGridItemActions(),
              label: Text('item 3-2'),
            ),
            FluentTreeItem(
              value: 'item 3-3',
              actions: _TreeGridItemActions(),
              label: Text('item 3-3'),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _TreeGridItemActions extends StatelessWidget {
  const _TreeGridItemActions();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentButton.icon(
        icon: const Icon(FluentIcons.edit_20_regular),
        semanticLabel: 'Edit',
        appearance: FluentButtonAppearance.subtle,
        onPressed: () {},
      ),
      FluentMenu(
        items: <FluentMenuItem>[
          FluentMenuItem(label: const Text('New '), onPressed: () {}),
          FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
          const FluentMenuItem(label: Text('Open File'), enabled: false),
          FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
        ],
        builder: (BuildContext context, VoidCallback toggle) =>
            FluentButton.icon(
              icon: const Icon(FluentIcons.more_horizontal_20_regular),
              semanticLabel: 'More options',
              appearance: FluentButtonAppearance.subtle,
              onPressed: toggle,
            ),
      ),
    ],
  );
}
// #enddocregion components-tree--navigation-mode-tree-grid

// #docregion components-tree--default-open
Widget _defaultOpen(BuildContext context) => const FluentTree(
  semanticLabel: 'Default Open',
  defaultOpenItems: <Object>{
    'default-subtree-1',
    'default-subtree-2',
    'default-subtree-2-1',
  },
  items: <FluentTreeItem>[
    FluentTreeItem(
      value: 'default-subtree-1',
      label: Text('level 1, item 1'),
      children: <FluentTreeItem>[
        FluentTreeItem(value: '1-1', label: Text('level 2, item 1')),
        FluentTreeItem(value: '1-2', label: Text('level 2, item 2')),
        FluentTreeItem(value: '1-3', label: Text('level 2, item 3')),
      ],
    ),
    FluentTreeItem(
      value: 'default-subtree-2',
      label: Text('level 1, item 2'),
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: 'default-subtree-2-1',
          label: Text('level 2, item 1'),
          children: <FluentTreeItem>[
            FluentTreeItem(value: '2-1-1', label: Text('level 3, item 1')),
            FluentTreeItem(value: '2-1-2', label: Text('level 3, item 2')),
            FluentTreeItem(value: '2-1-3', label: Text('level 3, item 3')),
          ],
        ),
      ],
    ),
  ],
);
// #enddocregion components-tree--default-open

// #docregion components-tree--open-items-controlled
Widget _openItemsControlled(BuildContext context) =>
    const _OpenItemsControlled();

class _OpenItemsControlled extends StatefulWidget {
  const _OpenItemsControlled();

  @override
  State<_OpenItemsControlled> createState() => _OpenItemsControlledState();
}

class _OpenItemsControlledState extends State<_OpenItemsControlled> {
  Set<Object> _openItems = <Object>{};

  @override
  Widget build(BuildContext context) => FluentTree(
    semanticLabel: 'Open Items Controlled',
    openItems: _openItems,
    onOpenChange: (Set<Object> next) => setState(() => _openItems = next),
    items: const <FluentTreeItem>[
      FluentTreeItem(
        value: 'tree-item-1',
        label: Text('level 1, item 1'),
        children: <FluentTreeItem>[
          FluentTreeItem(value: '1-1', label: Text('level 2, item 1')),
          FluentTreeItem(value: '1-2', label: Text('level 2, item 2')),
          FluentTreeItem(value: '1-3', label: Text('level 2, item 3')),
        ],
      ),
      FluentTreeItem(
        value: 'tree-item-2',
        label: Text('level 1, item 2'),
        children: <FluentTreeItem>[
          FluentTreeItem(
            value: 'tree-item-3',
            label: Text('level 2, item 1'),
            children: <FluentTreeItem>[
              FluentTreeItem(value: '3-1', label: Text('level 3, item 1')),
            ],
          ),
        ],
      ),
    ],
  );
}
// #enddocregion components-tree--open-items-controlled

// #docregion components-tree--open-item-controlled
// Upstream controls the `open` prop of one `TreeItem` and leaves the rest
// uncontrolled. `FluentTree` owns the open set for the whole tree, so the set
// is controlled here instead and `tree-item-1` simply starts inside it.
Widget _openItemControlled(BuildContext context) => const _OpenItemControlled();

class _OpenItemControlled extends StatefulWidget {
  const _OpenItemControlled();

  @override
  State<_OpenItemControlled> createState() => _OpenItemControlledState();
}

class _OpenItemControlledState extends State<_OpenItemControlled> {
  Set<Object> _openItems = <Object>{'tree-item-1'};

  @override
  Widget build(BuildContext context) => FluentTree(
    semanticLabel: 'Open Item Controlled',
    openItems: _openItems,
    onOpenChange: (Set<Object> next) => setState(() => _openItems = next),
    items: const <FluentTreeItem>[
      FluentTreeItem(
        value: 'tree-item-1',
        label: Text('level 1, item 1'),
        children: <FluentTreeItem>[
          FluentTreeItem(value: '1-1', label: Text('level 2, item 1')),
          FluentTreeItem(value: '1-2', label: Text('level 2, item 2')),
          FluentTreeItem(value: '1-3', label: Text('level 2, item 3')),
        ],
      ),
      FluentTreeItem(
        value: 'tree-item-2',
        label: Text('level 1, item 2'),
        children: <FluentTreeItem>[
          FluentTreeItem(
            value: 'tree-item-3',
            label: Text('level 2, item 1'),
            children: <FluentTreeItem>[
              FluentTreeItem(value: '3-1', label: Text('level 3, item 1')),
            ],
          ),
        ],
      ),
    ],
  );
}
// #enddocregion components-tree--open-item-controlled

// #docregion components-tree--customizing-interaction
// Upstream reads `data.type` to tell a click on the content from a click on the
// chevron, and calls `alert('click on item')` for the first. A `FluentTree` row
// is one hit target, so the row both reports through `onInvoke` and opens
// through `onOpenChange`; the message lands under the tree rather than in an
// alert, which Flutter has no equivalent of.
Widget _customizingInteraction(BuildContext context) =>
    const _CustomizingInteraction();

class _CustomizingInteraction extends StatefulWidget {
  const _CustomizingInteraction();

  @override
  State<_CustomizingInteraction> createState() =>
      _CustomizingInteractionState();
}

class _CustomizingInteractionState extends State<_CustomizingInteraction> {
  Set<Object> _openItems = <Object>{};
  String? _message;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentTree(
        semanticLabel: 'Customizing Interaction',
        openItems: _openItems,
        onOpenChange: (Set<Object> next) => setState(() => _openItems = next),
        onInvoke: (Object value) => setState(() => _message = 'click on item'),
        items: const <FluentTreeItem>[
          FluentTreeItem(
            value: 'default-subtree-1',
            label: Text('level 1, item 1'),
            children: <FluentTreeItem>[
              FluentTreeItem(value: '1-1', label: Text('level 2, item 1')),
              FluentTreeItem(value: '1-2', label: Text('level 2, item 2')),
            ],
          ),
          FluentTreeItem(
            value: 'default-subtree-2',
            label: Text('level 1, item 2'),
            children: <FluentTreeItem>[
              FluentTreeItem(
                value: 'default-subtree-2-1',
                label: Text('level 2, item 1'),
                children: <FluentTreeItem>[
                  FluentTreeItem(
                    value: '2-1-1',
                    label: Text('level 3, item 1'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      if (_message != null) ...<Widget>[
        const SizedBox(height: 12),
        Text(_message!),
      ],
    ],
  );
}
// #enddocregion components-tree--customizing-interaction

// #docregion components-tree--inline-styling-tree-item-level
// Upstream recurses through `useSubtreeContext_unstable`, so the tree is
// arbitrarily deep and each item writes its own `--fui-TreeItem--level`.
// `FluentTree` takes a data tree and derives the level from it, so the depth is
// materialised here — twelve levels, past the ten upstream generates static
// styles for — and the per-level inset is set once through
// `FluentTreeItemStyle.indent`.
Widget _inlineStylingTreeItemLevel(BuildContext context) => FluentTree(
  semanticLabel: 'Inline Styling Tree Item Level',
  style: const FluentTreeItemStyle(indent: WidgetStatePropertyAll<double?>(12)),
  items: <FluentTreeItem>[_treeItemForLevel(1)],
);

FluentTreeItem _treeItemForLevel(int level) => FluentTreeItem(
  value: level,
  label: Text('level $level, item 1'),
  children: level < 12
      ? <FluentTreeItem>[_treeItemForLevel(level + 1)]
      : const <FluentTreeItem>[],
);
// #enddocregion components-tree--inline-styling-tree-item-level

// #docregion components-tree--flat-tree
// `FlatTree` renders one flat list and leaves it to the caller to hide the rows
// whose parent is closed, and to supply `aria-level`, `aria-setsize`,
// `aria-posinset` and `parentValue` by hand. `FluentTree` has no flat variant:
// the same items are nested and every one of those four falls out of the
// structure.
Widget _flatTree(BuildContext context) => const _FlatTree();

class _FlatTree extends StatefulWidget {
  const _FlatTree();

  @override
  State<_FlatTree> createState() => _FlatTreeState();
}

class _FlatTreeState extends State<_FlatTree> {
  Set<Object> _openItems = <Object>{};

  @override
  Widget build(BuildContext context) => FluentTree(
    semanticLabel: 'Flat Tree',
    openItems: _openItems,
    onOpenChange: (Set<Object> next) => setState(() => _openItems = next),
    items: const <FluentTreeItem>[
      FluentTreeItem(
        value: '1',
        label: Text('Item 1, level 1'),
        children: <FluentTreeItem>[
          FluentTreeItem(value: '1-1', label: Text('Item 1, level 2')),
          FluentTreeItem(value: '1-2', label: Text('Item 1, level 2')),
        ],
      ),
      FluentTreeItem(
        value: '2',
        label: Text('Item 1, level 1'),
        children: <FluentTreeItem>[
          FluentTreeItem(value: '2-1', label: Text('Item 1, level 2')),
          FluentTreeItem(value: '2-2', label: Text('Item 2, level 2')),
          FluentTreeItem(value: '2-3', label: Text('Item 3, level 2')),
        ],
      ),
    ],
  );
}
// #enddocregion components-tree--flat-tree

// #docregion components-tree--use-headless-flat-tree
// `useHeadlessFlatTree_unstable` turns a flat `value`/`parentValue` list into
// the tree's row model. `FluentTree` already takes a tree, so the flat list —
// which is what the story is about — is kept as written and folded into nested
// items by `_nestHeadlessItems`. Upstream also gives each row an
// `openOnContext` menu repeating the same commands; `FluentMenu` opens from its
// trigger only, so the row keeps the overflow button alone.
//
// Upstream also keeps a commented-out `flattenTree_unstable` example beside
// the flat list, nesting the same rows — level 1, item 1 over level 2, item 1,
// level 2, item 2 and level 2, item 3, then level 1, item 2 over level 2,
// item 1, level 3, item 1 and level 4, item 1 — to show that the nested and
// the flat form describe the same tree.
Widget _useHeadlessFlatTree(BuildContext context) =>
    FluentTree(semanticLabel: 'Flat Tree', items: _nestHeadlessItems(null));

class _HeadlessFlatItem {
  const _HeadlessFlatItem(this.value, this.content, {this.parentValue});

  final String value;
  final String content;
  final String? parentValue;
}

const List<_HeadlessFlatItem> _headlessFlatTreeItems = <_HeadlessFlatItem>[
  _HeadlessFlatItem('1', 'Level 1, item 1'),
  _HeadlessFlatItem('1-1', 'Level 2, item 1', parentValue: '1'),
  _HeadlessFlatItem('1-2', 'Level 2, item 2', parentValue: '1'),
  _HeadlessFlatItem('1-3', 'Level 2, item 3', parentValue: '1'),
  _HeadlessFlatItem('2', 'Level 1, item 2'),
  _HeadlessFlatItem('2-1', 'Level 2, item 1', parentValue: '2'),
  _HeadlessFlatItem('2-1-1', 'Level 3, item 1', parentValue: '2-1'),
  _HeadlessFlatItem('2-1-1-1', 'Level 4, item 1', parentValue: '2-1-1'),
];

List<FluentTreeItem> _nestHeadlessItems(String? parentValue) =>
    <FluentTreeItem>[
      for (final _HeadlessFlatItem item in _headlessFlatTreeItems)
        if (item.parentValue == parentValue)
          FluentTreeItem(
            value: item.value,
            actions: const _HeadlessFlatTreeActions(),
            label: Text(item.content),
            children: _nestHeadlessItems(item.value),
          ),
    ];

class _HeadlessFlatTreeActions extends StatelessWidget {
  const _HeadlessFlatTreeActions();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentButton.icon(
        icon: const Icon(FluentIcons.edit_20_regular),
        semanticLabel: 'Edit',
        appearance: FluentButtonAppearance.subtle,
        onPressed: () {},
      ),
      FluentMenu(
        items: <FluentMenuItem>[
          FluentMenuItem(label: const Text('New'), onPressed: () {}),
          FluentMenuItem(label: const Text('New Window'), onPressed: () {}),
          const FluentMenuItem(label: Text('Open File'), enabled: false),
          FluentMenuItem(label: const Text('Open Folder'), onPressed: () {}),
        ],
        builder: (BuildContext context, VoidCallback toggle) =>
            FluentButton.icon(
              icon: const Icon(FluentIcons.more_horizontal_20_regular),
              semanticLabel: 'More options',
              appearance: FluentButtonAppearance.subtle,
              onPressed: toggle,
            ),
      ),
    ],
  );
}
// #enddocregion components-tree--use-headless-flat-tree

// #docregion components-tree--selection
// `defaultCheckedItems` has no uncontrolled counterpart: `FluentTree` always
// takes `selectedItems` from the caller, so the default set is the initial
// value of local state instead.
Widget _selection(BuildContext context) => const _Selection();

class _Selection extends StatefulWidget {
  const _Selection();

  @override
  State<_Selection> createState() => _SelectionState();
}

class _SelectionState extends State<_Selection> {
  // change to FluentTreeSelectionMode.single for single selection
  static const FluentTreeSelectionMode _selectionMode =
      FluentTreeSelectionMode.multiple;

  Set<Object> _checkedItems = <Object>{'1-2'};

  @override
  Widget build(BuildContext context) => FluentTree(
    semanticLabel: 'Selection',
    selectionMode: _selectionMode,
    defaultOpenItems: const <Object>{'1', '2', '2-1', '2-2'},
    selectedItems: _checkedItems,
    onSelectionChange: (Set<Object> next) =>
        setState(() => _checkedItems = next),
    items: const <FluentTreeItem>[
      FluentTreeItem(
        value: '1',
        label: Text('Level 1, item 1'),
        children: <FluentTreeItem>[
          FluentTreeItem(value: '1-1', label: Text('Level 2, item 1')),
          FluentTreeItem(value: '1-2', label: Text('Level 2, item 2')),
        ],
      ),
      FluentTreeItem(
        value: '2',
        label: Text('Level 1, item 2'),
        children: <FluentTreeItem>[
          FluentTreeItem(
            value: '2-1',
            label: Text('Level 2, item 1'),
            children: <FluentTreeItem>[
              FluentTreeItem(value: '2-1-1', label: Text('Level 3, item 1')),
            ],
          ),
          FluentTreeItem(
            value: '2-2',
            label: Text('Level 2, item 2'),
            children: <FluentTreeItem>[
              FluentTreeItem(value: '2-2-1', label: Text('Level 3, item 1')),
              FluentTreeItem(value: '2-2-2', label: Text('Level 3, item 2')),
            ],
          ),
        ],
      ),
      FluentTreeItem(value: '3', label: Text('Level 1, item 3')),
    ],
  );
}
// #enddocregion components-tree--selection

// #docregion components-tree--manipulation
// Upstream keeps two flat subtrees in state, adds and removes entries by
// `parentValue`, and hands the focus to the row that takes the removed one's
// place — its `aria-description` is "has actions". `FluentTree` owns focus
// itself and moves it to the next visible row when the focused one disappears,
// so only the two mutations are written here.
Widget _manipulation(BuildContext context) => const _Manipulation();

class _ManipulationItem {
  const _ManipulationItem(this.value, this.content);

  final String value;
  final String content;
}

class _Manipulation extends StatefulWidget {
  const _Manipulation();

  @override
  State<_Manipulation> createState() => _ManipulationState();
}

class _ManipulationState extends State<_Manipulation> {
  List<List<_ManipulationItem>> _trees = <List<_ManipulationItem>>[
    <_ManipulationItem>[
      const _ManipulationItem('1', 'Level 1, item 1'),
      const _ManipulationItem('1-1', 'Item 1-1'),
      const _ManipulationItem('1-2', 'Item 1-2'),
    ],
    <_ManipulationItem>[
      const _ManipulationItem('2', 'Level 1, item 2'),
      const _ManipulationItem('2-1', 'Item 2-1'),
    ],
  ];

  void _addItem(int subtreeIndex) {
    setState(() {
      final List<_ManipulationItem> subtree = _trees[subtreeIndex];
      final String last = subtree.last.value;
      final String newItemValue =
          '${subtreeIndex + 1}-${int.parse(last.substring(2)) + 1}';
      _trees = <List<_ManipulationItem>>[
        for (int i = 0; i < _trees.length; i++)
          if (i == subtreeIndex)
            <_ManipulationItem>[
              ...subtree,
              _ManipulationItem(newItemValue, 'New item $newItemValue'),
            ]
          else
            _trees[i],
      ];
    });
  }

  void _removeItem(String value) {
    setState(() {
      _trees = <List<_ManipulationItem>>[
        for (final List<_ManipulationItem> subtree in _trees)
          <_ManipulationItem>[
            for (final _ManipulationItem item in subtree)
              if (item.value != value) item,
          ],
      ];
    });
  }

  @override
  Widget build(BuildContext context) => FluentTree(
    semanticLabel: 'Manipulation',
    defaultOpenItems: const <Object>{'1', '2'},
    onInvoke: (Object value) {
      if (value is String && value.endsWith('-btn')) {
        _addItem(int.parse(value[0]) - 1);
      }
    },
    items: <FluentTreeItem>[
      for (int i = 0; i < _trees.length; i++)
        FluentTreeItem(
          value: _trees[i].first.value,
          label: Text(_trees[i].first.content),
          children: <FluentTreeItem>[
            for (final _ManipulationItem item in _trees[i].skip(1))
              FluentTreeItem(
                value: item.value,
                actions: FluentButton.icon(
                  icon: const Icon(FluentIcons.delete_20_regular),
                  semanticLabel: 'Remove item',
                  appearance: FluentButtonAppearance.subtle,
                  onPressed: () => _removeItem(item.value),
                ),
                label: Text(item.content),
              ),
            FluentTreeItem(
              value: '${i + 1}-btn',
              label: const Text('Add new item'),
            ),
          ],
        ),
    ],
  );
}
// #enddocregion components-tree--manipulation

// #docregion components-tree--lazy-loading
// Upstream fetches each subtree through a `mockFetch` helper the captured story
// does not include, so the rows that arrive are numbered rather than named.
// Everything else is upstream's shape: a branch opens, a spinner stands in for
// the expand icon while the request is in flight, and the live region announces
// both edges of the load.
Widget _lazyLoading(BuildContext context) => const _LazyLoading();

class _LazyLoading extends StatefulWidget {
  const _LazyLoading();

  @override
  State<_LazyLoading> createState() => _LazyLoadingState();
}

class _LazyLoadingState extends State<_LazyLoading> {
  static const List<String> _subtrees = <String>[
    'People',
    'Planet',
    'Starship',
  ];

  final Map<String, List<String>> _loaded = <String, List<String>>{};
  final Set<String> _loading = <String>{};
  Set<Object> _openItems = <Object>{};
  String _ariaMessage = '';

  Future<void> _load(String value) async {
    setState(() {
      _loading.add(value);
      _ariaMessage = 'loading ${value.toLowerCase()} items...';
    });
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }
    setState(() {
      _loading.remove(value);
      _loaded[value] = <String>[for (int i = 1; i <= 3; i++) '$value $i'];
      _ariaMessage = '${value.toLowerCase()} items loaded';
    });
  }

  void _handleOpenChange(Set<Object> next) {
    setState(() => _openItems = next);
    for (final String value in _subtrees) {
      if (next.contains(value) &&
          !_loaded.containsKey(value) &&
          !_loading.contains(value)) {
        _load(value);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentTree(
        semanticLabel: 'Lazy Loading',
        openItems: _openItems,
        onOpenChange: _handleOpenChange,
        items: <FluentTreeItem>[
          for (final String value in _subtrees)
            FluentTreeItem(
              value: value,
              icon: _loading.contains(value)
                  ? const FluentSpinner(size: FluentSpinnerSize.tiny)
                  : null,
              label: Text(value),
              children: <FluentTreeItem>[
                if (_loaded[value] == null)
                  FluentTreeItem(
                    value: '$value/loading',
                    label: const Text('...'),
                  )
                else
                  for (final String name in _loaded[value]!)
                    FluentTreeItem(value: '$value/$name', label: Text(name)),
              ],
            ),
        ],
      ),
      // Upstream's `screenReadersOnly` live region: announced, never drawn.
      Semantics(liveRegion: true, label: _ariaMessage, child: const SizedBox()),
    ],
  );
}
// #enddocregion components-tree--lazy-loading

// #docregion components-tree--infinite-scrolling
// Upstream's `mockFetchPeople` resolves a Promise after a one second timeout
// and the page-in happens when the scroll container hits its end. A `Future`
// and a `ScrollNotification` do the same two jobs here; `FluentTree` lays its
// rows out as a column, so the 400px container is the scroll view.
Widget _infiniteScrolling(BuildContext context) => const _InfiniteScrolling();

class _InfiniteScrolling extends StatefulWidget {
  const _InfiniteScrolling();

  @override
  State<_InfiniteScrolling> createState() => _InfiniteScrollingState();
}

class _InfiniteScrollingState extends State<_InfiniteScrolling> {
  static const int _itemsPerPage = 10;
  static const int _maxPages = 4;

  int _page = 1;
  bool _isLoading = false;
  String _ariaMessage = '';
  List<String> _people = <String>[
    for (int index = 0; index < _itemsPerPage; index++) 'Person ${index + 1}',
  ];

  Future<void> _fetchMoreItems() async {
    setState(() {
      _isLoading = true;
      _ariaMessage = 'loading more people...';
    });
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }
    final int startIndex = _page * _itemsPerPage + 1;
    final List<String> fetchedItems = <String>[
      for (int index = 0; index < _itemsPerPage; index++)
        'Person ${startIndex + index}',
    ];
    setState(() {
      _people = <String>[..._people, ...fetchedItems];
      _isLoading = false;
      _page += 1;
      _ariaMessage = '${fetchedItems.length} new people loaded';
    });
  }

  bool _handleScroll(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    final bool hasReachedEnd =
        metrics.maxScrollExtent > 0 &&
        metrics.pixels >= metrics.maxScrollExtent;
    if (!_isLoading && hasReachedEnd && _page < _maxPages) {
      _fetchMoreItems();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(
        height: 400,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScroll,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 10),
            child: FluentTree(
              semanticLabel: 'Infinite Scrolling',
              defaultOpenItems: const <Object>{'pinned', 'people'},
              items: <FluentTreeItem>[
                const FluentTreeItem(
                  value: 'pinned',
                  label: Text('Pinned'),
                  children: <FluentTreeItem>[
                    FluentTreeItem(
                      value: 'pinned-item-1',
                      label: Text('Pinned item 1'),
                    ),
                    FluentTreeItem(
                      value: 'pinned-item-2',
                      label: Text('Pinned item 2'),
                    ),
                    FluentTreeItem(
                      value: 'pinned-item-3',
                      label: Text('Pinned item 3'),
                    ),
                  ],
                ),
                FluentTreeItem(
                  value: 'people',
                  label: const Text('People'),
                  children: <FluentTreeItem>[
                    for (final String name in _people)
                      FluentTreeItem(value: 'person-$name', label: Text(name)),
                    if (_isLoading)
                      const FluentTreeItem(
                        value: 'loading-people',
                        label: FluentSpinner(
                          size: FluentSpinnerSize.tiny,
                          semanticLabel: 'Loading more people',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      // Upstream's `screenReadersOnly` live region: announced, never drawn.
      Semantics(liveRegion: true, label: _ariaMessage, child: const SizedBox()),
    ],
  );
}
// #enddocregion components-tree--infinite-scrolling

// #docregion components-tree--virtualization
// Upstream recomposes `FlatTree` around react-window's `FixedSizeList`.
// `FluentTree` builds only the rows its open set makes visible — a closed
// branch costs nothing — and Flutter's widgets layer has no drop-in virtualiser
// for a component that lays itself out as a column, so the 600 items are real
// and the 300x300 viewport simply scrolls them.
Widget _virtualization(BuildContext context) => SizedBox(
  width: 300,
  height: 300,
  child: SingleChildScrollView(
    child: FluentTree(
      semanticLabel: 'Virtualization',
      items: <FluentTreeItem>[
        FluentTreeItem(
          value: 'flatTreeItem_lvl-1_item-1',
          label: const Text('Level 1, item 1'),
          children: <FluentTreeItem>[
            for (int i = 0; i < 300; i++)
              FluentTreeItem(
                value: 'flatTreeItem_lvl-1_item-1--child:$i',
                label: Text('Item ${i + 1}'),
              ),
          ],
        ),
        FluentTreeItem(
          value: 'flatTreeItem_lvl-1_item-2',
          label: const Text('Level 1, item 2'),
          children: <FluentTreeItem>[
            for (int index = 0; index < 300; index++)
              FluentTreeItem(
                value: 'flatTreeItem_lvl-1_item-2--child:$index',
                label: Text('Item ${index + 1}'),
              ),
          ],
        ),
      ],
    ),
  ),
);
// #enddocregion components-tree--virtualization

// #docregion components-tree--drag-and-drop
// Upstream reaches for `@dnd-kit`, whose `useSortable` hook turns each leaf into
// a drag handle. Flutter's widgets layer has `Draggable` but no sortable-list
// primitive, and `FluentTree` lays its own rows out, so the same eight items
// are reordered from the row's trailing actions instead — the story, a tree
// whose leaves can be rearranged, still works.
Widget _dragAndDrop(BuildContext context) => const _DragAndDrop();

class _DragAndDrop extends StatefulWidget {
  const _DragAndDrop();

  @override
  State<_DragAndDrop> createState() => _DragAndDropState();
}

class _DragAndDropState extends State<_DragAndDrop> {
  List<String> _items = <String>[
    'Sortable item 1',
    'Sortable item 2',
    'Sortable item 3',
    'Sortable item 4',
    'Sortable item 5',
    'Sortable item 6',
    'Sortable item 7',
    'Sortable item 8',
  ];

  void _sortItems(int from, int to) {
    setState(() {
      final List<String> next = <String>[..._items];
      next.insert(to, next.removeAt(from));
      _items = next;
    });
  }

  @override
  Widget build(BuildContext context) => FluentTree(
    semanticLabel: 'Drag And Drop',
    defaultOpenItems: const <Object>{'1'},
    items: <FluentTreeItem>[
      FluentTreeItem(
        value: '1',
        label: const Text('Parent item'),
        children: <FluentTreeItem>[
          for (int index = 0; index < _items.length; index++)
            FluentTreeItem(
              value: '1-${index + 1}',
              actions: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FluentButton.icon(
                    icon: const Icon(FluentIcons.arrow_up_20_regular),
                    semanticLabel: 'Move up',
                    appearance: FluentButtonAppearance.subtle,
                    onPressed: index == 0
                        ? null
                        : () => _sortItems(index, index - 1),
                  ),
                  FluentButton.icon(
                    icon: const Icon(FluentIcons.arrow_down_20_regular),
                    semanticLabel: 'Move down',
                    appearance: FluentButtonAppearance.subtle,
                    onPressed: index == _items.length - 1
                        ? null
                        : () => _sortItems(index, index + 1),
                  ),
                ],
              ),
              label: Text(_items[index]),
            ),
        ],
      ),
    ],
  );
}
// #enddocregion components-tree--drag-and-drop

// #docregion components-tree--motion-custom
// Upstream drives each subtree's `collapseMotion` slot from these controls.
// `FluentTree` exposes no motion hook, so the controls are live and the collapse
// animation is not. `color="colorful"` also has no counterpart: `FluentAvatar`
// has the palette families but picks none from a name, so the avatarless
// personas keep the neutral fill.
Widget _motionCustom(BuildContext context) => const _MotionCustom();

class _MotionPersona {
  const _MotionPersona({
    required this.name,
    required this.secondaryText,
    required this.status,
    this.image,
  });

  final String name;
  final String secondaryText;
  final FluentPresenceStatus status;
  final ImageProvider<Object>? image;
}

const List<_MotionPersona> _motionPersonaData = <_MotionPersona>[
  _MotionPersona(
    name: 'Kevin Sturgis',
    secondaryText: 'Available',
    status: FluentPresenceStatus.available,
    image: AssetImage('assets/storybook/persona-male.png'),
  ),
  _MotionPersona(
    name: 'Sarah Chen',
    secondaryText: 'In a meeting',
    status: FluentPresenceStatus.busy,
  ),
  _MotionPersona(
    name: 'Jessica Brown',
    secondaryText: 'Do not disturb',
    status: FluentPresenceStatus.busy,
    image: AssetImage('assets/storybook/persona-female.png'),
  ),
  _MotionPersona(
    name: 'Emily Johnson',
    secondaryText: 'Available',
    status: FluentPresenceStatus.available,
  ),
  _MotionPersona(
    name: 'David Kim',
    secondaryText: 'Offline',
    status: FluentPresenceStatus.offline,
  ),
  _MotionPersona(
    name: 'Michael Rodriguez',
    secondaryText: 'Away',
    status: FluentPresenceStatus.away,
    image: AssetImage('assets/storybook/persona-male.png'),
  ),
];

List<FluentTreeItem> _motionTeam(
  String prefix,
  Iterable<_MotionPersona> people,
) => <FluentTreeItem>[
  for (final _MotionPersona person in people)
    FluentTreeItem(
      value: '$prefix/${person.name}',
      label: FluentPersona(
        name: person.name,
        image: person.image,
        status: person.status,
        secondary: Text(person.secondaryText),
      ),
    ),
];

class _MotionCustom extends StatefulWidget {
  const _MotionCustom();

  @override
  State<_MotionCustom> createState() => _MotionCustomState();
}

class _MotionCustomState extends State<_MotionCustom> {
  double _duration = 1000;
  bool _animateOpacity = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentField(
        label: Text('Duration: ${_duration.round()}ms'),
        child: FluentSlider(
          min: 100,
          max: 2000,
          step: 50,
          value: _duration,
          onChanged: (double value) => setState(() => _duration = value),
        ),
      ),
      const SizedBox(height: 12),
      FluentSwitch(
        checked: _animateOpacity,
        label: const Text('Animate opacity'),
        onChanged: (bool value) => setState(() => _animateOpacity = value),
      ),
      const SizedBox(height: 16),
      FluentTree(
        semanticLabel: 'Motion Custom',
        items: <FluentTreeItem>[
          FluentTreeItem(
            value: 'team-a',
            label: const Text('Team A'),
            children: _motionTeam('team-a', _motionPersonaData.take(3)),
          ),
          FluentTreeItem(
            value: 'team-b',
            label: const Text('Team B'),
            children: _motionTeam('team-b', _motionPersonaData.skip(3)),
          ),
          FluentTreeItem(
            value: 'team-c',
            label: const Text('Team C'),
            children: _motionTeam('team-c', _motionPersonaData),
          ),
        ],
      ),
    ],
  );
}

// #enddocregion components-tree--motion-custom
