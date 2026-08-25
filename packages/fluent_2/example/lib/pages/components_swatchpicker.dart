import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The SwatchPicker docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage swatchPickerPage = DocsPage(
  id: 'components-swatchpicker',
  title: 'SwatchPicker',
  description:
      'A swatch picker lets people choose a color, image, or pattern and apply '
      'it to graphics or text.',
  source: 'lib/pages/components_swatchpicker.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-swatchpicker--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-swatchpicker--swatch-picker-size',
      title: 'Swatch Picker Size',
      description:
          'The size prop sets width and height of the Swatch. The default is '
          'medium which is 28x28px. extra-small is 20x20px, small is 24x24px, '
          'large is 32x32px.',
      builder: _swatchPickerSize,
    ),
    DocsSection(
      id: 'components-swatchpicker--swatch-picker-shape',
      title: 'Swatch Picker Shape',
      description:
          'The shape prop sets border-radius of the Swatch. The default is '
          'square.',
      builder: _swatchPickerShape,
    ),
    DocsSection(
      id: 'components-swatchpicker--swatch-picker-layout',
      title: 'Swatch Picker Layout',
      description: 'The layout prop places items in a row or a grid.',
      builder: _swatchPickerLayout,
    ),
    DocsSection(
      id: 'components-swatchpicker--swatch-picker-spacing',
      title: 'Swatch Picker Spacing',
      description: 'The spacing prop sets gap between swatches.',
      builder: _swatchPickerSpacing,
    ),
    DocsSection(
      id: 'components-swatchpicker--swatch-picker-image',
      title: 'Swatch Picker Image',
      description: 'A swatch can be represented as an image.',
      builder: _swatchPickerImage,
    ),
    DocsSection(
      id: 'components-swatchpicker--empty-swatch-example',
      title: 'Empty Swatch Example',
      description:
          'Empty swatch is used for cases where new swatches can be added.',
      builder: _emptySwatchExample,
    ),
    DocsSection(
      id: 'components-swatchpicker--color-swatch-variants',
      title: 'Color Swatch Variants',
      description:
          'ColorSwatch component can have color, gradient, icon and initials.',
      builder: _colorSwatchVariants,
    ),
    DocsSection(
      id: 'components-swatchpicker--swatch-picker-mixed-swatches',
      title: 'Swatch Picker Mixed Swatches',
      description:
          "It's possible to use ColorSwatch and ImageSwatch in one "
          'SwatchPicker.',
      builder: _swatchPickerMixedSwatches,
    ),
    DocsSection(
      id: 'components-swatchpicker--swatch-picker-with-tooltip',
      title: 'Swatch Picker With Tooltip',
      description: 'Each swatch should have a descriptive tooltip.',
      builder: _swatchPickerWithTooltip,
    ),
    DocsSection(
      id: 'components-swatchpicker--swatch-picker-focus-mode',
      title: 'Swatch Picker Focus Mode',
      description:
          'The focusMode prop controls how focus moves between swatches. Use '
          '"arrow" (default) to navigate with arrow keys, or "tab" to navigate '
          'with the Tab key.',
      builder: _swatchPickerFocusMode,
    ),
    DocsSection(
      id: 'components-swatchpicker--swatch-picker-popup',
      title: 'Swatch Picker Popup',
      description:
          'The swatch picker can be integrated within a popover or similar '
          'element.',
      builder: _swatchPickerPopup,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'children',
      type: 'List<Widget>',
      description: 'The swatches.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String',
      description: "Announced by assistive technology as the group's name.",
    ),
    PropRow(
      name: 'layout',
      type: 'FluentSwatchPickerLayout',
      defaultValue: 'FluentSwatchPickerLayout.row',
      description: 'Row or grid.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentSwatchSize',
      defaultValue: 'FluentSwatchSize.medium',
      description: 'The footprint every swatch inside takes.',
    ),
    PropRow(
      name: 'shape',
      type: 'FluentSwatchShape',
      defaultValue: 'FluentSwatchShape.square',
      description: 'The corner treatment every swatch inside takes.',
    ),
    PropRow(
      name: 'spacing',
      type: 'FluentSwatchPickerSpacing',
      defaultValue: 'FluentSwatchPickerSpacing.medium',
      description: 'Gap between swatches.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentSwatchPickerStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
  ],
);

