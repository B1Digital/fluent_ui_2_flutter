import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Rating docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage ratingPage = DocsPage(
  id: 'components-rating',
  title: 'Rating',
  description:
      'A Rating component allows users to provide a rating for a particular '
      'item. Rating allows customers to determine a sense of value of a good '
      'or a service. By default, the rating is selected out of 5 stars, but '
      'the number and symbol used can be customized. To display the result of '
      "other users' rating values, use RatingDisplay instead.",
  source: 'lib/pages/components_rating.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-rating--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-rating--controlled-value',
      title: 'Controlled Value',
      description:
          'The selected rating value can be controlled using the value and '
          'onChange props.',
      builder: _controlledValue,
    ),
    DocsSection(
      id: 'components-rating--step',
      title: 'Step',
      description: 'You can specify half values in the Rating with step={0.5}.',
      builder: _step,
    ),
    DocsSection(
      id: 'components-rating--max',
      title: 'Max',
      description:
          'You can specify the number of elements in the Rating with the max '
          'prop.',
      builder: _max,
    ),
    DocsSection(
      id: 'components-rating--size',
      title: 'Size',
      description:
          "A Rating's size can be small, medium, large, or extra-large.",
      builder: _size,
    ),
    DocsSection(
      id: 'components-rating--color',
      title: 'Color',
      description:
          "A Rating's color can be neutral (default), brand, or marigold.",
      builder: _color,
    ),
    DocsSection(
      id: 'components-rating--shape',
      title: 'Shape',
      description:
          'You can pass in custom icons to the Rating component. You can '
          'specify the icons with the iconFilled and iconOutline props.',
      builder: _shape,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'value',
      type: 'double',
      description:
          'The rating being shown. Rounded to the nearest half before it is '
          'drawn.',
    ),
    PropRow(
      name: 'onChanged',
      type: 'ValueChanged<double>?',
      defaultValue: 'null',
      description:
          'Invoked with the new value on click and on the arrow keys. Null '
          'disables the rating.',
    ),
    PropRow(
      name: 'max',
      type: 'int',
      defaultValue: '5',
      description: 'How many shapes a full rating is worth.',
    ),
    PropRow(
      name: 'step',
      type: 'double',
      defaultValue: '1',
      description:
          'The granularity the control commits at: 1, or 0.5 for half values.',
    ),
    PropRow(
      name: 'compact',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether a single filled shape stands in for the whole row.',
    ),
    PropRow(
      name: 'type',
      type: 'FluentRatingType',
      defaultValue: 'FluentRatingType.interactive',
      description: 'Whether the rating takes input.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentRatingSize',
      defaultValue: 'FluentRatingSize.extraLarge',
      description: 'Shape box edge length.',
    ),
    PropRow(
      name: 'shape',
      type: 'FluentRatingShape',
      defaultValue: 'FluentRatingShape.star',
      description: 'Which silhouette is drawn.',
    ),
    PropRow(
      name: 'color',
      type: 'FluentRatingColor',
      defaultValue: 'FluentRatingColor.neutral',
      description: 'Which colour family the shapes take.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentRatingStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Announced by assistive technology alongside the value.',
    ),
  ],
);

// #docregion components-rating--default
// Upstream's Rating is uncontrolled — it keeps the value itself. FluentRating
// requires `value`, so every demo on this page owns the value it shows.
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  double _value = 0;

  @override
  Widget build(BuildContext context) => FluentRating(
    value: _value,
    onChanged: (double value) => setState(() => _value = value),
  );
}
// #enddocregion components-rating--default

// #docregion components-rating--controlled-value
Widget _controlledValue(BuildContext context) => const _ControlledValue();

class _ControlledValue extends StatefulWidget {
  const _ControlledValue();

  @override
  State<_ControlledValue> createState() => _ControlledValueState();
}

