import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The DataGrid docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Upstream composes a grid out of six render-prop elements — `DataGrid`,
/// `DataGridHeader`, `DataGridHeaderCell`, `DataGridBody`, `DataGridRow` and
/// `DataGridCell` — over a `createTableColumn` column definition that carries
/// both `renderHeaderCell` and `renderCell`. [FluentDataGrid] splits the same
/// information the other way: [FluentDataGridColumn] is the header and
/// [FluentDataGridRow] is the data, so every section below builds its rows from
/// its items rather than handing the grid a renderer. Sorting and selection are
/// controlled here in every case — the widget never owns either — so the
/// "controlled" sections differ from their uncontrolled twins only in what the
/// prose says.
const DocsPage dataGridPage = DocsPage(
  id: 'components-datagrid',
  title: 'DataGrid',
  description:
      'This component is a higher level extension of the Table primitive '
      'components and the useTableFeatures hook. DataGrid is a feature-rich '
      'component that uses useTableFeatures internally, so there should always '
      'be full feature parity with what can be achieved with primitives. This '
      'component is opinionated and this is intentional. If the desired '
      'scenario can be achieved easily and does not vary too much from '
      'documented examples, it can be very convenient. If the desired scenario '
      'varies a lot from the documented examples please use the Table '
      'components with useTableFeatures (or another state management solution '
      'of choice). Feature requests will be accepted, but the team will '
      'prioritize overall API scalability and extensibility over uncommon '
      'features and scenarios.',
  source: 'lib/pages/components_datagrid.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-datagrid--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-datagrid--composite-navigation',
      title: 'Composite Navigation',
      builder: _compositeNavigation,
    ),
    DocsSection(
      id: 'components-datagrid--focusable-elements-in-cells',
      title: 'Focusable Elements In Cells',
      description:
          'When cells contain focusable elements, set the focusMode prop on '
          'the DataGridCell or DataGridHeaderCell components. Use group when '
          'there are multiple focusable elements in cell, group will enable '
          'the following behaviour: Enter will move focus into the cell. Focus '
          'is trapped in the cell. Escape will move focus back to the cell. '
          'Use none when there is one single focusable element in cell, none '
          'will make the cell non-focusable. Do not add nested focusable '
          'elements to a sortable DataGridHeaderCell, since they will be '
          'rendered within the sort button.',
      builder: _focusableElementsInCells,
    ),
    DocsSection(
      id: 'components-datagrid--sort',
      title: 'Sort',
      description:
          'To enable sorting, the sortable prop needs to be set. Column '
          'definitions without a compare function will not be sortable. Due to '
          'screen reader support, the sort status might not be announced once '
          'a sortable column header is invoked. This is a known issue. However '
          'the implementation still follows the pattern recommended by the '
          'WAI.',
      builder: _sort,
    ),
    DocsSection(
      id: 'components-datagrid--sort-controlled',
      title: 'Sort Controlled',
      description:
          'To enable sorting, the sortable prop needs to be set. The API '
          'surface is directly equivalent to the usage of useTableFeatures.',
      builder: _sortControlled,
    ),
    DocsSection(
      id: 'components-datagrid--multiple-select',
      title: 'Multiple Select',
      description:
          'In order to enable this feature the selectionMode prop needs to be '
          'set. The API surface is directly equivalent to the usage of '
          'useTableFeatures.',
      builder: _multipleSelect,
    ),
    DocsSection(
      id: 'components-datagrid--multiple-select-controlled',
      title: 'Multiple Select Controlled',
      description:
          'To enable selection, the selectionMode prop needs to be set. The '
          'API surface is directly equivalent to the usage of '
          'useTableFeatures.',
      builder: _multipleSelectControlled,
    ),
    DocsSection(
      id: 'components-datagrid--single-select',
      title: 'Single Select',
      description:
          'To enable selection, the selectionMode prop needs to be set. The '
          'API surface is directly equivalent to the usage of '
          'useTableFeatures.',
      builder: _singleSelect,
    ),
    DocsSection(
      id: 'components-datagrid--single-select-controlled',
      title: 'Single Select Controlled',
      description:
          'To enable selection, the selectionMode prop needs to be set. The '
          'API surface is directly equivalent to the usage of '
          'useTableFeatures.',
      builder: _singleSelectControlled,
    ),
    DocsSection(
      id: 'components-datagrid--subtle-selection',
      title: 'Subtle Selection',
      description:
          'To enable subtle selection mode, the subtleSelection should be set. '
          'The selection indicator slot will only appear when: the DataGridRow '
          'component is hovered. The current focused element is within the '
          'DataGridRow. The DataGridSelectionCell is checked.',
      builder: _subtleSelection,
    ),
    DocsSection(
      id: 'components-datagrid--selection-appearance',
      title: 'Selection Appearance',
      description:
          'The selectionAppearance prop will vary the appearance of selected '
          'rows. The default appearance is a brand background color. However a '
          'neutral (grey) background is also available.',
      builder: _selectionAppearance,
    ),
    DocsSection(
      id: 'components-datagrid--resizable-columns',
      title: 'Resizable Columns (preview)',
      description:
          'Columns can be made resizable by passing a prop resizableColumns. '
          'The resizing configuration for each column (like minWidth and '
          'defaultWidth), can be further customized by passing down a '
          'columnSizingOptions prop. The control over the state of resizing '
          'can be achieved with the combination of onColumnResize callback and '
          'setting the idealWidth for a column in columnSizingOptions. For '
          'accessibility, the DataGrid component supports keyboard navigation '
          'and screen reader navigation. To make features like column resizing '
          'work with keyboard navigation, the Menu component is used to '
          'provide a context menu for the header cells, which allows the user '
          'to access other DataGrid features. Once an option is selected, the '
          'arrows keys can be used to interact with the DataGrid (e.g. resize '
          'columns). ESC, ENTER, or SPACE can be used to return to the '
          'original navigation mode.',
      builder: _resizableColumns,
    ),
    DocsSection(
      id: 'components-datagrid--resizable-columns-disable-auto-fit',
      title: 'Resizable Columns - Disabled container auto-fit',
      description:
          'In the previous example, the columns are automatically fitted to '
          'the container. This means that the columns are squeezed when the '
          'container is narrowed, until the minimum width is reached, and the '
          'last column is extended past its optimal width to fill the '
          'available space. This also effectively prevents the user from '
          'making the columns wider than the total width of the container, as '
          'the columns are automatically resized to fit the container. This '
          'behavior can be disabled by passing resizableColumnsOptions prop to '
          'Datagrid, with the {autoFitColumns: false} option. With this '
          'option, the columns can be made wider than the container, and the '
          'container will overflow. Also, the automatic resizing of adjacent '
          'columns will be disabled, as the column are now allowed to be wider '
          'that the container. This also enables the resize handle on the last '
          'column.',
      builder: _resizableColumnsDisableAutoFit,
    ),
    DocsSection(
      id: 'components-datagrid--virtualization',
      title: 'Virtualization',
      description:
          'Virtualizating the DataGrid component involves recomposing '
          'components to use a virtualized container. This is already done in '
          'the extension package @fluentui-contrib/react-data-grid-react-window '
          'which provides extended DataGrid components that are powered by '
          'react-window. The example below shows how to use this extension '
          'package to virtualize the DataGrid component. Here some useful '
          'links for the package: Storybook documentation. NPM page. README. '
          'Make sure to memoize the row render function to avoid excessive '
          'unmouting/mounting of components. react-window will create '
          'components based on this renderer.',
      builder: _virtualization,
    ),
    DocsSection(
      id: 'components-datagrid--custom-row-id',
      title: 'Custom Row Id',
      description:
          'By default row Ids are the index of the item in the collection. In '
          'order to use a row Id based on the data use the getRowId prop.',
      builder: _customRowId,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'columns',
      type: 'List<FluentDataGridColumn>',
      description: 'The columns, in order.',
    ),
    PropRow(
      name: 'rows',
      type: 'List<FluentDataGridRow>',
      description: 'The body rows, in order. Each holds one cell per column.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentDataGridSize',
      defaultValue: 'FluentDataGridSize.medium',
      description: 'Row height and type ramp.',
    ),
    PropRow(
      name: 'selectionMode',
      type: 'FluentDataGridSelectionMode',
      defaultValue: 'FluentDataGridSelectionMode.none',
      description:
          'Which selection affordance the leading column holds, if any.',
    ),
    PropRow(
      name: 'selectionAppearance',
      type: 'FluentDataGridSelectionAppearance',
      defaultValue: 'FluentDataGridSelectionAppearance.neutral',
      description: 'How a selected row is filled.',
    ),
    PropRow(
      name: 'headerWeight',
      type: 'FluentDataGridHeaderWeight',
      defaultValue: 'FluentDataGridHeaderWeight.semibold',
      description: 'Header label weight.',
    ),
    PropRow(
      name: 'selectedRows',
      type: 'Set<int>',
      defaultValue: '{}',
      description:
          'Indices of the selected rows. Selection is controlled: this is the '
          'truth, and the grid never mutates it.',
    ),
    PropRow(
      name: 'onSelectionChanged',
      type: 'ValueChanged<Set<int>>?',
      defaultValue: 'null',
      description:
          'Reports the next selection. Null leaves the selection column '
          'read-only.',
    ),
    PropRow(
      name: 'sortColumn',
      type: 'int?',
      defaultValue: 'null',
      description:
          'Index of the sorted column, or null when nothing is sorted.',
    ),
    PropRow(
      name: 'sortDirection',
      type: 'FluentDataGridSortDirection?',
      defaultValue: 'null',
      description: 'Which way sortColumn is ordered. Null draws no arrow.',
    ),
    PropRow(
      name: 'onSort',
      type: 'ValueChanged<int>?',
      defaultValue: 'null',
      description:
          'Invoked with a column index when its sort control is activated. '
          'Null leaves every header inert.',
    ),
    PropRow(
      name: 'showHeader',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether the header row is drawn at all.',
    ),
    PropRow(
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether the grid responds to input.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentDataGridStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Announced by assistive technology as the name of the grid.',
    ),
    PropRow(
      name: 'selectAllSemanticLabel',
      type: 'String',
      defaultValue: "'Select all rows'",
      description: "Announced for the header's select-all checkbox.",
    ),
    PropRow(
      name: 'selectRowSemanticLabel',
      type: 'String',
      defaultValue: "'Select row'",
      description:
          "Announced for a row's selection control. The row number is "
          'appended.',
    ),
  ],
);