// #docregion components-swatchpicker--default
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  String _selectedValue = '00B053';
  Color _selectedColor = const Color(0xFF00B053);

  Widget _swatch(
    String value,
    Color color,
    String label, {
    bool disabled = false,
  }) => FluentSwatch(
    color: color,
    semanticLabel: label,
    selected: _selectedValue == value,
    onPressed: disabled
        ? null
        : () => setState(() {
            _selectedValue = value;
            _selectedColor = color;
          }),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentSwatchPicker(
        semanticLabel: 'SwatchPicker default',
        children: <Widget>[
          _swatch('FF1921', const Color(0xFFFF1921), 'red'),
          _swatch('FF7A00', const Color(0xFFFF7A00), 'orange'),
          _swatch('90D057', const Color(0xFF90D057), 'light green'),
          _swatch('00B053', const Color(0xFF00B053), 'green'),
          _swatch('00AFED', const Color(0xFF00AFED), 'light blue'),
          _swatch('006EBD', const Color(0xFF006EBD), 'blue'),
          _swatch(
            '011F5E',
            const Color(0xFF011F5E),
            'dark blue',
            disabled: true,
          ),
          _swatch('712F9E', const Color(0xFF712F9E), 'purple'),
        ],
      ),
      const SizedBox(height: 20),
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: _selectedColor,
          border: Border.all(color: const Color(0xFFCCCCCC)),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}
// #enddocregion components-swatchpicker--default

// #docregion components-swatchpicker--swatch-picker-size
const List<(String, Color, String)> _sizeColors = <(String, Color, String)>[
  ('FF1921', Color(0xFFFF1921), 'red'),
  ('FF7A00', Color(0xFFFF7A00), 'orange'),
  ('90D057', Color(0xFF90D057), 'light green'),
  ('00B053', Color(0xFF00B053), 'green'),
  ('00AFED', Color(0xFF00AFED), 'light blue'),
  ('006EBD', Color(0xFF006EBD), 'blue'),
  ('011F5E', Color(0xFF011F5E), 'dark blue'),
  ('712F9E', Color(0xFF712F9E), 'purple'),
];

Widget _swatchPickerSize(BuildContext context) => const _SwatchPickerSize();

class _SwatchPickerSize extends StatefulWidget {
  const _SwatchPickerSize();

  @override
  State<_SwatchPickerSize> createState() => _SwatchPickerSizeState();
}

class _SwatchPickerSizeState extends State<_SwatchPickerSize> {
  String _selectedValue = '';

  Widget _picker(String semanticLabel, FluentSwatchSize size) =>
      FluentSwatchPicker(
        semanticLabel: semanticLabel,
        size: size,
        children: <Widget>[
          for (final (String value, Color color, String label) in _sizeColors)
            FluentSwatch(
              color: color,
              semanticLabel: label,
              selected: _selectedValue == value,
              onPressed: () => setState(() => _selectedValue = value),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final TextStyle heading = FluentTheme.of(context).typography.subtitle2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: <Widget>[
        Text('Large', style: heading),
        _picker('SwatchPicker large size', FluentSwatchSize.large),
        Text('Medium', style: heading),
        _picker('SwatchPicker medium size', FluentSwatchSize.medium),
        Text('Small', style: heading),
        _picker('SwatchPicker small size', FluentSwatchSize.small),
        Text('Extra small', style: heading),
        _picker('SwatchPicker extra small size', FluentSwatchSize.extraSmall),
      ],
    );
  }
}
// #enddocregion components-swatchpicker--swatch-picker-size

// #docregion components-swatchpicker--swatch-picker-shape
const List<(String, Color, String)> _shapeColors = <(String, Color, String)>[
  ('FF1921', Color(0xFFFF1921), 'red'),
  ('FF7A00', Color(0xFFFF7A00), 'dark orange'),
  ('FFC12E', Color(0xFFFFC12E), 'orange'),
  ('90D057', Color(0xFF90D057), 'light green'),
  ('00B053', Color(0xFF00B053), 'green'),
  ('00AFED', Color(0xFF00AFED), 'light blue'),
  ('006EBD', Color(0xFF006EBD), 'blue'),
  ('011F5E', Color(0xFF011F5E), 'dark blue'),
  ('712F9E', Color(0xFF712F9E), 'purple'),
];

Widget _swatchPickerShape(BuildContext context) => const _SwatchPickerShape();

class _SwatchPickerShape extends StatefulWidget {
  const _SwatchPickerShape();

  @override
  State<_SwatchPickerShape> createState() => _SwatchPickerShapeState();
}

class _SwatchPickerShapeState extends State<_SwatchPickerShape> {
  String _selectedValue = '';

