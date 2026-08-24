import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Popover docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// [FluentPopover] is controlled — it takes `open` plus `onOpenChanged` rather
/// than upstream's `PopoverTrigger` wrapper — so every section below owns a
/// `bool` and a real trigger button.
const DocsPage popoverPage = DocsPage(
  id: 'components-popover',
  title: 'Popover',
  description: 'A popover displays content on top of other content.',
  source: 'lib/pages/components_popover.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-popover--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-popover--non-interactive-content',
      title: 'Non Interactive Content',
      description:
          'A Popover without interactive content is an edge case. Use a '
          'Tooltip for simple non-interactive content. If richer content '
          'requires a Popover, set tabIndex={-1} on PopoverSurface and give '
          'the surface an accessible name so its content is announced when it '
          'receives focus.',
      builder: _nonInteractiveContent,
    ),
    DocsSection(
      id: 'components-popover--with-arrow',
      title: 'With Arrow',
      description:
          'The withArrow prop can be used to display an arrow pointing to the '
          'target.',
      builder: _withArrow,
    ),
    DocsSection(
      id: 'components-popover--with-arrow-autosize',
      title: 'With Arrow Autosize',
      description:
          'When using the arrow with the autoSize positioning feature, make '
          'sure to move the overflow from the popover to an inner element to '
          'avoid clipping the arrow.',
      builder: _withArrowAutosize,
    ),
    DocsSection(
      id: 'components-popover--trapping-focus',
      title: 'Trapping Focus',
      description:
          'When a Popover contains focusable elements, the modal dialog '
          'pattern will apply. By using the trapFocus prop, the component sets '
          'aria-hidden appropriately to parent elements in the document so '
          'that elements not contained in the focus trap are hidden to screen '
          'reader users. This focus trap is automatically removed when the '
          'Popover is closed.',
      builder: _trappingFocus,
    ),
    DocsSection(
      id: 'components-popover--controlling-open-and-close',
      title: 'Controlling Open And Close',
      description:
          'The opening and close of the Popover can be controlled with your '
          'own state. The onOpenChange callback will provide the hints for the '
          'state and triggers based on the appropriate event. When controlling '
          'the open state of the Popover, extra effort is required to ensure '
          'that interactions are still appropriate and that keyboard '
          'accessibility does not degrade.',
      builder: _controllingOpenAndClose,
    ),
    DocsSection(
      id: 'components-popover--motion-custom',
      title: 'Motion Custom',
      description:
          'Popover animations can be customized using the Motion APIs, '
          'together with the surfaceMotion slot.',
      builder: _motionCustom,
    ),
    DocsSection(
      id: 'components-popover--motion-disabled',
      title: 'Motion Disabled',
      description:
          'To disable the Popover transition animation, set the surfaceMotion '
          'prop to null.',
      builder: _motionDisabled,
    ),
    DocsSection(
      id: 'components-popover--nested-popovers',
      title: 'Nested Popovers',
      description:
          'Popovers can be nested within each other. Too much nesting can '
          'result in extra accessibility considerations and are generally not '
          'a great user experience. Since nested popovers will generally have '
          'an interactive PopoverTrigger to control the nested popover, make '
          'sure to combine their usage with the trapFocus prop for correct '
          'screen reader and keyboard accessibility. Try and limit nesting to '
          '2 levels. Make sure to use trapFocus when nesting. Creating nested '
          'popovers as separate components will result in more maintainable '
          'code.',
      builder: _nestedPopovers,
    ),
    DocsSection(
      id: 'components-popover--anchor-to-custom-target',
      title: 'Anchor To Custom Target',
      description:
          'A Popover can be used without a trigger and anchored to any DOM '
          'element. This can be useful if a Popover instance needs to be '
          'reused in different places. Not using a PopoverTrigger will require '
          'more work to make sure your scenario is accessible, such as, '
          'implementing accessible markup and keyboard interactions for your '
          'trigger.',
      builder: _anchorToCustomTarget,
    ),
    DocsSection(
      id: 'components-popover--custom-trigger',
      title: 'Custom Trigger',
      description:
          'Native elements and Fluent components have first class support as '
          'children of PopoverTrigger so they will be injected automatically '
          'with the correct props for interactions and accessibility '
          'attributes. It is possible to use your own custom React component '
          'as a child of PopoverTrigger. These components should use ref '
          'forwarding with React.forwardRef.',
      builder: _customTrigger,
    ),
    DocsSection(
      id: 'components-popover--without-trigger',
      title: 'Without Trigger',
      description:
          'When using a Popover without a PopoverTrigger, it is up to the user '
          'to make sure that the focus is restored correctly when the popover '
          'is closed. This can be done quite easily by using the '
          'useRestoreFocusTarget hook. The Popover already uses the '
          'useRestoreFocusSource hook directly, which will restore focus to '
          'the most recently focused target on close.',
      builder: _withoutTrigger,
    ),
    DocsSection(
      id: 'components-popover--internal-update-content',
      title: 'Internal Update Content',
      builder: _internalUpdateContent,
    ),
    DocsSection(
      id: 'components-popover--appearance',
      title: 'Appearance',
      builder: _appearance,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'child',
      type: 'Widget',
      description:
          'The trigger. Rendered in place; the surface is anchored to it.',
    ),
    PropRow(name: 'content', type: 'Widget', description: 'The popover body.'),
    PropRow(
      name: 'open',
      type: 'bool',
      description: 'Whether the surface is showing.',
    ),
    PropRow(
      name: 'onOpenChanged',
      type: 'ValueChanged<bool>?',
      defaultValue: 'null',
      description:
          'Reports every open and close this widget performs — Escape, an '
          'outside tap. Null disables the popover.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentPopoverAppearance',
      defaultValue: 'FluentPopoverAppearance.normal',
      description: 'Fill treatment.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentPopoverSize',
      defaultValue: 'FluentPopoverSize.medium',
      description: 'Padding and arrow ramp.',
    ),
    PropRow(
      name: 'position',
      type: 'FluentPopoverPosition',
      defaultValue: 'FluentPopoverPosition.above',
      description: 'Which side of child the surface sits on.',
    ),
    PropRow(
      name: 'align',
      type: 'FluentPopoverAlign',
      defaultValue: 'FluentPopoverAlign.center',
      description: 'Where along that side the surface lines up.',
    ),
    PropRow(
      name: 'withArrow',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether to draw the pointing arrow.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentPopoverStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology when the surface appears.',
    ),
  ],
);

