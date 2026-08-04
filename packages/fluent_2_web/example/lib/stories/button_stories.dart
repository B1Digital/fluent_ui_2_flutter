import 'dart:async';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentButton], [FluentCompoundButton] and [FluentSplitButton].
///
/// One section rather than three, because the three share every design axis —
/// the same five appearances, the same three sizes, the same three shapes — and
/// reading them side by side is what shows that.
final StorySection buttonStories = StorySection(
  component: 'Button',
  description:
      'The control that performs an action. Five appearances say how loud the '
      'action is, three sizes and three shapes fit it to its surface, and two '
      'variants extend it: a compound button that explains itself on a second '
      'line, and a split button that pairs a default action with a menu.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every axis of a plain button at once. Disabling is a real state, '
          'not a fade: the whole colour ramp is replaced and the button stops '
          'reporting hover, press and focus.',
      knobs: const [
        TextKnob(label: 'Label', id: 'label', initial: 'Send'),
        OptionKnob<FluentButtonAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentButtonAppearance.secondary,
          options: FluentButtonAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentButtonSize>(
          label: 'Size',
          id: 'size',
          initial: FluentButtonSize.medium,
          options: FluentButtonSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentButtonShape>(
          label: 'Shape',
          id: 'shape',
          initial: FluentButtonShape.rounded,
          options: FluentButtonShape.values,
          labelOf: _shapeLabel,
        ),
        BoolKnob(label: 'Icon', id: 'icon'),
        OptionKnob<FluentButtonIconPosition>(
          label: 'Icon position',
          id: 'iconPosition',
          initial: FluentButtonIconPosition.before,
          options: FluentButtonIconPosition.values,
          labelOf: _iconPositionLabel,
        ),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Appearances',
      description:
          'Secondary is the default; primary marks the single most important '
          'action in a view. Outline, subtle and transparent step down from '
          'there — transparent is the only one whose label takes brand colour '
          'on hover instead of a fill.',
      builder: _appearancesBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'Small is 24 high on caption type, medium 32 on body, large 40 on '
          'subtitle. Padding and the icon gap move with the height; the icon '
          'itself stays 20 at all three.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Shapes',
      description:
          'Rounded is the default 4px radius, circular gives fully rounded '
          'ends, and square removes the radius entirely.',
      builder: _shapesBuilder,
    ),
    const Story(
      name: 'With icon',
      description:
          'An icon can lead or trail the label. Dropping the label entirely '
          'calls for FluentButton.icon, which requires a semantic label since '
          'there is no text left for a screen reader to announce.',
      builder: _withIconBuilder,
    ),
    const Story(
      name: 'Disabled',
      description:
          'Disabled across all five appearances. The bordered ones keep a '
          'border in its disabled tone; subtle and transparent lose their fill '
          'completely and are legible only by their greyed label.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Loading',
      description:
          'There is no loading flag: a button in flight is a disabled button '
          'whose icon is a FluentSpinner. Press it and it holds that state for '
          'two seconds.',
      builder: _loadingBuilder,
    ),
    Story(
      name: 'Menu button',
      description:
          'A menu button is not a separate component — it is a button carrying '
          'fluentMenuChevron after its label, wired to a real FluentMenu. '
          'Press it to open the menu.',
      knobs: const [
        OptionKnob<FluentButtonAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentButtonAppearance.secondary,
          options: FluentButtonAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentButtonSize>(
          label: 'Size',
          id: 'size',
          initial: FluentButtonSize.medium,
          options: FluentButtonSize.values,
          labelOf: _sizeLabel,
        ),
      ],
      builder: _menuButtonBuilder,
    ),
    Story(
      name: 'Compound',
      description:
          'A second, quieter line under the label. It brings its own geometry: '
          'a uniform inset that doubles as the icon gap, a 40px icon, and a '
          'height driven by the content rather than the size ramp.',
      knobs: const [
        OptionKnob<FluentButtonAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentButtonAppearance.secondary,
          options: FluentButtonAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentButtonSize>(
          label: 'Size',
          id: 'size',
          initial: FluentButtonSize.medium,
          options: FluentButtonSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentButtonShape>(
          label: 'Shape',
          id: 'shape',
          initial: FluentButtonShape.rounded,
          options: FluentButtonShape.values,
          labelOf: _shapeLabel,
        ),
        BoolKnob(label: 'Icon', id: 'icon', initial: true),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: _compoundBuilder,
    ),
    const Story(
      name: 'Compound appearances',
      description:
          'The five fills are the button\'s own, but the foreground table is '
          'not: the first line stays on neutralForeground1 even on subtle and '
          'transparent, and the second line sits one step quieter — except on '
          'primary, where both share the on-brand colour.',
      builder: _compoundAppearancesBuilder,
    ),
    const Story(
      name: 'Compound sizes',
      description:
          'Only the inset moves — 8, 12 and 16. Both lines hold the same type '
          'ramp at all three sizes, which is what makes a small compound '
          'button read as compact rather than shrunken.',
      builder: _compoundSizesBuilder,
    ),
    Story(
      name: 'Split button',
      description:
          'A default action and a menu in one container. The two halves are '
          'separate hit targets with separate focus stops, so hovering the '
          'chevron does not light up the action.',
      knobs: const [
        OptionKnob<FluentButtonAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentButtonAppearance.secondary,
          options: FluentButtonAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentButtonSize>(
          label: 'Size',
          id: 'size',
          initial: FluentButtonSize.medium,
          options: FluentButtonSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentButtonShape>(
          label: 'Shape',
          id: 'shape',
          initial: FluentButtonShape.rounded,
          options: FluentButtonShape.values,
          labelOf: _shapeLabel,
        ),
        BoolKnob(label: 'Icon', id: 'icon'),
      ],
      builder: _splitBuilder,
    ),
    const Story(
      name: 'Split appearances',
      description:
          'The divider is not the border: on primary there is no border at '
          'all, yet a rule in the on-brand stroke token still separates the '
          'halves. Subtle and transparent are drawn with no rule at all.',
      builder: _splitAppearancesBuilder,
    ),
    const Story(
      name: 'Split sizes',
      description:
          'The chevron half is 24 wide at every size — it is its own Figma '
          'component with no size axis, and 24 is also the WCAG minimum for a '
          'target adjacent to another one. Only its height follows the ramp.',
      builder: _splitSizesBuilder,
    ),
    Story(
      name: 'Split disabled halves',
      description:
          'Disabling is per half. A split button whose menu is reachable while '
          'its default action is not is a real arrangement, so the two have '
          'separate callbacks and separate disabled states.',
      knobs: const [
        BoolKnob(label: 'Action enabled', id: 'action', initial: true),
        BoolKnob(label: 'Menu enabled', id: 'menu', initial: true),
      ],
      builder: _splitDisabledBuilder,
    ),
    const Story(
      name: 'Long label',
      description:
          'A button is sized by its content: a long label makes it wider, '
          'never taller. The compound button is the one place text reflows, '
          'and only because the second line is a separate line.',
      builder: _longLabelBuilder,
    ),
  ],
);

String _appearanceLabel(FluentButtonAppearance value) => value.name;

String _sizeLabel(FluentButtonSize value) => value.name;

String _shapeLabel(FluentButtonShape value) => value.name;

String _iconPositionLabel(FluentButtonIconPosition value) => value.name;

/// The menu a menu button and a split button hang off, shared so both stories
/// demonstrate the same rows.
List<FluentMenuItem> _shareItems(void Function(String) onChosen) =>
    <FluentMenuItem>[
      FluentMenuItem(
        icon: const Icon(FluentIcons.mail_20_regular),
        label: const Text('Send by email'),
        onPressed: () => onChosen('Send by email'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.cloud_arrow_up_20_regular),
        label: const Text('Save to cloud'),
        onPressed: () => onChosen('Save to cloud'),
      ),
      const FluentMenuItem.divider(),
      FluentMenuItem(
        icon: const Icon(FluentIcons.settings_20_regular),
        label: const Text('Sharing settings'),
        onPressed: () => onChosen('Sharing settings'),
      ),
    ];

void _noop() {}

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final disabled = knobs.get<bool>('disabled', false);
  return FluentButton(
    appearance: knobs.get<FluentButtonAppearance>(
      'appearance',
      FluentButtonAppearance.secondary,
    ),
    size: knobs.get<FluentButtonSize>('size', FluentButtonSize.medium),
    shape: knobs.get<FluentButtonShape>('shape', FluentButtonShape.rounded),
    iconPosition: knobs.get<FluentButtonIconPosition>(
      'iconPosition',
      FluentButtonIconPosition.before,
    ),
    icon: knobs.get<bool>('icon', false)
        ? const Icon(FluentIcons.send_20_regular)
        : null,
    onPressed: disabled ? null : _noop,
    child: Text(knobs.get<String>('label', 'Send')),
  );
}

Widget _appearancesBuilder(BuildContext context) => const _Cases(
  children: [
    ('secondary', FluentButton(onPressed: _noop, child: Text('Secondary'))),
    (
      'primary',
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: _noop,
        child: Text('Primary'),
      ),
    ),
    (
      'outline',
      FluentButton(
        appearance: FluentButtonAppearance.outline,
        onPressed: _noop,
        child: Text('Outline'),
      ),
    ),
    (
      'subtle',
      FluentButton(
        appearance: FluentButtonAppearance.subtle,
        onPressed: _noop,
        child: Text('Subtle'),
      ),
    ),
    (
      'transparent',
      FluentButton(
        appearance: FluentButtonAppearance.transparent,
        onPressed: _noop,
        child: Text('Transparent'),
      ),
    ),
  ],
);

Widget _sizesBuilder(BuildContext context) => const _Cases(
  crossAxisAlignment: WrapCrossAlignment.end,
  children: [
    (
      'small — 24',
      FluentButton(
        size: FluentButtonSize.small,
        icon: Icon(FluentIcons.add_20_regular),
        onPressed: _noop,
        child: Text('Small'),
      ),
    ),
    (
      'medium — 32',
      FluentButton(
        icon: Icon(FluentIcons.add_20_regular),
        onPressed: _noop,
        child: Text('Medium'),
      ),
    ),
    (
      'large — 40',
      FluentButton(
        size: FluentButtonSize.large,
        icon: Icon(FluentIcons.add_20_regular),
        onPressed: _noop,
        child: Text('Large'),
      ),
    ),
  ],
);

Widget _shapesBuilder(BuildContext context) => const _Cases(
  children: [
    ('rounded', FluentButton(onPressed: _noop, child: Text('Rounded'))),
    (
      'circular',
      FluentButton(
        shape: FluentButtonShape.circular,
        onPressed: _noop,
        child: Text('Circular'),
      ),
    ),
    (
      'square',
      FluentButton(
        shape: FluentButtonShape.square,
        onPressed: _noop,
        child: Text('Square'),
      ),
    ),
  ],
);

Widget _withIconBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'before',
      FluentButton(
        icon: Icon(FluentIcons.save_20_regular),
        onPressed: _noop,
        child: Text('Save'),
      ),
    ),
    (
      'after',
      FluentButton(
        icon: Icon(FluentIcons.chevron_down_20_regular),
        iconPosition: FluentButtonIconPosition.after,
        onPressed: _noop,
        child: Text('More'),
      ),
    ),
    (
      'icon only',
      FluentButton.icon(
        icon: Icon(FluentIcons.more_horizontal_20_regular),
        semanticLabel: 'More options',
        onPressed: _noop,
      ),
    ),
    (
      'icon only, primary',
      FluentButton.icon(
        appearance: FluentButtonAppearance.primary,
        shape: FluentButtonShape.circular,
        icon: Icon(FluentIcons.add_20_regular),
        semanticLabel: 'Add',
        onPressed: _noop,
      ),
    ),
  ],
);

