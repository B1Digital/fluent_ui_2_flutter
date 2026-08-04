import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentPopover].
final StorySection popoverStories = StorySection(
  component: 'Popover',
  description:
      'A light-dismiss surface anchored to a trigger, rendered in the app '
      'Overlay so it escapes any ancestor clip. It is controlled on purpose: '
      'the caller owns `open`, and the widget reports every open and close it '
      'performs — Escape, a pointer landing outside — through `onOpenChanged`. '
      'Focus moves into the surface while it is showing and returns to the '
      'trigger when it closes.',
  stories: [
    const Story(
      name: 'Default',
      description:
          'Every axis at once. Press the trigger to open, then Escape or click '
          'away to close — and switch Enabled off to see that a disabled '
          'popover never reaches the overlay at all.',
      knobs: [
        OptionKnob<FluentPopoverAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentPopoverAppearance.normal,
          options: FluentPopoverAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentPopoverSize>(
          label: 'Size',
          id: 'size',
          initial: FluentPopoverSize.medium,
          options: FluentPopoverSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentPopoverPosition>(
          label: 'Position',
          id: 'position',
          initial: FluentPopoverPosition.above,
          options: FluentPopoverPosition.values,
          labelOf: _positionLabel,
        ),
        OptionKnob<FluentPopoverAlign>(
          label: 'Align',
          id: 'align',
          initial: FluentPopoverAlign.center,
          options: FluentPopoverAlign.values,
          labelOf: _alignLabel,
        ),
        BoolKnob(label: 'With arrow', id: 'arrow'),
        BoolKnob(label: 'Enabled', id: 'enabled', initial: true),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Appearances',
      description:
          'Normal sits on the ambient surface, brand carries a promotional or '
          'onboarding message, and inverted flips the neutral fill — dark on a '
          'light theme, light on a dark one.',
      builder: _appearancesBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'One number drives the whole inset: 12, 16 and 20 logical pixels on '
          'both axes, and a small surface also drops to a shorter arrow.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Positions',
      description:
          'Four sides, named in reading order — before and after follow the '
          'text direction, so they swap under the RTL toggle. The Align knob '
          'moves every surface along its side of the anchor at once.',
      knobs: [
        OptionKnob<FluentPopoverAlign>(
          label: 'Align',
          id: 'align',
          initial: FluentPopoverAlign.center,
          options: FluentPopoverAlign.values,
          labelOf: _alignLabel,
        ),
      ],
      builder: _positionsBuilder,
    ),
    const Story(
      name: 'With arrow',
      description:
          'The arrow is opt-in, takes the surface fill, and fills the gap '
          'between anchor and surface. An aligned popover pins it one padding '
          'step in from the matching edge rather than centring it.',
      builder: _withArrowBuilder,
    ),
    const Story(
      name: 'Controlling open and close',
      description:
          '`open` is owned by the caller, so the surface can be driven from '
          'anywhere — here from three buttons beside an anchor that is not '
          'itself interactive, which is also how a popover with no trigger of '
          'its own is built.',
      builder: _controlledBuilder,
    ),
    const Story(
      name: 'Custom trigger',
      description:
          'Anything can be the trigger: the child is rendered in place and the '
          'surface is anchored to it, so an icon button, a link and a card all '
          'work without a wrapper.',
      builder: _customTriggerBuilder,
    ),
    const Story(
      name: 'Updating content',
      description:
          'The content is a live subtree, not a snapshot. Press the counter '
          'inside the open surface and it re-lays out around the new text '
          'while staying anchored.',
      builder: _updatingBuilder,
    ),
    const Story(
      name: 'Nested popovers',
      description:
          'A popover opened from inside another one. The inner surface goes '
          'above the outer, and dismissing it hands focus back to the button '
          'that opened it rather than closing both.',
      builder: _nestedBuilder,
    ),
    const Story(
      name: 'Trapping focus',
      description:
          'The content sits in a focus scope that takes focus on open: Tab '
          'cycles inside the surface and wraps rather than walking off into '
          'the page, and Escape closes it and returns focus to the trigger.',
      builder: _focusBuilder,
    ),
    const Story(
      name: 'Motion',
      description:
          'Entrance only — a fade plus a 10px slide from the anchor over '
          'durationSlower; a closing popover is simply gone. Switch the knob '
          'off to collapse it to zero, exactly as the global reduced-motion '
          'toggle does.',
      knobs: [BoolKnob(label: 'Motion', id: 'motion', initial: true)],
      builder: _motionBuilder,
    ),
    const Story(
      name: 'Custom style',
      description:
          'Three rungs of customisation: the appearance defaults, a '
          'FluentPopoverTheme over a subtree, and the widget style, which is '
          'merged last and wins. Overrides are per property — restyling the '
          'radius keeps every resolved colour.',
      builder: _styledBuilder,
    ),
  ],
);

String _appearanceLabel(FluentPopoverAppearance value) => value.name;

String _sizeLabel(FluentPopoverSize value) => value.name;

String _positionLabel(FluentPopoverPosition value) => value.name;

String _alignLabel(FluentPopoverAlign value) => value.name;

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final enabled = knobs.get<bool>('enabled', true);
  return _Controlled(
    builder: (context, open, setOpen) => FluentPopover(
      open: open,
      onOpenChanged: enabled ? setOpen : null,
      appearance: knobs.get<FluentPopoverAppearance>(
        'appearance',
        FluentPopoverAppearance.normal,
      ),
      size: knobs.get<FluentPopoverSize>('size', FluentPopoverSize.medium),
      position: knobs.get<FluentPopoverPosition>(
        'position',
        FluentPopoverPosition.above,
      ),
      align: knobs.get<FluentPopoverAlign>('align', FluentPopoverAlign.center),
      withArrow: knobs.get<bool>('arrow', false),
      semanticLabel: 'About sharing',
      content: _body('Sharing', 'Anyone with the link can open this file.'),
      child: FluentButton(
        onPressed: () => setOpen(!open),
        child: Text(enabled ? 'Show popover' : 'Disabled'),
      ),
    ),
  );
}

Widget _appearancesBuilder(BuildContext context) => _Cases(
  children: [
    for (final appearance in FluentPopoverAppearance.values)
      (
        appearance.name,
        _demo(
          trigger: appearance.name,
          appearance: appearance,
          withArrow: true,
          semanticLabel: 'About sharing',
          content: _body('Sharing', 'Anyone with the link can open this file.'),
        ),
      ),
  ],
);

Widget _sizesBuilder(BuildContext context) => _Cases(
  children: [
    for (final size in FluentPopoverSize.values)
      (
        size.name,
        _demo(
          trigger: size.name,
          size: size,
          withArrow: true,
          semanticLabel: 'About sharing',
          content: _body('Sharing', 'Anyone with the link can open this file.'),
        ),
      ),
  ],
);

Widget _positionsBuilder(BuildContext context) {
  final align = KnobsScope.of(
    context,
  ).get<FluentPopoverAlign>('align', FluentPopoverAlign.center);
  return _Cases(
    children: [
      for (final position in FluentPopoverPosition.values)
        (
          position.name,
          _demo(
            trigger: position.name,
            position: position,
            align: align,
            withArrow: true,
            semanticLabel: 'About sharing',
            content: _body(
              'Sharing',
              'Anyone with the link can open this file.',
            ),
          ),
        ),
    ],
  );
}

Widget _withArrowBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Without arrow',
      _demo(
        trigger: 'Show',
        semanticLabel: 'About sharing',
        content: _body('Sharing', 'Anyone with the link can open this file.'),
      ),
    ),
    (
      'With arrow',
      _demo(
        trigger: 'Show',
        withArrow: true,
        semanticLabel: 'About sharing',
        content: _body('Sharing', 'Anyone with the link can open this file.'),
      ),
    ),
    (
      'Aligned to the start',
      _demo(
        trigger: 'Show',
        align: FluentPopoverAlign.start,
        withArrow: true,
        semanticLabel: 'About sharing',
        content: _body('Sharing', 'Anyone with the link can open this file.'),
      ),
    ),
    (
      'Aligned to the end',
      _demo(
        trigger: 'Show',
        align: FluentPopoverAlign.end,
        withArrow: true,
        semanticLabel: 'About sharing',
        content: _body('Sharing', 'Anyone with the link can open this file.'),
      ),
    ),
  ],
);