// #docregion components-popover--default
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        const Text(
          'Popover content',
          style: TextStyle(fontSize: 16, fontWeight: FluentFontWeight.semibold),
        ),
        const Text('This is some popover content'),
        FluentButton(onPressed: () {}, child: const Text('Action')),
      ],
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Popover trigger'),
    ),
  );
}
// #enddocregion components-popover--default

// #docregion components-popover--non-interactive-content
Widget _nonInteractiveContent(BuildContext context) =>
    const _NonInteractiveContent();

class _NonInteractiveContent extends StatefulWidget {
  const _NonInteractiveContent();

  @override
  State<_NonInteractiveContent> createState() => _NonInteractiveContentState();
}

class _NonInteractiveContentState extends State<_NonInteractiveContent> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    // Upstream's `tabIndex={-1}` plus `aria-labelledby` on the surface. Our
    // surface is already a semantics node of its own, so naming it is all
    // that is left: `semanticLabel` is what assistive technology announces
    // when a popover with nothing focusable inside it appears.
    semanticLabel: 'Popover content',
    content: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        Text(
          'Popover content',
          style: TextStyle(fontSize: 16, fontWeight: FluentFontWeight.semibold),
        ),
        Text('This is some non-interactive popover content.'),
      ],
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Popover trigger'),
    ),
  );
}
// #enddocregion components-popover--non-interactive-content

// #docregion components-popover--with-arrow
Widget _withArrow(BuildContext context) => const _WithArrow();

class _WithArrow extends StatefulWidget {
  const _WithArrow();

  @override
  State<_WithArrow> createState() => _WithArrowState();
}

