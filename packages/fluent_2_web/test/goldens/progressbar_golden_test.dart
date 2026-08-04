import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';

/// The indeterminate bar sweeps forever, so `pumpAndSettle` would time out.
/// Each image is one frame at a fixed elapsed time: 750ms is a quarter through
/// the 3000ms sweep, which puts the indicator part-way across rather than at
/// either end.
///
/// Rows one and two: the four statuses at both sizes, determinate at 60%.
/// Row three: 0%, 100%, and the indeterminate sweep at both sizes.
void main() {
  const elapsed = Duration(milliseconds: 750);
  const rail = 160.0;

  Widget bar(Widget child) => SizedBox(width: rail, child: child);

  Widget grid() => goldenGrid(columns: 4, <Widget>[
    for (final size in FluentProgressBarSize.values)
      for (final status in FluentProgressBarStatus.values)
        bar(FluentProgressBar(value: 0.6, size: size, status: status)),
    bar(const FluentProgressBar(value: 0)),
    bar(const FluentProgressBar(value: 1)),
    for (final size in FluentProgressBarSize.values)
      bar(FluentProgressBar(size: size)),
  ]);

  goldenGridTest('progressbar', grid, elapsed: elapsed);

  // With animations disabled the sweep never starts. Light only: the path is
  // about motion, not tokens.
  testWidgets('progressbar, reduced motion — light', (tester) async {
    await expectGolden(
      tester,
      'progressbar.reduced_motion',
      grid(),
      elapsed: elapsed,
      reducedMotion: true,
    );
  });
}
