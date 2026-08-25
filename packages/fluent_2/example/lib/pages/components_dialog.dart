import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Dialog docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// `FluentDialog` is controlled: it takes a required `open` bool and an
/// `onOpenChange` callback and never flips itself. Upstream's `DialogTrigger`
/// wrapper has no counterpart, so every section below owns a `bool _open` and
/// wires its own trigger — including the ones upstream writes uncontrolled.
const DocsPage dialogPage = DocsPage(
  id: 'components-dialog',
  title: 'Dialog',
  description:
      'Dialog is a window overlaid on either the primary window or another '
      'dialog window. Windows under a modal dialog are inert. That is, users '
      'cannot interact with content outside an active dialog window. Inert '
      'content outside an active dialog is typically visually obscured or '
      'dimmed so it is difficult to discern, and in some implementations, '
      'attempts to interact with the inert content cause the dialog to close.',
  source: 'lib/pages/components_dialog.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-dialog--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-dialog--non-modal',
      title: 'Non Modal',
      description:
          'A non-modal Dialog by default presents no backdrop, allowing '
          'elements outside of the Dialog to be interacted with. DialogTitle '
          'compound component will present by default a closeButton. Note: if '
          'an element outside of the dialog is focused then it will not be '
          'possible to close the dialog with the Escape key.',
      builder: _nonModal,
    ),
    DocsSection(
      id: 'components-dialog--alert',
      title: 'Alert',
      description:
          "An alert Dialog is a modal dialog that interrupts the user's "
          'workflow to communicate an important message and acquire a '
          'response. Examples include action confirmation prompts and error '
          'message confirmations. The alert Dialog role enables assistive '
          'technologies and browsers to distinguish alert dialogs from other '
          'dialogs so they have the option of giving alert dialogs special '
          'treatment, such as playing a system alert sound. By default '
          'clicking on backdrop will not dismiss an alert Dialog.',
      builder: _alert,
    ),
    DocsSection(
      id: 'components-dialog--backdrop-appearance',
      title: 'Backdrop Appearance',
      description:
          'The backdrop slot on DialogSurface accepts an appearance prop that '
          'allows you to explicitly control the backdrop appearance of the '
          'dialog. By default, DialogSurface automatically determines the '
          'backdrop appearance based on context: standalone dialogs show a '
          'dimmed backdrop, while nested dialogs (inside another Dialog) show '
          'a transparent backdrop to avoid stacking multiple dimmed layers. '
          'Use backdrop={{ appearance: "dimmed" }} when rendering a Dialog '
          'inside components that internally use Dialog (like OverlayDrawer) '
          'but the dialog should visually behave as standalone with a dimmed '
          "backdrop. 'dimmed': Always shows a dimmed backdrop, regardless of "
          "nesting. 'transparent': Always shows a transparent backdrop.",
      builder: _backdropAppearance,
    ),
    DocsSection(
      id: 'components-dialog--scrolling-long-content',
      title: 'Scrolling Long Content',
      description:
          'By default DialogContent should grow until it fits viewport size, '
          'overflowed content will be scrollable',
      builder: _scrollingLongContent,
    ),
    DocsSection(
      id: 'components-dialog--keep-rendered-in-the-dom',
      title: 'Keep Rendered In The DOM',
      description:
          'Keep the dialog in the DOM tree when it is closed by setting the '
          'unmountOnClose prop to false. This is useful when you want to '
          'preserve the state of the dialog content between opens. For this '
          'example, the scroll position will be preserved when reopening the '
          'dialog.',
      builder: _keepRenderedInTheDom,
    ),
    DocsSection(
      id: 'components-dialog--actions',
      title: 'Actions',
      description:
          'Dialogs should be used for providing the user with quick prompt '
          'options where decisions should be made quickly. They should be '
          'used for actions that are not reversible, such as deleting an '
          'item. DialogActions should be used to provide the user with a set '
          'of actions to choose from. The actions should be clear and '
          'concise, and should be used to guide the user to the next step in '
          'the process.',
      builder: _actions,
    ),
    DocsSection(
      id: 'components-dialog--fluid-actions',
      title: 'Fluid Actions',
      description:
          'Use the fluid prop on the DialogActions component so that it spans '
          'the entire width of the dialog. This prop can be useful for having '
          'large number of actions. A Dialog should have no more than two '
          'actions.',
      builder: _fluidActions,
    ),
    DocsSection(
      id: 'components-dialog--no-focusable-element',
      title: 'No Focusable Element',
      description:
          'A Dialog should always have at least one focusable element. Some '
          'accessibility issues might happen if no focusable element is '
          'provided, like this one caught in Talkback. In the case when there '
          'is no focusable element inside a Dialog the only way to close the '
          'Dialog would be clicking on the backdrop. A common scenario for no '
          'focusable elements on a dialog is lazy loaded content, where the '
          'content (with focusable elements) is added after the Dialog is '
          'mounted. In that case, it is recommended to manually focus on the '
          'desired focusable element after the content is loaded.',
      builder: _noFocusableElement,
    ),
    DocsSection(
      id: 'components-dialog--controlling-open-and-close',
      title: 'Controlling Open And Close',
      description:
          'The opening and close of the Dialog can be controlled with your '
          'own state. The onOpenChange callback will provide the hints for '
          'the state and triggers based on the appropriate event.',
      builder: _controllingOpenAndClose,
    ),
    DocsSection(
      id: 'components-dialog--change-focus',
      title: 'Change Focus',
      description:
          'Changing the default focused element can be done in an effect',
      builder: _changeFocus,
    ),
    DocsSection(
      id: 'components-dialog--trigger-outside-dialog',
      title: 'Trigger Outside Dialog',
      description:
          'When using a Dialog without a DialogTrigger, you become '
          "responsible for managing the dialog's behavior. This applies to: "
          'Opening dialogs programmatically (via state, API calls, side '
          'effects). Opening nested dialogs where the inner dialog is not '
          'wrapped in a DialogTrigger. Your responsibilities: Control the '
          'open state - React to the onOpenChange callback and ensure the '
          "open state reflects the dialog's visibility. Restore focus - When "
          'the dialog closes, you must restore focus to the element that '
          'triggered the open.',
      builder: _triggerOutsideDialog,
    ),
    DocsSection(
      id: 'components-dialog--custom-trigger',
      title: 'Custom Trigger',
      description:
          'Native HTML elements and Fluent components have first class '
          'support as children of DialogTrigger, so they will be injected '
          'automatically with the correct props for interactions and '
          'accessibility attributes. It is possible to use your own custom '
          'React component as a child of DialogTrigger. DialogTrigger '
          'provides proper aria attributes for a modal trigger.',
      builder: _customTrigger,
    ),
    DocsSection(
      id: 'components-dialog--with-form',
      title: 'With Form',
      description:
          'Having a form inside the Dialog its quite simple, you simply add a '
          'form element between DialogSurface and DialogBody to ensure all '
          'the content between them are properly wrapped inside the '
          'formulary. This allows a button inside DialogActions to be '
          'properly used as submission button. Keep in mind that controlling '
          'the open state of the Dialog might be ideal in this scenario, '
          'since validation and submission are possibly synchronous '
          'activities.',
      builder: _withForm,
    ),
    DocsSection(
      id: 'components-dialog--title-custom-action',
      title: 'Title Custom Action',
      description:
          "By default if Dialog has modalType='non-modal' a button with a "
          'close icon is provided to close the dialog as action slot. This '
          'slot can be customized to add a different kind of action, that '
          "it'll be available in any kind of Dialog, ignoring the modalType "
          "property, here's an example replacing the simple close icon with a "
          'Fluent UI Button using the same icon.',
      builder: _titleCustomAction,
    ),
    DocsSection(
      id: 'components-dialog--title-no-action',
      title: 'Title No Action',
      description:
          'As any other slot, action={null} can be provided to opt out of '
          'rendering any action',
      builder: _titleNoAction,
    ),
    DocsSection(
      id: 'components-dialog--confirmation',
      title: 'Confirmation',
      description:
          'A confirmation dialog is a type of very short dialog that sends '
          'focus directly to an action button, usually at the end of the '
          "dialog. For this type of dialog it makes sense to set the dialog's "
          'accessible name to the title, and the accessible description to '
          'the content via aria-labelledby and aria-describedby. This should '
          'not be done for dialogs with longer content.',
      builder: _confirmation,
    ),
    DocsSection(
      id: 'components-dialog--motion-custom',
      title: 'Motion Custom',
      description:
          "Dialog's surfaceMotion slot accepts Scale params directly, such as "
          "duration, outScale, easing, and animateOpacity. DialogSurface's "
          'backdropMotion slot accepts Fade params. Both slots also support '
          'the children render function, which allows replacing the default '
          'motion with a custom implementation. This story demonstrates the '
          'simpler direct prop approach.',
      builder: _motionCustom,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'child',
      type: 'Widget',
      description:
          'The trigger. Stays in the tree whether the dialog is open or not.',
    ),
    PropRow(name: 'content', type: 'Widget', description: 'The body.'),
    PropRow(
      name: 'open',
      type: 'bool',
      description:
          'Whether the dialog is showing. Controlled — see onOpenChange.',
    ),
    PropRow(
      name: 'onOpenChange',
      type: 'ValueChanged<bool>?',
      defaultValue: 'null',
      description: 'Invoked with false when the user asks to close.',
    ),
    PropRow(
      name: 'title',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The heading. Rendered in subtitle1.',
    ),
    PropRow(
      name: 'actions',
      type: 'List<Widget>',
      defaultValue: '[]',
      description: 'The primary actions, at the end of the footer row.',
    ),
    PropRow(
      name: 'secondaryActions',
      type: 'List<Widget>',
      defaultValue: '[]',
      description: 'The secondary actions, at the start of the footer row.',
    ),
    PropRow(
      name: 'showCloseButton',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether the header carries a close button.',
    ),
    PropRow(
      name: 'modalType',
      type: 'FluentDialogModalType',
      defaultValue: 'FluentDialogModalType.modal',
      description:
          'Whether the dialog blocks the page, and how it may be dismissed.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentDialogSize',
      defaultValue: 'FluentDialogSize.medium',
      description: 'Width and action layout.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentDialogStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it '
          'wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: "Announced by assistive technology as the dialog's name.",
    ),
    PropRow(
      name: 'closeButtonSemanticLabel',
      type: 'String',
      defaultValue: "'Close'",
      description:
          "Announced for the header's close button, which has no text of its "
          'own.',
    ),
  ],
);