class _WithArrowState extends State<_WithArrow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    withArrow: true,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        const Text(
          'Popover content',
          style: TextStyle(fontSize: 16, fontWeight: FluentFontWeight.semibold),
        ),
        const Text('This popover has an arrow pointing to its target'),
        FluentButton(onPressed: () {}, child: const Text('Action')),
      ],
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Popover trigger'),
    ),
  );
}
// #enddocregion components-popover--with-arrow

// #docregion components-popover--with-arrow-autosize
Widget _withArrowAutosize(BuildContext context) => const _WithArrowAutosize();

class _WithArrowAutosize extends StatefulWidget {
  const _WithArrowAutosize();

  @override
  State<_WithArrowAutosize> createState() => _WithArrowAutosizeState();
}

class _WithArrowAutosizeState extends State<_WithArrowAutosize> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    withArrow: true,
    // Upstream's `positioning: { autoSize: true }` caps the surface against the
    // viewport and then moves `overflow` off the surface so the arrow is not
    // clipped. Our surface never clips, so the port is the other half only: a
    // bounded, scrolling box supplies the height the content scrolls inside.
    content: SizedBox(
      width: 320,
      height: 300,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            const Text(
              'Popover content',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FluentFontWeight.semibold,
              ),
            ),
            FluentButton(onPressed: () {}, child: const Text('Action')),
            const Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
              'Vestibulum semper, nulla at pretium pulvinar, erat nibh '
              'ultricies risus, eget tincidunt neque nisl non nunc. Integer '
              'tempus augue nec facilisis suscipit. Aenean finibus orci id '
              'turpis euismod, sit amet varius neque porta. Curabitur et '
              'urna vel orci luctus dictum. Mauris sed eros euismod, cursus '
              'justo non, facilisis nibh. Aliquam blandit leo ut nisl '
              'tincidunt, sit amet ultrices lacus molestie. Phasellus '
              'aliquet massa non vestibulum condimentum. Vivamus posuere, '
              'ligula eu pharetra fringilla, lorem leo elementum risus, '
              'vitae tempor odio purus sed libero. Vestibulum porta nisl a '
              'metus ultricies, vel dignissim lectus facilisis. Etiam '
              'interdum mi a suscipit aliquet. Nullam rhoncus molestie '
              'purus, id porta neque consequat vitae. Sed id aliquam elit. '
              'Praesent nunc libero, vulputate vitae porta nec, venenatis '
              'sed augue. Lorem ipsum dolor sit amet, consectetur '
              'adipiscing elit. Vestibulum semper, nulla at pretium '
              'pulvinar, erat nibh ultricies risus, eget tincidunt neque '
              'nisl non nunc. Integer tempus augue nec facilisis suscipit. '
              'Aenean finibus orci id turpis euismod, sit amet varius neque '
              'porta. Curabitur et urna vel orci luctus dictum. Mauris sed '
              'eros euismod, cursus justo non, facilisis nibh. Aliquam '
              'blandit leo ut nisl tincidunt, sit amet ultrices lacus '
              'molestie. Phasellus aliquet massa non vestibulum '
              'condimentum. Vivamus posuere, ligula eu pharetra fringilla, '
              'lorem leo elementum risus, vitae tempor odio purus sed '
              'libero. Vestibulum porta nisl a metus ultricies, vel '
              'dignissim lectus facilisis. Etiam interdum mi a suscipit '
              'aliquet. Nullam rhoncus molestie purus, id porta neque '
              'consequat vitae. Sed id aliquam elit. Praesent nunc libero, '
              'vulputate vitae porta nec, venenatis sed augue. Lorem ipsum '
              'dolor sit amet, consectetur adipiscing elit. Vestibulum '
              'semper, nulla at pretium pulvinar, erat nibh ultricies '
              'risus, eget tincidunt neque nisl non nunc. Integer tempus '
              'augue nec facilisis suscipit. Aenean finibus orci id turpis '
              'euismod, sit amet varius neque porta. Curabitur et urna vel '
              'orci luctus dictum. Mauris sed eros euismod, cursus justo '
              'non, facilisis nibh. Aliquam blandit leo ut nisl tincidunt, '
              'sit amet ultrices lacus molestie. Phasellus aliquet massa '
              'non vestibulum condimentum. Vivamus posuere, ligula eu '
              'pharetra fringilla, lorem leo elementum risus, vitae tempor '
              'odio purus sed libero. Vestibulum porta nisl a metus '
              'ultricies, vel dignissim lectus facilisis. Etiam interdum mi '
              'a suscipit aliquet. Nullam rhoncus molestie purus, id porta '
              'neque consequat vitae. Sed id aliquam elit. Praesent nunc '
              'libero, vulputate vitae porta nec, venenatis sed augue. '
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
              'Vestibulum semper, nulla at pretium pulvinar, erat nibh '
              'ultricies risus, eget tincidunt neque nisl non nunc. Integer '
              'tempus augue nec facilisis suscipit. Aenean finibus orci id '
              'turpis euismod, sit amet varius neque porta. Curabitur et '
              'urna vel orci luctus dictum. Mauris sed eros euismod, cursus '
              'justo non, facilisis nibh. Aliquam blandit leo ut nisl '
              'tincidunt, sit amet ultrices lacus molestie. Phasellus '
              'aliquet massa non vestibulum condimentum. Vivamus posuere, '
              'ligula eu pharetra fringilla, lorem leo elementum risus, '
              'vitae tempor odio purus sed libero. Vestibulum porta nisl a '
              'metus ultricies, vel dignissim lectus facilisis. Etiam '
              'interdum mi a suscipit aliquet. Nullam rhoncus molestie '
              'purus, id porta neque consequat vitae. Sed id aliquam elit. '
              'Praesent nunc libero, vulputate vitae porta nec, venenatis '
              'sed augue. Lorem ipsum dolor sit amet, consectetur '
              'adipiscing elit. Vestibulum semper, nulla at pretium '
              'pulvinar, erat nibh ultricies risus, eget tincidunt neque '
              'nisl non nunc. Integer tempus augue nec facilisis suscipit. '
              'Aenean finibus orci id turpis euismod, sit amet varius neque '
              'porta. Curabitur et urna vel orci luctus dictum. Mauris sed '
              'eros euismod, cursus justo non, facilisis nibh. Aliquam '
              'blandit leo ut nisl tincidunt, sit amet ultrices lacus '
              'molestie. Phasellus aliquet massa non vestibulum '
              'condimentum. Vivamus posuere, ligula eu pharetra fringilla, '
              'lorem leo elementum risus, vitae tempor odio purus sed '
              'libero. Vestibulum porta nisl a metus ultricies, vel '
              'dignissim lectus facilisis. Etiam interdum mi a suscipit '
              'aliquet. Nullam rhoncus molestie purus, id porta neque '
              'consequat vitae. Sed id aliquam elit. Praesent nunc libero, '
              'vulputate vitae porta nec, venenatis sed augue. Lorem ipsum '
              'dolor sit amet, consectetur adipiscing elit. Vestibulum '
              'semper, nulla at pretium pulvinar, erat nibh ultricies '
              'risus, eget tincidunt neque nisl non nunc. Integer tempus '
              'augue nec facilisis suscipit. Aenean finibus orci id turpis '
              'euismod, sit amet varius neque porta. Curabitur et urna vel '
              'orci luctus dictum. Mauris sed eros euismod, cursus justo '
              'non, facilisis nibh. Aliquam blandit leo ut nisl tincidunt, '
              'sit amet ultrices lacus molestie. Phasellus aliquet massa '
              'non vestibulum condimentum. Vivamus posuere, ligula eu '
              'pharetra fringilla, lorem leo elementum risus, vitae tempor '
              'odio purus sed libero. Vestibulum porta nisl a metus '
              'ultricies, vel dignissim lectus facilisis. Etiam interdum mi '
              'a suscipit aliquet. Nullam rhoncus molestie purus, id porta '
              'neque consequat vitae. Sed id aliquam elit. Praesent nunc '
              'libero, vulputate vitae porta nec, venenatis sed augue.',
            ),
          ],
        ),
      ),
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Popover trigger'),
    ),
  );
}
// #enddocregion components-popover--with-arrow-autosize

