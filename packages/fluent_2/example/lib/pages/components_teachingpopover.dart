import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The TeachingPopover docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage teachingPopoverPage = DocsPage(
  id: 'components-teachingpopover',
  title: 'TeachingPopover',
  description: '',
  source: 'lib/pages/components_teachingpopover.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-teachingpopover--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-teachingpopover--appearance-brand',
      title: 'Appearance Brand',
      builder: _appearanceBrand,
    ),
    DocsSection(
      id: 'components-teachingpopover--carousel',
      title: 'Carousel',
      builder: _carousel,
    ),
    DocsSection(
      id: 'components-teachingpopover--carousel-brand',
      title: 'Carousel Brand',
      builder: _carouselBrand,
    ),
    DocsSection(
      id: 'components-teachingpopover--carousel-text',
      title: 'Carousel Text',
      builder: _carouselText,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'child',
      type: 'Widget',
      description:
          'The trigger. Rendered in place; the surface is anchored to it.',
    ),
    PropRow(name: 'title', type: 'Widget', description: 'The headline.'),
    PropRow(
      name: 'body',
      type: 'Widget',
      description: 'The explanatory paragraph.',
    ),
    PropRow(
      name: 'open',
      type: 'bool',
      description: 'Whether the surface is showing.',
    ),
    PropRow(
      name: 'onOpenChanged',
      type: 'ValueChanged<bool>?',
      defaultValue: 'null',
      description:
          'Reports every open and close — Escape, an outside tap, the dismiss '
          'button. Null disables the popover.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentTeachingPopoverAppearance',
      defaultValue: 'FluentTeachingPopoverAppearance.normal',
      description: 'Fill treatment.',
    ),
    PropRow(
      name: 'position',
      type: 'FluentPopoverPosition',
      defaultValue: 'FluentPopoverPosition.below',
      description: 'Which side of child the surface sits on.',
    ),
    PropRow(
      name: 'align',
      type: 'FluentPopoverAlign',
      defaultValue: 'FluentPopoverAlign.center',
      description: 'Where along that side the surface lines up.',
    ),
    PropRow(
      name: 'withArrow',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether to draw the pointing arrow.',
    ),
    PropRow(
      name: 'header',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The small caption above the media. Optional.',
    ),
    PropRow(
      name: 'media',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The image or illustration between the caption and the title. '
          'Optional.',
    ),
    PropRow(
      name: 'onDismiss',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          "Invoked by the header's dismiss button, in addition to "
          'onOpenChanged being called with false. Null draws no dismiss button '
          'at all.',
    ),
    PropRow(
      name: 'dismissSemanticLabel',
      type: 'String',
      defaultValue: "'Close'",
      description:
          'Announced for the dismiss button, which has no text of its own.',
    ),
    PropRow(
      name: 'primaryAction',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The confirming action. Normally a FluentButton with '
          'FluentButtonAppearance.primary.',
    ),
    PropRow(
      name: 'secondaryAction',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The secondary action. Normally a default-appearance '
          'FluentButton.',
    ),
    PropRow(
      name: 'carousel',
      type: 'FluentTeachingPopoverCarousel?',
      defaultValue: 'null',
      description: 'Multi-step tour state, or null for a single-step popover.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentTeachingPopoverStyle?',
      defaultValue: 'null',
      description:
          'Content overrides layered over the theme defaults. Merged last, so '
          'it wins.',
    ),
    PropRow(
      name: 'popoverStyle',
      type: 'FluentPopoverStyle?',
      defaultValue: 'null',
      description: 'Surface overrides, passed straight through to the popover.',
    ),
  ],
);

// #docregion components-teachingpopover--default
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentTeachingPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    // A non-null onDismiss is what draws the header's dismiss button; closing
    // is already handled for us, so there is nothing extra to do here.
    onDismiss: () {},
    header: const Text('Tips'),
    media: const Image(
      image: AssetImage('assets/storybook/image-square.png'),
      fit: BoxFit.cover,
      height: 90,
    ),
    title: const Text('Teaching Bubble Title'),
    body: const Text('This is a teaching popover body'),
    primaryAction: FluentButton(
      appearance: FluentButtonAppearance.primary,
      onPressed: () => setState(() => _open = false),
      child: const Text('Learn more'),
    ),
    secondaryAction: FluentButton(
      onPressed: () => setState(() => _open = false),
      child: const Text('Got it'),
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = !_open),
      child: const Text('TeachingPopover trigger'),
    ),
  );
}
// #enddocregion components-teachingpopover--default