// #docregion components-dialog--default
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentDialog(
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    title: const Text('Dialog title'),
    content: const Text(
      'Lorem ipsum dolor sit amet consectetur adipisicing elit. Quisquam '
      'exercitationem cumque repellendus eaque est dolor eius expedita nulla '
      'ullam? Tenetur reprehenderit aut voluptatum impedit voluptates in '
      'natus iure cumque eaque?',
    ),
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () {},
        child: const Text('Do Something'),
      ),
      FluentButton(
        onPressed: () => setState(() => _open = false),
        child: const Text('Close'),
      ),
    ],
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open dialog'),
    ),
  );
}
// #enddocregion components-dialog--default

// #docregion components-dialog--non-modal
Widget _nonModal(BuildContext context) => const _NonModal();

class _NonModal extends StatefulWidget {
  const _NonModal();

  @override
  State<_NonModal> createState() => _NonModalState();
}

class _NonModalState extends State<_NonModal> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentDialog(
    modalType: FluentDialogModalType.nonModal,
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    title: const Text('Non-modal dialog title'),
    content: const Text(
      'Lorem, ipsum dolor sit amet consectetur adipisicing elit. Aliquid, '
      'explicabo repudiandae impedit doloribus laborum quidem maxime dolores '
      'perspiciatis non ipsam, nostrum commodi quis autem sequi, incidunt '
      'cum? Consequuntur, repellendus nostrum?',
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open non-modal dialog'),
    ),
  );
}
// #enddocregion components-dialog--non-modal