Widget _controlledBuilder(BuildContext context) => const _Controlling();

Widget _customTriggerBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Icon button',
      _Controlled(
        builder: (context, open, setOpen) => FluentPopover(
          open: open,
          onOpenChanged: setOpen,
          withArrow: true,
          semanticLabel: 'About sharing',
          content: _body('Sharing', 'Anyone with the link can open this file.'),
          child: FluentButton.icon(
            icon: const Icon(FluentIcons.share_20_regular),
            semanticLabel: 'Share',
            appearance: FluentButtonAppearance.subtle,
            onPressed: () => setOpen(!open),
          ),
        ),
      ),
    ),
    (
      'Link',
      _Controlled(
        builder: (context, open, setOpen) => FluentPopover(
          open: open,
          onOpenChanged: setOpen,
          withArrow: true,
          semanticLabel: 'About sharing',
          content: _body('Sharing', 'Anyone with the link can open this file.'),
          child: FluentLink(
            onPressed: () => setOpen(!open),
            child: const Text('Who can see this?'),
          ),
        ),
      ),
    ),
    (
      'Card',
      _Controlled(
        builder: (context, open, setOpen) => FluentPopover(
          open: open,
          onOpenChanged: setOpen,
          position: FluentPopoverPosition.after,
          withArrow: true,
          semanticLabel: 'About sharing',
          content: _body('Sharing', 'Anyone with the link can open this file.'),
          child: SizedBox(
            width: 180,
            child: FluentCard(
              onPressed: () => setOpen(!open),
              child: const Text('Quarterly report'),
            ),
          ),
        ),
      ),
    ),
  ],
);

