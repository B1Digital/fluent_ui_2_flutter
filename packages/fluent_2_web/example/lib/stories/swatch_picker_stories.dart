import 'dart:convert';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentSwatchPicker].
final StorySection swatchPickerStories = StorySection(
  component: 'SwatchPicker',
  description:
      'A row or grid of selectable colour, image and "no colour" cells. The '
      'picker owns nothing but the layout: size and shape are pushed down onto '
      'every swatch inside it, while the chosen value stays a plain piece of '
      'the caller\'s state.',
  stories: [
    Story(
      name: 'Default',
      description:
          'A row of colour swatches with one selected. Every design axis of '
          'the picker is a knob here, because all four change the cells rather '
          'than the container.',
      knobs: const [
        OptionKnob<FluentSwatchPickerLayout>(
          label: 'Layout',
          id: 'layout',
          initial: FluentSwatchPickerLayout.row,
          options: FluentSwatchPickerLayout.values,
          labelOf: _layoutLabel,
        ),
        OptionKnob<FluentSwatchSize>(
          label: 'Size',
          id: 'size',
          initial: FluentSwatchSize.medium,
          options: FluentSwatchSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentSwatchShape>(
          label: 'Shape',
          id: 'shape',
          initial: FluentSwatchShape.square,
          options: FluentSwatchShape.values,
          labelOf: _shapeLabel,
        ),
        OptionKnob<FluentSwatchPickerSpacing>(
          label: 'Spacing',
          id: 'spacing',
          initial: FluentSwatchPickerSpacing.medium,
          options: FluentSwatchPickerSpacing.values,
          labelOf: _spacingLabel,
        ),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _ColorPicker(
          layout: knobs.get<FluentSwatchPickerLayout>(
            'layout',
            FluentSwatchPickerLayout.row,
          ),
          size: knobs.get<FluentSwatchSize>('size', FluentSwatchSize.medium),
          shape: knobs.get<FluentSwatchShape>(
            'shape',
            FluentSwatchShape.square,
          ),
          spacing: knobs.get<FluentSwatchPickerSpacing>(
            'spacing',
            FluentSwatchPickerSpacing.medium,
          ),
        );
      },
    ),
    const Story(
      name: 'Sizes',
      description:
          'Four footprints, 20 through 32. The size set on the picker wins '
          'over a size set on a swatch, so a row can never disagree with '
          'itself about how tall it is.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Shapes',
      description:
          'Square corners are the default; rounded takes the medium radius and '
          'circular turns each cell into a dot.',
      builder: _shapesBuilder,
    ),
    const Story(
      name: 'Layouts',
      description:
          'A row hugs its content on one line; a grid wraps at whatever width '
          'it is given, so the column count is the layout\'s business rather '
          'than the caller\'s.',
      builder: _layoutsBuilder,
    ),
    const Story(
      name: 'Spacing',
      description:
          'Two gaps between cells: medium (4) and small (2). Everything else '
          'about the two rows is identical.',
      builder: _spacingBuilder,
    ),
    const Story(
      name: 'Swatch kinds',
      description:
          'The four things a cell can be — a colour, a colour with a glyph '
          'over it, an image, and the "no colour" bar — plus the empty slot '
          'that stands for a choice not yet made.',
      builder: _kindsBuilder,
    ),
    const Story(
      name: 'Mixed palette',
      description:
          'One live picker combining "no colour", a palette, and an empty slot '
          'for a custom colour. Selection is a single index in the caller\'s '
          'state, so mixing kinds costs nothing.',
      builder: _mixedBuilder,
    ),
    const Story(
      name: 'Image swatches',
      description:
          'Image cells paint their picture cover-fit inside the same square, '
          'and carry the same selection ring as a colour.',
      builder: _imageBuilder,
    ),
    Story(
      name: 'Disabled',
      description:
          'Passing no callback disables a swatch: it stops reporting hover and '
          'press, refuses focus, and is struck through with a glyph you can '
          'replace.',
      knobs: const [BoolKnob(label: 'Disable the whole row', id: 'all')],
      builder: (context) =>
          _DisabledRow(all: KnobsScope.of(context).get<bool>('all', false)),
    ),
    const Story(
      name: 'With tooltip',
      description:
          'A swatch has no text, so the colour name usually lives in a tooltip '
          'on hover and on keyboard focus.',
      builder: _tooltipBuilder,
    ),
    const Story(
      name: 'In a popover',
      description:
          'The common shape for a colour control: a button carrying the '
          'current choice, and the grid tucked into a popover behind it.',
      builder: _popoverBuilder,
    ),
  ],
);

String _layoutLabel(FluentSwatchPickerLayout value) => switch (value) {
  FluentSwatchPickerLayout.row => 'row',
  FluentSwatchPickerLayout.grid => 'grid',
};

String _sizeLabel(FluentSwatchSize value) => switch (value) {
  FluentSwatchSize.extraSmall => 'extra small',
  FluentSwatchSize.small => 'small',
  FluentSwatchSize.medium => 'medium',
  FluentSwatchSize.large => 'large',
};

String _shapeLabel(FluentSwatchShape value) => switch (value) {
  FluentSwatchShape.square => 'square',
  FluentSwatchShape.rounded => 'rounded',
  FluentSwatchShape.circular => 'circular',
};

String _spacingLabel(FluentSwatchPickerSpacing value) => switch (value) {
  FluentSwatchPickerSpacing.medium => 'medium',
  FluentSwatchPickerSpacing.small => 'small',
};

/// The sample palette.
///
/// The one place in the gallery where a raw colour is correct rather than a
/// token: a swatch's fill *is* the arbitrary value on offer, so reading it from
/// the theme would be showing the reader the theme instead of the control.
const _palette = <(String, Color)>[
  ('Cranberry', Color(0xFFC50F1F)),
  ('Pumpkin', Color(0xFFCA5010)),
  ('Gold', Color(0xFFC19C00)),
  ('Forest', Color(0xFF498205)),
  ('Teal', Color(0xFF038387)),
  ('Cornflower', Color(0xFF4F6BED)),
  ('Orchid', Color(0xFF9373C0)),
  ('Berry', Color(0xFFC239B3)),
];

Widget _sizesBuilder(BuildContext context) => const _Cases(
  children: [
    ('Extra small', _ColorPicker(size: FluentSwatchSize.extraSmall, count: 5)),
    ('Small', _ColorPicker(size: FluentSwatchSize.small, count: 5)),
    ('Medium', _ColorPicker(count: 5)),
    ('Large', _ColorPicker(size: FluentSwatchSize.large, count: 5)),
  ],
);

Widget _shapesBuilder(BuildContext context) => const _Cases(
  children: [
    ('Square', _ColorPicker(count: 5)),
    ('Rounded', _ColorPicker(shape: FluentSwatchShape.rounded, count: 5)),
    ('Circular', _ColorPicker(shape: FluentSwatchShape.circular, count: 5)),
  ],
);

Widget _layoutsBuilder(BuildContext context) => const _Cases(
  children: [
    ('Row', _ColorPicker()),
    (
      'Grid, wrapping at 140',
      SizedBox(
        width: 140,
        child: _ColorPicker(layout: FluentSwatchPickerLayout.grid),
      ),
    ),
  ],
);

Widget _spacingBuilder(BuildContext context) => const _Cases(
  children: [
    ('Medium — 4', _ColorPicker()),
    ('Small — 2', _ColorPicker(spacing: FluentSwatchPickerSpacing.small)),
  ],
);

Widget _kindsBuilder(BuildContext context) => _Selectable(
  builder: (context, selected, select) => FluentSwatchPicker(
    semanticLabel: 'Swatch kinds',
    size: FluentSwatchSize.large,
    children: [
      FluentSwatch(
        color: _palette[4].$2,
        semanticLabel: 'Colour',
        selected: selected == 0,
        onPressed: () => select(0),
      ),
      FluentSwatch(
        color: _palette[5].$2,
        icon: const Icon(FluentIcons.checkmark_16_filled),
        semanticLabel: 'Colour with a glyph',
        selected: selected == 1,
        onPressed: () => select(1),
      ),
      FluentSwatch.image(
        image: _images.first.$2,
        semanticLabel: 'Image',
        selected: selected == 2,
        onPressed: () => select(2),
      ),
      FluentSwatch.transparent(
        semanticLabel: 'No colour',
        selected: selected == 3,
        onPressed: () => select(3),
      ),
      FluentSwatch.empty(
        semanticLabel: 'Not chosen yet',
        selected: selected == 4,
        onPressed: () => select(4),
      ),
    ],
  ),
);

Widget _mixedBuilder(BuildContext context) => const _MixedPalette();

Widget _imageBuilder(BuildContext context) => _Selectable(
  initial: 1,
  builder: (context, selected, select) => FluentSwatchPicker(
    semanticLabel: 'Background',
    size: FluentSwatchSize.large,
    shape: FluentSwatchShape.rounded,
    children: [
      for (var i = 0; i < _images.length; i++)
        FluentSwatch.image(
          image: _images[i].$2,
          semanticLabel: _images[i].$1,
          selected: selected == i,
          onPressed: () => select(i),
        ),
    ],
  ),
);

Widget _tooltipBuilder(BuildContext context) => _Selectable(
  initial: 2,
  builder: (context, selected, select) => FluentSwatchPicker(
    semanticLabel: 'Highlight colour',
    children: [
      for (var i = 0; i < _palette.length; i++)
        FluentTooltip(
          content: Text(_palette[i].$1),
          child: FluentSwatch(
            color: _palette[i].$2,
            semanticLabel: _palette[i].$1,
            selected: selected == i,
            onPressed: () => select(i),
          ),
        ),
    ],
  ),
);

Widget _popoverBuilder(BuildContext context) => const _PopoverPicker();

/// A picker over [_palette] that keeps its own selection, so every story here
/// shows a control that actually responds rather than a frozen one.
class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    this.layout = FluentSwatchPickerLayout.row,
    this.size = FluentSwatchSize.medium,
    this.shape = FluentSwatchShape.square,
    this.spacing = FluentSwatchPickerSpacing.medium,
    this.count = 8,
  });

  final FluentSwatchPickerLayout layout;
  final FluentSwatchSize size;
  final FluentSwatchShape shape;
  final FluentSwatchPickerSpacing spacing;

  /// How many of the palette's colours to show.
  final int count;

  @override
  Widget build(BuildContext context) => _Selectable(
    initial: 2,
    builder: (context, selected, select) => FluentSwatchPicker(
      semanticLabel: 'Highlight colour',
      layout: layout,
      size: size,
      shape: shape,
      spacing: spacing,
      children: [
        for (var i = 0; i < count; i++)
          FluentSwatch(
            color: _palette[i].$2,
            semanticLabel: _palette[i].$1,
            selected: selected == i,
            onPressed: () => select(i),
          ),
      ],
    ),
  );
}