// #docregion components-dialog--alert
Widget _alert(BuildContext context) => const _Alert();

class _Alert extends StatefulWidget {
  const _Alert();

  @override
  State<_Alert> createState() => _AlertState();
}

class _AlertState extends State<_Alert> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentDialog(
    // `alert` renders the scrim but refuses to be dismissed by it, which is
    // exactly upstream's `modalType="alert"`.
    modalType: FluentDialogModalType.alert,
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    title: const Text('Alert dialog title'),
    content: const Text(
      'This dialog cannot be dismissed by clicking on the backdrop. Close '
      'button should be pressed to dismiss this Alert, or `Escape` keydown.',
    ),
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () {},
        child: const Text('Do Something'),
      ),
      FluentButton(
        onPressed: () => setState(() => _open = false),
        child: const Text('Close'),
      ),
    ],
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open Alert dialog'),
    ),
  );
}
// #enddocregion components-dialog--alert

// #docregion components-dialog--backdrop-appearance
Widget _backdropAppearance(BuildContext context) => const _BackdropAppearance();

class _BackdropAppearance extends StatefulWidget {
  const _BackdropAppearance();

  @override
  State<_BackdropAppearance> createState() => _BackdropAppearanceState();
}

class _BackdropAppearanceState extends State<_BackdropAppearance> {
  bool _drawerOpen = false;
  bool _dialogOpen = false;
  String? _backdropAppearance;