class _ControlledValueState extends State<_ControlledValue> {
  double _value = 4;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentRating(
        value: _value,
        onChanged: (double value) => setState(() => _value = value),
      ),
      const SizedBox(height: 10),
      FluentButton(
        onPressed: () => setState(() => _value = 0),
        child: const Text('Clear Rating'),
      ),
    ],
  );
}
// #enddocregion components-rating--controlled-value

// #docregion components-rating--step
Widget _step(BuildContext context) => const _Step();

class _Step extends StatefulWidget {
  const _Step();

  @override
  State<_Step> createState() => _StepState();
}

class _StepState extends State<_Step> {
  double _value = 3.5;

  @override
  Widget build(BuildContext context) => FluentRating(
    step: 0.5,
    value: _value,
    onChanged: (double value) => setState(() => _value = value),
  );
}
// #enddocregion components-rating--step

// #docregion components-rating--max
Widget _max(BuildContext context) => const _Max();

class _Max extends StatefulWidget {
  const _Max();

  @override
  State<_Max> createState() => _MaxState();
}

class _MaxState extends State<_Max> {
  double _value = 5;

  @override
  Widget build(BuildContext context) => FluentRating(
    max: 10,
    value: _value,
    onChanged: (double value) => setState(() => _value = value),
  );
}
// #enddocregion components-rating--max

// #docregion components-rating--size
Widget _size(BuildContext context) => const _Size();

class _Size extends StatefulWidget {
  const _Size();

  @override
  State<_Size> createState() => _SizeState();
}

class _SizeState extends State<_Size> {
  // One value per row, so each rating stays independently interactive.
  final List<double> _values = <double>[3, 3, 3, 3];

  Widget _rating(int index, FluentRatingSize size) => FluentRating(
    value: _values[index],
    size: size,
    onChanged: (double value) => setState(() => _values[index] = value),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _rating(0, FluentRatingSize.small),
      const SizedBox(height: 10),
      _rating(1, FluentRatingSize.medium),
      const SizedBox(height: 10),
      _rating(2, FluentRatingSize.large),
      const SizedBox(height: 10),
      _rating(3, FluentRatingSize.extraLarge),
    ],
  );
}
// #enddocregion components-rating--size

// #docregion components-rating--color
Widget _color(BuildContext context) => const _Color();

class _Color extends StatefulWidget {
  const _Color();

  @override
  State<_Color> createState() => _ColorState();
}

class _ColorState extends State<_Color> {
  // One value per row, so each rating stays independently interactive.
  final List<double> _values = <double>[3, 3, 3];

  Widget _rating(int index, FluentRatingColor color) => FluentRating(
    value: _values[index],
    color: color,
    onChanged: (double value) => setState(() => _values[index] = value),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _rating(0, FluentRatingColor.neutral),
      const SizedBox(height: 10),
      _rating(1, FluentRatingColor.brand),
      const SizedBox(height: 10),
      _rating(2, FluentRatingColor.marigold),
    ],
  );
}
// #enddocregion components-rating--color

// #docregion components-rating--shape
// Upstream swaps the glyph through `iconFilled` / `iconOutline`, taking
// CircleFilled/CircleRegular and SquareFilled/SquareRegular. FluentRating draws
// its silhouettes itself, so the same two rows come from `shape` instead.
Widget _shape(BuildContext context) => const _Shape();

class _Shape extends StatefulWidget {
  const _Shape();

  @override
  State<_Shape> createState() => _ShapeState();
}

class _ShapeState extends State<_Shape> {
  // One value per row, so each rating stays independently interactive.
  final List<double> _values = <double>[0, 0];

  Widget _rating(int index, FluentRatingShape shape) => FluentRating(
    value: _values[index],
    shape: shape,
    step: 0.5,
    onChanged: (double value) => setState(() => _values[index] = value),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _rating(0, FluentRatingShape.circle),
      const SizedBox(height: 10),
      _rating(1, FluentRatingShape.square),
    ],
  );
}

// #enddocregion components-rating--shape