Widget _disabledBuilder(BuildContext context) => const _Cases(
  children: [
    ('secondary', FluentButton(child: Text('Secondary'))),
    (
      'primary',
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        child: Text('Primary'),
      ),
    ),
    (
      'outline',
      FluentButton(
        appearance: FluentButtonAppearance.outline,
        child: Text('Outline'),
      ),
    ),
    (
      'subtle',
      FluentButton(
        appearance: FluentButtonAppearance.subtle,
        child: Text('Subtle'),
      ),
    ),
    (
      'transparent',
      FluentButton(
        appearance: FluentButtonAppearance.transparent,
        child: Text('Transparent'),
      ),
    ),
  ],
);

Widget _loadingBuilder(BuildContext context) => const _LoadingButton();

Widget _menuButtonBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  return _MenuButton(
    appearance: knobs.get<FluentButtonAppearance>(
      'appearance',
      FluentButtonAppearance.secondary,
    ),
    size: knobs.get<FluentButtonSize>('size', FluentButtonSize.medium),
  );
}

Widget _compoundBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final disabled = knobs.get<bool>('disabled', false);
  return FluentCompoundButton(
    appearance: knobs.get<FluentButtonAppearance>(
      'appearance',
      FluentButtonAppearance.secondary,
    ),
    size: knobs.get<FluentButtonSize>('size', FluentButtonSize.medium),
    shape: knobs.get<FluentButtonShape>('shape', FluentButtonShape.rounded),
    icon: knobs.get<bool>('icon', true)
        ? const Icon(FluentIcons.calendar_month_20_regular)
        : null,
    secondaryContent: const Text('Everyone in the workspace can join'),
    onPressed: disabled ? null : _noop,
    child: const Text('Schedule a meeting'),
  );
}