  // Upstream's `backdrop={{ appearance }}` slot has no counterpart. The scrim
  // is a style token here, so 'transparent' is spelled as a fully transparent
  // `scrimColor` and 'dimmed' as the theme default.
  FluentDialogStyle? get _style => _backdropAppearance == 'transparent'
      ? const FluentDialogStyle(
          scrimColor: WidgetStatePropertyAll<Color?>(Color(0x00000000)),
        )
      : null;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () => setState(() => _drawerOpen = true),
        child: const Text('Open Drawer'),
      ),
      FluentDrawer(
        open: _drawerOpen,
        onDismiss: () => setState(() => _drawerOpen = false),
        // Upstream's OverlayDrawer is 320 wide; the radio group and its field
        // label need more room than that once the labels are real text.
        size: FluentDrawerSize.medium,
        header: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: Text('Drawer')),
              FluentButton.icon(
                icon: const Icon(FluentIcons.dismiss_24_regular),
                semanticLabel: 'Close',
                appearance: FluentButtonAppearance.subtle,
                onPressed: () => setState(() => _drawerOpen = false),
              ),
            ],
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: <Widget>[
            FluentField(
              label: const Text('Backdrop appearance'),
              child: FluentRadioGroup<String>(
                value: _backdropAppearance,
                onChanged: (String value) =>
                    setState(() => _backdropAppearance = value),
                semanticLabel: 'Backdrop appearance',
                children: const <Widget>[
                  FluentRadio<String>(value: 'dimmed', label: Text('Dimmed')),
                  FluentRadio<String>(
                    value: 'transparent',
                    label: Text('Transparent'),
                  ),
                ],
              ),
            ),
            FluentDialog(
              open: _dialogOpen,
              onOpenChange: (bool open) => setState(() => _dialogOpen = open),
              style: _style,
              title: const Text('Dialog'),
              content: const Text(
                'This Dialog is rendered inside an OverlayDrawer, which '
                'internally uses Dialog. By default, nested dialogs have a '
                'backdrop applied based on inner context. Use the backdrop '
                'prop to override this behavior.',
              ),
              actions: <Widget>[
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  onPressed: () => setState(() => _dialogOpen = false),
                  child: const Text('Close'),
                ),
              ],
              child: FluentButton(
                onPressed: () => setState(() => _dialogOpen = true),
                child: const Text('Open Dialog'),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
// #enddocregion components-dialog--backdrop-appearance

// #docregion components-dialog--scrolling-long-content
Widget _scrollingLongContent(BuildContext context) =>
    const _ScrollingLongContent();

/// The five paragraphs upstream prints twice over.
const List<String> _scrollingParagraphs = <String>[
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do '
      'eiusmod tempor incididunt ut labore et dolore magna aliqua. Nisl '
      'pretium fusce id velit ut tortor. Leo vel fringilla est '
      'ullamcorper. Eget est lorem ipsum dolor sit amet consectetur '
      'adipiscing elit. In mollis nunc sed id semper risus in hendrerit '
      'gravida. Ullamcorper sit amet risus nullam eget felis eget. Dolor '
      'sed viverra ipsum nunc aliquet bibendum. Facilisi morbi tempus '
      'iaculis urna id volutpat. Porta non pulvinar neque laoreet '
      'suspendisse. Nunc id cursus metus aliquam eleifend mi in. A '
      'iaculis at erat pellentesque adipiscing commodo. Proin nibh nisl '
      'condimentum id. In hac habitasse platea dictumst vestibulum '
      'rhoncus est. Non tellus orci ac auctor augue mauris augue neque. '
      'Enim nulla aliquet porttitor lacus luctus accumsan tortor. '
      'Nascetur ridiculus mus mauris vitae ultricies leo integer. '
      'Ullamcorper eget nulla facilisi etiam dignissim. Leo in vitae '
      'turpis massa sed elementum tempus egestas sed.',
  'Ut enim blandit volutpat maecenas volutpat. Venenatis urna cursus '
      'eget nunc scelerisque viverra mauris. Neque aliquam vestibulum '
      'morbi blandit. Porttitor eget dolor morbi non. Nisi quis eleifend '
      'quam adipiscing vitae. Aliquam ultrices sagittis orci a '
      'scelerisque purus semper. Interdum varius sit amet mattis '
      'vulputate enim nulla aliquet. Ut sem viverra aliquet eget sit amet '
      'tellus cras. Sit amet tellus cras adipiscing enim eu turpis '
      'egestas. Amet cursus sit amet dictum sit amet justo donec enim. '
      'Neque gravida in fermentum et sollicitudin ac. Arcu cursus euismod '
      'quis viverra nibh cras pulvinar mattis nunc. Ultrices eros in '
      'cursus turpis massa tincidunt dui. Nisl rhoncus mattis rhoncus '
      'urna neque viverra justo. Odio pellentesque diam volutpat commodo '
      'sed egestas. Nunc mi ipsum faucibus vitae aliquet nec ullamcorper. '
      'Ipsum nunc aliquet bibendum enim. Faucibus ornare suspendisse sed '
      'nisi lacus sed. Sapien nec sagittis aliquam malesuada bibendum '
      'arcu vitae elementum. Metus vulputate eu scelerisque felis '
      'imperdiet.',
  'Consequat interdum varius sit amet mattis vulputate enim. Amet '
      'cursus sit amet dictum sit amet justo. Eget aliquet nibh praesent '
      'tristique magna sit. Ut consequat semper viverra nam libero justo. '
      'Pharetra massa massa ultricies mi. Sem viverra aliquet eget sit '
      'amet. Pulvinar mattis nunc sed blandit libero volutpat sed. '
      'Pharetra diam sit amet nisl suscipit adipiscing bibendum. '
      'Consectetur adipiscing elit ut aliquam. Volutpat diam ut venenatis '
      'tellus in metus vulputate. Scelerisque in dictum non consectetur a '
      'erat. Venenatis lectus magna fringilla urna porttitor rhoncus. '
      'Vitae congue mauris rhoncus aenean vel elit. Neque laoreet '
      'suspendisse interdum consectetur. Ultrices gravida dictum fusce ut '
      'placerat orci. Bibendum ut tristique et egestas quis ipsum '
      'suspendisse. Mattis rhoncus urna neque viverra justo nec ultrices '
      'dui. Elit duis tristique sollicitudin nibh sit amet.',
  'At risus viverra adipiscing at. Interdum posuere lorem ipsum dolor '
      'sit amet consectetur adipiscing elit. Nunc vel risus commodo '
      'viverra maecenas. Sit amet est placerat in egestas erat imperdiet '
      'sed euismod. Turpis egestas maecenas pharetra convallis posuere. '
      'Egestas tellus rutrum tellus pellentesque eu tincidunt tortor '
      'aliquam. Dolor sit amet consectetur adipiscing elit. Aliquam purus '
      'sit amet luctus venenatis lectus magna fringilla. Scelerisque '
      'fermentum dui faucibus in ornare quam viverra. Egestas maecenas '
      'pharetra convallis posuere morbi leo urna. A diam sollicitudin '
      'tempor id eu nisl nunc. Lectus sit amet est placerat.',
  'Mattis ullamcorper velit sed ullamcorper morbi tincidunt ornare '
      'massa eget. At tellus at urna condimentum mattis pellentesque id '
      'nibh. Dui faucibus in ornare quam. Tincidunt id aliquet risus '
      'feugiat in ante metus dictum. Adipiscing commodo elit at imperdiet '
      'dui. Dolor sed viverra ipsum nunc. Sodales neque sodales ut etiam '
      'sit amet nisl. Hendrerit dolor magna eget est lorem ipsum dolor '
      'sit amet. Mattis molestie a iaculis at erat pellentesque '
      'adipiscing. Adipiscing elit duis tristique sollicitudin nibh sit '
      'amet commodo nulla. Fringilla urna porttitor rhoncus dolor purus.',
];

class _ScrollingLongContent extends StatefulWidget {
  const _ScrollingLongContent();

  @override
  State<_ScrollingLongContent> createState() => _ScrollingLongContentState();
}

class _ScrollingLongContentState extends State<_ScrollingLongContent> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentDialog(
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    title: const Text('Dialog title'),
    // `buildFluentDialog` already wraps the body in a Flexible
    // SingleChildScrollView under a viewport-height cap, so a body this long
    // scrolls while the title and the actions stay put.
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: <Widget>[
        for (final String paragraph in <String>[
          ..._scrollingParagraphs,
          ..._scrollingParagraphs,
        ])
          Text(paragraph),
      ],
    ),
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () {},
        child: const Text('Do Something'),
      ),
      FluentButton(
        onPressed: () => setState(() => _open = false),
        child: const Text('Close'),
      ),
    ],
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open dialog'),
    ),
  );
}
// #enddocregion components-dialog--scrolling-long-content

// #docregion components-dialog--keep-rendered-in-the-dom
Widget _keepRenderedInTheDom(BuildContext context) =>
    const _KeepRenderedInTheDom();

