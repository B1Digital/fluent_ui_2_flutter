import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentTextarea].
final StorySection textareaStories = StorySection(
  component: 'Textarea',
  description:
      'A multi-line text input for free-form prose — a comment, a note or a '
      'description that will not fit on one line.',
  stories: <Story>[
    Story(
      name: 'Default',
      description:
          'The whole design surface on one field: fill treatment, type ramp '
          'and every state the component reports.',
      knobs: const <Knob<Object?>>[
        OptionKnob<FluentTextareaAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentTextareaAppearance.outline,
          options: FluentTextareaAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentTextareaSize>(
          label: 'Size',
          id: 'size',
          initial: FluentTextareaSize.medium,
          options: FluentTextareaSize.values,
          labelOf: _sizeLabel,
        ),
        BoolKnob(label: 'Disabled', id: 'disabled'),
        BoolKnob(label: 'Read only', id: 'readOnly'),
        BoolKnob(label: 'Invalid', id: 'invalid'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _Field(
          child: FluentTextarea(
            appearance: knobs.get(
              'appearance',
              FluentTextareaAppearance.outline,
            ),
            size: knobs.get('size', FluentTextareaSize.medium),
            enabled: !knobs.get('disabled', false),
            readOnly: knobs.get('readOnly', false),
            invalid: knobs.get('invalid', false),
            placeholder: 'Tell us what happened',
          ),
        );
      },
    ),
    Story(
      name: 'Appearances',
      description:
          'Outline carries a border and a heavier accessible rule along its '
          'bottom edge; the two filled treatments carry neither.',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          for (final appearance in FluentTextareaAppearance.values)
            _Captioned(
              caption: _appearanceLabel(appearance),
              child: FluentTextarea(
                appearance: appearance,
                placeholder: 'Tell us what happened',
              ),
            ),
        ],
      ),
    ),
    Story(
      name: 'Sizes',
      description:
          'Three steps of the type ramp, each with its own inset — 12/16, '
          '14/20 and 16/22.',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          for (final size in FluentTextareaSize.values)
            _Captioned(
              caption: _sizeLabel(size),
              child: FluentTextarea(
                size: size,
                placeholder: 'Tell us what happened',
              ),
            ),
        ],
      ),
    ),
    Story(
      name: 'Placeholder',
      description:
          'The placeholder is a hint painted under the caret while the field '
          'is empty, and disappears on the first character typed.',
      builder: (context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          _Captioned(
            caption: 'Empty',
            child: FluentTextarea(placeholder: 'Tell us what happened'),
          ),
          _Captioned(
            caption: 'Holding a value',
            child: _SeededTextarea(
              text: 'The build fell over on the second retry.',
              placeholder: 'Tell us what happened',
            ),
          ),
        ],
      ),
    ),
    Story(
      name: 'Disabled and read only',
      description:
          'Both refuse edits and drop to the same chrome, but read only stays '
          'focusable, selectable and at full text contrast.',
      builder: (context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          _Captioned(
            caption: 'Disabled — skipped by Tab, text dimmed',
            child: _SeededTextarea(
              text: 'The build fell over on the second retry.',
              enabled: false,
            ),
          ),
          _Captioned(
            caption: 'Read only — focusable and selectable',
            child: _SeededTextarea(
              text: 'The build fell over on the second retry.',
              readOnly: true,
            ),
          ),
        ],
      ),
    ),
    Story(
      name: 'Controlled',
      description:
          'A caller-owned controller seeds the initial text, and every edit '
          'reports back through onChanged.',
      builder: (context) => const _ControlledTextarea(),
    ),
    Story(
      name: 'Invalid',
      description:
          'The error state swaps the border for the danger stroke and drops '
          'the resting bottom rule, on every appearance.',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          for (final appearance in FluentTextareaAppearance.values)
            _Captioned(
              caption: _appearanceLabel(appearance),
              child: FluentTextarea(
                appearance: appearance,
                invalid: true,
                placeholder: 'Tell us what happened',
              ),
            ),
        ],
      ),
    ),
    Story(
      name: 'Height',
      description:
          'minLines and maxLines size the field and decide when it starts '
          'scrolling internally — Flutter\'s answer to the CSS resize handle.',
      knobs: const <Knob<Object?>>[
        NumberKnob(
          label: 'Min lines',
          id: 'minLines',
          initial: 2,
          min: 1,
          max: 8,
        ),
        NumberKnob(
          label: 'Max lines',
          id: 'maxLines',
          initial: 4,
          min: 1,
          max: 8,
        ),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        final minLines = knobs.get('minLines', 2.0).round();
        final maxLines = knobs.get('maxLines', 4.0).round();
        return _Field(
          child: FluentTextarea(
            minLines: minLines,
            // The widget asserts maxLines >= minLines, so the two knobs are
            // reconciled here rather than left to crash the story.
            maxLines: maxLines < minLines ? minLines : maxLines,
            placeholder: 'Tell us what happened',
          ),
        );
      },
    ),
    Story(
      name: 'Character limit',
      description:
          'maxLength caps the value with an input formatter, so the field '
          'simply stops accepting characters past the limit.',
      builder: (context) => const _CountedTextarea(),
    ),
  ],
);

