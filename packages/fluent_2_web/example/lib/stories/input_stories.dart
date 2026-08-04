import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentInput].
final StorySection inputStories = StorySection(
  component: 'Input',
  description:
      'A single-line text field: the plainest way to ask for a value the '
      'reader has to type — a name, an address, a search term.',
  stories: <Story>[
    Story(
      name: 'Default',
      description:
          'Every design axis and every state on one field: the fill '
          'treatment, the type ramp, and the three states the component '
          'reports.',
      knobs: const <Knob<Object?>>[
        OptionKnob<FluentInputAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentInputAppearance.outline,
          options: FluentInputAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentInputSize>(
          label: 'Size',
          id: 'size',
          initial: FluentInputSize.medium,
          options: FluentInputSize.values,
          labelOf: _sizeLabel,
        ),
        BoolKnob(label: 'Disabled', id: 'disabled'),
        BoolKnob(label: 'Read only', id: 'readOnly'),
        BoolKnob(label: 'Error', id: 'error'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _Field(
          child: FluentInput(
            appearance: knobs.get<FluentInputAppearance>(
              'appearance',
              FluentInputAppearance.outline,
            ),
            size: knobs.get<FluentInputSize>('size', FluentInputSize.medium),
            enabled: !knobs.get<bool>('disabled', false),
            readOnly: knobs.get<bool>('readOnly', false),
            error: knobs.get<bool>('error', false),
            placeholder: const Text('Your display name'),
            semanticLabel: 'Display name',
          ),
        );
      },
    ),
    Story(
      name: 'Appearances',
      description:
          'Outline draws a box plus an accessible-contrast rule along its '
          'bottom edge, underline draws only that rule, and the two filled '
          'treatments sit on a neutral surface with neither.',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          for (final appearance in FluentInputAppearance.values)
            _Captioned(
              caption: _appearanceLabel(appearance),
              child: FluentInput(
                appearance: appearance,
                placeholder: const Text('Your display name'),
                semanticLabel: 'Display name',
              ),
            ),
        ],
      ),
    ),
    Story(
      name: 'Sizes',
      description:
          'Three heights — 24, 32 and 40 — each pulling its own type ramp '
          'step and its own horizontal inset.',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          for (final size in FluentInputSize.values)
            _Captioned(
              caption: _sizeLabel(size),
              child: FluentInput(
                size: size,
                placeholder: const Text('Your display name'),
                semanticLabel: 'Display name',
              ),
            ),
        ],
      ),
    ),
    Story(
      name: 'Placeholder',
      description:
          'The placeholder is a hint painted under the caret while the value '
          'is empty; it is not a label, so name the field as well.',
      builder: (context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          _Captioned(
            caption: 'Empty — the hint shows',
            child: FluentInput(
              placeholder: Text('Your display name'),
              semanticLabel: 'Display name',
            ),
          ),
          _Captioned(
            caption: 'Holding a value — the hint is gone',
            child: _SeededInput(
              text: 'Ada Lovelace',
              placeholder: 'Your display name',
            ),
          ),
        ],
      ),
    ),
    Story(
      name: 'Content before and after',
      description:
          'Two slots either side of the editable area, tinted and sized by '
          'the field: a prefix, a suffix, or a live control.',
      builder: (context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          _Captioned(
            caption: 'Before',
            child: FluentInput(
              contentBefore: Text(r'$'),
              placeholder: Text('0.00'),
              semanticLabel: 'Amount',
            ),
          ),
          _Captioned(
            caption: 'After',
            child: FluentInput(
              contentAfter: Text('kg'),
              placeholder: Text('0'),
              semanticLabel: 'Weight',
            ),
          ),
          _Captioned(
            caption: 'Both',
            child: FluentInput(
              contentBefore: Text('https://'),
              contentAfter: Text('.com'),
              placeholder: Text('example'),
              semanticLabel: 'Domain',
            ),
          ),
          _Captioned(
            caption: 'A button in the after slot',
            child: _ClearableInput(),
          ),
        ],
      ),
    ),
    Story(
      name: 'Types',
      description:
          'What the field asks the platform for: an obscured value, and the '
          'keyboard suited to an address, a number or a phone number.',
      builder: (context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          _Captioned(caption: 'Password', child: _PasswordInput()),
          _Captioned(
            caption: 'Email',
            child: FluentInput(
              keyboardType: TextInputType.emailAddress,
              placeholder: Text('you@example.com'),
              semanticLabel: 'Email address',
            ),
          ),
          _Captioned(
            caption: 'Number',
            child: FluentInput(
              keyboardType: TextInputType.number,
              placeholder: Text('42'),
              semanticLabel: 'Quantity',
            ),
          ),
          _Captioned(
            caption: 'Phone',
            child: FluentInput(
              keyboardType: TextInputType.phone,
              placeholder: Text('+44 20 7946 0000'),
              semanticLabel: 'Phone number',
            ),
          ),
        ],
      ),
    ),
    Story(
      name: 'Disabled and read only',
      description:
          'Both refuse edits and share one chrome, but read only keeps its '
          'focus bar, its selection and full text contrast.',
      builder: (context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          _Captioned(
            caption: 'Disabled — dimmed text, no focus bar',
            child: _SeededInput(text: 'Ada Lovelace', enabled: false),
          ),
          _Captioned(
            caption: 'Read only — focusable and selectable',
            child: _SeededInput(text: 'Ada Lovelace', readOnly: true),
          ),
          _Captioned(
            caption: 'Disabled and empty',
            child: FluentInput(
              enabled: false,
              placeholder: Text('Your display name'),
              semanticLabel: 'Display name',
            ),
          ),
        ],
      ),
    ),
    Story(
      name: 'Error',
      description:
          'The error state swaps every visible stroke for the danger border, '
          'on each appearance that draws one.',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.l,
        children: <Widget>[
          for (final appearance in FluentInputAppearance.values)
            _Captioned(
              caption: _appearanceLabel(appearance),
              child: FluentInput(
                appearance: appearance,
                error: true,
                placeholder: const Text('Your display name'),
                semanticLabel: 'Display name',
              ),
            ),
        ],
      ),
    ),
    Story(
      name: 'Controlled',
      description:
          'A caller-owned controller seeds the value and can rewrite it from '
          'outside, while onChanged reports every edit back.',
      builder: (context) => const _ControlledInput(),
    ),
    Story(
      name: 'Uncontrolled',
      description:
          'With no controller the field owns its own value; onChanged is the '
          'only way the value leaves it.',
      builder: (context) => const _UncontrolledInput(),
    ),
    Story(
      name: 'Inline',
      description:
          'The field placed in a run of prose rather than on its own line, at '
          'the small size so it sits on the text baseline.',
      builder: (context) {
        final theme = FluentTheme.of(context);
        return Text.rich(
          TextSpan(
            children: <InlineSpan>[
              const TextSpan(text: 'Remind me in '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                // The field fills whatever width it is given — it has no
                // content-sized mode — so an inline one needs a width.
                child: SizedBox(
                  width: 56,
                  child: FluentInput(
                    size: FluentInputSize.small,
                    placeholder: const Text('10'),
                    keyboardType: TextInputType.number,
                    semanticLabel: 'Minutes',
                  ),
                ),
              ),
              const TextSpan(text: ' minutes.'),
            ],
          ),
          style: theme.typography.body1.copyWith(
            color: theme.colors.neutralForeground1,
          ),
        );
      },
    ),
  ],
);

