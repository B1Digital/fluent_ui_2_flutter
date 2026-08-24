import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The TagGroup docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Upstream's `TagGroup` is a flex container that hands its children a shared
/// size, a shared disabled flag and the dismiss/select callbacks. We have no
/// group widget: the group is a `Wrap`, and each tag carries those settings
/// itself.
const DocsPage tagTagGroupPage = DocsPage(
  id: 'components-tag-taggroup',
  folder: 'Tag',
  title: 'TagGroup',
  description:
      'A TagGroup is a container for multiple controls that are Tag or '
      'InteractionTag.',
  source: 'lib/pages/components_tag_taggroup.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-tag-taggroup--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-tag-taggroup--dismiss',
      title: 'Dismiss',
      description:
          'A TagGroup contains a collection of Tag/InteractionTag that can be '
          'dismissed. Ensure that focus is properly managed when all tags have '
          'been dismissed.',
      builder: _dismiss,
    ),
    DocsSection(
      id: 'components-tag-taggroup--sizes',
      title: 'Sizes',
      description:
          'A TagGroup can set default size for all its tags. It supports '
          'medium, small and extra-small size. Default value is medium.',
      builder: _sizes,
    ),
    DocsSection(
      id: 'components-tag-taggroup--with-overflow',
      title: 'With Overflow',
      description:
          'A TagGroup can support overflow by using Overflow and OverflowItem.',
      builder: _withOverflow,
    ),
    DocsSection(
      id: 'components-tag-taggroup--disabled',
      title: 'Disabled',
      description:
          'A TagGroup can be disabled. The collection of Tag/InteractionTag '
          'will also be disabled.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-tag-taggroup--select',
      title: 'Select',
      description:
          'A TagGroup contains a collection of InteractionTag that can be '
          'selected. Note: This prop only changes the appearance of the tag at '
          'the moment. A future PR will add the integration with TagGroup.',
      builder: _select,
    ),
  ],
  props: <PropRow>[
    PropRow(name: 'child', type: 'Widget', description: 'The primary line.'),
    PropRow(
      name: 'onPressed',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          'Invoked on tap and on Space or Enter. Null disables the whole tag.',
    ),
    PropRow(
      name: 'secondaryChild',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The second line. Figma only draws two lines at FluentTagSize.medium.',
    ),
    PropRow(
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Leading media — an avatar or an icon.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentTagAppearance',
      defaultValue: 'FluentTagAppearance.filled',
      description: 'Fill and outline treatment.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentTagSize',
      defaultValue: 'FluentTagSize.medium',
      description: 'Height and type ramp.',
    ),
    PropRow(
      name: 'selected',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the tag is chosen. Selected overrides appearance: all three '
          'render as a brand-filled tag.',
    ),
    PropRow(
      name: 'onDismiss',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          'Invoked when the dismiss half is activated. Null omits that half.',
    ),
    PropRow(
      name: 'dismissSemanticLabel',
      type: 'String',
      defaultValue: "'Dismiss'",
      description:
          'Announced for the dismiss half, which has no text of its own.',
    ),
  ],
);

// #docregion components-tag-taggroup--default
// Upstream's `TagGroup` is a flex container with an ARIA role; we have no group
// widget, so each group here is a `Wrap`.
Widget _default(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: 10,
  children: <Widget>[
    const Text('Example with Tag:'),
    Semantics(
      container: true,
      label: 'Simple tag group with Tag',
      child: const Wrap(
        spacing: 4,
        runSpacing: 4,
        children: <Widget>[
          FluentTag(child: Text('Tag 1')),
          FluentTag(child: Text('Tag 2')),
          FluentTag(child: Text('Tag 3')),
        ],
      ),
    ),
    const Text('Example with InteractionTag:'),
    Semantics(
      container: true,
      label: 'Simple tag group with InteractionTag',
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: <Widget>[
          FluentInteractionTag(onPressed: () {}, child: const Text('Tag 1')),
          FluentInteractionTag(onPressed: () {}, child: const Text('Tag 2')),
          FluentInteractionTag(onPressed: () {}, child: const Text('Tag 3')),
        ],
      ),
    ),
  ],
);
// #enddocregion components-tag-taggroup--default

// #docregion components-tag-taggroup--dismiss
Widget _dismiss(BuildContext context) => const _Dismiss();

class _Dismiss extends StatefulWidget {
  const _Dismiss();

  @override
  State<_Dismiss> createState() => _DismissState();
}

class _DismissState extends State<_Dismiss> {
  static const List<(String, String)> _initialTags = <(String, String)>[
    ('1', 'Tag 1'),
    ('2', 'Tag 2'),
    ('3', 'Tag 3'),
  ];

  // Upstream moves focus to the reset button once the last tag goes, which is
  // what its "ensure that focus is properly managed" note is about.
  final FocusNode _tagReset = FocusNode();
  final FocusNode _interactionTagReset = FocusNode();