  Widget _picker(String semanticLabel, FluentSwatchShape shape) =>
      FluentSwatchPicker(
        semanticLabel: semanticLabel,
        shape: shape,
        children: <Widget>[
          for (final (String value, Color color, String label) in _shapeColors)
            FluentSwatch(
              color: color,
              semanticLabel: label,
              selected: _selectedValue == value,
              onPressed: () => setState(() => _selectedValue = value),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final TextStyle heading = FluentTheme.of(context).typography.subtitle2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: <Widget>[
        Text('Square', style: heading),
        _picker('SwatchPicker square shape', FluentSwatchShape.square),
        Text('Circular', style: heading),
        _picker('SwatchPicker circular shape', FluentSwatchShape.circular),
        Text('Rounded', style: heading),
        _picker('SwatchPicker rounded shape', FluentSwatchShape.rounded),
      ],
    );
  }
}
// #enddocregion components-swatchpicker--swatch-picker-shape

// #docregion components-swatchpicker--swatch-picker-layout
const List<(String, Color, String)> _layoutColors = <(String, Color, String)>[
  ('FF1921', Color(0xFFFF1921), 'red'),
  ('FF7A00', Color(0xFFFF7A00), 'orange'),
  ('90D057', Color(0xFF90D057), 'light green'),
  ('00B053', Color(0xFF00B053), 'green'),
  ('00AFED', Color(0xFF00AFED), 'light blue'),
  ('006EBD', Color(0xFF006EBD), 'blue'),
  ('011F5E', Color(0xFF011F5E), 'dark blue'),
  ('712F9E', Color(0xFF712F9E), 'purple'),
  ('FF0099', Color(0xFFFF0099), 'pink'),
];

Widget _swatchPickerLayout(BuildContext context) => const _SwatchPickerLayout();

class _SwatchPickerLayout extends StatefulWidget {
  const _SwatchPickerLayout();

  @override
  State<_SwatchPickerLayout> createState() => _SwatchPickerLayoutState();
}

class _SwatchPickerLayoutState extends State<_SwatchPickerLayout> {
  String _selectedValue = '00B053';
  Color _selectedSwatch = const Color(0xFF00B053);

