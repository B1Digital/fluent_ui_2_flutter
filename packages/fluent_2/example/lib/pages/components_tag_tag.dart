import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Tag docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage tagPage = DocsPage(
  id: 'components-tag-tag',
  folder: 'Tag',
  title: 'Tag',
  description:
      'A Tag provides a visual representation of an attribute, person, or '
      'asset.',
  source: 'lib/pages/components_tag_tag.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-tag-tag--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-tag-tag--icon',
      title: 'Icon',
      description: 'A Tag can render a custom icon if provided.',
      builder: _icon,
    ),
    DocsSection(
      id: 'components-tag-tag--media',
      title: 'Media',
      description: 'A tag can render a media, for example an Avatar.',
      builder: _media,
    ),
    DocsSection(
      id: 'components-tag-tag--secondary-text',
      title: 'SecondaryText',
      description: 'A Tag can have a secondary text.',
      builder: _secondaryText,
    ),
    DocsSection(
      id: 'components-tag-tag--dismiss',
      title: 'Dismiss',
      description:
          'A tag can have a dismiss icon and become focusable. TagGroup can '
          'handle dismiss for a collection of tags. Ensure that focus is '
          'properly managed when all tags have been dismissed.',
      builder: _dismiss,
    ),
    DocsSection(
      id: 'components-tag-tag--shape',
      title: 'Shape',
      description: 'A tag can be rounded or circular,',
      builder: _shape,
    ),
    DocsSection(
      id: 'components-tag-tag--size',
      title: 'Size',
      description:
          'A tag supports medium, small and extra-small size. Default size is '
          'medium.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-tag-tag--appearance',
      title: 'Appearance',
      description:
          'A tag can have a filled, outline or brand appearance. The default '
          'is filled.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-tag-tag--disabled',
      title: 'Disabled',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-tag-tag--selected',
      title: 'Selected',
      builder: _selected,
    ),
  ],
  props: <PropRow>[
    PropRow(name: 'child', type: 'Widget', description: 'The primary line.'),
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
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether the tag reads as active.',
    ),
    PropRow(
      name: 'onDismiss',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          'Invoked when the dismiss glyph is activated. Null omits the glyph.',
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
          'Announced for the dismiss affordance, which has no text of its own.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentTagStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
  ],
);

// #docregion components-tag-tag--default
Widget _default(BuildContext context) =>
    const FluentTag(child: Text('Primary text'));
// #enddocregion components-tag-tag--default

// #docregion components-tag-tag--icon
Widget _icon(BuildContext context) => const FluentTag(
  icon: Icon(FluentIcons.calendar_month_20_regular),
  child: Text('Primary text'),
);
// #enddocregion components-tag-tag--icon

// #docregion components-tag-tag--media
// Upstream's `media` slot is our `icon` slot: the tag has one leading slot and
// an avatar is what it was drawn for. FluentAvatar does not derive initials
// from `name` — upstream's `getInitials` is locale-sensitive — so they are
// spelled out. The square shape is the one Fluent gives a rounded tag.
Widget _media(BuildContext context) => const FluentTag(
  icon: FluentAvatar(
    name: 'Katri Athokas',
    initials: 'KA',
    size: FluentAvatarSize.size24,
    shape: FluentAvatarShape.square,
    status: FluentPresenceStatus.busy,
  ),
  child: Text('Primary text'),
);
// #enddocregion components-tag-tag--media

// #docregion components-tag-tag--secondary-text
Widget _secondaryText(BuildContext context) => const FluentTag(
  secondaryChild: Text('Secondary text'),
  child: Text('Primary text'),
);
// #enddocregion components-tag-tag--secondary-text

// #docregion components-tag-tag--dismiss
Widget _dismiss(BuildContext context) => const _Dismiss();

class _Dismiss extends StatefulWidget {
  const _Dismiss();

  @override
  State<_Dismiss> createState() => _DismissState();
}

class _DismissState extends State<_Dismiss> {
  static const List<String> _initialTags = <String>['Tag 1', 'Tag 2', 'Tag 3'];

  List<String> _visibleTags = _initialTags;

  // Focus management for the reset button: focus lands on it once the last tag
  // is gone, and returns to the first tag when the example is reset.
  final FocusNode _firstTagFocusNode = FocusNode();
  final FocusNode _resetButtonFocusNode = FocusNode();

  @override
  void dispose() {
    _firstTagFocusNode.dispose();
    _resetButtonFocusNode.dispose();
    super.dispose();
  }