// #docregion components-teachingpopover--appearance-brand
Widget _appearanceBrand(BuildContext context) => const _AppearanceBrand();

class _AppearanceBrand extends StatefulWidget {
  const _AppearanceBrand();

  @override
  State<_AppearanceBrand> createState() => _AppearanceBrandState();
}

class _AppearanceBrandState extends State<_AppearanceBrand> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentTeachingPopover(
    appearance: FluentTeachingPopoverAppearance.brand,
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    onDismiss: () {},
    header: const Text('Tips'),
    media: const Image(
      image: AssetImage('assets/storybook/image-square.png'),
      fit: BoxFit.cover,
      height: 90,
    ),
    title: const Text('Teaching Bubble Title'),
    body: const Text('This is a teaching popover body'),
    primaryAction: FluentButton(
      appearance: FluentButtonAppearance.primary,
      onPressed: () => setState(() => _open = false),
      child: const Text('Learn more'),
    ),
    secondaryAction: FluentButton(
      onPressed: () => setState(() => _open = false),
      child: const Text('Got it'),
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = !_open),
      child: const Text('TeachingPopover trigger'),
    ),
  );
}
// #enddocregion components-teachingpopover--appearance-brand

// #docregion components-teachingpopover--carousel
Widget _carousel(BuildContext context) => const _Carousel();

class _Carousel extends StatefulWidget {
  const _Carousel();

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  // Upstream's three TeachingPopoverCarouselCards. One FluentTeachingPopover
  // shows one page at a time, so the cards are data and `_step` picks one.
  static const List<String> _pages = <String>[
    'This is page: 1',
    'This is page: 2',
    'This is page: 3',
  ];

  bool _open = false;
  int _step = 0;

  bool get _isFirst => _step == 0;

  bool get _isLast => _step == _pages.length - 1;

  @override
  Widget build(BuildContext context) => FluentTeachingPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    onDismiss: () {},
    header: const Text('Tips'),
    media: const Image(
      image: AssetImage('assets/storybook/image-square.png'),
      fit: BoxFit.cover,
      height: 90,
    ),
    title: const Text('Teaching Bubble Title'),
    body: Text(_pages[_step]),
    carousel: FluentTeachingPopoverCarousel(
      steps: _pages.length,
      activeStep: _step,
      onStepSelected: (int step) => setState(() => _step = step),
      stepSemanticLabel: (int index) => 'Tip ${index + 1}',
    ),
    // `initialStepText` and `finalStepText` are upstream's swap-in labels for
    // the first and last page of the tour.
    secondaryAction: FluentButton(
      onPressed: () => setState(() {
        if (_isFirst) {
          _open = false;
        } else {
          _step -= 1;
        }
      }),
      child: Text(_isFirst ? 'Close' : 'Previous'),
    ),
    primaryAction: FluentButton(
      appearance: FluentButtonAppearance.primary,
      onPressed: () => setState(() {
        if (_isLast) {
          _open = false;
        } else {
          _step += 1;
        }
      }),
      child: Text(_isLast ? 'Finish' : 'Next'),
    ),
    child: FluentButton(
      onPressed: () => setState(() {
        _open = !_open;
        _step = 0;
      }),
      child: const Text('TeachingPopover trigger'),
    ),
  );
}
// #enddocregion components-teachingpopover--carousel

// #docregion components-teachingpopover--carousel-brand
Widget _carouselBrand(BuildContext context) => const _CarouselBrand();

class _CarouselBrand extends StatefulWidget {
  const _CarouselBrand();

  @override
  State<_CarouselBrand> createState() => _CarouselBrandState();
}

