import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentAcrylicSurface].
///
/// Acrylic has no upstream React counterpart, so the axes demonstrated here are
/// the ones the Figma `Material acrylic` set declares: two stacked tints, a
/// backdrop blur radius, a three-stop gradient hairline, the remote
/// `material-radius` shape variable and the `Spacing/Horizontal/L` inset.
final StorySection acrylicSurfaceStories = StorySection(
  component: 'Acrylic surface',
  description:
      'The Fluent 2 Acrylic material: a blurred backdrop under two translucent '
      'tints, edged with a gradient hairline. It is a material, not a control — '
      'no hover, no focus, no transition — so every story puts it over a busy '
      'backdrop, because a surface with nothing behind it has nothing to blur.',
  stories: [
    Story(
      name: 'Default',
      description:
          'The material as the theme resolves it, live: the blur radius, the '
          '`material-radius` shape and the hairline width are the three numbers '
          'a caller usually reaches for.',
      knobs: const [
        NumberKnob(
          label: 'Blur radius',
          id: 'blur',
          initial: 60,
          max: 120,
          step: 4,
        ),
        OptionKnob<_MaterialShape>(
          label: 'Corner radius',
          id: 'shape',
          initial: _MaterialShape.none,
          options: _MaterialShape.values,
          labelOf: _shapeLabel,
        ),
        NumberKnob(
          label: 'Hairline width',
          id: 'stroke',
          initial: FluentStroke.thin,
          max: 4,
        ),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Material shape',
      description:
          'The six modes of the remote `material-radius` variable. The shipped '
          'Figma file resolves it to None, so a square surface is the default '
          'and every other stop is an explicit override.',
      builder: _shapeBuilder,
    ),
    const Story(
      name: 'Backdrop blur',
      description:
          'The blur is a RADIUS, as Figma and CSS state it — the renderer halves '
          'it into a Gaussian sigma. Zero is special: the backdrop filter is '
          'dropped entirely rather than set to nothing, because a zero-sigma '
          'blur still forces a saveLayer.',
      builder: _blurBuilder,
    ),
    const Story(
      name: 'The two tints',
      description:
          'Secondary is painted on the blurred backdrop and Primary on top of '
          'it. Translucent paints do not commute, so the order is the spec: '
          'swapping them is a different colour, not the same one.',
      builder: _tintsBuilder,
    ),
    const Story(
      name: 'The hairline',
      description:
          'A three-stop linear gradient stroked inside the corner radius, not a '
          'flat border. The last case recolours the stops so the gradient is '
          'visible; a width of zero paints no edge at all.',
      builder: _hairlineBuilder,
    ),
    const Story(
      name: 'Content padding',
      description:
          'The inset between the hairline and the content, `Spacing/Horizontal/'
          'L` by default on all four sides.',
      builder: _paddingBuilder,
    ),
    const Story(
      name: 'Not a control',
      description:
          'A material has no interaction states and absorbs no pointers: the '
          'button on the surface works, and a tap on the bare surface reaches '
          'the content behind it.',
      builder: _passThroughBuilder,
    ),
    const Story(
      name: 'Light, dark and high contrast',
      description:
          'Dark flips every acrylic token — Stop 2 goes fully opaque while its '
          'siblings stay translucent. High contrast refuses translucency '
          'outright: an opaque neutral surface, a neutral hairline, no blur.',
      builder: _themesBuilder,
    ),
    const Story(
      name: 'Custom styling',
      description:
          'Three rungs of override: the theme defaults, a '
          '`FluentAcrylicSurfaceTheme` over a subtree, then the widget style, '
          'which is merged last and wins. Merging is per-property, so an '
          'override of one value keeps every other resolved token.',
      builder: _stylingBuilder,
    ),
    const Story(
      name: 'Recomposed',
      description:
          'The resolver and the renderer are public and separable: reuse '
          'Fluent\'s blur arithmetic and gradient hairline with your own token '
          'selection, or keep the tokens and render them yourself.',
      builder: _recomposedBuilder,
    ),
    const Story(
      name: 'On a page',
      description:
          'What the material is for — a reading panel floating over content it '
          'must not hide completely.',
      builder: _compositionBuilder,
    ),
  ],
);

/// The stops of the remote `material-radius` variable from Figma's
/// `MaterialShape` collection, in the order Figma lists its modes.
enum _MaterialShape {
  none('None', BorderRadius.zero),
  small('Small', FluentRadius.allSmall),
  medium('Medium', FluentRadius.allMedium),
  large('Large', FluentRadius.allLarge),
  xLarge('X-Large', FluentRadius.allXLarge),
  circular('Circular', FluentRadius.allCircular);

  const _MaterialShape(this.label, this.radius);

  final String label;
  final BorderRadius radius;
}

String _shapeLabel(_MaterialShape value) => value.label;

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  return _Backdrop(
    height: 200,
    child: FluentAcrylicSurface(
      style: FluentAcrylicSurfaceStyle.from(
        backgroundBlur: knobs.get<double>('blur', 60),
        borderRadius: knobs
            .get<_MaterialShape>('shape', _MaterialShape.none)
            .radius,
        strokeWidth: knobs.get<double>('stroke', FluentStroke.thin),
      ),
      child: const _Panel(),
    ),
  );
}