  void _removeItem(String tag) {
    setState(
      () => _visibleTags = _visibleTags
          .where((String visible) => visible != tag)
          .toList(),
    );
    if (_visibleTags.isEmpty) {
      _resetButtonFocusNode.requestFocus();
    }
  }

  void _resetItems() {
    setState(() => _visibleTags = _initialTags);
    // The first tag's dismiss affordance only exists after this frame.
    WidgetsBinding.instance.addPostFrameCallback(
      (Duration _) => _firstTagFocusNode.requestFocus(),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      if (_visibleTags.isNotEmpty)
        Semantics(
          container: true,
          label: 'Dismiss example',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (int index = 0; index < _visibleTags.length; index += 1)
                FluentTag(
                  focusNode: index == 0 ? _firstTagFocusNode : null,
                  dismissSemanticLabel: 'remove',
                  onDismiss: () => _removeItem(_visibleTags[index]),
                  child: Text(_visibleTags[index]),
                ),
            ],
          ),
        ),
      FluentButton(
        focusNode: _resetButtonFocusNode,
        size: FluentButtonSize.small,
        onPressed: _visibleTags.isEmpty ? _resetItems : null,
        child: const Text('Reset the example'),
      ),
    ],
  );
}
// #enddocregion components-tag-tag--dismiss

// #docregion components-tag-tag--shape
Widget _shape(BuildContext context) {
  // FluentTag has no `shape` axis. A circular tag is the default medium corner
  // radius swapped for FluentRadius.allCircular through the style.
  const FluentTagStyle circular = FluentTagStyle(
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allCircular,
    ),
  );

  return const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          FluentTag(
            icon: FluentAvatar(
              name: 'Katri Athokas',
              initials: 'KA',
              size: FluentAvatarSize.size24,
              shape: FluentAvatarShape.square,
              status: FluentPresenceStatus.busy,
            ),
            child: Text('Rounded'),
          ),
          FluentTag(
            style: circular,
            icon: FluentAvatar(
              name: 'Katri Athokas',
              initials: 'KA',
              size: FluentAvatarSize.size24,
              status: FluentPresenceStatus.busy,
            ),
            child: Text('Circular'),
          ),
        ],
      ),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          FluentTag(
            dismissSemanticLabel: 'remove',
            onDismiss: _noop,
            icon: Icon(FluentIcons.calendar_month_20_regular),
            secondaryChild: Text('Secondary text'),
            child: Text('Rounded'),
          ),
          FluentTag(
            style: circular,
            dismissSemanticLabel: 'remove',
            onDismiss: _noop,
            icon: Icon(FluentIcons.calendar_month_20_regular),
            secondaryChild: Text('Secondary text'),
            child: Text('Circular'),
          ),
        ],
      ),
    ],
  );
}

// A dismiss that does nothing: this section demonstrates shape, not removal.
void _noop() {}
// #enddocregion components-tag-tag--shape

// #docregion components-tag-tag--size
Widget _size(BuildContext context) {
  // FluentTag has no `shape` axis. A circular tag is the default medium corner
  // radius swapped for FluentRadius.allCircular through the style.
  const FluentTagStyle circular = FluentTagStyle(
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allCircular,
    ),
  );

  return const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      // medium
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          FluentTag(child: Text('Medium')),
          FluentTag(
            dismissSemanticLabel: 'remove',
            onDismiss: _noSizeDismiss,
            icon: FluentAvatar(
              name: 'Katri Athokas',
              initials: 'KA',
              size: FluentAvatarSize.size24,
              shape: FluentAvatarShape.square,
              status: FluentPresenceStatus.busy,
            ),
            child: Text('Medium dismissible'),
          ),
          FluentTag(
            style: circular,
            icon: Icon(FluentIcons.calendar_month_20_regular),
            child: Text('Medium circular'),
          ),
        ],
      ),

      // small
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          FluentTag(size: FluentTagSize.small, child: Text('Small')),
          FluentTag(
            size: FluentTagSize.small,
            dismissSemanticLabel: 'remove',
            onDismiss: _noSizeDismiss,
            icon: FluentAvatar(
              name: 'Katri Athokas',
              initials: 'KA',
              size: FluentAvatarSize.size20,
              shape: FluentAvatarShape.square,
              status: FluentPresenceStatus.busy,
            ),
            child: Text('Small dismissible'),
          ),
          FluentTag(
            size: FluentTagSize.small,
            style: circular,
            icon: Icon(FluentIcons.calendar_month_20_regular),
            child: Text('Small circular'),
          ),
        ],
      ),

      // extra-small
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          FluentTag(size: FluentTagSize.extraSmall, child: Text('Extra small')),
          FluentTag(
            size: FluentTagSize.extraSmall,
            dismissSemanticLabel: 'remove',
            onDismiss: _noSizeDismiss,
            icon: FluentAvatar(
              name: 'Katri Athokas',
              initials: 'KA',
              size: FluentAvatarSize.size16,
              shape: FluentAvatarShape.square,
              status: FluentPresenceStatus.busy,
            ),
            child: Text('Extra small dismissible'),
          ),
          FluentTag(
            size: FluentTagSize.extraSmall,
            style: circular,
            icon: Icon(FluentIcons.calendar_month_20_regular),
            child: Text('Extra small circular'),
          ),
        ],
      ),
    ],
  );
}

