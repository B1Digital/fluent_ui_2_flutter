import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The TabList docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage tablistPage = DocsPage(
  id: 'components-tablist',
  title: 'TabList',
  description:
      'A tab list provides single selection from tabs. When a tab is selected, '
      'the application displays content associated with the selected tab and '
      'hides other content. Each tab typically contains a text header and '
      'often includes an icon.',
  source: 'lib/pages/components_tablist.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-tablist--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-tablist--horizontal',
      title: 'Horizontal',
      description:
          'The tabs within a tab list are arranged horzontally by default.',
      builder: _horizontal,
    ),
    DocsSection(
      id: 'components-tablist--vertical',
      title: 'Vertical',
      description:
          'The tabs within a tab list can be arranged vertically. The default '
          'is false.',
      builder: _vertical,
    ),
    DocsSection(
      id: 'components-tablist--appearance',
      title: 'Appearance',
      description:
          'A tab list can have a transparent, subtle, subtle-circular and '
          'filled-circular appearance. The default is transparent.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-tablist--disabled',
      title: 'Disabled',
      description:
          'A tab list can disable interaction for all its tabs. The default is '
          'false. Individual tabs can also be disabled.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-tablist--size-small',
      title: 'Size Small',
      description: 'A tab list can have small tabs.',
      builder: _sizeSmall,
    ),
    DocsSection(
      id: 'components-tablist--size-medium',
      title: 'Size Medium',
      description: 'A tab list can have medium tabs (default).',
      builder: _sizeMedium,
    ),
    DocsSection(
      id: 'components-tablist--size-large',
      title: 'Size Large',
      description: 'A tab list can have large tabs.',
      builder: _sizeLarge,
    ),
    DocsSection(
      id: 'components-tablist--with-icon',
      title: 'With Icon',
      description:
          'A tab has an icon slot to display an icon before the tab content.',
      builder: _withIcon,
    ),
    DocsSection(
      id: 'components-tablist--icon-only',
      title: 'Icon Only',
      description: 'Tabs can have an icon slot filled and no content..',
      builder: _iconOnly,
    ),
    DocsSection(
      id: 'components-tablist--select-tab-on-focus',
      title: 'Select Tab On Focus',
      description: 'A tab list can select tabs whenever a tab is focused.',
      builder: _selectTabOnFocus,
    ),
    DocsSection(
      id: 'components-tablist--with-overflow',
      title: 'With Overflow',
      description:
          'A tab list can support overflow by using Overflow and OverflowItem. '
          'Note: when adding custom buttons to a tablist, e.g. the overflow '
          'button in this example,role="tab" must be manually added for screen '
          'reader accessibility.',
      builder: _withOverflow,
    ),
    DocsSection(
      id: 'components-tablist--with-panels',
      title: 'With Panels',
      description:
          'A tab list can be used to show/hide UI when a tab is selected.',
      builder: _withPanels,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'tabs',
      type: 'List<FluentTab<T>>',
      description: 'The tabs, in reading order.',
    ),
    PropRow(
      name: 'selectedValue',
      type: 'T?',
      defaultValue: 'null',
      description:
          "The selected tab's value, or null when nothing is selected.",
    ),
    PropRow(
      name: 'onSelect',
      type: 'ValueChanged<T>?',
      defaultValue: 'null',
      description:
          'Invoked with the newly selected value. Null disables every tab.',
    ),
    PropRow(
      name: 'orientation',
      type: 'FluentTabOrientation',
      defaultValue: 'FluentTabOrientation.horizontal',
      description: 'Which way the list runs.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentTabSize',
      defaultValue: 'FluentTabSize.medium',
      description: 'Height and type ramp for every tab.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentTabAppearance',
      defaultValue: 'FluentTabAppearance.transparent',
      description: 'Fill and shape treatment for every tab.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentTabStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults for every tab. A tab\'s '
          'own style is merged after this one.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology as the name of the tab list.',
    ),
  ],
);

// #docregion components-tablist--default
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  String? _selected;

  @override
  Widget build(BuildContext context) => FluentTabList<String>(
    selectedValue: _selected,
    onSelect: (String value) => setState(() => _selected = value),
    tabs: const <FluentTab<String>>[
      FluentTab<String>(value: 'tab1', child: Text('First Tab')),
      FluentTab<String>(value: 'tab2', child: Text('Second Tab')),
      FluentTab<String>(value: 'tab3', child: Text('Third Tab')),
      FluentTab<String>(value: 'tab4', child: Text('Fourth Tab')),
    ],
  );
}
// #enddocregion components-tablist--default

