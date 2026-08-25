import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Tooltip docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage tooltipPage = DocsPage(
  id: 'components-tooltip',
  title: 'Tooltip',
  description:
      'A tooltip displays additional information about another component. The '
      'information is displayed above and near the target component. Tooltip '
      'is not expected to handle interactive content. If this is necessary '
      'behavior, an expand/collapse button + popover should be used instead. '
      'Hover or focus the buttons in the examples to see their tooltips.',
  source: 'lib/pages/components_tooltip.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-tooltip--default',
      title: 'Default',
      description:
          'By default, Tooltip appears above its target element, when it is '
          'focused or hovered.',
      builder: _default,
    ),
    DocsSection(
      id: 'components-tooltip--relationship-label',
      title: 'Relationship: label',
      description:
          'A tooltip can be used as the label of its trigger. For example, a '
          'label tooltip can be used for buttons that have only an icon and no '
          "visible label text. The tooltip sets its content as the trigger's "
          'aria-label, so the tooltip is accessible to screen readers and '
          'other assistive technology.',
      builder: _relationshipLabel,
    ),
    DocsSection(
      id: 'components-tooltip--relationship-description',
      title: 'Relationship: description',
      description:
          'A tooltip can be used as the description of its trigger. For '
          'example, this is used for controls that have a visible label, but '
          'the tooltip provides additional descriptive information. The '
          "tooltip sets itself as the trigger's aria-describedby, so the "
          'tooltip is accessible to screen readers and other assistive '
          'technology.',
      builder: _relationshipDescription,
    ),
    DocsSection(
      id: 'components-tooltip--inverted',
      title: 'Appearance: inverted',
      description:
          "The appearance prop can be set to inverted to use the theme's "
          'inverted colors.',
      builder: _inverted,
    ),
    DocsSection(
      id: 'components-tooltip--with-arrow',
      title: 'With Arrow',
      description:
          'The withArrow prop causes the tooltip to have an arrow pointing to '
          'its target.',
      builder: _withArrow,
    ),
    DocsSection(
      id: 'components-tooltip--styled',
      title: 'Styled',
      description:
          'To style a tooltip, classNames must be passed through the content '
          'slot.',
      builder: _styled,
    ),
    DocsSection(
      id: 'components-tooltip--custom-mount',
      title: 'Custom Mount',
      description:
          'Tooltips are rendered in a React Portal. By default that Portal is '
          'the outermost div. A custom mountNode can be provided in the case '
          'that the tooltip needs to be rendered elsewhere.',
      builder: _customMount,
    ),
    DocsSection(
      id: 'components-tooltip--controlled',
      title: 'Controlled',
      description:
          'The visibility of the tooltip can be controlled using the visible '
          'and onVisibleChange props. In this example, the tooltip will show '
          'on hover or focus only if the checkbox is checked.',
      builder: _controlled,
    ),
    DocsSection(
      id: 'components-tooltip--positioning',
      title: 'Positioning',
      description:
          'The positioning attribute can be used to change the relative '
          'placement of the tooltip to its anchor. Hover or focus the buttons '
          "in the example to see the tooltip's placement.",
      builder: _positioning,
    ),
    DocsSection(
      id: 'components-tooltip--target',
      title: 'Target',
      description:
          'The tooltip can be placed relative to a custom element using '
          'positioning.target. In this example, the tooltip points to the icon '
          'inside the button, but it could point to any element.',
      builder: _target,
    ),
    DocsSection(
      id: 'components-tooltip--icon',
      title: 'Icon',
      description:
          'When tooltips are attached to icons, they should use the InfoLabel '
          'control to be accessible. Tooltips should not be attached directly '
          'to static elements like icons, and nor should static elements be '
          'given a tabindex.',
      builder: _icon,
    ),
    DocsSection(
      id: 'components-tooltip--overflow-hidden',
      title: 'Overflow Hidden',
      description:
          'When a tooltip trigger scrolls out of an overflow container, the '
          'tooltip should hide instead of rendering outside the clipped '
          'boundary.',
      builder: _overflowHidden,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'child',
      type: 'Widget',
      description:
          'The trigger. Hovering or keyboard-focusing it shows the tooltip.',
    ),
    PropRow(
      name: 'content',
      type: 'Widget',
      description: 'The tooltip body. Wraps at 240 logical pixels.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentTooltipAppearance',
      defaultValue: 'FluentTooltipAppearance.normal',
      description: 'Fill treatment.',
    ),
    PropRow(
      name: 'position',
      type: 'FluentTooltipPosition',
      defaultValue: 'FluentTooltipPosition.above',
      description: 'Which side of child the surface sits on.',
    ),
    PropRow(
      name: 'withArrow',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether to draw the pointing arrow.',
    ),
    PropRow(
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether the tooltip may appear at all.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentTooltipStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Announced by assistive technology alongside the trigger.',
    ),
  ],
);