// Both label functions take `Object?` rather than their own enum on purpose:
// the knob panel reads `OptionKnob.labelOf` through `OptionKnob<Object?>`, and
// a `String Function(FluentInputAppearance)` fails that cast at runtime. The
// switch is still exhaustive — the cast is inside it.

String _appearanceLabel(Object? appearance) =>
    switch (appearance! as FluentInputAppearance) {
      FluentInputAppearance.outline => 'Outline',
      FluentInputAppearance.underline => 'Underline',
      FluentInputAppearance.filledDarker => 'Filled darker',
      FluentInputAppearance.filledLighter => 'Filled lighter',
    };

String _sizeLabel(Object? size) => switch (size! as FluentInputSize) {
  FluentInputSize.small => 'Small',
  FluentInputSize.medium => 'Medium',
  FluentInputSize.large => 'Large',
};

/// Gives a field a sensible reading width — it would otherwise stretch across
/// the whole canvas.
class _Field extends StatelessWidget {
  const _Field({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(width: 280, child: child);
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

/// A field holding text from the start.
///
/// [FluentInput] takes no initial value, so anything with content in it needs a
/// controller — and a controller needs an owner that disposes it.
class _SeededInput extends StatefulWidget {
  const _SeededInput({
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
  State<_SeededInput> createState() => _SeededInputState();
}

class _SeededInputState extends State<_SeededInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FluentInput(
    controller: _controller,
    placeholder: widget.placeholder == null ? null : Text(widget.placeholder!),
    enabled: widget.enabled,
    readOnly: widget.readOnly,
    semanticLabel: 'Display name',
  );
}

/// A field whose after-slot holds a button that empties it.
class _ClearableInput extends StatefulWidget {
  const _ClearableInput();

  @override
  State<_ClearableInput> createState() => _ClearableInputState();
}

class _ClearableInputState extends State<_ClearableInput> {
  final TextEditingController _controller = TextEditingController(
    text: 'Ada Lovelace',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FluentInput(
    controller: _controller,
    placeholder: const Text('Your display name'),
    semanticLabel: 'Display name',
    contentAfter: FluentButton(
      appearance: FluentButtonAppearance.subtle,
      size: FluentButtonSize.small,
      onPressed: _controller.clear,
      child: const Text('Clear'),
    ),
  );
}

/// An obscured field with a control that reveals the value.
class _PasswordInput extends StatefulWidget {
  const _PasswordInput();

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) => FluentInput(
    obscureText: _obscured,
    placeholder: const Text('Password'),
    semanticLabel: 'Password',
    contentAfter: FluentButton(
      appearance: FluentButtonAppearance.subtle,
      size: FluentButtonSize.small,
      onPressed: () => setState(() => _obscured = !_obscured),
      child: Text(_obscured ? 'Show' : 'Hide'),
    ),
  );
}

/// A field whose value is mirrored outside it and can be rewritten from a
/// button.
class _ControlledInput extends StatefulWidget {
  const _ControlledInput();

  @override
  State<_ControlledInput> createState() => _ControlledInputState();
}

class _ControlledInputState extends State<_ControlledInput> {
  static const String _seed = 'Ada Lovelace';

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
          child: FluentInput(
            controller: _controller,
            placeholder: const Text('Your display name'),
            semanticLabel: 'Display name',
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

/// A field with no controller: the value lives inside the widget, and only
/// onChanged and onSubmitted see it.
class _UncontrolledInput extends StatefulWidget {
  const _UncontrolledInput();

  @override
  State<_UncontrolledInput> createState() => _UncontrolledInputState();
}

class _UncontrolledInputState extends State<_UncontrolledInput> {
  String _submitted = '';

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: <Widget>[
        _Field(
          child: FluentInput(
            placeholder: const Text('Your display name'),
            semanticLabel: 'Display name',
            onSubmitted: (value) => setState(() => _submitted = value),
          ),
        ),
        Text(
          _submitted.isEmpty
              ? 'Type something and press Enter.'
              : 'Submitted: $_submitted',
          style: theme.typography.body1.copyWith(
            color: theme.colors.neutralForeground2,
          ),
        ),
      ],
    );
  }
}
