import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The InteractionTag docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage interactionTagPage = DocsPage(
  id: 'components-tag-interactiontag',
  folder: 'Tag',
  title: 'InteractionTag',
  description:
      'A InteractionTag follows the same characteristics as a Tag, but with '
      'the added functionality of having a primary and secondary action. This '
      'is mostly used in scenarios where gaining more context for a '
      'InteractionTag is available for the user, an example would be clicking '
      'into a persona to expand their profile page.',
  source: 'lib/pages/components_tag_interactiontag.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-tag-interactiontag--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-tag-interactiontag--icon',
      title: 'Icon',
      description: 'An InteractionTag can render a custom icon if provided.',
      builder: _icon,
    ),
    DocsSection(
      id: 'components-tag-interactiontag--media',
      title: 'Media',
      description:
          'An InteractionTag can render a media, for example an Avatar. When '
          'using VoiceOver, if you focus on the InteractionTag with media, '
          'Chrome will announce it as a "button group", whereas Safari will '
          'describe it simply as a "button". This discrepancy is acceptable '
          'since Chrome users can navigate within the button, while Safari '
          'users cannot.',
      builder: _media,
    ),
    DocsSection(
      id: 'components-tag-interactiontag--secondary-text',
      title: 'SecondaryText',
      description: 'An InteractionTag can have a secondary text.',
      builder: _secondaryText,
    ),
    DocsSection(
      id: 'components-tag-interactiontag--dismiss',
      title: 'Dismiss',
      description:
          'An InteractionTag can have a secondary action that is usually '
          'dismiss. TagGroup can handle dismiss for a collection of tags. '
          'Ensure that focus is properly managed when all tags have been '
          'dismissed.',
      builder: _dismiss,
    ),
    DocsSection(
      id: 'components-tag-interactiontag--shape',
      title: 'Shape',
      description: 'An InteractionTag can be rounded or circular,',
      builder: _shape,
    ),
    DocsSection(
      id: 'components-tag-interactiontag--size',
      title: 'Size',
      description:
          'An InteractionTag supports medium, small and extra-small size. '
          'Default size is medium.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-tag-interactiontag--appearance',
      title: 'Appearance',
      description:
          'An InteractionTag can have a filled, outline or brand appearance. '
          'The default is filled.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-tag-interactiontag--disabled',
      title: 'Disabled',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-tag-interactiontag--has-primary-action',
      title: 'Has Primary Action',
      description:
          'An InteractionTag can have a primary action. This example shows an '
          'Interaction Tag that opens a popover as Primary Action.',
      builder: _hasPrimaryAction,
    ),
    DocsSection(
      id: 'components-tag-interactiontag--selected',
      title: 'Selected',
      description:
          'InteractionTag that can be selected. Note: This prop only changes '
          'the appearance of the tag at the moment. A future PR will add the '
          'integration with TagGroup.',
      builder: _selected,
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
          'The second line. Figma only draws two lines at '
          'FluentTagSize.medium.',
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
      name: 'dismissIcon',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Replaces the built-in FluentTagDismissGlyph.',
    ),
    PropRow(
      name: 'dismissSemanticLabel',
      type: 'String',
      defaultValue: "'Dismiss'",
      description:
          'Announced for the dismiss half, which has no text of its own.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentTagStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'focusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description: 'Focus node for the primary half.',
    ),
    PropRow(
      name: 'dismissFocusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description: 'Focus node for the dismiss half.',
    ),
    PropRow(
      name: 'autofocus',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the primary half takes focus on mount.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Announced by assistive technology in place of the label.',
    ),
  ],
);

// #docregion components-tag-interactiontag--default
// Upstream splits the tag into `InteractionTag` + `InteractionTagPrimary`;
// here the primary half is the widget itself, and `onPressed` is what makes it
// interactive rather than an inert `FluentTag`.
Widget _default(BuildContext context) =>
    FluentInteractionTag(onPressed: () {}, child: const Text('Primary text'));
// #enddocregion components-tag-interactiontag--default

// #docregion components-tag-interactiontag--icon
Widget _icon(BuildContext context) => FluentInteractionTag(
  onPressed: () {},
  icon: const Icon(FluentIcons.calendar_month_20_regular),
  child: const Text('Primary text'),
);
// #enddocregion components-tag-interactiontag--icon

