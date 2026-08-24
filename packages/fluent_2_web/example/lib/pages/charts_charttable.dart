import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The ChartTable docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage chartTablePage = DocsPage(
  id: 'charts-charttable',
  title: 'ChartTable',
  description: '',
  source: 'lib/pages/charts_charttable.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-charttable--chart-table-basic',
      title: 'Chart Table Basic',
      description:
          'Basic chart table example with customizable width, height, styling '
          'options, and different data sets.',
      builder: _chartTableBasic,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'headers',
      type: 'List<FluentChartTableCell>',
      description: 'Header cells, left to right.',
    ),
    PropRow(
      name: 'rows',
      type: 'List<List<FluentChartTableCell>>?',
      defaultValue: 'null',
      description: 'Body rows. A null or empty list renders the header alone.',
    ),
    PropRow(
      name: 'width',
      type: 'double?',
      defaultValue: 'null',
      description: 'Hard width. Null honours the incoming constraints.',
    ),
    PropRow(
      name: 'height',
      type: 'double?',
      defaultValue: 'null',
      description: "Hard height. Null uses the style's defaultHeight of 650.",
    ),
    PropRow(
      name: 'columnWidth',
      type: 'double?',
      defaultValue: 'null',
      description:
          "Fixed width of every column's own box, exclusive of the grid line "
          'it shares with its neighbour.',
    ),
    PropRow(
      name: 'chartTitle',
      type: 'String?',
      defaultValue: 'null',
      description:
          "Optional title above the grid. Reserves the style's titleHeight of "
          '30 out of the total.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentChartTableStyle?',
      defaultValue: 'null',
      description:
          'Style layered over the derived defaults and the nearest '
          'FluentChartTableTheme.',
    ),
  ],
);

// #docregion charts-charttable--chart-table-basic
Widget _chartTableBasic(BuildContext context) => const _ChartTableBasic();

class _ChartTableBasic extends StatefulWidget {
  const _ChartTableBasic();

  @override
  State<_ChartTableBasic> createState() => _ChartTableBasicState();
}

class _ChartTableBasicState extends State<_ChartTableBasic> {
  double _width = 700;
  double _height = 200;
  bool _showStyledCells = false;
  String _tableVariant = 'basic';

  // Basic table headers
  static const List<FluentChartTableCell> _basicHeaders =
      <FluentChartTableCell>[
        FluentChartTableCell(value: 'Product'),
        FluentChartTableCell(value: 'Q1 Sales'),
        FluentChartTableCell(value: 'Q2 Sales'),
        FluentChartTableCell(value: 'Q3 Sales'),
        FluentChartTableCell(value: 'Q4 Sales'),
        FluentChartTableCell(value: 'Total'),
      ];

  // Basic table rows
  static const List<List<FluentChartTableCell>> _basicRows =
      <List<FluentChartTableCell>>[
        <FluentChartTableCell>[
          FluentChartTableCell(value: 'Product A'),
          FluentChartTableCell(value: 25000),
          FluentChartTableCell(value: 30000),
          FluentChartTableCell(value: 28000),
          FluentChartTableCell(value: 35000),
          FluentChartTableCell(value: 118000),
        ],
        <FluentChartTableCell>[
          FluentChartTableCell(value: 'Product B'),
          FluentChartTableCell(value: 18000),
          FluentChartTableCell(value: 22000),
          FluentChartTableCell(value: 25000),
          FluentChartTableCell(value: 27000),
          FluentChartTableCell(value: 92000),
        ],
        <FluentChartTableCell>[
          FluentChartTableCell(value: 'Product C'),
          FluentChartTableCell(value: 32000),
          FluentChartTableCell(value: 28000),
          FluentChartTableCell(value: 31000),
          FluentChartTableCell(value: 29000),
          FluentChartTableCell(value: 120000),
        ],
        <FluentChartTableCell>[
          FluentChartTableCell(value: 'Product D'),
          FluentChartTableCell(value: 15000),
          FluentChartTableCell(value: 19000),
          FluentChartTableCell(value: 21000),
          FluentChartTableCell(value: 23000),
          FluentChartTableCell(value: 78000),
        ],
      ];

  // Financial data example
  static const List<FluentChartTableCell> _financialHeaders =
      <FluentChartTableCell>[
        FluentChartTableCell(value: 'Metric'),
        FluentChartTableCell(value: '2021'),
        FluentChartTableCell(value: '2022'),
        FluentChartTableCell(value: '2023'),
        FluentChartTableCell(value: 'Change %'),
      ];

  // Styled table rows with conditional formatting.
  //
  // Upstream also sets `textAlign: 'right'` and `padding: '8px'` on the sales
  // cells. FluentChartTableCell carries only the two properties ChartTable
  // itself reads — a colour and a background — so alignment and padding stay
  // with the widget's own cellPadding.
  List<List<FluentChartTableCell>> _styledRows(FluentColors colors) =>
      _basicRows
          .map(
            (List<FluentChartTableCell> row) => <FluentChartTableCell>[
              for (int cellIndex = 0; cellIndex < row.length; cellIndex++)
                _styledCell(colors, row, cellIndex),
            ],
          )
          .toList();

