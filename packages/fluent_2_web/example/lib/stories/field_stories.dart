import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentField].
final StorySection fieldStories = StorySection(
  component: 'Field',
  description:
      'The label, hint and validation message around a control. A pure '
      'wrapper: it never inspects the control it holds, so the same field '
      'works around an input, a slider or a radio group.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every row is optional and every design axis is a knob: the label '
          'ramp follows the size, the message and the glyph follow the '
          'validation state, and the hint stays 12/16 throughout.',
      knobs: const [
        TextKnob(label: 'Label', id: 'label', initial: 'Display name'),
        OptionKnob<FluentFieldSize>(
          label: 'Size',
          id: 'size',
          initial: FluentFieldSize.medium,
          options: FluentFieldSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentFieldValidationState>(
          label: 'Validation state',
          id: 'validation',
          initial: FluentFieldValidationState.none,
          options: FluentFieldValidationState.values,
          labelOf: _validationLabel,
        ),
        BoolKnob(label: 'Hint', id: 'hint', initial: true),
        BoolKnob(label: 'Required', id: 'required'),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        final validation = knobs.get<FluentFieldValidationState>(
          'validation',
          FluentFieldValidationState.none,
        );
        final enabled = !knobs.get<bool>('disabled', false);
        final quiet = validation == FluentFieldValidationState.none;

        return SizedBox(
          width: 280,
          child: FluentField(
            size: knobs.get<FluentFieldSize>('size', FluentFieldSize.medium),
            required: knobs.get<bool>('required', false),
            enabled: enabled,
            validationState: validation,
            label: Text(knobs.get<String>('label', 'Display name')),
            hint: knobs.get<bool>('hint', true)
                ? const Text('This is how you appear to other people.')
                : null,
            validationMessage: quiet
                ? null
                : const Text('That name is already taken'),
            validationMessageIcon: quiet ? null : const _ValidationGlyph(),
            child: FluentInput(
              enabled: enabled,
              error: validation == FluentFieldValidationState.error,
              placeholder: const Text('Your name'),
            ),
          ),
        );
      },
    ),
    const Story(
      name: 'Sizes',
      description:
          'Size moves the label ramp and the gap under it — 12/16, 14/20, '
          'then 16/22 semibold — and nothing else: the hint and the '
          'validation message stay 12/16 at all three.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Required',
      description:
          'The asterisk comes from the composed FluentLabel, while the '
          'required-ness itself is published on the field node, so a screen '
          'reader announces "required" rather than reading "Label star".',
      builder: _requiredBuilder,
    ),
    const Story(
      name: 'Hint',
      description:
          'The hint is the last row, under the validation message — that is '
          'the render order, so a message never pushes the hint off the '
          'control it explains.',
      builder: _hintBuilder,
    ),
    Story(
      name: 'Validation states',
      description:
          'Only error recolours the message text; the glyph takes its tint in '
          'all three states. Painting the control itself is the control\'s own '
          'job — the error case here also sets the input\'s error treatment.',
      knobs: const [BoolKnob(label: 'Glyph', id: 'glyph', initial: true)],
      builder: (context) {
        final glyph = KnobsScope.of(context).get<bool>('glyph', true);
        return _Cases(
          children: [
            for (final state in FluentFieldValidationState.values)
              (
                _validationLabel(state),
                SizedBox(
                  width: 240,
                  child: FluentField(
                    validationState: state,
                    label: const Text('Email address'),
                    validationMessage: Text(_messageFor(state)),
                    validationMessageIcon: glyph
                        ? const _ValidationGlyph()
                        : null,
                    child: FluentInput(
                      error: state == FluentFieldValidationState.error,
                      placeholder: const Text('name@example.com'),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Disabled',
      description:
          'Disabling swaps every row onto the disabled token rather than '
          'fading the enabled colours — the error message loses its red '
          'entirely. It does not reach into the control: that has to be '
          'disabled on its own.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Around any control',
      description:
          'The child is any widget and the field never inspects it, so one '
          'wrapper serves the whole input family. The control is stretched to '
          'the field, which needs a bounded width of its own.',
      builder: _controlsBuilder,
    ),
    const Story(
      name: 'Info button on the label',
      description:
          'For a label that is not plain text, build the base state by hand '
          'and put a FluentInfoLabel in the slot — the field then renders it '
          'as given instead of wrapping it in a second label.',
      builder: _infoBuilder,
    ),
    const Story(
      name: 'Restyling',
      description:
          'Three rungs, lowest to highest: the size and validation defaults, '
          'a FluentFieldTheme over a subtree, then the widget\'s own style. '
          'Merging is per-property, so an override keeps every other value.',
      builder: _restyleBuilder,
    ),
  ],
);

String _sizeLabel(FluentFieldSize value) => value.name;

String _validationLabel(FluentFieldValidationState value) => value.name;

/// The message each validation state carries in the stories above.
String _messageFor(FluentFieldValidationState state) => switch (state) {
  FluentFieldValidationState.none => 'We will only use this to sign you in',
  FluentFieldValidationState.error => 'That address is already registered',
  FluentFieldValidationState.warning => 'This looks like a personal address',
  FluentFieldValidationState.success => 'Address confirmed',
};

Widget _sizesBuilder(BuildContext context) => _Cases(
  children: [
    for (final size in FluentFieldSize.values)
      (
        _sizeLabel(size),
        SizedBox(
          width: 240,
          child: FluentField(
            size: size,
            label: const Text('Label'),
            hint: const Text('Helper text stays 12/16'),
            validationMessage: const Text('So does the message'),
            validationMessageIcon: const _ValidationGlyph(),
            child: const FluentInput(placeholder: Text('Placeholder')),
          ),
        ),
      ),
  ],
);

Widget _requiredBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Optional',
      SizedBox(
        width: 240,
        child: FluentField(
          label: Text('Nickname'),
          child: FluentInput(placeholder: Text('Optional')),
        ),
      ),
    ),
    (
      'Required',
      SizedBox(
        width: 240,
        child: FluentField(
          required: true,
          label: Text('Full name'),
          child: FluentInput(placeholder: Text('Required')),
        ),
      ),
    ),
  ],
);

Widget _hintBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Hint only',
      SizedBox(
        width: 240,
        child: FluentField(
          label: Text('Workspace URL'),
          hint: Text('Letters, numbers and hyphens.'),
          child: FluentInput(placeholder: Text('my-team')),
        ),
      ),
    ),
    (
      'Hint under a message',
      SizedBox(
        width: 240,
        child: FluentField(
          validationState: FluentFieldValidationState.error,
          label: Text('Workspace URL'),
          validationMessage: Text('That URL is taken'),
          validationMessageIcon: _ValidationGlyph(),
          hint: Text('Letters, numbers and hyphens.'),
          child: FluentInput(error: true, placeholder: Text('my-team')),
        ),
      ),
    ),
  ],
);

