import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';

/// The skeleton loops forever, so `pumpAndSettle` would time out. Every image
/// here is a single frame pumped to a fixed elapsed time instead: 750ms is a
/// quarter through the 3000ms wave and three quarters through the 1000ms pulse,
/// which puts both mid-cycle rather than at an endpoint where a broken
/// animation would look identical to a working one.
void main() {
  const elapsed = Duration(milliseconds: 750);

  Widget grid() => goldenGrid(columns: 3, <Widget>[
    for (final shape in FluentSkeletonShape.values)
      for (final animation in FluentSkeletonAnimation.values)
        FluentSkeleton(
          shape: shape,
          animation: animation,
          width: shape == FluentSkeletonShape.circle ? 40 : 160,
          height: shape == FluentSkeletonShape.circle ? 40 : 24,
        ),
  ]);

  goldenGridTest('skeleton', grid, elapsed: elapsed);

  // Reduced motion is a distinct appearance, not a faster one: the wave falls
  // back to Figma's Animated=False band and the pulse freezes at full opacity.
  // Captured in light only — the code path is about motion, not tokens.
  testWidgets('skeleton, reduced motion — light', (tester) async {
    await expectGolden(
      tester,
      'skeleton.reduced_motion',
      grid(),
      elapsed: elapsed,
      reducedMotion: true,
    );
  });
}
