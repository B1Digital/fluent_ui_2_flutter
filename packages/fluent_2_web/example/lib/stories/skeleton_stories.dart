import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentSkeleton].
final StorySection skeletonStories = StorySection(
  component: 'Skeleton',
  description:
      'The placeholder that holds a layout together while its content is still '
      'loading. Two corner shapes, two loops — a sweeping wave or a fading '
      'pulse — and no intrinsic size at all: a skeleton takes the shape of the '
      'thing it is standing in for. It is decorative, never interactive, and '
      'both loops stop dead under reduced motion.',
  stories: [
    Story(
      name: 'Default',
      description:
          'One skeleton with every axis live. Width and height are ordinary '
          'box constraints, so a skeleton is sized like any other widget '
          'rather than picked from a size ramp.',
      knobs: const [
        OptionKnob<FluentSkeletonShape>(
          label: 'Shape',
          id: 'shape',
          initial: FluentSkeletonShape.rectangle,
          options: FluentSkeletonShape.values,
          labelOf: _shapeLabel,
        ),
        OptionKnob<FluentSkeletonAnimation>(
          label: 'Animation',
          id: 'animation',
          initial: FluentSkeletonAnimation.wave,
          options: FluentSkeletonAnimation.values,
          labelOf: _animationLabel,
        ),
        NumberKnob(
          label: 'Width',
          id: 'width',
          initial: 240,
          min: 16,
          max: 400,
          step: 4,
        ),
        NumberKnob(
          label: 'Height',
          id: 'height',
          initial: 32,
          min: 8,
          max: 120,
          step: 4,
        ),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return FluentSkeleton(
          shape: knobs.get<FluentSkeletonShape>(
            'shape',
            FluentSkeletonShape.rectangle,
          ),
          animation: knobs.get<FluentSkeletonAnimation>(
            'animation',
            FluentSkeletonAnimation.wave,
          ),
          width: knobs.get<double>('width', 240),
          height: knobs.get<double>('height', 32),
        );
      },
    ),
    const Story(
      name: 'Shapes',
      description:
          'Rectangle rounds by 4px; circle takes the fully-rounded radius, so '
          'it reads as a circle only when the box is square and as a stadium '
          'when it is not.',
      builder: _shapesBuilder,
    ),
    const Story(
      name: 'Animations',
      description:
          'Wave sweeps a highlight band across the surface over 3s; pulse '
          'fades the whole surface to 40% and back over 1s and draws no band '
          'at all; none holds the band still and centred.',
      builder: _animationsBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'A skeleton has no size ramp — it fills whatever box it is given. '
          'These are the global size stops used as heights, which is how a '
          'placeholder is matched to the line height it replaces.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Filling the space',
      description:
          'Omit an axis and the skeleton expands on it, so a bar can stretch '
          'to its column and a block can fill a fixed region without either '
          'one being measured by hand.',
      builder: _fillBuilder,
    ),
    Story(
      name: 'A loading row',
      description:
          'The shape a skeleton is usually used in: a round avatar beside two '
          'lines of stand-in text, all sharing one loop so the row shimmers as '
          'a single unit.',
      knobs: const [
        OptionKnob<FluentSkeletonAnimation>(
          label: 'Animation',
          id: 'animation',
          initial: FluentSkeletonAnimation.wave,
          options: FluentSkeletonAnimation.values,
          labelOf: _animationLabel,
        ),
      ],
      builder: (context) => _Rows(
        animation: KnobsScope.of(context).get<FluentSkeletonAnimation>(
          'animation',
          FluentSkeletonAnimation.wave,
        ),
      ),
    ),
    const Story(
      name: 'Standing in for content',
      description:
          'What the component is for. Press reload and the real rows are '
          'replaced by skeletons of the same metrics for two seconds, so '
          'nothing on the page moves when the content lands.',
      builder: _loadingSwapBuilder,
    ),
    Story(
      name: 'Reduced motion',
      description:
          'Under MediaQuery.disableAnimations neither loop runs: the wave '
          'falls back to its still, centred band and the pulse holds fully '
          'opaque. Toggle the knob to see both.',
      knobs: const [
        BoolKnob(label: 'Reduce motion', id: 'reduced', initial: true),
      ],
      builder: _reducedMotionBuilder,
    ),
    const Story(
      name: 'Custom styling',
      description:
          'Three rungs of override — the shape defaults, a '
          'FluentSkeletonTheme over a subtree, then the widget style, which is '
          'merged last and wins. The last case swaps in the alpha stencil '
          'tokens, which is how a skeleton reads over a coloured surface.',
      builder: _stylingBuilder,
    ),
  ],
);

