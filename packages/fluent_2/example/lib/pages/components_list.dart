import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The List docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage listPage = DocsPage(
  id: 'components-list',
  title: 'List',
  description:
      'The List is a component for rendering set of vertically stacked items '
      '(other layouts are being discussed). These items can be focusable, '
      'selectable, have one primary action and one or more secondary actions. '
      'There are 2 basic use cases for List, based on the elements it '
      'contains: (TL;DR at the end)',
  source: 'lib/pages/components_list.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-list--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-list--single-action',
      title: 'Single Action',
      description:
          'When the list item should have a custom primary action on it, you '
          'can pass the onAction prop to the ListItem component. This callback '
          'will also be automatically called when the user presses the Enter '
          'or Space key on the list item. To learn more about what event '
          'triggered the action, you can check the '
          'event.details.originalEvent. To enable keyboard navigation between '
          'the list items, the navigationMode prop should be set to items.',
      builder: _singleAction,
    ),
    DocsSection(
      id: 'components-list--single-action-selection',
      title: 'Single Action Selection',
      description:
          'Any List can be selectable. You have an option to control the '
          'selection state yourself or let the List manage it for you. You can '
          'pass selectionMode prop with value "single" or "multiselect" to the '
          'List component to get support for selection. The items can be '
          'toggled by clicking on the list item, or pressing Spacebar or Enter '
          'when the item is focused. Keyboard navigation is automatically '
          'enabled and navigationMode is set to items. Also this example only '
          "has one action in the list item, and it's for toggling the "
          'selection. The roles for this one are listbox and option.',
      builder: _singleActionSelection,
    ),
    DocsSection(
      id: 'components-list--single-action-selection-controlled',
      title: 'Single Action Selection Controlled',
      description:
          'This example shows how to use the selectedItems and '
          'onSelectionChange props to control the selection state of the List '
          'and keep track of it in the parent component. This is more in line '
          'with how we expect the selection to be used in production '
          'environment.',
      builder: _singleActionSelectionControlled,
    ),
    DocsSection(
      id: 'components-list--single-action-selection-different-primary',
      title: 'Single Action Selection Different Primary',
      description:
          'This example is similar to the previous one, but it implements a '
          'custom primary action on ListItem, allowing us to trigger a '
          'different action than the selection when the user clicks on the '
          'list item or presses Enter. This is useful when you want to have a '
          'primary action on the list item, but still want to allow the user '
          'to select it. To change the default action on the ListItem (when '
          'user clicks on it or presses Enter), you can use the onAction prop. '
          'By calling event.preventDefault() in the onAction callback, you can '
          'prevent the default action (toggling the selection) from happening. '
          'This way, you can perform a completely custom action. In this '
          'example, the custom action is an alert that triggers when the user '
          'clicks on the list item or presses Enter. The selection can still '
          'be toggled by clicking on the checkbox or pressing Space when the '
          'item is focused.',
      builder: _singleActionSelectionDifferentPrimary,
    ),
    DocsSection(
      id: 'components-list--multiple-actions-with-primary',
      title: 'Multiple Actions With Primary',
      description:
          "Base item with multiple actions. Doesn't support selection, but the "
          'list items have a primary action that can be triggered by clicking '
          'on the item or pressing Enter. To make the navigation work '
          'properly, the navigationMode prop should be set to composite. This '
          'will allow the user to navigate inside of the list items by '
          'pressing the Right Arrow key. It also sets the grid role '
          'automatically to the list. In cases where grid role is used, it is '
          'important that every direct children of ListItem has role gridcell. '
          'Also each focusable item should be in its own "gridcell". This '
          'makes sure the screen readers work properly.',
      builder: _multipleActionsWithPrimary,
    ),
    DocsSection(
      id: 'components-list--multiple-actions-selection',
      title: 'Multiple Actions Selection',
      description:
          "Item with multiple actions. It has selection enabled, which is also "
          "it's primary action. The selection can be toggled by clicking on "
          'the item or pressing the Space key. Because the selection is the '
          'action on the item, to properly narrate the state of selection we '
          'are using the role grid / row / gridcell here to properly announce '
          'when the selection on the item is toggled. To enable the user to '
          'navigate inside of the list items by pressing the RightArrow key, '
          'the navigationMode prop should be set to composite.',
      builder: _multipleActionsSelection,
    ),
    DocsSection(
      id: 'components-list--multiple-actions-different-primary',
      title: 'Multiple Actions Different Primary',
      description:
          'Similar to previous example, but this one implements a custom '
          'onAction prop on the ListItem, allowing us to trigger a different '
          'action than the selection when the user clicks on the list item or '
          'presses Enter. The primary action can be triggered by clicking on '
          'the list item or pressing Enter. The selection can be toggled by '
          'clicking on the checkbox or pressing Space when the item is '
          'focused. To focus on the secondary actions, you can navigate '
          'between them by using left and right arrows.',
      builder: _multipleActionsDifferentPrimary,
    ),
    DocsSection(
      id: 'components-list--virtualized-list',
      title: 'Virtualized List',
      description:
          'When creating a list of large size, one way of making sure you are '
          'getting the best performance is to use virtualization. In this '
          'example we are leveraging the react-window package. Please note '
          'that if the virtualized list contains non-actionable list items, '
          'scrolling should be achieved by using the tabIndex={0} property on '
          'the List. It is important to manually set aria-setsize and '
          'aria-posinset attributes on the list items, since the virualization '
          'will only render the visible items. Relying on the DOM state for '
          'these attributes will not work.',
      builder: _virtualizedList,
    ),
    DocsSection(
      id: 'components-list--virtualized-list-with-actionable-items',
      title: 'Virtualized List With Actionable Items',
      description:
          'Virtualized list can also be used with interactive elements.',
      builder: _virtualizedListWithActionableItems,
    ),
    DocsSection(
      id: 'components-list--list-active-element',
      title: 'List Active Element',
      description:
          'You can use selection and custom styles to show the active element '
          'in a different way. This is useful for scenarios where you want to '
          'show the details of the selected item, for example. In this '
          'example, we are also demonstrating how the onFocus prop can be '
          'utilized to change the selected item immediately upon receiving '
          'focus. This allows us to show the details of the selected item in '
          'the right panel as user navigates through the list with the '
          'keyboard.',
      builder: _listActiveElement,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'items',
      type: 'List<FluentListItem<T>>',
      description: 'The rows, in reading order.',
    ),
    PropRow(
      name: 'selectedValues',
      type: 'Set<T>',
      defaultValue: '{}',
      description: 'The values currently selected.',
    ),
    PropRow(
      name: 'onSelectionChange',
      type: 'ValueChanged<Set<T>>?',
      defaultValue: 'null',
      description:
          'Invoked with the whole new selection. Null makes every row inert.',
    ),
    PropRow(
      name: 'selection',
      type: 'FluentListSelection',
      defaultValue: 'FluentListSelection.none',
      description:
          'Which affordance each row draws, and therefore whether selecting is '
          'additive.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentListItemSize',
      defaultValue: 'FluentListItemSize.medium',
      description: 'Row height and title type ramp for every row.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentListItemStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults for every row. A row\'s '
          'own style is merged after this one.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Announced by assistive technology as the name of the list.',
    ),
  ],
);

