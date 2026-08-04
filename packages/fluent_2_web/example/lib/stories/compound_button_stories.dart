import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for `FluentCompoundButton`.
final StorySection compoundButtonStories = StorySection(
  component: 'Compound button',
  description:
      'A button with a second, quieter line under its label — for an action '
      'whose consequence needs a sentence of explanation before the reader '
      'commits to it.',
  stories: <Story>[
    Story(
      name: 'Default',
      description:
          'A compound button with every design axis on a knob. The axes are '
          "the plain button's own: five appearances, three sizes, three "
          'shapes.',
      knobs: <Knob<Object?>>[
        const OptionKnob<FluentButtonAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentButtonAppearance.secondary,
          options: FluentButtonAppearance.values,
          labelOf: _appearanceLabel,
        ),
        const OptionKnob<FluentButtonSize>(
          label: 'Size',
          id: 'size',
          initial: FluentButtonSize.medium,
          options: FluentButtonSize.values,
          labelOf: _sizeLabel,
        ),
        const OptionKnob<FluentButtonShape>(
          label: 'Shape',
          id: 'shape',
          initial: FluentButtonShape.rounded,
          options: FluentButtonShape.values,
          labelOf: _shapeLabel,
        ),
        const BoolKnob(label: 'Icon', id: 'icon'),
        const BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return FluentCompoundButton(
          appearance: knobs.get<FluentButtonAppearance>(
            'appearance',
            FluentButtonAppearance.secondary,
          ),
          size: knobs.get<FluentButtonSize>('size', FluentButtonSize.medium),
          shape: knobs.get<FluentButtonShape>(
            'shape',
            FluentButtonShape.rounded,
          ),
          icon: knobs.get<bool>('icon', false)
              ? const Icon(FluentIcons.cloud_arrow_up_32_regular)
              : null,
          secondaryContent: const Text('Everyone with the link can edit'),
          onPressed: knobs.get<bool>('disabled', false) ? null : () {},
          child: const Text('Publish'),
        );
      },
    ),
    Story(
      name: 'Appearances',
      description:
          'The five fills, shared verbatim with the plain button. Both lines '
          'sit one step louder than a button label, and on primary they share '
          'a single on-brand colour.',
      builder: (context) => const Wrap(
        spacing: FluentSpacing.l,
        runSpacing: FluentSpacing.l,
        children: <Widget>[
          _Sample(label: 'Secondary', secondary: 'The default fill'),
          _Sample(
            label: 'Primary',
            secondary: 'The one committing action',
            appearance: FluentButtonAppearance.primary,
          ),
          _Sample(
            label: 'Outline',
            secondary: 'Border, no fill',
            appearance: FluentButtonAppearance.outline,
          ),
          _Sample(
            label: 'Subtle',
            secondary: 'Fill appears on hover',
            appearance: FluentButtonAppearance.subtle,
          ),
          _Sample(
            label: 'Transparent',
            secondary: 'Brand colour on hover',
            appearance: FluentButtonAppearance.transparent,
          ),
        ],
      ),
    ),
    Story(
      name: 'Sizes',
      description:
          'Only the inset moves — 8, 12 then 16 — and it doubles as the icon '
          'gap. Two lines make a fixed height ramp meaningless, so the height '
          'is content-driven and the type ramp is the same at all three.',
      builder: (context) => const Wrap(
        spacing: FluentSpacing.l,
        runSpacing: FluentSpacing.l,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _Sample(
            label: 'Small',
            secondary: 'Inset of 8',
            size: FluentButtonSize.small,
          ),
          _Sample(label: 'Medium', secondary: 'Inset of 12'),
          _Sample(
            label: 'Large',
            secondary: 'Inset of 16',
            size: FluentButtonSize.large,
          ),
        ],
      ),
    ),
    Story(
      name: 'Shapes',
      description:
          'Corner treatment: the default medium radius, fully rounded ends, '
          'and square. Circular reads very differently on a two-line button '
          'than on a one-line one.',
      knobs: <Knob<Object?>>[
        const OptionKnob<FluentButtonAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentButtonAppearance.secondary,
          options: FluentButtonAppearance.values,
          labelOf: _appearanceLabel,
        ),
      ],
      builder: (context) {
        final appearance = KnobsScope.of(context).get<FluentButtonAppearance>(
          'appearance',
          FluentButtonAppearance.secondary,
        );
        return Wrap(
          spacing: FluentSpacing.l,
          runSpacing: FluentSpacing.l,
          children: <Widget>[
            _Sample(
              label: 'Rounded',
              secondary: 'The default',
              appearance: appearance,
            ),
            _Sample(
              label: 'Circular',
              secondary: 'Fully rounded ends',
              appearance: appearance,
              shape: FluentButtonShape.circular,
            ),
            _Sample(
              label: 'Square',
              secondary: 'No radius at all',
              appearance: appearance,
              shape: FluentButtonShape.square,
            ),
          ],
        );
      },
    ),
    Story(
      name: 'With icon',
      description:
          'The icon is rendered at 40 logical pixels — double a plain '
          "button's — so it can stand beside two lines, and it can sit on "
          'either side of them.',
      builder: (context) => const Wrap(
        spacing: FluentSpacing.l,
        runSpacing: FluentSpacing.l,
        children: <Widget>[
          _Sample(
            label: 'Invite people',
            secondary: 'They will get an email',
            icon: Icon(FluentIcons.person_add_32_regular),
          ),
          _Sample(
            label: 'Send now',
            secondary: 'Delivery cannot be undone',
            appearance: FluentButtonAppearance.primary,
            icon: Icon(FluentIcons.send_32_regular),
            iconPosition: FluentButtonIconPosition.after,
          ),
        ],
      ),
    ),
    Story(
      name: 'Without a second line',
      description:
          'Omitting the secondary content is legal: what is left is a plain '
          'button label wearing compound geometry — the uniform inset, the 40 '
          'pixel icon and the content-driven height.',
      builder: (context) => const Wrap(
        spacing: FluentSpacing.l,
        runSpacing: FluentSpacing.l,
        children: <Widget>[
          _Sample(label: 'No second line', secondary: null),
          _Sample(
            label: 'With an icon',
            secondary: null,
            icon: Icon(FluentIcons.save_32_regular),
          ),
        ],
      ),
    ),
    Story(
      name: 'Disabled',
      description:
          'Disabled is a real state, not a treatment: both lines drop to the '
          'disabled foreground, the surface stops reacting to hover and press, '
          'and the button refuses focus.',
      builder: (context) => const Wrap(
        spacing: FluentSpacing.l,
        runSpacing: FluentSpacing.l,
        children: <Widget>[
          _Sample(
            label: 'Secondary',
            secondary: 'Nothing will happen',
            enabled: false,
          ),
          _Sample(
            label: 'Primary',
            secondary: 'Nothing will happen',
            appearance: FluentButtonAppearance.primary,
            enabled: false,
          ),
          _Sample(
            label: 'Subtle',
            secondary: 'Nothing will happen',
            appearance: FluentButtonAppearance.subtle,
            enabled: false,
          ),
        ],
      ),
    ),
    Story(
      name: 'Long text',
      description:
          'Neither line truncates. Given a bounded width both wrap, and the '
          'two stay left-aligned to each other however many lines they take.',
      knobs: <Knob<Object?>>[
        const NumberKnob(
          label: 'Width',
          id: 'width',
          initial: 280,
          min: 160,
          max: 520,
          step: 20,
        ),
      ],
      builder: (context) => SizedBox(
        width: KnobsScope.of(context).get<double>('width', 280),
        child: const FluentCompoundButton(
          secondaryContent: Text(
            'Everyone in the organisation will be able to open, comment on '
            'and download this file until you change it back',
          ),
          onPressed: _noop,
          child: Text('Share this document with the whole organisation'),
        ),
      ),
    ),
    Story(
      name: 'Loading',
      description:
          'There is no loading flag: a spinner is a widget, so it goes in the '
          'icon slot, and dropping the callback for the duration disables the '
          'button while the work runs.',
      builder: (context) => const _LoadingCompoundButton(),
    ),
  ],
);