// A dismiss that does nothing: this section demonstrates size, not removal.
void _noSizeDismiss() {}
// #enddocregion components-tag-tag--size

// #docregion components-tag-tag--appearance
Widget _appearance(BuildContext context) => const Wrap(
  spacing: 10,
  runSpacing: 10,
  children: <Widget>[
    FluentTag(
      icon: Icon(FluentIcons.calendar_month_20_regular),
      dismissSemanticLabel: 'remove',
      onDismiss: _noAppearanceDismiss,
      child: Text('filled'),
    ),
    FluentTag(
      appearance: FluentTagAppearance.outline,
      icon: Icon(FluentIcons.calendar_month_20_regular),
      dismissSemanticLabel: 'remove',
      onDismiss: _noAppearanceDismiss,
      child: Text('outline'),
    ),
    FluentTag(
      appearance: FluentTagAppearance.brand,
      icon: Icon(FluentIcons.calendar_month_20_regular),
      dismissSemanticLabel: 'remove',
      onDismiss: _noAppearanceDismiss,
      child: Text('brand'),
    ),
  ],
);

// A dismiss that does nothing: this section demonstrates appearance, not
// removal.
void _noAppearanceDismiss() {}
// #enddocregion components-tag-tag--appearance

// #docregion components-tag-tag--disabled
Widget _disabled(BuildContext context) => const Wrap(
  spacing: 10,
  runSpacing: 10,
  children: <Widget>[
    FluentTag(
      enabled: false,
      secondaryChild: Text('appearance=filled'),
      icon: Icon(FluentIcons.calendar_month_20_regular),
      dismissSemanticLabel: 'remove',
      onDismiss: _noDisabledDismiss,
      child: Text('Disabled'),
    ),
    FluentTag(
      enabled: false,
      secondaryChild: Text('appearance=outline'),
      appearance: FluentTagAppearance.outline,
      icon: Icon(FluentIcons.calendar_month_20_regular),
      dismissSemanticLabel: 'remove',
      onDismiss: _noDisabledDismiss,
      child: Text('Disabled'),
    ),
    FluentTag(
      enabled: false,
      secondaryChild: Text('appearance=brand'),
      appearance: FluentTagAppearance.brand,
      icon: Icon(FluentIcons.calendar_month_20_regular),
      dismissSemanticLabel: 'remove',
      onDismiss: _noDisabledDismiss,
      child: Text('Disabled'),
    ),
  ],
);

// Never reached — `enabled: false` disables the dismiss affordance. Passing a
// callback is what draws the glyph at all.
void _noDisabledDismiss() {}
// #enddocregion components-tag-tag--disabled

// #docregion components-tag-tag--selected
Widget _selected(BuildContext context) => const Wrap(
  spacing: 10,
  runSpacing: 10,
  children: <Widget>[
    FluentTag(
      selected: true,
      secondaryChild: Text('appearance=filled'),
      icon: Icon(FluentIcons.calendar_month_20_regular),
      dismissSemanticLabel: 'remove',
      onDismiss: _noSelectedDismiss,
      child: Text('Selected'),
    ),
    FluentTag(
      selected: true,
      secondaryChild: Text('appearance=outline'),
      appearance: FluentTagAppearance.outline,
      icon: Icon(FluentIcons.calendar_month_20_regular),
      dismissSemanticLabel: 'remove',
      onDismiss: _noSelectedDismiss,
      child: Text('Selected'),
    ),
    FluentTag(
      selected: true,
      secondaryChild: Text('appearance=brand'),
      appearance: FluentTagAppearance.brand,
      icon: Icon(FluentIcons.calendar_month_20_regular),
      dismissSemanticLabel: 'remove',
      onDismiss: _noSelectedDismiss,
      child: Text('Selected'),
    ),
  ],
);

// A dismiss that does nothing: this section demonstrates selection, not
// removal.
void _noSelectedDismiss() {}
// #enddocregion components-tag-tag--selected
