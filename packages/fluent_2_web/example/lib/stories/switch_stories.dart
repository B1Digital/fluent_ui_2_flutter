import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentSwitch].
final StorySection switchStories = StorySection(
  component: 'Switch',
  description:
      'A two-state toggle for a setting that takes effect immediately, with no '
      'separate confirmation step.',
  stories: [
    Story(
      name: 'Default',
      description:
          'A switch owns nothing: the value lives with the caller and comes '
          'back through onChanged. Every design axis is a knob here.',
      knobs: const [
        TextKnob(label: 'Label', id: 'label', initial: 'Wi-Fi'),
        OptionKnob<FluentSwitchSize>(
          label: 'Size',
          id: 'size',
          initial: FluentSwitchSize.medium,
          options: FluentSwitchSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentSwitchLabelPosition>(
          label: 'Label position',
          id: 'position',
          initial: FluentSwitchLabelPosition.after,
          options: FluentSwitchLabelPosition.values,
          labelOf: _positionLabel,
        ),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _ToggleSwitch(
          label: Text(knobs.get<String>('label', 'Wi-Fi')),
          size: knobs.get<FluentSwitchSize>('size', FluentSwitchSize.medium),
          labelPosition: knobs.get<FluentSwitchLabelPosition>(
            'position',
            FluentSwitchLabelPosition.after,
          ),
          enabled: !knobs.get<bool>('disabled', false),
        );
      },
    ),
    const Story(
      name: 'Checked',
      description:
          'Starting on is just a starting value — the switch still reports the '
          'next value and never changes itself.',
      builder: _checkedBuilder,
    ),
    const Story(
      name: 'Disabled',
      description:
          'Disabling replaces the whole colour ramp rather than fading it, so a '
          'disabled checked switch loses its brand fill entirely.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'Medium (40x20 track) and small (32x16). The label follows the track '
          'down a type ramp, body to caption.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Label position',
      description:
          'The label can trail the track, lead it in reading order, or sit '
          'above it; the tight 4px gap follows the side facing the track.',
      builder: _labelPositionBuilder,
    ),
    Story(
      name: 'Label wrapping',
      description:
          'A long label wraps and the track stays beside its first line, not '
          'centred against the whole block. Drag the width to see it fold.',
      knobs: const [
        NumberKnob(
          label: 'Available width',
          id: 'width',
          initial: 260,
          min: 140,
          max: 520,
          step: 10,
        ),
      ],
      builder: (context) => SizedBox(
        width: KnobsScope.of(context).get<double>('width', 260),
        child: const _ToggleSwitch(
          initial: true,
          label: Text(
            'Sync everything over cellular data as well as Wi-Fi, including '
            'video I have not watched yet',
          ),
        ),
      ),
    ),
    const Story(
      name: 'Required',
      description:
          'A required switch marks its label with an asterisk by composing '
          'FluentLabel, which owns that treatment.',
      builder: _requiredBuilder,
    ),
    const Story(
      name: 'In a settings list',
      description:
          'The label is optional: in a row that already carries its text, the '
          'switch is the bare track and semanticLabel names it for a reader.',
      builder: _settingsBuilder,
    ),
  ],
);

String _sizeLabel(FluentSwitchSize value) => value.name;

String _positionLabel(FluentSwitchLabelPosition value) => value.name;

Widget _checkedBuilder(BuildContext context) =>
    const _ToggleSwitch(initial: true, label: Text('Do not disturb'));

Widget _disabledBuilder(BuildContext context) => const _Cases(
  children: [
    ('Off', FluentSwitch(label: Text('Off'))),
    ('On', FluentSwitch(checked: true, label: Text('On'))),
  ],
);

Widget _sizesBuilder(BuildContext context) => const _Cases(
  children: [
    ('Medium', _ToggleSwitch(initial: true, label: Text('Medium'))),
    (
      'Small',
      _ToggleSwitch(
        initial: true,
        size: FluentSwitchSize.small,
        label: Text('Small'),
      ),
    ),
  ],
);

Widget _labelPositionBuilder(BuildContext context) => const _Cases(
  children: [
    ('After (default)', _ToggleSwitch(label: Text('Label after'))),
    (
      'Before',
      _ToggleSwitch(
        labelPosition: FluentSwitchLabelPosition.before,
        label: Text('Label before'),
      ),
    ),
    (
      'Above',
      _ToggleSwitch(
        labelPosition: FluentSwitchLabelPosition.above,
        label: Text('Label above'),
      ),
    ),
  ],
);

Widget _requiredBuilder(BuildContext context) => const _ToggleSwitch(
  label: FluentLabel(required: true, child: Text('Share diagnostic data')),
);

Widget _settingsBuilder(BuildContext context) => const _SettingsList();

/// A switch that keeps its own value, so the gallery shows a real control
/// rather than a frozen one. Every axis is forwarded untouched.
class _ToggleSwitch extends StatefulWidget {
  const _ToggleSwitch({
    this.initial = false,
    this.label,
    this.size = FluentSwitchSize.medium,
    this.labelPosition = FluentSwitchLabelPosition.after,
    this.enabled = true,
  });

  final bool initial;
  final Widget? label;
  final FluentSwitchSize size;
  final FluentSwitchLabelPosition labelPosition;
  final bool enabled;

  @override
  State<_ToggleSwitch> createState() => _ToggleSwitchState();
}

class _ToggleSwitchState extends State<_ToggleSwitch> {
  late bool _checked = widget.initial;

  @override
  Widget build(BuildContext context) => FluentSwitch(
    checked: _checked,
    label: widget.label,
    size: widget.size,
    labelPosition: widget.labelPosition,
    onChanged: widget.enabled
        ? (value) => setState(() => _checked = value)
        : null,
  );
}

/// Rows whose text lives in the row rather than on the switch — the layout a
/// settings pane actually uses.
class _SettingsList extends StatefulWidget {
  const _SettingsList();

  @override
  State<_SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<_SettingsList> {
  static const _rows = <(String, String)>[
    ('Automatic updates', 'Install them overnight'),
    ('Background sync', 'Keep files current while the app is closed'),
    ('Usage reports', 'Send anonymous diagnostics'),
  ];
  final _values = <bool>[true, false, false];

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.s,
        children: [
          for (var i = 0; i < _rows.length; i++)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_rows[i].$1, style: theme.typography.body1),
                      Text(
                        _rows[i].$2,
                        style: theme.typography.caption1.copyWith(
                          color: theme.colors.neutralForeground3,
                        ),
                      ),
                    ],
                  ),
                ),
                FluentSwitch(
                  checked: _values[i],
                  semanticLabel: _rows[i].$1,
                  onChanged: (value) => setState(() => _values[i] = value),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Side-by-side cases under a caption, the layout most of these stories want.
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