Widget _shapeBuilder(BuildContext context) => _Samples(
  children: [
    for (final shape in _MaterialShape.values)
      (
        shape.label,
        FluentAcrylicSurface(
          style: FluentAcrylicSurfaceStyle.from(borderRadius: shape.radius),
          child: const _Tile(),
        ),
      ),
  ],
);

Widget _blurBuilder(BuildContext context) => _Samples(
  children: [
    (
      '0 — the backdrop filter is dropped',
      const FluentAcrylicSurface(style: _noBlur, child: _Tile()),
    ),
    for (final radius in const <double>[12, 30, 60, 120])
      (
        radius == 60 ? '60 — the token' : '$radius',
        FluentAcrylicSurface(
          style: FluentAcrylicSurfaceStyle.from(backgroundBlur: radius),
          child: const _Tile(),
        ),
      ),
  ],
);

/// Reused by several stories that need the tints readable rather than blurred.
const FluentAcrylicSurfaceStyle _noBlur = FluentAcrylicSurfaceStyle(
  backgroundBlur: WidgetStatePropertyAll<double?>(0),
);

Widget _tintsBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  final acrylic = colors.acrylic;
  return _Samples(
    children: [
      (
        'both, Secondary under Primary',
        const FluentAcrylicSurface(child: _Tile()),
      ),
      (
        'Secondary only',
        FluentAcrylicSurface(
          style: FluentAcrylicSurfaceStyle.from(
            backgroundPrimary: colors.transparentBackground,
          ),
          child: const _Tile(),
        ),
      ),
      (
        'Primary only',
        FluentAcrylicSurface(
          style: FluentAcrylicSurfaceStyle.from(
            backgroundSecondary: colors.transparentBackground,
          ),
          child: const _Tile(),
        ),
      ),
      (
        'swapped — a different colour',
        FluentAcrylicSurface(
          style: FluentAcrylicSurfaceStyle.from(
            backgroundSecondary: acrylic.backgroundPrimary,
            backgroundPrimary: acrylic.backgroundSecondary,
          ),
          child: const _Tile(),
        ),
      ),
    ],
  );
}

Widget _hairlineBuilder(BuildContext context) {
  final palette = FluentTheme.of(context).colors.palette;
  return _Samples(
    children: [
      (
        'none — no edge at all',
        FluentAcrylicSurface(
          style: FluentAcrylicSurfaceStyle.from(strokeWidth: FluentStroke.none),
          child: const _Tile(),
        ),
      ),
      ('thin — the token', const FluentAcrylicSurface(child: _Tile())),
      (
        'thick',
        FluentAcrylicSurface(
          style: FluentAcrylicSurfaceStyle.from(
            strokeWidth: FluentStroke.thick,
          ),
          child: const _Tile(),
        ),
      ),
      (
        'recoloured stops, so the gradient shows',
        FluentAcrylicSurface(
          style: FluentAcrylicSurfaceStyle.from(
            strokeWidth: FluentStroke.thickest,
            strokeStop1: palette.background2Rest(FluentPaletteFamily.cranberry),
            strokeStop2: palette.background2Rest(FluentPaletteFamily.marigold),
            strokeStop3: palette.background2Rest(FluentPaletteFamily.forest),
          ),
          child: const _Tile(),
        ),
      ),
    ],
  );
}

Widget _paddingBuilder(BuildContext context) => _Samples(
  children: [
    (
      'none',
      FluentAcrylicSurface(
        style: FluentAcrylicSurfaceStyle.from(padding: EdgeInsets.zero),
        child: const _Tile(),
      ),
    ),
    (
      'L — the token, 16 on every side',
      const FluentAcrylicSurface(child: _Tile()),
    ),
    (
      'XXL',
      FluentAcrylicSurface(
        style: FluentAcrylicSurfaceStyle.from(
          padding: const EdgeInsets.all(FluentSpacing.xxl),
        ),
        child: const _Tile(),
      ),
    ),
  ],
);