/// The five paragraphs upstream prints, the first three of them twice.
const List<String> _keepRenderedParagraphs = <String>[
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do '
      'eiusmod tempor incididunt ut labore et dolore magna aliqua. Nisl '
      'pretium fusce id velit ut tortor. Leo vel fringilla est '
      'ullamcorper. Eget est lorem ipsum dolor sit amet consectetur '
      'adipiscing elit. In mollis nunc sed id semper risus in hendrerit '
      'gravida. Ullamcorper sit amet risus nullam eget felis eget. Dolor '
      'sed viverra ipsum nunc aliquet bibendum. Facilisi morbi tempus '
      'iaculis urna id volutpat. Porta non pulvinar neque laoreet '
      'suspendisse. Nunc id cursus metus aliquam eleifend mi in. A '
      'iaculis at erat pellentesque adipiscing commodo. Proin nibh nisl '
      'condimentum id. In hac habitasse platea dictumst vestibulum '
      'rhoncus est. Non tellus orci ac auctor augue mauris augue neque. '
      'Enim nulla aliquet porttitor lacus luctus accumsan tortor. '
      'Nascetur ridiculus mus mauris vitae ultricies leo integer. '
      'Ullamcorper eget nulla facilisi etiam dignissim. Leo in vitae '
      'turpis massa sed elementum tempus egestas sed.',
  'Ut enim blandit volutpat maecenas volutpat. Venenatis urna cursus '
      'eget nunc scelerisque viverra mauris. Neque aliquam vestibulum '
      'morbi blandit. Porttitor eget dolor morbi non. Nisi quis eleifend '
      'quam adipiscing vitae. Aliquam ultrices sagittis orci a '
      'scelerisque purus semper. Interdum varius sit amet mattis '
      'vulputate enim nulla aliquet. Ut sem viverra aliquet eget sit amet '
      'tellus cras. Sit amet tellus cras adipiscing enim eu turpis '
      'egestas. Amet cursus sit amet dictum sit amet justo donec enim. '
      'Neque gravida in fermentum et sollicitudin ac. Arcu cursus euismod '
      'quis viverra nibh cras pulvinar mattis nunc. Ultrices eros in '
      'cursus turpis massa tincidunt dui. Nisl rhoncus mattis rhoncus '
      'urna neque viverra justo. Odio pellentesque diam volutpat commodo '
      'sed egestas. Nunc mi ipsum faucibus vitae aliquet nec ullamcorper. '
      'Ipsum nunc aliquet bibendum enim. Faucibus ornare suspendisse sed '
      'nisi lacus sed. Sapien nec sagittis aliquam malesuada bibendum '
      'arcu vitae elementum. Metus vulputate eu scelerisque felis '
      'imperdiet.',
  'Consequat interdum varius sit amet mattis vulputate enim. Amet '
      'cursus sit amet dictum sit amet justo. Eget aliquet nibh praesent '
      'tristique magna sit. Ut consequat semper viverra nam libero justo. '
      'Pharetra massa massa ultricies mi. Sem viverra aliquet eget sit '
      'amet. Pulvinar mattis nunc sed blandit libero volutpat sed. '
      'Pharetra diam sit amet nisl suscipit adipiscing bibendum. '
      'Consectetur adipiscing elit ut aliquam. Volutpat diam ut venenatis '
      'tellus in metus vulputate. Scelerisque in dictum non consectetur a '
      'erat. Venenatis lectus magna fringilla urna porttitor rhoncus. '
      'Vitae congue mauris rhoncus aenean vel elit. Neque laoreet '
      'suspendisse interdum consectetur. Ultrices gravida dictum fusce ut '
      'placerat orci. Bibendum ut tristique et egestas quis ipsum '
      'suspendisse. Mattis rhoncus urna neque viverra justo nec ultrices '
      'dui. Elit duis tristique sollicitudin nibh sit amet.',
  'At risus viverra adipiscing at. Interdum posuere lorem ipsum dolor '
      'sit amet consectetur adipiscing elit. Nunc vel risus commodo '
      'viverra maecenas. Sit amet est placerat in egestas erat imperdiet '
      'sed euismod. Turpis egestas maecenas pharetra convallis posuere. '
      'Egestas tellus rutrum tellus pellentesque eu tincidunt tortor '
      'aliquam. Dolor sit amet consectetur adipiscing elit. Aliquam purus '
      'sit amet luctus venenatis lectus magna fringilla. Scelerisque '
      'fermentum dui faucibus in ornare quam viverra. Egestas maecenas '
      'pharetra convallis posuere morbi leo urna. A diam sollicitudin '
      'tempor id eu nisl nunc. Lectus sit amet est placerat.',
  'Mattis ullamcorper velit sed ullamcorper morbi tincidunt ornare '
      'massa eget. At tellus at urna condimentum mattis pellentesque id '
      'nibh. Dui faucibus in ornare quam. Tincidunt id aliquet risus '
      'feugiat in ante metus dictum. Adipiscing commodo elit at imperdiet '
      'dui. Dolor sed viverra ipsum nunc. Sodales neque sodales ut etiam '
      'sit amet nisl. Hendrerit dolor magna eget est lorem ipsum dolor '
      'sit amet. Mattis molestie a iaculis at erat pellentesque '
      'adipiscing. Adipiscing elit duis tristique sollicitudin nibh sit '
      'amet commodo nulla. Fringilla urna porttitor rhoncus dolor purus.',
];

class _KeepRenderedInTheDom extends StatefulWidget {
  const _KeepRenderedInTheDom();

  @override
  State<_KeepRenderedInTheDom> createState() => _KeepRenderedInTheDomState();
}

class _KeepRenderedInTheDomState extends State<_KeepRenderedInTheDom> {
  // Upstream's `unmountOnClose={false}` has no counterpart: FluentDialog always
  // removes its OverlayEntry on close, so the body's viewport — and with it the
  // ScrollPosition holding the offset — is built fresh on every open. Flutter's
  // own answer to that is PageStorage: a keyed Scrollable writes its offset
  // into the bucket when a scroll ends and reads it back when the next position
  // is created, which is the job the retained DOM node did upstream. A
  // ScrollController cannot do it — `initialScrollOffset` is fixed at
  // construction, so a controller held out here hands every fresh viewport the
  // same zero.
  //
  // The height cap is what makes any of it real. `buildFluentDialog` already
  // wraps `content` in a scroll view of its own, so a body left to grow is
  // handed unbounded height: it never scrolls, never saves an offset, and the
  // dialog's own viewport — which has no key and no controller — does the
  // scrolling instead.
  final PageStorageBucket _bucket = PageStorageBucket();
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentDialog(
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    title: const Text('Dialog title'),
    content: PageStorage(
      bucket: _bucket,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
          key: const PageStorageKey<String>('keep-rendered-body'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: <Widget>[
              for (final String paragraph in <String>[
                ..._keepRenderedParagraphs,
                ..._keepRenderedParagraphs.take(3),
              ])
                Text(paragraph),
            ],
          ),
        ),
      ),
    ),
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () {},
        child: const Text('Do Something'),
      ),
      FluentButton(
        onPressed: () => setState(() => _open = false),
        child: const Text('Close'),
      ),
    ],
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open dialog'),
    ),
  );
}
// #enddocregion components-dialog--keep-rendered-in-the-dom

