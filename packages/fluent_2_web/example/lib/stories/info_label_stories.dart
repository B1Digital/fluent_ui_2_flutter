import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentInfoLabel].
final StorySection infoLabelStories = StorySection(
  component: 'InfoLabel',
  description:
      'A label with an information trigger after it: the field name, plus the '
      'explanation that would otherwise crowd the form.',
  stories: [
    Story(
      name: 'Default',
      description:
          'The whole component on one row — label, optional asterisk, trigger. '
          'Turn the trigger off and it is a plain label, which is exactly what '
          'the component renders when it has nothing to explain.',
      knobs: const [
        TextKnob(label: 'Label', id: 'label', initial: 'Retention'),
        BoolKnob(label: 'With info', id: 'info', initial: true),
        OptionKnob<FluentLabelSize>(
          label: 'Size',
          id: 'size',
          initial: FluentLabelSize.medium,
          options: FluentLabelSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentLabelWeight>(
          label: 'Weight',
          id: 'weight',
          initial: FluentLabelWeight.regular,
          options: FluentLabelWeight.values,
          labelOf: _weightLabel,
        ),
        BoolKnob(label: 'Required', id: 'required'),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        final withInfo = knobs.get<bool>('info', true);
        return FluentInfoLabel(
          size: knobs.get<FluentLabelSize>('size', FluentLabelSize.medium),
          weight: knobs.get<FluentLabelWeight>(
            'weight',
            FluentLabelWeight.regular,
          ),
          required: knobs.get<bool>('required', false),
          disabled: knobs.get<bool>('disabled', false),
          infoSemanticLabel: withInfo ? _semanticLabel : null,
          info: withInfo ? const Text(_tip) : null,
          child: Text(knobs.get<String>('label', 'Retention')),
        );
      },
    ),
    const Story(
      name: 'Sizes',
      description:
          'One size axis drives both halves: the label moves up the type ramp '
          'and the trigger box grows with it, 20px at small and 24 above.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Required',
      description:
          'The asterisk belongs to the label, so it lands between the text and '
          'the trigger rather than at the end of the row.',
      builder: _requiredBuilder,
    ),
    const Story(
      name: 'Disabled',
      description:
          'Disabling is a real state, not a fade: the label and asterisk take '
          'the disabled token and the trigger refuses focus and taps.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'In a field',
      description:
          'Used as a form label: the trigger carries the explanation that would '
          'otherwise have to live in the hint under the control.',
      builder: _inFieldBuilder,
    ),
  ],
);

const String _tip =
    'Deleted items are kept for this long, then removed for '
    'good. Changing it does not restore anything already gone.';

const String _semanticLabel = 'About the retention period';

String _sizeLabel(FluentLabelSize value) => value.name;

String _weightLabel(FluentLabelWeight value) => value.name;

Widget _sizesBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Small',
      FluentInfoLabel(
        size: FluentLabelSize.small,
        infoSemanticLabel: _semanticLabel,
        info: Text(_tip),
        child: Text('Retention'),
      ),
    ),
    (
      'Medium',
      FluentInfoLabel(
        infoSemanticLabel: _semanticLabel,
        info: Text(_tip),
        child: Text('Retention'),
      ),
    ),
    (
      // Figma draws its Large variant semibold, because the Label set ships no
      // large + regular pair — the weight is the label's own, not a rule the
      // info label imposes.
      'Large',
      FluentInfoLabel(
        size: FluentLabelSize.large,
        weight: FluentLabelWeight.semibold,
        infoSemanticLabel: _semanticLabel,
        info: Text(_tip),
        child: Text('Retention'),
      ),
    ),
  ],
);

Widget _requiredBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Optional',
      FluentInfoLabel(
        infoSemanticLabel: _semanticLabel,
        info: Text(_tip),
        child: Text('Retention'),
      ),
    ),
    (
      'Required',
      FluentInfoLabel(
        required: true,
        infoSemanticLabel: _semanticLabel,
        info: Text(_tip),
        child: Text('Retention'),
      ),
    ),
  ],
);

Widget _disabledBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Enabled',
      FluentInfoLabel(
        required: true,
        infoSemanticLabel: _semanticLabel,
        info: Text(_tip),
        child: Text('Retention'),
      ),
    ),
    (
      'Disabled',
      FluentInfoLabel(
        required: true,
        disabled: true,
        infoSemanticLabel: _semanticLabel,
        info: Text(_tip),
        child: Text('Retention'),
      ),
    ),
  ],
);

Widget _inFieldBuilder(BuildContext context) => const _RetentionField();

/// A field whose label is an info label.
///
/// [FluentField] composes its own [FluentLabel] around whatever it is handed,
/// so an info label goes in through the recomposition contract instead: our
/// state, Fluent's resolved style, Fluent's rendering. The label's weight and
/// size are the ones [resolveFluentFieldState] would have chosen for a medium
/// field.
class _RetentionField extends StatelessWidget {
  const _RetentionField();

  @override
  Widget build(BuildContext context) {
    const state = FluentFieldState(
      enabled: true,
      size: FluentFieldSize.medium,
      validationState: FluentFieldValidationState.none,
      label: FluentInfoLabel(
        infoSemanticLabel: _semanticLabel,
        info: Text(_tip),
        child: Text('Retention'),
      ),
      hint: Text('Applies to every mailbox in the organisation.'),
      child: FluentInput(placeholder: Text('30 days')),
    );

    return SizedBox(
      width: 280,
      child: buildFluentField(
        state,
        resolveFluentFieldStyle(state, FluentTheme.of(context)),
        const <WidgetState>{},
      ),
    );
  }
}

/// Side-by-side cases under a caption.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.xxl,
      runSpacing: FluentSpacing.l,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (final (caption, child) in children)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}
