import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';

/// The spinner rotates forever, so `pumpAndSettle` would time out. Each image
/// is one frame at a fixed elapsed time: 750ms is exactly half of the 1500ms
/// rotation, so the arc sits opposite its rest position and a stalled
/// controller shows up immediately.
///
/// Row one: the eight sizes, primary. Row two: the same sizes, subtle, on a
/// brand fill — subtle resolves to `neutralStrokeOnBrand2`, which is white and
/// therefore invisible on the page background. Row three: the four label
/// positions.
void main() {
  const elapsed = Duration(milliseconds: 750);

  Widget onBrand(Widget child) => Builder(
    builder: (context) => ColoredBox(
      color: FluentTheme.of(context).colors.brandBackground,
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.xs),
        child: child,
      ),
    ),
  );

  Widget grid() => goldenGrid(columns: 8, <Widget>[
    for (final size in FluentSpinnerSize.values) FluentSpinner(size: size),
    for (final size in FluentSpinnerSize.values)
      onBrand(
        FluentSpinner(appearance: FluentSpinnerAppearance.subtle, size: size),
      ),
    for (final position in FluentSpinnerLabelPosition.values)
      FluentSpinner(labelPosition: position, label: const Text('Loading')),
  ]);

  goldenGridTest('spinner', grid, elapsed: elapsed);

  // With animations disabled the controller never starts, so the arc parks at
  // its rest angle. Light only: the path is about motion, not tokens.
  testWidgets('spinner, reduced motion — light', (tester) async {
    await expectGolden(
      tester,
      'spinner.reduced_motion',
      grid(),
      elapsed: elapsed,
      reducedMotion: true,
    );
  });
}