Widget _compoundAppearancesBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'secondary',
      FluentCompoundButton(
        secondaryContent: Text('The quieter second line'),
        onPressed: _noop,
        child: Text('Secondary'),
      ),
    ),
    (
      'primary',
      FluentCompoundButton(
        appearance: FluentButtonAppearance.primary,
        secondaryContent: Text('Both lines share one colour'),
        onPressed: _noop,
        child: Text('Primary'),
      ),
    ),
    (
      'outline',
      FluentCompoundButton(
        appearance: FluentButtonAppearance.outline,
        secondaryContent: Text('The quieter second line'),
        onPressed: _noop,
        child: Text('Outline'),
      ),
    ),
    (
      'subtle',
      FluentCompoundButton(
        appearance: FluentButtonAppearance.subtle,
        secondaryContent: Text('The quieter second line'),
        onPressed: _noop,
        child: Text('Subtle'),
      ),
    ),
    (
      'transparent',
      FluentCompoundButton(
        appearance: FluentButtonAppearance.transparent,
        secondaryContent: Text('Brand colour on hover'),
        onPressed: _noop,
        child: Text('Transparent'),
      ),
    ),
  ],
);

Widget _compoundSizesBuilder(BuildContext context) => const _Cases(
  crossAxisAlignment: WrapCrossAlignment.end,
  children: [
    (
      'small — inset 8',
      FluentCompoundButton(
        size: FluentButtonSize.small,
        secondaryContent: Text('Same type ramp'),
        onPressed: _noop,
        child: Text('Small'),
      ),
    ),
    (
      'medium — inset 12',
      FluentCompoundButton(
        secondaryContent: Text('Same type ramp'),
        onPressed: _noop,
        child: Text('Medium'),
      ),
    ),
    (
      'large — inset 16',
      FluentCompoundButton(
        size: FluentButtonSize.large,
        secondaryContent: Text('Same type ramp'),
        onPressed: _noop,
        child: Text('Large'),
      ),
    ),
  ],
);

