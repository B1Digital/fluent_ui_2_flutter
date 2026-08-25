import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Legends docs page.
///
/// Sections, titles and sample data are upstream's, verbatim. Each section's
/// demo is delimited by a `#docregion` whose id is the section id, so the
/// "Show code" panel can read this file back and print exactly the code that
/// rendered.
const DocsPage legendsPage = DocsPage(
  id: 'charts-legends',
  title: 'Legends',
  description:
      'A legend describes data visualized in the chart. The legends can '
      'wrap based upon the space available for them. If there is not '
      'enough space to show all legends on a single line, the legends '
      'fall into an overflow menu. A button is shown to open the '
      'overflow menu and displays the number of legends in it.',
  source: 'lib/pages/charts_legends.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Content',
      body:
          '#### Legend Actions\n'
          'The legends are selectable. Action to be performed upon '
          'clicking a certain legend can be customized. Refer to the '
          '`action`, `hoverAction` and `onMouseOutAction` properties to '
          'customize these actions.\n'
          '#### Legend shapes and colors\n'
          'Use shape to customize the legend shape. Legend support '
          'different shapes like rectangle, triangle, diamond, circle, '
          'pyramid, hexagon. Use `stripePattern` to have stripe pattern '
          'applied to the legend shape. If `isLineLegendInBarChart` is '
          'set, the legend will have the shape of a line with height '
          '4px. All other legend shapes have a height of 12px.\n'
          '#### Legend overflow\n'
          '`overflowText` describes the overflow text. `overflowProps` '
          'can be used to set properties like overflow layout direction '
          'to be stacked/vertical, overflow side to be start/end, '
          'overflow styling and more.\n'
          'Legends can be wrapped to the next line if the labels are '
          'very long.\n',
    ),
    ProseBlock(
      title: 'Accessibility',
      body:
          '- Legends are readable via screen readers. The user can '
          'navigate through the entire legend section by using the Left '
          'and Right arrow keys.\n'
          '- Legends can reflow to accommodate zooming in to 400%.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-legends--legends-basic',
      title: 'Legends Basic',
      builder: _legendsBasic,
    ),
    DocsSection(
      id: 'charts-legends--legends-overflow',
      title: 'Legends Overflow',
      builder: _legendsOverflow,
    ),
    DocsSection(
      id: 'charts-legends--legends-styled',
      title: 'Legends Styled',
      builder: _legendsStyled,
    ),
    DocsSection(
      id: 'charts-legends--legends-wrap-lines',
      title: 'Legends Wrap Lines',
      builder: _legendsWrapLines,
    ),
    DocsSection(
      id: 'charts-legends--legends-controlled',
      title: 'Legends Controlled',
      builder: _legendsControlled,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'legends',
      type: 'List<FluentChartLegendItem>',
      description: 'The rows, in order.',
    ),
    PropRow(
      name: 'selectionMode',
      type: 'FluentChartLegendSelectionMode',
      defaultValue: 'FluentChartLegendSelectionMode.single',
      description: 'Whether one legend or several may be selected at once.',
    ),
    PropRow(
      name: 'allowFocusOnLegends',
      type: 'bool',
      defaultValue: 'true',
      description:
          'Whether the rows are reachable by keyboard and carry listbox '
          'semantics.',
    ),
    PropRow(
      name: 'centerLegends',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether each line of legends is centred in the strip.',
    ),
    PropRow(
      name: 'enabledWrapLines',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether rows wrap onto further lines instead of collapsing into an '
          'overflow menu.',
    ),
    PropRow(
      name: 'overflowText',
      type: 'String',
      defaultValue: "'more'",
      description:
          "The word in the overflow trigger's `+{n} overflowText` label.",
    ),
    PropRow(
      name: 'selectedLegends',
      type: 'List<String>?',
      defaultValue: 'null',
      description:
          'Controlled selection. Supplying it makes the widget controlled and '
          'the parent owns every change.',
    ),
    PropRow(
      name: 'defaultSelectedLegends',
      type: 'List<String>?',
      defaultValue: 'null',
      description: 'Initial selection for the uncontrolled case.',
    ),
    PropRow(
      name: 'onChange',
      type: 'void Function(List<String>, FluentChartLegendItem?)?',
      defaultValue: 'null',
      description: 'Fired with the new selection and the row that caused it.',
    ),
    PropRow(
      name: 'shape',
      type: 'FluentChartLegendShape?',
      defaultValue: 'null',
      description: 'Overrides every per-item shape when set.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentChartLegendStyle?',
      defaultValue: 'null',
      description: 'The highest-precedence style layer.',
    ),
  ],
);

