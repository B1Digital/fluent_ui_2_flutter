import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/annotations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an id is the slugified text capped at 32 characters', () {
    expect(
      createAnnotationId(
        'Hello, World! This is a very long annotation label',
        3,
      ),
      'annotation-3-hello-world-this-is-a-very-long-',
      reason:
          'PlotlySchemaAdapter.ts:716-729 lower-cases, replaces [^a-z0-9]+ '
          'with a hyphen, trims leading and trailing hyphens and slices the '
          'slug to 32 characters. The trim runs BEFORE the slice, so a slice '
          'that lands on a separator keeps the trailing hyphen: the 32-'
          'character prefix of `hello-world-this-is-a-very-long-annotation-'
          'label` is `hello-world-this-is-a-very-long-`. The plan expected '
          '`annotation-3-hello-world-this-is-a-very`, which is the 26-'
          'character prefix and matches no step of :716-729.',
    );
  });

  test('an empty slug falls back to the bare index form', () {
    expect(
      createAnnotationId('!!!', 0),
      'annotation-0',
      reason: 'PlotlySchemaAdapter.ts:727-728.',
    );
  });

  test('the five arrow dash patterns match the line dash table', () {
    expect(
      mapArrowDashToPattern('solid'),
      isNull,
      reason: 'PlotlySchemaAdapter.ts:766-791.',
    );
    expect(
      mapArrowDashToPattern('dot'),
      '1, 5',
      reason: 'PlotlySchemaAdapter.ts:766-791.',
    );
    expect(
      mapArrowDashToPattern('dash'),
      '5, 5',
      reason: 'PlotlySchemaAdapter.ts:766-791.',
    );
    expect(
      mapArrowDashToPattern('longdash'),
      '10, 5',
      reason: 'PlotlySchemaAdapter.ts:766-791.',
    );
    expect(
      mapArrowDashToPattern('dashdot'),
      '5, 5, 1, 5',
      reason: 'PlotlySchemaAdapter.ts:766-791.',
    );
    expect(
      mapArrowDashToPattern('longdashdot'),
      '10, 5, 1, 5',
      reason: 'PlotlySchemaAdapter.ts:766-791.',
    );
  });

  test('an unrecognised dash falls through to the numeric passthrough', () {
    expect(
      mapArrowDashToPattern('4  2'),
      '4 2',
      reason:
          'PlotlySchemaAdapter.ts:785-788 collapses runs of whitespace and '
          'returns a bare numeric list unchanged.',
    );
    expect(
      mapArrowDashToPattern(' Wobbly '),
      ' Wobbly ',
      reason:
          'PlotlySchemaAdapter.ts:789 returns the ORIGINAL value, not the '
          'normalised one, when the regex does not match.',
    );
  });

  test('arrowhead and startarrowhead together give a double-headed arrow', () {
    expect(
      mapArrowsideToArrow(<String, Object?>{
        'arrowhead': 2,
        'startarrowhead': 3,
      }),
      FluentChartAnnotationArrowHead.both,
      reason: 'PlotlySchemaAdapter.ts:733-763.',
    );
    expect(
      mapArrowsideToArrow(<String, Object?>{'arrowhead': 2}),
      FluentChartAnnotationArrowHead.end,
      reason: 'PlotlySchemaAdapter.ts:733-763.',
    );
    expect(
      mapArrowsideToArrow(const <String, Object?>{}),
      FluentChartAnnotationArrowHead.none,
      reason: 'PlotlySchemaAdapter.ts:733-763 with neither head set.',
    );
    expect(
      mapArrowsideToArrow(<String, Object?>{'arrowside': 'End+Start'}),
      FluentChartAnnotationArrowHead.both,
      reason:
          'PlotlySchemaAdapter.ts:737-741 lower-cases arrowside and tests it '
          'with substring containment, so `end+start` sets both.',
    );
  });

  test(
    'an arrow with no explicit offset takes the default vertical offset',
    () {
      final annotation = convertPlotlyAnnotation(
        <String, Object?>{'text': 'a', 'x': 1, 'y': 2, 'showarrow': true},
        0,
        layout: null,
      );
      expect(
        annotation!.layout!.offsetY,
        kDefaultArrowOffset,
        reason:
            'PlotlySchemaAdapter.ts:731, :989-991: DEFAULT_ARROW_OFFSET '
            'is -40.',
      );
    },
  );

  test('explicit ax and xshift sum into one offset', () {
    final annotation = convertPlotlyAnnotation(
      <String, Object?>{
        'text': 'a',
        'x': 1,
        'y': 2,
        'showarrow': true,
        'ax': 10,
        'xshift': 5,
      },
      0,
      layout: null,
    );
    expect(
      annotation!.layout!.offsetX,
      15,
      reason:
          'PlotlySchemaAdapter.ts:950-987 sums ax and xshift when axref is '
          'absent or pixel.',
    );
    expect(
      annotation.layout!.offsetY,
      0,
      reason:
          'PlotlySchemaAdapter.ts:989-991 withholds the default arrow offset '
          'once ANY explicit offset component is present, and 0 is this '
          "port's unset value for a non-nullable offset.",
    );
  });

  test('a data-space ax in axref units is not an offset at all', () {
    final annotation = convertPlotlyAnnotation(
      <String, Object?>{
        'text': 'a',
        'x': 1,
        'y': 2,
        'showarrow': true,
        'ax': 10,
        'axref': 'x',
      },
      0,
      layout: null,
    );
    expect(
      annotation!.layout!.offsetX,
      0,
      reason:
          'PlotlySchemaAdapter.ts:952-957 takes ax only when axref is absent '
          'or `pixel`; an axis-referenced ax is a data coordinate this port '
          'cannot express as a pixel nudge.',
    );
    expect(
      annotation.layout!.offsetY,
      kDefaultArrowOffset,
      reason:
          'PlotlySchemaAdapter.ts:989-991 — the rejected ax never set '
          'hasExplicitOffset, so the default arrow offset still applies.',
    );
  });

  test('a zero offset is not emitted', () {
    final annotation = convertPlotlyAnnotation(
      <String, Object?>{'text': 'a', 'x': 1, 'y': 2, 'ax': 0, 'ay': 0},
      0,
      layout: null,
    );
    expect(
      annotation!.layout!.offsetX,
      0,
      reason:
          'PlotlySchemaAdapter.ts:950-987 skips zero offsets. The plan '
          'expected null, but FluentChartAnnotationLayout.offsetX is a non-'
          'nullable double defaulting to 0 (chart_annotation.dart:250-252), '
          'so 0 is what "not emitted" means in this port.',
    );
  });

  test(
    'data coordinates default clipToBounds to true, and cliponaxis wins',
    () {
      final implicit = convertPlotlyAnnotation(
        <String, Object?>{'text': 'a', 'x': 1, 'y': 2},
        0,
        layout: null,
      );
      expect(
        implicit!.layout!.clipToBounds,
        isTrue,
        reason:
            'PlotlySchemaAdapter.ts:919-924 defaults data coordinates to '
            'clipped.',
      );
      final explicit = convertPlotlyAnnotation(
        <String, Object?>{'text': 'a', 'x': 1, 'y': 2, 'cliponaxis': false},
        0,
        layout: null,
      );
      expect(
        explicit!.layout!.clipToBounds,
        isFalse,
        reason: 'PlotlySchemaAdapter.ts:919-924.',
      );
    },
  );

  test('a relative anchor leaves clipToBounds unset, not false', () {
    final annotation = convertPlotlyAnnotation(
      <String, Object?>{
        'text': 'a',
        'x': 0.5,
        'y': 0.5,
        'xref': 'paper',
        'yref': 'paper',
      },
      0,
      layout: null,
    );
    expect(
      annotation!.layout?.clipToBounds,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:919-924 sets clipToBounds only for a data '
          'anchor. The null is load-bearing: ChartAnnotationLayer.tsx:385 '
          'reads it as falsey while :544 reads `!= false` as truthy.',
    );
  });

  test(
    'a paper-relative y is flipped because Plotly paper y is bottom-origin',
    () {
      final annotation = convertPlotlyAnnotation(
        <String, Object?>{
          'text': 'a',
          'x': 0.25,
          'y': 0.25,
          'xref': 'paper',
          'yref': 'paper',
        },
        0,
        layout: null,
      );
      final coordinates = annotation!.coordinates;
      expect(
        coordinates,
        isA<FluentRelativeCoordinate>().having((c) => c.y, 'y', 0.75),
        reason:
            'PlotlySchemaAdapter.ts:601-609 flips a relative y with 1 - value. '
            'The plan named the arm FluentChartAnnotationRelativeCoordinates; '
            'the contract calls it FluentRelativeCoordinate '
            '(chart_annotation.dart:130).',
      );
    },
  );

  test('a paper x against a data y produces a mixed anchor', () {
    final annotation = convertPlotlyAnnotation(
      <String, Object?>{
        'text': 'a',
        'x': 0.25,
        'y': 7,
        'xref': 'paper',
        'yref': 'y2',
      },
      0,
      layout: null,
    );
    expect(
      annotation!.coordinates,
      isA<FluentMixedCoordinate>()
          .having((c) => c.xSpace, 'xSpace', FluentCoordinateSpace.relative)
          .having((c) => c.ySpace, 'ySpace', FluentCoordinateSpace.data)
          .having((c) => c.yAxis, 'yAxis', FluentAnnotationYAxis.secondary),
      reason:
          'PlotlySchemaAdapter.ts:894-903 falls through to the mixed arm when '
          'the two spaces differ, and :869-871 routes a `y2` reference to the '
          'secondary scale.',
    );
  });

  test('an unresolvable reference drops the annotation', () {
    expect(
      convertPlotlyAnnotation(
        <String, Object?>{'text': 'a', 'x': 1, 'y': 2, 'xref': 'y'},
        0,
        layout: null,
      ),
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:848-852 — resolveRefType returns undefined '
          'for an axis letter that is not the one being resolved.',
    );
    expect(
      convertPlotlyAnnotation(
        <String, Object?>{'text': 'a', 'x': 1, 'y': 2, 'visible': false},
        0,
        layout: null,
      ),
      isNull,
      reason: 'PlotlySchemaAdapter.ts:844-846.',
    );
  });

  test('a date axis parses its coordinate into a DateTime', () {
    final annotation = convertPlotlyAnnotation(
      <String, Object?>{'text': 'a', 'x': '2020-03-01', 'y': 2},
      0,
      layout: <String, Object?>{
        'xaxis': <String, Object?>{'type': 'date'},
        'yaxis': <String, Object?>{'type': 'linear'},
      },
    );
    expect(
      annotation!.coordinates,
      isA<FluentDataCoordinate>()
          .having((c) => c.x, 'x', DateTime.parse('2020-03-01'))
          .having((c) => c.y, 'y', 2),
      reason:
          'PlotlySchemaAdapter.ts:688-714 parses against the axis type named '
          'in the layout, and :809-816 reads that type through '
          'getAxisLayoutByRef.',
    );
  });

  test('annotation text arrives decoded, because Flutter Text cannot parse '
      'entities', () {
    final annotation = convertPlotlyAnnotation(
      <String, Object?>{'text': '&lt;b&gt;', 'x': 1, 'y': 2},
      0,
      layout: null,
    );
    expect(
      annotation!.text,
      '<b>',
      reason:
          'PlotlySchemaAdapter.ts:542-548 entity-encodes for the DOM; a '
          'Flutter Text widget renders entities literally, so the port '
          'decodes again.',
    );
  });

  test(
    'a showarrow annotation carries a connector, and a plain one does not',
    () {
      final arrowed = convertPlotlyAnnotation(
        <String, Object?>{
          'text': 'a',
          'x': 1,
          'y': 2,
          'showarrow': true,
          'arrowcolor': '#ff0000',
          'arrowwidth': 3,
          'standoff': -5,
          'arrowdash': 'dash',
        },
        0,
        layout: null,
      );
      final connector = arrowed!.connector;
      expect(connector, isNotNull, reason: 'PlotlySchemaAdapter.ts:1056-1071.');
      expect(
        connector!.strokeColor,
        const Color(0xffff0000),
        reason: 'PlotlySchemaAdapter.ts:1057, :1064.',
      );
      expect(
        connector.strokeWidth,
        3,
        reason: 'PlotlySchemaAdapter.ts:1058, :1065.',
      );
      expect(
        connector.endPadding,
        0,
        reason: 'PlotlySchemaAdapter.ts:1059, :1066 clamps standoff at 0.',
      );
      expect(
        connector.dashArray,
        '5, 5',
        reason: 'PlotlySchemaAdapter.ts:1061, :1068.',
      );
      expect(
        convertPlotlyAnnotation(
          <String, Object?>{'text': 'a', 'x': 1, 'y': 2},
          0,
          layout: null,
        )!.connector,
        isNull,
        reason: 'PlotlySchemaAdapter.ts:1056 gates the connector on showarrow.',
      );
    },
  );

  test('style props come across, textangle included', () {
    final annotation = convertPlotlyAnnotation(
      <String, Object?>{
        'text': 'a',
        'x': 1,
        'y': 2,
        'bgcolor': 'rgb(0, 0, 255)',
        'bordercolor': '#00ff00',
        'borderwidth': 2,
        'borderpad': 6,
        'opacity': 0.5,
        'width': 120,
        'xanchor': 'right',
        'yanchor': 'top',
        'textangle': '45',
        'font': <String, Object?>{'color': '#123456', 'size': 14},
      },
      0,
      layout: null,
    );
    final style = annotation!.style!;
    expect(
      style.backgroundColor,
      const Color(0xff0000ff),
      reason: 'PlotlySchemaAdapter.ts:998-1000.',
    );
    expect(
      style.borderColor,
      const Color(0xff00ff00),
      reason: 'PlotlySchemaAdapter.ts:1002-1004.',
    );
    expect(style.borderWidth, 2, reason: 'PlotlySchemaAdapter.ts:1006-1009.');
    expect(
      style.padding,
      const EdgeInsets.all(6),
      reason:
          'PlotlySchemaAdapter.ts:1011-1014 turns borderpad into the CSS '
          'shorthand `6px`, which is EdgeInsets.all in Flutter.',
    );
    expect(style.opacity, 0.5, reason: 'PlotlySchemaAdapter.ts:1016-1019.');
    expect(
      style.textColor,
      const Color(0xff123456),
      reason: 'PlotlySchemaAdapter.ts:1027-1029.',
    );
    expect(style.fontSize, 14, reason: 'PlotlySchemaAdapter.ts:1030-1033.');
    expect(
      style.rotation,
      45,
      reason:
          'PlotlySchemaAdapter.ts:1039-1047 parses a numeric string, and '
          'drops `auto`.',
    );
    expect(
      annotation.layout!.align,
      FluentChartAnnotationAlign.end,
      reason: 'PlotlySchemaAdapter.ts:611-622, :926-929: right maps to end.',
    );
    expect(
      annotation.layout!.verticalAlign,
      FluentChartAnnotationVerticalAlign.top,
      reason: 'PlotlySchemaAdapter.ts:624-635, :938-941.',
    );
    expect(
      annotation.layout!.maxWidth,
      120,
      reason: 'PlotlySchemaAdapter.ts:993-996.',
    );
  });

  test('annotations are suppressed entirely in a multi-plot figure', () {
    expect(
      getChartAnnotationsFromLayout(<String, Object?>{
        'annotations': <Object?>[
          <String, Object?>{'text': 'a', 'x': 1, 'y': 2},
        ],
      }, isMultiPlot: true),
      isEmpty,
      reason: 'PlotlySchemaAdapter.ts:1081.',
    );
  });

  test('a lone annotation object is wrapped, and its index numbers its id', () {
    final annotations = getChartAnnotationsFromLayout(<String, Object?>{
      'annotations': <String, Object?>{'text': 'Only', 'x': 1, 'y': 2},
    }, isMultiPlot: false);
    expect(
      annotations.map((a) => a.id).toList(),
      <String>['annotation-0-only'],
      reason:
          'PlotlySchemaAdapter.ts:1155 wraps a non-array `annotations` in a '
          'one-element list before mapping.',
    );
  });

  test(
    'a dropped annotation does not shift the ids of the ones that survive',
    () {
      final annotations = getChartAnnotationsFromLayout(<String, Object?>{
        'annotations': <Object?>[
          <String, Object?>{'text': 'first', 'x': 1, 'y': 2},
          <String, Object?>{'text': 'gone', 'x': 1, 'y': 2, 'visible': false},
          <String, Object?>{'text': 'third', 'x': 1, 'y': 2},
        ],
      }, isMultiPlot: false);
      expect(
        annotations.map((a) => a.id).toList(),
        <String>['annotation-0-first', 'annotation-2-third'],
        reason:
            'PlotlySchemaAdapter.ts:1156-1158 numbers with the ORIGINAL index '
            'and filters afterwards, so the survivors keep their source '
            'positions.',
      );
    },
  );

  test('a layout with no annotations yields nothing', () {
    expect(
      getChartAnnotationsFromLayout(null, isMultiPlot: false),
      isEmpty,
      reason: 'PlotlySchemaAdapter.ts:1081.',
    );
  });
}