  Widget _picker(String semanticLabel, FluentSwatchPickerLayout layout) =>
      FluentSwatchPicker(
        semanticLabel: semanticLabel,
        layout: layout,
        children: <Widget>[
          for (final (String value, Color color, String label) in _layoutColors)
            FluentSwatch(
              color: color,
              semanticLabel: label,
              selected: _selectedValue == value,
              onPressed: () => setState(() {
                _selectedValue = value;
                _selectedSwatch = color;
              }),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final TextStyle heading = FluentTheme.of(context).typography.subtitle2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Row', style: heading),
        _picker('SwatchPicker row layout', FluentSwatchPickerLayout.row),
        Text('Grid', style: heading),
        // Upstream's `renderSwatchPickerGrid({ columnCount: 3 })` buckets the
        // items into rows; ours is a Wrap, so three columns is a width — three
        // 28px swatches, two 4px gaps, and the picker's own 10px padding on
        // each side.
        SizedBox(
          width: 3 * 28 + 2 * 4 + 2 * 10,
          child: _picker(
            'SwatchPicker grid layout',
            FluentSwatchPickerLayout.grid,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _selectedSwatch,
            border: Border.all(color: const Color(0xFFCCCCCC)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
// #enddocregion components-swatchpicker--swatch-picker-layout

// #docregion components-swatchpicker--swatch-picker-spacing
const List<(String, Color, String)> _spacingColors = <(String, Color, String)>[
  ('FF1921', Color(0xFFFF1921), 'red'),
  ('FF7A00', Color(0xFFFF7A00), 'dark orange'),
  ('FFC12E', Color(0xFFFFC12E), 'orange'),
  ('90D057', Color(0xFF90D057), 'light green'),
  ('00B053', Color(0xFF00B053), 'green'),
  ('00AFED', Color(0xFF00AFED), 'light blue'),
  ('006EBD', Color(0xFF006EBD), 'blue'),
  ('011F5E', Color(0xFF011F5E), 'dark blue'),
  ('712F9E', Color(0xFF712F9E), 'purple'),
];

Widget _swatchPickerSpacing(BuildContext context) =>
    const _SwatchPickerSpacing();

class _SwatchPickerSpacing extends StatefulWidget {
  const _SwatchPickerSpacing();

  @override
  State<_SwatchPickerSpacing> createState() => _SwatchPickerSpacingState();
}

class _SwatchPickerSpacingState extends State<_SwatchPickerSpacing> {
  String _selectedValue = '';

  Widget _picker(String semanticLabel, FluentSwatchPickerSpacing spacing) =>
      FluentSwatchPicker(
        semanticLabel: semanticLabel,
        layout: FluentSwatchPickerLayout.grid,
        spacing: spacing,
        children: <Widget>[
          for (final (String value, Color color, String label)
              in _spacingColors)
            FluentSwatch(
              color: color,
              semanticLabel: label,
              selected: _selectedValue == value,
              onPressed: () => setState(() => _selectedValue = value),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final TextStyle heading = FluentTheme.of(context).typography.subtitle2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: <Widget>[
        Text('Medium', style: heading),
        // Three columns is a width: three 28px swatches, two gaps of the
        // spacing being demonstrated, and the picker's own 10px padding on
        // each side.
        SizedBox(
          width: 3 * 28 + 2 * 4 + 2 * 10,
          child: _picker(
            'SwatchPicker medium spacing',
            FluentSwatchPickerSpacing.medium,
          ),
        ),
        Text('Small', style: heading),
        SizedBox(
          width: 3 * 28 + 2 * 2 + 2 * 10,
          child: _picker(
            'SwatchPicker small spacing',
            FluentSwatchPickerSpacing.small,
          ),
        ),
      ],
    );
  }
}
// #enddocregion components-swatchpicker--swatch-picker-spacing

// #docregion components-swatchpicker--swatch-picker-image
/// `(value, label, swatch image, full image)`. Upstream loads these from
/// `fabricweb.azureedge.net`; they ship as assets here.
const List<(String, String, String, String)> _images =
    <(String, String, String, String)>[
      ('0', 'sea', 'sea-swatch.jpg', 'sea-full-img.jpg'),
      ('1', 'bridge', 'bridge-swatch.jpg', 'bridge-full-img.jpg'),
      ('2', 'park', 'park-swatch.jpg', 'park-full-img.jpg'),
    ];

const String _defaultImage = 'bridge-full-img.jpg';

Widget _swatchPickerImage(BuildContext context) => const _SwatchPickerImage();

class _SwatchPickerImage extends StatefulWidget {
  const _SwatchPickerImage();

  @override
  State<_SwatchPickerImage> createState() => _SwatchPickerImageState();
}

class _SwatchPickerImageState extends State<_SwatchPickerImage> {
  String _selectedValue = '1';
  String _selectedImage = _defaultImage;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentSwatchPicker(
        semanticLabel: 'SwatchPicker with images',
        children: <Widget>[
          for (final (
                String value,
                String label,
                String swatch,
                String fullImage,
              )
              in _images)
            FluentSwatch.image(
              image: AssetImage('assets/storybook/$swatch'),
              semanticLabel: label,
              selected: _selectedValue == value,
              // Upstream sizes these swatches at 100x100 from CSS rather than
              // from the `size` ramp, so the override goes on `style`, which is
              // the one rung above the picker's own theme.
              style: const FluentSwatchStyle(
                size: WidgetStatePropertyAll<Size?>(Size.square(100)),
              ),
              onPressed: () => setState(() {
                _selectedValue = value;
                _selectedImage = fullImage;
              }),
            ),
        ],
      ),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        height: 466,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/storybook/$_selectedImage'),
            fit: BoxFit.contain,
            alignment: Alignment.topLeft,
          ),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}
// #enddocregion components-swatchpicker--swatch-picker-image

// #docregion components-swatchpicker--empty-swatch-example
const int _itemsLimit = 8;

const List<(String, Color, String)> _defaultItems = <(String, Color, String)>[
  ('FF1921', Color(0xFFFF1921), 'red'),
  ('FF7A00', Color(0xFFFF7A00), 'dark orange'),
  ('90D057', Color(0xFF90D057), 'light green'),
  ('00B053', Color(0xFF00B053), 'green'),
];

const Color _defaultColor = Color(0xFF2be700);

Widget _emptySwatchExample(BuildContext context) => const _EmptySwatchExample();

class _EmptySwatchExample extends StatefulWidget {
  const _EmptySwatchExample();

  @override
  State<_EmptySwatchExample> createState() => _EmptySwatchExampleState();
}

class _EmptySwatchExampleState extends State<_EmptySwatchExample> {
  List<(String, Color, String)> _items = _defaultItems;
  String _selectedValue = '00B053';
  Color _selectedColor = const Color(0xFF00B053);

  void _addColor() => setState(() {
    // "value" should be unique as it's used as a key and for selection
    final String newValue = 'custom-${_items.length - _itemsLimit}';
    _items = <(String, Color, String)>[
      ..._items,
      (newValue, _defaultColor, 'custom color'),
    ];
  });

  void _resetColors() => setState(() => _items = _defaultItems);

  @override
  Widget build(BuildContext context) {
    final TextStyle heading = FluentTheme.of(context).typography.subtitle2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: <Widget>[
        FluentSwatchPicker(
          semanticLabel: 'SwatchPicker with empty swatches',
          children: <Widget>[
            for (final (String value, Color color, String label) in _items)
              FluentSwatch(
                color: color,
                semanticLabel: label,
                selected: _selectedValue == value,
                onPressed: () => setState(() {
                  _selectedValue = value;
                  _selectedColor = color;
                }),
              ),
            for (int i = 0; i < _itemsLimit - _items.length; i++)
              // A disabled swatch is struck through with a prohibited glyph;
              // upstream's empty slots show the dashed outline alone, so the
              // mark is replaced with nothing.
              const FluentSwatch.empty(
                semanticLabel: 'empty swatch',
                disabledIcon: SizedBox.shrink(),
              ),
          ],
        ),
        Text('Selected swatch', style: heading),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _selectedColor,
            border: Border.all(color: const Color(0xFFCCCCCC)),
          ),
        ),
        // Upstream's tooltipped preview button opens a Popover holding a
        // ColorPicker, so the colour "Add new color" appends can be dialled
        // in. This package ships no colour picker, so the preview is the fixed
        // swatch below and every added colour is that one.
        FluentTooltip(
          content: const Text('Custom color'),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _defaultColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFCCCCCC)),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            FluentButton(
              appearance: FluentButtonAppearance.primary,
              onPressed: _items.length >= _itemsLimit ? null : _addColor,
              child: const Text('Add new color'),
            ),
            FluentButton(
              onPressed: _resetColors,
              child: const Text('Reset example'),
            ),
          ],
        ),
      ],
    );
  }
}
// #enddocregion components-swatchpicker--empty-swatch-example

// #docregion components-swatchpicker--color-swatch-variants
Widget _colorSwatchVariants(BuildContext context) =>
    const _ColorSwatchVariants();

class _ColorSwatchVariants extends StatefulWidget {
  const _ColorSwatchVariants();