// #docregion components-list--default
Widget _default(BuildContext context) => const FluentList<String>(
  items: <FluentListItem<String>>[
    FluentListItem<String>(value: 'Asia', child: Text('Asia')),
    FluentListItem<String>(value: 'Africa', child: Text('Africa')),
    FluentListItem<String>(value: 'Europe', child: Text('Europe')),
    FluentListItem<String>(
      value: 'North America',
      child: Text('North America'),
    ),
    FluentListItem<String>(
      value: 'South America',
      child: Text('South America'),
    ),
    FluentListItem<String>(
      value: 'Australia/Oceania',
      child: Text('Australia/Oceania'),
    ),
    FluentListItem<String>(value: 'Antarctica', child: Text('Antarctica')),
  ],
);
// #enddocregion components-list--default

// #docregion components-list--single-action
Widget _singleAction(BuildContext context) => const _SingleAction();

class _SingleAction extends StatefulWidget {
  const _SingleAction();

  @override
  State<_SingleAction> createState() => _SingleActionState();
}

class _SingleActionState extends State<_SingleAction> {
  static const List<String> _names = <String>[
    'Melda Bevel',
    'Demetra Manwaring',
    'Eusebia Stufflebeam',
    'Israel Rabin',
    'Bart Merrill',
    'Sonya Farner',
  ];