// #docregion components-datagrid--default
typedef _DefaultItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_DefaultItem> _defaultItems = <_DefaultItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
    lastUpdate: 'You edited this',
    lastUpdateIcon: FluentIcons.edit_20_regular,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
    lastUpdate: 'You shared this in a Teams chat',
    lastUpdateIcon: FluentIcons.people_20_regular,
  ),
];

List<Widget> _defaultCells(_DefaultItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  // Upstream's `getRowId` keys the selection on the file name so it survives a
  // sort. The grid selects by index, so the demo keeps the names and maps them
  // back on the way in and out.
  Set<String> _selected = <String>{};
  int? _sortColumn;
  FluentDataGridSortDirection _sortDirection =
      FluentDataGridSortDirection.ascending;

  List<_DefaultItem> get _sorted {
    final int? column = _sortColumn;
    if (column == null) return _defaultItems;
    final List<_DefaultItem> items = <_DefaultItem>[..._defaultItems];
    items.sort(
      (_DefaultItem a, _DefaultItem b) => switch (column) {
        0 => a.file.compareTo(b.file),
        1 => a.author.compareTo(b.author),
        2 => a.timestamp.compareTo(b.timestamp),
        _ => a.lastUpdate.compareTo(b.lastUpdate),
      },
    );
    return _sortDirection == FluentDataGridSortDirection.descending
        ? items.reversed.toList()
        : items;
  }

  void _sort(int column) => setState(() {
    if (_sortColumn == column) {
      _sortDirection = _sortDirection == FluentDataGridSortDirection.ascending
          ? FluentDataGridSortDirection.descending
          : FluentDataGridSortDirection.ascending;
    } else {
      _sortColumn = column;
      _sortDirection = FluentDataGridSortDirection.ascending;
    }
  });

  @override
  Widget build(BuildContext context) {
    final List<_DefaultItem> items = _sorted;
    return FluentDataGrid(
      columns: const <FluentDataGridColumn>[
        FluentDataGridColumn(header: Text('File'), sortable: true),
        FluentDataGridColumn(header: Text('Author'), sortable: true),
        FluentDataGridColumn(header: Text('Last updated'), sortable: true),
        FluentDataGridColumn(header: Text('Last update'), sortable: true),
      ],
      rows: <FluentDataGridRow>[
        for (final _DefaultItem item in items)
          FluentDataGridRow(cells: _defaultCells(item)),
      ],
      sortColumn: _sortColumn,
      sortDirection: _sortDirection,
      onSort: _sort,
      selectionMode: FluentDataGridSelectionMode.multiple,
      selectedRows: <int>{
        for (int i = 0; i < items.length; i++)
          if (_selected.contains(items[i].file)) i,
      },
      onSelectionChanged: (Set<int> next) => setState(() {
        _selected = <String>{for (final int i in next) items[i].file};
      }),
    );
  }
}
// #enddocregion components-datagrid--default

