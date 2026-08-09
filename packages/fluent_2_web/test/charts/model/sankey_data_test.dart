import 'dart:ui';

import 'package:fluent_2_web/src/charts/model/sankey_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentSankeyNode', () {
    test('accepts a numeric or a string node id', () {
      const numeric = FluentSankeyNode(nodeId: 0, name: 'Source');
      const textual = FluentSankeyNode(nodeId: 'src', name: 'Source');
      expect(
        numeric.nodeId,
        0,
        reason: 'types/DataPoint.ts:905 `number | string`.',
      );
      expect(
        textual.nodeId,
        'src',
        reason: 'types/DataPoint.ts:905 string arm.',
      );
    });
    test('rejects any other node id type', () {
      expect(
        () => FluentSankeyNode(nodeId: DateTime(2024), name: 'x'),
        throwsA(isA<AssertionError>()),
        reason: 'types/DataPoint.ts:905 admits only a number or a string.',
      );
    });
    test('carries no layout fields', () {
      const node = FluentSankeyNode(nodeId: 0, name: 'Source');
      expect(
        node.toString().contains('x0'),
        isFalse,
        reason:
            'actualValue, layer, x0/x1/y0/y1 are layout outputs and live on '
            'SankeyLayoutNode, closing the upstream TODO at '
            'SankeyChart.tsx:697-701.',
      );
    });
  });

  group('FluentSankeyLink', () {
    test('addresses its endpoints by index into the node list', () {
      const link = FluentSankeyLink(source: 0, target: 2, value: 17);
      expect(link.source, 0, reason: 'types/DataPoint.ts:920 index, not id.');
      expect(link.target, 2, reason: 'types/DataPoint.ts:924 index, not id.');
      expect(link.value, 17, reason: 'types/DataPoint.ts:928 weight.');
      expect(link.color, isNull, reason: 'Optional (types/DataPoint.ts:930).');
    });
  });

  group('FluentSankeyChartData', () {
    test('bundles nodes and links', () {
      const data = FluentSankeyChartData(
        nodes: <FluentSankeyNode>[
          FluentSankeyNode(nodeId: 0, name: 'A', color: Color(0xFF4F6BED)),
          FluentSankeyNode(nodeId: 1, name: 'B'),
        ],
        links: <FluentSankeyLink>[
          FluentSankeyLink(source: 0, target: 1, value: 5),
        ],
      );
      expect(data.nodes.length, 2, reason: 'types/DataPoint.ts:897.');
      expect(data.links.length, 1, reason: 'types/DataPoint.ts:898.');
      expect(
        data.nodes.first.color?.toARGB32(),
        0xFF4F6BED,
        reason: 'types/DataPoint.ts:908 optional per-node colour.',
      );
    });
  });
}
