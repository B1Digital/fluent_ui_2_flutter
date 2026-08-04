import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentDrawer].
final StorySection drawerStories = StorySection(
  component: 'Drawer',
  description:
      'A panel anchored to one edge of the reading direction. Two components '
      'in one: an overlay drawer floats over the page on a modal scrim, casts '
      'shadow64 and traps focus, while an inline drawer sits in the layout and '
      'takes its width from its siblings. Openness is controlled — the widget '
      'never flips it, so every story here owns the bool and hands it back '
      'through onDismiss. An overlay drawer paints nothing where it is '
      'written: the panel builds into the nearest Overlay, which in this '
      'gallery is the whole window.',
  stories: [
    const Story(
      name: 'Default',
      description:
          'Every axis at once, over a stage with a page beside it. Overlay or '
          'inline, either edge, three widths and the inline rule — press the '
          'trigger, then close with the header button, with Escape, or by '
          'clicking the scrim.',
      knobs: [
        OptionKnob<FluentDrawerType>(
          label: 'Type',
          id: 'type',
          initial: FluentDrawerType.overlay,
          options: FluentDrawerType.values,
          labelOf: _typeLabel,
        ),
        OptionKnob<FluentDrawerSize>(
          label: 'Size',
          id: 'size',
          initial: FluentDrawerSize.small,
          // `full` is left to the Sizes story: it resolves to infinity, which
          // an inline drawer sharing a Row with a page cannot honour.
          options: [
            FluentDrawerSize.small,
            FluentDrawerSize.medium,
            FluentDrawerSize.large,
          ],
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentDrawerPosition>(
          label: 'Position',
          id: 'position',
          initial: FluentDrawerPosition.start,
          options: FluentDrawerPosition.values,
          labelOf: _positionLabel,
        ),
        BoolKnob(label: 'Separator', id: 'separator', initial: true),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'The width axis, and with it the length of the transition: 320 in '
          '250ms, 592 in 300ms, 940 in 400ms, and full — as wide as the parent '
          'allows — in 500ms. Bigger panels travel further, so they take '
          'longer to arrive.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Position',
      description:
          'Start and end rather than left and right: the anchor, the slide '
          'direction and the side the rule sits on all flip with the reading '
          'direction. Turn RTL on in the toolbar and watch both swap.',
      builder: _positionBuilder,
    ),
    const Story(
      name: 'Inline',
      description:
          'An inline drawer builds in place, is not modal and takes width from '
          'its siblings — the page beside it narrows as the panel arrives. One '
          'here is toggled; the other is simply open with no dismissal path at '
          'all, which is how a permanent side panel is expressed.',
      builder: _inlineBuilder,
    ),
    const Story(
      name: 'Separator',
      description:
          'The rule between an inline drawer and the page. It sits on the edge '
          'facing the page, so it moves with the position. An overlay drawer '
          'ignores the flag and always carries one, because its rule is '
          'transparentStroke — invisible until high contrast turns it opaque.',
      knobs: [BoolKnob(label: 'Separator', id: 'separator', initial: true)],
      builder: _separatorBuilder,
    ),
    const Story(
      name: 'Title and footer',
      description:
          'Header and footer are lists of widgets, not a title string: the '
          'header stacks its children in a column at the 20/28 subtitle ramp, '
          'the footer lays its own out in a row. The body takes whatever '
          'height is left between them.',
      builder: _titleBuilder,
    ),
    const Story(
      name: 'With navigation',
      description:
          'The everyday inline drawer: a nav in the body, the selection kept '
          'by the page. The panel is 320 wide and the nav fills it.',
      builder: _navigationBuilder,
    ),
    const Story(
      name: 'Scrolling body',
      description:
          'The body is the only part that scrolls. Header and footer are '
          'outside it, so a list of any length leaves the title and the '
          'actions where they are.',
      knobs: [
        NumberKnob(label: 'Items', id: 'items', initial: 24, min: 3, max: 60),
      ],
      builder: _scrollingBuilder,
    ),
    const Story(
      name: 'Multiple levels',
      description:
          'A second drawer opened from inside the first. It anchors to the '
          'opposite edge, stacks on top with its own scrim, and takes the '
          'focus trap with it.',
      builder: _levelsBuilder,
    ),
    const Story(
      name: 'Preventing close',
      description:
          'A null onDismiss is a real state, not a visual one: Escape and the '
          'scrim are genuinely inert, and the only way out is the action '
          'inside the panel.',
      builder: _preventCloseBuilder,
    ),
    const Story(
      name: 'Responsive',
      description:
          'Type is a value like any other, so a breakpoint can drive it: below '
          '600 the drawer is an overlay behind a trigger, above it the same '
          'drawer is inline and permanently open. Drag the width to cross the '
          'breakpoint.',
      knobs: [
        NumberKnob(
          label: 'Container width',
          id: 'width',
          initial: 720,
          min: 320,
          max: 1000,
          step: 10,
        ),
      ],
      builder: _responsiveBuilder,
    ),
    const Story(
      name: 'Motion disabled',
      description:
          'Under reduced motion the drawer jumps straight to its end state and '
          'schedules no frames at all — the scrim included. The right-hand '
          'case forces it locally; the toolbar switch does the same to the '
          'whole gallery.',
      builder: _motionBuilder,
    ),
    const Story(
      name: 'Inside a container',
      description:
          'An overlay drawer builds into the nearest Overlay, so scoping one '
          'to a box is a matter of giving that box an Overlay of its own. The '
          'scrim and the panel stay inside the frame.',
      builder: _containedBuilder,
    ),
    const Story(
      name: 'Custom width and style',
      description:
          'Three rungs: a width the size axis does not offer, a '
          'FluentDrawerTheme over a subtree, and the widget style merged last. '
          'Overriding one property keeps every other resolved value.',
      builder: _styledBuilder,
    ),
  ],
);

String _typeLabel(FluentDrawerType value) => switch (value) {
  FluentDrawerType.overlay => 'overlay',
  FluentDrawerType.inline => 'inline',
};

String _sizeLabel(FluentDrawerSize value) => switch (value) {
  FluentDrawerSize.small => 'small (320)',
  FluentDrawerSize.medium => 'medium (592)',
  FluentDrawerSize.large => 'large (940)',
  FluentDrawerSize.full => 'full',
};

String _positionLabel(FluentDrawerPosition value) => switch (value) {
  FluentDrawerPosition.start => 'start',
  FluentDrawerPosition.end => 'end',
};

const String _blurb =
    'Everything you pick here is scoped to this view and kept until you '
    'change it again.';

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final type = knobs.get<FluentDrawerType>('type', FluentDrawerType.overlay);
  final size = knobs.get<FluentDrawerSize>('size', FluentDrawerSize.small);
  final position = knobs.get<FluentDrawerPosition>(
    'position',
    FluentDrawerPosition.start,
  );

  return _Open(
    builder: (context, open, setOpen) {
      final drawer = FluentDrawer(
        open: open,
        onDismiss: () => setOpen(false),
        type: type,
        size: size,
        position: position,
        separator: knobs.get<bool>('separator', true),
        semanticLabel: 'Filters',
        header: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: Text('Filters')),
              FluentButton.icon(
                icon: const Icon(FluentIcons.dismiss_20_regular),
                semanticLabel: 'Close',
                appearance: FluentButtonAppearance.subtle,
                onPressed: () => setOpen(false),
              ),
            ],
          ),
        ],
        footer: <Widget>[
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: () => setOpen(false),
            child: const Text('Apply'),
          ),
          FluentButton(
            onPressed: () => setOpen(false),
            child: const Text('Reset'),
          ),
        ],
        child: const Text(_blurb),
      );
      final page = Expanded(
        child: _Page(
          children: <Widget>[
            FluentButton(
              icon: const Icon(FluentIcons.filter_20_regular),
              onPressed: () => setOpen(!open),
              child: Text(open ? 'Close filters' : 'Open filters'),
            ),
            const Text(
              'An inline drawer takes this page\'s width; an overlay one '
              'covers the whole gallery instead.',
            ),
          ],
        ),
      );
      // Which side of the page the panel is written on is the caller's job —
      // `position` only decides the anchor and the rule.
      return _Stage(
        children: position == FluentDrawerPosition.start
            ? <Widget>[drawer, page]
            : <Widget>[page, drawer],
      );
    },
  );
}