// #docregion components-datagrid--composite-navigation
typedef _CompositeItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_CompositeItem> _compositeItems = <_CompositeItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
    lastUpdate: 'You edited this',
    lastUpdateIcon: FluentIcons.edit_20_regular,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
    lastUpdate: 'You shared this in a Teams chat',
    lastUpdateIcon: FluentIcons.people_20_regular,
  ),
];

List<Widget> _compositeCells(_CompositeItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

// Upstream sets `focusMode="composite"`, which turns the whole grid into one
// tab stop and moves between cells with the arrow keys. `FluentDataGrid` has no
// focusMode: that behaviour is the only one it has, so this section is the
// Default grid with sorting switched off, which is exactly what upstream's is.
Widget _compositeNavigation(BuildContext context) =>
    const _CompositeNavigation();

class _CompositeNavigation extends StatefulWidget {
  const _CompositeNavigation();

  @override
  State<_CompositeNavigation> createState() => _CompositeNavigationState();
}

class _CompositeNavigationState extends State<_CompositeNavigation> {
  Set<int> _selected = <int>{};

  @override
  Widget build(BuildContext context) => FluentDataGrid(
    columns: const <FluentDataGridColumn>[
      FluentDataGridColumn(header: Text('File')),
      FluentDataGridColumn(header: Text('Author')),
      FluentDataGridColumn(header: Text('Last updated')),
      FluentDataGridColumn(header: Text('Last update')),
    ],
    rows: <FluentDataGridRow>[
      for (final _CompositeItem item in _compositeItems)
        FluentDataGridRow(cells: _compositeCells(item)),
    ],
    selectionMode: FluentDataGridSelectionMode.multiple,
    selectedRows: _selected,
    onSelectionChanged: (Set<int> next) => setState(() => _selected = next),
  );
}
// #enddocregion components-datagrid--composite-navigation

// #docregion components-datagrid--focusable-elements-in-cells
typedef _FocusableItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
});

const List<_FocusableItem> _focusableItems = <_FocusableItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
  ),
];

// The `Author` header is upstream's `focusMode="group"` header cell: a label
// with two controls beside it.
Widget _focusableAuthorHeader() => Row(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    const Text('Author'),
    FluentButton.icon(
      appearance: FluentButtonAppearance.transparent,
      semanticLabel: 'Edit',
      icon: const Icon(FluentIcons.edit_20_regular),
      onPressed: () {},
    ),
    FluentMenu(
      items: const <FluentMenuItem>[
        FluentMenuItem(label: Text('Delete column')),
        FluentMenuItem(label: Text('Create new author')),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton.icon(
        appearance: FluentButtonAppearance.transparent,
        semanticLabel: 'More options',
        icon: const Icon(FluentIcons.more_horizontal_20_regular),
        onPressed: toggle,
      ),
    ),
  ],
);

// `emphasis: none` is the cell layout Figma pins for control cells — the one
// that leaves its child's own ramp alone. It is what upstream's
// `focusMode="none"` and `"group"` cells hold.
List<Widget> _focusableCells(_FocusableItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(
    emphasis: FluentDataGridCellEmphasis.none,
    child: FluentButton(
      icon: const Icon(FluentIcons.open_20_regular),
      onPressed: () {},
      child: const Text('Open'),
    ),
  ),
  FluentDataGridCell(
    emphasis: FluentDataGridCellEmphasis.none,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: <Widget>[
        FluentButton.icon(
          semanticLabel: 'Edit',
          icon: const Icon(FluentIcons.edit_20_regular),
          onPressed: () {},
        ),
        FluentButton.icon(
          semanticLabel: 'Delete',
          icon: const Icon(FluentIcons.delete_20_regular),
          onPressed: () {},
        ),
      ],
    ),
  ),
];

Widget _focusableElementsInCells(BuildContext context) => const _Focusable();

class _Focusable extends StatefulWidget {
  const _Focusable();

  @override
  State<_Focusable> createState() => _FocusableState();
}

class _FocusableState extends State<_Focusable> {
  Set<String> _selected = <String>{};
  int? _sortColumn;
  FluentDataGridSortDirection _sortDirection =
      FluentDataGridSortDirection.ascending;

  List<_FocusableItem> get _sorted {
    if (_sortColumn == null) return _focusableItems;
    final List<_FocusableItem> items = <_FocusableItem>[..._focusableItems];
    items.sort(
      (_FocusableItem a, _FocusableItem b) => a.file.compareTo(b.file),
    );
    return _sortDirection == FluentDataGridSortDirection.descending
        ? items.reversed.toList()
        : items;
  }

  void _sort(int column) => setState(() {
    if (_sortColumn == column) {
      _sortDirection = _sortDirection == FluentDataGridSortDirection.ascending
          ? FluentDataGridSortDirection.descending
          : FluentDataGridSortDirection.ascending;
    } else {
      _sortColumn = column;
      _sortDirection = FluentDataGridSortDirection.ascending;
    }
  });

  @override
  Widget build(BuildContext context) {
    final List<_FocusableItem> items = _sorted;
    return FluentDataGrid(
      columns: <FluentDataGridColumn>[
        const FluentDataGridColumn(header: Text('File'), sortable: true),
        FluentDataGridColumn(header: _focusableAuthorHeader()),
        const FluentDataGridColumn(header: Text('Single action')),
        const FluentDataGridColumn(header: Text('Actions')),
      ],
      rows: <FluentDataGridRow>[
        for (final _FocusableItem item in items)
          FluentDataGridRow(cells: _focusableCells(item)),
      ],
      sortColumn: _sortColumn,
      sortDirection: _sortDirection,
      onSort: _sort,
      selectionMode: FluentDataGridSelectionMode.multiple,
      selectedRows: <int>{
        for (int i = 0; i < items.length; i++)
          if (_selected.contains(items[i].file)) i,
      },
      onSelectionChanged: (Set<int> next) => setState(() {
        _selected = <String>{for (final int i in next) items[i].file};
      }),
    );
  }
}
// #enddocregion components-datagrid--focusable-elements-in-cells