String _appearanceLabel(FluentTextareaAppearance appearance) =>
    switch (appearance) {
      FluentTextareaAppearance.outline => 'Outline',
      FluentTextareaAppearance.filledDarker => 'Filled darker',
      FluentTextareaAppearance.filledLighter => 'Filled lighter',
    };

String _sizeLabel(FluentTextareaSize size) => switch (size) {
  FluentTextareaSize.small => 'Small',
  FluentTextareaSize.medium => 'Medium',
  FluentTextareaSize.large => 'Large',
};

/// Gives a textarea a sensible reading width — it would otherwise stretch to
/// the whole canvas.
class _Field extends StatelessWidget {
  const _Field({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(width: 360, child: child);
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

/// A textarea holding text from the start.
///
/// [FluentTextarea] takes no initial value, so anything with content in it
/// needs a controller — and a controller needs an owner that disposes it.
class _SeededTextarea extends StatefulWidget {
  const _SeededTextarea({
    required this.text,
    this.placeholder,
    this.enabled = true,
    this.readOnly = false,
  });

  final String text;
  final String? placeholder;
  final bool enabled;
  final bool readOnly;

  @override
  State<_SeededTextarea> createState() => _SeededTextareaState();
}

class _SeededTextareaState extends State<_SeededTextarea> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FluentTextarea(
    controller: _controller,
    placeholder: widget.placeholder,
    enabled: widget.enabled,
    readOnly: widget.readOnly,
  );
}

/// A field whose value is mirrored outside it and can be cleared from a button.
class _ControlledTextarea extends StatefulWidget {
  const _ControlledTextarea();

  @override
  State<_ControlledTextarea> createState() => _ControlledTextareaState();
}

class _ControlledTextareaState extends State<_ControlledTextarea> {
  static const String _seed = 'The build fell over on the second retry.';

  final TextEditingController _controller = TextEditingController(text: _seed);
  String _value = _seed;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: <Widget>[
        _Field(
          child: FluentTextarea(
            controller: _controller,
            placeholder: 'Tell us what happened',
            onChanged: (value) => setState(() => _value = value),
          ),
        ),
        Text(
          _value.isEmpty ? 'The field is empty.' : _value,
          style: theme.typography.body1.copyWith(
            color: theme.colors.neutralForeground2,
          ),
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

/// A capped field with a live count of how much of the budget is left.
class _CountedTextarea extends StatefulWidget {
  const _CountedTextarea();

  @override
  State<_CountedTextarea> createState() => _CountedTextareaState();
}

class _CountedTextareaState extends State<_CountedTextarea> {
  static const int _limit = 80;

  int _length = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.xs,
    children: <Widget>[
      _Field(
        child: FluentTextarea(
          maxLength: _limit,
          placeholder: 'Tell us what happened',
          onChanged: (value) => setState(() => _length = value.length),
        ),
      ),
      FluentLabel(
        size: FluentLabelSize.small,
        child: Text('$_length / $_limit'),
      ),
    ],
  );
}
