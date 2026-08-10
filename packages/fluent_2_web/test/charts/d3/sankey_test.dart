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

  // ---------------------------------------------------------------------------
  // Exact breadth ties.
  //
  // `ascendingBreadth` is `a.y0 - b.y0` (`d3-sankey/src/sankey.js:13-15`), so it
  // returns 0 for any two nodes a column has pushed onto the same y0, and both
  // column sorts — `sankey.js:263` in the left-to-right pass, `:286` in the
  // right-to-left one — hand those ties to `Array.prototype.sort`, stable in V8
  // since ES2019. Dart's `List.sort` is not, which is why the port routes both
  // through `stableSort`. Without a layout that actually ties, that routing is
  // unobservable: reversing the tie order at all six call sites leaves every
  // other test in this suite green.
  //
  // The graph below ties on purpose. Two sources P and Q feed two sinks X and Y
  // with values a = P→X, b = P→Y, c = Q→X, d = Q→Y. Both columns hold the same
  // total — each is a + b + c + d — so with `nodePadding(0)`
  // `initializeNodeBreadths` (`sankey.js:211-231`) packs each flush into the
  // extent and has no slack to share out (`:223` divides zero by the node
  // count): P at 0, Q at (a + b)k, X at 0 and Y at (a + c)k, for the `:212`
  // value-to-pixel scale k.
  //
  // The first relaxation runs at alpha 1 (`sankey.js:238`, `Math.pow(0.99, 0)`)
  // and lands each node on the value-weighted mean of its neighbours' ribbon
  // tops (`:275-279` right to left, `:252-256` left to right). Zero padding
  // collapses those tops to plain sums of ribbon widths, leaving, in units of k,
  //
  //   P → bc/(a + b)          Q → (ac + d(a + b))/(c + d)
  //   X → bc/(a + c)          Y → (ab + d(a + c))/(b + d)
  //
  // Both pairs collide at once when b == c — which makes the two conditions the
  // same equation — and b^2(b + d) == (a + b)(ab + d(a + b)). (5, 10, 10, 2)
  // satisfies it: 100 * 12 == 15 * 80.
  //
  // That covers two of the six `stableSort` calls in the port —
  // `sankey.dart:450` and `:482`, the two column sorts. The other four cannot
  // be covered this way and do not need to be: `ascendingSourceBreadth` and
  // `ascendingTargetBreadth` fall back to `a.index - b.index`
  // (`sankey.js:5-11`), and `computeNodeLinks` numbers every link across the
  // whole link list (`sankey.js:134`, `sankey.dart:207-208`), so those two
  // comparators return 0 only when handed the same link twice. Sorting a
  // reversed copy at `sankey.dart:546`, `:552`, `:562` or `:566` is a no-op:
  // stability there is unobservable, not untested. The order those four produce
  // is load-bearing and is covered — reversing the sorted result at any of them
  // fails the tests below, and at three of the four the corpus test too.
  // ---------------------------------------------------------------------------

  /// Two sources feeding two sinks, in the input order P, X, Y, Q.
  ///
  /// The input order is the column order — `computeNodeLayers`
  /// (`sankey.js:193-209`) appends nodes as it walks the input — so column 0
  /// starts as `[P, Q]` and column 1 as `[X, Y]`, and that is the order a
  /// stable sort has to hold on to through a tie.
  (List<SankeyLayoutNode>, List<SankeyLayoutLink>) tieGraph(
    double pToX,
    double pToY,
    double qToX,
    double qToY,
  ) {
    final p = SankeyLayoutNode(id: 'P');
    final x = SankeyLayoutNode(id: 'X');
    final y = SankeyLayoutNode(id: 'Y');
    final q = SankeyLayoutNode(id: 'Q');
    return (
      <SankeyLayoutNode>[p, x, y, q],
      <SankeyLayoutLink>[
        SankeyLayoutLink(source: p, target: x, value: pToX),
        SankeyLayoutLink(source: p, target: y, value: pToY),
        SankeyLayoutLink(source: q, target: x, value: qToX),
        SankeyLayoutLink(source: q, target: y, value: qToY),
      ],
    );
  }

  test('both column sorts tie, and the tie keeps the input order', () {
    // iterations(1) is what puts the left-to-right pair on the same y0 as
    // well: only there does beta reach 1 on the first pass (`sankey.js:239`,
    // `max(1 - alpha, (i + 1) / iterations)`), so `resolveCollisions` repacks
    // the source column flush against the extent before the left-to-right pass
    // reads it, and the closed form above holds for X and Y too. The corpus
    // already covers `iterations(1)` as a supported setting
    // (`crawlers/d3-golden/generate.mjs:498`).
    final (nodes, links) = tieGraph(5, 10, 10, 2);
    final graph = Sankey()
        .nodePadding(0)
        .iterations(1)
        .extentOf(0, 0, 800, 320)(nodes, links);
    // Ground truth: d3-sankey run on this graph under node, same settings
    // (`crawlers/d3-golden/node_modules/d3-sankey`). Every digit below is V8's,
    // and the port reproduces all of them bit for bit — alpha is 0.99^0 here,
    // so the sub-ulp `math.pow` deviation of `sankey.dart:370-377` cannot bite.
    const wantNodes = <(String, double, double)>[
      ('P', 0, 177.77777777777777),
      ('X', 0, 177.77777777777777),
      ('Y', 177.77777777777777, 320),
      ('Q', 177.77777777777777, 320),
    ];
    expect(
      graph.nodes,
      hasLength(wantNodes.length),
      reason: 'the layout returns the four input nodes',
    );
    for (var i = 0; i < wantNodes.length; i++) {
      final node = graph.nodes[i];
      final (id, y0, y1) = wantNodes[i];
      expect(node.id, id, reason: 'node $i is $id');
      expect(
        node.y0,
        y0,
        reason:
            '$id y0 — inverting either tie swaps the pair inside its column '
            'and moves this edge',
      );
      expect(node.y1, y1, reason: '$id y1');
    }
    const wantLinks = <(String, double, double, double)>[
      ('P→X', 59.25925925925925, 29.629629629629626, 29.629629629629626),
      ('P→Y', 118.5185185185185, 118.5185185185185, 237.037037037037),
      ('Q→X', 118.5185185185185, 237.037037037037, 118.5185185185185),
      ('Q→Y', 23.703703703703702, 308.14814814814815, 308.14814814814815),
    ];
    expect(
      graph.links,
      hasLength(wantLinks.length),
      reason: 'the layout returns the four input links',
    );
    for (var i = 0; i < wantLinks.length; i++) {
      final link = graph.links[i];
      final (label, width, y0, y1) = wantLinks[i];
      expect(
        '${link.source.id}→${link.target.id}',
        label,
        reason: 'link $i is $label',
      );
      expect(link.width, width, reason: '$label width');
      expect(link.y0, y0, reason: '$label y0 follows its source node');
      expect(link.y1, y1, reason: '$label y1 follows its target node');
    }
  });

  test('the right-to-left tie holds at the default six iterations', () {
    final (nodes, links) = tieGraph(5, 10, 10, 2);
    final graph = Sankey().nodePadding(0).extentOf(0, 0, 800, 320)(
      nodes,
      links,
    );
    // The right-to-left tie is in the first relaxation, where alpha is 1
    // whatever the iteration count, so it survives the d3 default of six
    // (`sankey.js:64`). Only y0 is asserted: the later iterations run alpha
    // through `math.pow(0.99, 3)`, one ulp off V8 (`sankey.dart:370-377`),
    // which shows up in y1 at the extent edge but not in these four values —
    // all four are V8's own, from d3-sankey under node.
    const wantY0 = <(String, double)>[
      ('P', 0),
      ('X', 0),
      ('Y', 177.77777777777777),
      ('Q', 177.77777777777777),
    ];
    expect(graph.nodes, hasLength(wantY0.length), reason: 'four nodes back');
    for (var i = 0; i < wantY0.length; i++) {
      final (id, y0) = wantY0[i];
      expect(graph.nodes[i].id, id, reason: 'node $i is $id');
      expect(
        graph.nodes[i].y0,
        y0,
        reason:
            '$id y0 — with the tie inverted at sankey.js:286 the sources swap, '
            'putting Q on top at 0 and P at 142.22',
      );
    }
  });

  test('the left-to-right tie holds at the default six iterations', () {
    // The left-to-right pass reads a source column the collision pass has
    // already nudged, so the closed form above does not survive past
    // `iterations(1)` and this quadruple came from scanning integer values
    // 1..14 for a layout that an inverted tie order moves; (1, 3, 1, 3) is the
    // first. Its sinks tie in a later iteration, and the values below are once
    // more d3-sankey's under node.
    final (nodes, links) = tieGraph(1, 3, 1, 3);
    final graph = Sankey().nodePadding(0).extentOf(0, 0, 800, 320)(
      nodes,
      links,
    );
    final x = graph.nodes[1];
    final y = graph.nodes[2];
    expect(x.id, 'X', reason: 'node 1 is X');
    expect(y.id, 'Y', reason: 'node 2 is Y');
    expect(
      <double>[x.y0, x.y1, y.y0, y.y1],
      <double>[0, 80, 80, 320],
      reason:
          'X keeps the top of its column through the tie; inverting it at '
          'sankey.js:263 drops X to 240 and lifts Y to 0',
    );
    expect(
      graph.nodes[0].y0,
      lessThan(graph.nodes[3].y0),
      reason:
          'P stays above Q — asserted as an order, not a number, because the '
          'source column lands on 159.99999999999997 against V8\'s 160 through '
          'the `math.pow(0.99, 3)` deviation of sankey.dart:370-377',
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
