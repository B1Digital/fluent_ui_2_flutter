import 'package:fluent_2_web/src/charts/internal/responsive.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    Directionality(textDirection: TextDirection.ltr, child: child),
  );

  testWidgets(
    'floors the measured constraints, matching the ResizeObserver callback',
    (tester) async {
      late FluentResponsiveChartMetrics seen;
      await pump(
        tester,
        Center(
          child: SizedBox(
            width: 300.7,
            height: 120.4,
            child: FluentResponsiveChartHost(
              builder: (context, metrics) {
                seen = metrics;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      expect(
        seen.width,
        300,
        reason:
            'ResponsiveContainer.tsx:35 applies Math.floor to the observed contentRect width.',
      );
      expect(
        seen.height,
        120,
        reason:
            'ResponsiveContainer.tsx:36 applies Math.floor to the observed contentRect height.',
      );
    },
  );

  testWidgets(
    'aspect derives the height from the width and clamps it to maxHeight',
    (tester) async {
      late FluentResponsiveChartMetrics seen;
      await pump(
        tester,
        Center(
          child: SizedBox(
            width: 400,
            height: 1000,
            child: FluentResponsiveChartHost(
              aspect: 2,
              maxHeight: 150,
              builder: (context, metrics) {
                seen = metrics;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      expect(
        seen.height,
        150,
        reason:
            'ResponsiveContainer.tsx:74-76 clamps the aspect-derived height to maxHeight.',
      );
    },
  );

  testWidgets('shouldResize is the sum the SankeyChart effect watches', (
    tester,
  ) async {
    late FluentResponsiveChartMetrics seen;
    await pump(
      tester,
      Center(
        child: SizedBox(
          width: 300,
          height: 120,
          child: FluentResponsiveChartHost(
            builder: (context, metrics) {
              seen = metrics;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    expect(
      seen.shouldResize,
      420,
      reason:
          'ResponsiveContainer.tsx:84 passes (width ?? 0) + (height ?? 0) as shouldResize; '
          'SankeyChart.tsx:608 keys its resize effect on it.',
    );
  });

  // The plan's aspect test above is satisfied whether or not the aspect branch
  // runs: without it the height is the box's own 1000, which the unconditional
  // maxHeight clamp then cuts to the same 150. Deleting the branch keeps it
  // green. The next two cases are what make the branch load-bearing — each one
  // fails if `aspect` is ignored — so the derivation is proven, not assumed.
  testWidgets('aspect derives the height from the width with no maxHeight', (
    tester,
  ) async {
    late FluentResponsiveChartMetrics seen;
    await pump(
      tester,
      Center(
        child: SizedBox(
          width: 400,
          height: 1000,
          child: FluentResponsiveChartHost(
            aspect: 2,
            builder: (context, metrics) {
              seen = metrics;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    expect(
      seen.height,
      200,
      reason:
          'ResponsiveContainer.tsx:69 sets calculatedHeight = calculatedWidth / aspect, '
          'so a 400-wide box at aspect 2 reports 200 rather than its own 1000.',
    );
  });

  testWidgets('aspect derives the width when the parent leaves it unbounded', (
    tester,
  ) async {
    late FluentResponsiveChartMetrics seen;
    await pump(
      tester,
      // A Row hands its non-flex child unbounded width, which is the Flutter
      // equivalent of the un-measured `undefined` at ResponsiveContainer.tsx:18
      // and the reason both dimensions on the metrics record are nullable.
      Row(
        children: <Widget>[
          SizedBox(
            height: 120,
            child: FluentResponsiveChartHost(
              aspect: 2,
              builder: (context, metrics) {
                seen = metrics;
                return const SizedBox(width: 1, height: 1);
              },
            ),
          ),
        ],
      ),
    );
    expect(
      seen.width,
      240,
      reason:
          'ResponsiveContainer.tsx:71 falls back to calculatedHeight * aspect when the '
          'width is undefined; 120 * 2 = 240.',
    );
  });

  testWidgets('minWidth and minHeight raise a box smaller than either bound', (
    tester,
  ) async {
    late FluentResponsiveChartMetrics seen;
    await pump(
      tester,
      Center(
        child: SizedBox(
          width: 40,
          height: 30,
          child: FluentResponsiveChartHost(
            minWidth: 100,
            minHeight: 80,
            builder: (context, metrics) {
              seen = metrics;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    expect(
      seen.width,
      100,
      reason:
          'ResponsiveContainer.tsx:100 floors the rendered width at props.minWidth.',
    );
    expect(
      seen.height,
      80,
      reason:
          'ResponsiveContainer.tsx:101 floors the rendered height at props.minHeight.',
    );
  });
}
