import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentDataGrid], its cells and its selection column.
final StorySection dataGridStories = StorySection(
  component: 'Data grid',
  description:
      'A header row over body rows, with sortable columns, checkbox or radio '
      'row selection, and four row heights. The whole grid is a single tab '
      'stop: arrow keys rove between cells, and a cell hands focus to whatever '
      'control it holds.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every axis on one grid: the row height, the selection affordance '
          'and its fill, the header weight, and whether the grid takes input '
          'at all.',
      knobs: const [
        OptionKnob<FluentDataGridSize>(
          label: 'Size',
          id: 'size',
          initial: FluentDataGridSize.medium,
          options: FluentDataGridSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentDataGridSelectionMode>(
          label: 'Selection',
          id: 'selection',
          initial: FluentDataGridSelectionMode.multiple,
          options: FluentDataGridSelectionMode.values,
          labelOf: _selectionLabel,
        ),
        OptionKnob<FluentDataGridSelectionAppearance>(
          label: 'Selection fill',
          id: 'appearance',
          initial: FluentDataGridSelectionAppearance.neutral,
          options: FluentDataGridSelectionAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentDataGridHeaderWeight>(
          label: 'Header weight',
          id: 'headerWeight',
          initial: FluentDataGridHeaderWeight.semibold,
          options: FluentDataGridHeaderWeight.values,
          labelOf: _weightLabel,
        ),
        BoolKnob(label: 'Show header', id: 'showHeader', initial: true),
        BoolKnob(label: 'Enabled', id: 'enabled', initial: true),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'Smaller, small, medium and large — 24, 33, 45 and 59 tall. Only '
          'smaller steps down to the caption ramp; the other three stay on '
          'body text and grow the row instead.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Multi-select',
      description:
          'A checkbox column plus a tri-state select-all in the header. The '
          'selection is controlled — the buttons above write the same set the '
          'grid reads, so nothing on the page can disagree with it.',
      builder: _multiSelectBuilder,
    ),
    const Story(
      name: 'Single select',
      description:
          'A radio column takes exactly one row, and the header has no '
          'select-all: a radio group cannot express "all".',
      builder: _singleSelectBuilder,
    ),
    const Story(
      name: 'Selection fill',
      description:
          'The neutral fill is the subtle selected surface; the brand fill is '
          'the brand 2 surface. Hover a selected row in either to see its own '
          'selected-hover token.',
      builder: _appearanceBuilder,
    ),
    const Story(
      name: 'Sort',
      description:
          'Sorting is controlled: the header reports which column was '
          'activated, and the caller decides the order and re-sorts the rows. '
          'Activating the sorted column flips the arrow.',
      builder: _sortBuilder,
    ),
    Story(
      name: 'Cell layouts',
      description:
          'A leading icon, a second line, a link, secondary emphasis, and a '
          'cell whose content is left unstyled. Every one follows the owning '
          "row's hover and selected ramp.",
      knobs: const [
        OptionKnob<FluentDataGridSize>(
          label: 'Size',
          id: 'size',
          initial: FluentDataGridSize.large,
          options: FluentDataGridSize.values,
          labelOf: _sizeLabel,
        ),
      ],
      builder: _layoutsBuilder,
    ),
    const Story(
      name: 'Cell actions',
      description:
          'Buttons in a trailing cell keep their own tap target and their own '
          'focus stop: pressing one runs its action and leaves the row '
          'selection alone.',
      builder: _actionsBuilder,
    ),
    const Story(
      name: 'Keyboard navigation',
      description:
          'Tab once to enter, then arrows to move between cells, Home and End '
          'for the ends of a row, Control-Home and Control-End for the grid. A '
          'cell with a control focuses the control; a cell of plain text takes '
          'the ring itself.',
      builder: _keyboardBuilder,
    ),
    const Story(
      name: 'Row activation',
      description:
          'A row can carry its own callback, which replaces the selection '
          "toggle. Rows without one are inert — no hover fill, no cursor, no "
          'tap action in the semantics tree.',
      builder: _activationBuilder,
    ),
    Story(
      name: 'Column widths',
      description:
          'A column with a width is fixed; the rest share what is left in '
          'equal parts. There is no drag handle — a width is set, not resized.',
      knobs: const [
        NumberKnob(
          label: 'Modified width',
          id: 'width',
          initial: 160,
          min: 100,
          max: 280,
          step: 10,
        ),
      ],
      builder: _widthsBuilder,
    ),
    Story(
      name: 'Long grid',
      description:
          'A long grid scrolls inside a bounded box. Every row is built up '
          'front: there is no virtualised variant.',
      knobs: const [
        NumberKnob(
          label: 'Rows',
          id: 'rows',
          initial: 50,
          min: 10,
          max: 300,
          step: 10,
        ),
      ],
      builder: _longBuilder,
    ),
  ],
);

/// Name, author, when it changed, and the glyph for its kind.
typedef _File = (String, String, String, IconData);

const List<_File> _files = <_File>[
  (
    'Q3 report.docx',
    'Ada Lovelace',
    'Yesterday 9:41',
    FluentIcons.document_20_regular,
  ),
  (
    'Budget.xlsx',
    'Grace Hopper',
    'Tuesday 14:02',
    FluentIcons.document_table_20_regular,
  ),
  (
    'Launch deck.pptx',
    'Alan Turing',
    'Monday 8:15',
    FluentIcons.slide_layout_20_regular,
  ),
  (
    'Re-entry.pdf',
    'Katherine Johnson',
    '12 May',
    FluentIcons.document_pdf_20_regular,
  ),
  ('Wind tunnel.png', 'Mary Jackson', '3 May', FluentIcons.image_20_regular),
];

String _sizeLabel(FluentDataGridSize value) => value.name;

String _selectionLabel(FluentDataGridSelectionMode value) => value.name;

String _appearanceLabel(FluentDataGridSelectionAppearance value) => value.name;

String _weightLabel(FluentDataGridHeaderWeight value) => value.name;

/// The three columns every story starts from.
List<FluentDataGridColumn> _columns({bool sortable = false}) =>
    <FluentDataGridColumn>[
      FluentDataGridColumn(header: const Text('Name'), sortable: sortable),
      FluentDataGridColumn(header: const Text('Author'), sortable: sortable),
      FluentDataGridColumn(
        header: const Text('Modified'),
        sortable: sortable,
        width: 160,
      ),
    ];

/// One row per file, with the kind glyph in the leading slot.
List<FluentDataGridRow> _rows(List<_File> files) => <FluentDataGridRow>[
  for (final (name, author, modified, icon) in files)
    FluentDataGridRow(
      semanticLabel: name,
      cells: <Widget>[
        FluentDataGridCell(leading: Icon(icon), child: Text(name)),
        FluentDataGridCell(child: Text(author)),
        FluentDataGridCell(
          emphasis: FluentDataGridCellEmphasis.secondary,
          child: Text(modified),
        ),
      ],
    ),
];

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  return _SelectableGrid(
    size: knobs.get<FluentDataGridSize>('size', FluentDataGridSize.medium),
    selectionMode: knobs.get<FluentDataGridSelectionMode>(
      'selection',
      FluentDataGridSelectionMode.multiple,
    ),
    appearance: knobs.get<FluentDataGridSelectionAppearance>(
      'appearance',
      FluentDataGridSelectionAppearance.neutral,
    ),
    headerWeight: knobs.get<FluentDataGridHeaderWeight>(
      'headerWeight',
      FluentDataGridHeaderWeight.semibold,
    ),
    showHeader: knobs.get<bool>('showHeader', true),
    enabled: knobs.get<bool>('enabled', true),
    initial: const <int>{1},
  );
}