  // Upstream gives each `ListItem` its own `onAction`. Ours has no per-row
  // callback: the list owns every gesture, so `onSelectionChange` is the action
  // hook and the selection it hands back is deliberately never kept. Upstream
  // calls `alert()`; the action is reported in place instead.
  String? _message;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: <Widget>[
      FluentList<String>(
        onSelectionChange: (Set<String> _) =>
            setState(() => _message = 'Triggered custom action!'),
        items: <FluentListItem<String>>[
          for (final String name in _names)
            FluentListItem<String>(
              value: name,
              semanticLabel: '$name, available',
              child: FluentPersona(
                name: name,
                secondary: const Text('Available'),
                status: FluentPresenceStatus.available,
                image: const AssetImage('assets/storybook/persona-male.png'),
              ),
            ),
        ],
      ),
      if (_message != null) Text(_message!),
    ],
  );
}
// #enddocregion components-list--single-action

// #docregion components-list--single-action-selection
Widget _singleActionSelection(BuildContext context) =>
    const _SingleActionSelection();

class _SingleActionSelection extends StatefulWidget {
  const _SingleActionSelection();

  @override
  State<_SingleActionSelection> createState() => _SingleActionSelectionState();
}

class _SingleActionSelectionState extends State<_SingleActionSelection> {
  static const List<String> _names = <String>[
    'Melda Bevel',
    'Demetra Manwaring',
    'Eusebia Stufflebeam',
    'Israel Rabin',
    'Bart Merrill',
    'Sonya Farner',
  ];

  // Upstream's `defaultSelectedItems` leaves the List uncontrolled. FluentList
  // is always controlled, so the initial selection lives here.
  Set<String> _selected = <String>{'Demetra Manwaring', 'Bart Merrill'};

  @override
  Widget build(BuildContext context) => FluentList<String>(
    semanticLabel: 'People example',
    selection: FluentListSelection.checkbox,
    selectedValues: _selected,
    onSelectionChange: (Set<String> next) => setState(() => _selected = next),
    items: <FluentListItem<String>>[
      for (int i = 0; i < _names.length; i++)
        FluentListItem<String>(
          value: _names[i],
          semanticLabel: _names[i],
          // Example of disabling selection for last 2 items. Upstream's
          // `disabledSelection` only refuses the toggle; `enabled: false` also
          // takes the row out of the arrow order and paints the disabled ramp.
          enabled: i <= 3,
          child: FluentPersona(
            name: _names[i],
            secondary: const Text('Available'),
            status: FluentPresenceStatus.available,
            image: const AssetImage('assets/storybook/persona-male.png'),
          ),
        ),
    ],
  );
}
// #enddocregion components-list--single-action-selection

// #docregion components-list--single-action-selection-controlled
Widget _singleActionSelectionControlled(BuildContext context) =>
    const _SingleActionSelectionControlled();

class _SingleActionSelectionControlled extends StatefulWidget {
  const _SingleActionSelectionControlled();

  @override
  State<_SingleActionSelectionControlled> createState() =>
      _SingleActionSelectionControlledState();
}

class _SingleActionSelectionControlledState
    extends State<_SingleActionSelectionControlled> {
  static const List<String> _names = <String>[
    'Melda Bevel',
    'Demetra Manwaring',
    'Eusebia Stufflebeam',
    'Israel Rabin',
    'Bart Merrill',
    'Sonya Farner',
  ];

  Set<String> _selectedItems = <String>{'Demetra Manwaring', 'Bart Merrill'};

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: <Widget>[
      FluentButton(
        onPressed: () => setState(() => _selectedItems = <String>{..._names}),
        child: const Text('Select all'),
      ),
      FluentList<String>(
        semanticLabel: 'People example',
        selection: FluentListSelection.checkbox,
        selectedValues: _selectedItems,
        onSelectionChange: (Set<String> next) =>
            setState(() => _selectedItems = next),
        items: <FluentListItem<String>>[
          for (final String name in _names)
            FluentListItem<String>(
              value: name,
              semanticLabel: name,
              child: FluentPersona(
                name: name,
                secondary: const Text('Available'),
                status: FluentPresenceStatus.available,
                image: const AssetImage('assets/storybook/persona-male.png'),
              ),
            ),
        ],
      ),
    ],
  );
}
// #enddocregion components-list--single-action-selection-controlled

// #docregion components-list--single-action-selection-different-primary
Widget _singleActionSelectionDifferentPrimary(BuildContext context) =>
    const _SingleActionSelectionDifferentPrimary();