// #docregion components-datagrid--sort
typedef _SortItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_SortItem> _sortItems = <_SortItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
    lastUpdate: 'You edited this',
    lastUpdateIcon: FluentIcons.edit_20_regular,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
    lastUpdate: 'You shared this in a Teams chat',
    lastUpdateIcon: FluentIcons.people_20_regular,
  ),
];

List<Widget> _sortCells(_SortItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

Widget _sort(BuildContext context) => const _Sort();

class _Sort extends StatefulWidget {
  const _Sort();

  @override
  State<_Sort> createState() => _SortState();
}

class _SortState extends State<_Sort> {
  // Upstream's `defaultSortState`: file, ascending.
  int _sortColumn = 0;
  FluentDataGridSortDirection _sortDirection =
      FluentDataGridSortDirection.ascending;

  List<_SortItem> get _sorted {
    final List<_SortItem> items = <_SortItem>[..._sortItems];
    items.sort(
      (_SortItem a, _SortItem b) => switch (_sortColumn) {
        0 => a.file.compareTo(b.file),
        1 => a.author.compareTo(b.author),
        _ => a.timestamp.compareTo(b.timestamp),
      },
    );
    return _sortDirection == FluentDataGridSortDirection.descending
        ? items.reversed.toList()
        : items;
  }

  void _sort(int column) => setState(() {
    if (_sortColumn == column) {
      _sortDirection = _sortDirection == FluentDataGridSortDirection.ascending
          ? FluentDataGridSortDirection.descending
          : FluentDataGridSortDirection.ascending;
    } else {
      _sortColumn = column;
      _sortDirection = FluentDataGridSortDirection.ascending;
    }
  });

  @override
  Widget build(BuildContext context) => FluentDataGrid(
    // The fourth column has no `compare` upstream, so it is the one header
    // without a sort control — which is what `sortable: false` says here.
    columns: const <FluentDataGridColumn>[
      FluentDataGridColumn(header: Text('File'), sortable: true),
      FluentDataGridColumn(header: Text('Author'), sortable: true),
      FluentDataGridColumn(header: Text('Last updated'), sortable: true),
      FluentDataGridColumn(header: Text('Not sortable')),
    ],
    rows: <FluentDataGridRow>[
      for (final _SortItem item in _sorted)
        FluentDataGridRow(cells: _sortCells(item)),
    ],
    sortColumn: _sortColumn,
    sortDirection: _sortDirection,
    onSort: _sort,
  );
}
// #enddocregion components-datagrid--sort

// #docregion components-datagrid--sort-controlled
typedef _SortControlledItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_SortControlledItem> _sortControlledItems = <_SortControlledItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
    lastUpdate: 'You edited this',
    lastUpdateIcon: FluentIcons.edit_20_regular,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
    lastUpdate: 'You shared this in a Teams chat',
    lastUpdateIcon: FluentIcons.people_20_regular,
  ),
];

List<Widget> _sortControlledCells(_SortControlledItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

// `FluentDataGrid` has no uncontrolled sort mode — `sortColumn`, `sortDirection`
// and `onSort` are the whole API — so this reads the same as the Sort section
// above. Upstream's distinction is between `defaultSortState` and `sortState`;
// here the caller always owns the state.
Widget _sortControlled(BuildContext context) => const _SortControlled();

class _SortControlled extends StatefulWidget {
  const _SortControlled();

  @override
  State<_SortControlled> createState() => _SortControlledState();
}

class _SortControlledState extends State<_SortControlled> {
  int _sortColumn = 0;
  FluentDataGridSortDirection _sortDirection =
      FluentDataGridSortDirection.ascending;

  List<_SortControlledItem> get _sorted {
    final List<_SortControlledItem> items = <_SortControlledItem>[
      ..._sortControlledItems,
    ];
    items.sort(
      (_SortControlledItem a, _SortControlledItem b) => switch (_sortColumn) {
        0 => a.file.compareTo(b.file),
        1 => a.author.compareTo(b.author),
        2 => a.timestamp.compareTo(b.timestamp),
        _ => a.lastUpdate.compareTo(b.lastUpdate),
      },
    );
    return _sortDirection == FluentDataGridSortDirection.descending
        ? items.reversed.toList()
        : items;
  }

  @override
  Widget build(BuildContext context) => FluentDataGrid(
    columns: const <FluentDataGridColumn>[
      FluentDataGridColumn(header: Text('File'), sortable: true),
      FluentDataGridColumn(header: Text('Author'), sortable: true),
      FluentDataGridColumn(header: Text('Last updated'), sortable: true),
      FluentDataGridColumn(header: Text('Last update'), sortable: true),
    ],
    rows: <FluentDataGridRow>[
      for (final _SortControlledItem item in _sorted)
        FluentDataGridRow(cells: _sortControlledCells(item)),
    ],
    sortColumn: _sortColumn,
    sortDirection: _sortDirection,
    onSort: (int column) => setState(() {
      if (_sortColumn == column) {
        _sortDirection = _sortDirection == FluentDataGridSortDirection.ascending
            ? FluentDataGridSortDirection.descending
            : FluentDataGridSortDirection.ascending;
      } else {
        _sortColumn = column;
        _sortDirection = FluentDataGridSortDirection.ascending;
      }
    }),
  );
}
// #enddocregion components-datagrid--sort-controlled

// #docregion components-datagrid--multiple-select
typedef _MultipleSelectItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_MultipleSelectItem> _multipleSelectItems = <_MultipleSelectItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
    lastUpdate: 'You edited this',
    lastUpdateIcon: FluentIcons.edit_20_regular,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
    lastUpdate: 'You shared this in a Teams chat',
    lastUpdateIcon: FluentIcons.people_20_regular,
  ),
];