Widget _sizesBuilder(BuildContext context) => const _Cases(
  children: [
    ('Smaller — 24', _SelectableGrid(size: FluentDataGridSize.smaller)),
    ('Small — 33', _SelectableGrid(size: FluentDataGridSize.small)),
    ('Medium — 45', _SelectableGrid()),
    ('Large — 59', _SelectableGrid(size: FluentDataGridSize.large)),
  ],
);

Widget _multiSelectBuilder(BuildContext context) =>
    const _SelectableGrid(initial: <int>{0, 3}, controls: true);

Widget _singleSelectBuilder(BuildContext context) => const _SelectableGrid(
  selectionMode: FluentDataGridSelectionMode.single,
  initial: <int>{1},
);

Widget _appearanceBuilder(BuildContext context) => const _Cases(
  children: [
    ('Neutral', _SelectableGrid(initial: <int>{0, 1})),
    (
      'Brand',
      _SelectableGrid(
        appearance: FluentDataGridSelectionAppearance.brand,
        initial: <int>{0, 1},
      ),
    ),
  ],
);

Widget _sortBuilder(BuildContext context) => const _SortableGrid();

Widget _actionsBuilder(BuildContext context) => const _ActionGrid();

Widget _keyboardBuilder(BuildContext context) => const _ActionGrid(
  selectionMode: FluentDataGridSelectionMode.single,
  links: true,
);

