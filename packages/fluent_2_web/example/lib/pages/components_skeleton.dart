import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Skeleton docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Upstream splits the component in two: a `Skeleton` wrapper that carries the
/// `aria-label` and the shared defaults, and the `SkeletonItem` stencils inside
/// it. `FluentSkeleton` is the stencil; the wrapper's job is done by ordinary
/// layout plus a `Semantics` label, so every section here reads as one widget
/// per stencil.
const DocsPage skeletonPage = DocsPage(
  id: 'components-skeleton',
  title: 'Skeleton',
  description:
      'The Skeleton component is a temporary animation placeholder for when a '
      "service call takes time to return data and we don't want to block "
      'rendering the rest of the UI.',
  source: 'lib/pages/components_skeleton.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-skeleton--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-skeleton--appearance',
      title: 'Appearance',
      description:
          'You can specify the appearance of the Skeleton. This is useful for '
          'instances where you want to render a Skeleton with a MaterialOS '
          'theme',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-skeleton--animation',
      title: 'Animation',
      description:
          "You can specify the animation style of the Skeleton. The default is "
          "'wave' with the alternative being 'pulse'",
      builder: _animation,
    ),
    DocsSection(
      id: 'components-skeleton--row',
      title: 'Row',
      description:
          'You can make more complex wireframes using the basic building '
          'blocks of the Skeleton.',
      builder: _row,
    ),
    DocsSection(
      id: 'components-skeleton--size',
      title: 'Size',
      description:
          'You can specify the size of the SkeletonItem by using the size '
          'prop. The size is a number that represents the height of the '
          'SkeletonItem in pixels',
      builder: _size,
    ),
    DocsSection(
      id: 'components-skeleton--shape',
      title: 'Shape',
      description:
          'The shape of the SkeletonItem can be set to circle, rectangle, or '
          'square.',
      builder: _shape,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'shape',
      type: 'FluentSkeletonShape',
      defaultValue: 'FluentSkeletonShape.rectangle',
      description: 'Corner treatment.',
    ),
    PropRow(
      name: 'animation',
      type: 'FluentSkeletonAnimation',
      defaultValue: 'FluentSkeletonAnimation.wave',
      description: 'The loop to run while content is pending.',
    ),
    PropRow(
      name: 'width',
      type: 'double?',
      defaultValue: 'null',
      description: 'Width, or null to fill the space available.',
    ),
    PropRow(
      name: 'height',
      type: 'double?',
      defaultValue: 'null',
      description: 'Height, or null to fill the space available.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentSkeletonStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Announced by assistive technology.',
    ),
  ],
);

// #docregion components-skeleton--default
// Upstream's bare `<SkeletonItem />` is 16px tall and fills its wrapper's
// width; `FluentSkeleton` fills any axis left null, so only the height is
// pinned. The wrapper's `aria-label` becomes `semanticLabel`.
Widget _default(BuildContext context) =>
    const FluentSkeleton(height: 16, semanticLabel: 'Loading Content');
// #enddocregion components-skeleton--default