List<Widget> _multipleSelectCells(_MultipleSelectItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

Widget _multipleSelect(BuildContext context) => const _MultipleSelect();

class _MultipleSelect extends StatefulWidget {
  const _MultipleSelect();

  @override
  State<_MultipleSelect> createState() => _MultipleSelectState();
}

class _MultipleSelectState extends State<_MultipleSelect> {
  // Upstream's `defaultSelectedItems`.
  Set<int> _selected = <int>{1};

  @override
  Widget build(BuildContext context) => FluentDataGrid(
    columns: const <FluentDataGridColumn>[
      FluentDataGridColumn(header: Text('File')),
      FluentDataGridColumn(header: Text('Author')),
      FluentDataGridColumn(header: Text('Last updated')),
      FluentDataGridColumn(header: Text('Last update')),
    ],
    rows: <FluentDataGridRow>[
      for (final _MultipleSelectItem item in _multipleSelectItems)
        FluentDataGridRow(cells: _multipleSelectCells(item)),
    ],
    selectionMode: FluentDataGridSelectionMode.multiple,
    selectedRows: _selected,
    onSelectionChanged: (Set<int> next) => setState(() => _selected = next),
  );
}
// #enddocregion components-datagrid--multiple-select

// #docregion components-datagrid--multiple-select-controlled
typedef _MultipleControlledItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_MultipleControlledItem> _multipleControlledItems =
    <_MultipleControlledItem>[
      (
        file: 'Meeting notes',
        fileIcon: FluentIcons.document_20_regular,
        author: 'Max Mustermann',
        initials: 'MM',
        status: FluentPresenceStatus.available,
        lastUpdated: '7h ago',
        timestamp: 1,
        lastUpdate: 'You edited this',
        lastUpdateIcon: FluentIcons.edit_20_regular,
      ),
      (
        file: 'Thursday presentation',
        fileIcon: FluentIcons.folder_20_regular,
        author: 'Erika Mustermann',
        initials: 'EM',
        status: FluentPresenceStatus.busy,
        lastUpdated: 'Yesterday at 1:45 PM',
        timestamp: 2,
        lastUpdate: 'You recently opened this',
        lastUpdateIcon: FluentIcons.open_20_regular,
      ),
      (
        file: 'Training recording',
        fileIcon: FluentIcons.video_20_regular,
        author: 'John Doe',
        initials: 'JD',
        status: FluentPresenceStatus.away,
        lastUpdated: 'Yesterday at 1:45 PM',
        timestamp: 2,
        lastUpdate: 'You recently opened this',
        lastUpdateIcon: FluentIcons.open_20_regular,
      ),
      (
        file: 'Purchase order',
        fileIcon: FluentIcons.document_pdf_20_regular,
        author: 'Jane Doe',
        initials: 'JD',
        status: FluentPresenceStatus.offline,
        lastUpdated: 'Tue at 9:30 AM',
        timestamp: 3,
        lastUpdate: 'You shared this in a Teams chat',
        lastUpdateIcon: FluentIcons.people_20_regular,
      ),
    ];

List<Widget> _multipleControlledCells(_MultipleControlledItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

// `FluentDataGrid` selection is always controlled: `selectedRows` is the truth
// and the grid never mutates it. Upstream's uncontrolled twin above therefore
// looks identical here — the difference is only in which prop upstream reads.
Widget _multipleSelectControlled(BuildContext context) =>
    const _MultipleControlled();

class _MultipleControlled extends StatefulWidget {
  const _MultipleControlled();

  @override
  State<_MultipleControlled> createState() => _MultipleControlledState();
}

class _MultipleControlledState extends State<_MultipleControlled> {
  Set<int> _selectedRows = <int>{1};

  @override
  Widget build(BuildContext context) => FluentDataGrid(
    columns: const <FluentDataGridColumn>[
      FluentDataGridColumn(header: Text('File')),
      FluentDataGridColumn(header: Text('Author')),
      FluentDataGridColumn(header: Text('Last updated')),
      FluentDataGridColumn(header: Text('Last update')),
    ],
    rows: <FluentDataGridRow>[
      for (final _MultipleControlledItem item in _multipleControlledItems)
        FluentDataGridRow(cells: _multipleControlledCells(item)),
    ],
    selectionMode: FluentDataGridSelectionMode.multiple,
    selectedRows: _selectedRows,
    onSelectionChanged: (Set<int> next) => setState(() => _selectedRows = next),
  );
}
// #enddocregion components-datagrid--multiple-select-controlled

// #docregion components-datagrid--single-select
typedef _SingleSelectItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_SingleSelectItem> _singleSelectItems = <_SingleSelectItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
    lastUpdate: 'You edited this',
    lastUpdateIcon: FluentIcons.edit_20_regular,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
    lastUpdate: 'You shared this in a Teams chat',
    lastUpdateIcon: FluentIcons.people_20_regular,
  ),
];