Widget _updatingBuilder(BuildContext context) => const _Updating();

Widget _nestedBuilder(BuildContext context) => _Controlled(
  builder: (context, open, setOpen) => FluentPopover(
    open: open,
    onOpenChanged: setOpen,
    withArrow: true,
    semanticLabel: 'Sharing',
    content: SizedBox(
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.s,
        children: [
          const Text(
            'Sharing',
            style: TextStyle(fontWeight: FluentFontWeight.semibold),
          ),
          const Text('Anyone with the link can open this file.'),
          _Controlled(
            builder: (context, innerOpen, setInnerOpen) => FluentPopover(
              open: innerOpen,
              onOpenChanged: setInnerOpen,
              appearance: FluentPopoverAppearance.brand,
              position: FluentPopoverPosition.after,
              withArrow: true,
              semanticLabel: 'Link expiry',
              content: _body(
                'Link expiry',
                'Links stop working 30 days after they are created.',
              ),
              child: FluentButton(
                size: FluentButtonSize.small,
                onPressed: () => setInnerOpen(!innerOpen),
                child: const Text('When does it expire?'),
              ),
            ),
          ),
        ],
      ),
    ),
    child: FluentButton(
      onPressed: () => setOpen(!open),
      child: const Text('Sharing details'),
    ),
  ),
);

Widget _focusBuilder(BuildContext context) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: FluentSpacing.l,
  children: [
    _Controlled(
      builder: (context, open, setOpen) => FluentPopover(
        open: open,
        onOpenChanged: setOpen,
        withArrow: true,
        semanticLabel: 'Invite someone',
        content: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FluentSpacing.s,
            children: [
              const FluentLabel(child: Text('Email address')),
              const FluentInput(placeholder: Text('name@contoso.com')),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: FluentSpacing.s,
                children: [
                  FluentButton(
                    appearance: FluentButtonAppearance.primary,
                    onPressed: () => setOpen(false),
                    child: const Text('Invite'),
                  ),
                  FluentButton(
                    onPressed: () => setOpen(false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
        child: FluentButton(
          onPressed: () => setOpen(!open),
          child: const Text('Invite someone'),
        ),
      ),
    ),
    FluentButton(
      appearance: FluentButtonAppearance.subtle,
      onPressed: () {},
      child: const Text('A button behind the popover — Tab never reaches it'),
    ),
  ],
);

Widget _motionBuilder(BuildContext context) {
  final motion = KnobsScope.of(context).get<bool>('motion', true);
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: !motion),
    child: _demo(
      trigger: motion ? 'Show with motion' : 'Show without motion',
      withArrow: true,
      semanticLabel: 'About sharing',
      content: _body('Sharing', 'Anyone with the link can open this file.'),
    ),
  );
}

Widget _styledBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return _Cases(
    children: [
      (
        'Defaults',
        _demo(
          trigger: 'Show',
          withArrow: true,
          semanticLabel: 'About sharing',
          content: _body('Sharing', 'Anyone with the link can open this file.'),
        ),
      ),
      (
        'Subtree theme',
        FluentPopoverTheme(
          style: FluentPopoverStyle.from(
            backgroundColor: theme.colors.brandBackground2,
            foregroundColor: theme.colors.brandForeground2,
            borderColor: theme.colors.brandStroke2,
          ),
          child: _demo(
            trigger: 'Show',
            withArrow: true,
            semanticLabel: 'About sharing',
            content: _body(
              'Sharing',
              'Anyone with the link can open this file.',
            ),
          ),
        ),
      ),
      (
        'Widget style',
        _demo(
          trigger: 'Show',
          appearance: FluentPopoverAppearance.inverted,
          withArrow: true,
          semanticLabel: 'About sharing',
          style: FluentPopoverStyle.from(
            borderRadius: FluentRadius.allLarge,
            padding: const EdgeInsets.all(FluentSpacing.xxl),
            arrowSize: const Size(24, 12),
            offset: FluentSpacing.s,
          ),
          content: _body('Sharing', 'Anyone with the link can open this file.'),
        ),
      ),
    ],
  );
}