// #docregion charts-legends--legends-basic
Widget _legendsBasic(BuildContext context) => const _LegendsBasic();

class _LegendsBasic extends StatefulWidget {
  const _LegendsBasic();

  @override
  State<_LegendsBasic> createState() => _LegendsBasicState();
}

class _LegendsBasicState extends State<_LegendsBasic> {
  // Upstream's `action` callbacks raise a browser `alert()`. Flutter has no
  // blocking alert, so the same message is written under the strip instead.
  String _message = '';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentChartLegend(
        legends: <FluentChartLegendItem>[
          FluentChartLegendItem(
            title: 'Legend 1',
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
            onAction: () => setState(() => _message = 'Legend1 clicked'),
          ),
          FluentChartLegendItem(
            title: 'Legend 2',
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
            onAction: () => setState(() => _message = 'Legend2 clicked'),
          ),
          FluentChartLegendItem(
            title: 'Legend 3',
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
            shape: FluentChartLegendShape.diamond,
            onAction: () => setState(() => _message = 'Legend3 clicked'),
          ),
          FluentChartLegendItem(
            title: 'Legend 4',
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
            shape: FluentChartLegendShape.triangle,
            onAction: () => setState(() => _message = 'Legend4 clicked'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(_message),
    ],
  );
}
// #enddocregion charts-legends--legends-basic

// #docregion charts-legends--legends-overflow
// Upstream's per-legend `action`, `hoverAction` and `onMouseOutAction` here only
// write to the browser console, which has no Flutter counterpart, so they are
// left off rather than ported as empty closures.
Widget _legendsOverflow(BuildContext context) => FluentChartLegend(
  overflowText: 'Overflow Items',
  allowFocusOnLegends: true,
  selectionMode: FluentChartLegendSelectionMode.single,
  legends: <FluentChartLegendItem>[
    FluentChartLegendItem(
      title: 'Legend 1',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
    ),
    FluentChartLegendItem(
      title: 'Legend 2',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
    ),
    FluentChartLegendItem(
      title: 'Legend 3',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
    ),
    FluentChartLegendItem(
      title: 'Legend 4',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
    ),
    FluentChartLegendItem(
      title: 'Legend 5',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
    ),
    FluentChartLegendItem(
      title: 'Legend 6',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
    ),
    FluentChartLegendItem(
      title: 'Legend 7',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
    ),
    FluentChartLegendItem(
      title: 'Legend 8',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color12),
    ),
    FluentChartLegendItem(
      title: 'Legend 9',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color13),
    ),
    FluentChartLegendItem(
      title: 'Legend 10',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color14),
    ),
    FluentChartLegendItem(
      title: 'Legend 11',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color15),
    ),
    FluentChartLegendItem(
      title: 'Legend 12',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color16),
    ),
    FluentChartLegendItem(
      title: 'Legend 13',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color17),
    ),
    FluentChartLegendItem(
      title: 'Legend 14',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color18),
    ),
    FluentChartLegendItem(
      title: 'Legend 15',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color19),
    ),
    FluentChartLegendItem(
      title: 'Legend 16',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color20),
    ),
    FluentChartLegendItem(
      title: 'Legend 17',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color21),
    ),
  ],
);
// #enddocregion charts-legends--legends-overflow

// #docregion charts-legends--legends-styled
Widget _legendsStyled(BuildContext context) => FluentChartLegend(
  overflowText: 'Overflow Items',
  allowFocusOnLegends: true,
  selectionMode: FluentChartLegendSelectionMode.single,
  legends: <FluentChartLegendItem>[
    FluentChartLegendItem(
      title: 'Legend 1',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
    ),
    FluentChartLegendItem(
      title: 'Legend 2',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
    ),
    FluentChartLegendItem(
      title: 'Legend 3',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
    ),
    FluentChartLegendItem(
      title: 'Legend 4',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
    ),
    FluentChartLegendItem(
      title: 'Legend 5',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
    ),
    FluentChartLegendItem(
      title: 'Legend 6',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
    ),
    FluentChartLegendItem(
      title: 'Legend 7',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
    ),
    FluentChartLegendItem(
      title: 'Legend 8',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
    ),
    FluentChartLegendItem(
      title: 'Legend 9',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
    ),
    FluentChartLegendItem(
      title: 'Legend 10',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
    ),
    FluentChartLegendItem(
      title: 'Legend 11',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
    ),
    FluentChartLegendItem(
      title: 'Legend 12',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color12),
    ),
    FluentChartLegendItem(
      title: 'Legend 13',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color13),
    ),
    FluentChartLegendItem(
      title: 'Legend 14',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color14),
    ),
    FluentChartLegendItem(
      title: 'Legend 15',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color15),
    ),
    FluentChartLegendItem(
      title: 'Legend 16',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color16),
    ),
    FluentChartLegendItem(
      title: 'Legend 17',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color17),
    ),
  ],
);
// #enddocregion charts-legends--legends-styled