// #docregion components-tablist--horizontal
Widget _horizontal(BuildContext context) => const _Horizontal();

class _Horizontal extends StatefulWidget {
  const _Horizontal();

  @override
  State<_Horizontal> createState() => _HorizontalState();
}

class _HorizontalState extends State<_Horizontal> {
  String _selected = 'tab2';

  @override
  Widget build(BuildContext context) => FluentTabList<String>(
    orientation: FluentTabOrientation.horizontal,
    selectedValue: _selected,
    onSelect: (String value) => setState(() => _selected = value),
    tabs: const <FluentTab<String>>[
      FluentTab<String>(value: 'tab1', child: Text('First Tab')),
      FluentTab<String>(value: 'tab2', child: Text('Second Tab')),
      FluentTab<String>(value: 'tab3', child: Text('Third Tab')),
      FluentTab<String>(value: 'tab4', child: Text('Fourth Tab')),
    ],
  );
}
// #enddocregion components-tablist--horizontal

// #docregion components-tablist--vertical
Widget _vertical(BuildContext context) => const _Vertical();

class _Vertical extends StatefulWidget {
  const _Vertical();

  @override
  State<_Vertical> createState() => _VerticalState();
}

class _VerticalState extends State<_Vertical> {
  String _selected = 'tab2';

  @override
  Widget build(BuildContext context) => FluentTabList<String>(
    orientation: FluentTabOrientation.vertical,
    selectedValue: _selected,
    onSelect: (String value) => setState(() => _selected = value),
    tabs: const <FluentTab<String>>[
      FluentTab<String>(value: 'tab1', child: Text('First Tab')),
      FluentTab<String>(value: 'tab2', child: Text('Second Tab')),
      FluentTab<String>(value: 'tab3', child: Text('Third Tab')),
      FluentTab<String>(value: 'tab4', child: Text('Fourth Tab')),
    ],
  );
}
// #enddocregion components-tablist--vertical

// #docregion components-tablist--appearance
Widget _appearance(BuildContext context) => const _Appearance();

class _Appearance extends StatefulWidget {
  const _Appearance();

  @override
  State<_Appearance> createState() => _AppearanceState();
}

class _AppearanceState extends State<_Appearance> {
  // One selection per list, so all four stay independently interactive.
  final Map<FluentTabAppearance, String> _selected =
      <FluentTabAppearance, String>{
        for (final FluentTabAppearance appearance in FluentTabAppearance.values)
          appearance: 'tab3',
      };

  Widget _list(FluentTabAppearance appearance) => FluentTabList<String>(
    appearance: appearance,
    selectedValue: _selected[appearance],
    onSelect: (String value) => setState(() => _selected[appearance] = value),
    tabs: const <FluentTab<String>>[
      FluentTab<String>(value: 'tab1', child: Text('First Tab')),
      FluentTab<String>(
        value: 'tab2',
        enabled: false,
        child: Text('Second Tab'),
      ),
      FluentTab<String>(value: 'tab3', child: Text('Third Tab')),
      FluentTab<String>(value: 'tab4', child: Text('Fourth Tab')),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: <Widget>[
      _list(FluentTabAppearance.transparent),
      _list(FluentTabAppearance.subtle),
      _list(FluentTabAppearance.subtleCircular),
      _list(FluentTabAppearance.filledCircular),
    ],
  );
}
// #enddocregion components-tablist--appearance

// #docregion components-tablist--disabled
Widget _disabled(BuildContext context) => const _Disabled();

class _Disabled extends StatefulWidget {
  const _Disabled();