  List<(String, String)> _tags = _initialTags;
  List<(String, String)> _interactionTags = _initialTags;

  @override
  void dispose() {
    _tagReset.dispose();
    _interactionTagReset.dispose();
    super.dispose();
  }

  void _remove(String value, {required bool interaction}) => setState(() {
    if (interaction) {
      _interactionTags = _interactionTags
          .where(((String, String) tag) => tag.$1 != value)
          .toList();
      if (_interactionTags.isEmpty) {
        _interactionTagReset.requestFocus();
      }
    } else {
      _tags = _tags.where(((String, String) tag) => tag.$1 != value).toList();
      if (_tags.isEmpty) {
        _tagReset.requestFocus();
      }
    }
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      const Text('Example with Tag:'),
      if (_tags.isNotEmpty)
        Semantics(
          container: true,
          label: 'TagGroup example with dismissible Tags',
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: <Widget>[
              for (final (String value, String label) in _tags)
                FluentTag(
                  key: ValueKey<String>('tag-$value'),
                  dismissSemanticLabel: 'remove',
                  onDismiss: () => _remove(value, interaction: false),
                  child: Text(label),
                ),
            ],
          ),
        ),
      FluentButton(
        size: FluentButtonSize.small,
        focusNode: _tagReset,
        onPressed: _tags.length == _initialTags.length
            ? null
            : () => setState(() => _tags = _initialTags),
        child: const Text('Reset the example'),
      ),
      const Text('Example with InteractionTag:'),
      if (_interactionTags.isNotEmpty)
        Semantics(
          container: true,
          label: 'Dismiss example',
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: <Widget>[
              for (final (String value, String label) in _interactionTags)
                FluentInteractionTag(
                  key: ValueKey<String>('interaction-tag-$value'),
                  onPressed: () {},
                  dismissSemanticLabel: 'remove',
                  onDismiss: () => _remove(value, interaction: true),
                  child: Text(label),
                ),
            ],
          ),
        ),
      FluentButton(
        size: FluentButtonSize.small,
        focusNode: _interactionTagReset,
        onPressed: _interactionTags.isNotEmpty
            ? null
            : () => setState(() => _interactionTags = _initialTags),
        child: const Text('Reset the example'),
      ),
    ],
  );
}
// #enddocregion components-tag-taggroup--dismiss

// #docregion components-tag-taggroup--sizes
Widget _sizes(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: 10,
  children: <Widget>[
    for (final (FluentTagSize size, String label, FluentAvatarSize avatar)
        in <(FluentTagSize, String, FluentAvatarSize)>[
          (FluentTagSize.medium, 'medium', FluentAvatarSize.size20),
          (FluentTagSize.small, 'small', FluentAvatarSize.size16),
          (FluentTagSize.extraSmall, 'extra-small', FluentAvatarSize.size16),
        ])
      Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text('$label: '),
          FluentInteractionTag(
            size: size,
            onPressed: () {},
            icon: FluentAvatar(
              name: 'Katri Athokas',
              initials: 'KA',
              size: avatar,
            ),
            child: Text(label),
          ),
          // Upstream sets `shape="circular"` on this one. Our tag has no shape
          // axis, so the pill comes from the style's border radius instead.
          FluentInteractionTag(
            size: size,
            onPressed: () {},
            style: const FluentTagStyle(
              borderRadius: WidgetStatePropertyAll<BorderRadius?>(
                FluentRadius.allCircular,
              ),
            ),
            icon: const Icon(FluentIcons.calendar_month_20_regular),
            child: Text(label),
          ),
          FluentInteractionTag(
            size: size,
            onPressed: () {},
            icon: const Icon(FluentIcons.calendar_month_20_regular),
            dismissSemanticLabel: 'remove',
            onDismiss: () {},
            child: Text(label),
          ),
        ],
      ),
  ],
);
// #enddocregion components-tag-taggroup--sizes

// #docregion components-tag-taggroup--with-overflow
// Upstream wraps the group in `Overflow`/`OverflowItem`, which measure the
// container and move whatever does not fit into the menu behind the `+n` tag.
// Flutter has no equivalent primitive, so the split is fixed here: the first
// five tags render, the remaining six live in the overflow menu.
Widget _withOverflow(BuildContext context) {
  const List<String> names = <String>[
    'Johnie McConnell',
    'Allan Munger',
    'Erik Nason',
    'Kristin Patterson',
    'Daisy Phillips',
    'Carole Poland',
    'Carlos Slattery',
    'Robert Tolbert',
    'Kevin Sturgis',
    'Charlotte Waltson',
    'Elliot Woodward',
  ];
  const int visibleCount = 5;

  String initials(String name) =>
      name.split(' ').map((String word) => word[0]).join();

  return Semantics(
    container: true,
    label: 'Overflow example',
    child: Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final String name in names.take(visibleCount))
          FluentInteractionTag(
            onPressed: () {},
            icon: FluentAvatar(
              name: name,
              initials: initials(name),
              size: FluentAvatarSize.size24,
              status: FluentPresenceStatus.available,
            ),
            secondaryChild: const Text('Available'),
            child: Text(name),
          ),
        FluentMenu(
          items: <FluentMenuItem>[
            for (final String name in names.skip(visibleCount))
              FluentMenuItem(label: Text(name), onPressed: () {}),
          ],
          builder: (BuildContext context, VoidCallback toggle) =>
              FluentInteractionTag(
                onPressed: toggle,
                semanticLabel: '${names.length - visibleCount} more tags',
                child: Text('+${names.length - visibleCount}'),
              ),
        ),
      ],
    ),
  );
}
// #enddocregion components-tag-taggroup--with-overflow