List<Widget> _singleSelectCells(_SingleSelectItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

Widget _singleSelect(BuildContext context) => const _SingleSelect();

class _SingleSelect extends StatefulWidget {
  const _SingleSelect();

  @override
  State<_SingleSelect> createState() => _SingleSelectState();
}

class _SingleSelectState extends State<_SingleSelect> {
  Set<int> _selected = <int>{1};

  @override
  Widget build(BuildContext context) => FluentDataGrid(
    columns: const <FluentDataGridColumn>[
      FluentDataGridColumn(header: Text('File')),
      FluentDataGridColumn(header: Text('Author')),
      FluentDataGridColumn(header: Text('Last updated')),
      FluentDataGridColumn(header: Text('Last update')),
    ],
    rows: <FluentDataGridRow>[
      for (final _SingleSelectItem item in _singleSelectItems)
        FluentDataGridRow(cells: _singleSelectCells(item)),
    ],
    selectionMode: FluentDataGridSelectionMode.single,
    selectedRows: _selected,
    onSelectionChanged: (Set<int> next) => setState(() => _selected = next),
  );
}
// #enddocregion components-datagrid--single-select

// #docregion components-datagrid--single-select-controlled
typedef _SingleControlledItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_SingleControlledItem> _singleControlledItems =
    <_SingleControlledItem>[
      (
        file: 'Meeting notes',
        fileIcon: FluentIcons.document_20_regular,
        author: 'Max Mustermann',
        initials: 'MM',
        status: FluentPresenceStatus.available,
        lastUpdated: '7h ago',
        timestamp: 1,
        lastUpdate: 'You edited this',
        lastUpdateIcon: FluentIcons.edit_20_regular,
      ),
      (
        file: 'Thursday presentation',
        fileIcon: FluentIcons.folder_20_regular,
        author: 'Erika Mustermann',
        initials: 'EM',
        status: FluentPresenceStatus.busy,
        lastUpdated: 'Yesterday at 1:45 PM',
        timestamp: 2,
        lastUpdate: 'You recently opened this',
        lastUpdateIcon: FluentIcons.open_20_regular,
      ),
      (
        file: 'Training recording',
        fileIcon: FluentIcons.video_20_regular,
        author: 'John Doe',
        initials: 'JD',
        status: FluentPresenceStatus.away,
        lastUpdated: 'Yesterday at 1:45 PM',
        timestamp: 2,
        lastUpdate: 'You recently opened this',
        lastUpdateIcon: FluentIcons.open_20_regular,
      ),
      (
        file: 'Purchase order',
        fileIcon: FluentIcons.document_pdf_20_regular,
        author: 'Jane Doe',
        initials: 'JD',
        status: FluentPresenceStatus.offline,
        lastUpdated: 'Tue at 9:30 AM',
        timestamp: 3,
        lastUpdate: 'You shared this in a Teams chat',
        lastUpdateIcon: FluentIcons.people_20_regular,
      ),
    ];

List<Widget> _singleControlledCells(_SingleControlledItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

// Single select is a radio group, so the grid honours the lowest index in
// `selectedRows` and ignores the rest.
Widget _singleSelectControlled(BuildContext context) =>
    const _SingleControlled();

class _SingleControlled extends StatefulWidget {
  const _SingleControlled();

  @override
  State<_SingleControlled> createState() => _SingleControlledState();
}

class _SingleControlledState extends State<_SingleControlled> {
  Set<int> _selectedRows = <int>{1};

  @override
  Widget build(BuildContext context) => FluentDataGrid(
    columns: const <FluentDataGridColumn>[
      FluentDataGridColumn(header: Text('File')),
      FluentDataGridColumn(header: Text('Author')),
      FluentDataGridColumn(header: Text('Last updated')),
      FluentDataGridColumn(header: Text('Last update')),
    ],
    rows: <FluentDataGridRow>[
      for (final _SingleControlledItem item in _singleControlledItems)
        FluentDataGridRow(cells: _singleControlledCells(item)),
    ],
    selectionMode: FluentDataGridSelectionMode.single,
    selectedRows: _selectedRows,
    onSelectionChanged: (Set<int> next) => setState(() => _selectedRows = next),
  );
}
// #enddocregion components-datagrid--single-select-controlled

// #docregion components-datagrid--subtle-selection
typedef _SubtleItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_SubtleItem> _subtleItems = <_SubtleItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
    lastUpdate: 'You edited this',
    lastUpdateIcon: FluentIcons.edit_20_regular,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
    lastUpdate: 'You shared this in a Teams chat',
    lastUpdateIcon: FluentIcons.people_20_regular,
  ),
];

List<Widget> _subtleCells(_SubtleItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

// `subtleSelection` hides the checkbox until the row is hovered, focused or
// checked. Figma's `DataGrid` sets have no such mode and `FluentDataGrid` has no
// prop for it, so the selection column stays visible — the rest of the story,
// multi-select with row 2 checked, is intact.
Widget _subtleSelection(BuildContext context) => const _SubtleSelection();

class _SubtleSelection extends StatefulWidget {
  const _SubtleSelection();

  @override
  State<_SubtleSelection> createState() => _SubtleSelectionState();
}

class _SubtleSelectionState extends State<_SubtleSelection> {
  Set<int> _selected = <int>{1};

  @override
  Widget build(BuildContext context) => FluentDataGrid(
    columns: const <FluentDataGridColumn>[
      FluentDataGridColumn(header: Text('File')),
      FluentDataGridColumn(header: Text('Author')),
      FluentDataGridColumn(header: Text('Last updated')),
      FluentDataGridColumn(header: Text('Last update')),
    ],
    rows: <FluentDataGridRow>[
      for (final _SubtleItem item in _subtleItems)
        FluentDataGridRow(cells: _subtleCells(item)),
    ],
    selectionMode: FluentDataGridSelectionMode.multiple,
    selectedRows: _selected,
    onSelectionChanged: (Set<int> next) => setState(() => _selected = next),
  );
}
// #enddocregion components-datagrid--subtle-selection

// #docregion components-datagrid--selection-appearance
typedef _AppearanceItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_AppearanceItem> _appearanceItems = <_AppearanceItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
    lastUpdate: 'You edited this',
    lastUpdateIcon: FluentIcons.edit_20_regular,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
    lastUpdate: 'You shared this in a Teams chat',
    lastUpdateIcon: FluentIcons.people_20_regular,
  ),
];

List<Widget> _appearanceCells(_AppearanceItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

Widget _selectionAppearance(BuildContext context) =>
    const _SelectionAppearance();

class _SelectionAppearance extends StatefulWidget {
  const _SelectionAppearance();

  @override
  State<_SelectionAppearance> createState() => _SelectionAppearanceState();
}

class _SelectionAppearanceState extends State<_SelectionAppearance> {
  Set<int> _selected = <int>{1};

  @override
  Widget build(BuildContext context) => FluentDataGrid(
    columns: const <FluentDataGridColumn>[
      FluentDataGridColumn(header: Text('File')),
      FluentDataGridColumn(header: Text('Author')),
      FluentDataGridColumn(header: Text('Last updated')),
      FluentDataGridColumn(header: Text('Last update')),
    ],
    rows: <FluentDataGridRow>[
      for (final _AppearanceItem item in _appearanceItems)
        FluentDataGridRow(cells: _appearanceCells(item)),
    ],
    selectionMode: FluentDataGridSelectionMode.multiple,
    selectionAppearance: FluentDataGridSelectionAppearance.neutral,
    selectedRows: _selected,
    onSelectionChanged: (Set<int> next) => setState(() => _selected = next),
  );
}
// #enddocregion components-datagrid--selection-appearance

// #docregion components-datagrid--resizable-columns
typedef _ResizableItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_ResizableItem> _resizableItems = <_ResizableItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
    lastUpdate: 'You edited this',
    lastUpdateIcon: FluentIcons.edit_20_regular,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
    lastUpdate: 'You shared this in a Teams chat',
    lastUpdateIcon: FluentIcons.people_20_regular,
  ),
];

List<Widget> _resizableCells(_ResizableItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

// Upstream's keyboard escape hatch: `Menu openOnContext` on every header cell.
// A right-click (secondary tap) opens it here, which is the same gesture.
Widget _resizableHeader(String label) => FluentMenu(
  items: const <FluentMenuItem>[
    FluentMenuItem(label: Text('Keyboard Column Resizing')),
  ],
  builder: (BuildContext context, VoidCallback toggle) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onSecondaryTap: toggle,
    child: Text(label),
  ),
);

