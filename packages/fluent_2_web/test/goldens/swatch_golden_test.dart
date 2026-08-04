import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Rows 1–4: the four sizes, each as colour, icon, empty and transparent.
/// Row 5: the three shapes, plus a selected swatch.
/// Row 6: selected at every size — the band steps from 2/1 to 3/2 at Medium.
/// Row 7: disabled, and the two pickers.
///
/// Hover and pressed are absent on purpose: they are interaction states, and a
/// golden captures a resting frame. `swatch_test.dart` asserts both rings
/// numerically against the Figma extraction.
void main() {
  const palette = <Color>[
    Color(0xFFE3008C),
    Color(0xFF0F6CBD),
    Color(0xFF107C10),
    Color(0xFFF7630C),
    Color(0xFF5C2E91),
    Color(0xFF767171),
  ];

  Widget colour(FluentSwatchSize size, {bool selected = false}) => FluentSwatch(
    color: palette.first,
    size: size,
    selected: selected,
    semanticLabel: 'Hot pink',
    onPressed: () {},
  );

  Widget icon(FluentSwatchSize size) => FluentSwatch(
    color: palette[1],
    size: size,
    icon: const Icon(FluentIcons.checkmark_20_filled),
    semanticLabel: 'Brand blue',
    onPressed: () {},
  );

  Widget picker(FluentSwatchPickerLayout layout) => FluentSwatchPicker(
    layout: layout,
    semanticLabel: 'Palette',
    spacing: layout == FluentSwatchPickerLayout.grid
        ? FluentSwatchPickerSpacing.small
        : FluentSwatchPickerSpacing.medium,
    children: <Widget>[
      for (final (index, color) in palette.indexed)
        FluentSwatch(
          color: color,
          selected: index == 1,
          semanticLabel: 'Colour $index',
          onPressed: () {},
        ),
    ],
  );

  goldenGridTest(
    'swatch',
    () => goldenGrid(<Widget>[
      for (final size in FluentSwatchSize.values) ...<Widget>[
        colour(size),
        icon(size),
        FluentSwatch.empty(
          size: size,
          semanticLabel: 'No colour yet',
          onPressed: () {},
        ),
        FluentSwatch.transparent(
          size: size,
          semanticLabel: 'No colour',
          onPressed: () {},
        ),
      ],
      for (final shape in FluentSwatchShape.values)
        FluentSwatch(
          color: palette[2],
          shape: shape,
          semanticLabel: 'Green',
          onPressed: () {},
        ),
      colour(FluentSwatchSize.medium, selected: true),
      for (final size in FluentSwatchSize.values) colour(size, selected: true),
      // Disabled keeps its colour and is struck through.
      const FluentSwatch(color: Color(0xFFE3008C), semanticLabel: 'Hot pink'),
      picker(FluentSwatchPickerLayout.row),
      picker(FluentSwatchPickerLayout.grid),
    ], columns: 4),
  );
}