// #docregion components-tag-interactiontag--media
// `icon` is the media slot: it takes any widget, so an avatar goes here just
// as an icon does. Initials are not derived from `name`, so both are given.
Widget _media(BuildContext context) => FluentInteractionTag(
  onPressed: () {},
  icon: const FluentAvatar(
    name: 'Katri Athokas',
    initials: 'KA',
    size: FluentAvatarSize.size20,
    status: FluentPresenceStatus.busy,
  ),
  child: const Text('Primary text'),
);
// #enddocregion components-tag-interactiontag--media

// #docregion components-tag-interactiontag--secondary-text
Widget _secondaryText(BuildContext context) => FluentInteractionTag(
  onPressed: () {},
  secondaryChild: const Text('Secondary text'),
  child: const Text('Primary text'),
);
// #enddocregion components-tag-interactiontag--secondary-text

// #docregion components-tag-interactiontag--dismiss
Widget _dismiss(BuildContext context) => const _Dismiss();

class _Dismiss extends StatefulWidget {
  const _Dismiss();

  @override
  State<_Dismiss> createState() => _DismissState();
}

class _DismissState extends State<_Dismiss> {
  // Upstream groups these in a `TagGroup`, which owns one `onDismiss` for the
  // whole collection. We have no group widget, so the Wrap below plays that
  // part and each tag reports its own dismissal.
  static const List<(String, String)> _initialTags = <(String, String)>[
    ('1', 'Tag 1'),
    ('2', 'Tag 2'),
    ('3', 'Tag 3'),
  ];

  final FocusNode _resetFocusNode = FocusNode();
  List<(String, String)> _visibleTags = _initialTags;

  @override
  void dispose() {
    _resetFocusNode.dispose();
    super.dispose();
  }

  void _removeItem(String value) {
    setState(() {
      _visibleTags = _visibleTags
          .where(((String, String) tag) => tag.$1 != value)
          .toList();
    });
    // Focus management: with the last tag gone there is nothing left to hold
    // focus, so the reset button takes it. Resetting re-mounts the first tag,
    // whose `autofocus` hands focus straight back.
    if (_visibleTags.isEmpty) {
      _resetFocusNode.requestFocus();
    }
  }

  void _resetItems() => setState(() => _visibleTags = _initialTags);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      if (_visibleTags.isNotEmpty) ...<Widget>[
        Semantics(
          container: true,
          label: 'Dismiss example',
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: <Widget>[
              for (int index = 0; index < _visibleTags.length; index += 1)
                FluentInteractionTag(
                  key: ValueKey<String>(_visibleTags[index].$1),
                  autofocus: index == 0,
                  onPressed: () {},
                  onDismiss: () => _removeItem(_visibleTags[index].$1),
                  dismissSemanticLabel: 'remove',
                  child: Text(_visibleTags[index].$2),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
      FluentButton(
        size: FluentButtonSize.small,
        focusNode: _resetFocusNode,
        onPressed: _visibleTags.isEmpty ? _resetItems : null,
        child: const Text('Reset the example'),
      ),
    ],
  );
}
// #enddocregion components-tag-interactiontag--dismiss

// #docregion components-tag-interactiontag--shape
// We have no `shape` axis. Circular is the border radius upstream's
// `shape="circular"` sets, supplied through the style the caller already owns.
const FluentTagStyle _shapeCircular = FluentTagStyle(
  borderRadius: WidgetStatePropertyAll<BorderRadius?>(FluentRadius.allCircular),
);

Widget _shape(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: <Widget>[
        FluentInteractionTag(
          onPressed: () {},
          icon: const FluentAvatar(
            name: 'Katri Athokas',
            initials: 'KA',
            size: FluentAvatarSize.size20,
            status: FluentPresenceStatus.busy,
          ),
          child: const Text('Rounded'),
        ),
        FluentInteractionTag(
          onPressed: () {},
          style: _shapeCircular,
          icon: const FluentAvatar(
            name: 'Katri Athokas',
            initials: 'KA',
            size: FluentAvatarSize.size20,
            status: FluentPresenceStatus.busy,
          ),
          child: const Text('Circular'),
        ),
      ],
    ),
    const SizedBox(height: 10),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: <Widget>[
        FluentInteractionTag(
          onPressed: () {},
          onDismiss: () {},
          dismissSemanticLabel: 'remove',
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          secondaryChild: const Text('Secondary text'),
          child: const Text('Rounded'),
        ),
        FluentInteractionTag(
          onPressed: () {},
          onDismiss: () {},
          dismissSemanticLabel: 'remove',
          style: _shapeCircular,
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          secondaryChild: const Text('Secondary text'),
          child: const Text('Circular'),
        ),
      ],
    ),
  ],
);
// #enddocregion components-tag-interactiontag--shape