  @override
  State<_ColorSwatchVariants> createState() => _ColorSwatchVariantsState();
}

class _ColorSwatchVariantsState extends State<_ColorSwatchVariants> {
  String _selectedValue = '';

  void _select(String value) => setState(() => _selectedValue = value);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: <Widget>[
      FluentSwatch(
        color: const Color(0xFFE3008C),
        semanticLabel: 'Hot pink',
        selected: _selectedValue == 'hot-pink-color',
        onPressed: () => _select('hot-pink-color'),
      ),
      // A swatch takes one `color`, so CSS's `linear-gradient(0deg, ...)` is
      // painted behind a fully transparent one — the ring, the states and the
      // footprint stay the widget's own.
      DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[Color(0xFFE3008C), Color(0xFFfff232)],
          ),
        ),
        child: FluentSwatch(
          color: const Color(0x00000000),
          semanticLabel: 'Gradient yellow pink',
          selected: _selectedValue == 'gradient',
          onPressed: () => _select('gradient'),
        ),
      ),
      FluentSwatch(
        color: const Color(0xFFc8eeff),
        icon: const Icon(FluentIcons.heart_20_filled, color: Color(0xFFFF0000)),
        semanticLabel: 'heart icon',
        selected: _selectedValue == 'icon',
        onPressed: () => _select('icon'),
      ),
      // Upstream disables these two, so they carry a value but no handler.
      FluentSwatch(
        color: const Color(0xFF016ab0),
        semanticLabel: 'blue',
        selected: _selectedValue == 'blue',
      ),
      FluentSwatch(
        color: const Color(0xFFff659a),
        icon: const Text('A'),
        semanticLabel: 'initials',
        selected: _selectedValue == 'initials',
        onPressed: () => _select('initials'),
      ),
      FluentSwatch(
        color: const Color(0xFFc8eeff),
        semanticLabel: 'light blue',
        selected: _selectedValue == 'light-blue',
      ),
    ],
  );
}
// #enddocregion components-swatchpicker--color-swatch-variants

