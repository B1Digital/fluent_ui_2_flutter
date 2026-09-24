import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [FluentAnimatedStyle] is the single implicit animation in the package, so
/// the reduced-motion clamp is written once instead of once per component.
void main() {
  const black = Color(0xFF000000);
  const white = Color(0xFFFFFFFF);

  // `fade` is 200ms of easyEase. easyEase is symmetric about its midpoint
  // (its control points mirror through (0.5, 0.5)), so half the timeline is
  // exactly half the tween — which is what makes the mid-tween assertion below
  // a number rather than a range.
  const spec = FluentMotionSpec.fade;
  const half = Duration(milliseconds: 100);

  late Color latest;

  Widget build(Color value, {bool disableAnimations = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: FluentAnimatedStyle<Color>(
      value: value,
      spec: spec,
      lerp: Color.lerp,
      builder: (context, color) {
        latest = color;
        return const SizedBox.shrink();
      },
    ),
  );

  group('FluentAnimatedStyle', () {
    testWidgets('shows the first value outright, without animating into it', (
      tester,
    ) async {
      await tester.pumpWidget(build(black));
      expect(latest, black);
    });

    testWidgets(
      'is mid-tween at half the spec duration and settled at the end',
      (tester) async {
        await tester.pumpWidget(build(black));
        await tester.pumpWidget(build(white));
        expect(latest, black, reason: 'the tween starts from the old value');

        await tester.pump(half);
        expect(latest.r, greaterThan(0.0));
        expect(latest.r, lessThan(1.0));
        expect(
          latest.r,
          closeTo(0.5, 0.02),
          reason: 'easyEase is symmetric, so half the time is half the tween',
        );

        await tester.pumpAndSettle();
        expect(latest, white);
      },
    );

    testWidgets('jumps instantly under reduced motion, with no intermediate '
        'frame', (tester) async {
      await tester.pumpWidget(build(black, disableAnimations: true));
      await tester.pumpWidget(build(white, disableAnimations: true));
      expect(
        latest,
        white,
        reason:
            'prefers-reduced-motion clamps the transition to nothing, so '
            'the very first frame after the change is already the target',
      );
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'no ticker should be left running',
      );

      await tester.pump(half);
      expect(latest, white);
    });

    testWidgets('retargets from the current value rather than snapping', (
      tester,
    ) async {
      await tester.pumpWidget(build(black));
      await tester.pumpWidget(build(white));
      await tester.pump(half);
      final mid = latest;

      // Reverse mid-flight. Upstream's transitions are property-based, so an
      // interrupted one continues from wherever it had got to.
      await tester.pumpWidget(build(black));
      expect(
        latest,
        mid,
        reason: 'a retarget must not snap back to the old start value',
      );

      await tester.pump(half);
      expect(latest.r, lessThan(mid.r), reason: 'now heading back to black');

      await tester.pumpAndSettle();
      expect(latest, black);
    });
  });

  group('FluentMotionSpec', () {
    test('is a value type', () {
      const same = FluentMotionSpec(
        duration: FluentDuration.normal,
        curve: FluentCurve.easyEase,
      );
      expect(same, FluentMotionSpec.fade);
      expect(same.hashCode, FluentMotionSpec.fade.hashCode);

      expect(
        FluentMotionSpec.fade,
        isNot(FluentMotionSpec.collapse),
        reason: 'same duration, different curve',
      );
      expect(
        FluentMotionSpec.scaleEnter,
        isNot(FluentMotionSpec.tabIndicator),
        reason: 'same curve, different duration',
      );
    });

    test('carries the upstream values verbatim', () {
      expect(FluentMotionSpec.buttonSurface.duration, FluentDuration.faster);
      expect(FluentMotionSpec.buttonSurface.curve, FluentCurve.easyEase);
      expect(FluentMotionSpec.switchTrack.duration, FluentDuration.normal);
      expect(FluentMotionSpec.switchThumb.duration, FluentDuration.normal);
      expect(FluentMotionSpec.tabIndicator.duration, FluentDuration.slow);
      expect(FluentMotionSpec.tabIndicator.curve, FluentCurve.decelerateMax);
      expect(FluentMotionSpec.collapse.curve, FluentCurve.easyEaseMax);
      expect(FluentMotionSpec.scaleEnter.duration, FluentDuration.gentle);
      expect(FluentMotionSpec.scaleExit.curve, FluentCurve.accelerateMax);
      expect(FluentMotionSpec.slideEnter.curve, FluentCurve.decelerateMid);
      expect(FluentMotionSpec.slideExit.curve, FluentCurve.accelerateMid);
      expect(FluentMotionSpec.popover.duration, FluentDuration.slower);
      expect(FluentMotionSpec.popover.curve, FluentCurve.decelerateMid);
      expect(FluentMotionSpec.accordionChevron.duration, FluentDuration.normal);
      // Upstream writes a raw CSS `ease-out` — cubic-bezier(0, 0, 0.58, 1),
      // which decelerates with no ease-in. decelerateMin is the ramp's nearest
      // match; easyEase is symmetric and therefore the wrong category.
      expect(
        FluentMotionSpec.accordionChevron.curve,
        FluentCurve.decelerateMin,
      );
    });
  });

  group('FluentCssCubic', () {
    test("ease matches Chrome's own scale to six decimals", () {
      // `getComputedStyle(::after).transform` at 20ms steps of a 200ms `ease`
      // transition, paused with `Animation.currentTime`, on the live
      // storybook. Flutter's `Cubic` misses these by up to 0.002.
      const chrome = <double>[
        0.0947963,
        0.295244,
        0.513315,
        0.68254,
        0.802403,
        0.885229,
        0.940765,
        0.975625,
        0.994316,
      ];
      for (var i = 0; i < chrome.length; i++) {
        final t = (i + 1) / 10;
        expect(
          FluentCssCubic.ease.transform(t),
          closeTo(chrome[i], 2e-6),
          reason: 't=$t',
        );
      }
      expect(FluentCssCubic.ease.transform(0), 0);
      expect(FluentCssCubic.ease.transform(1), 1);
    });

    test('solves steep and flat control points', () {
      // decelerateMid (0, 0, 0, 1) has zero slope in x at t=0, which stalls
      // Newton and must fall back to bisection.
      const steep = FluentCssCubic(0, 0, 0, 1);
      for (var t = 0.05; t < 1; t += 0.05) {
        final y = steep.transform(t);
        expect(y, inInclusiveRange(0, 1));
        expect(y, greaterThanOrEqualTo(steep.transform(t - 0.05)));
      }
      expect(const FluentCssCubic(0.25, 0.1, 0.25, 1), FluentCssCubic.ease);
    });
  });
}