Widget _splitBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  return _SplitButtonDemo(
    appearance: knobs.get<FluentButtonAppearance>(
      'appearance',
      FluentButtonAppearance.secondary,
    ),
    size: knobs.get<FluentButtonSize>('size', FluentButtonSize.medium),
    shape: knobs.get<FluentButtonShape>('shape', FluentButtonShape.rounded),
    icon: knobs.get<bool>('icon', false),
  );
}

Widget _splitAppearancesBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'secondary — ruled',
      FluentSplitButton(
        menuSemanticLabel: 'More send options',
        onPressed: _noop,
        onMenuPressed: _noop,
        child: Text('Secondary'),
      ),
    ),
    (
      'primary — on-brand rule',
      FluentSplitButton(
        appearance: FluentButtonAppearance.primary,
        menuSemanticLabel: 'More send options',
        onPressed: _noop,
        onMenuPressed: _noop,
        child: Text('Primary'),
      ),
    ),
    (
      'outline — ruled',
      FluentSplitButton(
        appearance: FluentButtonAppearance.outline,
        menuSemanticLabel: 'More send options',
        onPressed: _noop,
        onMenuPressed: _noop,
        child: Text('Outline'),
      ),
    ),
    (
      'subtle — no rule',
      FluentSplitButton(
        appearance: FluentButtonAppearance.subtle,
        menuSemanticLabel: 'More send options',
        onPressed: _noop,
        onMenuPressed: _noop,
        child: Text('Subtle'),
      ),
    ),
    (
      'transparent — no rule',
      FluentSplitButton(
        appearance: FluentButtonAppearance.transparent,
        menuSemanticLabel: 'More send options',
        onPressed: _noop,
        onMenuPressed: _noop,
        child: Text('Transparent'),
      ),
    ),
  ],
);

Widget _splitSizesBuilder(BuildContext context) => const _Cases(
  crossAxisAlignment: WrapCrossAlignment.end,
  children: [
    (
      'small — 24 high',
      FluentSplitButton(
        size: FluentButtonSize.small,
        menuSemanticLabel: 'More send options',
        onPressed: _noop,
        onMenuPressed: _noop,
        child: Text('Small'),
      ),
    ),
    (
      'medium — 32 high',
      FluentSplitButton(
        menuSemanticLabel: 'More send options',
        onPressed: _noop,
        onMenuPressed: _noop,
        child: Text('Medium'),
      ),
    ),
    (
      'large — 40 high',
      FluentSplitButton(
        size: FluentButtonSize.large,
        menuSemanticLabel: 'More send options',
        onPressed: _noop,
        onMenuPressed: _noop,
        child: Text('Large'),
      ),
    ),
  ],
);