/// One index of state, handed to a builder. Every story on this page needs the
/// same thing — a swatch is only honest if pressing it moves the ring.
class _Selectable extends StatefulWidget {
  const _Selectable({required this.builder, this.initial = 0});

  final Widget Function(
    BuildContext context,
    int selected,
    ValueChanged<int> select,
  )
  builder;

  final int initial;

  @override
  State<_Selectable> createState() => _SelectableState();
}

class _SelectableState extends State<_Selectable> {
  late int _selected = widget.initial;

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _selected,
    (value) => setState(() => _selected = value),
  );
}

/// "No colour", a palette and a custom slot in one grid, with the current
/// choice named underneath.
class _MixedPalette extends StatefulWidget {
  const _MixedPalette();

  @override
  State<_MixedPalette> createState() => _MixedPaletteState();
}

class _MixedPaletteState extends State<_MixedPalette> {
  /// -1 is "no colour", -2 the not-yet-chosen custom slot.
  int _selected = 0;

  String get _label => switch (_selected) {
    -1 => 'No colour',
    -2 => 'Custom — nothing picked yet',
    final i => _palette[i].$1,
  };

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.s,
      children: [
        SizedBox(
          width: 180,
          child: FluentSwatchPicker(
            semanticLabel: 'Fill',
            layout: FluentSwatchPickerLayout.grid,
            shape: FluentSwatchShape.rounded,
            children: [
              FluentSwatch.transparent(
                semanticLabel: 'No colour',
                selected: _selected == -1,
                onPressed: () => setState(() => _selected = -1),
              ),
              for (var i = 0; i < _palette.length; i++)
                FluentSwatch(
                  color: _palette[i].$2,
                  semanticLabel: _palette[i].$1,
                  selected: _selected == i,
                  onPressed: () => setState(() => _selected = i),
                ),
              FluentSwatch.empty(
                semanticLabel: 'Custom colour',
                selected: _selected == -2,
                onPressed: () => setState(() => _selected = -2),
              ),
            ],
          ),
        ),
        Text(
          'Selected: $_label',
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
      ],
    );
  }
}