// #docregion components-tag-interactiontag--size
// We have no `shape` axis. Circular is the border radius upstream's
// `shape="circular"` sets, supplied through the style the caller already owns.
const FluentTagStyle _sizeCircular = FluentTagStyle(
  borderRadius: WidgetStatePropertyAll<BorderRadius?>(FluentRadius.allCircular),
);

Widget _size(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    // medium
    Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: <Widget>[
        FluentInteractionTag(onPressed: () {}, child: const Text('Medium')),
        FluentInteractionTag(
          onPressed: () {},
          onDismiss: () {},
          dismissSemanticLabel: 'dismiss',
          icon: const FluentAvatar(
            name: 'Katri Athokas',
            initials: 'KA',
            size: FluentAvatarSize.size20,
            status: FluentPresenceStatus.busy,
          ),
          child: const Text('Medium dismissible'),
        ),
        FluentInteractionTag(
          onPressed: () {},
          style: _sizeCircular,
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          child: const Text('Medium circular'),
        ),
      ],
    ),
    const SizedBox(height: 10),
    // small
    Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: <Widget>[
        FluentInteractionTag(
          size: FluentTagSize.small,
          onPressed: () {},
          child: const Text('Small'),
        ),
        FluentInteractionTag(
          size: FluentTagSize.small,
          onPressed: () {},
          onDismiss: () {},
          dismissSemanticLabel: 'dismiss',
          icon: const FluentAvatar(
            name: 'Katri Athokas',
            initials: 'KA',
            size: FluentAvatarSize.size16,
            status: FluentPresenceStatus.busy,
          ),
          child: const Text('Small dismissible'),
        ),
        FluentInteractionTag(
          size: FluentTagSize.small,
          onPressed: () {},
          style: _sizeCircular,
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          child: const Text('Small circular'),
        ),
      ],
    ),
    const SizedBox(height: 10),
    // extra-small
    Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: <Widget>[
        FluentInteractionTag(
          size: FluentTagSize.extraSmall,
          onPressed: () {},
          child: const Text('Extra small'),
        ),
        FluentInteractionTag(
          size: FluentTagSize.extraSmall,
          onPressed: () {},
          onDismiss: () {},
          dismissSemanticLabel: 'dismiss',
          icon: const FluentAvatar(
            name: 'Katri Athokas',
            initials: 'KA',
            size: FluentAvatarSize.size16,
            status: FluentPresenceStatus.busy,
          ),
          child: const Text('Extra small dismissible'),
        ),
        FluentInteractionTag(
          size: FluentTagSize.extraSmall,
          onPressed: () {},
          style: _sizeCircular,
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          child: const Text('Extra small circular'),
        ),
      ],
    ),
  ],
);
// #enddocregion components-tag-interactiontag--size

// #docregion components-tag-interactiontag--appearance
// Upstream bundles the filled and regular calendar glyphs so the media swaps
// on hover. Our tag exposes no hover hook for its media slot, so the regular
// glyph stands on its own.
Widget _appearance(BuildContext context) => Wrap(
  spacing: 10,
  runSpacing: 10,
  children: <Widget>[
    FluentInteractionTag(
      onPressed: () {},
      onDismiss: () {},
      dismissSemanticLabel: 'remove',
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      child: const Text('filled'),
    ),
    FluentInteractionTag(
      appearance: FluentTagAppearance.outline,
      onPressed: () {},
      onDismiss: () {},
      dismissSemanticLabel: 'remove',
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      child: const Text('outline'),
    ),
    FluentInteractionTag(
      appearance: FluentTagAppearance.brand,
      onPressed: () {},
      onDismiss: () {},
      dismissSemanticLabel: 'remove',
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      child: const Text('brand'),
    ),
  ],
);
// #enddocregion components-tag-interactiontag--appearance