  @override
  State<_Disabled> createState() => _DisabledState();
}

class _DisabledState extends State<_Disabled> {
  String _selected = 'tab2';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: <Widget>[
      // Upstream's list-wide `disabled` is our null `onSelect`: with nothing to
      // report a selection to, every tab in the list is disabled.
      const FluentTabList<String>(
        selectedValue: 'tab2',
        tabs: <FluentTab<String>>[
          FluentTab<String>(
            value: 'tab1',
            icon: Icon(FluentIcons.calendar_month_20_regular),
            child: Text('First Tab'),
          ),
          FluentTab<String>(
            value: 'tab2',
            icon: Icon(FluentIcons.calendar_month_20_regular),
            child: Text('Second Tab'),
          ),
          FluentTab<String>(
            value: 'tab3',
            icon: Icon(FluentIcons.calendar_month_20_regular),
            child: Text('Third Tab'),
          ),
          FluentTab<String>(
            value: 'tab4',
            icon: Icon(FluentIcons.calendar_month_20_regular),
            child: Text('Fourth Tab'),
          ),
        ],
      ),
      FluentTabList<String>(
        selectedValue: _selected,
        onSelect: (String value) => setState(() => _selected = value),
        tabs: const <FluentTab<String>>[
          FluentTab<String>(
            value: 'tab1',
            icon: Icon(FluentIcons.calendar_month_20_regular),
            child: Text('First Tab'),
          ),
          FluentTab<String>(
            value: 'tab2',
            icon: Icon(FluentIcons.calendar_month_20_regular),
            enabled: false,
            child: Text('Second Tab'),
          ),
          FluentTab<String>(
            value: 'tab3',
            icon: Icon(FluentIcons.calendar_month_20_regular),
            enabled: false,
            child: Text('Third Tab'),
          ),
          FluentTab<String>(
            value: 'tab4',
            icon: Icon(FluentIcons.calendar_month_20_regular),
            child: Text('Fourth Tab'),
          ),
        ],
      ),
    ],
  );
}
// #enddocregion components-tablist--disabled

// #docregion components-tablist--size-small
Widget _sizeSmall(BuildContext context) => const _SizeSmall();

class _SizeSmall extends StatefulWidget {
  const _SizeSmall();

  @override
  State<_SizeSmall> createState() => _SizeSmallState();
}

class _SizeSmallState extends State<_SizeSmall> {
  final Map<FluentTabOrientation, String> _selected =
      <FluentTabOrientation, String>{
        FluentTabOrientation.horizontal: 'tab2',
        FluentTabOrientation.vertical: 'tab2',
      };

  Widget _list(FluentTabOrientation orientation) => FluentTabList<String>(
    size: FluentTabSize.small,
    orientation: orientation,
    selectedValue: _selected[orientation],
    onSelect: (String value) => setState(() => _selected[orientation] = value),
    tabs: const <FluentTab<String>>[
      FluentTab<String>(value: 'tab1', child: Text('First Tab')),
      FluentTab<String>(
        value: 'tab2',
        icon: Icon(FluentIcons.calendar_month_20_regular),
        child: Text('Second Tab'),
      ),
      FluentTab<String>(value: 'tab3', child: Text('Third Tab')),
      FluentTab<String>(value: 'tab4', child: Text('Fourth Tab')),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: <Widget>[
      _list(FluentTabOrientation.horizontal),
      _list(FluentTabOrientation.vertical),
    ],
  );
}
// #enddocregion components-tablist--size-small

// #docregion components-tablist--size-medium
Widget _sizeMedium(BuildContext context) => const _SizeMedium();

class _SizeMedium extends StatefulWidget {
  const _SizeMedium();

  @override
  State<_SizeMedium> createState() => _SizeMediumState();
}

class _SizeMediumState extends State<_SizeMedium> {
  final Map<FluentTabOrientation, String> _selected =
      <FluentTabOrientation, String>{
        FluentTabOrientation.horizontal: 'tab2',
        FluentTabOrientation.vertical: 'tab2',
      };

  Widget _list(FluentTabOrientation orientation) => FluentTabList<String>(
    size: FluentTabSize.medium,
    orientation: orientation,
    selectedValue: _selected[orientation],
    onSelect: (String value) => setState(() => _selected[orientation] = value),
    tabs: const <FluentTab<String>>[
      FluentTab<String>(value: 'tab1', child: Text('First Tab')),
      FluentTab<String>(
        value: 'tab2',
        icon: Icon(FluentIcons.calendar_month_20_regular),
        child: Text('Second Tab'),
      ),
      FluentTab<String>(value: 'tab3', child: Text('Third Tab')),
      FluentTab<String>(value: 'tab4', child: Text('Fourth Tab')),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: <Widget>[
      _list(FluentTabOrientation.horizontal),
      _list(FluentTabOrientation.vertical),
    ],
  );
}
// #enddocregion components-tablist--size-medium

// #docregion components-tablist--size-large
// `FluentTabSize` ships Figma's two variants, `medium` and `small` — there is
// no `large` tab in the Fluent 2 tab set. The nearest honest rendering is the
// largest size we have, so this section repeats `medium` rather than faking a
// ramp the design system does not define.
Widget _sizeLarge(BuildContext context) => const _SizeLarge();

class _SizeLarge extends StatefulWidget {
  const _SizeLarge();

