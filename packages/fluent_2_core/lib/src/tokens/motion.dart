// ignore_for_file: public_member_api_docs
// Each member below is a single stop on a named numeric scale — the
// identifier and its value are the documentation (`size20 = 2`,
// `ultraFast = 50ms`). The class doc explains the scale; per-stop prose
// would restate the name and nothing more. Real API elsewhere is covered.
import 'package:flutter/animation.dart';

/// Fluent duration ramp. Source: `global/durations.ts`.
abstract final class FluentDuration {
  static const Duration ultraFast = Duration(milliseconds: 50);
  static const Duration faster = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration gentle = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration slower = Duration(milliseconds: 400);
  static const Duration ultraSlow = Duration(milliseconds: 500);
}

/// Fluent easing curves. Source: `global/curves.ts`.
///
/// Accelerate curves are for exits (the element leaves and speeds up),
/// decelerate for entrances, easyEase for elements that stay on screen.
abstract final class FluentCurve {
  static const Cubic accelerateMax = Cubic(0.9, 0.1, 1.0, 0.2);
  static const Cubic accelerateMid = Cubic(1.0, 0.0, 1.0, 1.0);
  static const Cubic accelerateMin = Cubic(0.8, 0.0, 0.78, 1.0);
  static const Cubic decelerateMax = Cubic(0.1, 0.9, 0.2, 1.0);
  static const Cubic decelerateMid = Cubic(0.0, 0.0, 0.0, 1.0);
  static const Cubic decelerateMin = Cubic(0.33, 0.0, 0.1, 1.0);
  static const Cubic easyEaseMax = Cubic(0.8, 0.0, 0.2, 1.0);
  static const Cubic easyEase = Cubic(0.33, 0.0, 0.67, 1.0);
  static const Cubic linear = Cubic(0.0, 0.0, 1.0, 1.0);
}