// #docregion components-tooltip--default
Widget _default(BuildContext context) => FluentTooltip(
  content: const Text('Example tooltip'),
  child: FluentButton.icon(
    icon: const Icon(FluentIcons.slide_text_20_regular),
    semanticLabel: 'Example tooltip',
    size: FluentButtonSize.large,
    onPressed: () {},
  ),
);
// #enddocregion components-tooltip--default

// #docregion components-tooltip--relationship-label
// Upstream's `relationship="label"` writes the tooltip text onto the trigger's
// `aria-label`. `FluentButton.icon` already requires that name outright, so the
// same string is passed to both.
Widget _relationshipLabel(BuildContext context) => Row(
  mainAxisSize: MainAxisSize.min,
  spacing: FluentSpacing.s,
  children: <Widget>[
    FluentTooltip(
      content: const Text('Bold'),
      child: FluentButton.icon(
        icon: const Icon(FluentIcons.text_bold_20_regular),
        semanticLabel: 'Bold',
        onPressed: () {},
      ),
    ),
    FluentTooltip(
      content: const Text('Italic'),
      child: FluentButton.icon(
        icon: const Icon(FluentIcons.text_italic_20_regular),
        semanticLabel: 'Italic',
        onPressed: () {},
      ),
    ),
    FluentTooltip(
      content: const Text('Underline'),
      child: FluentButton.icon(
        icon: const Icon(FluentIcons.text_underline_20_regular),
        semanticLabel: 'Underline',
        onPressed: () {},
      ),
    ),
  ],
);
// #enddocregion components-tooltip--relationship-label

// #docregion components-tooltip--relationship-description
// `relationship="description"` has no flag here: `semanticLabel` is announced
// alongside the trigger's own name, which is what `aria-describedby` buys.
Widget _relationshipDescription(BuildContext context) => FluentTooltip(
  content: const Text('This is the description of the button'),
  semanticLabel: 'This is the description of the button',
  child: FluentButton(onPressed: () {}, child: const Text('Button')),
);
// #enddocregion components-tooltip--relationship-description

// #docregion components-tooltip--inverted
Widget _inverted(BuildContext context) => FluentTooltip(
  appearance: FluentTooltipAppearance.inverted,
  content: const Text('Example inverted tooltip'),
  child: FluentButton.icon(
    icon: const Icon(FluentIcons.slide_text_20_filled),
    semanticLabel: 'Example inverted tooltip',
    size: FluentButtonSize.large,
    onPressed: () {},
  ),
);
// #enddocregion components-tooltip--inverted

// #docregion components-tooltip--with-arrow
Widget _withArrow(BuildContext context) => FluentTooltip(
  withArrow: true,
  content: const Text('Example tooltip with an arrow'),
  child: FluentButton.icon(
    icon: const Icon(FluentIcons.arrow_step_in_20_regular),
    semanticLabel: 'Example tooltip with an arrow',
    size: FluentButtonSize.large,
    onPressed: () {},
  ),
);
// #enddocregion components-tooltip--with-arrow

// #docregion components-tooltip--styled
// Upstream reaches the surface through a griffel class on the content slot.
// Here the same two tokens go through `FluentTooltipStyle`, which is the slot
// this package exposes for exactly this.
Widget _styled(BuildContext context) {
  final FluentColors colors = FluentTheme.of(context).colors;
  return FluentTooltip(
    withArrow: true,
    content: const Text('Example tooltip'),
    style: FluentTooltipStyle(
      backgroundColor: WidgetStatePropertyAll<Color>(colors.brandBackground),
      foregroundColor: WidgetStatePropertyAll<Color>(
        colors.neutralForegroundInverted,
      ),
    ),
    child: FluentButton.icon(
      icon: const Icon(FluentIcons.slide_text_20_regular),
      semanticLabel: 'Example tooltip',
      size: FluentButtonSize.large,
      onPressed: () {},
    ),
  );
}
// #enddocregion components-tooltip--styled

// #docregion components-tooltip--custom-mount
// React's `mountNode` picks the portal host. Flutter's equivalent is the
// nearest [Overlay]: `FluentTooltip` calls `Overlay.of`, so putting one here
// mounts the surface inside this box instead of the app's root overlay.
Widget _customMount(BuildContext context) => SizedBox(
  height: 160,
  child: Overlay(
    clipBehavior: Clip.none,
    initialEntries: <OverlayEntry>[
      OverlayEntry(
        builder: (BuildContext context) => Center(
          child: FluentTooltip(
            content: const Text('Example tooltip'),
            child: FluentButton.icon(
              icon: const Icon(FluentIcons.slide_text_20_regular),
              semanticLabel: 'Example tooltip',
              size: FluentButtonSize.large,
              onPressed: () {},
            ),
          ),
        ),
      ),
    ],
  ),
);
// #enddocregion components-tooltip--custom-mount

// #docregion components-tooltip--controlled
Widget _controlled(BuildContext context) => const _Controlled();