Widget _disabledBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Enabled',
      SizedBox(
        width: 240,
        child: FluentField(
          required: true,
          validationState: FluentFieldValidationState.error,
          label: Text('Recovery email'),
          validationMessage: Text('That address is not verified'),
          validationMessageIcon: _ValidationGlyph(),
          hint: Text('Used only to reset your password.'),
          child: FluentInput(error: true, placeholder: Text('name@work.com')),
        ),
      ),
    ),
    (
      'Field disabled, control left alone',
      SizedBox(
        width: 240,
        child: FluentField(
          enabled: false,
          required: true,
          validationState: FluentFieldValidationState.error,
          label: Text('Recovery email'),
          validationMessage: Text('That address is not verified'),
          validationMessageIcon: _ValidationGlyph(),
          hint: Text('Used only to reset your password.'),
          child: FluentInput(placeholder: Text('still typeable')),
        ),
      ),
    ),
    (
      'Both disabled',
      SizedBox(
        width: 240,
        child: FluentField(
          enabled: false,
          required: true,
          validationState: FluentFieldValidationState.error,
          label: Text('Recovery email'),
          validationMessage: Text('That address is not verified'),
          validationMessageIcon: _ValidationGlyph(),
          hint: Text('Used only to reset your password.'),
          child: FluentInput(
            enabled: false,
            placeholder: Text('name@work.com'),
          ),
        ),
      ),
    ),
  ],
);

Widget _controlsBuilder(BuildContext context) => const _ControlGallery();

Widget _infoBuilder(BuildContext context) {
  // The base state takes any widget in the label slot, so the info label is
  // rendered exactly as given. Going through `FluentField` instead would wrap
  // it in a second `FluentLabel`.
  const state = FluentFieldBaseState(
    enabled: true,
    label: FluentInfoLabel(
      info: Text('Deleted items are kept for 30 days, then purged.'),
      infoSemanticLabel: 'About the retention period',
      child: Text('Retention period'),
    ),
    hint: Text('Applies to every shared folder.'),
    child: FluentInput(placeholder: Text('30 days')),
  );

  return SizedBox(
    width: 280,
    child: buildFluentField(
      state,
      resolveFluentFieldStyle(
        const FluentFieldState(
          enabled: true,
          size: FluentFieldSize.medium,
          validationState: FluentFieldValidationState.none,
        ),
        FluentTheme.of(context),
      ),
      const <WidgetState>{},
    ),
  );
}

