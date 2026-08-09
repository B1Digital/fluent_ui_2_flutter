import 'package:fluent_2_web/src/charts/internal/d3/sankey.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  /// The graph the corpus was generated from
  /// (`crawlers/d3-golden/generate.mjs:479-486`).
  (List<SankeyLayoutNode>, List<SankeyLayoutLink>) sample() {
    final nodes = <SankeyLayoutNode>[
      for (final id in <String>['a', 'b', 'c', 'd', 'e'])
        SankeyLayoutNode(id: id),
    ];
    final byId = <String, SankeyLayoutNode>{
      for (final node in nodes) node.id! as String: node,
    };
    final links = <SankeyLayoutLink>[
      SankeyLayoutLink(source: byId['a']!, target: byId['c']!, value: 10),
      SankeyLayoutLink(source: byId['b']!, target: byId['c']!, value: 5),
      SankeyLayoutLink(source: byId['a']!, target: byId['d']!, value: 3),
      SankeyLayoutLink(source: byId['c']!, target: byId['e']!, value: 12),
      SankeyLayoutLink(source: byId['d']!, target: byId['e']!, value: 3),
    ];
    return (nodes, links);
  }

  test('the defaults are nodeWidth 24, nodePadding 8, iterations 6', () {
    final s = Sankey();
    expect(s.nodeWidthValue, 24.0, reason: 'd3-sankey/src/sankey.js:56');
    expect(s.nodePaddingValue, 8.0, reason: 'sankey.js:57');
    expect(s.iterationsValue, 6, reason: 'sankey.js:64');
  });

  test('sankeyJustify and sankeyRight', () {
    final leaf = SankeyLayoutNode(id: 'leaf')..height = 2;
    expect(
      sankeyJustify(leaf, 5),
      4,
      reason:
          'd3-sankey/src/align.js:16 — no sourceLinks means the last column',
    );
    expect(sankeyRight(leaf, 5), 2, reason: 'align.js:12, n - 1 - height');
  });

  test('a cycle throws rather than looping forever', () {
    final a = SankeyLayoutNode(id: 'a');
    final b = SankeyLayoutNode(id: 'b');
    final links = <SankeyLayoutLink>[
      SankeyLayoutLink(source: a, target: b, value: 1),
      SankeyLayoutLink(source: b, target: a, value: 1),
    ];
    expect(
      () => Sankey()(<SankeyLayoutNode>[a, b], links),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          'circular link',
        ),
      ),
      reason: 'sankey.js:169 and :187 both throw Error("circular link")',
    );
  });

  test('the layout is deterministic across runs — stable ties', () {
    String layout() {
      final (nodes, links) = sample();
      return Sankey()
          .nodeWidth(124)
          .extentOf(0, 0, 800, 400)(nodes, links)
          .nodes
          .map((SankeyLayoutNode n) => '${n.id}:${n.y0}')
          .join(',');
    }

    expect(
      layout(),
      layout(),
      reason:
          'ascendingBreadth returns 0 on every tie and is applied twelve '
          'times per layout (sankey.js:263,286); an unstable sort makes the '
          'diagram shuffle between renders',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    final cases = goldenCases(corpus, 'sankey');
    expect(cases, hasLength(6), reason: 'the corpus holds six sankey vectors');
    for (final c in cases) {
      final (nodes, links) = sample();
      // Every field the generator varied has to be replayed, not just the
      // alignment: cases 3-6 change nodeWidth, nodePadding, the extent and the
      // iteration count (`crawlers/d3-golden/generate.mjs:492-499`).
      final extent = (c['extent']! as List<Object?>)
          .map((Object? p) => (p! as List<Object?>).cast<num>())
          .toList(growable: false);
      final graph = Sankey()
          .nodeWidth((c['nodeWidth']! as num).toDouble())
          .nodePadding((c['nodePadding']! as num).toDouble())
          .iterations(c['iterations']! as int)
          .nodeAlign(c['align'] == 'right' ? sankeyRight : sankeyJustify)
          .extentOf(
            extent[0][0].toDouble(),
            extent[0][1].toDouble(),
            extent[1][0].toDouble(),
            extent[1][1].toDouble(),
          )(nodes, links);
      final label =
          '${c['align']} nodeWidth=${c['nodeWidth']} '
          'nodePadding=${c['nodePadding']} iterations=${c['iterations']}';
      final wantNodes = (c['nodes']! as List<Object?>)
          .cast<Map<String, dynamic>>();
      expect(
        graph.nodes,
        hasLength(wantNodes.length),
        reason: '$label: node count',
      );
      for (var i = 0; i < wantNodes.length; i++) {
        final n = graph.nodes[i];
        expect(n.id, wantNodes[i]['id'], reason: '$label: node $i id');
        expect(n.index, wantNodes[i]['index'], reason: '$label: node $i index');
        expect(n.depth, wantNodes[i]['depth'], reason: '$label: node $i depth');
        expect(
          n.height,
          wantNodes[i]['height'],
          reason: '$label: node $i height',
        );
        expect(n.layer, wantNodes[i]['layer'], reason: '$label: node $i layer');
        expect(
          n.value,
          closeToJs(wantNodes[i]['value']),
          reason: '$label: node $i value',
        );
        expect(
          n.x0,
          closeToJs(wantNodes[i]['x0']),
          reason: '$label: node $i x0',
        );
        expect(
          n.x1,
          closeToJs(wantNodes[i]['x1']),
          reason: '$label: node $i x1',
        );
        expect(
          n.y0,
          closeToJs(wantNodes[i]['y0']),
          reason: '$label: node $i y0',
        );
        expect(
          n.y1,
          closeToJs(wantNodes[i]['y1']),
          reason: '$label: node $i y1',
        );
      }
      final wantLinks = (c['links']! as List<Object?>)
          .cast<Map<String, dynamic>>();
      for (var i = 0; i < wantLinks.length; i++) {
        final l = graph.links[i];
        expect(l.index, wantLinks[i]['index'], reason: '$label: link $i index');
        expect(
          l.source.id,
          wantLinks[i]['source'],
          reason: '$label: link $i source',
        );
        expect(
          l.target.id,
          wantLinks[i]['target'],
          reason: '$label: link $i target',
        );
        expect(
          l.width,
          closeToJs(wantLinks[i]['width']),
          reason: '$label: link $i width',
        );
        expect(
          l.y0,
          closeToJs(wantLinks[i]['y0']),
          reason: '$label: link $i y0',
        );
        expect(
          l.y1,
          closeToJs(wantLinks[i]['y1']),
          reason: '$label: link $i y1',
        );
      }
    }
  });

  test('the layout clamps the padding actually in force', () {
    final (nodes, links) = sample();
    final s = Sankey().nodePadding(1000).extentOf(0, 0, 800, 400);
    expect(
      s.currentNodePadding,
      1000.0,
      reason: 'sankey.js:99 — nodePadding sets dy and py together',
    );
    s(nodes, links);
    expect(
      s.currentNodePadding,
      400.0,
      reason:
          'sankey.js:235 clamps py to (y1 - y0) / (widest column - 1), and the '
          'widest column of the sample holds two nodes',
    );
  });
}