// #docregion components-tag-interactiontag--disabled
// A null `onPressed` is what disables the tag: both halves stop reporting
// hover and press and refuse focus, so `onDismiss` is never invoked either.
// It still has to be non-null, because that is what draws the dismiss half.
Widget _disabled(BuildContext context) => Wrap(
  spacing: 10,
  runSpacing: 10,
  children: <Widget>[
    FluentInteractionTag(
      onDismiss: () {},
      dismissSemanticLabel: 'remove',
      secondaryChild: const Text('appearance=filled'),
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      child: const Text('Disabled'),
    ),
    FluentInteractionTag(
      appearance: FluentTagAppearance.outline,
      onDismiss: () {},
      dismissSemanticLabel: 'remove',
      secondaryChild: const Text('appearance=outline'),
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      child: const Text('Disabled'),
    ),
    FluentInteractionTag(
      appearance: FluentTagAppearance.brand,
      onDismiss: () {},
      dismissSemanticLabel: 'remove',
      secondaryChild: const Text('appearance=brand'),
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      child: const Text('Disabled'),
    ),
  ],
);
// #enddocregion components-tag-interactiontag--disabled

// #docregion components-tag-interactiontag--has-primary-action
Widget _hasPrimaryAction(BuildContext context) => const _HasPrimaryAction();

class _HasPrimaryAction extends StatefulWidget {
  const _HasPrimaryAction();

  @override
  State<_HasPrimaryAction> createState() => _HasPrimaryActionState();
}

class _HasPrimaryActionState extends State<_HasPrimaryAction> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    content: SizedBox(
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FluentLink(
            onPressed: () {},
            child: const Text('Find out more on wiki'),
          ),
          const _Bullet('Size: Medium to large-sized dog breed.'),
          const _Bullet(
            'Coat: Luxurious double coat with a dense, water-repellent outer '
            'layer and a soft, dense undercoat.',
          ),
          const _Bullet(
            'Color: Typically a luscious golden or cream color, with '
            'variations in shade.',
          ),
          const _Bullet(
            'Build: Sturdy and well-proportioned body with a friendly and '
            'intelligent expression.',
          ),
        ],
      ),
    ),
    // Upstream wraps only the primary half in the popover trigger, and only
    // the dismiss half in a tooltip. Our tag is one widget with two halves, so
    // the whole tag is the trigger and the dismiss half's accessible name
    // carries what the tooltip said.
    child: FluentInteractionTag(
      onPressed: () => setState(() => _open = !_open),
      onDismiss: () {},
      dismissSemanticLabel: 'dismiss',
      child: const Text('Golden retriever'),
    ),
  );
}

/// One `<li>` of upstream's unordered list.
class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('• '),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
// #enddocregion components-tag-interactiontag--has-primary-action

// #docregion components-tag-interactiontag--selected
// Upstream bundles the filled and regular calendar glyphs so the media swaps
// on hover. Our tag exposes no hover hook for its media slot, so the regular
// glyph stands on its own.
Widget _selected(BuildContext context) => Wrap(
  spacing: 10,
  runSpacing: 10,
  children: <Widget>[
    FluentInteractionTag(
      selected: true,
      onPressed: () {},
      onDismiss: () {},
      dismissSemanticLabel: 'remove',
      secondaryChild: const Text('appearance=filled'),
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      child: const Text('Selected'),
    ),
    FluentInteractionTag(
      selected: true,
      appearance: FluentTagAppearance.outline,
      onPressed: () {},
      onDismiss: () {},
      dismissSemanticLabel: 'remove',
      secondaryChild: const Text('appearance=outline'),
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      child: const Text('Selected'),
    ),
    FluentInteractionTag(
      selected: true,
      appearance: FluentTagAppearance.brand,
      onPressed: () {},
      onDismiss: () {},
      dismissSemanticLabel: 'remove',
      secondaryChild: const Text('appearance=brand'),
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      child: const Text('Selected'),
    ),
  ],
);
// #enddocregion components-tag-interactiontag--selected