  @override
  State<_SizeLarge> createState() => _SizeLargeState();
}

class _SizeLargeState extends State<_SizeLarge> {
  final Map<FluentTabOrientation, String> _selected =
      <FluentTabOrientation, String>{
        FluentTabOrientation.horizontal: 'tab2',
        FluentTabOrientation.vertical: 'tab2',
      };

  Widget _list(FluentTabOrientation orientation) => FluentTabList<String>(
    size: FluentTabSize.medium,
    orientation: orientation,
    selectedValue: _selected[orientation],
    onSelect: (String value) => setState(() => _selected[orientation] = value),
    tabs: const <FluentTab<String>>[
      FluentTab<String>(value: 'tab1', child: Text('First Tab')),
      FluentTab<String>(
        value: 'tab2',
        icon: Icon(FluentIcons.calendar_month_20_regular),
        child: Text('Second Tab'),
      ),
      FluentTab<String>(value: 'tab3', child: Text('Third Tab')),
      FluentTab<String>(value: 'tab4', child: Text('Fourth Tab')),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: <Widget>[
      _list(FluentTabOrientation.horizontal),
      _list(FluentTabOrientation.vertical),
    ],
  );
}
// #enddocregion components-tablist--size-large

// #docregion components-tablist--with-icon
Widget _withIcon(BuildContext context) => const _WithIcon();

class _WithIcon extends StatefulWidget {
  const _WithIcon();

  @override
  State<_WithIcon> createState() => _WithIconState();
}

class _WithIconState extends State<_WithIcon> {
  final Map<FluentTabOrientation, String> _selected =
      <FluentTabOrientation, String>{
        FluentTabOrientation.horizontal: 'tab2',
        FluentTabOrientation.vertical: 'tab2',
      };