Widget _passThroughBuilder(BuildContext context) => const _PassThrough();

Widget _themesBuilder(BuildContext context) => Wrap(
  spacing: FluentSpacing.l,
  runSpacing: FluentSpacing.l,
  children: [
    for (final (caption, data) in <(String, FluentThemeData)>[
      ('light', FluentThemeData.light(fontPlatform: FluentFontPlatform.web)),
      ('dark', FluentThemeData.dark(fontPlatform: FluentFontPlatform.web)),
      (
        'high contrast',
        FluentThemeData.highContrast(fontPlatform: FluentFontPlatform.web),
      ),
    ])
      FluentTheme(
        data: data,
        child: _Sample(
          caption: caption,
          surface: const FluentAcrylicSurface(child: _Tile()),
        ),
      ),
  ],
);

Widget _stylingBuilder(BuildContext context) {
  final palette = FluentTheme.of(context).colors.palette;
  return FluentAcrylicSurfaceTheme(
    style: FluentAcrylicSurfaceStyle.from(
      borderRadius: FluentRadius.allXLarge,
      padding: const EdgeInsets.all(FluentSpacing.xxl),
    ),
    child: _Samples(
      children: [
        ('theme defaults, outside the subtree', _outsideTheSubtree),
        (
          'subtree theme — rounded and roomier',
          const FluentAcrylicSurface(child: _Tile()),
        ),
        (
          'widget style wins',
          FluentAcrylicSurface(
            style: FluentAcrylicSurfaceStyle.from(
              borderRadius: FluentRadius.allCircular,
              strokeWidth: FluentStroke.thick,
              strokeStop1: palette.background2Rest(FluentPaletteFamily.grape),
              strokeStop2: palette.background2Rest(FluentPaletteFamily.grape),
              strokeStop3: palette.background2Rest(FluentPaletteFamily.grape),
            ),
            child: const _Tile(),
          ),
        ),
        (
          'one property overridden — every other token survives',
          FluentAcrylicSurface(
            style: FluentAcrylicSurfaceStyle.from(backgroundBlur: 0),
            child: const _Tile(),
          ),
        ),
      ],
    ),
  );
}

/// Sits outside the [FluentAcrylicSurfaceTheme] so the unthemed default is
/// visible beside the overridden ones.
const Widget _outsideTheSubtree = FluentAcrylicSurface(child: _Tile());

Widget _recomposedBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  final palette = theme.colors.palette;
  // The resolver's output, adjusted — every colour still comes from the theme.
  final adjusted = resolveFluentAcrylicSurfaceStyle(theme).merge(
    FluentAcrylicSurfaceStyle.from(
      borderRadius: FluentRadius.allXLarge,
      backgroundBlur: 20,
    ),
  );
  // A style assembled from scratch: Fluent's rendering, someone else's tokens.
  final foreign = FluentAcrylicSurfaceStyle.from(
    backgroundSecondary: palette.background2Rest(FluentPaletteFamily.teal),
    backgroundPrimary: theme.colors.transparentBackground,
    backgroundBlur: 40,
    strokeStop1: theme.colors.neutralStroke1,
    strokeStop2: theme.colors.brandStroke1,
    strokeStop3: theme.colors.neutralStroke1,
    strokeWidth: FluentStroke.thick,
    borderRadius: FluentRadius.allXLarge,
    padding: const EdgeInsets.all(FluentSpacing.l),
  );

  return _Samples(
    children: [
      (
        'resolveFluentAcrylicSurfaceStyle, then merged',
        buildFluentAcrylicSurface(
          adjusted,
          const <WidgetState>{},
          child: const _Tile(),
        ),
      ),
      (
        'buildFluentAcrylicSurface with foreign tokens',
        buildFluentAcrylicSurface(
          foreign,
          const <WidgetState>{},
          child: const _Tile(),
        ),
      ),
    ],
  );
}