// #docregion components-popover--trapping-focus
Widget _trappingFocus(BuildContext context) => const _TrappingFocus();

class _TrappingFocus extends StatefulWidget {
  const _TrappingFocus();

  @override
  State<_TrappingFocus> createState() => _TrappingFocusState();
}

class _TrappingFocusState extends State<_TrappingFocus> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    // There is no `trapFocus` flag to set: FluentPopover always puts its
    // content in a FocusScope that takes focus on open and hands it back on
    // close, which is upstream's trapFocus behaviour, always on.
    semanticLabel: 'Popover content',
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        const Text(
          'Popover content',
          style: TextStyle(fontSize: 16, fontWeight: FluentFontWeight.semibold),
        ),
        const Text('This is some popover content'),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            FluentButton(onPressed: () {}, child: const Text('Action')),
            FluentButton(onPressed: () {}, child: const Text('Action')),
          ],
        ),
      ],
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Popover trigger'),
    ),
  );
}
// #enddocregion components-popover--trapping-focus

// #docregion components-popover--controlling-open-and-close
Widget _controllingOpenAndClose(BuildContext context) =>
    const _ControllingOpenAndClose();

class _ControllingOpenAndClose extends StatefulWidget {
  const _ControllingOpenAndClose();

  @override
  State<_ControllingOpenAndClose> createState() =>
      _ControllingOpenAndCloseState();
}