// #docregion components-dialog--actions
Widget _actions(BuildContext context) => const _Actions();

class _Actions extends StatefulWidget {
  const _Actions();

  @override
  State<_Actions> createState() => _ActionsState();
}

class _ActionsState extends State<_Actions> {
  bool _open = false;
  bool _checked = false;

  @override
  Widget build(BuildContext context) => FluentDialog(
    modalType: FluentDialogModalType.nonModal,
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    title: const Text('Delete this campaign?'),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: <Widget>[
        const Text(
          'You\'re about to delete the campaign group "Campaign name that '
          'goes up to two lines". This will also delete all associated '
          'campaign resources, including the overview page, files, '
          'publications, conversations, and so forth. Please back up any '
          'content you need before proceeding.',
        ),
        FluentCheckbox(
          checked: _checked,
          onChanged: (bool? checked) =>
              setState(() => _checked = checked ?? false),
          // FluentCheckbox lays the label out in a min-width Row, so a label
          // this long needs a cap of its own to wrap instead of overflowing.
          label: const SizedBox(
            width: 500,
            child: Text(
              'Yes, delete this campaign and all its associated resources',
            ),
          ),
        ),
      ],
    ),
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: _checked ? () => setState(() => _open = false) : null,
        child: const Text('Delete'),
      ),
      FluentButton(
        onPressed: () => setState(() => _open = false),
        child: const Text('Cancel'),
      ),
    ],
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open campaign dialog'),
    ),
  );
}
// #enddocregion components-dialog--actions

// #docregion components-dialog--fluid-actions
Widget _fluidActions(BuildContext context) => const _FluidActions();

class _FluidActions extends StatefulWidget {
  const _FluidActions();

  @override
  State<_FluidActions> createState() => _FluidActionsState();
}

class _FluidActionsState extends State<_FluidActions> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentDialog(
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    // There is no `fluid` flag. `FluentDialogSize.small` is what stacks the
    // actions into a full-width column, and it also narrows the surface to
    // 320 — so the medium width is put back through `style.maxWidth`, leaving
    // only the action layout changed.
    size: FluentDialogSize.small,
    style: const FluentDialogStyle(
      maxWidth: WidgetStatePropertyAll<double?>(600),
    ),
    title: const Text('Dialog title'),
    content: const Text(
      'Lorem ipsum dolor sit amet consectetur adipisicing elit. Quisquam '
      'exercitationem cumque repellendus eaque est dolor eius expedita nulla '
      'ullam? Tenetur reprehenderit aut voluptatum impedit voluptates in '
      'natus iure cumque eaque?',
    ),
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () {},
        child: const Text('Do Something'),
      ),
      FluentButton(onPressed: () {}, child: const Text('Something Else')),
      FluentButton(onPressed: () {}, child: const Text('Something Else')),
      FluentButton(
        onPressed: () => setState(() => _open = false),
        child: const Text('Close'),
      ),
    ],
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open dialog'),
    ),
  );
}
// #enddocregion components-dialog--fluid-actions

// #docregion components-dialog--no-focusable-element
Widget _noFocusableElement(BuildContext context) => const _NoFocusableElement();

class _NoFocusableElement extends StatefulWidget {
  const _NoFocusableElement();

  @override
  State<_NoFocusableElement> createState() => _NoFocusableElementState();
}

class _NoFocusableElementState extends State<_NoFocusableElement> {
  bool _modalOpen = false;
  bool _nonModalOpen = false;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: <Widget>[
      FluentDialog(
        open: _modalOpen,
        onOpenChange: (bool open) => setState(() => _modalOpen = open),
        // FluentDialog draws a header close button by default; it is switched
        // off here so the dialog genuinely has nothing focusable, which is the
        // whole point of the story.
        showCloseButton: false,
        title: const Text('Dialog Title'),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: <Widget>[
            Text('⛔️ A Dialog without focusable elements is not recommended!'),
            Text('✅ Escape key works'),
            Text(
              '✅ Backdrop click still works to ensure this modal can be '
              'closed',
            ),
          ],
        ),
        child: FluentButton(
          onPressed: () => setState(() => _modalOpen = true),
          child: const Text('Open modal dialog'),
        ),
      ),
      FluentDialog(
        modalType: FluentDialogModalType.nonModal,
        open: _nonModalOpen,
        onOpenChange: (bool open) => setState(() => _nonModalOpen = open),
        showCloseButton: false,
        title: const Text('Dialog Title'),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: <Widget>[
            Text(
              '⛔️ A modal Dialog without focusable elements is not '
              'recommended!',
            ),
            Text('✅ Escape key works'),
          ],
        ),
        child: FluentButton(
          onPressed: () => setState(() => _nonModalOpen = true),
          child: const Text('Open non-modal dialog'),
        ),
      ),
    ],
  );
}
// #enddocregion components-dialog--no-focusable-element

// #docregion components-dialog--controlling-open-and-close
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
  Widget build(BuildContext context) => FluentDialog(
    // FluentDialog is only ever controlled — it never flips `open` itself, so
    // this is the shape every dialog on the page already has.
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    title: const Text('Dialog title'),
    content: const Text(
      'Lorem ipsum dolor sit amet consectetur adipisicing elit. Quisquam '
      'exercitationem cumque repellendus eaque est dolor eius expedita nulla '
      'ullam? Tenetur reprehenderit aut voluptatum impedit voluptates in '
      'natus iure cumque eaque?',
    ),
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () {},
        child: const Text('Do Something'),
      ),
      FluentButton(
        onPressed: () => setState(() => _open = false),
        child: const Text('Close'),
      ),
    ],
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open dialog'),
    ),
  );
}
// #enddocregion components-dialog--controlling-open-and-close