Widget _compositionBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return _Backdrop(
    height: 280,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: FluentAcrylicSurface(
        style: FluentAcrylicSurfaceStyle.from(
          borderRadius: FluentRadius.allXLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.s,
          children: [
            Text('Northern lights', style: theme.typography.subtitle2),
            Text(
              'The surface keeps the photograph legible as texture while the '
              'text stays readable over it.',
              style: theme.typography.body1.copyWith(
                color: theme.colors.neutralForeground2,
              ),
            ),
            const SizedBox(height: FluentSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: FluentSpacing.s,
              children: [
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  icon: const Icon(FluentIcons.play_20_regular),
                  onPressed: () {},
                  child: const Text('Play'),
                ),
                FluentButton(
                  appearance: FluentButtonAppearance.subtle,
                  onPressed: () {},
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Three tap targets that separate what the material does from what its content
/// does: the button on the surface, the bare surface itself, and the scene
/// around it.
class _PassThrough extends StatefulWidget {
  const _PassThrough();

  @override
  State<_PassThrough> createState() => _PassThroughState();
}

class _PassThroughState extends State<_PassThrough> {
  int _onSurface = 0;
  int _backdrop = 0;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.m,
      children: [
        _Backdrop(
          height: 220,
          // Fills the scene under the surface, so it catches every tap the
          // acrylic does not — and none of the ones it does.
          behind: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _backdrop++),
          ),
          child: FluentAcrylicSurface(
            style: FluentAcrylicSurfaceStyle.from(
              borderRadius: FluentRadius.allXLarge,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: FluentSpacing.s,
              children: [
                Text(
                  'Tap the button, the bare surface, then the scene',
                  style: theme.typography.caption1,
                ),
                FluentButton(
                  onPressed: () => setState(() => _onSurface++),
                  child: const Text('On the surface'),
                ),
              ],
            ),
          ),
        ),
        Text(
          'Button: $_onSurface — scene around it: $_backdrop',
          style: theme.typography.body1Strong,
        ),
        Text(
          'A tap on bare acrylic moves neither count: the material has no '
          'pressed, hover or focus state to enter, and its tint fills are '
          'opaque to hit testing, so it is not a click-through overlay.',
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
      ],
    );
  }
}

/// A deliberately busy scene for the surface to blur.
///
/// Blobs are drawn from `FluentPaletteColors`, the persona/accent token layer,
/// purely so the backdrop has high-frequency colour to lose under the blur.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child, this.height = 160, this.behind});

  final Widget child;
  final double height;

  /// Painted over the blobs but under the acrylic surface.
  final Widget? behind;

  static const _blobs = <(FluentPaletteFamily, double, double, double)>[
    (FluentPaletteFamily.marigold, -0.9, -0.8, 150),
    (FluentPaletteFamily.magenta, 0.9, -0.6, 120),
    (FluentPaletteFamily.forest, -0.7, 0.9, 110),
    (FluentPaletteFamily.cranberry, 0.8, 0.9, 170),
    (FluentPaletteFamily.lavender, 0.1, 0.2, 90),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final palette = theme.colors.palette;
    return ClipRRect(
      borderRadius: FluentRadius.allMedium,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.background2Rest(FluentPaletteFamily.blue),
              ),
            ),
            for (final (family, x, y, size) in _blobs)
              Align(
                alignment: Alignment(x, y),
                child: SizedBox.square(
                  dimension: size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.background2Rest(family),
                    ),
                  ),
                ),
              ),
            // Fine text is what makes a blur unmistakable — it is the first
            // thing to dissolve.
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(FluentSpacing.xs),
                child: Text(
                  'behind the surface ' * 6,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: theme.typography.caption2.copyWith(
                    color: theme.colors.neutralForeground1Static,
                  ),
                ),
              ),
            ),
            ?behind,
            Center(child: child),
          ],
        ),
      ),
    );
  }
}

/// Placeholder content wide enough to show the surface's own geometry.
class _Tile extends StatelessWidget {
  const _Tile();

  @override
  Widget build(BuildContext context) => const SizedBox(width: 140, height: 48);
}

/// Content for the Default story: readable text proving the surface keeps its
/// foreground crisp while the backdrop dissolves.
class _Panel extends StatelessWidget {
  const _Panel();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xs,
        children: [
          Text('Acrylic', style: theme.typography.subtitle2),
          Text(
            'Two tints over a blurred backdrop, edged with a gradient hairline.',
            style: theme.typography.body1.copyWith(
              color: theme.colors.neutralForeground2,
            ),
          ),
        ],
      ),
    );
  }
}

/// One captioned surface over its own backdrop.
class _Sample extends StatelessWidget {
  const _Sample({required this.caption, required this.surface});

  final String caption;
  final Widget surface;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xs,
        children: [
          Text(
            caption,
            style: theme.typography.caption1.copyWith(
              color: theme.colors.neutralForeground3,
            ),
          ),
          _Backdrop(child: surface),
        ],
      ),
    );
  }
}

/// Captioned surfaces laid out side by side so an axis can be read across.
class _Samples extends StatelessWidget {
  const _Samples({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: FluentSpacing.l,
    runSpacing: FluentSpacing.l,
    children: [
      for (final (caption, surface) in children)
        _Sample(caption: caption, surface: surface),
    ],
  );
}