  Widget _list(FluentTabOrientation orientation) => FluentTabList<String>(
    orientation: orientation,
    selectedValue: _selected[orientation],
    onSelect: (String value) => setState(() => _selected[orientation] = value),
    tabs: const <FluentTab<String>>[
      FluentTab<String>(
        value: 'tab1',
        icon: Icon(FluentIcons.calendar_month_20_regular),
        child: Text('First Tab'),
      ),
      FluentTab<String>(
        value: 'tab2',
        icon: Icon(FluentIcons.calendar_month_20_regular),
        child: Text('Second Tab'),
      ),
      FluentTab<String>(
        value: 'tab3',
        icon: Icon(FluentIcons.calendar_month_20_regular),
        child: Text('Third Tab'),
      ),
      FluentTab<String>(
        value: 'tab4',
        icon: Icon(FluentIcons.calendar_month_20_regular),
        child: Text('Fourth Tab'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: <Widget>[
      _list(FluentTabOrientation.horizontal),
      _list(FluentTabOrientation.vertical),
    ],
  );
}
// #enddocregion components-tablist--with-icon

// #docregion components-tablist--icon-only
Widget _iconOnly(BuildContext context) => const _IconOnly();

class _IconOnly extends StatefulWidget {
  const _IconOnly();

  @override
  State<_IconOnly> createState() => _IconOnlyState();
}

class _IconOnlyState extends State<_IconOnly> {
  final Map<FluentTabOrientation, String> _selected =
      <FluentTabOrientation, String>{
        FluentTabOrientation.horizontal: 'tab2',
        FluentTabOrientation.vertical: 'tab2',
      };

  // A tab with no `child` is an icon-only tab, and upstream's `aria-label` is
  // our `semanticLabel` — the only name a screen reader has to read.
  Widget _list(FluentTabOrientation orientation) => FluentTabList<String>(
    orientation: orientation,
    selectedValue: _selected[orientation],
    onSelect: (String value) => setState(() => _selected[orientation] = value),
    tabs: const <FluentTab<String>>[
      FluentTab<String>(
        value: 'tab1',
        icon: Icon(FluentIcons.calendar_month_20_regular),
        semanticLabel: 'First Tab',
      ),
      FluentTab<String>(
        value: 'tab2',
        icon: Icon(FluentIcons.calendar_month_20_regular),
        semanticLabel: 'Second Tab',
      ),
      FluentTab<String>(
        value: 'tab3',
        icon: Icon(FluentIcons.calendar_month_20_regular),
        semanticLabel: 'Third Tab',
      ),
      FluentTab<String>(
        value: 'tab4',
        icon: Icon(FluentIcons.calendar_month_20_regular),
        semanticLabel: 'Fourth Tab',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: <Widget>[
      _list(FluentTabOrientation.horizontal),
      _list(FluentTabOrientation.vertical),
    ],
  );
}
// #enddocregion components-tablist--icon-only

// #docregion components-tablist--select-tab-on-focus
// Upstream's `selectTabOnFocus` is a knob because its default is to move focus
// without selecting. `FluentTabList` has no such knob: its arrow keys move the
// *selection*, the way `useArrowNavigationGroup` does with the flag on, so this
// list already behaves the way the story is demonstrating. Tab into it and
// press the left or right arrow.
Widget _selectTabOnFocus(BuildContext context) => const _SelectTabOnFocus();

class _SelectTabOnFocus extends StatefulWidget {
  const _SelectTabOnFocus();

  @override
  State<_SelectTabOnFocus> createState() => _SelectTabOnFocusState();
}

class _SelectTabOnFocusState extends State<_SelectTabOnFocus> {
  String _selected = 'tab2';

  @override
  Widget build(BuildContext context) => FluentTabList<String>(
    selectedValue: _selected,
    onSelect: (String value) => setState(() => _selected = value),
    tabs: const <FluentTab<String>>[
      FluentTab<String>(value: 'tab1', child: Text('First Tab')),
      FluentTab<String>(value: 'tab2', child: Text('Second Tab')),
      FluentTab<String>(value: 'tab3', child: Text('Third Tab')),
      FluentTab<String>(value: 'tab4', child: Text('Fourth Tab')),
    ],
  );
}
// #enddocregion components-tablist--select-tab-on-focus

// #docregion components-tablist--with-overflow
// Upstream wraps the list in `Overflow`/`OverflowItem`, which measure the strip
// and move whatever no longer fits into the menu. Flutter has no equivalent
// measuring primitive, so the split is declared rather than measured: the first
// `visible` tabs render, the rest are reachable from the overflow menu. The
// selected tab is pulled back into view the way upstream's `priority` does.
Widget _withOverflow(BuildContext context) => const _WithOverflow();

class _OverflowTab {
  const _OverflowTab(this.id, this.name, this.icon);

  final String id;
  final String name;
  final IconData icon;
}

const List<_OverflowTab> _overflowTabs = <_OverflowTab>[
  _OverflowTab('today', 'Today', FluentIcons.calendar_today_20_regular),
  _OverflowTab('agenda', 'Agenda', FluentIcons.calendar_agenda_20_regular),
  _OverflowTab('day', 'Day', FluentIcons.calendar_day_20_regular),
  _OverflowTab('threeDay', 'Three Day', FluentIcons.calendar_3_day_20_regular),
  _OverflowTab(
    'workWeek',
    'Work Week',
    FluentIcons.calendar_work_week_20_regular,
  ),
  _OverflowTab('week', 'Week', FluentIcons.calendar_week_start_20_regular),
  _OverflowTab('month', 'Month', FluentIcons.calendar_month_20_regular),
  _OverflowTab('search', 'Search', FluentIcons.calendar_search_20_regular),
  _OverflowTab('chat', 'Conversations', FluentIcons.calendar_chat_20_regular),
];

class _WithOverflow extends StatefulWidget {
  const _WithOverflow();

  @override
  State<_WithOverflow> createState() => _WithOverflowState();
}

class _WithOverflowState extends State<_WithOverflow> {
  String _horizontal = 'today';
  String _vertical = 'today';

  Widget _example({
    required FluentTabOrientation orientation,
    required int visible,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    final List<_OverflowTab> ordered = <_OverflowTab>[..._overflowTabs];
    final int index = ordered.indexWhere(
      (_OverflowTab tab) => tab.id == selected,
    );
    if (index >= visible) {
      ordered.insert(visible - 1, ordered.removeAt(index));
    }
    final List<_OverflowTab> hidden = ordered.sublist(visible);

    final Widget list = FluentTabList<String>(
      orientation: orientation,
      selectedValue: selected,
      onSelect: onSelect,
      tabs: <FluentTab<String>>[
        for (final _OverflowTab tab in ordered.sublist(0, visible))
          FluentTab<String>(
            value: tab.id,
            icon: Icon(tab.icon),
            child: Text(tab.name),
          ),
      ],
    );

    final Widget menu = FluentMenu(
      items: <FluentMenuItem>[
        for (final _OverflowTab tab in hidden)
          FluentMenuItem(
            label: Text(tab.name),
            icon: Icon(tab.icon),
            onPressed: () => onSelect(tab.id),
          ),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton.icon(
        icon: const Icon(FluentIcons.more_horizontal_20_regular),
        semanticLabel: '${hidden.length} more tabs',
        appearance: FluentButtonAppearance.transparent,
        onPressed: toggle,
      ),
    );

    return orientation == FluentTabOrientation.horizontal
        ? Row(mainAxisSize: MainAxisSize.min, children: <Widget>[list, menu])
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[list, menu],
          );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: <Widget>[
      _example(
        orientation: FluentTabOrientation.horizontal,
        visible: 5,
        selected: _horizontal,
        onSelect: (String value) => setState(() => _horizontal = value),
      ),
      _example(
        orientation: FluentTabOrientation.vertical,
        visible: 6,
        selected: _vertical,
        onSelect: (String value) => setState(() => _vertical = value),
      ),
    ],
  );
}
// #enddocregion components-tablist--with-overflow

// #docregion components-tablist--with-panels
Widget _withPanels(BuildContext context) => const _WithPanels();

class _WithPanels extends StatefulWidget {
  const _WithPanels();

  @override
  State<_WithPanels> createState() => _WithPanelsState();
}

class _WithPanelsState extends State<_WithPanels> {
  String _selectedValue = 'conditions';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: <Widget>[
      FluentTabList<String>(
        selectedValue: _selectedValue,
        onSelect: (String value) => setState(() => _selectedValue = value),
        tabs: const <FluentTab<String>>[
          FluentTab<String>(
            value: 'arrivals',
            icon: Icon(FluentIcons.airplane_20_regular),
            child: Text('Arrivals'),
          ),
          FluentTab<String>(
            value: 'departures',
            icon: Icon(FluentIcons.airplane_take_off_20_regular),
            child: Text('Departures'),
          ),
          FluentTab<String>(
            value: 'conditions',
            icon: Icon(FluentIcons.time_and_weather_20_regular),
            child: Text('Conditions'),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: switch (_selectedValue) {
          'arrivals' => const _Panel(
            header: <String>['Origin', 'Gate', 'ETA'],
            rows: <List<String>>[
              <String>['DEN', 'C3', '12:40 PM'],
              <String>['SMF', 'D1', '1:18 PM'],
              <String>['SFO', 'E18', '1:42 PM'],
            ],
          ),
          'departures' => const _Panel(
            header: <String>['Destination', 'Gate', 'ETD'],
            rows: <List<String>>[
              <String>['MSP', 'A7', '8:26 AM'],
              <String>['DCA', 'N2', '9:03 AM'],
              <String>['LAS', 'E15', '2:36 PM'],
            ],
          ),
          _ => const _Panel(
            boldFirstColumn: true,
            rows: <List<String>>[
              <String>['Time', '6:45 AM'],
              <String>['Temperature', '68F / 20C'],
              <String>['Forecast', 'Overcast'],
              <String>['Visibility', '0.5 miles, 1800 ft runway visual range'],
            ],
          ),
        },
      ),
    ],
  );
}

/// Upstream's panels are `<table>`s; `Table` is the widget with the same
/// column-alignment behaviour, so the markup translates one for one.
class _Panel extends StatelessWidget {
  const _Panel({required this.rows, this.header, this.boldFirstColumn = false});

  final List<String>? header;
  final List<List<String>> rows;
  final bool boldFirstColumn;

  static Widget _cell(String text, {required bool bold}) => Padding(
    padding: const EdgeInsets.only(right: 30),
    child: Text(
      text,
      style: bold ? const TextStyle(fontWeight: FontWeight.w600) : null,
    ),
  );

  @override
  Widget build(BuildContext context) => Table(
    defaultColumnWidth: const IntrinsicColumnWidth(),
    children: <TableRow>[
      if (header case final List<String> cells)
        TableRow(
          children: <Widget>[
            for (final String cell in cells) _cell(cell, bold: true),
          ],
        ),
      for (final List<String> row in rows)
        TableRow(
          children: <Widget>[
            for (int i = 0; i < row.length; i++)
              _cell(row[i], bold: boldFirstColumn && i == 0),
          ],
        ),
    ],
  );
}

// #enddocregion components-tablist--with-panels
