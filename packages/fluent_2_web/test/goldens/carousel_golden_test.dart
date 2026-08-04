import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// A regression net over the four `Carousel` axes — layout, chevron placement,
/// nav type and where the autoplay control lives — in all three themes.
///
/// High contrast is the cell to look at: the over-content wash and the step's
/// transparent hit target both turn opaque there, and a step whose mark
/// matched either of them would disappear without anything else moving.
void main() {
  /// A slide that reads as a filled panel without needing an image asset.
  ///
  /// Outlined as well as filled: in high contrast every background token
  /// collapses onto Canvas, so a fill-only placeholder would be invisible and
  /// the image would say nothing about where the slides sit.
  Widget slide(Color Function(FluentColors colors) pick) => Builder(
    builder: (context) {
      final colors = FluentTheme.of(context).colors;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: pick(colors),
          border: Border.all(color: colors.neutralStroke1),
        ),
      );
    },
  );

  List<Widget> slides() => <Widget>[
    slide((c) => c.brandBackground2),
    slide((c) => c.neutralBackground3),
    slide((c) => c.brandBackground2Hover),
  ];

  Widget cell({
    required FluentCarouselLayout layout,
    required FluentCarouselChevronPlacement placement,
    bool preview = false,
    bool autoplay = false,
    int index = 0,
  }) => SizedBox(
    width: 320,
    height: 176,
    child: FluentCarousel(
      slides: slides(),
      previews: preview ? slides() : null,
      initialIndex: index,
      layout: layout,
      chevronPlacement: placement,
      autoplay: autoplay,
      pauseButton: autoplay
          ? FluentCarouselPauseButton.inNav
          : FluentCarouselPauseButton.onContentClick,
      semanticLabel: 'Gallery',
    ),
  );

  goldenGridTest(
    'carousel',
    () => goldenGrid(<Widget>[
      // Row 1 — the two layouts, flexible chevrons.
      cell(
        layout: FluentCarouselLayout.outsideContent,
        placement: FluentCarouselChevronPlacement.flexibleToEdges,
      ),
      cell(
        layout: FluentCarouselLayout.overContent,
        placement: FluentCarouselChevronPlacement.flexibleToEdges,
        index: 1,
      ),
      // Row 2 — the other two chevron placements.
      cell(
        layout: FluentCarouselLayout.outsideContent,
        placement: FluentCarouselChevronPlacement.groupedToSteps,
        index: 1,
      ),
      cell(
        layout: FluentCarouselLayout.outsideContent,
        placement: FluentCarouselChevronPlacement.centeredToContent,
        index: 2,
      ),
      // Row 3 — image-preview nav, and the autoplay control in the nav.
      cell(
        layout: FluentCarouselLayout.outsideContent,
        placement: FluentCarouselChevronPlacement.groupedToSteps,
        preview: true,
      ),
      cell(
        layout: FluentCarouselLayout.outsideContent,
        placement: FluentCarouselChevronPlacement.groupedToSteps,
        autoplay: true,
      ),
    ], columns: 2),
    surfaceSize: const Size(760, 640),
  );
}