// #docregion components-swatchpicker--swatch-picker-mixed-swatches
const List<(String, Color, String)> _mixedColors = <(String, Color, String)>[
  ('FF1921', Color(0xFFFF1921), 'red'),
  ('FF7A00', Color(0xFFFF7A00), 'orange'),
  ('90D057', Color(0xFF90D057), 'light green'),
  ('00B053', Color(0xFF00B053), 'green'),
  ('00AFED', Color(0xFF00AFED), 'light blue'),
  ('006EBD', Color(0xFF006EBD), 'blue'),
];

const List<(String, String)> _mixedImages = <(String, String)>[
  ('sea', 'sea-swatch.jpg'),
  ('bridge', 'bridge-swatch.jpg'),
  ('park', 'park-swatch.jpg'),
];

Widget _swatchPickerMixedSwatches(BuildContext context) =>
    const _SwatchPickerMixedSwatches();

class _SwatchPickerMixedSwatches extends StatefulWidget {
  const _SwatchPickerMixedSwatches();

  @override
  State<_SwatchPickerMixedSwatches> createState() =>
      _SwatchPickerMixedSwatchesState();
}

class _SwatchPickerMixedSwatchesState
    extends State<_SwatchPickerMixedSwatches> {
  String _selectedValue = '00B053';
  Color? _selectedColor = const Color(0xFF00B053);
  String? _selectedImage;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // Three columns is a width: three 28px swatches, two 4px gaps, and the
      // picker's own 10px padding on each side.
      SizedBox(
        width: 3 * 28 + 2 * 4 + 2 * 10,
        child: FluentSwatchPicker(
          semanticLabel: 'SwatchPicker with both colors and images',
          layout: FluentSwatchPickerLayout.grid,
          children: <Widget>[
            for (final (String value, Color color, String label)
                in _mixedColors)
              FluentSwatch(
                color: color,
                semanticLabel: label,
                selected: _selectedValue == value,
                onPressed: () => setState(() {
                  _selectedValue = value;
                  _selectedColor = color;
                  _selectedImage = null;
                }),
              ),
            for (final (String value, String asset) in _mixedImages)
              FluentSwatch.image(
                image: AssetImage('assets/storybook/$asset'),
                semanticLabel: value,
                selected: _selectedValue == value,
                onPressed: () => setState(() {
                  _selectedValue = value;
                  _selectedColor = null;
                  _selectedImage = asset;
                }),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: _selectedColor,
          image: _selectedImage == null
              ? null
              : DecorationImage(
                  image: AssetImage('assets/storybook/$_selectedImage'),
                  fit: BoxFit.cover,
                ),
          border: Border.all(color: const Color(0xFFCCCCCC)),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}
// #enddocregion components-swatchpicker--swatch-picker-mixed-swatches

// #docregion components-swatchpicker--swatch-picker-with-tooltip
const List<(String, Color, String)> _tooltipColors = <(String, Color, String)>[
  ('FF1921', Color(0xFFFF1921), 'red'),
  ('FF7A00', Color(0xFFFF7A00), 'orange'),
  ('90D057', Color(0xFF90D057), 'light green'),
  ('00B053', Color(0xFF00B053), 'green'),
  ('00AFED', Color(0xFF00AFED), 'light blue'),
  ('006EBD', Color(0xFF006EBD), 'blue'),
  ('011F5E', Color(0xFF011F5E), 'dark blue'),
  ('712F9E', Color(0xFF712F9E), 'purple'),
  ('FF0099', Color(0xFFFF0099), 'pink'),
];

Widget _swatchPickerWithTooltip(BuildContext context) =>
    const _SwatchPickerWithTooltip();

class _SwatchPickerWithTooltip extends StatefulWidget {
  const _SwatchPickerWithTooltip();

  @override
  State<_SwatchPickerWithTooltip> createState() =>
      _SwatchPickerWithTooltipState();
}

class _SwatchPickerWithTooltipState extends State<_SwatchPickerWithTooltip> {
  String _selectedValue = '00B053';
  Color _selectedColor = const Color(0xFF00B053);

  Widget _picker(String semanticLabel, FluentSwatchPickerLayout layout) =>
      FluentSwatchPicker(
        semanticLabel: semanticLabel,
        layout: layout,
        children: <Widget>[
          for (final (String value, Color color, String label)
              in _tooltipColors)
            FluentTooltip(
              withArrow: true,
              content: Text(label),
              child: FluentSwatch(
                color: color,
                semanticLabel: label,
                selected: _selectedValue == value,
                onPressed: () => setState(() {
                  _selectedValue = value;
                  _selectedColor = color;
                }),
              ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final TextStyle heading = FluentTheme.of(context).typography.subtitle2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Row layout', style: heading),
        _picker('SwatchPicker row layout', FluentSwatchPickerLayout.row),
        Text('Grid layout', style: heading),
        // Three columns is a width: three 28px swatches, two 4px gaps, and the
        // picker's own 10px padding on each side.
        SizedBox(
          width: 3 * 28 + 2 * 4 + 2 * 10,
          child: _picker(
            'SwatchPicker grid layout',
            FluentSwatchPickerLayout.grid,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _selectedColor,
            border: Border.all(color: const Color(0xFFCCCCCC)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
// #enddocregion components-swatchpicker--swatch-picker-with-tooltip

// #docregion components-swatchpicker--swatch-picker-focus-mode
const List<(String, Color, String)> _focusColors = <(String, Color, String)>[
  ('FF1921', Color(0xFFFF1921), 'red'),
  ('FF7A00', Color(0xFFFF7A00), 'orange'),
  ('90D057', Color(0xFF90D057), 'light green'),
  ('00B053', Color(0xFF00B053), 'green'),
  ('00AFED', Color(0xFF00AFED), 'light blue'),
  ('006EBD', Color(0xFF006EBD), 'blue'),
];

Widget _swatchPickerFocusMode(BuildContext context) =>
    const _SwatchPickerFocusMode();

class _SwatchPickerFocusMode extends StatefulWidget {
  const _SwatchPickerFocusMode();

  @override
  State<_SwatchPickerFocusMode> createState() => _SwatchPickerFocusModeState();
}

class _SwatchPickerFocusModeState extends State<_SwatchPickerFocusMode> {
  String _selectedValue = '00B053';

  Widget _picker(String semanticLabel) => FluentSwatchPicker(
    semanticLabel: semanticLabel,
    children: <Widget>[
      for (final (String value, Color color, String label) in _focusColors)
        FluentSwatch(
          color: color,
          semanticLabel: label,
          selected: _selectedValue == value,
          onPressed: () => setState(() => _selectedValue = value),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final TextStyle heading = FluentTheme.of(context).typography.subtitle2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // `FluentSwatchPicker` has no `focusMode`: Flutter's traversal already
        // walks a row of focusable children with both Tab and the arrow keys,
        // so the two pickers below differ only in the label upstream gives
        // them.
        Text('Arrow navigation (default)', style: heading),
        _picker('SwatchPicker with arrow navigation'),
        Text('Tab navigation', style: heading),
        _picker('SwatchPicker with tab navigation'),
      ],
    );
  }
}
// #enddocregion components-swatchpicker--swatch-picker-focus-mode

// #docregion components-swatchpicker--swatch-picker-popup
/// One choice in the popup. A single colour is flat; two or more are the stops
/// of a CSS `linear-gradient(0deg, ...)`, which runs bottom to top.
@immutable
class _Choice {
  const _Choice(this.value, this.label, this.colors, [this.stops]);

  final String value;
  final String label;
  final List<Color> colors;
  final List<double>? stops;

  BoxDecoration get decoration => BoxDecoration(
    color: colors.length == 1 ? colors.single : null,
    gradient: colors.length == 1
        ? null
        : LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: colors,
            stops: stops,
          ),
  );
}

const List<_Choice> _colorSet1 = <_Choice>[
  _Choice('FF1921', 'red', <Color>[Color(0xFFFF1921)]),
  _Choice('00B053', 'green', <Color>[Color(0xFF00B053)]),
  _Choice('00AFED', 'light blue', <Color>[Color(0xFF00AFED)]),
  _Choice('006EBD', 'blue', <Color>[Color(0xFF006EBD)]),
  _Choice('712F9E', 'purple', <Color>[Color(0xFF712F9E)]),
];

const List<_Choice> _colorSet2 = <_Choice>[
  _Choice('FF7A00', 'dark orange', <Color>[Color(0xFFFF7A00)]),
  _Choice('90D057', 'light green', <Color>[Color(0xFF90D057)]),
  _Choice('3BC4F5', 'light blue 10', <Color>[Color(0xFF3BC4F5)]),
  _Choice('1F93E6', 'blue 10', <Color>[Color(0xFF1F93E6)]),
  _Choice('A01CFa', 'bright purple', <Color>[Color(0xFFA01CFa)]),
  _Choice('orange-red', 'gradient orange-red', <Color>[
    Color(0xFFFF1921),
    Color(0xFFFFB92E),
  ]),
  _Choice('light-green-gradient', 'gradient light green', <Color>[
    Color(0xFF00B053),
    Color(0xFF90D057),
  ]),
  _Choice('blue gradient', 'gradient blue', <Color>[
    Color(0xFF006EBD),
    Color(0xFF00AFED),
  ]),
  _Choice('blue-purple', 'gradient blue-purple', <Color>[
    Color(0xFF712F9E),
    Color(0xFF00AFED),
  ]),
  _Choice('blue-purple', 'gradient pink-purple', <Color>[
    Color(0xFFfA1CBC),
    Color(0xFFA01CFa),
  ]),
  _Choice('yellow-orange', 'gradient yellow-orange', <Color>[
    Color(0xFFFFC12E),
    Color(0xFFFEFF37),
  ]),
  _Choice('yellow-green', 'gradient yellow-green', <Color>[
    Color(0xFF90D057),
    Color(0xFFFEFF37),
  ]),
  _Choice('green-blue', 'gradient green-blue', <Color>[
    Color(0xFF00B053),
    Color(0xFF00AFED),
  ]),
  _Choice('blue-purple gradient', 'gradient blue', <Color>[
    Color(0xFFA01CFA),
    Color(0xFF00AFED),
  ]),
  _Choice(
    'gradient',
    'gradient rainbow',
    <Color>[
      Color(0xFFFF1921),
      Color(0xFFFFC12E),
      Color(0xFFFEFF37),
      Color(0xFF90D057),
      Color(0xFF00B053),
      Color(0xFF00AFED),
      Color(0xFF006EBD),
      Color(0xFF011F5E),
      Color(0xFF712F9E),
    ],
    <double>[0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
  ),
];

Widget _swatchPickerPopup(BuildContext context) => const _SwatchPickerPopup();

class _SwatchPickerPopup extends StatefulWidget {
  const _SwatchPickerPopup();

  @override
  State<_SwatchPickerPopup> createState() => _SwatchPickerPopupState();
}

class _SwatchPickerPopupState extends State<_SwatchPickerPopup> {
  bool _popoverOpen = false;
  _Choice _selected = const _Choice('00B053', 'green', <Color>[
    Color(0xFF00B053),
  ]);

  Widget _swatch(_Choice choice) {
    final FluentSwatch swatch = FluentSwatch(
      // A swatch takes one `color`, so a gradient is painted behind a fully
      // transparent one by the DecoratedBox below.
      color: choice.colors.length == 1
          ? choice.colors.single
          : const Color(0x00000000),
      semanticLabel: choice.label,
      selected: _selected.value == choice.value,
      onPressed: () => setState(() {
        _selected = choice;
        _popoverOpen = false;
      }),
    );
    return choice.colors.length == 1
        ? swatch
        : DecoratedBox(decoration: choice.decoration, child: swatch);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle heading = FluentTheme.of(context).typography.subtitle2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FluentPopover(
          open: _popoverOpen,
          onOpenChanged: (bool open) => setState(() => _popoverOpen = open),
          position: FluentPopoverPosition.below,
          semanticLabel: 'Choose color',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Color set 1', style: heading),
              FluentSwatchPicker(
                semanticLabel: 'SwatchPicker set 1',
                children: <Widget>[
                  for (final _Choice choice in _colorSet1) _swatch(choice),
                ],
              ),
              Text('Color set 2', style: heading),
              // Five columns is a width: five 28px swatches, four 4px gaps, and
              // the picker's own 10px padding on each side.
              SizedBox(
                width: 5 * 28 + 4 * 4 + 2 * 10,
                child: FluentSwatchPicker(
                  semanticLabel: 'SwatchPicker set 2',
                  layout: FluentSwatchPickerLayout.grid,
                  children: <Widget>[
                    for (final _Choice choice in _colorSet2) _swatch(choice),
                  ],
                ),
              ),
            ],
          ),
          child: FluentButton(
            onPressed: () => setState(() => _popoverOpen = true),
            child: const Text('Choose color'),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 100,
          height: 100,
          decoration: _selected.decoration.copyWith(
            border: Border.all(color: const Color(0xFFCCCCCC)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// #enddocregion components-swatchpicker--swatch-picker-popup