  FluentChartTableCell _styledCell(
    FluentColors colors,
    List<FluentChartTableCell> row,
    int cellIndex,
  ) {
    final FluentChartTableCell cell = row[cellIndex];
    if (cellIndex == 0) {
      // Product name column - keep original
      return cell;
    }
    if (cellIndex == row.length - 1) {
      // Total column - highlight with background color
      return FluentChartTableCell(
        value: cell.value,
        backgroundColor: colors.neutralBackground3,
        textStyle: TextStyle(
          fontWeight: FluentFontWeight.semibold,
          color: colors.neutralForeground1,
        ),
      );
    }
    // Sales columns - color based on value
    final num value = cell.value! as num;
    final FluentPaletteFamily family = value > 30000
        ? FluentPaletteFamily.green
        : value > 20000
        ? FluentPaletteFamily.yellow
        : FluentPaletteFamily.red;
    return FluentChartTableCell(
      value: cell.value,
      backgroundColor: colors.palette.background2Rest(family),
      textStyle: TextStyle(color: colors.palette.foreground2Rest(family)),
    );
  }

  List<List<FluentChartTableCell>> _financialRows(FluentColors colors) {
    final Color green = colors.palette.foreground2Rest(
      FluentPaletteFamily.green,
    );
    final Color red = colors.palette.foreground2Rest(FluentPaletteFamily.red);
    return <List<FluentChartTableCell>>[
      <FluentChartTableCell>[
        const FluentChartTableCell(value: 'Revenue (\$M)'),
        const FluentChartTableCell(value: 150.5),
        const FluentChartTableCell(value: 175.2),
        const FluentChartTableCell(value: 198.7),
        FluentChartTableCell(
          value: '+13.4%',
          textStyle: TextStyle(color: green),
        ),
      ],
      <FluentChartTableCell>[
        const FluentChartTableCell(value: 'Operating Income (\$M)'),
        const FluentChartTableCell(value: 45.2),
        const FluentChartTableCell(value: 52.8),
        const FluentChartTableCell(value: 59.1),
        FluentChartTableCell(
          value: '+11.9%',
          textStyle: TextStyle(color: green),
        ),
      ],
      <FluentChartTableCell>[
        const FluentChartTableCell(value: 'Net Income (\$M)'),
        const FluentChartTableCell(value: 32.1),
        const FluentChartTableCell(value: 38.9),
        const FluentChartTableCell(value: 42.3),
        FluentChartTableCell(
          value: '+8.7%',
          textStyle: TextStyle(color: green),
        ),
      ],
      <FluentChartTableCell>[
        const FluentChartTableCell(value: 'Expenses (\$M)'),
        const FluentChartTableCell(value: 105.3),
        const FluentChartTableCell(value: 122.4),
        const FluentChartTableCell(value: 139.6),
        FluentChartTableCell(
          value: '+14.1%',
          textStyle: TextStyle(color: red),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final FluentColors colors = FluentTheme.of(context).colors;
    final bool financial = _tableVariant == 'financial';
    final List<FluentChartTableCell> headers = financial
        ? _financialHeaders
        : _basicHeaders;
    final List<List<FluentChartTableCell>> rows = financial
        ? _financialRows(colors)
        : _showStyledCells
        ? _styledRows(colors)
        : _basicRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: <Widget>[
        Wrap(
          spacing: 20,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const Text('Change Width:'),
            SizedBox(
              width: 120,
              child: FluentSlider(
                value: _width,
                min: 300,
                max: 1200,
                semanticLabel: 'Change Width',
                semanticFormatter: (double value) =>
                    "current value ${value.round()}', Minimum 300 and Maximum "
                    '1200',
                onChanged: (double value) => setState(() => _width = value),
              ),
            ),
            Text('${_width.round()}px'),
            const Text('Change Height:'),
            SizedBox(
              width: 120,
              child: FluentSlider(
                value: _height,
                min: 200,
                max: 800,
                semanticLabel: 'Change Height',
                semanticFormatter: (double value) =>
                    "current value ${value.round()}', Minimum 200 and Maximum "
                    '800',
                onChanged: (double value) => setState(() => _height = value),
              ),
            ),
            Text('${_height.round()}px'),
          ],
        ),
        FluentField(
          label: const Text('Table Type'),
          child: FluentRadioGroup<String>(
            value: _tableVariant,
            onChanged: (String value) => setState(() => _tableVariant = value),
            children: const <Widget>[
              FluentRadio<String>(
                value: 'basic',
                label: Text('Sales Data Example'),
              ),
              FluentRadio<String>(
                value: 'financial',
                label: Text('Financial Data Example'),
              ),
            ],
          ),
        ),
        FluentSwitch(
          checked: _showStyledCells,
          // Upstream disables the switch on the financial data set, and a null
          // callback is how a Fluent switch is disabled.
          onChanged: financial
              ? null
              : (bool value) => setState(() => _showStyledCells = value),
          label: Text(
            _showStyledCells ? 'Styled cells ON' : 'Styled cells OFF',
          ),
        ),
        // The slider reaches 1200, which is wider than the docs column, so the
        // table box scrolls rather than overflowing.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: FluentChartTable(
            width: _width,
            height: _height,
            headers: headers,
            rows: rows,
          ),
        ),
      ],
    );
  }
}

// #enddocregion charts-charttable--chart-table-basic