String _shapeLabel(FluentSkeletonShape value) => value.name;

String _animationLabel(FluentSkeletonAnimation value) => value.name;

Widget _shapesBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'rectangle — borderRadiusMedium',
      FluentSkeleton(width: 240, height: FluentSize.size320),
    ),
    (
      'circle, square box — a true circle',
      FluentSkeleton(
        shape: FluentSkeletonShape.circle,
        width: FluentSize.size480,
        height: FluentSize.size480,
      ),
    ),
    (
      'circle, wide box — a stadium',
      FluentSkeleton(
        shape: FluentSkeletonShape.circle,
        width: 240,
        height: FluentSize.size320,
      ),
    ),
  ],
);

Widget _animationsBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'wave — a band sweeping over 3s',
      FluentSkeleton(width: 240, height: FluentSize.size320),
    ),
    (
      'pulse — the surface fading over 1s',
      FluentSkeleton(
        animation: FluentSkeletonAnimation.pulse,
        width: 240,
        height: FluentSize.size320,
      ),
    ),
    (
      'none — the band held still',
      FluentSkeleton(
        animation: FluentSkeletonAnimation.none,
        width: 240,
        height: FluentSize.size320,
      ),
    ),
  ],
);

/// The global size stops a placeholder is usually matched to: caption, body and
/// title line heights, then the avatar sizes.
const List<double> _sizeRamp = <double>[
  FluentSize.size80,
  FluentSize.size120,
  FluentSize.size160,
  FluentSize.size200,
  FluentSize.size240,
  FluentSize.size320,
  FluentSize.size400,
  FluentSize.size480,
];

Widget _sizesBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.xxl,
    children: [
      for (final (caption, shape, width)
          in <(String, FluentSkeletonShape, double?)>[
            (
              'rectangles — one bar per stop',
              FluentSkeletonShape.rectangle,
              240.0,
            ),
            ('circles — the box kept square', FluentSkeletonShape.circle, null),
          ])
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: FluentSpacing.s,
          children: [
            Text(
              caption,
              style: theme.typography.caption1.copyWith(
                color: theme.colors.neutralForeground3,
              ),
            ),
            Wrap(
              spacing: FluentSpacing.m,
              runSpacing: FluentSpacing.m,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final size in _sizeRamp)
                  FluentSkeleton(
                    shape: shape,
                    width: width ?? size,
                    height: size,
                  ),
              ],
            ),
          ],
        ),
    ],
  );
}

Widget _fillBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'no width — stretches to the column',
      FluentSkeleton(height: FluentSize.size200),
    ),
    (
      'no height — fills a 96-high region',
      SizedBox(height: 96, child: FluentSkeleton()),
    ),
    ('both pinned', FluentSkeleton(width: 120, height: FluentSize.size200)),
  ],
);

Widget _loadingSwapBuilder(BuildContext context) => const _LoadingSwap();

Widget _reducedMotionBuilder(BuildContext context) {
  final reduced = KnobsScope.of(context).get<bool>('reduced', true);
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: const _Cases(
      children: [
        ('wave', FluentSkeleton(width: 240, height: FluentSize.size320)),
        (
          'pulse',
          FluentSkeleton(
            animation: FluentSkeletonAnimation.pulse,
            width: 240,
            height: FluentSize.size320,
          ),
        ),
      ],
    ),
  );
}