Widget _restyleBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return FluentFieldTheme(
    // Every value is a token off the theme; nothing here is a literal colour.
    style: FluentFieldStyle.from(
      hintColor: colors.neutralForeground2,
      secondaryTextPadding: const EdgeInsets.only(top: FluentSpacing.s),
    ),
    child: _Cases(
      children: [
        const (
          'Theme only',
          SizedBox(
            width: 240,
            child: FluentField(
              label: Text('Label'),
              hint: Text('A roomier, darker hint'),
              child: FluentInput(placeholder: Text('Placeholder')),
            ),
          ),
        ),
        (
          'Theme plus its own style',
          SizedBox(
            width: 240,
            child: FluentField(
              validationState: FluentFieldValidationState.warning,
              style: FluentFieldStyle.from(
                gap: FluentSpacing.m,
                validationMessageIconSize: FluentSize.size160,
              ),
              label: const Text('Label'),
              validationMessage: const Text('A wider gap, a bigger glyph'),
              validationMessageIcon: const _ValidationGlyph(),
              hint: const Text('The themed hint survives the override'),
              child: const FluentInput(placeholder: Text('Placeholder')),
            ),
          ),
        ),
      ],
    ),
  );
}

/// One field per control the library ships, each keeping its own value.
class _ControlGallery extends StatefulWidget {
  const _ControlGallery();

  @override
  State<_ControlGallery> createState() => _ControlGalleryState();
}

class _ControlGalleryState extends State<_ControlGallery> {
  String? _region;
  String _plan = 'monthly';
  double _budget = 40;
  bool _digest = true;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: FluentSpacing.xxl,
    runSpacing: FluentSpacing.xl,
    children: [
      const SizedBox(
        width: 240,
        child: FluentField(
          required: true,
          label: Text('Project name'),
          child: FluentInput(placeholder: Text('Untitled')),
        ),
      ),
      const SizedBox(
        width: 240,
        child: FluentField(
          label: Text('Description'),
          hint: Text('Shown on the project card.'),
          child: FluentTextarea(placeholder: 'What is this for?'),
        ),
      ),
      SizedBox(
        width: 240,
        child: FluentField(
          label: const Text('Region'),
          hint: const Text('Where the data is stored.'),
          child: FluentDropdown<String>(
            value: _region,
            placeholder: const Text('Select a region'),
            options: const [
              FluentDropdownOption<String>(value: 'eu', label: Text('Europe')),
              FluentDropdownOption<String>(
                value: 'us',
                label: Text('United States'),
              ),
              FluentDropdownOption<String>(value: 'ap', label: Text('Asia')),
            ],
            onChanged: (value) => setState(() => _region = value),
          ),
        ),
      ),
      SizedBox(
        width: 240,
        child: FluentField(
          label: const Text('Billing period'),
          child: FluentRadioGroup<String>(
            value: _plan,
            onChanged: (value) => setState(() => _plan = value),
            children: const [
              FluentRadio<String>(value: 'monthly', label: Text('Monthly')),
              FluentRadio<String>(value: 'annual', label: Text('Annual')),
            ],
          ),
        ),
      ),
      SizedBox(
        width: 240,
        child: FluentField(
          label: const Text('Monthly budget'),
          hint: Text('${_budget.round()} credits'),
          child: FluentSlider(
            value: _budget,
            onChanged: (value) => setState(() => _budget = value),
          ),
        ),
      ),
      SizedBox(
        width: 240,
        child: FluentField(
          label: const Text('Weekly digest'),
          hint: const Text('Sent every Monday morning.'),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FluentSwitch(
              checked: _digest,
              onChanged: (value) => setState(() => _digest = value),
            ),
          ),
        ),
      ),
    ],
  );
}

/// The validation glyph these stories pass into the icon slot.
///
/// Fluent's icon set is not shipped with this package — every glyph slot in
/// the library is caller-supplied — so this is a dot that reads its edge
/// length and its tint from the [IconTheme] the field wraps the slot in,
/// exactly as a real icon component would. Upstream uses `ErrorCircle12Filled`,
/// `Warning12Filled` and `CheckmarkCircle12Filled` here.
class _ValidationGlyph extends StatelessWidget {
  const _ValidationGlyph();

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    final size = icon.size ?? FluentSize.size120;
    return SizedBox(
      width: size,
      height: size,
      // The colour is the field's resolved status token, handed down by the
      // field itself — never a literal.
      child: DecoratedBox(
        decoration: BoxDecoration(color: icon.color, shape: BoxShape.circle),
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
      runSpacing: FluentSpacing.xl,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (final (caption, child) in children)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FluentSpacing.s,
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