Widget _splitDisabledBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  return FluentSplitButton(
    menuSemanticLabel: 'More send options',
    onPressed: knobs.get<bool>('action', true) ? _noop : null,
    onMenuPressed: knobs.get<bool>('menu', true) ? _noop : null,
    child: const Text('Send'),
  );
}

Widget _longLabelBuilder(BuildContext context) => const SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: _Cases(
    children: [
      (
        'button',
        FluentButton(
          icon: Icon(FluentIcons.share_20_regular),
          onPressed: _noop,
          child: Text('Share this document with the whole team'),
        ),
      ),
      (
        'compound',
        FluentCompoundButton(
          icon: Icon(FluentIcons.share_20_regular),
          secondaryContent: Text('Everyone with the link can comment'),
          onPressed: _noop,
          child: Text('Share this document with the whole team'),
        ),
      ),
      (
        'split',
        FluentSplitButton(
          menuSemanticLabel: 'More sharing options',
          onPressed: _noop,
          onMenuPressed: _noop,
          child: Text('Share this document with the whole team'),
        ),
      ),
    ],
  ),
);

/// A button that spends two seconds in flight after each press.
///
/// There is no `loading` flag on `FluentButton`, and there does not need to be:
/// a button in flight is a disabled button whose icon is a spinner.
class _LoadingButton extends StatefulWidget {
  const _LoadingButton();

  @override
  State<_LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<_LoadingButton> {
  Timer? _timer;
  bool _loading = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _loading = true);
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) => FluentButton(
    appearance: FluentButtonAppearance.primary,
    icon: _loading
        ? const FluentSpinner(
            size: FluentSpinnerSize.tiny,
            semanticLabel: 'Uploading',
          )
        : const Icon(FluentIcons.arrow_download_20_regular),
    onPressed: _loading ? null : _start,
    child: Text(_loading ? 'Uploading…' : 'Upload'),
  );
}

/// A button carrying the menu chevron, opening a real menu.
class _MenuButton extends StatefulWidget {
  const _MenuButton({required this.appearance, required this.size});

  final FluentButtonAppearance appearance;
  final FluentButtonSize size;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  String? _chosen;

  @override
  Widget build(BuildContext context) => _WithStatus(
    status: _chosen,
    child: FluentMenu(
      semanticLabel: 'Sharing options',
      items: _shareItems((label) => setState(() => _chosen = label)),
      builder: (context, toggle) => FluentButton(
        appearance: widget.appearance,
        size: widget.size,
        icon: fluentMenuChevron,
        iconPosition: FluentButtonIconPosition.after,
        onPressed: toggle,
        child: const Text('Share'),
      ),
    ),
  );
}

/// A split button whose chevron opens a real menu while its primary half runs
/// the default action.
class _SplitButtonDemo extends StatefulWidget {
  const _SplitButtonDemo({
    required this.appearance,
    required this.size,
    required this.shape,
    required this.icon,
  });

  final FluentButtonAppearance appearance;
  final FluentButtonSize size;
  final FluentButtonShape shape;
  final bool icon;

  @override
  State<_SplitButtonDemo> createState() => _SplitButtonDemoState();
}

class _SplitButtonDemoState extends State<_SplitButtonDemo> {
  String? _chosen;

  @override
  Widget build(BuildContext context) => _WithStatus(
    status: _chosen,
    child: FluentMenu(
      semanticLabel: 'Sharing options',
      items: _shareItems((label) => setState(() => _chosen = label)),
      builder: (context, toggle) => FluentSplitButton(
        appearance: widget.appearance,
        size: widget.size,
        shape: widget.shape,
        icon: widget.icon ? const Icon(FluentIcons.share_20_regular) : null,
        menuSemanticLabel: 'More sharing options',
        onPressed: () => setState(() => _chosen = 'Share (default action)'),
        onMenuPressed: toggle,
        child: const Text('Share'),
      ),
    ),
  );
}

/// A control with a line underneath reporting what was last invoked, so a menu
/// story proves the callback fired rather than merely opening.
class _WithStatus extends StatelessWidget {
  const _WithStatus({required this.child, this.status});

  final Widget child;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: [
        child,
        Text(
          status == null ? 'Nothing chosen yet' : 'Chose: $status',
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
      ],
    );
  }
}

/// Side-by-side cases under a caption, the layout most of these stories want.
class _Cases extends StatelessWidget {
  const _Cases({
    required this.children,
    this.crossAxisAlignment = WrapCrossAlignment.start,
  });

  final List<(String, Widget)> children;
  final WrapCrossAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.xxl,
      runSpacing: FluentSpacing.l,
      crossAxisAlignment: crossAxisAlignment,
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