Widget _stylingBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return FluentSkeletonTheme(
    style: FluentSkeletonStyle.from(borderRadius: FluentRadius.allXLarge),
    child: _Cases(
      children: [
        ('shape defaults, outside the subtree', _outsideTheSubtree),
        (
          'subtree theme — an 8px radius',
          const FluentSkeleton(width: 240, height: FluentSize.size400),
        ),
        (
          'widget style wins — a slower loop and a square corner',
          const FluentSkeleton(
            width: 240,
            height: FluentSize.size400,
            style: FluentSkeletonStyle(
              borderRadius: WidgetStatePropertyAll<BorderRadius?>(
                BorderRadius.zero,
              ),
              motion: FluentMotionSpec(
                duration: Duration(seconds: 6),
                curve: Curves.easeInOut,
              ),
            ),
          ),
        ),
        (
          'the alpha stencil tokens, over a coloured surface',
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.brandBackground2,
              borderRadius: FluentRadius.allMedium,
            ),
            child: Padding(
              padding: const EdgeInsets.all(FluentSpacing.m),
              child: FluentSkeleton(
                height: FluentSize.size400,
                style: FluentSkeletonStyle.from(
                  backgroundColor: colors.neutralStencil1Alpha,
                  waveColor: colors.neutralStencil2Alpha,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Sits outside the [FluentSkeletonTheme] so the unthemed default is visible
/// beside the overridden ones.
const Widget _outsideTheSubtree = FluentSkeleton(
  width: 240,
  height: FluentSize.size400,
);

/// Three rows of the shape a feed loads into: an avatar and two text lines.
class _Rows extends StatelessWidget {
  const _Rows({required this.animation});

  final FluentSkeletonAnimation animation;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.l,
      children: [
        for (var i = 0; i < 3; i++)
          Row(
            spacing: FluentSpacing.m,
            children: [
              FluentSkeleton(
                shape: FluentSkeletonShape.circle,
                animation: animation,
                width: FluentSize.size400,
                height: FluentSize.size400,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  spacing: FluentSpacing.s,
                  children: [
                    FluentSkeleton(
                      animation: animation,
                      height: FluentSize.size160,
                    ),
                    // The second line is short, the way a subtitle is.
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FluentSkeleton(
                        animation: animation,
                        width: 160,
                        height: FluentSize.size120,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

/// Swaps real rows for skeletons of the same metrics while a fake fetch runs.
class _LoadingSwap extends StatefulWidget {
  const _LoadingSwap();

  @override
  State<_LoadingSwap> createState() => _LoadingSwapState();
}

class _LoadingSwapState extends State<_LoadingSwap> {
  static const List<(String, String, String)> _people = [
    ('Kat Larsson', 'KL', 'Sent the deck for review'),
    ('Daisy Phillips', 'DP', 'Added three files to Design'),
    ('Robert Tolbert', 'RT', 'Commented on the spec'),
  ];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _loading = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.l,
        children: [
          FluentButton(
            onPressed: _loading ? null : _reload,
            child: Text(_loading ? 'Loading…' : 'Reload'),
          ),
          for (final (name, initials, detail) in _people)
            SizedBox(
              height: FluentSize.size480,
              child: Row(
                spacing: FluentSpacing.m,
                children: [
                  if (_loading)
                    const FluentSkeleton(
                      shape: FluentSkeletonShape.circle,
                      width: FluentSize.size400,
                      height: FluentSize.size400,
                      semanticLabel: 'Loading',
                    )
                  else
                    FluentAvatar(
                      initials: initials,
                      name: name,
                      size: FluentAvatarSize.size40,
                    ),
                  Expanded(
                    child: _loading
                        ? const Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: FluentSpacing.s,
                            children: [
                              FluentSkeleton(height: FluentSize.size160),
                              FluentSkeleton(height: FluentSize.size120),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(name, style: theme.typography.body1Strong),
                              Text(
                                detail,
                                style: theme.typography.caption1.copyWith(
                                  color: theme.colors.neutralForeground3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Stacked cases under a caption, stretched to one width so the surfaces are
/// directly comparable.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xl,
        children: [
          for (final (caption, child) in children)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: FluentSpacing.xs,
              children: [
                Text(
                  caption,
                  style: theme.typography.caption1.copyWith(
                    color: theme.colors.neutralForeground3,
                  ),
                ),
                child,
              ],
            ),
        ],
      ),
    );
  }
}