// #docregion components-dialog--change-focus
Widget _changeFocus(BuildContext context) => const _ChangeFocus();

class _ChangeFocus extends StatefulWidget {
  const _ChangeFocus();

  @override
  State<_ChangeFocus> createState() => _ChangeFocusState();
}

class _ChangeFocusState extends State<_ChangeFocus> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentDialog(
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    title: const Text('Dialog title'),
    content: const Text(
      'This dialog focus on the second button instead of the first',
    ),
    secondaryActions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.outline,
        onPressed: () {},
        child: const Text('Third Action'),
      ),
    ],
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () {},
        child: const Text('Do Something'),
      ),
      FluentButton(
        // Upstream moves focus from an effect once the dialog is open. Flutter
        // has the affordance built in: the dialog's FocusScope honours an
        // autofocus descendant when it takes focus.
        autofocus: true,
        onPressed: () => setState(() => _open = false),
        child: const Text('Close'),
      ),
    ],
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open dialog'),
    ),
  );
}
// #enddocregion components-dialog--change-focus

// #docregion components-dialog--trigger-outside-dialog
Widget _triggerOutsideDialog(BuildContext context) =>
    const _TriggerOutsideDialog();

class _TriggerOutsideDialog extends StatefulWidget {
  const _TriggerOutsideDialog();

  @override
  State<_TriggerOutsideDialog> createState() => _TriggerOutsideDialogState();
}

class _TriggerOutsideDialogState extends State<_TriggerOutsideDialog> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentButton(
        onPressed: () => setState(() => _open = true),
        child: const Text('Open Dialog'),
      ),
      FluentDialog(
        open: _open,
        onOpenChange: (bool open) => setState(() => _open = open),
        title: const Text('Dialog title'),
        content: const Text(
          'Lorem ipsum dolor sit amet consectetur adipisicing elit. Quisquam '
          'exercitationem cumque repellendus eaque est dolor eius expedita '
          'nulla ullam? Tenetur reprehenderit aut voluptatum impedit '
          'voluptates in natus iure cumque eaque?',
        ),
        actions: <Widget>[
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: () {},
            child: const Text('Do Something'),
          ),
          FluentButton(
            onPressed: () => setState(() => _open = false),
            child: const Text('Close'),
          ),
        ],
        // No trigger of its own: `child` is the slot the trigger normally
        // occupies, so a dialog opened from elsewhere passes an empty box.
        // Restoring focus is not the caller's job here — FluentDialog records
        // the primary focus on open and hands it back on close.
        child: const SizedBox.shrink(),
      ),
    ],
  );
}
// #enddocregion components-dialog--trigger-outside-dialog

// #docregion components-dialog--custom-trigger
Widget _customTrigger(BuildContext context) => const _CustomTrigger();

/// Any widget can be the trigger — `child` is a plain slot, so there is no
/// ref forwarding to arrange.
class _CustomDialogTrigger extends StatelessWidget {
  const _CustomDialogTrigger({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      FluentButton(onPressed: onPressed, child: const Text('Custom Trigger'));
}

class _CustomTrigger extends StatefulWidget {
  const _CustomTrigger();

  @override
  State<_CustomTrigger> createState() => _CustomTriggerState();
}

class _CustomTriggerState extends State<_CustomTrigger> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentDialog(
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    title: const Text('Dialog title'),
    content: const Text(
      'Lorem ipsum dolor sit amet consectetur adipisicing elit. Quisquam '
      'exercitationem cumque repellendus eaque est dolor eius expedita nulla '
      'ullam? Tenetur reprehenderit aut voluptatum impedit voluptates in '
      'natus iure cumque eaque?',
    ),
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () {},
        child: const Text('Do Something'),
      ),
      FluentButton(
        onPressed: () => setState(() => _open = false),
        child: const Text('Close'),
      ),
    ],
    child: _CustomDialogTrigger(onPressed: () => setState(() => _open = true)),
  );
}
// #enddocregion components-dialog--custom-trigger

// #docregion components-dialog--with-form
Widget _withForm(BuildContext context) => const _WithForm();

class _WithForm extends StatefulWidget {
  const _WithForm();

  @override
  State<_WithForm> createState() => _WithFormState();
}

class _WithFormState extends State<_WithForm> {
  bool _open = false;

  // Upstream's `<form onSubmit>` wraps the body so a DialogActions button can
  // submit it. There is no form element here; the primary action calls this
  // directly, which is the same wiring with one less indirection. Upstream
  // alerts on submit — closing the dialog is the nearest thing this showroom
  // can do without leaving the page.
  void _handleSubmit() => setState(() => _open = false);

  @override
  Widget build(BuildContext context) => FluentDialog(
    modalType: FluentDialogModalType.nonModal,
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    title: const Text('Dialog title'),
    content: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: <Widget>[
        FluentField(
          required: true,
          label: Text('Email input'),
          child: FluentInput(semanticLabel: 'Email input'),
        ),
        FluentField(
          required: true,
          label: Text('Password input'),
          child: FluentInput(
            obscureText: true,
            semanticLabel: 'Password input',
          ),
        ),
      ],
    ),
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: _handleSubmit,
        child: const Text('Submit'),
      ),
      FluentButton(
        onPressed: () => setState(() => _open = false),
        child: const Text('Close'),
      ),
    ],
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open formulary dialog'),
    ),
  );
}
// #enddocregion components-dialog--with-form

// #docregion components-dialog--title-custom-action
Widget _titleCustomAction(BuildContext context) => const _TitleCustomAction();

class _TitleCustomAction extends StatefulWidget {
  const _TitleCustomAction();

  @override
  State<_TitleCustomAction> createState() => _TitleCustomActionState();
}

