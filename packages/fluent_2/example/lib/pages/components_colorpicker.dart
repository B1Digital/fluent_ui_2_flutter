import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The ColorPicker docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Every demo is pinned to 300 logical pixels wide, which is upstream's own
/// `.example { width: 300px }`.
const DocsPage colorPickerPage = DocsPage(
  id: 'components-colorpicker',
  title: 'ColorPicker',
  description:
      'The ColorPicker allows users to browse and select colors. By default, '
      'it enables navigation through a color spectrum and operates in HSV/HSL '
      'format. However, it is also possible to specify a color using '
      'Red-Green-Blue (RGB), an alpha color code, or hexadecimal values in the '
      'text boxes.',
  source: 'lib/pages/components_colorpicker.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-colorpicker--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-colorpicker--color-picker-shape',
      title: 'Color Picker Shape',
      description:
          'The shape prop sets border-radius of the ColorPicker '
          'sub-components. The default is rounded.',
      builder: _shape,
    ),
    DocsSection(
      id: 'components-colorpicker--color-area-default',
      title: 'Color Area Default',
      description:
          'The ColorArea component allows users to adjust two channels of HSB '
          'color values against a two-dimensional gradient background.',
      builder: _colorArea,
    ),
    DocsSection(
      id: 'components-colorpicker--color-slider-default',
      title: 'Color Slider Default',
      description:
          'The ColorSlider allows users to change the hue aspect of a color '
          'value.',
      builder: _colorSlider,
    ),
    DocsSection(
      id: 'components-colorpicker--color-slider-channels',
      title: 'Color Slider Channels',
      description:
          'The ColorSlider allows users to choose color channels like hue, '
          'saturation, and value.',
      builder: _channels,
    ),
    DocsSection(
      id: 'components-colorpicker--alpha-slider-default',
      title: 'Alpha Slider Default',
      description:
          'The AlphaSlider allows users to change the alpha channel of a color '
          'value.',
      builder: _alphaSlider,
    ),
    DocsSection(
      id: 'components-colorpicker--color-and-swatch-picker',
      title: 'Color And Swatch Picker',
      builder: _colorAndSwatchPicker,
    ),
    DocsSection(
      id: 'components-colorpicker--color-picker-popup',
      title: 'Color Picker Popup',
      builder: _popup,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'color',
      type: 'HSVColor',
      description: 'The colour every control inside shows.',
    ),
    PropRow(
      name: 'children',
      type: 'List<Widget>',
      description: 'The controls. Upstream\'s order is area, hue, alpha.',
    ),
    PropRow(
      name: 'onColorChanged',
      type: 'ValueChanged<HSVColor>?',
      defaultValue: 'null',
      description:
          'Called with the colour a gesture or a key landed on. Null disables '
          'every control inside.',
    ),
    PropRow(
      name: 'shape',
      type: 'FluentColorPickerShape',
      defaultValue: 'FluentColorPickerShape.rounded',
      description: 'The corner treatment every control inside takes.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Announced by assistive technology as the group\'s name.',
    ),
  ],
);

/// Upstream's `DEFAULT_COLOR_HSV`, shared by five of the eight stories.
const HSVColor _defaultColor = HSVColor.fromAHSV(1, 109, 1, 0.9);

/// Upstream's `.example` block: a 300-wide column with a 10px gap.
class _Example extends StatelessWidget {
  const _Example({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: children,
    ),
  );
}

/// Upstream's `.previewColor` box: a 50 square with a 4 radius and a hairline.
class _Preview extends StatelessWidget {
  const _Preview(this.color);

  final HSVColor color;

  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: color.toColor(),
      borderRadius: FluentRadius.allMedium,
      border: Border.all(color: FluentTheme.of(context).colors.neutralStroke1),
    ),
  );
}