Widget _sizesBuilder(BuildContext context) => _Cases(
  children: <(String, Widget)>[
    for (final size in FluentDrawerSize.values)
      (
        '${_sizeLabel(size)} · '
            '${fluentDrawerDuration(size).inMilliseconds}ms',
        _Open(
          builder: (context, open, setOpen) => _Trigger(
            label: 'Open ${_sizeLabel(size)}',
            onPressed: () => setOpen(true),
            drawer: FluentDrawer(
              open: open,
              onDismiss: () => setOpen(false),
              size: size,
              semanticLabel: _sizeLabel(size),
              header: <Widget>[Text(_sizeLabel(size))],
              footer: <Widget>[
                FluentButton(
                  onPressed: () => setOpen(false),
                  child: const Text('Close'),
                ),
              ],
              child: Text(
                'This panel is ${_sizeLabel(size)} and took '
                '${fluentDrawerDuration(size).inMilliseconds}ms to arrive.',
              ),
            ),
          ),
        ),
      ),
  ],
);

Widget _positionBuilder(BuildContext context) => _Cases(
  children: <(String, Widget)>[
    for (final position in FluentDrawerPosition.values)
      (
        _positionLabel(position),
        _Open(
          builder: (context, open, setOpen) => _Trigger(
            label: 'Open ${_positionLabel(position)}',
            onPressed: () => setOpen(true),
            drawer: FluentDrawer(
              open: open,
              onDismiss: () => setOpen(false),
              position: position,
              semanticLabel: _positionLabel(position),
              header: <Widget>[Text('Anchored to ${_positionLabel(position)}')],
              child: const Text(
                'The panel slides in from the edge it lives on, and the rule '
                'sits on the edge facing the page.',
              ),
            ),
          ),
        ),
      ),
  ],
);

