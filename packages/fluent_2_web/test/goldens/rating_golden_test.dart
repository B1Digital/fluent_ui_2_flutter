import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row 1: the three shapes, interactive, at a half value.
/// Row 2: the three shapes as an inert display, plus compact.
/// Row 3: the three colours, display.
/// Row 4: the four sizes, interactive.
/// Row 5: disabled, a ten-shape row, an empty rating and a full one.
void main() {
  goldenGridTest(
    'rating',
    () => goldenGrid(columns: 4, <Widget>[
      for (final shape in FluentRatingShape.values)
        FluentRating(value: 3.5, shape: shape, onChanged: (_) {}),
      const SizedBox.shrink(),

      for (final shape in FluentRatingShape.values)
        FluentRating(value: 3.5, shape: shape, type: FluentRatingType.display),
      const FluentRating(
        value: 4,
        compact: true,
        color: FluentRatingColor.marigold,
        type: FluentRatingType.display,
      ),

      for (final color in FluentRatingColor.values)
        FluentRating(value: 2.5, color: color, type: FluentRatingType.display),
      const SizedBox.shrink(),

      for (final size in FluentRatingSize.values)
        FluentRating(
          value: 3,
          size: size,
          color: FluentRatingColor.marigold,
          onChanged: (_) {},
        ),

      const FluentRating(value: 3),
      const FluentRating(value: 7, max: 10, type: FluentRatingType.display),
      const FluentRating(value: 0, type: FluentRatingType.display),
      const FluentRating(value: 5, type: FluentRatingType.display),
    ]),
  );
}
