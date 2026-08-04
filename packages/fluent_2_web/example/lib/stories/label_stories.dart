import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentLabel].
final StorySection labelStories = StorySection(
  component: 'Label',
  description:
      'The text that names a form field: three type ramp steps, two weights, '
      'an optional required-field asterisk, and a disabled colour resolved '
      'from a token rather than faded.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every design axis at once — 14/20 regular out of the box, with the '
          'text, size, weight, asterisk and disabled state all live.',
      knobs: const [
        TextKnob(label: 'Text', id: 'text', initial: 'Email address'),
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
        return FluentLabel(
          size: knobs.get<FluentLabelSize>('size', FluentLabelSize.medium),
          weight: knobs.get<FluentLabelWeight>(
            'weight',
            FluentLabelWeight.regular,
          ),
          required: knobs.get<bool>('required', false),
          disabled: knobs.get<bool>('disabled', false),
          child: Text(knobs.get<String>('text', 'Email address')),
        );
      },
    ),
    const Story(
      name: 'Sizes',
      description:
          'Three steps of the type ramp: small is 12/16 caption, medium 14/20 '
          'body, large 16/22. Only the type changes — there is no padding to '
          'grow with it.',
      builder: _sizesBuilder,
    ),
    Story(
      name: 'Weights',
      description:
          'Regular names a field inside dense content; semibold is the usual '
          'choice above an input. Change the size to see the pairing at each '
          'ramp step.',
      knobs: const [
        OptionKnob<FluentLabelSize>(
          label: 'Size',
          id: 'size',
          initial: FluentLabelSize.medium,
          options: FluentLabelSize.values,
          labelOf: _sizeLabel,
        ),
      ],
      builder: (context) {
        final size = KnobsScope.of(
          context,
        ).get<FluentLabelSize>('size', FluentLabelSize.medium);
        return _Cases(
          children: [
            ('Regular', FluentLabel(size: size, child: const Text('Label'))),
            (
              'Semibold',
              FluentLabel(
                size: size,
                weight: FluentLabelWeight.semibold,
                child: const Text('Label'),
              ),
            ),
          ],
        );
      },
    ),
    const Story(
      name: 'Required',
      description:
          'The asterisk is a separate token — the danger foreground, an XS gap '
          'after the text — and is hidden from assistive technology, because '
          'required-ness belongs to the field, not to the name of it.',
      builder: _requiredBuilder,
    ),
    const Story(
      name: 'Disabled',
      description:
          'Disabled swaps in the disabled foreground token rather than fading '
          'the enabled colour, and the asterisk greys along with the text.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Naming a field',
      description:
          'What the component is for: a semibold label above an input, and the '
          'same label greyed when the field it names is disabled.',
      builder: _fieldBuilder,
    ),
    const Story(
      name: 'Custom styling',
      description:
          'Three rungs of override — theme defaults, a FluentLabelTheme over a '
          'subtree, then the widget style, which is merged last and wins.',
      builder: _stylingBuilder,
    ),
  ],
);

String _sizeLabel(FluentLabelSize value) => value.name;

String _weightLabel(FluentLabelWeight value) => value.name;

Widget _sizesBuilder(BuildContext context) => const _Cases(
  children: [
    ('Small', FluentLabel(size: FluentLabelSize.small, child: Text('Label'))),
    ('Medium', FluentLabel(child: Text('Label'))),
    ('Large', FluentLabel(size: FluentLabelSize.large, child: Text('Label'))),
  ],
);

Widget _requiredBuilder(BuildContext context) => const _Cases(
  children: [
    ('Optional', FluentLabel(child: Text('Middle name'))),
    ('Required', FluentLabel(required: true, child: Text('Email address'))),
    (
      'Required, semibold',
      FluentLabel(
        weight: FluentLabelWeight.semibold,
        required: true,
        child: Text('Email address'),
      ),
    ),
  ],
);

Widget _disabledBuilder(BuildContext context) => const _Cases(
  children: [
    ('Enabled', FluentLabel(required: true, child: Text('Email address'))),
    (
      'Disabled',
      FluentLabel(disabled: true, required: true, child: Text('Email address')),
    ),
  ],
);

Widget _fieldBuilder(BuildContext context) => const _Cases(
  children: [('Enabled', _Field()), ('Disabled', _Field(enabled: false))],
);

Widget _stylingBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return FluentLabelTheme(
    style: FluentLabelStyle.from(foregroundColor: colors.brandForeground1),
    child: _Cases(
      children: [
        (
          'Subtree theme',
          const FluentLabel(required: true, child: Text('Label')),
        ),
        (
          'Widget style wins',
          FluentLabel(
            required: true,
            style: FluentLabelStyle.from(
              foregroundColor: colors.neutralForeground2,
              requiredColor: colors.neutralForeground3,
              gap: FluentSpacing.m,
            ),
            child: const Text('Label'),
          ),
        ),
      ],
    ),
  );
}

/// A label naming a real field, which is the composition the component exists
/// for: semibold above the input, and greyed with it when it is disabled.
class _Field extends StatelessWidget {
  const _Field({this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.xs,
      children: [
        FluentLabel(
          weight: FluentLabelWeight.semibold,
          required: true,
          disabled: !enabled,
          child: const Text('Email address'),
        ),
        FluentInput(
          enabled: enabled,
          placeholder: const Text('name@example.com'),
          semanticLabel: 'Email address',
        ),
      ],
    ),
  );
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
