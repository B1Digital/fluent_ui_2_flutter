import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The CarouselNav docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Upstream ships `CarouselNav` as a standalone element with a render function
/// over `totalSlides`. Our nav strip is not a separate widget — [FluentCarousel]
/// builds it — but its individual button *is* public as [FluentCarouselStep],
/// which is the same thing the React render function returns. So the demo below
/// is a `Row` of steps over a local index, which is exactly the index-based
/// pagination the page describes.
const DocsPage carouselNavPage = DocsPage(
  id: 'components-carousel-carouselnav',
  folder: 'Carousel',
  title: 'CarouselNav',
  description:
      'CarouselNav provides an index based pagination of the Carousel '
      'containing it. The render function of CarouselNav will be called based '
      'on the total number of slide breakpoints in the carousel (i.e. if '
      'groupSize is 2, there will be one CarouselNavButton for each group of '
      'slides). By passing in the index function, we connect the pagination '
      'buttons to the carousel without a need for specific values or IDs, and '
      'will be a consistent page index selected after changes such as '
      'resizing. Each CarouselNavButton or CarouselImageNavButton will be '
      'wrapped in a context provider, enabling the index to be passed in '
      'without manual intervention. You can also override this render with a '
      'custom component and access the index via this same context.',
  source: 'lib/pages/components_carousel_carouselnav.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-carousel-carouselnav--default',
      title: 'Default',
      builder: _default,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'selected',
      type: 'bool',
      description: "Whether this step's slide is the one in view.",
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String',
      description:
          'Announced by assistive technology. A step has no text of its own.',
    ),
    PropRow(
      name: 'onPressed',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          'Invoked on tap and on Space or Enter. Null disables the step.',
    ),
    PropRow(
      name: 'preview',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The thumbnail for the image-preview indicator. Null draws a dot or '
          'pill.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentCarouselStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
  ],
);

// #docregion components-carousel-carouselnav--default
// Upstream's `CarouselNav` renders one `CarouselNavButton` per slide from a
// render function over `totalSlides`. Our equivalent button is public as
// [FluentCarouselStep]; the strip that holds them is private to
// [FluentCarousel], so the row below is built by hand. `appearance="brand"` has
// no Dart axis either — the Figma `Brand` mode of the step colour collection is
// unexposed — so the selected step's mark is tinted with `brandBackground`.
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  static const int _totalSlides = 5;
  static const AssetImage _swapImage = AssetImage(
    'assets/storybook/image-square.png',
  );

  bool _useImageButtons = false;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final BorderSide side = BorderSide(
      color: theme.colors.neutralForeground3,
      width: 2,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.fromBorderSide(side),
        borderRadius: FluentRadius.allMedium,
        boxShadow: theme.shadow(FluentElevation.shadow16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Upstream wraps the switch in a `Field` with
          // `orientation="horizontal"`. FluentField only stacks, so the label
          // rides on the switch instead.
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(border: Border(bottom: side)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FluentSwitch(
                checked: _useImageButtons,
                labelPosition: FluentSwitchLabelPosition.before,
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Use '),
                    Text(
                      'CarouselNavImageButton',
                      style: TextStyle(
                        fontFamily: FluentFontFamily.monospace,
                        fontFamilyFallback: FluentFontFamily.monospaceFallback,
                      ),
                    ),
                  ],
                ),
                onChanged: (bool checked) =>
                    setState(() => _useImageButtons = checked),
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(10),
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int index = 0; index < _totalSlides; index++)
                  FluentCarouselStep(
                    selected: index == _index,
                    semanticLabel: 'Carousel Nav Button $index',
                    preview: _useImageButtons
                        ? const Image(image: _swapImage, fit: BoxFit.cover)
                        : null,
                    style: index == _index
                        ? FluentCarouselStyle(
                            stepColor: WidgetStatePropertyAll<Color?>(
                              theme.colors.brandBackground,
                            ),
                          )
                        : null,
                    onPressed: () => setState(() => _index = index),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// #enddocregion components-carousel-carouselnav--default
