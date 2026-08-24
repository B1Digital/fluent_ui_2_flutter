import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The ProgressBar docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage progressBarPage = DocsPage(
  id: 'components-progressbar',
  title: 'ProgressBar',
  description:
      'A ProgressBar provides a visual representation of content being loaded '
      'or processed.',
  source: 'lib/pages/components_progressbar.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-progressbar--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-progressbar--color',
      title: 'Color',
      description:
          'The color prop can be used to indicate a "brand" state (default), '
          '"error" state (red), "warning" state (orange), or "success" state '
          '(green).',
      builder: _color,
    ),
    DocsSection(
      id: 'components-progressbar--indeterminate',
      title: 'Indeterminate',
      description:
          "ProgressBar is indeterminate when 'value' is undefined. "
          'Indeterminate ProgressBar is best used to show that an operation is '
          'being executed.',
      builder: _indeterminate,
    ),
    DocsSection(
      id: 'components-progressbar--motion-custom',
      title: 'Motion Custom',
      description:
          'The indeterminate animation can be customized using the Motion '
          'APIs, together with the indeterminateMotion slot.',
      builder: _motionCustom,
    ),
    DocsSection(
      id: 'components-progressbar--max',
      title: 'Max',
      description:
          'You can specify the maximum value of the determinate ProgressBar. '
          'This is useful for instances where you want to show capacity, or '
          'how much of a total has been uploaded/downloaded.',
      builder: _max,
    ),
    DocsSection(
      id: 'components-progressbar--shape',
      title: 'Shape',
      description:
          'The shape prop affects the corners of the bar. It can be rounded '
          '(default) or square.',
      builder: _shape,
    ),
    DocsSection(
      id: 'components-progressbar--thickness',
      title: 'Thickness',
      description:
          'The thickness prop affects the size of the bar. It can be medium '
          '(default) or large.',
      builder: _thickness,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'value',
      type: 'double?',
      defaultValue: 'null',
      description:
          'How much of the bar is filled, from 0 to 1. Null means '
          'indeterminate.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentProgressBarSize',
      defaultValue: 'FluentProgressBarSize.medium',
      description: 'Bar height.',
    ),
    PropRow(
      name: 'status',
      type: 'FluentProgressBarStatus',
      defaultValue: 'FluentProgressBarStatus.none',
      description: 'Which colour family the filled portion takes.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentProgressBarStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology alongside the percentage.',
    ),
  ],
);

// #docregion components-progressbar--default
Widget _default(BuildContext context) => const FluentField(
  validationMessage: Text('Default ProgressBar'),
  validationState: FluentFieldValidationState.none,
  child: FluentProgressBar(value: 0.5),
);
// #enddocregion components-progressbar--default

// #docregion components-progressbar--color
// Upstream's `color` prop is our `status`. Its `warning` binds Fluent's Severe
// family, which is the dark orange the React bar also renders.
Widget _color(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    FluentField(
      validationMessage: Text('Error ProgressBar'),
      validationState: FluentFieldValidationState.error,
      child: FluentProgressBar(
        value: 0.75,
        status: FluentProgressBarStatus.error,
      ),
    ),
    SizedBox(height: 20),
    FluentField(
      validationMessage: Text('Warning ProgressBar'),
      validationState: FluentFieldValidationState.warning,
      child: FluentProgressBar(
        value: 0.95,
        status: FluentProgressBarStatus.warning,
      ),
    ),
    SizedBox(height: 20),
    FluentField(
      validationMessage: Text('Success ProgressBar'),
      validationState: FluentFieldValidationState.success,
      child: FluentProgressBar(
        value: 1,
        status: FluentProgressBarStatus.success,
      ),
    ),
  ],
);
// #enddocregion components-progressbar--color

// #docregion components-progressbar--indeterminate
Widget _indeterminate(BuildContext context) => const FluentField(
  validationMessage: Text('Indeterminate ProgressBar'),
  validationState: FluentFieldValidationState.none,
  child: FluentProgressBar(),
);
// #enddocregion components-progressbar--indeterminate

// #docregion components-progressbar--motion-custom
// `FluentProgressBar` owns its indeterminate sweep and exposes no motion slot,
// so this bar is composed from the public recomposition functions instead:
// `resolveFluentProgressBarState` and `resolveFluentProgressBarStyle` still
// supply every token, and only the rendering — the part upstream replaces with
// its own motion component — is written by hand.
Widget _motionCustom(BuildContext context) => const _MotionCustom();