class _CarouselBrandState extends State<_CarouselBrand> {
  static const List<String> _pages = <String>[
    'This is page: 1',
    'This is page: 2',
    'This is page: 3',
  ];

  bool _open = false;
  int _step = 0;

  bool get _isFirst => _step == 0;

  bool get _isLast => _step == _pages.length - 1;

  @override
  Widget build(BuildContext context) => FluentTeachingPopover(
    appearance: FluentTeachingPopoverAppearance.brand,
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    onDismiss: () {},
    header: const Text('Tips'),
    media: const Image(
      image: AssetImage('assets/storybook/image-square.png'),
      fit: BoxFit.cover,
      height: 90,
    ),
    title: const Text('Teaching Bubble Title'),
    body: Text(_pages[_step]),
    carousel: FluentTeachingPopoverCarousel(
      steps: _pages.length,
      activeStep: _step,
      onStepSelected: (int step) => setState(() => _step = step),
      stepSemanticLabel: (int index) => 'Tip ${index + 1}',
    ),
    secondaryAction: FluentButton(
      onPressed: () => setState(() {
        if (_isFirst) {
          _open = false;
        } else {
          _step -= 1;
        }
      }),
      child: Text(_isFirst ? 'Close' : 'Previous'),
    ),
    primaryAction: FluentButton(
      appearance: FluentButtonAppearance.primary,
      onPressed: () => setState(() {
        if (_isLast) {
          _open = false;
        } else {
          _step += 1;
        }
      }),
      child: Text(_isLast ? 'Finish' : 'Next'),
    ),
    child: FluentButton(
      onPressed: () => setState(() {
        _open = !_open;
        _step = 0;
      }),
      child: const Text('TeachingPopover trigger'),
    ),
  );
}
// #enddocregion components-teachingpopover--carousel-brand

// #docregion components-teachingpopover--carousel-text
Widget _carouselText(BuildContext context) => const _CarouselText();

class _CarouselText extends StatefulWidget {
  const _CarouselText();

  @override
  State<_CarouselText> createState() => _CarouselTextState();
}

class _CarouselTextState extends State<_CarouselText> {
  static const List<String> _pages = <String>[
    'This is page: 1',
    'This is page: 2',
    'This is page: 3',
  ];

  bool _open = false;
  int _step = 0;

  bool get _isFirst => _step == 0;

  bool get _isLast => _step == _pages.length - 1;

  @override
  Widget build(BuildContext context) => FluentTeachingPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    onDismiss: () {},
    header: const Text('Tips"'),
    media: const Image(
      image: AssetImage('assets/storybook/image-square.png'),
      fit: BoxFit.cover,
      height: 90,
    ),
    title: const Text('Teaching Bubble Title'),
    body: Text(_pages[_step]),
    // Upstream swaps its nav dots for a TeachingPopoverCarouselPageCount here.
    // FluentTeachingPopoverCarousel draws `pageCount` beside the dots rather
    // than instead of them, so this footer shows both.
    carousel: FluentTeachingPopoverCarousel(
      steps: _pages.length,
      activeStep: _step,
      onStepSelected: (int step) => setState(() => _step = step),
      stepSemanticLabel: (int index) => 'Tip ${index + 1}',
      pageCount: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text('${_step + 1} of ${_pages.length}'),
      ),
    ),
    secondaryAction: FluentButton(
      onPressed: () => setState(() {
        if (_isFirst) {
          _open = false;
        } else {
          _step -= 1;
        }
      }),
      child: Text(_isFirst ? 'Close' : 'Previous'),
    ),
    primaryAction: FluentButton(
      appearance: FluentButtonAppearance.primary,
      onPressed: () => setState(() {
        if (_isLast) {
          _open = false;
        } else {
          _step += 1;
        }
      }),
      child: Text(_isLast ? 'Finish' : 'Next'),
    ),
    child: FluentButton(
      onPressed: () => setState(() {
        _open = !_open;
        _step = 0;
      }),
      child: const Text('TeachingPopover trigger'),
    ),
  );
}

// #enddocregion components-teachingpopover--carousel-text
