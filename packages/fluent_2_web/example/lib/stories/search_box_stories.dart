import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentSearchBox].
final StorySection searchBoxStories = StorySection(
  component: 'SearchBox',
  description:
      'A single-line field for querying a list — a text input with a leading '
      'magnifier and a clear affordance that appears while the field has '
      'focus.',
  stories: <Story>[
    Story(
      name: 'Default',
      description:
          'Every design axis on one field, plus the states the component '
          'reports for itself: hover, focus and disabled.',
      knobs: const <Knob<Object?>>[
        OptionKnob<FluentSearchBoxAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentSearchBoxAppearance.outline,
          options: FluentSearchBoxAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentSearchBoxSize>(
          label: 'Size',
          id: 'size',
          initial: FluentSearchBoxSize.medium,
          options: FluentSearchBoxSize.values,
          labelOf: _sizeLabel,
        ),
        TextKnob(label: 'Placeholder', id: 'placeholder', initial: 'Search'),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _Field(
          child: FluentSearchBox(
            appearance: knobs.get(
              'appearance',
              FluentSearchBoxAppearance.outline,
            ),
            size: knobs.get('size', FluentSearchBoxSize.medium),
            enabled: !knobs.get('disabled', false),
            placeholder: knobs.get('placeholder', 'Search'),
          ),
        );
      },
    ),
    Story(
      name: 'Appearances',
      description:
          'Four fill treatments. Outline and transparent carry the heavier '
          'accessible rule along the bottom edge; the two filled ones carry a '
          'fill instead and no rule at all.',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          for (final appearance in FluentSearchBoxAppearance.values)
            _Captioned(
              caption: _appearanceLabel(appearance),
              child: FluentSearchBox(
                appearance: appearance,
                placeholder: 'Search',
              ),
            ),
        ],
      ),
    ),
    Story(
      name: 'Sizes',
      description:
          'Three heights — 24, 32 and 40 — each with its own type ramp, inset '
          'and glyph size.',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          for (final size in FluentSearchBoxSize.values)
            _Captioned(
              caption: _sizeLabel(size),
              child: FluentSearchBox(size: size, placeholder: 'Search'),
            ),
        ],
      ),
    ),
    Story(
      name: 'Placeholder',
      description:
          'The placeholder is a hint painted under the caret while the value '
          'is empty, and vanishes on the first character typed.',
      builder: (context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          _Captioned(
            caption: 'Empty — the hint shows',
            child: FluentSearchBox(placeholder: 'Search files'),
          ),
          _Captioned(
            caption: 'Holding a value — the hint is gone',
            child: _SeededSearchBox(
              text: 'quarterly report',
              placeholder: 'Search files',
            ),
          ),
          _Captioned(
            caption: 'No placeholder at all',
            child: FluentSearchBox(),
          ),
        ],
      ),
    ),
    Story(
      name: 'Disabled',
      description:
          'A real state rather than a dimming: the field refuses focus and '
          'input, drops the bottom rule, hides the clear button and swaps to '
          'the disabled token ramp wholesale.',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          for (final appearance in FluentSearchBoxAppearance.values)
            _Captioned(
              caption: _appearanceLabel(appearance),
              child: FluentSearchBox(
                appearance: appearance,
                enabled: false,
                placeholder: 'Search',
              ),
            ),
          const _Captioned(
            caption: 'Disabled while holding a value',
            child: _SeededSearchBox(text: 'quarterly report', enabled: false),
          ),
        ],
      ),
    ),
    Story(
      name: 'Clearing',
      description:
          'The clear button appears while focus is inside the control, hands '
          'focus straight back to the field, and reports through onClear. '
          'Escape does the same from the keyboard.',
      builder: (context) => const _ClearableSearchBox(),
    ),
    Story(
      name: 'Controlled',
      description:
          'A caller-owned controller seeds the value and drives it from '
          'outside, while every edit reports back through onChanged.',
      builder: (context) => const _ControlledSearchBox(),
    ),
    Story(
      name: 'Glyph slots',
      description:
          'The leading magnifier and the trailing dismiss cross are both '
          'replaceable widgets — and the leading slot can be emptied outright.',
      builder: (context) {
        final theme = FluentTheme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: FluentSpacing.l,
          children: <Widget>[
            const _Captioned(
              caption: 'Default — a painted Search20Regular',
              child: FluentSearchBox(placeholder: 'Search'),
            ),
            const _Captioned(
              caption: 'No leading glyph — an empty box in the slot',
              child: FluentSearchBox(
                icon: SizedBox.shrink(),
                placeholder: 'Search',
              ),
            ),
            _Captioned(
              caption: 'A brand-toned leading glyph',
              child: FluentSearchBox(
                placeholder: 'Search',
                icon: CustomPaint(
                  painter: FluentSearchBoxGlyphPainter(
                    glyph: FluentSearchBoxGlyph.search,
                    color: theme.colors.brandForeground1,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  ],
);

String _appearanceLabel(FluentSearchBoxAppearance appearance) =>
    switch (appearance) {
      FluentSearchBoxAppearance.filledDarker => 'Filled darker',
      FluentSearchBoxAppearance.filledLighter => 'Filled lighter',
      FluentSearchBoxAppearance.outline => 'Outline',
      FluentSearchBoxAppearance.transparent => 'Transparent',
    };

String _sizeLabel(FluentSearchBoxSize size) => switch (size) {
  FluentSearchBoxSize.small => 'Small',
  FluentSearchBoxSize.medium => 'Medium',
  FluentSearchBoxSize.large => 'Large',
};

/// Gives a search box a realistic width — it would otherwise stretch to the
/// 468 cap on every canvas wider than that.
class _Field extends StatelessWidget {
  const _Field({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(width: 320, child: child);
}

/// One example under a small label naming the variant it shows.
class _Captioned extends StatelessWidget {
  const _Captioned({required this.caption, required this.child});

  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.xs,
    children: <Widget>[
      FluentLabel(size: FluentLabelSize.small, child: Text(caption)),
      _Field(child: child),
    ],
  );
}

/// A search box holding text from the start.
///
/// [FluentSearchBox] takes no initial value, so anything with content in it
/// needs a controller — and a controller needs an owner that disposes it.
class _SeededSearchBox extends StatefulWidget {
  const _SeededSearchBox({
    required this.text,
    this.placeholder,
    this.enabled = true,
  });

  final String text;
  final String? placeholder;
  final bool enabled;

  @override
  State<_SeededSearchBox> createState() => _SeededSearchBoxState();
}

class _SeededSearchBoxState extends State<_SeededSearchBox> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FluentSearchBox(
    controller: _controller,
    placeholder: widget.placeholder,
    enabled: widget.enabled,
  );
}

/// A field that counts how often it has been cleared, by button or by Escape.
class _ClearableSearchBox extends StatefulWidget {
  const _ClearableSearchBox();

  @override
  State<_ClearableSearchBox> createState() => _ClearableSearchBoxState();
}

class _ClearableSearchBoxState extends State<_ClearableSearchBox> {
  final TextEditingController _controller = TextEditingController(
    text: 'quarterly report',
  );
  int _clears = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: <Widget>[
        _Field(
          child: FluentSearchBox(
            controller: _controller,
            placeholder: 'Search files',
            onClear: () => setState(() => _clears++),
          ),
        ),
        Text(
          _clears == 0
              ? 'Click into the field: the dismiss cross appears on focus.'
              : 'Cleared $_clears time${_clears == 1 ? '' : 's'}.',
          style: theme.typography.body1.copyWith(
            color: theme.colors.neutralForeground2,
          ),
        ),
      ],
    );
  }
}

/// A field whose value is mirrored outside it and can be driven from buttons.
class _ControlledSearchBox extends StatefulWidget {
  const _ControlledSearchBox();

  @override
  State<_ControlledSearchBox> createState() => _ControlledSearchBoxState();
}

class _ControlledSearchBoxState extends State<_ControlledSearchBox> {
  static const String _seed = 'quarterly report';

  final TextEditingController _controller = TextEditingController(text: _seed);
  String _value = _seed;
  String? _submitted;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(String value) {
    _controller.text = value;
    setState(() => _value = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final caption = theme.typography.body1.copyWith(
      color: theme.colors.neutralForeground2,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: <Widget>[
        _Field(
          child: FluentSearchBox(
            controller: _controller,
            placeholder: 'Search files',
            onChanged: (value) => setState(() => _value = value),
            onSubmitted: (value) => setState(() => _submitted = value),
          ),
        ),
        Text(_value.isEmpty ? 'The field is empty.' : _value, style: caption),
        Text(
          _submitted == null
              ? 'Press Enter to submit.'
              : 'Submitted: $_submitted',
          style: caption,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.s,
          children: <Widget>[
            FluentButton(onPressed: () => _set(''), child: const Text('Clear')),
            FluentButton(
              onPressed: () => _set(_seed),
              child: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }
}