// #docregion components-colorpicker--default
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  HSVColor _color = _defaultColor;

  /// Upstream keeps hex and RGB in their own state so a half-typed value can
  /// sit in the field without snapping the picker. `FluentInput` is controlled
  /// the same way.
  late final TextEditingController _hex = TextEditingController(
    text: _hexOf(_color),
  );

  static String _hexOf(HSVColor color) =>
      '#${(color.toColor().toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  void _setColor(HSVColor next) {
    setState(() => _color = next);
    _hex.text = _hexOf(next);
  }

  /// Upstream's `HEX_COLOR_REGEX`, and `tinycolor(...).isValid`.
  void _setHex(String text) {
    final match = RegExp(r'^#?([0-9A-Fa-f]{6})$').firstMatch(text.trim());
    if (match == null) return;
    final rgb = int.parse(match.group(1)!, radix: 16);
    final next = HSVColor.fromColor(Color(0xFF000000 | rgb));
    setState(
      () => _color = HSVColor.fromAHSV(
        _color.alpha,
        next.hue,
        next.saturation,
        next.value,
      ),
    );
  }

  void _setChannel(String name, double value) {
    final rgb = _color.toColor();
    final next = Color.fromARGB(
      255,
      name == 'r' ? value.round() : (rgb.r * 255).round(),
      name == 'g' ? value.round() : (rgb.g * 255).round(),
      name == 'b' ? value.round() : (rgb.b * 255).round(),
    );
    _setColor(HSVColor.fromColor(next).withAlpha(_color.alpha));
  }

  Widget _channel(String label, String name, double value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 6,
    children: <Widget>[
      FluentLabel(child: Text(label)),
      SizedBox(
        width: 60,
        child: FluentSpinButton(
          value: value,
          min: 0,
          max: 255,
          precision: 0,
          semanticLabel: label,
          // FluentSpinButton reports null when the field is emptied.
          onChanged: (double? next) =>
              next == null ? null : _setChannel(name, next),
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rgb = _color.toColor();
    return _Example(
      children: <Widget>[
        FluentColorPicker(
          color: _color,
          onColorChanged: _setColor,
          children: const <Widget>[
            FluentColorArea(
              saturationLabel: 'Saturation',
              brightnessLabel: 'Brightness',
            ),
            FluentColorSlider(semanticLabel: 'Hue'),
            FluentAlphaSlider(semanticLabel: 'Alpha'),
          ],
        ),
        _Preview(_color),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 10,
          children: <Widget>[
            // Flexible, because the four fields want 96 + 60 + 60 + 60 and the
            // three gaps want 30 — six pixels more than the 300 upstream's
            // `.example` gives them. CSS resolves that by shrinking the flex
            // items, and `min-width: 60px` on the spin buttons means the hex
            // input is the one that gives way. This is that rule: it absorbs
            // whatever the row is short by, however wide the labels render.
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: <Widget>[
                  const FluentLabel(child: Text('Hex')),
                  SizedBox(
                    width: 96,
                    child: FluentInput(
                      controller: _hex,
                      semanticLabel: 'Hex',
                      onChanged: _setHex,
                    ),
                  ),
                ],
              ),
            ),
            _channel('Red', 'r', (rgb.r * 255).roundToDouble()),
            _channel('Green', 'g', (rgb.g * 255).roundToDouble()),
            _channel('Blue', 'b', (rgb.b * 255).roundToDouble()),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: <Widget>[
            const FluentLabel(child: Text('Alpha')),
            SizedBox(
              width: 96,
              child: FluentSpinButton(
                value: _color.alpha,
                min: 0,
                max: 1,
                step: 0.1,
                precision: 2,
                semanticLabel: 'Alpha',
                onChanged: (double? next) =>
                    next == null ? null : _setColor(_color.withAlpha(next)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
// #enddocregion components-colorpicker--default

// #docregion components-colorpicker--color-picker-shape
Widget _shape(BuildContext context) => const _Shape();

class _Shape extends StatefulWidget {
  const _Shape();

  @override
  State<_Shape> createState() => _ShapeState();
}

class _ShapeState extends State<_Shape> {
  HSVColor _rounded = _defaultColor;
  HSVColor _square = _defaultColor;

  Widget _picker(
    String heading,
    HSVColor color,
    FluentColorPickerShape shape,
    ValueChanged<HSVColor> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      FluentLabel(weight: FluentLabelWeight.semibold, child: Text(heading)),
      FluentColorPicker(
        color: color,
        shape: shape,
        onColorChanged: onChanged,
        children: const <Widget>[
          FluentColorArea(
            saturationLabel: 'Saturation',
            brightnessLabel: 'Brightness',
          ),
          FluentColorSlider(semanticLabel: 'Hue'),
          FluentAlphaSlider(semanticLabel: 'Alpha'),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => _Example(
    children: <Widget>[
      _picker(
        'Rounded (default)',
        _rounded,
        FluentColorPickerShape.rounded,
        (HSVColor next) => setState(() => _rounded = next),
      ),
      _picker(
        'Square (default)',
        _square,
        FluentColorPickerShape.square,
        (HSVColor next) => setState(() => _square = next),
      ),
    ],
  );
}
// #enddocregion components-colorpicker--color-picker-shape

// #docregion components-colorpicker--color-area-default
Widget _colorArea(BuildContext context) => const _ColorArea();

class _ColorArea extends StatefulWidget {
  const _ColorArea();

  @override
  State<_ColorArea> createState() => _ColorAreaState();
}

class _ColorAreaState extends State<_ColorArea> {
  static const HSVColor _initial = HSVColor.fromAHSV(1, 324, 0.5, 0.5);

  HSVColor _color = _initial;

  @override
  Widget build(BuildContext context) => _Example(
    children: <Widget>[
      FluentColorArea(
        color: _color,
        onChanged: (HSVColor next) => setState(() => _color = next),
        saturationLabel: 'Saturation',
        brightnessLabel: 'Brightness',
        // Upstream announces both channels from either axis, which is why the
        // formatter is handed the whole colour rather than one axis's number.
        semanticFormatter: (HSVColor color, Axis axis) =>
            'Saturation ${(color.saturation * 100).round()}, '
            'Brightness: ${(color.value * 100).round()}',
      ),
      _Preview(_color),
      FluentButton(
        onPressed: () => setState(() => _color = _initial),
        child: const Text('Reset'),
      ),
    ],
  );
}
// #enddocregion components-colorpicker--color-area-default

// #docregion components-colorpicker--color-slider-default
Widget _colorSlider(BuildContext context) => const _ColorSlider();

class _ColorSlider extends StatefulWidget {
  const _ColorSlider();

  @override
  State<_ColorSlider> createState() => _ColorSliderState();
}

class _ColorSliderState extends State<_ColorSlider> {
  HSVColor _color = _defaultColor;

  @override
  Widget build(BuildContext context) => _Example(
    children: <Widget>[
      FluentColorSlider(
        color: _color,
        onChanged: (HSVColor next) => setState(() => _color = next),
        semanticLabel: 'Hue',
        semanticFormatter: (double value) => '${value.round()}°',
      ),
      SizedBox(
        height: 280,
        child: FluentColorSlider(
          color: _color,
          vertical: true,
          onChanged: (HSVColor next) => setState(() => _color = next),
          semanticLabel: 'Vertical Hue',
          semanticFormatter: (double value) => '${value.round()}°',
        ),
      ),
      _Preview(_color),
      FluentButton(
        onPressed: () => setState(() => _color = _defaultColor),
        child: const Text('Reset'),
      ),
    ],
  );
}
// #enddocregion components-colorpicker--color-slider-default

// #docregion components-colorpicker--color-slider-channels
Widget _channels(BuildContext context) => const _Channels();

class _Channels extends StatefulWidget {
  const _Channels();

  @override
  State<_Channels> createState() => _ChannelsState();
}

class _ChannelsState extends State<_Channels> {
  /// Upstream's `tinycolor('#2be700').toHsv()`.
  static final HSVColor _initial = HSVColor.fromColor(const Color(0xFF2BE700));

  late HSVColor _color = _initial;

  Widget _rail(String heading, FluentColorChannel channel) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      FluentLabel(weight: FluentLabelWeight.semibold, child: Text(heading)),
      FluentColorSlider(
        color: _color,
        channel: channel,
        onChanged: (HSVColor next) => setState(() => _color = next),
        semanticLabel: heading,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => _Example(
    children: <Widget>[
      _rail('Hue', FluentColorChannel.hue),
      _rail('Saturation', FluentColorChannel.saturation),
      _rail('Value (Brightness)', FluentColorChannel.value),
      _Preview(_color),
      FluentButton(
        onPressed: () => setState(() => _color = _initial),
        child: const Text('Reset'),
      ),
    ],
  );
}
// #enddocregion components-colorpicker--color-slider-channels

// #docregion components-colorpicker--alpha-slider-default
Widget _alphaSlider(BuildContext context) => const _AlphaSlider();

class _AlphaSlider extends StatefulWidget {
  const _AlphaSlider();

  @override
  State<_AlphaSlider> createState() => _AlphaSliderState();
}

class _AlphaSliderState extends State<_AlphaSlider> {
  static const HSVColor _initial = HSVColor.fromAHSV(1, 96, 1, 0.9);

  HSVColor _color = _initial;
  HSVColor _transparent = _initial;

  @override
  Widget build(BuildContext context) => _Example(
    children: <Widget>[
      FluentAlphaSlider(
        color: _color,
        onChanged: (HSVColor next) => setState(() => _color = next),
        semanticLabel: 'Alpha',
        semanticFormatter: (double value) => '${value.round()}%',
      ),
      SizedBox(
        height: 280,
        child: FluentAlphaSlider(
          color: _color,
          vertical: true,
          onChanged: (HSVColor next) => setState(() => _color = next),
          semanticLabel: 'Vertical alpha',
          semanticFormatter: (double value) => '${value.round()}%',
        ),
      ),
      _Preview(_color),
      FluentButton(
        onPressed: () => setState(() => _color = _initial),
        child: const Text('Reset'),
      ),
      const FluentLabel(
        size: FluentLabelSize.large,
        weight: FluentLabelWeight.semibold,
        child: Text('Transparency'),
      ),
      FluentAlphaSlider(
        color: _transparent,
        transparency: true,
        onChanged: (HSVColor next) => setState(() => _transparent = next),
        semanticLabel: 'Alpha',
        semanticFormatter: (double value) => '${value.round()}%',
      ),
      SizedBox(
        height: 280,
        child: FluentAlphaSlider(
          color: _transparent,
          transparency: true,
          vertical: true,
          onChanged: (HSVColor next) => setState(() => _transparent = next),
          semanticLabel: 'Vertical alpha',
          semanticFormatter: (double value) => '${value.round()}%',
        ),
      ),
      _Preview(_transparent),
      FluentButton(
        onPressed: () => setState(() => _transparent = _initial),
        child: const Text('Reset'),
      ),
    ],
  );
}
// #enddocregion components-colorpicker--alpha-slider-default

// #docregion components-colorpicker--color-and-swatch-picker
Widget _colorAndSwatchPicker(BuildContext context) =>
    const _ColorAndSwatchPicker();

class _ColorAndSwatchPicker extends StatefulWidget {
  const _ColorAndSwatchPicker();

  @override
  State<_ColorAndSwatchPicker> createState() => _ColorAndSwatchPickerState();
}

class _ColorAndSwatchPickerState extends State<_ColorAndSwatchPicker> {
  static const int _itemsLimit = 8;
  static const Color _defaultSelected = Color(0xFF2BE700);

  HSVColor _color = _defaultColor;
  List<Color> _items = const <Color>[];
  Color _selected = _defaultSelected;

  void _addColor() => setState(() {
    final Color added = _color.toColor();
    _items = <Color>[..._items, added];
  });

  void _reset() => setState(() {
    _items = const <Color>[];
    _selected = _defaultSelected;
    _color = _defaultColor;
  });

  @override
  Widget build(BuildContext context) => _Example(
    children: <Widget>[
      FluentColorPicker(
        color: _color,
        onColorChanged: (HSVColor next) => setState(() => _color = next),
        children: <Widget>[
          const FluentColorArea(
            saturationLabel: 'Saturation',
            brightnessLabel: 'Brightness',
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: <Widget>[
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FluentColorSlider(semanticLabel: 'Hue'),
                    FluentAlphaSlider(semanticLabel: 'Alpha'),
                  ],
                ),
              ),
              _Preview(_color),
            ],
          ),
        ],
      ),
      FluentSwatchPicker(
        semanticLabel: 'SwatchPicker with empty swatches',
        shape: FluentSwatchShape.rounded,
        children: <Widget>[
          for (final Color item in _items)
            FluentSwatch(
              color: item,
              semanticLabel:
                  'rgb(${(item.r * 255).round()}, '
                  '${(item.g * 255).round()}, ${(item.b * 255).round()})',
              shape: FluentSwatchShape.rounded,
              selected: item == _selected,
              onPressed: () => setState(() => _selected = item),
            ),
          for (int i = _items.length; i < _itemsLimit; i += 1)
            const FluentSwatch.empty(
              semanticLabel: 'empty swatch',
              shape: FluentSwatchShape.rounded,
              // A disabled FluentSwatch is otherwise struck through with a
              // prohibited glyph that upstream's dashed empty slots do not
              // draw.
              disabledIcon: SizedBox.shrink(),
            ),
        ],
      ),
      const FluentLabel(child: Text('Selected color')),
      Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _selected,
          borderRadius: FluentRadius.allMedium,
          border: Border.all(
            color: FluentTheme.of(context).colors.neutralStroke1,
          ),
        ),
      ),
      // Stacked, not side by side: upstream's two Buttons are direct children
      // of `.example`, which is `flex-direction: column`, so its
      // `.button { margin-right: spacingHorizontalS }` never applies. Side by
      // side they also cannot fit 300 once the labels are wide.
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: _items.length >= _itemsLimit ? null : _addColor,
        child: const Text('Add new color'),
      ),
      FluentButton(onPressed: _reset, child: const Text('Reset example')),
    ],
  );
}
// #enddocregion components-colorpicker--color-and-swatch-picker

// #docregion components-colorpicker--color-picker-popup
Widget _popup(BuildContext context) => const _Popup();

class _Popup extends StatefulWidget {
  const _Popup();

  @override
  State<_Popup> createState() => _PopupState();
}

class _PopupState extends State<_Popup> {
  HSVColor _preview = _defaultColor;
  HSVColor _color = _defaultColor;
  bool _open = false;

  @override
  Widget build(BuildContext context) => _Example(
    children: <Widget>[
      FluentPopover(
        open: _open,
        // Below the trigger and flush with its leading edge, which is where
        // upstream's floating-ui would put it: a whole colour picker is ~380
        // tall and 300 wide, so FluentPopover's default `above` + `center`
        // hangs it off the top of the page and off the left of a narrow
        // trigger.
        position: FluentPopoverPosition.below,
        align: FluentPopoverAlign.start,
        onOpenChanged: (bool open) => setState(() => _open = open),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: <Widget>[
            FluentColorPicker(
              color: _preview,
              onColorChanged: (HSVColor next) =>
                  setState(() => _preview = next),
              children: <Widget>[
                const FluentColorArea(
                  saturationLabel: 'Saturation',
                  brightnessLabel: 'Brightness',
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: <Widget>[
                    const Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          FluentColorSlider(semanticLabel: 'Hue'),
                          FluentAlphaSlider(semanticLabel: 'Alpha'),
                        ],
                      ),
                    ),
                    _Preview(_preview),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: <Widget>[
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  onPressed: () => setState(() {
                    _color = _preview;
                    _open = false;
                  }),
                  child: const Text('Ok'),
                ),
                FluentButton(
                  onPressed: () => setState(() => _open = false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
        child: FluentButton(
          onPressed: () => setState(() => _open = true),
          child: const Text('Choose color'),
        ),
      ),
      _Preview(_color),
    ],
  );
}

// #enddocregion components-colorpicker--color-picker-popup