// #docregion components-skeleton--appearance
// `FluentSkeleton` has no `appearance` axis. Upstream's translucent appearance
// is exactly a swap of the two stencil tokens for their alpha variants, so it
// is written here as a `style` override naming those same tokens.
Widget _appearance(BuildContext context) {
  final FluentColors colors = FluentTheme.of(context).colors;
  return ColoredBox(
    color: colors.neutralBackground1,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const FluentField(
            validationMessage: Text('Opaque Appearance'),
            child: FluentSkeleton(height: 16, semanticLabel: 'Loading Content'),
          ),
          FluentField(
            validationMessage: const Text('Translucent Appearance'),
            child: FluentSkeleton(
              height: 16,
              semanticLabel: 'Loading Content',
              style: FluentSkeletonStyle(
                backgroundColor: WidgetStatePropertyAll<Color?>(
                  colors.neutralStencil1Alpha,
                ),
                waveColor: WidgetStatePropertyAll<Color?>(
                  colors.neutralStencil2Alpha,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
// #enddocregion components-skeleton--appearance

// #docregion components-skeleton--animation
Widget _animation(BuildContext context) => ColoredBox(
  color: FluentTheme.of(context).colors.neutralBackground1,
  child: const Padding(
    padding: EdgeInsets.symmetric(vertical: 50),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FluentField(
          validationMessage: Text('Wave animation'),
          child: FluentSkeleton(
            height: 16,
            animation: FluentSkeletonAnimation.wave,
            semanticLabel: 'Loading Content',
          ),
        ),
        FluentField(
          validationMessage: Text('Pulse animation'),
          child: FluentSkeleton(
            height: 16,
            animation: FluentSkeletonAnimation.pulse,
            semanticLabel: 'Loading Content',
          ),
        ),
      ],
    ),
  ),
);
// #enddocregion components-skeleton--animation

// #docregion components-skeleton--row
// Upstream sets `size={20}` on the wrapper and lets each row's CSS grid size
// the stencils as percentages of the row's own width. A Flutter `Row` flexes
// what is *left over* rather than the whole width, so the percentages are
// resolved against the measured width instead. `shape="square"` is a rectangle
// with equal sides, which is what a 24x24 rectangle already is.
Widget _row(BuildContext context) => Semantics(
  label: 'Loading Content',
  child: ColoredBox(
    color: FluentTheme.of(context).colors.neutralBackground1,
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                spacing: 10,
                children: <Widget>[
                  const FluentSkeleton(
                    shape: FluentSkeletonShape.circle,
                    width: 24,
                    height: 24,
                  ),
                  FluentSkeleton(width: width * 0.8, height: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                spacing: 10,
                children: <Widget>[
                  const FluentSkeleton(
                    shape: FluentSkeletonShape.circle,
                    width: 24,
                    height: 24,
                  ),
                  FluentSkeleton(width: width * 0.2, height: 20),
                  FluentSkeleton(width: width * 0.2, height: 20),
                  FluentSkeleton(width: width * 0.15, height: 20),
                  FluentSkeleton(width: width * 0.15, height: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                spacing: 10,
                children: <Widget>[
                  const FluentSkeleton(width: 24, height: 24),
                  FluentSkeleton(width: width * 0.2, height: 20),
                  FluentSkeleton(width: width * 0.2, height: 20),
                  FluentSkeleton(width: width * 0.15, height: 20),
                  FluentSkeleton(width: width * 0.15, height: 20),
                ],
              ),
            ),
          ],
        );
      },
    ),
  ),
);
// #enddocregion components-skeleton--row

// #docregion components-skeleton--size
Widget _size(BuildContext context) => ColoredBox(
  color: FluentTheme.of(context).colors.neutralBackground1,
  child: Padding(
    padding: const EdgeInsets.all(FluentSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FluentSpacing.l,
      children: <Widget>[
        for (final int size in _sizes)
          Row(
            spacing: FluentSpacing.s,
            children: <Widget>[
              SizedBox(
                width: 25,
                child: Text('$size', textAlign: TextAlign.center),
              ),
              Expanded(
                child: FluentSkeleton(
                  height: size.toDouble(),
                  semanticLabel: 'Loading Content',
                ),
              ),
            ],
          ),
      ],
    ),
  ),
);

const List<int> _sizes = <int>[
  8,
  12,
  14,
  16,
  20,
  22,
  24,
  28,
  32,
  36,
  40,
  48,
  52,
  56,
  64,
  72,
  92,
  96,
  120,
  128,
];
// #enddocregion components-skeleton--size

// #docregion components-skeleton--shape
// `FluentSkeletonShape` has `rectangle` and `circle`. Upstream's third shape,
// `square`, is a rectangle whose sides are equal — so it is one here too.
Widget _shape(BuildContext context) => Semantics(
  label: 'Loading Content',
  child: ColoredBox(
    color: FluentTheme.of(context).colors.neutralBackground1,
    child: const Padding(
      padding: EdgeInsets.all(FluentSpacing.xl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.l,
        children: <Widget>[
          FluentSkeleton(
            shape: FluentSkeletonShape.circle,
            width: 64,
            height: 64,
          ),
          FluentSkeleton(width: 150, height: 64),
          FluentSkeleton(width: 64, height: 64),
        ],
      ),
    ),
  ),
);
// #enddocregion components-skeleton--shape
