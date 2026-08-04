import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// One grid per `Size`, then the selection, sorting and disabled states.
///
/// Nothing in the DataGrid styles files declares a transition, so the
/// reduced-motion image must be byte-identical to the ordinary one. A diff
/// there means a transition crept in.
void main() {
  FluentDataGrid build({
    FluentDataGridSize size = FluentDataGridSize.medium,
    FluentDataGridSelectionMode selectionMode =
        FluentDataGridSelectionMode.none,
    FluentDataGridSelectionAppearance appearance =
        FluentDataGridSelectionAppearance.neutral,
    FluentDataGridHeaderWeight headerWeight =
        FluentDataGridHeaderWeight.semibold,
    Set<int> selected = const <int>{},
    bool sortable = false,
    bool enabled = true,
  }) => FluentDataGrid(
    size: size,
    selectionMode: selectionMode,
    selectionAppearance: appearance,
    headerWeight: headerWeight,
    selectedRows: selected,
    onSelectionChanged: selectionMode == FluentDataGridSelectionMode.none
        ? null
        : (_) {},
    sortColumn: sortable ? 0 : null,
    sortDirection: sortable ? FluentDataGridSortDirection.ascending : null,
    onSort: sortable ? (_) {} : null,
    enabled: enabled,
    semanticLabel: 'Files',
    columns: <FluentDataGridColumn>[
      FluentDataGridColumn(header: const Text('File'), sortable: sortable),
      const FluentDataGridColumn(header: Text('Author'), width: 120),
    ],
    rows: <FluentDataGridRow>[
      for (var r = 0; r < 3; r++)
        FluentDataGridRow(
          cells: <Widget>[
            FluentDataGridCell(
              leading: const Icon(FluentIcons.document_20_regular),
              child: Text('Report $r'),
            ),
            FluentDataGridCell(
              emphasis: FluentDataGridCellEmphasis.secondary,
              child: Text('Ada $r'),
            ),
          ],
        ),
    ],
  );

  Widget cell(Widget child) => SizedBox(width: 380, child: child);

  Widget scene() => goldenGrid(columns: 2, <Widget>[
    for (final size in FluentDataGridSize.values) cell(build(size: size)),
    cell(
      build(
        selectionMode: FluentDataGridSelectionMode.multiple,
        selected: const <int>{1},
      ),
    ),
    cell(
      build(
        selectionMode: FluentDataGridSelectionMode.multiple,
        appearance: FluentDataGridSelectionAppearance.brand,
        selected: const <int>{0, 1},
      ),
    ),
    cell(
      build(
        selectionMode: FluentDataGridSelectionMode.single,
        selected: const <int>{2},
      ),
    ),
    cell(build(sortable: true)),
    cell(build(headerWeight: FluentDataGridHeaderWeight.regular)),
    cell(
      build(
        enabled: false,
        selectionMode: FluentDataGridSelectionMode.multiple,
      ),
    ),
  ]);

  goldenGridTest('data_grid', scene, surfaceSize: const Size(1100, 1600));

  goldenGridTest(
    'data_grid',
    scene,
    surfaceSize: const Size(1100, 1600),
    reducedMotion: true,
    suffix: '.reduced_motion',
  );
}