class _MotionCustom extends StatefulWidget {
  const _MotionCustom();

  @override
  State<_MotionCustom> createState() => _MotionCustomState();
}

class _MotionCustomState extends State<_MotionCustom>
    with SingleTickerProviderStateMixin {
  // A custom motion that swings between left and right, instead of always
  // moving to the right. `reverse: true` is upstream's `direction: 'alternate'`.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Set<WidgetState> states = <WidgetState>{};
    final FluentProgressBarStyle style = resolveFluentProgressBarStyle(
      resolveFluentProgressBarState(),
      FluentTheme.of(context),
    );
    final BorderRadius radius =
        style.borderRadius?.resolve(states) ?? FluentRadius.allCircular;

    return FluentField(
      validationMessage: const Text('Custom indeterminate animation'),
      validationState: FluentFieldValidationState.none,
      child: SizedBox(
        height: style.thickness?.resolve(states) ?? 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.railColor?.resolve(states),
            borderRadius: radius,
          ),
          child: ClipRRect(
            borderRadius: radius,
            // The bar is a third of the rail wide, so translations are in
            // bar-widths: -1 is one bar-width off-screen to the left, and 3 is
            // three bar-widths right, which is the full rail.
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1 / 3,
              heightFactor: 1,
              child: AnimatedBuilder(
                animation: _controller,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: style.indicatorColor?.resolve(states),
                    borderRadius: radius,
                  ),
                ),
                builder: (BuildContext context, Widget? child) =>
                    FractionalTranslation(
                      translation: Offset(
                        -1 + 4 * Curves.easeInOut.transform(_controller.value),
                        0,
                      ),
                      child: child,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// #enddocregion components-progressbar--motion-custom

// #docregion components-progressbar--max
// `FluentProgressBar` takes a fraction rather than a `max`, so the count is
// divided by the maximum here. Upstream steps the count on a 100ms interval;
// a repeating `AnimationController` is the same clock without a timer to leak.
Widget _max(BuildContext context) => const _Max();

const int _maxValue = 42;
const int _intervalDelay = 100;

class _Max extends StatefulWidget {
  const _Max();

  @override
  State<_Max> createState() => _MaxState();
}

class _MaxState extends State<_Max> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _intervalDelay * (_maxValue + 1)),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (BuildContext context, Widget? child) {
      final int value = (_controller.value * (_maxValue + 1)).floor().clamp(
        0,
        _maxValue,
      );
      return FluentField(
        validationMessage: Text('There have been $value files downloaded'),
        validationState: FluentFieldValidationState.none,
        child: FluentProgressBar(value: value / _maxValue),
      );
    },
  );
}
// #enddocregion components-progressbar--max

// #docregion components-progressbar--shape
// Upstream's `shape` prop is a style override here: `square` is the default
// pill radius replaced with a zero one.
Widget _shape(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    FluentField(
      validationMessage: Text('Rounded ProgressBar'),
      validationState: FluentFieldValidationState.none,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: FluentProgressBar(value: 0.5, size: FluentProgressBarSize.large),
      ),
    ),
    FluentField(
      validationMessage: Text('Square ProgressBar'),
      validationState: FluentFieldValidationState.none,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: FluentProgressBar(
          value: 0.5,
          size: FluentProgressBarSize.large,
          style: FluentProgressBarStyle(
            borderRadius: WidgetStatePropertyAll<BorderRadius?>(
              BorderRadius.zero,
            ),
          ),
        ),
      ),
    ),
  ],
);
// #enddocregion components-progressbar--shape

// #docregion components-progressbar--thickness
// Upstream's `thickness` prop is our `size`: medium is 2 high, large is 4.
Widget _thickness(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    FluentField(
      validationMessage: Text('Medium ProgressBar'),
      validationState: FluentFieldValidationState.none,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: FluentProgressBar(
          value: 0.7,
          size: FluentProgressBarSize.medium,
        ),
      ),
    ),
    FluentField(
      validationMessage: Text('Large ProgressBar'),
      validationState: FluentFieldValidationState.none,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: FluentProgressBar(value: 0.7, size: FluentProgressBarSize.large),
      ),
    ),
  ],
);
// #enddocregion components-progressbar--thickness