class _ControllingOpenAndCloseState extends State<_ControllingOpenAndClose> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: <Widget>[
      FluentPopover(
        open: _open,
        onOpenChanged: (bool open) => setState(() => _open = open),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            const Text(
              'Popover content',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FluentFontWeight.semibold,
              ),
            ),
            const Text('This is some popover content'),
            FluentButton(onPressed: () {}, child: const Text('Action')),
          ],
        ),
        child: FluentButton(
          onPressed: () => setState(() => _open = true),
          child: const Text('Controlled trigger'),
        ),
      ),
      FluentCheckbox(
        checked: _open,
        label: const Text('open'),
        onChanged: (bool? checked) => setState(() => _open = checked ?? false),
      ),
    ],
  );
}
// #enddocregion components-popover--controlling-open-and-close

// #docregion components-popover--motion-custom
Widget _motionCustom(BuildContext context) => const _MotionCustom();

class _MotionCustom extends StatefulWidget {
  const _MotionCustom();

  @override
  State<_MotionCustom> createState() => _MotionCustomState();
}

class _MotionCustomState extends State<_MotionCustom> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    // Upstream swaps the surface's presence component through the
    // `surfaceMotion` slot. FluentPopover has no such slot: its entrance is
    // FluentPopoverEntrance — Fluent's own fade plus direction-aware slide —
    // and it is not replaceable, so the demo keeps the copy and shows the
    // stock entrance rather than a fade-in/blur-out.
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        const Text(
          'Popover content',
          style: TextStyle(fontSize: 16, fontWeight: FluentFontWeight.semibold),
        ),
        const Text('This popover fades in and blurs out.'),
        FluentButton(onPressed: () {}, child: const Text('Action')),
      ],
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open popover'),
    ),
  );
}
// #enddocregion components-popover--motion-custom

// #docregion components-popover--motion-disabled
Widget _motionDisabled(BuildContext context) => const _MotionDisabled();

class _MotionDisabled extends StatefulWidget {
  const _MotionDisabled();

  @override
  State<_MotionDisabled> createState() => _MotionDisabledState();
}

class _MotionDisabledState extends State<_MotionDisabled> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => MediaQuery(
    // Upstream's `surfaceMotion={null}`. FluentPopoverEntrance reads
    // MediaQuery.disableAnimationsOf, so turning animations off for the
    // subtree is the supported way to land the surface with no transition.
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: FluentPopover(
      open: _open,
      onOpenChanged: (bool open) => setState(() => _open = open),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          const Text(
            'Popover content',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FluentFontWeight.semibold,
            ),
          ),
          const Text('This popover has motion disabled'),
          FluentButton(onPressed: () {}, child: const Text('Action')),
        ],
      ),
      child: FluentButton(
        onPressed: () => setState(() => _open = true),
        child: const Text('Open popover'),
      ),
    ),
  );
}
// #enddocregion components-popover--motion-disabled