/// The body most stories put in the surface, sized so the text has somewhere
/// to wrap. The title is styled by weight alone, so it inherits whatever
/// foreground colour the appearance resolved.
Widget _body(String title, String text) => SizedBox(
  width: 240,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.xs,
    children: [
      Text(
        title,
        style: const TextStyle(fontWeight: FluentFontWeight.semibold),
      ),
      Text(text),
    ],
  ),
);

/// A popover behind a plain button trigger — the arrangement most stories want.
Widget _demo({
  required String trigger,
  required Widget content,
  FluentPopoverAppearance appearance = FluentPopoverAppearance.normal,
  FluentPopoverSize size = FluentPopoverSize.medium,
  FluentPopoverPosition position = FluentPopoverPosition.above,
  FluentPopoverAlign align = FluentPopoverAlign.center,
  bool withArrow = false,
  FluentPopoverStyle? style,
  String? semanticLabel,
}) => _Controlled(
  builder: (context, open, setOpen) => FluentPopover(
    open: open,
    onOpenChanged: setOpen,
    appearance: appearance,
    size: size,
    position: position,
    align: align,
    withArrow: withArrow,
    style: style,
    semanticLabel: semanticLabel,
    content: content,
    child: FluentButton(onPressed: () => setOpen(!open), child: Text(trigger)),
  ),
);

/// Owns the open flag for one popover.
///
/// [FluentPopover.open] is controlled on purpose, so every story needs a scrap
/// of state; this is that scrap, written once instead of a dozen times.
class _Controlled extends StatefulWidget {
  const _Controlled({required this.builder});

  final Widget Function(
    BuildContext context,
    bool open,
    ValueChanged<bool> onOpenChanged,
  )
  builder;

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  bool _open = false;

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _open, (value) => setState(() => _open = value));
}

/// A popover driven entirely from outside itself.
///
/// The anchor is a card, which does nothing when pressed: opening, closing and
/// toggling all happen in the buttons beside it, and the popover still reports
/// its own Escape and outside-tap dismissals back into the same flag.
class _Controlling extends StatefulWidget {
  const _Controlling();

  @override
  State<_Controlling> createState() => _ControllingState();
}

class _ControllingState extends State<_Controlling> {
  bool _open = false;

  void _set({required bool open}) => setState(() => _open = open);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.l,
    children: [
      FluentPopover(
        open: _open,
        onOpenChanged: (value) => _set(open: value),
        position: FluentPopoverPosition.after,
        withArrow: true,
        semanticLabel: 'About sharing',
        content: _body('Sharing', 'Anyone with the link can open this file.'),
        child: const SizedBox(
          width: 200,
          child: FluentCard(child: Text('Quarterly report')),
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.s,
        children: [
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: _open ? null : () => _set(open: true),
            child: const Text('Open'),
          ),
          FluentButton(
            onPressed: _open ? () => _set(open: false) : null,
            child: const Text('Close'),
          ),
          FluentButton(
            appearance: FluentButtonAppearance.subtle,
            onPressed: () => _set(open: !_open),
            child: const Text('Toggle'),
          ),
        ],
      ),
      Text(_open ? 'open: true' : 'open: false'),
    ],
  );
}

/// A popover whose content changes while it is showing.
class _Updating extends StatefulWidget {
  const _Updating();

  @override
  State<_Updating> createState() => _UpdatingState();
}

class _UpdatingState extends State<_Updating> {
  bool _open = false;
  int _people = 1;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (value) => setState(() => _open = value),
    withArrow: true,
    semanticLabel: 'Sharing',
    content: SizedBox(
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.s,
        children: [
          const Text(
            'Sharing',
            style: TextStyle(fontWeight: FluentFontWeight.semibold),
          ),
          Text(
            _people == 1
                ? 'One person has this link.'
                : '$_people people have this link, and this line grows as the '
                      'number does.',
          ),
          FluentButton(
            size: FluentButtonSize.small,
            icon: const Icon(FluentIcons.add_20_regular),
            onPressed: () => setState(() => _people++),
            child: const Text('Add someone'),
          ),
        ],
      ),
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = !_open),
      child: const Text('Sharing details'),
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
      runSpacing: FluentSpacing.xxl,
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