// `FluentDataGrid` has no drag handle and no `columnSizingOptions`: its
// documented answer is `FluentDataGridColumn.width`, so upstream's
// `defaultWidth` values land there and the two unsized columns share what is
// left — which is upstream's auto-fit behaviour, minus the dragging.
Widget _resizableColumns(BuildContext context) => const _ResizableColumns();

class _ResizableColumns extends StatefulWidget {
  const _ResizableColumns();

  @override
  State<_ResizableColumns> createState() => _ResizableColumnsState();
}

class _ResizableColumnsState extends State<_ResizableColumns> {
  Set<String> _selected = <String>{};
  int? _sortColumn;
  FluentDataGridSortDirection _sortDirection =
      FluentDataGridSortDirection.ascending;

  List<_ResizableItem> get _sorted {
    final int? column = _sortColumn;
    if (column == null) return _resizableItems;
    final List<_ResizableItem> items = <_ResizableItem>[..._resizableItems];
    items.sort(
      (_ResizableItem a, _ResizableItem b) => switch (column) {
        0 => a.file.compareTo(b.file),
        1 => a.author.compareTo(b.author),
        2 => a.timestamp.compareTo(b.timestamp),
        _ => a.lastUpdate.compareTo(b.lastUpdate),
      },
    );
    return _sortDirection == FluentDataGridSortDirection.descending
        ? items.reversed.toList()
        : items;
  }

  void _sort(int column) => setState(() {
    if (_sortColumn == column) {
      _sortDirection = _sortDirection == FluentDataGridSortDirection.ascending
          ? FluentDataGridSortDirection.descending
          : FluentDataGridSortDirection.ascending;
    } else {
      _sortColumn = column;
      _sortDirection = FluentDataGridSortDirection.ascending;
    }
  });

  @override
  Widget build(BuildContext context) {
    final List<_ResizableItem> items = _sorted;
    return FluentDataGrid(
      columns: <FluentDataGridColumn>[
        FluentDataGridColumn(
          header: _resizableHeader('File'),
          width: 120,
          sortable: true,
        ),
        FluentDataGridColumn(
          header: _resizableHeader('Author'),
          width: 180,
          sortable: true,
        ),
        FluentDataGridColumn(
          header: _resizableHeader('Last updated'),
          sortable: true,
        ),
        FluentDataGridColumn(
          header: _resizableHeader('Last update'),
          sortable: true,
        ),
      ],
      rows: <FluentDataGridRow>[
        for (final _ResizableItem item in items)
          FluentDataGridRow(cells: _resizableCells(item)),
      ],
      sortColumn: _sortColumn,
      sortDirection: _sortDirection,
      onSort: _sort,
      selectionMode: FluentDataGridSelectionMode.multiple,
      selectedRows: <int>{
        for (int i = 0; i < items.length; i++)
          if (_selected.contains(items[i].file)) i,
      },
      onSelectionChanged: (Set<int> next) => setState(() {
        _selected = <String>{for (final int i in next) items[i].file};
      }),
    );
  }
}
// #enddocregion components-datagrid--resizable-columns

// #docregion components-datagrid--resizable-columns-disable-auto-fit
typedef _NoAutoFitItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_NoAutoFitItem> _noAutoFitItems = <_NoAutoFitItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
    lastUpdate: 'You edited this',
    lastUpdateIcon: FluentIcons.edit_20_regular,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
    lastUpdate: 'You shared this in a Teams chat',
    lastUpdateIcon: FluentIcons.people_20_regular,
  ),
];

List<Widget> _noAutoFitCells(_NoAutoFitItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

Widget _noAutoFitHeader(String label) => FluentMenu(
  items: const <FluentMenuItem>[
    FluentMenuItem(label: Text('Keyboard Column Resizing')),
  ],
  builder: (BuildContext context, VoidCallback toggle) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onSecondaryTap: toggle,
    child: Text(label),
  ),
);

// `autoFitColumns: false` is what upstream's `<div style={{overflowX: 'auto'}}>`
// wrapper is for: the grid is laid out wider than its container and the
// container scrolls. `FluentDataGrid` has no such option, so the demo states the
// total width itself and puts the same horizontal scroller around it.
Widget _resizableColumnsDisableAutoFit(BuildContext context) =>
    const _NoAutoFit();

class _NoAutoFit extends StatefulWidget {
  const _NoAutoFit();

  @override
  State<_NoAutoFit> createState() => _NoAutoFitState();
}

class _NoAutoFitState extends State<_NoAutoFit> {
  Set<String> _selected = <String>{};
  int? _sortColumn;
  FluentDataGridSortDirection _sortDirection =
      FluentDataGridSortDirection.ascending;

  List<_NoAutoFitItem> get _sorted {
    final int? column = _sortColumn;
    if (column == null) return _noAutoFitItems;
    final List<_NoAutoFitItem> items = <_NoAutoFitItem>[..._noAutoFitItems];
    items.sort(
      (_NoAutoFitItem a, _NoAutoFitItem b) => switch (column) {
        0 => a.file.compareTo(b.file),
        1 => a.author.compareTo(b.author),
        2 => a.timestamp.compareTo(b.timestamp),
        _ => a.lastUpdate.compareTo(b.lastUpdate),
      },
    );
    return _sortDirection == FluentDataGridSortDirection.descending
        ? items.reversed.toList()
        : items;
  }

  void _sort(int column) => setState(() {
    if (_sortColumn == column) {
      _sortDirection = _sortDirection == FluentDataGridSortDirection.ascending
          ? FluentDataGridSortDirection.descending
          : FluentDataGridSortDirection.ascending;
    } else {
      _sortColumn = column;
      _sortDirection = FluentDataGridSortDirection.ascending;
    }
  });

  @override
  Widget build(BuildContext context) {
    final List<_NoAutoFitItem> items = _sorted;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1100,
        child: FluentDataGrid(
          columns: <FluentDataGridColumn>[
            FluentDataGridColumn(
              header: _noAutoFitHeader('File'),
              width: 180,
              sortable: true,
            ),
            FluentDataGridColumn(
              header: _noAutoFitHeader('Author'),
              width: 180,
              sortable: true,
            ),
            FluentDataGridColumn(
              header: _noAutoFitHeader('Last updated'),
              sortable: true,
            ),
            FluentDataGridColumn(
              header: _noAutoFitHeader('Last update'),
              sortable: true,
            ),
          ],
          rows: <FluentDataGridRow>[
            for (final _NoAutoFitItem item in items)
              FluentDataGridRow(cells: _noAutoFitCells(item)),
          ],
          sortColumn: _sortColumn,
          sortDirection: _sortDirection,
          onSort: _sort,
          selectionMode: FluentDataGridSelectionMode.multiple,
          selectedRows: <int>{
            for (int i = 0; i < items.length; i++)
              if (_selected.contains(items[i].file)) i,
          },
          onSelectionChanged: (Set<int> next) => setState(() {
            _selected = <String>{for (final int i in next) items[i].file};
          }),
        ),
      ),
    );
  }
}
// #enddocregion components-datagrid--resizable-columns-disable-auto-fit