// #docregion components-tag-taggroup--disabled
// A null `onPressed` is what disables an interaction tag — there is no separate
// `enabled` flag on it, because a tag with no action has nothing to disable.
Widget _disabled(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: 10,
  children: <Widget>[
    const Text('Disabled example with Tag:'),
    Semantics(
      container: true,
      label: 'Disabled tag group with Tag',
      child: const Wrap(
        spacing: 4,
        runSpacing: 4,
        children: <Widget>[
          FluentTag(enabled: false, child: Text('Tag 1')),
          FluentTag(enabled: false, child: Text('Tag 2')),
          FluentTag(enabled: false, child: Text('Tag 3')),
        ],
      ),
    ),
    const Text('Disabled example with InteractionTag:'),
    Semantics(
      container: true,
      label: 'Disabled tag group with InteractionTag',
      child: const Wrap(
        spacing: 4,
        runSpacing: 4,
        children: <Widget>[
          FluentInteractionTag(child: Text('Tag 1')),
          FluentInteractionTag(child: Text('Tag 2')),
          FluentInteractionTag(child: Text('Tag 3')),
        ],
      ),
    ),
  ],
);
// #enddocregion components-tag-taggroup--disabled

// #docregion components-tag-taggroup--select
Widget _select(BuildContext context) => const _Select();

class _Select extends StatefulWidget {
  const _Select();

  @override
  State<_Select> createState() => _SelectState();
}

class _SelectState extends State<_Select> {
  static const List<(String, String)> _initialTags = <(String, String)>[
    ('1', 'Tag 1'),
    ('2', 'Tag 2'),
    ('3', 'Tag 3'),
  ];

  // Upstream moves focus to the reset button once the last tag goes.
  final FocusNode _reset = FocusNode();

  List<String> _selected = <String>[];
  List<String> _dismissSelected = <String>[];
  List<(String, String)> _visibleTags = _initialTags;

  @override
  void dispose() {
    _reset.dispose();
    super.dispose();
  }

  static List<String> _toggle(List<String> values, String value) =>
      values.contains(value)
      ? (values.where((String each) => each != value).toList())
      : (<String>[...values, value]);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      const Text('Example with InteractionTag:'),
      Text('Selected values: ${_selected.join(', ')}'),
      Semantics(
        container: true,
        label: 'Tag group with Multiselect Tag',
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: <Widget>[
            for (final (String value, String label) in _initialTags)
              FluentInteractionTag(
                selected: _selected.contains(value),
                onPressed: () =>
                    setState(() => _selected = _toggle(_selected, value)),
                child: Text(label),
              ),
          ],
        ),
      ),
      const Text('Example with Dismissable InteractionTag:'),
      Text('Selected values: ${_dismissSelected.join(', ')}'),
      if (_visibleTags.isNotEmpty)
        Semantics(
          container: true,
          label: 'Tag group with Dismissable Multiselect Tag',
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: <Widget>[
              for (final (String value, String label) in _visibleTags)
                FluentInteractionTag(
                  key: ValueKey<String>('select-$value'),
                  selected: _dismissSelected.contains(value),
                  onPressed: () => setState(
                    () => _dismissSelected = _toggle(_dismissSelected, value),
                  ),
                  dismissSemanticLabel: 'remove',
                  onDismiss: () => setState(() {
                    _dismissSelected = _dismissSelected
                        .where((String each) => each != value)
                        .toList();
                    _visibleTags = _visibleTags
                        .where(((String, String) tag) => tag.$1 != value)
                        .toList();
                    if (_visibleTags.isEmpty) {
                      _reset.requestFocus();
                    }
                  }),
                  child: Text(label),
                ),
            ],
          ),
        ),
      FluentButton(
        size: FluentButtonSize.small,
        focusNode: _reset,
        onPressed: _visibleTags.isNotEmpty
            ? null
            : () => setState(() => _visibleTags = _initialTags),
        child: const Text('Reset the example'),
      ),
    ],
  );
}

// #enddocregion components-tag-taggroup--select