// #docregion components-popover--nested-popovers
Widget _nestedPopovers(BuildContext context) => const _NestedPopovers();

const TextStyle _nestedHeading = TextStyle(
  fontSize: 16,
  fontWeight: FluentFontWeight.semibold,
);

class _NestedPopovers extends StatefulWidget {
  const _NestedPopovers();

  @override
  State<_NestedPopovers> createState() => _NestedPopoversState();
}

class _NestedPopoversState extends State<_NestedPopovers> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        const Text('Popover content', style: _nestedHeading),
        const Text('This is some popover content'),
        FluentButton(onPressed: () {}, child: const Text('Root button')),
        const _FirstNestedPopover(),
      ],
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Root trigger'),
    ),
  );
}

class _FirstNestedPopover extends StatefulWidget {
  const _FirstNestedPopover();

  @override
  State<_FirstNestedPopover> createState() => _FirstNestedPopoverState();
}

class _FirstNestedPopoverState extends State<_FirstNestedPopover> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    semanticLabel: 'Popover content',
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        const Text('Popover content', style: _nestedHeading),
        const Text('This is some popover content'),
        FluentButton(
          onPressed: () {},
          child: const Text('First nested button'),
        ),
        const _SecondNestedPopover(),
        const _SecondNestedPopover(),
      ],
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('First nested trigger'),
    ),
  );
}

class _SecondNestedPopover extends StatefulWidget {
  const _SecondNestedPopover();

  @override
  State<_SecondNestedPopover> createState() => _SecondNestedPopoverState();
}

class _SecondNestedPopoverState extends State<_SecondNestedPopover> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    semanticLabel: 'Popover content',
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        const Text('Popover content', style: _nestedHeading),
        const Text('This is some popover content'),
        FluentButton(
          onPressed: () {},
          child: const Text('Second nested button'),
        ),
      ],
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Second nested trigger'),
    ),
  );
}
// #enddocregion components-popover--nested-popovers

// #docregion components-popover--anchor-to-custom-target
Widget _anchorToCustomTarget(BuildContext context) =>
    const _AnchorToCustomTarget();

class _AnchorToCustomTarget extends StatefulWidget {
  const _AnchorToCustomTarget();

  @override
  State<_AnchorToCustomTarget> createState() => _AnchorToCustomTargetState();
}

class _AnchorToCustomTargetState extends State<_AnchorToCustomTarget> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      // Upstream retargets the popover imperatively with a positioningRef.
      // Our surface is anchored to whatever widget is passed as `child`, so
      // the retarget is structural instead: the popover wraps the custom
      // target, and the button that opens it stands on its own.
      FluentButton(
        onPressed: () => setState(() => _open = true),
        child: const Text('Popover trigger'),
      ),
      FluentPopover(
        open: _open,
        onOpenChanged: (bool open) => setState(() => _open = open),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            const Text(
              'Popover content',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FluentFontWeight.semibold,
              ),
            ),
            const Text('This is some popover content'),
            FluentButton(onPressed: () {}, child: const Text('Action')),
          ],
        ),
        child: FluentButton(
          onPressed: () {},
          child: const Text('Custom target'),
        ),
      ),
    ],
  );
}
// #enddocregion components-popover--anchor-to-custom-target

// #docregion components-popover--custom-trigger
Widget _customTrigger(BuildContext context) => const _CustomTrigger();

class _CustomTrigger extends StatefulWidget {
  const _CustomTrigger();

  @override
  State<_CustomTrigger> createState() => _CustomTriggerState();
}

class _CustomTriggerState extends State<_CustomTrigger> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        const Text(
          'Popover content',
          style: TextStyle(fontSize: 16, fontWeight: FluentFontWeight.semibold),
        ),
        const Text('This is some popover content'),
        FluentButton(onPressed: () {}, child: const Text('Action')),
      ],
    ),
    // Upstream needs React.forwardRef so a custom trigger component can be
    // handed the ref and the interaction props. A Flutter trigger needs
    // neither: `child` is an ordinary widget and the open state is ours, so a
    // custom trigger is just a widget that calls back.
    child: _CustomPopoverTrigger(onPressed: () => setState(() => _open = true)),
  );
}