/// Disabled swatches: the default prohibited mark, a replacement mark, and the
/// whole row switched off at once.
class _DisabledRow extends StatelessWidget {
  const _DisabledRow({required this.all});

  /// Whether every swatch in the row is disabled rather than only two.
  final bool all;

  @override
  Widget build(BuildContext context) => _Selectable(
    initial: 0,
    builder: (context, selected, select) => FluentSwatchPicker(
      semanticLabel: 'Highlight colour',
      size: FluentSwatchSize.large,
      children: [
        for (var i = 0; i < 6; i++)
          FluentSwatch(
            color: _palette[i].$2,
            semanticLabel: _palette[i].$1,
            selected: selected == i,
            // The fourth swatch replaces the default prohibited glyph.
            disabledIcon: i == 3
                ? const Icon(FluentIcons.dismiss_20_regular)
                : null,
            onPressed: all || i == 2 || i == 3 ? null : () => select(i),
          ),
      ],
    ),
  );
}

/// A button carrying the current choice, with the grid in a popover behind it.
class _PopoverPicker extends StatefulWidget {
  const _PopoverPicker();

  @override
  State<_PopoverPicker> createState() => _PopoverPickerState();
}

class _PopoverPickerState extends State<_PopoverPicker> {
  bool _open = false;
  int _selected = 4;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    position: FluentPopoverPosition.below,
    withArrow: true,
    semanticLabel: 'Highlight colour',
    onOpenChanged: (open) => setState(() => _open = open),
    content: SizedBox(
      width: 172,
      child: FluentSwatchPicker(
        semanticLabel: 'Highlight colour',
        layout: FluentSwatchPickerLayout.grid,
        shape: FluentSwatchShape.circular,
        children: [
          for (var i = 0; i < _palette.length; i++)
            FluentSwatch(
              color: _palette[i].$2,
              semanticLabel: _palette[i].$1,
              selected: _selected == i,
              onPressed: () => setState(() {
                _selected = i;
                _open = false;
              }),
            ),
        ],
      ),
    ),
    child: FluentButton(
      icon: const Icon(FluentIcons.edit_20_regular),
      onPressed: () => setState(() => _open = !_open),
      child: Text('Highlight: ${_palette[_selected].$1}'),
    ),
  );
}