class _SingleActionSelectionDifferentPrimary extends StatefulWidget {
  const _SingleActionSelectionDifferentPrimary();

  @override
  State<_SingleActionSelectionDifferentPrimary> createState() =>
      _SingleActionSelectionDifferentPrimaryState();
}

class _SingleActionSelectionDifferentPrimaryState
    extends State<_SingleActionSelectionDifferentPrimary> {
  static const List<String> _names = <String>[
    'Melda Bevel',
    'Demetra Manwaring',
    'Eusebia Stufflebeam',
    'Israel Rabin',
    'Bart Merrill',
    'Sonya Farner',
  ];

  Set<String> _selectedItems = <String>{'Demetra Manwaring', 'Bart Merrill'};
  String? _message;

  // Upstream separates the two gestures: clicking the checkbox selects,
  // clicking the row runs `onAction` and calls `preventDefault()`. Our row has
  // one gesture — the checkbox is a display of the row's state, not a second
  // control — so the custom action runs *alongside* the selection change
  // rather than instead of it.
  void _onAction(Set<String> next) {
    final Set<String> changed = next
        .difference(_selectedItems)
        .union(_selectedItems.difference(next));
    setState(() {
      _selectedItems = next;
      _message = 'Triggered custom action on ${changed.first}';
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: <Widget>[
      FluentList<String>(
        semanticLabel: 'People example',
        selection: FluentListSelection.checkbox,
        selectedValues: _selectedItems,
        onSelectionChange: _onAction,
        items: <FluentListItem<String>>[
          for (int index = 0; index < _names.length; index++)
            FluentListItem<String>(
              value: _names[index],
              semanticLabel: _names[index],
              enabled: index != 2,
              child: FluentPersona(
                name: _names[index],
                secondary: const Text('Available'),
                status: FluentPresenceStatus.available,
                image: const AssetImage('assets/storybook/persona-male.png'),
              ),
            ),
        ],
      ),
      if (_message != null) Text(_message!),
    ],
  );
}
// #enddocregion components-list--single-action-selection-different-primary

// #docregion components-list--multiple-actions-with-primary
Widget _multipleActionsWithPrimary(BuildContext context) =>
    const _MultipleActionsWithPrimary();

class _MultipleActionsWithPrimary extends StatefulWidget {
  const _MultipleActionsWithPrimary();

  @override
  State<_MultipleActionsWithPrimary> createState() =>
      _MultipleActionsWithPrimaryState();
}

class _MultipleActionsWithPrimaryState
    extends State<_MultipleActionsWithPrimary> {
  static const List<String> _values = <String>[
    'card-1',
    'card-2',
    'card-3',
    'card-4',
    'card-5',
    'card-6',
    'card-7',
    'card-8',
    'card-9',
  ];

  String? _message;

  void _report(String message) => setState(() => _message = message);

  // Upstream lays the row out as a CSS grid — preview across the top, then
  // header / action / secondary action. FluentListItem's slots are a fixed row,
  // so the card is built inside the row's own content slot with FluentCard,
  // which is where our border, radius and inset come from.
  FluentListItem<String> _card(String value) {
    final FluentTypography type = FluentTheme.of(context).typography;
    final FluentColors colors = FluentTheme.of(context).colors;

    return FluentListItem<String>(
      value: value,
      semanticLabel: value,
      child: FluentCard(
        appearance: FluentCardAppearance.outline,
        size: FluentCardSize.small,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: const Image(
                image: AssetImage('assets/storybook/image.png'),
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            Row(
              spacing: 8,
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Example List Item', style: type.body1Strong),
                      Text(
                        'You created 53m ago',
                        style: type.caption1.copyWith(
                          color: colors.neutralForeground3,
                        ),
                      ),
                    ],
                  ),
                ),
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  semanticLabel: 'Install',
                  onPressed: () => _report('Installing!'),
                  child: const Text('Install'),
                ),
                FluentMenu(
                  items: <FluentMenuItem>[
                    FluentMenuItem(
                      label: const Text('About'),
                      onPressed: () => _report('Clicked menu item'),
                    ),
                    FluentMenuItem(
                      label: const Text('Uninstall'),
                      onPressed: () => _report('Clicked menu item'),
                    ),
                    FluentMenuItem(
                      label: const Text('Block'),
                      onPressed: () => _report('Clicked menu item'),
                    ),
                  ],
                  builder: (BuildContext context, VoidCallback toggle) =>
                      FluentButton.icon(
                        icon: const Icon(
                          FluentIcons.more_horizontal_20_regular,
                        ),
                        semanticLabel: 'More actions',
                        appearance: FluentButtonAppearance.transparent,
                        onPressed: toggle,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: <Widget>[
      SizedBox(
        width: 300,
        child: FluentList<String>(
          // The list's own gesture is the primary action here; nothing is kept
          // selected, which is upstream's `onAction` plus `preventDefault()`.
          onSelectionChange: (Set<String> _) =>
              _report('Triggered custom action!'),
          items: <FluentListItem<String>>[
            for (final String value in _values) _card(value),
          ],
        ),
      ),
      if (_message != null) Text(_message!),
    ],
  );
}
// #enddocregion components-list--multiple-actions-with-primary

// #docregion components-list--multiple-actions-selection
Widget _multipleActionsSelection(BuildContext context) =>
    const _MultipleActionsSelection();

class _MultipleActionsSelection extends StatefulWidget {
  const _MultipleActionsSelection();

  @override
  State<_MultipleActionsSelection> createState() =>
      _MultipleActionsSelectionState();
}

class _MultipleActionsSelectionState extends State<_MultipleActionsSelection> {
  static const List<String> _values = <String>[
    'card-1',
    'card-2',
    'card-3',
    'card-4',
    'card-5',
    'card-6',
    'card-7',
    'card-8',
    'card-9',
  ];

  Set<String> _selectedItems = <String>{};
  String? _message;

  void _report(String message) => setState(() => _message = message);

  // Upstream lays the row out as a CSS grid — preview across the top, then
  // header / action / secondary action — and floats the checkmark over the
  // preview's top left corner. FluentListItem's slots are a fixed row, so the
  // card is built inside the row's content slot and the checkbox keeps its own
  // leading column.
  FluentListItem<String> _card(String value) {
    final FluentTypography type = FluentTheme.of(context).typography;
    final FluentColors colors = FluentTheme.of(context).colors;

    return FluentListItem<String>(
      value: value,
      semanticLabel: value,
      child: FluentCard(
        appearance: FluentCardAppearance.outline,
        size: FluentCardSize.small,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: const Image(
                image: AssetImage('assets/storybook/image.png'),
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            Row(
              spacing: 8,
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Example List Item', style: type.body1Strong),
                      Text(
                        'You created 53m ago',
                        style: type.caption1.copyWith(
                          color: colors.neutralForeground3,
                        ),
                      ),
                    ],
                  ),
                ),
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  semanticLabel: 'Install',
                  onPressed: () => _report('Installing!'),
                  child: const Text('Install'),
                ),
                FluentMenu(
                  items: <FluentMenuItem>[
                    FluentMenuItem(
                      label: const Text('About'),
                      onPressed: () => _report('Clicked menu item'),
                    ),
                    FluentMenuItem(
                      label: const Text('Uninstall'),
                      onPressed: () => _report('Clicked menu item'),
                    ),
                    FluentMenuItem(
                      label: const Text('Block'),
                      onPressed: () => _report('Clicked menu item'),
                    ),
                  ],
                  builder: (BuildContext context, VoidCallback toggle) =>
                      FluentButton.icon(
                        icon: const Icon(
                          FluentIcons.more_horizontal_20_regular,
                        ),
                        semanticLabel: 'More actions',
                        appearance: FluentButtonAppearance.transparent,
                        onPressed: toggle,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: <Widget>[
      SizedBox(
        width: 300,
        child: FluentList<String>(
          selection: FluentListSelection.checkbox,
          selectedValues: _selectedItems,
          onSelectionChange: (Set<String> next) =>
              setState(() => _selectedItems = next),
          items: <FluentListItem<String>>[
            for (final String value in _values) _card(value),
          ],
        ),
      ),
      if (_message != null) Text(_message!),
    ],
  );
}
// #enddocregion components-list--multiple-actions-selection

// #docregion components-list--multiple-actions-different-primary
Widget _multipleActionsDifferentPrimary(BuildContext context) =>
    const _MultipleActionsDifferentPrimary();

class _MultipleActionsDifferentPrimary extends StatefulWidget {
  const _MultipleActionsDifferentPrimary();

  @override
  State<_MultipleActionsDifferentPrimary> createState() =>
      _MultipleActionsDifferentPrimaryState();
}

class _MultipleActionsDifferentPrimaryState
    extends State<_MultipleActionsDifferentPrimary> {
  static const List<String> _values = <String>[
    'card-1',
    'card-2',
    'card-3',
    'card-4',
    'card-5',
    'card-6',
    'card-7',
    'card-8',
    'card-9',
  ];

  Set<String> _selectedItems = <String>{};
  String? _message;

  void _report(String message) => setState(() => _message = message);

  // Upstream separates the two gestures: the checkmark toggles selection, the
  // row runs `onAction` and calls `preventDefault()`. Our row has one gesture —
  // the checkbox is a display of the row's state, not a second control — so the
  // custom action runs *alongside* the selection change rather than instead of
  // it.
  void _onAction(Set<String> next) {
    final Set<String> changed = next
        .difference(_selectedItems)
        .union(_selectedItems.difference(next));
    setState(() {
      _selectedItems = next;
      _message = 'Triggered custom action on ${changed.first}';
    });
  }

  FluentListItem<String> _card(String value) {
    final FluentTypography type = FluentTheme.of(context).typography;
    final FluentColors colors = FluentTheme.of(context).colors;

    return FluentListItem<String>(
      value: value,
      semanticLabel: value,
      child: FluentCard(
        appearance: FluentCardAppearance.outline,
        size: FluentCardSize.small,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: const Image(
                image: AssetImage('assets/storybook/image.png'),
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            Row(
              spacing: 8,
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Example List Item', style: type.body1Strong),
                      Text(
                        'You created 53m ago',
                        style: type.caption1.copyWith(
                          color: colors.neutralForeground3,
                        ),
                      ),
                    ],
                  ),
                ),
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  semanticLabel: 'Install',
                  onPressed: () => _report('Installing!'),
                  child: const Text('Install'),
                ),
                FluentMenu(
                  items: <FluentMenuItem>[
                    FluentMenuItem(
                      label: const Text('About'),
                      onPressed: () => _report('Clicked menu item'),
                    ),
                    FluentMenuItem(
                      label: const Text('Uninstall'),
                      onPressed: () => _report('Clicked menu item'),
                    ),
                    FluentMenuItem(
                      label: const Text('Block'),
                      onPressed: () => _report('Clicked menu item'),
                    ),
                  ],
                  builder: (BuildContext context, VoidCallback toggle) =>
                      FluentButton.icon(
                        icon: const Icon(
                          FluentIcons.more_horizontal_20_regular,
                        ),
                        semanticLabel: 'More actions',
                        appearance: FluentButtonAppearance.transparent,
                        onPressed: toggle,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: <Widget>[
      SizedBox(
        width: 300,
        child: FluentList<String>(
          selection: FluentListSelection.checkbox,
          selectedValues: _selectedItems,
          onSelectionChange: _onAction,
          items: <FluentListItem<String>>[
            for (final String value in _values) _card(value),
          ],
        ),
      ),
      if (_message != null) Text(_message!),
    ],
  );
}
// #enddocregion components-list--multiple-actions-different-primary

// #docregion components-list--virtualized-list
// Upstream hands the rows to `react-window`'s `FixedSizeList`. FluentList
// builds every row into one Column — it has no virtualising constructor — so
// the whole list is laid out and scrolled inside a 400 high viewport instead.
Widget _virtualizedList(BuildContext context) {
  const List<String> countries = <String>[
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua & Deps',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina',
    'Burundi',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Cape Verde',
    'Central African Rep',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo',
    'Congo {Democratic Rep}',
    'Costa Rica',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'East Timor',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland {Republic}',
    'Israel',
    'Italy',
    'Ivory Coast',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Korea North',
    'Korea South',
    'Kosovo',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Macedonia',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar, {Burma}',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russian Federation',
    'Rwanda',
    'St Kitts & Nevis',
    'St Lucia',
    'Saint Vincent & the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome & Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Swaziland',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Togo',
    'Tonga',
    'Trinidad & Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe',
  ];

  return SizedBox(
    height: 400,
    child: SingleChildScrollView(
      child: FluentList<String>(
        semanticLabel: 'Countries',
        size: FluentListItemSize.small,
        items: <FluentListItem<String>>[
          for (final String country in countries)
            FluentListItem<String>(value: country, child: Text(country)),
        ],
      ),
    ),
  );
}
// #enddocregion components-list--virtualized-list

// #docregion components-list--virtualized-list-with-actionable-items
Widget _virtualizedListWithActionableItems(BuildContext context) =>
    const _VirtualizedListWithActionableItems();

class _VirtualizedListWithActionableItems extends StatefulWidget {
  const _VirtualizedListWithActionableItems();

  @override
  State<_VirtualizedListWithActionableItems> createState() =>
      _VirtualizedListWithActionableItemsState();
}

class _VirtualizedListWithActionableItemsState
    extends State<_VirtualizedListWithActionableItems> {
  // Upstream hands the rows to `react-window`'s `FixedSizeList`. FluentList
  // builds every row into one Column — it has no virtualising constructor — so
  // the whole list is laid out and scrolled inside a 400 high viewport instead.
  static const List<String> _countries = <String>[
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua & Deps',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina',
    'Burundi',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Cape Verde',
    'Central African Rep',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo',
    'Congo {Democratic Rep}',
    'Costa Rica',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'East Timor',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland {Republic}',
    'Israel',
    'Italy',
    'Ivory Coast',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Korea North',
    'Korea South',
    'Kosovo',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Macedonia',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar, {Burma}',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russian Federation',
    'Rwanda',
    'St Kitts & Nevis',
    'St Lucia',
    'Saint Vincent & the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome & Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Swaziland',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Togo',
    'Tonga',
    'Trinidad & Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe',
  ];

  String? _message;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: <Widget>[
      SizedBox(
        height: 400,
        child: SingleChildScrollView(
          child: FluentList<String>(
            semanticLabel: 'Countries',
            size: FluentListItemSize.small,
            // The list's own gesture is the row's action; nothing is kept
            // selected, which is upstream's `onAction`.
            onSelectionChange: (Set<String> next) =>
                setState(() => _message = next.first),
            items: <FluentListItem<String>>[
              for (final String country in _countries)
                FluentListItem<String>(value: country, child: Text(country)),
            ],
          ),
        ),
      ),
      if (_message != null) Text(_message!),
    ],
  );
}
// #enddocregion components-list--virtualized-list-with-actionable-items

// #docregion components-list--list-active-element
Widget _listActiveElement(BuildContext context) => const _ListActiveElement();

class _ListActiveElement extends StatefulWidget {
  const _ListActiveElement();

  @override
  State<_ListActiveElement> createState() => _ListActiveElementState();
}

class _ListActiveElementState extends State<_ListActiveElement> {
  static const List<String> _names = <String>[
    'Melda Bevel',
    'Demetra Manwaring',
    'Eusebia Stufflebeam',
    'Israel Rabin',
    'Bart Merrill',
    'Sonya Farner',
    'Kristan Cable',
  ];

  Set<String> _selectedItems = <String>{'Melda Bevel'};
  String? _message;

  // Upstream is `selectionMode="single"` with `checkmark={null}` and a custom
  // selected background — which is FluentListSelection.none plus a selected
  // value, since a `none` list still paints the selected fill. `none` toggles
  // additively, so the row that was just added is taken as the whole selection.
  // Upstream also selects on focus; FluentListItem exposes no focus callback,
  // so keyboard focus moves without selecting.
  void _onSelectionChange(Set<String> next) {
    final Set<String> added = next.difference(_selectedItems);
    if (added.isEmpty) return;
    setState(() => _selectedItems = added);
  }

  @override
  Widget build(BuildContext context) {
    final FluentTypography type = FluentTheme.of(context).typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: <Widget>[
        FluentList<String>(
          selectedValues: _selectedItems,
          onSelectionChange: _onSelectionChange,
          items: <FluentListItem<String>>[
            for (final String name in _names)
              FluentListItem<String>(
                value: name,
                semanticLabel: name,
                trailing: FluentButton.icon(
                  icon: const Icon(FluentIcons.mic_16_regular),
                  semanticLabel: 'Mute $name',
                  size: FluentButtonSize.small,
                  onPressed: () => setState(() => _message = 'Muting $name'),
                ),
                child: FluentPersona(
                  name: name,
                  secondary: const Text('Available'),
                  status: FluentPresenceStatus.available,
                  image: const AssetImage('assets/storybook/persona-male.png'),
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Currently selected:'),
            Text(_selectedItems.first, style: type.body1Strong),
          ],
        ),
        if (_message != null) Text(_message!),
      ],
    );
  }
}

// #enddocregion components-list--list-active-element