class _CustomPopoverTrigger extends StatelessWidget {
  const _CustomPopoverTrigger({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      FluentButton(onPressed: onPressed, child: const Text('Custom Trigger'));
}
// #enddocregion components-popover--custom-trigger

// #docregion components-popover--without-trigger
Widget _withoutTrigger(BuildContext context) => const _WithoutTrigger();

class _WithoutTrigger extends StatefulWidget {
  const _WithoutTrigger();

  @override
  State<_WithoutTrigger> createState() => _WithoutTriggerState();
}

class _WithoutTriggerState extends State<_WithoutTrigger> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() => _open = open),
    // There is no PopoverTrigger to leave out here — `child` is only the
    // anchor, never the thing that opens the surface. The toggle below is the
    // caller's own button, and focus return is FluentPopover's job either way:
    // it captures the focused node on open and restores it on close.
    semanticLabel: 'Popover content',
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        const Text(
          'Popover content',
          style: TextStyle(fontSize: 16, fontWeight: FluentFontWeight.semibold),
        ),
        const Text('This is some popover content'),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            FluentButton(onPressed: () {}, child: const Text('Action')),
            FluentButton(onPressed: () {}, child: const Text('Action')),
          ],
        ),
      ],
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Toggle popover'),
    ),
  );
}
// #enddocregion components-popover--without-trigger

// #docregion components-popover--internal-update-content
Widget _internalUpdateContent(BuildContext context) =>
    const _InternalUpdateContent();

class _InternalUpdateContent extends StatefulWidget {
  const _InternalUpdateContent();

  @override
  State<_InternalUpdateContent> createState() => _InternalUpdateContentState();
}

class _InternalUpdateContentState extends State<_InternalUpdateContent> {
  bool _open = false;
  bool _visible = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool open) => setState(() {
      _open = open;
      // Upstream resets the second panel whenever the popover closes.
      if (!open) {
        _visible = false;
      }
    }),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        const Text(
          'Popover content',
          style: TextStyle(fontSize: 16, fontWeight: FluentFontWeight.semibold),
        ),
        const Text('This is some popover content'),
        if (_visible)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: <Widget>[
              const Text('The second panel content'),
              FluentLink(
                inline: true,
                autofocus: true,
                onPressed: () {},
                child: const Text('and a link'),
              ),
            ],
          )
        else
          FluentButton(
            onPressed: () => setState(() => _visible = true),
            child: const Text('Action'),
          ),
      ],
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Popover trigger'),
    ),
  );
}
// #enddocregion components-popover--internal-update-content

// #docregion components-popover--appearance
Widget _appearance(BuildContext context) => const _Appearance();

class _Appearance extends StatefulWidget {
  const _Appearance();

  @override
  State<_Appearance> createState() => _AppearanceState();
}

class _AppearanceState extends State<_Appearance> {
  final Set<FluentPopoverAppearance> _open = <FluentPopoverAppearance>{};

  Widget _example(FluentPopoverAppearance appearance, String label) =>
      FluentPopover(
        appearance: appearance,
        open: _open.contains(appearance),
        onOpenChanged: (bool open) => setState(() {
          if (open) {
            _open.add(appearance);
          } else {
            _open.remove(appearance);
          }
        }),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            const Text(
              'Popover content',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FluentFontWeight.semibold,
              ),
            ),
            const Text('This is some popover content'),
            FluentButton(onPressed: () {}, child: const Text('Action')),
          ],
        ),
        child: FluentButton(
          onPressed: () => setState(() => _open.add(appearance)),
          child: Text(label),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    // tokens.spacingVerticalMNudge.
    spacing: 10,
    children: <Widget>[
      _example(
        FluentPopoverAppearance.normal,
        'Default appearance Popover trigger',
      ),
      _example(
        FluentPopoverAppearance.brand,
        'Brand appearance Popover trigger',
      ),
      _example(
        FluentPopoverAppearance.inverted,
        'Inverted appearance Popover trigger',
      ),
    ],
  );
}

// #enddocregion components-popover--appearance