/// Four 8x8 gradients, inlined so the gallery needs no asset bundle.
///
/// Raw colours again, and for the same reason as [_palette]: the picture a
/// swatch offers is the arbitrary value, not a themed surface.
final _images = <(String, MemoryImage)>[
  ('Sunset', _decode(_sunsetPng)),
  ('Meadow', _decode(_meadowPng)),
  ('Lagoon', _decode(_lagoonPng)),
  ('Dusk', _decode(_duskPng)),
];

MemoryImage _decode(String base64Png) => MemoryImage(base64Decode(base64Png));

const _sunsetPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAATklEQVR42mP4f6Tiz67yn+vL'
    'vi0t/Ty79MOEkrdtxa9qihiwir4oLGTAKvo0vYABq+ijmHwGrKL3g/IZsIre8chjwCp60zaX'
    'AavoNeMcAD/sdgGmKwBVAAAAAElFTkSuQmCC';

const _meadowPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAATklEQVR42mM49qJn14OOtddb'
    'Fp5vmHK8tmN/ZfW20vx1hQxYRZOX5TJgFQ2bm8mAVdRraioDVlHb3iQGrKKGrXEMWEVVaqIY'
    'sIpKlIQBAGe+Y4GNFMX2AAAAAElFTkSuQmCC';

const _lagoonPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAT0lEQVR42mOY9uhF7/XHrWfu'
    '1xy8VbztatbqC0kLzkROPc6AVTSg6xADVlGP+n0MWEXtS3YyYBU1y9zCgFVUN249A1ZR1eDV'
    'DFhFZTyWAQAWum1BKNOnIAAAAABJRU5ErkJggg==';

const _duskPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAT0lEQVR42mN4deT/vZ1fL697'
    'c3zxo93Tb6zvOb+k8eiMsj0MWEV7sjcxYBVtTFjBgFW0NHQ+A1bRTM+pDFhFY+26GbCKBhk3'
    'MWAVddOoAABTw3JltCQuUAAAAABJRU5ErkJggg==';

/// Side-by-side cases under a caption, the layout most of these stories want.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: FluentSpacing.xxl,
    runSpacing: FluentSpacing.l,
    crossAxisAlignment: WrapCrossAlignment.start,
    children: [
      for (final (caption, child) in children)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: FluentSpacing.xs,
          children: [
            FluentLabel(size: FluentLabelSize.small, child: Text(caption)),
            child,
          ],
        ),
    ],
  );
}