// `FluentTooltip` owns its own hover and focus tracking, so there is no
// `visible` to drive. `enabled` is the gate upstream's `visible && enabled`
// actually demonstrates: the checkbox decides whether hover or focus may raise
// the surface at all.
class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) => FluentTooltip(
    enabled: _enabled,
    content: const Text(
      'The checkbox controls whether the tooltip can show on hover or focus',
    ),
    semanticLabel:
        'The checkbox controls whether the tooltip can show on hover or focus',
    child: FluentCheckbox(
      checked: _enabled,
      label: const Text('Enable the tooltip'),
      onChanged: (bool? checked) => setState(() => _enabled = checked ?? false),
    ),
  );
}
// #enddocregion components-tooltip--controlled

// #docregion components-tooltip--positioning
// Upstream offers twelve placements, each with a start/end alignment variant.
// `FluentTooltipPosition` has the four sides and no alignment axis, so this
// renders those four and drops the eight aligned variants rather than fake
// them.
Widget _positioning(BuildContext context) => Row(
  mainAxisSize: MainAxisSize.min,
  spacing: FluentSpacing.xs,
  children: <Widget>[
    _positionCell('before', FluentTooltipPosition.before, 3),
    Column(
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xs,
      children: <Widget>[
        _positionCell('above', FluentTooltipPosition.above, 0),
        _positionCell('below', FluentTooltipPosition.below, 2),
      ],
    ),
    _positionCell('after', FluentTooltipPosition.after, 1),
  ],
);

Widget _positionCell(
  String label,
  FluentTooltipPosition position,
  int quarterTurns,
) => FluentTooltip(
  withArrow: true,
  position: position,
  content: Text(label),
  child: SizedBox(
    width: 64,
    height: 64,
    child: FluentButton.icon(
      icon: RotatedBox(
        quarterTurns: quarterTurns,
        child: const Icon(FluentIcons.arrow_step_out_20_regular),
      ),
      semanticLabel: label,
      size: FluentButtonSize.large,
      onPressed: () {},
    ),
  ),
);
// #enddocregion components-tooltip--positioning

// #docregion components-tooltip--target
// `positioning.target` points the surface at an element other than the
// trigger. A `FluentTooltip` always anchors to its own child, so the icon slot
// is what gets wrapped — the tooltip then measures and points at the icon.
Widget _target(BuildContext context) => FluentButton(
  onPressed: () {},
  icon: FluentTooltip(
    withArrow: true,
    content: const Text('This tooltip points to the icon'),
    semanticLabel: 'This tooltip points to the icon',
    child: const Icon(FluentIcons.arrow_routing_20_regular),
  ),
  child: const Text('Button with icon'),
);
// #enddocregion components-tooltip--target

// #docregion components-tooltip--icon
// `FluentInfoLabel` asks for `infoSemanticLabel` outright: React derives the
// trigger's accessible name from the label it is wired to, this does not.
Widget _icon(BuildContext context) => FluentInfoLabel(
  info: Text.rich(
    TextSpan(
      children: <InlineSpan>[
        const TextSpan(text: 'This is example information for an InfoLabel. '),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: FluentLink(
            inline: true,
            // Upstream links to https://react.fluentui.dev. This package
            // depends on no URL launcher, so the link is a callback.
            onPressed: () {},
            child: const Text('Learn more'),
          ),
        ),
      ],
    ),
  ),
  infoSemanticLabel:
      'More information about This is an icon with an InfoLabel to show extra '
      'information',
  child: const Text(
    'This is an icon with an InfoLabel to show extra information',
  ),
);
// #enddocregion components-tooltip--icon

// #docregion components-tooltip--overflow-hidden
// The surface lives in the nearest [Overlay], which sits above the scroll
// view and is not clipped by it, so scrolling the trigger away leaves the tip
// hanging outside the box. That is the defect upstream's story exists to
// catch; `FluentTooltip` has no clip boundary to hand it yet.
Widget _overflowHidden(BuildContext context) {
  final FluentColors colors = FluentTheme.of(context).colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: FluentSpacing.s,
    children: <Widget>[
      const Text(
        'Scroll the box below. The tooltip should disappear when the button '
        'scrolls out of view, not follow it outside the container boundary.',
      ),
      Container(
        height: 120,
        width: 240,
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.neutralStroke1,
            width: FluentStroke.thin,
          ),
          borderRadius: FluentRadius.allMedium,
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              top: FluentSpacing.s,
              left: FluentSpacing.s,
            ),
            child: SizedBox(
              height: 300,
              child: Align(
                alignment: Alignment.topLeft,
                child: FluentTooltip(
                  content: const Text(
                    'I should hide when scrolled out of view',
                  ),
                  child: FluentButton(
                    onPressed: () {},
                    // The label carries its own width: FluentButton lays it
                    // out in a Row, which hands non-flexible children unbounded
                    // width, so inside this 240px box the label would size to
                    // its intrinsic width and overflow instead of fitting.
                    child: const SizedBox(
                      width: 140,
                      child: Text('Hover me, then scroll'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// #enddocregion components-tooltip--overflow-hidden