Widget _inlineBuilder(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  spacing: FluentSpacing.xxl,
  children: <Widget>[
    _Caption(
      caption: 'toggled',
      child: _Open(
        builder: (context, open, setOpen) => _Stage(
          children: <Widget>[
            FluentDrawer(
              open: open,
              type: FluentDrawerType.inline,
              separator: true,
              semanticLabel: 'Details',
              header: const <Widget>[Text('Details')],
              child: const Text('No scrim, no focus trap, no shadow.'),
            ),
            Expanded(
              child: _Page(
                children: <Widget>[
                  FluentButton(
                    icon: const Icon(FluentIcons.panel_left_expand_20_regular),
                    onPressed: () => setOpen(!open),
                    child: Text(open ? 'Hide details' : 'Show details'),
                  ),
                  const Text('This column narrows as the panel arrives.'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    _Caption(
      caption: 'always open',
      // No trigger and no onDismiss: openness is a constant here, which is
      // how a permanent side panel is written.
      child: _Stage(
        children: <Widget>[
          const FluentDrawer(
            open: true,
            type: FluentDrawerType.inline,
            separator: true,
            semanticLabel: 'Library',
            header: <Widget>[Text('Library')],
            child: Text('Nothing can close this one.'),
          ),
          Expanded(
            child: _Page(
              children: const <Widget>[
                Text('The panel is part of the layout, not an interruption.'),
              ],
            ),
          ),
        ],
      ),
    ),
  ],
);

Widget _separatorBuilder(BuildContext context) {
  final separator = KnobsScope.of(context).get<bool>('separator', true);
  return _Stage(
    children: <Widget>[
      FluentDrawer(
        open: true,
        type: FluentDrawerType.inline,
        separator: separator,
        position: FluentDrawerPosition.start,
        semanticLabel: 'Sources',
        header: const <Widget>[Text('Sources')],
        child: Text(
          separator
              ? 'A thin neutralStroke2 rule on the trailing edge.'
              : 'No rule at all — the panel meets the page on its fill alone.',
        ),
      ),
      const Expanded(
        child: _Page(
          children: <Widget>[
            Text(
              'Flip the switch and the rule appears on the edge facing this '
              'column.',
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _titleBuilder(BuildContext context) => _Open(
  builder: (context, open, setOpen) => _Trigger(
    label: 'New workspace',
    onPressed: () => setOpen(true),
    drawer: FluentDrawer(
      open: open,
      onDismiss: () => setOpen(false),
      size: FluentDrawerSize.medium,
      position: FluentDrawerPosition.end,
      semanticLabel: 'New workspace',
      header: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(child: Text('New workspace')),
            FluentButton.icon(
              icon: const Icon(FluentIcons.dismiss_20_regular),
              semanticLabel: 'Close',
              appearance: FluentButtonAppearance.subtle,
              onPressed: () => setOpen(false),
            ),
          ],
        ),
        // A second header child, stacked under the title at the header gap.
        const FluentLabel(
          size: FluentLabelSize.small,
          child: Text('Step 1 of 3'),
        ),
      ],
      footer: <Widget>[
        FluentButton(
          appearance: FluentButtonAppearance.primary,
          onPressed: () => setOpen(false),
          child: const Text('Create'),
        ),
        FluentButton(
          onPressed: () => setOpen(false),
          child: const Text('Cancel'),
        ),
      ],
      child: const Text(
        'The body sits between the two slots and keeps whatever height is '
        'left over.',
      ),
    ),
  ),
);

Widget _navigationBuilder(BuildContext context) => const _Navigation();

Widget _scrollingBuilder(BuildContext context) {
  final count = KnobsScope.of(context).get<double>('items', 24).round();
  return _Open(
    builder: (context, open, setOpen) => _Trigger(
      label: 'Open activity',
      onPressed: () => setOpen(true),
      drawer: FluentDrawer(
        open: open,
        onDismiss: () => setOpen(false),
        size: FluentDrawerSize.medium,
        semanticLabel: 'Activity',
        header: const <Widget>[Text('Activity')],
        footer: <Widget>[
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: () => setOpen(false),
            child: const Text('Done'),
          ),
        ],
        child: ListView.separated(
          itemCount: count,
          padding: const EdgeInsets.symmetric(vertical: FluentSpacing.m),
          separatorBuilder: (context, index) => const FluentDivider(),
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: FluentSpacing.s),
            child: Text('Entry ${index + 1} of $count'),
          ),
        ),
      ),
    ),
  );
}

Widget _levelsBuilder(BuildContext context) => _Open(
  builder: (context, open, setOpen) => _Trigger(
    label: 'Open settings',
    onPressed: () => setOpen(true),
    drawer: FluentDrawer(
      open: open,
      onDismiss: () => setOpen(false),
      semanticLabel: 'Settings',
      header: const <Widget>[Text('Settings')],
      footer: <Widget>[
        FluentButton(
          onPressed: () => setOpen(false),
          child: const Text('Close'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.m,
        children: <Widget>[
          const Text('The second level anchors to the opposite edge.'),
          _Open(
            builder: (context, innerOpen, setInnerOpen) => _Trigger(
              label: 'Advanced',
              onPressed: () => setInnerOpen(true),
              drawer: FluentDrawer(
                open: innerOpen,
                onDismiss: () => setInnerOpen(false),
                position: FluentDrawerPosition.end,
                semanticLabel: 'Advanced settings',
                header: const <Widget>[Text('Advanced')],
                footer: <Widget>[
                  FluentButton(
                    onPressed: () => setInnerOpen(false),
                    child: const Text('Back'),
                  ),
                ],
                child: const Text(
                  'This panel carries its own scrim and its own focus trap, '
                  'over the one that opened it.',
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

Widget _preventCloseBuilder(BuildContext context) => const _PreventClose();

Widget _responsiveBuilder(BuildContext context) {
  final width = KnobsScope.of(context).get<double>('width', 720);
  return Align(
    alignment: AlignmentDirectional.centerStart,
    child: SizedBox(width: width, child: const _Responsive()),
  );
}

Widget _motionBuilder(BuildContext context) => _Cases(
  children: <(String, Widget)>[
    ('animated', _motionCase(context, reduced: false)),
    ('reduced motion', _motionCase(context, reduced: true)),
  ],
);

/// One trigger and drawer, optionally under a MediaQuery that switches
/// animations off for that subtree only.
Widget _motionCase(BuildContext context, {required bool reduced}) {
  final child = _Open(
    builder: (context, open, setOpen) => _Trigger(
      label: reduced ? 'Open instantly' : 'Open with motion',
      onPressed: () => setOpen(true),
      drawer: FluentDrawer(
        open: open,
        onDismiss: () => setOpen(false),
        size: FluentDrawerSize.medium,
        semanticLabel: reduced ? 'Reduced motion' : 'Animated',
        header: <Widget>[Text(reduced ? 'No transition' : '300ms transition')],
        footer: <Widget>[
          FluentButton(
            onPressed: () => setOpen(false),
            child: const Text('Close'),
          ),
        ],
        child: Text(
          reduced
              ? 'Straight to the end state, scrim included, with no ticker '
                    'running at all.'
              : 'Decelerating on the way in, accelerating on the way out.',
        ),
      ),
    ),
  );
  if (!reduced) return child;
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  );
}

Widget _containedBuilder(BuildContext context) => const _Contained();

Widget _styledBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return _Cases(
    children: <(String, Widget)>[
      (
        'custom width',
        _Open(
          builder: (context, open, setOpen) => _styledDrawer(
            open: open,
            setOpen: setOpen,
            label: 'custom width',
            body:
                'A width the size axis does not offer. Everything else — the '
                'fill, the shadow, the insets — is still the resolved default.',
            style: FluentDrawerStyle.from(width: 420),
          ),
        ),
      ),
      (
        'subtree theme',
        FluentDrawerTheme(
          style: FluentDrawerStyle.from(
            backgroundColor: theme.colors.neutralBackground2,
            // Derived from a token rather than picked: a scrim has to stay
            // translucent, and no alias token is both branded and see-through.
            scrimColor: theme.colors.brandBackground.withValues(alpha: 0.4),
          ),
          child: _Open(
            builder: (context, open, setOpen) => _styledDrawer(
              open: open,
              setOpen: setOpen,
              label: 'subtree theme',
              body:
                  'A FluentDrawerTheme restyles every drawer under it, and it '
                  'reaches the panel even though the panel builds in the '
                  'Overlay.',
            ),
          ),
        ),
      ),
      (
        'widget style',
        _Open(
          builder: (context, open, setOpen) => _styledDrawer(
            open: open,
            setOpen: setOpen,
            label: 'widget style',
            body:
                'Merged last, so it wins over both. Here it moves the body in '
                'and swaps the header ramp.',
            style: FluentDrawerStyle.from(
              bodyPadding: const EdgeInsets.all(FluentSpacing.xxxl),
              headerTextStyle: theme.typography.title3,
            ),
          ),
        ),
      ),
    ],
  );
}

/// One drawer per rung of the customisation ladder, so the three cases differ
/// only in what is styling them.
Widget _styledDrawer({
  required bool open,
  required ValueChanged<bool> setOpen,
  required String label,
  required String body,
  FluentDrawerStyle? style,
}) => _Trigger(
  label: 'Open $label',
  onPressed: () => setOpen(true),
  drawer: FluentDrawer(
    open: open,
    onDismiss: () => setOpen(false),
    style: style,
    semanticLabel: label,
    header: <Widget>[Text(label)],
    footer: <Widget>[
      FluentButton(onPressed: () => setOpen(false), child: const Text('Close')),
    ],
    child: Text(body),
  ),
);

/// Owns the one bool a controlled drawer needs.
///
/// Every story here is stateful for the same reason — `FluentDrawer.open` is
/// never flipped by the widget itself — so the state lives once, in here.
class _Open extends StatefulWidget {
  const _Open({required this.builder});

  final Widget Function(
    BuildContext context,
    bool open,
    ValueChanged<bool> setOpen,
  )
  builder;

  @override
  State<_Open> createState() => _OpenState();
}

class _OpenState extends State<_Open> {
  bool _open = false;

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _open, (value) => setState(() => _open = value));
}

/// A trigger with the overlay drawer it owns.
///
/// An overlay drawer renders nothing where it is written, so the two can sit
/// side by side in the tree without the drawer disturbing the layout.
class _Trigger extends StatelessWidget {
  const _Trigger({
    required this.label,
    required this.onPressed,
    required this.drawer,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget drawer;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      FluentButton(onPressed: onPressed, child: Text(label)),
      drawer,
    ],
  );
}

/// A bounded, bordered stage for an inline drawer.
///
/// The panel fills the height it is given and its body takes what is left
/// between header and footer, so an inline drawer has to sit in a parent with
/// a real height — a Row inside a SizedBox is the smallest one that works.
class _Stage extends StatelessWidget {
  const _Stage({required this.children, this.height = 320});

  final List<Widget> children;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.neutralBackground3,
          border: Border.all(color: theme.colors.neutralStroke2),
        ),
        child: ClipRect(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// The page an inline drawer shares its stage with.
class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(FluentSpacing.xxl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: children,
    ),
  );
}

/// One case under a caption.
class _Caption extends StatelessWidget {
  const _Caption({required this.caption, required this.child});

  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.xs,
      children: <Widget>[
        Text(
          caption,
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
        child,
      ],
    );
  }
}

/// Side-by-side cases, each under its own caption.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: FluentSpacing.xxl,
    runSpacing: FluentSpacing.xxl,
    crossAxisAlignment: WrapCrossAlignment.start,
    children: <Widget>[
      for (final (caption, child) in children)
        _Caption(caption: caption, child: child),
    ],
  );
}

/// An inline drawer whose body is a nav, with the selection kept by the page.
class _Navigation extends StatefulWidget {
  const _Navigation();

  @override
  State<_Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<_Navigation> {
  Object _selected = 'home';

  static const List<(Object, IconData, String)> _destinations = [
    ('home', FluentIcons.home_20_regular, 'Home'),
    ('files', FluentIcons.folder_20_regular, 'Files'),
    ('people', FluentIcons.people_20_regular, 'People'),
    ('settings', FluentIcons.settings_20_regular, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return _Stage(
      height: 360,
      children: <Widget>[
        FluentDrawer(
          open: true,
          type: FluentDrawerType.inline,
          separator: true,
          semanticLabel: 'Main navigation',
          header: const <Widget>[Text('Contoso')],
          child: FluentNav(
            selectedValue: _selected,
            onSelect: (value) => setState(() => _selected = value),
            semanticLabel: 'Main navigation',
            children: <Widget>[
              for (final (value, icon, label) in _destinations)
                FluentNavItem(
                  value: value,
                  icon: Icon(icon),
                  child: Text(label),
                ),
            ],
          ),
        ),
        Expanded(
          child: _Page(
            children: <Widget>[
              Text(
                _destinations.firstWhere((d) => d.$1 == _selected).$3,
                style: theme.typography.subtitle1,
              ),
              const Text(
                'The page keeps the selection; the drawer only shows it.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A drawer with no dismissal path but its own action.
class _PreventClose extends StatefulWidget {
  const _PreventClose();

  @override
  State<_PreventClose> createState() => _PreventCloseState();
}

class _PreventCloseState extends State<_PreventClose> {
  bool _open = false;
  bool _accepted = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.l,
    children: <Widget>[
      _Trigger(
        label: 'Show the terms',
        onPressed: () => setState(() => _open = true),
        drawer: FluentDrawer(
          open: _open,
          // Null, so nothing the drawer offers can close it. The action below
          // reaches this state directly instead.
          size: FluentDrawerSize.medium,
          semanticLabel: 'Terms update',
          header: const <Widget>[Text('We updated the terms')],
          footer: <Widget>[
            FluentButton(
              appearance: FluentButtonAppearance.primary,
              onPressed: () => setState(() {
                _accepted = true;
                _open = false;
              }),
              child: const Text('Accept'),
            ),
          ],
          child: const Text(
            'Escape does nothing and the scrim does nothing. Accepting is the '
            'only way out.',
          ),
        ),
      ),
      if (_accepted)
        const FluentMessageBar(
          intent: FluentMessageBarIntent.success,
          child: Text('Accepted.'),
        ),
    ],
  );
}

/// One drawer that is an overlay when it is cramped and inline when it is not.
class _Responsive extends StatefulWidget {
  const _Responsive();

  @override
  State<_Responsive> createState() => _ResponsiveState();
}

class _ResponsiveState extends State<_Responsive> {
  static const double _breakpoint = 600;

  bool _open = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < _breakpoint;
      return _Stage(
        children: <Widget>[
          FluentDrawer(
            // Wide enough, and the panel is simply part of the page.
            open: compact ? _open : true,
            onDismiss: compact ? () => setState(() => _open = false) : null,
            type: compact ? FluentDrawerType.overlay : FluentDrawerType.inline,
            separator: true,
            semanticLabel: 'Library',
            header: const <Widget>[Text('Library')],
            child: const Text('Albums, artists and playlists.'),
          ),
          Expanded(
            child: _Page(
              children: <Widget>[
                if (compact)
                  FluentButton(
                    icon: const Icon(FluentIcons.navigation_20_regular),
                    onPressed: () => setState(() => _open = true),
                    child: const Text('Library'),
                  ),
                Text(
                  compact
                      ? 'Under ${_breakpoint.toInt()}: an overlay behind a '
                            'trigger.'
                      : 'Over ${_breakpoint.toInt()}: inline and permanently '
                            'open, with no trigger to press.',
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

/// An overlay drawer scoped to a box by giving that box its own Overlay.
class _Contained extends StatefulWidget {
  const _Contained();

  @override
  State<_Contained> createState() => _ContainedState();
}

class _ContainedState extends State<_Contained> {
  late final OverlayEntry _page = OverlayEntry(
    builder: (context) => const _ContainedPage(),
  );

  @override
  void dispose() {
    _page
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Stage(
    height: 360,
    children: <Widget>[
      // The drawer resolves Overlay.of against its own context, so this one —
      // not the app's — is what it builds into.
      Expanded(child: Overlay(initialEntries: <OverlayEntry>[_page])),
    ],
  );
}

/// The page inside the scoped Overlay, and the drawer it owns.
class _ContainedPage extends StatefulWidget {
  const _ContainedPage();

  @override
  State<_ContainedPage> createState() => _ContainedPageState();
}

class _ContainedPageState extends State<_ContainedPage> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => _Page(
    children: <Widget>[
      FluentButton(
        onPressed: () => setState(() => _open = true),
        child: const Text('Open inside this box'),
      ),
      const Text('The scrim dims this frame and nothing beyond it.'),
      FluentDrawer(
        open: _open,
        onDismiss: () => setState(() => _open = false),
        position: FluentDrawerPosition.end,
        semanticLabel: 'Contained drawer',
        header: const <Widget>[Text('Scoped')],
        footer: <Widget>[
          FluentButton(
            onPressed: () => setState(() => _open = false),
            child: const Text('Close'),
          ),
        ],
        child: const Text('Clicking the dimmed area closes this.'),
      ),
    ],
  );
}
