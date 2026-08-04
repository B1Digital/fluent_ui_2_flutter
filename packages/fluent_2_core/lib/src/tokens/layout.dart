// ignore_for_file: public_member_api_docs
// Each member below is a single stop on a named numeric scale — the
// identifier and its value are the documentation (`size20 = 2`,
// `ultraFast = 50ms`). The class doc explains the scale; per-stop prose
// would restate the name and nothing more. Real API elsewhere is covered.
import 'package:flutter/widgets.dart';

/// The cross-platform global size ramp, in logical pixels.
///
/// Token number = px × 10 (`size20` = 2px). This is the canonical ramp shared
/// by web, iOS and Android; the web semantic aliases in [FluentSpacing] expose
/// only a subset of it.
abstract final class FluentSize {
  static const double none = 0;
  static const double size20 = 2;
  static const double size40 = 4;
  static const double size60 = 6;
  static const double size80 = 8;
  static const double size100 = 10;
  static const double size120 = 12;

  /// Android-only stop — absent on web and iOS.
  static const double size140 = 14;
  static const double size160 = 16;

  /// Android-only stop — absent on web and iOS.
  static const double size180 = 18;
  static const double size200 = 20;
  static const double size240 = 24;
  static const double size280 = 28;
  static const double size320 = 32;
  static const double size360 = 36;
  static const double size400 = 40;
  static const double size480 = 48;
  static const double size520 = 52;
  static const double size560 = 56;
}

/// Web semantic spacing aliases.
///
/// Horizontal and vertical ramps are identical upstream — both derive from one
/// private `spacings` object. The split exists so component tokens *could*
/// diverge, so [FluentSpacing.horizontal] and [FluentSpacing.vertical] are kept
/// as separate names rather than collapsed.
abstract final class FluentSpacing {
  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sNudge = 6;
  static const double s = 8;
  static const double mNudge = 10;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const FluentSpacingScale horizontal = FluentSpacingScale();
  static const FluentSpacingScale vertical = FluentSpacingScale();
}

/// One spacing axis. Identical values on both axes today.
@immutable
class FluentSpacingScale {
  const FluentSpacingScale();

  double get none => FluentSpacing.none;
  double get xxs => FluentSpacing.xxs;
  double get xs => FluentSpacing.xs;
  double get sNudge => FluentSpacing.sNudge;
  double get s => FluentSpacing.s;
  double get mNudge => FluentSpacing.mNudge;
  double get m => FluentSpacing.m;
  double get l => FluentSpacing.l;
  double get xl => FluentSpacing.xl;
  double get xxl => FluentSpacing.xxl;
  double get xxxl => FluentSpacing.xxxl;
}

/// Corner radius ramp.
///
/// [circular] is 9999 rather than the web token's 10000 — both saturate, and
/// 9999 matches the mobile platforms.
abstract final class FluentRadius {
  static const Radius none = Radius.zero;
  static const Radius small = Radius.circular(2);
  static const Radius medium = Radius.circular(4);

  /// Web and iOS only — Android's ramp has no 6dp stop.
  static const Radius large = Radius.circular(6);
  static const Radius xLarge = Radius.circular(8);
  static const Radius xxLarge = Radius.circular(12);
  static const Radius xxxLarge = Radius.circular(16);

  /// Web-only stops — mobile ramps top out at [xxxLarge].
  static const Radius xxxxLarge = Radius.circular(24);
  static const Radius xxxxxLarge = Radius.circular(32);
  static const Radius xxxxxxLarge = Radius.circular(40);
  static const Radius circular = Radius.circular(9999);

  static const BorderRadius allSmall = BorderRadius.all(small);
  static const BorderRadius allMedium = BorderRadius.all(medium);
  static const BorderRadius allLarge = BorderRadius.all(large);
  static const BorderRadius allXLarge = BorderRadius.all(xLarge);
  static const BorderRadius allCircular = BorderRadius.all(circular);
}

/// Stroke widths. Web exposes [thin]…[thickest]; mobile adds [none], [hairline]
/// (0.5) and [width15] (1.5), plus [width60] (6).
abstract final class FluentStroke {
  static const double none = 0;
  static const double hairline = 0.5;
  static const double thin = 1;
  static const double width15 = 1.5;
  static const double thick = 2;
  static const double thicker = 3;
  static const double thickest = 4;
  static const double width60 = 6;
}

/// Responsive size classes.
///
/// Fluent publishes the breakpoint ranges but *not* concrete column/gutter/
/// margin values — the grid is documented as 12 columns with gutters that are a
/// multiple of 4, chosen per breakpoint. Those numbers are yours to pick.
enum FluentBreakpoint {
  small(320, 479),
  medium(480, 639),
  large(640, 1023),
  xLarge(1024, 1365),
  xxLarge(1366, 1919),
  xxxLarge(1920, double.infinity);

  const FluentBreakpoint(this.min, this.max);

  final double min;
  final double max;

  static const int columns = 12;

  /// The size class containing [width].
  static FluentBreakpoint of(double width) =>
      values.firstWhere((b) => width <= b.max, orElse: () => xxxLarge);
}

/// Minimum interactive target sizes, per platform guidance.
abstract final class FluentTouchTarget {
  static const double web = 44;
  static const double ios = 44;
  static const double android = 48;
}