Widget _activationBuilder(BuildContext context) => const _ActivatedGrid();

Widget _layoutsBuilder(BuildContext context) {
  final size = KnobsScope.of(
    context,
  ).get<FluentDataGridSize>('size', FluentDataGridSize.large);
  return FluentDataGrid(
    size: size,
    semanticLabel: 'Cell layouts',
    columns: const <FluentDataGridColumn>[
      FluentDataGridColumn(header: Text('Layout')),
      FluentDataGridColumn(header: Text('Cell')),
    ],
    rows: <FluentDataGridRow>[
      const FluentDataGridRow(
        semanticLabel: 'Text',
        cells: <Widget>[
          FluentDataGridCell(child: Text('Text')),
          FluentDataGridCell(child: Text('Q3 report.docx')),
        ],
      ),
      const FluentDataGridRow(
        semanticLabel: 'Leading glyph',
        cells: <Widget>[
          FluentDataGridCell(child: Text('Leading glyph')),
          FluentDataGridCell(
            leading: Icon(FluentIcons.document_20_regular),
            child: Text('Q3 report.docx'),
          ),
        ],
      ),
      const FluentDataGridRow(
        semanticLabel: 'Two line text',
        cells: <Widget>[
          FluentDataGridCell(child: Text('Two line text')),
          FluentDataGridCell(
            leading: Icon(FluentIcons.document_20_regular),
            secondary: Text('Edited by Ada Lovelace'),
            child: Text('Q3 report.docx'),
          ),
        ],
      ),
      FluentDataGridRow(
        semanticLabel: 'Link',
        cells: <Widget>[
          const FluentDataGridCell(child: Text('Link')),
          FluentDataGridCell(
            emphasis: FluentDataGridCellEmphasis.none,
            child: FluentLink(
              onPressed: _noop,
              child: const Text('Open in the browser'),
            ),
          ),
        ],
      ),
      const FluentDataGridRow(
        semanticLabel: 'Secondary text',
        cells: <Widget>[
          FluentDataGridCell(child: Text('Secondary text')),
          FluentDataGridCell(
            emphasis: FluentDataGridCellEmphasis.secondary,
            child: Text('Yesterday 9:41'),
          ),
        ],
      ),
      FluentDataGridRow(
        semanticLabel: 'Unstyled',
        cells: <Widget>[
          const FluentDataGridCell(child: Text('Unstyled')),
          FluentDataGridCell(
            emphasis: FluentDataGridCellEmphasis.none,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: FluentSpacing.s,
              children: const <Widget>[
                FluentBadge(
                  appearance: FluentBadgeAppearance.tint,
                  child: Text('Shared'),
                ),
                FluentBadge(
                  appearance: FluentBadgeAppearance.tint,
                  color: FluentBadgeColor.warning,
                  child: Text('Checked out'),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _widthsBuilder(BuildContext context) {
  final width = KnobsScope.of(context).get<double>('width', 160);
  return FluentDataGrid(
    semanticLabel: 'Files',
    columns: <FluentDataGridColumn>[
      const FluentDataGridColumn(header: Text('Name')),
      const FluentDataGridColumn(header: Text('Author')),
      FluentDataGridColumn(header: const Text('Modified'), width: width),
    ],
    rows: _rows(_files),
  );
}

Widget _longBuilder(BuildContext context) {
  final count = KnobsScope.of(context).get<double>('rows', 50).round();
  return SizedBox(
    height: 320,
    child: SingleChildScrollView(
      child: FluentDataGrid(
        size: FluentDataGridSize.small,
        semanticLabel: 'Files',
        columns: const <FluentDataGridColumn>[
          FluentDataGridColumn(header: Text('Name')),
          FluentDataGridColumn(header: Text('Author')),
          FluentDataGridColumn(header: Text('Modified'), width: 160),
        ],
        rows: _rows(<_File>[
          for (var i = 0; i < count; i++)
            (
              'File ${i + 1}.docx',
              _files[i % _files.length].$2,
              _files[i % _files.length].$3,
              _files[i % _files.length].$4,
            ),
        ]),
      ),
    ),
  );
}

/// A link in a cell is a demonstration of the slot, not of the link.
void _noop() {}

/// A grid that keeps its own selection, so the gallery shows a real control
/// rather than a frozen one.
class _SelectableGrid extends StatefulWidget {
  const _SelectableGrid({
    this.size = FluentDataGridSize.medium,
    this.selectionMode = FluentDataGridSelectionMode.multiple,
    this.appearance = FluentDataGridSelectionAppearance.neutral,
    this.headerWeight = FluentDataGridHeaderWeight.semibold,
    this.showHeader = true,
    this.enabled = true,
    this.controls = false,
    this.initial = const <int>{},
  });

  final FluentDataGridSize size;
  final FluentDataGridSelectionMode selectionMode;
  final FluentDataGridSelectionAppearance appearance;
  final FluentDataGridHeaderWeight headerWeight;
  final bool showHeader;
  final bool enabled;

  /// Whether to put Select all / Clear buttons above the grid, which write the
  /// same set the grid reads.
  final bool controls;

  final Set<int> initial;

  @override
  State<_SelectableGrid> createState() => _SelectableGridState();
}

class _SelectableGridState extends State<_SelectableGrid> {
  late Set<int> _selected = widget.initial;

  @override
  void didUpdateWidget(_SelectableGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching the knob to single mid-story would otherwise leave two rows
    // holding a filled dot, which the mode cannot reach on its own.
    if (widget.selectionMode == FluentDataGridSelectionMode.single &&
        _selected.length > 1) {
      _selected = <int>{_selected.reduce((a, b) => a < b ? a : b)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectable = widget.selectionMode != FluentDataGridSelectionMode.none;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: <Widget>[
        if (widget.controls)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: FluentSpacing.s,
            children: <Widget>[
              FluentButton(
                size: FluentButtonSize.small,
                onPressed: () => setState(
                  () => _selected = <int>{
                    for (var i = 0; i < _files.length; i++) i,
                  },
                ),
                child: const Text('Select all'),
              ),
              FluentButton(
                size: FluentButtonSize.small,
                onPressed: () => setState(() => _selected = <int>{}),
                child: const Text('Clear'),
              ),
            ],
          ),
        FluentDataGrid(
          size: widget.size,
          selectionMode: widget.selectionMode,
          selectionAppearance: widget.appearance,
          headerWeight: widget.headerWeight,
          showHeader: widget.showHeader,
          enabled: widget.enabled,
          selectedRows: _selected,
          onSelectionChanged: selectable
              ? (next) => setState(() => _selected = next)
              : null,
          semanticLabel: 'Files',
          columns: _columns(),
          rows: _rows(_files),
        ),
        if (selectable)
          _Caption('${_selected.length} of ${_files.length} selected'),
      ],
    );
  }
}

/// A grid whose sort column and direction are held by the caller, which is the
/// only way [FluentDataGrid] sorts: it reports, the caller reorders.
class _SortableGrid extends StatefulWidget {
  const _SortableGrid();

  @override
  State<_SortableGrid> createState() => _SortableGridState();
}

class _SortableGridState extends State<_SortableGrid> {
  int? _column = 0;
  FluentDataGridSortDirection? _direction =
      FluentDataGridSortDirection.ascending;

  void _sort(int column) => setState(() {
    if (_column != column) {
      _column = column;
      _direction = FluentDataGridSortDirection.ascending;
      return;
    }
    _direction = _direction == FluentDataGridSortDirection.ascending
        ? FluentDataGridSortDirection.descending
        : FluentDataGridSortDirection.ascending;
  });

  String _field(_File file, int column) => switch (column) {
    0 => file.$1,
    1 => file.$2,
    _ => file.$3,
  };

  @override
  Widget build(BuildContext context) {
    final column = _column;
    final sorted = <_File>[..._files];
    if (column != null) {
      sorted.sort((a, b) {
        final order = _field(a, column).compareTo(_field(b, column));
        return _direction == FluentDataGridSortDirection.descending
            ? -order
            : order;
      });
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: <Widget>[
        FluentDataGrid(
          semanticLabel: 'Files',
          sortColumn: _column,
          sortDirection: _direction,
          onSort: _sort,
          columns: _columns(sortable: true),
          rows: _rows(sorted),
        ),
        _Caption(
          column == null
              ? 'Unsorted'
              : 'Sorted by column ${column + 1}, ${_direction?.name}',
        ),
      ],
    );
  }
}

/// Rows whose trailing cell holds real buttons, with a readout of the last one
/// pressed so the reader can see the row's own selection stay put.
class _ActionGrid extends StatefulWidget {
  const _ActionGrid({
    this.selectionMode = FluentDataGridSelectionMode.multiple,
    this.links = false,
  });

  final FluentDataGridSelectionMode selectionMode;

  /// Whether the name cell is a link rather than plain text, so the row holds
  /// two different kinds of focusable content.
  final bool links;

  @override
  State<_ActionGrid> createState() => _ActionGridState();
}

class _ActionGridState extends State<_ActionGrid> {
  Set<int> _selected = <int>{0};
  String _last = 'Nothing pressed yet';

  void _record(String message) => setState(() => _last = message);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.m,
    children: <Widget>[
      FluentDataGrid(
        semanticLabel: 'Files',
        selectionMode: widget.selectionMode,
        selectedRows: _selected,
        onSelectionChanged: (next) => setState(() => _selected = next),
        columns: const <FluentDataGridColumn>[
          FluentDataGridColumn(header: Text('Name')),
          FluentDataGridColumn(header: Text('Author')),
          FluentDataGridColumn(header: Text('Actions'), width: 132),
        ],
        rows: <FluentDataGridRow>[
          for (final (name, author, _, icon) in _files)
            FluentDataGridRow(
              semanticLabel: name,
              cells: <Widget>[
                FluentDataGridCell(
                  leading: Icon(icon),
                  emphasis: widget.links
                      ? FluentDataGridCellEmphasis.none
                      : FluentDataGridCellEmphasis.primary,
                  child: widget.links
                      ? FluentLink(
                          onPressed: () => _record('Opened $name'),
                          child: Text(name),
                        )
                      : Text(name),
                ),
                FluentDataGridCell(child: Text(author)),
                FluentDataGridCell(
                  emphasis: FluentDataGridCellEmphasis.none,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FluentButton.icon(
                        icon: const Icon(FluentIcons.edit_20_regular),
                        semanticLabel: 'Rename $name',
                        appearance: FluentButtonAppearance.subtle,
                        size: FluentButtonSize.small,
                        onPressed: () => _record('Renamed $name'),
                      ),
                      FluentButton.icon(
                        icon: const Icon(FluentIcons.share_20_regular),
                        semanticLabel: 'Share $name',
                        appearance: FluentButtonAppearance.subtle,
                        size: FluentButtonSize.small,
                        onPressed: () => _record('Shared $name'),
                      ),
                      FluentButton.icon(
                        icon: const Icon(FluentIcons.delete_20_regular),
                        semanticLabel: 'Delete $name',
                        appearance: FluentButtonAppearance.subtle,
                        size: FluentButtonSize.small,
                        onPressed: () => _record('Deleted $name'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      _Caption(_last),
    ],
  );
}

/// Rows carrying their own callback, next to rows carrying none.
class _ActivatedGrid extends StatefulWidget {
  const _ActivatedGrid();

  @override
  State<_ActivatedGrid> createState() => _ActivatedGridState();
}

class _ActivatedGridState extends State<_ActivatedGrid> {
  String _last = 'No row opened yet';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.m,
    children: <Widget>[
      FluentDataGrid(
        semanticLabel: 'Files',
        columns: _columns(),
        rows: <FluentDataGridRow>[
          for (var i = 0; i < _files.length; i++)
            FluentDataGridRow(
              semanticLabel: _files[i].$1,
              // The last two rows are archived: no callback, so no hover fill
              // and nothing to activate.
              onPressed: i < _files.length - 2
                  ? () => setState(() => _last = 'Opened ${_files[i].$1}')
                  : null,
              cells: <Widget>[
                FluentDataGridCell(
                  leading: Icon(_files[i].$4),
                  child: Text(_files[i].$1),
                ),
                FluentDataGridCell(child: Text(_files[i].$2)),
                FluentDataGridCell(
                  emphasis: FluentDataGridCellEmphasis.secondary,
                  child: Text(
                    i < _files.length - 2 ? _files[i].$3 : 'Archived',
                  ),
                ),
              ],
            ),
        ],
      ),
      _Caption(_last),
    ],
  );
}

/// The readout under a grid, on the caption ramp.
class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Text(
      text,
      style: theme.typography.caption1.copyWith(
        color: theme.colors.neutralForeground3,
      ),
    );
  }
}

/// Side-by-side cases under a caption. A grid stretches to its parent, so each
/// case is given a width of its own.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.xxl,
      runSpacing: FluentSpacing.xl,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: <Widget>[
        for (final (caption, child) in children)
          SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FluentSpacing.xs,
              children: <Widget>[
                Text(
                  caption,
                  style: theme.typography.caption1.copyWith(
                    color: theme.colors.neutralForeground3,
                  ),
                ),
                child,
              ],
            ),
          ),
      ],
    );
  }
}
