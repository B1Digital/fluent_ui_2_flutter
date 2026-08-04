import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// The grid is `Style` x footer `Type`, rendered through the two build
/// functions rather than through the widget: an open teaching popover lives in
/// the [Overlay], which sits above the RepaintBoundary these images are cropped
/// to. Building the surface directly captures the same pixels.
void main() {
  Widget cell(
    FluentTeachingPopoverAppearance appearance, {
    FluentTeachingPopoverCarousel? carousel,
    bool withMedia = true,
  }) => Builder(
    builder: (context) {
      final theme = FluentTheme.of(context);
      final state = resolveFluentTeachingPopoverState(
        appearance: appearance,
        header: const Text('New'),
        media: withMedia
            ? SizedBox(
                height: 90,
                child: ColoredBox(color: theme.colors.brandBackground2),
              )
            : null,
        title: const Text('Pin your favourites'),
        body: const Text('Anything you pin shows up here first.'),
        onDismiss: () {},
        primaryAction: FluentButton(
          appearance: FluentButtonAppearance.primary,
          onPressed: () {},
          child: const Text('Next'),
        ),
        secondaryAction: FluentButton(onPressed: () {}, child: const Text('B')),
        carousel: carousel,
      );

      final popoverState = resolveFluentPopoverState(
        appearance: switch (appearance) {
          FluentTeachingPopoverAppearance.normal =>
            FluentPopoverAppearance.normal,
          FluentTeachingPopoverAppearance.brand =>
            FluentPopoverAppearance.brand,
        },
        content: buildFluentTeachingPopover(
          state,
          resolveFluentTeachingPopoverStyle(state, theme),
          const <WidgetState>{},
        ),
      );

      return buildFluentPopover(
        popoverState,
        resolveFluentPopoverStyle(popoverState, theme),
        const <WidgetState>{},
      );
    },
  );

  goldenGridTest(
    'teaching_popover',
    () => goldenGrid(<Widget>[
      cell(FluentTeachingPopoverAppearance.normal),
      cell(FluentTeachingPopoverAppearance.brand),
      cell(
        FluentTeachingPopoverAppearance.normal,
        withMedia: false,
        carousel: const FluentTeachingPopoverCarousel(
          steps: 4,
          activeStep: 1,
          pageCount: Text('2/4'),
        ),
      ),
      cell(
        FluentTeachingPopoverAppearance.brand,
        withMedia: false,
        carousel: const FluentTeachingPopoverCarousel(steps: 4, activeStep: 1),
      ),
    ], columns: 2),
    surfaceSize: const Size(900, 900),
  );
}