// #docregion components-datagrid--virtualization
typedef _VirtualizedItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_VirtualizedItem> _virtualizedItems = <_VirtualizedItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
    lastUpdate: 'You edited this',
    lastUpdateIcon: FluentIcons.edit_20_regular,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
    lastUpdate: 'You shared this in a Teams chat',
    lastUpdateIcon: FluentIcons.people_20_regular,
  ),
];

List<Widget> _virtualizedCells(_VirtualizedItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

// Upstream embeds an iframe pointing at the `react-data-grid-react-window`
// extension package. There is no iframe here, and `FluentDataGrid` documents
// virtualisation as out of scope with the same remedy this uses: a bounded
// scroll view over a longer list. The four upstream rows are repeated to fill
// it.
//
// ponytail: every row is still built. Swap the body for a `ListView.builder`
// over composed `FluentDataGridRenderRow`s if the list ever runs to thousands.
Widget _virtualization(BuildContext context) => SizedBox(
  height: 500,
  child: SingleChildScrollView(
    child: FluentDataGrid(
      columns: const <FluentDataGridColumn>[
        FluentDataGridColumn(header: Text('File')),
        FluentDataGridColumn(header: Text('Author')),
        FluentDataGridColumn(header: Text('Last updated')),
        FluentDataGridColumn(header: Text('Last update')),
      ],
      rows: <FluentDataGridRow>[
        for (int i = 0; i < 40; i++)
          FluentDataGridRow(
            cells: _virtualizedCells(
              _virtualizedItems[i % _virtualizedItems.length],
            ),
          ),
      ],
    ),
  ),
);
// #enddocregion components-datagrid--virtualization

// #docregion components-datagrid--custom-row-id
typedef _CustomRowIdItem = ({
  String file,
  IconData fileIcon,
  String author,
  String initials,
  FluentPresenceStatus status,
  String lastUpdated,
  int timestamp,
  String lastUpdate,
  IconData lastUpdateIcon,
});

const List<_CustomRowIdItem> _customRowIdItems = <_CustomRowIdItem>[
  (
    file: 'Meeting notes',
    fileIcon: FluentIcons.document_20_regular,
    author: 'Max Mustermann',
    initials: 'MM',
    status: FluentPresenceStatus.available,
    lastUpdated: '7h ago',
    timestamp: 1,
    lastUpdate: 'You edited this',
    lastUpdateIcon: FluentIcons.edit_20_regular,
  ),
  (
    file: 'Thursday presentation',
    fileIcon: FluentIcons.folder_20_regular,
    author: 'Erika Mustermann',
    initials: 'EM',
    status: FluentPresenceStatus.busy,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Training recording',
    fileIcon: FluentIcons.video_20_regular,
    author: 'John Doe',
    initials: 'JD',
    status: FluentPresenceStatus.away,
    lastUpdated: 'Yesterday at 1:45 PM',
    timestamp: 2,
    lastUpdate: 'You recently opened this',
    lastUpdateIcon: FluentIcons.open_20_regular,
  ),
  (
    file: 'Purchase order',
    fileIcon: FluentIcons.document_pdf_20_regular,
    author: 'Jane Doe',
    initials: 'JD',
    status: FluentPresenceStatus.offline,
    lastUpdated: 'Tue at 9:30 AM',
    timestamp: 3,
    lastUpdate: 'You shared this in a Teams chat',
    lastUpdateIcon: FluentIcons.people_20_regular,
  ),
];

List<Widget> _customRowIdCells(_CustomRowIdItem item) => <Widget>[
  FluentDataGridCell(leading: Icon(item.fileIcon), child: Text(item.file)),
  FluentDataGridCell(
    leading: FluentAvatar(
      name: item.author,
      initials: item.initials,
      status: item.status,
      size: FluentAvatarSize.size24,
    ),
    child: Text(item.author),
  ),
  FluentDataGridCell(child: Text(item.lastUpdated)),
  FluentDataGridCell(
    leading: Icon(item.lastUpdateIcon),
    child: Text(item.lastUpdate),
  ),
];

// `getRowId` gives every row a key taken from the data rather than its index.
// `FluentDataGrid` selects by index, so the demo holds the file names — which is
// the point of the story — and translates on the way in and out. The list above
// the grid is upstream's read-only mirror of that set.
Widget _customRowId(BuildContext context) => const _CustomRowId();

class _CustomRowId extends StatefulWidget {
  const _CustomRowId();

  @override
  State<_CustomRowId> createState() => _CustomRowIdState();
}

class _CustomRowIdState extends State<_CustomRowId> {
  Set<String> _selectedRows = <String>{'Thursday presentation'};

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final _CustomRowIdItem item in _customRowIdItems)
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: <Widget>[
              const Text('•'),
              FluentCheckbox(
                checked: _selectedRows.contains(item.file),
                label: Text(item.file),
              ),
            ],
          ),
        ),
      const SizedBox(height: 12),
      FluentDataGrid(
        columns: const <FluentDataGridColumn>[
          FluentDataGridColumn(header: Text('File')),
          FluentDataGridColumn(header: Text('Author')),
          FluentDataGridColumn(header: Text('Last updated')),
          FluentDataGridColumn(header: Text('Last update')),
        ],
        rows: <FluentDataGridRow>[
          for (final _CustomRowIdItem item in _customRowIdItems)
            FluentDataGridRow(cells: _customRowIdCells(item)),
        ],
        selectionMode: FluentDataGridSelectionMode.multiple,
        selectedRows: <int>{
          for (int i = 0; i < _customRowIdItems.length; i++)
            if (_selectedRows.contains(_customRowIdItems[i].file)) i,
        },
        onSelectionChanged: (Set<int> next) => setState(() {
          _selectedRows = <String>{
            for (final int i in next) _customRowIdItems[i].file,
          };
        }),
      ),
    ],
  );
}

// #enddocregion components-datagrid--custom-row-id
