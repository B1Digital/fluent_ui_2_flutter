import 'package:fluent_2_web/src/charts/internal/plotly/json_guard.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a sankey self-loop is a cycle', () {
    expect(
      findSankeyCycles(<String, Object?>{
        'node': <String, Object?>{
          'label': <Object?>['a', 'b'],
        },
        'link': <String, Object?>{
          'source': <Object?>[0, 1],
          'target': <Object?>[1, 0],
          'value': <Object?>[1, 1],
        },
      }),
      isTrue,
      reason:
          'PlotlySchemaConverter.ts:350-373 depth-first search flags the back edge.',
    );
  });

  test('a link with an invalid value contributes no edge', () {
    expect(
      findSankeyCycles(<String, Object?>{
        'node': <String, Object?>{
          'label': <Object?>['a', 'b'],
        },
        'link': <String, Object?>{
          'source': <Object?>[0, 1],
          'target': <Object?>[1, 0],
          'value': <Object?>[1, null],
        },
      }),
      isFalse,
      reason:
          'PlotlySchemaConverter.ts:340-345 skips links whose value, source or '
          'target is invalid.',
    );
  });

  test('the five-point corner test recognises a plotly.py gantt scatter', () {
    expect(
      isScatterGanttChart(<String, Object?>{
        'mode': 'none',
        'fill': 'toself',
        'x': <Object?>[0, 5, 5, 0, null],
        'y': <Object?>[1, 1, 2, 2, null],
      }, foundScatterGantt: false),
      isTrue,
      reason:
          'PlotlySchemaConverter.ts:711-722 walks x with stride 5 and checks '
          'the four corners.',
    );
  });

  test(
    'the invisible-marker companion is a gantt only after a corner trace was seen',
    () {
      const companion = <String, Object?>{
        'mode': 'markers',
        'marker': <String, Object?>{'size': 1, 'opacity': 0},
        'name': '',
        'showlegend': false,
      };
      expect(
        isScatterGanttChart(companion, foundScatterGantt: false),
        isFalse,
        reason: 'PlotlySchemaConverter.ts:735 requires foundScatterGantt.',
      );
      expect(
        isScatterGanttChart(companion, foundScatterGantt: true),
        isTrue,
        reason: 'PlotlySchemaConverter.ts:729-738.',
      );
    },
  );

  test('a horizontal bar with string x values is rejected', () {
    expect(
      () => validatePlotlyTrace(<String, Object?>{
        'type': 'bar',
        'orientation': 'h',
        'x': <Object?>['a', 'b'],
        'y': <Object?>[1, 2],
      }, null),
      throwsA(
        isA<PlotlySchemaException>().having(
          (e) => e.message,
          'message',
          contains('string x values not supported'),
        ),
      ),
      reason: 'PlotlySchemaConverter.ts:274-278.',
    );
  });

  test('a log axis invalidates a bar trace', () {
    expect(
      () => validatePlotlyTrace(
        <String, Object?>{
          'type': 'bar',
          'y': <Object?>[1, 2],
          'yaxis': 'y2',
        },
        <String, Object?>{
          'yaxis2': <String, Object?>{'type': 'log'},
        },
      ),
      throwsA(isA<PlotlySchemaException>()),
      reason:
          'PlotlySchemaConverter.ts:402-405 with getAxisKey resolving yaxis2.',
    );
  });

  test('an area scatter that would need the VSBC fallback is rejected', () {
    expect(
      () => validatePlotlyTrace(<String, Object?>{
        'type': 'scatter',
        'fill': 'tozeroy',
        'mode': 'lines',
        'x': <Object?>['a', 'b'],
        'y': <Object?>[1, 2],
      }, null),
      throwsA(
        isA<PlotlySchemaException>().having(
          (e) => e.message,
          'message',
          contains(
            'Fallback to VerticalStackedBarChart is not allowed for Area Charts',
          ),
        ),
      ),
      reason: 'PlotlySchemaConverter.ts:309-313.',
    );
  });

  test('an indicator without a gauge mode is rejected', () {
    expect(
      () => validatePlotlyTrace(<String, Object?>{
        'type': 'indicator',
        'mode': 'number',
      }, null),
      throwsA(isA<PlotlySchemaException>()),
      reason: 'PlotlySchemaConverter.ts:387-391.',
    );
  });
}
