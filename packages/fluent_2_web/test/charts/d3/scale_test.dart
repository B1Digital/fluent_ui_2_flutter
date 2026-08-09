import 'package:fluent_2_web/src/charts/internal/d3/scale.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal conformer, proving the interface is implementable without any
/// scale type and pinning the null contract of each member.
class _Identity implements Scale {
  @override
  double? call(Object value) => value is num ? value.toDouble() : null;

  @override
  List<Object> get domain => <Object>[0, 1];

  @override
  List<double> get range => <double>[0, 1];

  @override
  double get bandwidth => 0;

  @override
  double get step => 1;

  @override
  Object? invert(double pixel) => pixel;

  @override
  List<Object> ticks([int? count]) => <Object>[0, 1];

  @override
  String Function(Object) tickFormat([int? count, String? specifier]) =>
      (Object v) => '$v';
}

void main() {
  test('the interface is implementable outside internal/d3', () {
    final Scale scale = _Identity();
    expect(scale(0.5), 0.5, reason: 'call is the mapping');
    expect(
      scale('nope'),
      isNull,
      reason:
          'null is the miss signal: a band domain miss and a non-numeric '
          'continuous input both return it',
    );
    expect(
      scale.bandwidth,
      0.0,
      reason:
          'continuous scales report zero bandwidth so a caller can branch '
          'on it the way d3-axis does at axis.js:50',
    );
  });
}