String _appearanceLabel(FluentButtonAppearance value) => switch (value) {
  FluentButtonAppearance.secondary => 'Secondary',
  FluentButtonAppearance.primary => 'Primary',
  FluentButtonAppearance.outline => 'Outline',
  FluentButtonAppearance.subtle => 'Subtle',
  FluentButtonAppearance.transparent => 'Transparent',
};

String _sizeLabel(FluentButtonSize value) => switch (value) {
  FluentButtonSize.small => 'Small',
  FluentButtonSize.medium => 'Medium',
  FluentButtonSize.large => 'Large',
};

String _shapeLabel(FluentButtonShape value) => switch (value) {
  FluentButtonShape.rounded => 'Rounded',
  FluentButtonShape.circular => 'Circular',
  FluentButtonShape.square => 'Square',
};

/// A pressed callback that does nothing, so a `const` story still reacts to
/// hover, press and focus rather than rendering as disabled.
void _noop() {}

/// One compound button, spelled out enough for a side-by-side row.
class _Sample extends StatelessWidget {
  const _Sample({
    required this.label,
    required this.secondary,
    this.appearance = FluentButtonAppearance.secondary,
    this.size = FluentButtonSize.medium,
    this.shape = FluentButtonShape.rounded,
    this.iconPosition = FluentButtonIconPosition.before,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final String? secondary;
  final FluentButtonAppearance appearance;
  final FluentButtonSize size;
  final FluentButtonShape shape;
  final FluentButtonIconPosition iconPosition;
  final Widget? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final secondaryText = secondary;
    return FluentCompoundButton(
      appearance: appearance,
      size: size,
      shape: shape,
      iconPosition: iconPosition,
      icon: icon,
      secondaryContent: secondaryText == null ? null : Text(secondaryText),
      onPressed: enabled ? _noop : null,
      child: Text(label),
    );
  }
}

/// A compound button that runs a two-second job, showing a spinner in its icon
/// slot and refusing further presses until the job is done.
class _LoadingCompoundButton extends StatefulWidget {
  const _LoadingCompoundButton();

  @override
  State<_LoadingCompoundButton> createState() => _LoadingCompoundButtonState();
}

class _LoadingCompoundButtonState extends State<_LoadingCompoundButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => FluentCompoundButton(
    // Secondary, not primary: dropping the callback disables the button while
    // the job runs, and a disabled brand fill turns neutral — which a brand
    // spinner would then sit on illegibly.
    // Extra-large is 40 across, the size the compound button gives its icon.
    icon: _busy
        ? const FluentSpinner(size: FluentSpinnerSize.extraLarge)
        : const Icon(FluentIcons.arrow_download_32_regular),
    secondaryContent: Text(_busy ? 'Working on it' : 'About 4 MB'),
    onPressed: _busy ? null : _run,
    child: Text(_busy ? 'Downloading' : 'Download'),
  );
}