class _TitleCustomActionState extends State<_TitleCustomAction> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentDialog(
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    // There is no `action` slot to swap: FluentDialog's header close button
    // already *is* a subtle icon FluentButton carrying the dismiss glyph, in
    // every modalType. Only its accessible name is the caller's to set, so
    // upstream's `aria-label="close"` maps to `closeButtonSemanticLabel`.
    closeButtonSemanticLabel: 'close',
    title: const Text('Dialog title'),
    content: const Text(
      'Lorem, ipsum dolor sit amet consectetur adipisicing elit. Aliquid, '
      'explicabo repudiandae impedit doloribus laborum quidem maxime dolores '
      'perspiciatis non ipsam, nostrum commodi quis autem sequi, incidunt '
      'cum? Consequuntur, repellendus nostrum?',
    ),
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open dialog'),
    ),
  );
}
// #enddocregion components-dialog--title-custom-action

// #docregion components-dialog--title-no-action
Widget _titleNoAction(BuildContext context) => const _TitleNoAction();

class _TitleNoAction extends StatefulWidget {
  const _TitleNoAction();

  @override
  State<_TitleNoAction> createState() => _TitleNoActionState();
}

class _TitleNoActionState extends State<_TitleNoAction> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentDialog(
    modalType: FluentDialogModalType.nonModal,
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    // Upstream's `action={null}`.
    showCloseButton: false,
    title: const Text('Non-modal dialog title without an action'),
    content: const Text(
      'Lorem, ipsum dolor sit amet consectetur adipisicing elit. Aliquid, '
      'explicabo repudiandae impedit doloribus laborum quidem maxime dolores '
      'perspiciatis non ipsam, nostrum commodi quis autem sequi, incidunt '
      'cum? Consequuntur, repellendus nostrum?',
    ),
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () => setState(() => _open = false),
        child: const Text('Close'),
      ),
    ],
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open non-modal dialog'),
    ),
  );
}
// #enddocregion components-dialog--title-no-action

// #docregion components-dialog--confirmation
Widget _confirmation(BuildContext context) => const _Confirmation();

class _Confirmation extends StatefulWidget {
  const _Confirmation();

  @override
  State<_Confirmation> createState() => _ConfirmationState();
}

class _ConfirmationState extends State<_Confirmation> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentDialog(
    open: _open,
    onOpenChange: (bool open) => setState(() => _open = open),
    // Upstream's `aria-labelledby` pointing at the title: a short confirmation
    // is worth naming, which `semanticLabel` does through `namesRoute`.
    semanticLabel: 'Delete dialogSpec_final_FINAL_v3.jpg',
    title: const Text('Delete dialogSpec_final_FINAL_v3.jpg'),
    content: const Text(
      'This action is permanent. Are you sure you want to continue?',
    ),
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        // Focus goes straight to the action, which is what makes this a
        // confirmation rather than a dialog that happens to be short.
        autofocus: true,
        onPressed: () => setState(() => _open = false),
        child: const Text('Delete file'),
      ),
      FluentButton(
        onPressed: () => setState(() => _open = false),
        child: const Text('Cancel'),
      ),
    ],
    child: FluentButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Delete file'),
    ),
  );
}
// #enddocregion components-dialog--confirmation

// #docregion components-dialog--motion-custom
// Upstream drives `Dialog`'s `surfaceMotion` and `DialogSurface`'s
// `backdropMotion` slots from these controls. FluentDialog exposes no motion
// hook — `fluentDialogSurfaceEnter`, `fluentDialogSurfaceExit`,
// `fluentDialogScrim` and `fluentDialogOutScale` are package constants — so the
// controls are live and the dialog animation is not.
Widget _motionCustom(BuildContext context) => const _MotionCustom();

class _MotionCustom extends StatefulWidget {
  const _MotionCustom();

  @override
  State<_MotionCustom> createState() => _MotionCustomState();
}

class _MotionCustomState extends State<_MotionCustom> {
  double _duration = 600;
  double _outScale = 0.5;
  double _backdropDuration = 300;
  bool _animateOpacity = true;
  bool _open = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: <Widget>[
      FluentField(
        label: Text('Surface duration: ${_duration.round()}ms'),
        child: FluentSlider(
          min: 100,
          max: 2000,
          step: 50,
          value: _duration,
          onChanged: (double value) => setState(() => _duration = value),
        ),
      ),
      FluentField(
        label: Text('Surface outScale: ${_outScale.toStringAsFixed(2)}'),
        child: FluentSlider(
          max: 1,
          step: 0.05,
          value: _outScale,
          onChanged: (double value) => setState(() => _outScale = value),
        ),
      ),
      FluentField(
        label: Text('Backdrop duration: ${_backdropDuration.round()}ms'),
        child: FluentSlider(
          max: 1000,
          step: 50,
          value: _backdropDuration,
          onChanged: (double value) =>
              setState(() => _backdropDuration = value),
        ),
      ),
      FluentSwitch(
        checked: _animateOpacity,
        label: const Text('Surface animateOpacity'),
        onChanged: (bool value) => setState(() => _animateOpacity = value),
      ),
      const SizedBox(height: 8),
      FluentDialog(
        open: _open,
        onOpenChange: (bool open) => setState(() => _open = open),
        title: const Text('Dialog with custom motion params'),
        content: const Text(
          "This dialog's surface animation is driven by direct surfaceMotion "
          'params (`duration`, `outScale`, `easing`, `animateOpacity`). Its '
          'backdrop fade is tuned independently via backdropMotion '
          '(`duration`).',
        ),
        actions: <Widget>[
          FluentButton(
            onPressed: () => setState(() => _open = false),
            child: const Text('Close'),
          ),
        ],
        child: FluentButton(
          onPressed: () => setState(() => _open = true),
          child: const Text('Open Dialog'),
        ),
      ),
    ],
  );
}

// #enddocregion components-dialog--motion-custom
