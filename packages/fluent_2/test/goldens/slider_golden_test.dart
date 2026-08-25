import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row per size: the rail at 0, half and full, then stepped and disabled.
///
/// The rail has no intrinsic width, so every cell is pinned to 200 — a golden
/// of an infinitely wide slider would just be the surface size.
void main() {
  Widget cell({
    required double value,
    FluentSliderSize size = FluentSliderSize.medium,
    double? step,
    bool enabled = true,
  }) => SizedBox(
    width: 200,
    child: FluentSlider(
      value: value,
      size: size,
      step: step,
      onChanged: enabled ? (_) {} : null,
    ),
  );

  goldenGridTest(
    'slider',
    () => goldenGrid(<Widget>[
      for (final size in FluentSliderSize.values) ...<Widget>[
        cell(value: 0, size: size),
        cell(value: 50, size: size),
        cell(value: 100, size: size),
        cell(value: 50, size: size, step: 25),
        cell(value: 50, size: size, enabled: false),
      ],
    ], columns: 5),
  );
}