// #docregion charts-legends--legends-wrap-lines
// Upstream's per-legend `action`, `hoverAction` and `onMouseOutAction` here only
// write to the browser console, which has no Flutter counterpart, so they are
// left off rather than ported as empty closures.
Widget _legendsWrapLines(BuildContext context) => FluentChartLegend(
  overflowText: 'Overflow Items',
  allowFocusOnLegends: true,
  selectionMode: FluentChartLegendSelectionMode.single,
  enabledWrapLines: true,
  legends: <FluentChartLegendItem>[
    FluentChartLegendItem(
      title: 'Legend 1',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
    ),
    FluentChartLegendItem(
      title: 'Legend 2',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
    ),
    FluentChartLegendItem(
      title: 'Legend 3',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
    ),
    FluentChartLegendItem(
      title: 'Legend 4',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
    ),
    FluentChartLegendItem(
      title: 'Legend 5',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
    ),
    FluentChartLegendItem(
      title: 'Legend 6',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
    ),
    FluentChartLegendItem(
      title: 'Legend 7',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
    ),
    FluentChartLegendItem(
      title: 'Legend 8',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
    ),
    FluentChartLegendItem(
      title: 'Legend 9',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
    ),
    FluentChartLegendItem(
      title: 'Legend 10',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
    ),
    FluentChartLegendItem(
      title: 'Legend 11',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
    ),
    FluentChartLegendItem(
      title: 'Legend 12',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color12),
    ),
    FluentChartLegendItem(
      title: 'Legend 13',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color13),
    ),
    FluentChartLegendItem(
      title: 'Legend 14',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color14),
    ),
    FluentChartLegendItem(
      title: 'Legend 15',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color15),
    ),
    FluentChartLegendItem(
      title: 'Legend 16',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color16),
    ),
    FluentChartLegendItem(
      title: 'Legend 17',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color17),
    ),
  ],
);
// #enddocregion charts-legends--legends-wrap-lines

// #docregion charts-legends--legends-controlled
final List<FluentChartLegendItem> _controlledLegends = <FluentChartLegendItem>[
  FluentChartLegendItem(
    title: 'Legend 1',
    color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
  ),
  FluentChartLegendItem(
    title: 'Legend 2',
    color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
  ),
  FluentChartLegendItem(
    title: 'Legend 3',
    color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
    shape: FluentChartLegendShape.diamond,
  ),
  FluentChartLegendItem(
    title: 'Legend 4',
    color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
    shape: FluentChartLegendShape.triangle,
  ),
];

Widget _legendsControlled(BuildContext context) => const _LegendsControlled();

class _LegendsControlled extends StatefulWidget {
  const _LegendsControlled();

  @override
  State<_LegendsControlled> createState() => _LegendsControlledState();
}

class _LegendsControlledState extends State<_LegendsControlled> {
  List<String> _selectedLegends = <String>[];

  void _onChange(List<String> keys, FluentChartLegendItem? currentLegend) {
    setState(() => _selectedLegends = keys);
  }

  void _handleSelect1And3() {
    setState(() => _selectedLegends = <String>['Legend 1', 'Legend 3']);
  }

  void _handleSelect2And4() {
    setState(() => _selectedLegends = <String>['Legend 2', 'Legend 4']);
  }

  void _handleSelectAll() {
    setState(
      () => _selectedLegends = _controlledLegends
          .map((FluentChartLegendItem legend) => legend.title)
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: <Widget>[
          FluentButton(
            onPressed: _handleSelect1And3,
            child: const Text('Select 1 and 3'),
          ),
          FluentButton(
            onPressed: _handleSelect2And4,
            child: const Text('Select 2 and 4'),
          ),
          FluentButton(
            onPressed: _handleSelectAll,
            child: const Text('Select all'),
          ),
        ],
      ),
      const SizedBox(height: 15),
      FluentChartLegend(
        legends: _controlledLegends,
        selectionMode: FluentChartLegendSelectionMode.multiple,
        selectedLegends: _selectedLegends,
        onChange: _onChange,
      ),
      const SizedBox(height: 10),
      Text('Selected legends: ${_selectedLegends.join(', ')}'),
    ],
  );
}

// #enddocregion charts-legends--legends-controlled
