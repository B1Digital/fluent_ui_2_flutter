import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Drawer docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Upstream ships three components — `OverlayDrawer`, `InlineDrawer` and the
/// combined `Drawer`. fluent_2 ships one, `FluentDrawer`, whose
/// [FluentDrawerType] axis is the same decision: `overlay` is `OverlayDrawer`,
/// `inline` is `InlineDrawer`, and flipping the axis at runtime is `Drawer`.
const DocsPage drawerPage = DocsPage(
  id: 'components-drawer',
  title: 'Drawer',
  description:
      'The Drawer gives users a quick entry point to configuration and '
      'information. It should be used when retaining context is beneficial to '
      'users. There are three main components to represent a Drawer: '
      'OverlayDrawer: An overlay Drawer renders on top of the whole page. By '
      'default blocks the screen and will require the user\'s full attention. '
      'Uses Dialog component under the hood. InlineDrawer: An inline Drawer '
      'renders within a container and can be placed next to any content. '
      'Drawer: A combination of OverlayDrawer and InlineDrawer. Used when '
      'toggling between the two modes is necessary. Often used for '
      'responsiveness.',
  source: 'lib/pages/components_drawer.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-drawer--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-drawer--overlay',
      title: 'Overlay',
      description:
          'OverlayDrawer contains supplementary content and is used for '
          'complex creation, edit, or management experiences. For example, '
          'viewing details about an item in a list or editing settings. By '
          "default, drawer is blocking and signifies that the user's full "
          'attention is required when making configurations.',
      builder: _overlay,
    ),
    DocsSection(
      id: 'components-drawer--overlay-no-modal',
      title: 'Overlay No Modal',
      description:
          'An overlay is optional depending on whether or not interacting with '
          "the background content is beneficial to the user's "
          'context/scenario. By setting the modalType prop to non-modal, the '
          'Drawer will not be blocking and the user can interact with the '
          'background content.',
      builder: _overlayNoModal,
    ),
    DocsSection(
      id: 'components-drawer--overlay-inside-container',
      title: 'Overlay Inside Container',
      description:
          'The overlay Drawer can be rendered inside a specific container by '
          'setting the mountNode prop to the desired container element. This '
          'approach is useful when you need the Drawer to appear within a '
          'particular section of the DOM, rather than being attached to the '
          'root element.',
      builder: _overlayInsideContainer,
    ),
    DocsSection(
      id: 'components-drawer--inline',
      title: 'Inline',
      description:
          'InlineDrawer is often used for navigation that is not dismissible. '
          'As it is on the same level as the main surface, users can still '
          'interact with other UI elements. This could be useful for swapping '
          'between different items in the main surface.',
      builder: _inline,
    ),
    DocsSection(
      id: 'components-drawer--position',
      title: 'Position',
      description:
          'When a Drawer is invoked, it slides in from either the start or end '
          'side, or bottom of the screen. This can be specified by the '
          'position prop.',
      builder: _position,
    ),
    DocsSection(
      id: 'components-drawer--size',
      title: 'Size',
      description:
          'The size prop controls the width of the drawer. The default is '
          'small.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-drawer--custom-size',
      title: 'Custom Size',
      description:
          'The Drawer can be sized to any custom width, by overriding the '
          'width style property.',
      builder: _customSize,
    ),
    DocsSection(
      id: 'components-drawer--separator',
      title: 'Separator',
      description:
          'The separator prop adds a line separator between the drawer and the '
          'content. Its placement will be determined by the position prop',
      builder: _separator,
    ),
    DocsSection(
      id: 'components-drawer--with-title',
      title: 'With Title',
      description:
          'DrawerHeaderTitle is a component that provides a structured heading '
          'for a Drawer and can be used to display a title and an action. '
          'Although it works as a standalone component, it is intended to be '
          'used within a DrawerHeader. The title renders an h2 element by '
          'default but it can be customized using the heading prop.',
      builder: _withTitle,
    ),
    DocsSection(
      id: 'components-drawer--with-navigation',
      title: 'With Navigation',
      description:
          'Drawers can have any type of content and one great case is to have '
          'a toolbar in the header. Drawer ships with a DrawerHeaderNavigation '
          'component that can be used to display a toolbar in the header of '
          'the drawer. This can be combined with DrawerHeaderTitle to display '
          'a title in the header.',
      builder: _withNavigation,
    ),
    DocsSection(
      id: 'components-drawer--with-scroll',
      title: 'With Scroll',
      description:
          'By default, the drawer will not scroll its content when it '
          'overflows. To enable this behavior, the DrawerBody component can be '
          'used to wrap the content of the drawer. Important note: if the '
          'drawer content does not contain any focusable elements, the '
          'DrawerBody itself needs a tabIndex of 0 to ensure keyboard scroll '
          'access.',
      builder: _withScroll,
    ),
    DocsSection(
      id: 'components-drawer--motion-custom',
      title: 'Motion Custom',
      description:
          'Drawer animations can be customized using the Motion APIs, together '
          'with the surfaceMotion prop.',
      builder: _motionCustom,
    ),
    DocsSection(
      id: 'components-drawer--motion-disabled',
      title: 'Motion Disabled',
      description:
          'To disable the Drawer transition animation, you can set both '
          'surfaceMotion and backdropMotion props of the Drawer to null.',
      builder: _motionDisabled,
    ),
    DocsSection(
      id: 'components-drawer--multiple-levels',
      title: 'Multiple Levels',
      description:
          'When there is a need to display multiple levels of content, the '
          'drawer can be used to display them. It is not recommended to invoke '
          'one drawer from another, as it can lead to a confusing experience '
          'for the user. Instead, when a second level of a Drawer is required, '
          'the L2 content pushes the L1 Drawer content to the side and out of '
          'the Drawer. This can be achieved by using the Motion APIs to '
          'animate the inner content of the Drawer.',
      builder: _multipleLevels,
    ),
    DocsSection(
      id: 'components-drawer--keep-rendered-in-the-dom',
      title: 'Keep Rendered In The DOM',
      builder: _keepRenderedInTheDom,
    ),
    DocsSection(
      id: 'components-drawer--always-open',
      title: 'Always Open',
      description:
          'A drawer can be always open, in which case it will not be able to '
          'be closed by the user. This is useful for drawers that are used for '
          'navigation, and should always be visible.',
      builder: _alwaysOpen,
    ),
    DocsSection(
      id: 'components-drawer--prevent-close',
      title: 'Prevent Close',
      description:
          'By setting the modalType prop to alert and not providing an '
          'onOpenChange handler, the Drawer will not be closable by clicking '
          'outside nor using the "ESC" key. This is useful for scenarios where '
          'the user must interact with the Drawer before continuing, when '
          'opening a Drawer is a critical action or when multiple Drawers are '
          'open at the same time.',
      builder: _preventClose,
    ),
    DocsSection(
      id: 'components-drawer--responsive',
      title: 'Responsive',
      description:
          'When using the Drawer component, the type prop can be used to '
          'change the drawer type based on the viewport size. The example '
          'below will change the drawer type to overlay when the viewport is '
          'smaller than 720px.',
      builder: _responsive,
    ),
    DocsSection(
      id: 'components-drawer--resizable',
      title: 'Resizable',
      description: 'This example shows how to implement a resizable drawer.',
      builder: _resizable,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'child',
      type: 'Widget',
      description: 'The body of the drawer.',
    ),
    PropRow(
      name: 'open',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the drawer is showing. Changing it runs the transition.',
    ),
    PropRow(
      name: 'onDismiss',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          'Invoked when the user asks to close: Escape, or a tap on the scrim.',
    ),
    PropRow(
      name: 'type',
      type: 'FluentDrawerType',
      defaultValue: 'FluentDrawerType.overlay',
      description: 'Overlay or inline.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentDrawerSize',
      defaultValue: 'FluentDrawerSize.small',
      description: 'Width, and the transition length that goes with it.',
    ),
    PropRow(
      name: 'position',
      type: 'FluentDrawerPosition',
      defaultValue: 'FluentDrawerPosition.start',
      description: 'Which edge the drawer is anchored to, in reading order.',
    ),
    PropRow(
      name: 'header',
      type: 'List<Widget>',
      defaultValue: '[]',
      description:
          'Header children, stacked in a column. Empty means no header.',
    ),
    PropRow(
      name: 'footer',
      type: 'List<Widget>',
      defaultValue: '[]',
      description: 'Footer children, laid out in a row. Empty means no footer.',
    ),
    PropRow(
      name: 'separator',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether an inline drawer draws the rule between itself and the '
          'page.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentDrawerStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology as the name of the drawer.',
    ),
  ],
);

// #docregion components-drawer--default
// Upstream's `Drawer` is the combined component: one element whose `type` prop
// flips it between overlay and inline. `FluentDrawer` is that component —
// `FluentDrawerType` is the same axis — so the radio group drives it directly.
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  bool _isOpen = false;
  FluentDrawerType _type = FluentDrawerType.overlay;

  @override
  Widget build(BuildContext context) => Container(
    height: 480,
    decoration: const BoxDecoration(
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xFFCCCCCC), width: 2),
      ),
    ),
    child: Row(
      children: <Widget>[
        FluentDrawer(
          type: _type,
          separator: true,
          open: _isOpen,
          onDismiss: () => setState(() => _isOpen = false),
          header: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(child: Text('Default Drawer')),
                FluentButton.icon(
                  appearance: FluentButtonAppearance.subtle,
                  semanticLabel: 'Close',
                  icon: const Icon(FluentIcons.dismiss_24_regular),
                  onPressed: () => setState(() => _isOpen = false),
                ),
              ],
            ),
          ],
          child: const Text('Drawer content'),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  onPressed: () => setState(() => _isOpen = !_isOpen),
                  child: Text(
                    _type == FluentDrawerType.inline ? 'Toggle' : 'Open',
                  ),
                ),
                const SizedBox(height: 24),
                FluentField(
                  label: const Text('Type'),
                  child: FluentRadioGroup<FluentDrawerType>(
                    value: _type,
                    onChanged: (FluentDrawerType value) =>
                        setState(() => _type = value),
                    children: const <Widget>[
                      FluentRadio<FluentDrawerType>(
                        value: FluentDrawerType.overlay,
                        label: Text('Overlay (Default)'),
                      ),
                      FluentRadio<FluentDrawerType>(
                        value: FluentDrawerType.inline,
                        label: Text('Inline'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
// #enddocregion components-drawer--default

// #docregion components-drawer--overlay
Widget _overlay(BuildContext context) => const _Overlay();

class _Overlay extends StatefulWidget {
  const _Overlay();

  @override
  State<_Overlay> createState() => _OverlayState();
}

class _OverlayState extends State<_Overlay> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // An overlay drawer paints nothing where it is written — the panel lives
      // in the Overlay — so it can sit anywhere in the tree.
      FluentDrawer(
        open: _isOpen,
        semanticLabel: 'Overlay Drawer',
        onDismiss: () => setState(() => _isOpen = false),
        header: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: Text('Overlay Drawer')),
              FluentButton.icon(
                appearance: FluentButtonAppearance.subtle,
                semanticLabel: 'Close',
                icon: const Icon(FluentIcons.dismiss_24_regular),
                onPressed: () => setState(() => _isOpen = false),
              ),
            ],
          ),
        ],
        child: const Text('Drawer content'),
      ),
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () => setState(() => _isOpen = true),
        child: const Text('Open Drawer'),
      ),
    ],
  );
}
// #enddocregion components-drawer--overlay

// #docregion components-drawer--overlay-no-modal
// FluentDrawer has no `non-modal` mode: an overlay drawer always lays a scrim
// over the page, and that scrim swallows pointers. Clearing the scrim colour
// removes the dimming so the page behind still reads as available, but it is
// not yet interactive while the drawer is open.
Widget _overlayNoModal(BuildContext context) => const _OverlayNoModal();

class _OverlayNoModal extends StatefulWidget {
  const _OverlayNoModal();

  @override
  State<_OverlayNoModal> createState() => _OverlayNoModalState();
}

class _OverlayNoModalState extends State<_OverlayNoModal> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentDrawer(
        open: _isOpen,
        semanticLabel: 'Overlay Drawer',
        onDismiss: () => setState(() => _isOpen = false),
        style: const FluentDrawerStyle(
          scrimColor: WidgetStatePropertyAll<Color?>(Color(0x00000000)),
        ),
        header: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: Text('Overlay Drawer')),
              FluentButton.icon(
                appearance: FluentButtonAppearance.subtle,
                semanticLabel: 'Close',
                icon: const Icon(FluentIcons.dismiss_24_regular),
                onPressed: () => setState(() => _isOpen = false),
              ),
            ],
          ),
        ],
        child: const Text('Drawer content'),
      ),
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () => setState(() => _isOpen = !_isOpen),
        child: const Text('Toggle'),
      ),
    ],
  );
}
// #enddocregion components-drawer--overlay-no-modal

// #docregion components-drawer--overlay-inside-container
// `mountNode` by another name. FluentDrawer inserts an overlay drawer into the
// nearest enclosing Overlay, so putting an Overlay inside the container keeps
// the panel and its scrim inside that container. An OverlayEntry is built once
// rather than on every parent rebuild, so the open flag travels through a
// ValueNotifier instead of setState.
Widget _overlayInsideContainer(BuildContext context) =>
    const _OverlayInsideContainer();

class _OverlayInsideContainer extends StatefulWidget {
  const _OverlayInsideContainer();

  @override
  State<_OverlayInsideContainer> createState() =>
      _OverlayInsideContainerState();
}

class _OverlayInsideContainerState extends State<_OverlayInsideContainer> {
  final ValueNotifier<bool> _open = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 500,
          height: 300,
          decoration: BoxDecoration(
            color: theme.colors.brandBackground2,
            border: Border.all(
              color: theme.colors.neutralStroke1,
              width: FluentStroke.thicker,
            ),
          ),
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(
                builder: (BuildContext context) => ValueListenableBuilder<bool>(
                  valueListenable: _open,
                  builder: (BuildContext context, bool open, Widget? _) =>
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              'Drawer will be rendered within this container',
                            ),
                          ),
                          FluentDrawer(
                            open: open,
                            semanticLabel: 'Overlay Drawer',
                            onDismiss: () => _open.value = false,
                            header: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Expanded(child: Text('Overlay Drawer')),
                                  FluentButton.icon(
                                    appearance: FluentButtonAppearance.subtle,
                                    semanticLabel: 'Close',
                                    icon: const Icon(
                                      FluentIcons.dismiss_24_regular,
                                    ),
                                    onPressed: () => _open.value = false,
                                  ),
                                ],
                              ),
                            ],
                            child: const Text('Drawer content'),
                          ),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FluentButton(
          appearance: FluentButtonAppearance.primary,
          onPressed: () => _open.value = true,
          child: const Text('Open Drawer'),
        ),
      ],
    );
  }
}
// #enddocregion components-drawer--overlay-inside-container

// #docregion components-drawer--inline
Widget _inline(BuildContext context) => const _Inline();

class _Inline extends StatefulWidget {
  const _Inline();

  @override
  State<_Inline> createState() => _InlineState();
}

class _InlineState extends State<_Inline> {
  bool _startOpen = false;
  bool _endOpen = false;

  @override
  Widget build(BuildContext context) => Container(
    height: 480,
    decoration: const BoxDecoration(
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xFFCCCCCC), width: 2),
      ),
    ),
    child: Row(
      children: <Widget>[
        _InlineDrawerExample(
          open: _startOpen,
          position: FluentDrawerPosition.start,
          title: 'Start Inline Drawer',
          onClose: () => setState(() => _startOpen = false),
        ),
        Expanded(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    FluentButton(
                      appearance: FluentButtonAppearance.primary,
                      onPressed: () => setState(() => _startOpen = !_startOpen),
                      child: const Text('Toggle start'),
                    ),
                    FluentButton(
                      appearance: FluentButtonAppearance.primary,
                      onPressed: () => setState(() => _endOpen = !_endOpen),
                      child: const Text('Toggle end'),
                    ),
                    // FluentDrawerPosition is start/end only — the drawer
                    // anchors to a vertical edge, in reading order — so there
                    // is no bottom drawer for this button to toggle.
                    const FluentButton(
                      appearance: FluentButtonAppearance.primary,
                      onPressed: null,
                      child: Text('Toggle bottom'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 100,
                  itemBuilder: (BuildContext context, int index) =>
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Lorem, ipsum dolor sit amet consectetur adipisicing '
                          'elit. Tempore voluptatem similique reiciendis, ipsa '
                          'accusamus distinctio dolorum quisquam, tenetur '
                          'minima animi autem nobis. Molestias totam natus, '
                          'deleniti nam itaque placeat quisquam!',
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
        _InlineDrawerExample(
          open: _endOpen,
          position: FluentDrawerPosition.end,
          title: 'End Inline Drawer',
          onClose: () => setState(() => _endOpen = false),
        ),
      ],
    ),
  );
}

class _InlineDrawerExample extends StatelessWidget {
  const _InlineDrawerExample({
    required this.open,
    required this.position,
    required this.title,
    required this.onClose,
  });

  final bool open;
  final FluentDrawerPosition position;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => FluentDrawer(
    type: FluentDrawerType.inline,
    position: position,
    open: open,
    header: <Widget>[
      Row(
        children: <Widget>[
          Expanded(child: Text(title)),
          FluentButton.icon(
            appearance: FluentButtonAppearance.subtle,
            semanticLabel: 'Close',
            icon: const Icon(FluentIcons.dismiss_24_regular),
            onPressed: onClose,
          ),
        ],
      ),
    ],
    child: const Text('Drawer content'),
  );
}
// #enddocregion components-drawer--inline

// #docregion components-drawer--position
Widget _position(BuildContext context) => const _Position();

class _Position extends StatefulWidget {
  const _Position();

  @override
  State<_Position> createState() => _PositionState();
}

class _PositionState extends State<_Position> {
  bool _isOpen = false;
  FluentDrawerPosition _position = FluentDrawerPosition.start;

  void _open(FluentDrawerPosition position) => setState(() {
    _position = position;
    _isOpen = true;
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentDrawer(
        position: _position,
        open: _isOpen,
        onDismiss: () => setState(() => _isOpen = false),
        header: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _position == FluentDrawerPosition.start
                      ? 'Start Drawer'
                      : 'End Drawer',
                ),
              ),
              FluentButton.icon(
                appearance: FluentButtonAppearance.subtle,
                semanticLabel: 'Close',
                icon: const Icon(FluentIcons.dismiss_24_regular),
                onPressed: () => setState(() => _isOpen = false),
              ),
            ],
          ),
        ],
        child: const Text('Drawer content'),
      ),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: <Widget>[
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: () => _open(FluentDrawerPosition.start),
            child: const Text('Open start'),
          ),
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: () => _open(FluentDrawerPosition.end),
            child: const Text('Open end'),
          ),
          // FluentDrawerPosition is start/end only: the drawer anchors to a
          // vertical edge, in reading order, and flips with Directionality.
          // There is no bottom edge to anchor to, so this button is inert.
          const FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: null,
            child: Text('Open Bottom'),
          ),
        ],
      ),
    ],
  );
}
// #enddocregion components-drawer--position

// #docregion components-drawer--size
Widget _size(BuildContext context) => const _Size();

const Map<FluentDrawerSize, String> _sizeLabels = <FluentDrawerSize, String>{
  FluentDrawerSize.small: 'Small (Default)',
  FluentDrawerSize.medium: 'Medium',
  FluentDrawerSize.large: 'Large',
  FluentDrawerSize.full: 'Full',
};

class _Size extends StatefulWidget {
  const _Size();

  @override
  State<_Size> createState() => _SizeState();
}

class _SizeState extends State<_Size> {
  bool _open = false;
  FluentDrawerSize _size = FluentDrawerSize.small;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentDrawer(
        size: _size,
        position: FluentDrawerPosition.end,
        open: _open,
        onDismiss: () => setState(() => _open = false),
        header: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text('${_sizeLabels[_size]} size')),
              FluentButton.icon(
                appearance: FluentButtonAppearance.subtle,
                semanticLabel: 'Close',
                icon: const Icon(FluentIcons.dismiss_24_regular),
                onPressed: () => setState(() => _open = false),
              ),
            ],
          ),
        ],
        child: const Text('Drawer content'),
      ),
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () => setState(() => _open = true),
        child: const Text('Open Drawer'),
      ),
      const SizedBox(height: 24),
      FluentField(
        label: const Text('Size'),
        child: FluentRadioGroup<FluentDrawerSize>(
          value: _size,
          onChanged: (FluentDrawerSize value) => setState(() => _size = value),
          children: <Widget>[
            for (final MapEntry<FluentDrawerSize, String> entry
                in _sizeLabels.entries)
              FluentRadio<FluentDrawerSize>(
                value: entry.key,
                label: Text(entry.value),
              ),
          ],
        ),
      ),
    ],
  );
}
// #enddocregion components-drawer--size

// #docregion components-drawer--custom-size
// Upstream overrides the panel's `width` style property. Ours is a style token
// like every other: FluentDrawerStyle.width is merged last and wins over the
// width FluentDrawerSize would have chosen.
Widget _customSize(BuildContext context) => const _CustomSize();

class _CustomSize extends StatefulWidget {
  const _CustomSize();

  @override
  State<_CustomSize> createState() => _CustomSizeState();
}

class _CustomSizeState extends State<_CustomSize> {
  final TextEditingController _controller = TextEditingController(text: '600');

  bool _open = false;
  int _customSize = 600;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentDrawer(
        position: FluentDrawerPosition.end,
        open: _open,
        onDismiss: () => setState(() => _open = false),
        style: FluentDrawerStyle(
          width: WidgetStatePropertyAll<double?>(_customSize.toDouble()),
        ),
        header: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text('Drawer with ${_customSize}px size')),
              FluentButton.icon(
                appearance: FluentButtonAppearance.subtle,
                semanticLabel: 'Close',
                icon: const Icon(FluentIcons.dismiss_24_regular),
                onPressed: () => setState(() => _open = false),
              ),
            ],
          ),
        ],
        child: const Text('Drawer content'),
      ),
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () => setState(() => _open = true),
        child: const Text('Open Drawer'),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: 320,
        child: FluentField(
          label: const Text('Size'),
          child: FluentInput(
            controller: _controller,
            keyboardType: TextInputType.number,
            onChanged: (String value) =>
                setState(() => _customSize = int.tryParse(value) ?? 0),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-drawer--custom-size

// #docregion components-drawer--separator
Widget _separator(BuildContext context) => const _Separator();

class _Separator extends StatefulWidget {
  const _Separator();

  @override
  State<_Separator> createState() => _SeparatorState();
}

class _SeparatorState extends State<_Separator> {
  bool _startOpen = true;
  bool _endOpen = true;

  @override
  Widget build(BuildContext context) => Container(
    height: 480,
    decoration: const BoxDecoration(
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xFFCCCCCC), width: 2),
      ),
    ),
    child: Row(
      children: <Widget>[
        _SeparatorDrawerExample(
          open: _startOpen,
          position: FluentDrawerPosition.start,
          onClose: () => setState(() => _startOpen = false),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: <Widget>[
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  onPressed: () => setState(() => _startOpen = !_startOpen),
                  child: const Text('Toggle start'),
                ),
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  onPressed: () => setState(() => _endOpen = !_endOpen),
                  child: const Text('Toggle end'),
                ),
                // FluentDrawerPosition is start/end only, so the third drawer
                // upstream stacks under the row has no equivalent here.
                const FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  onPressed: null,
                  child: Text('Toggle bottom'),
                ),
              ],
            ),
          ),
        ),
        _SeparatorDrawerExample(
          open: _endOpen,
          position: FluentDrawerPosition.end,
          onClose: () => setState(() => _endOpen = false),
        ),
      ],
    ),
  );
}

class _SeparatorDrawerExample extends StatelessWidget {
  const _SeparatorDrawerExample({
    required this.open,
    required this.position,
    required this.onClose,
  });

  final bool open;
  final FluentDrawerPosition position;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => FluentDrawer(
    type: FluentDrawerType.inline,
    separator: true,
    position: position,
    open: open,
    header: <Widget>[
      Row(
        children: <Widget>[
          const Expanded(child: Text('Drawer with separator')),
          FluentButton.icon(
            appearance: FluentButtonAppearance.subtle,
            semanticLabel: 'Close',
            icon: const Icon(FluentIcons.dismiss_24_regular),
            onPressed: onClose,
          ),
        ],
      ),
    ],
    child: const Text('Drawer content'),
  );
}
// #enddocregion components-drawer--separator

// #docregion components-drawer--with-title
// `header` is a list of widgets stacked in a column, so a drawer header title
// is whatever you put in it — there is no DrawerHeaderTitle to instantiate.
// Upstream's `heading` prop picks the HTML tag; the property that carries is
// the heading level, which Semantics reports to assistive technology.
Widget _withTitle(BuildContext context) => Align(
  alignment: Alignment.centerLeft,
  child: SizedBox(
    height: 600,
    child: FluentDrawer(
      type: FluentDrawerType.inline,
      open: true,
      style: const FluentDrawerStyle(
        width: WidgetStatePropertyAll<double?>(400),
      ),
      header: <Widget>[
        Semantics(headingLevel: 2, child: const Text('Drawer with title')),
        Semantics(headingLevel: 1, child: const Text('Drawer with custom tag')),
        Semantics(
          headingLevel: 2,
          child: Row(
            children: <Widget>[
              const Expanded(child: Text('Drawer with title and action')),
              FluentButton.icon(
                appearance: FluentButtonAppearance.subtle,
                semanticLabel: 'Close',
                icon: const Icon(FluentIcons.dismiss_24_regular),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
      child: const SizedBox.shrink(),
    ),
  ),
);
// #enddocregion components-drawer--with-title

// #docregion components-drawer--with-navigation
Widget _withNavigation(BuildContext context) => const _WithNavigation();

class _WithNavigation extends StatefulWidget {
  const _WithNavigation();

  @override
  State<_WithNavigation> createState() => _WithNavigationState();
}

class _WithNavigationState extends State<_WithNavigation> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentDrawer(
        position: FluentDrawerPosition.start,
        open: _isOpen,
        onDismiss: () => setState(() => _isOpen = false),
        header: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FluentButton.icon(
                semanticLabel: 'Back',
                appearance: FluentButtonAppearance.subtle,
                icon: const Icon(FluentIcons.arrow_left_24_regular),
                onPressed: () {},
              ),
              FluentToolbar(
                items: <Widget>[
                  FluentButton.icon(
                    semanticLabel: 'Reload content',
                    appearance: FluentButtonAppearance.subtle,
                    icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
                    onPressed: () {},
                  ),
                  FluentButton.icon(
                    semanticLabel: 'Settings',
                    appearance: FluentButtonAppearance.subtle,
                    icon: const Icon(FluentIcons.settings_24_regular),
                    onPressed: () {},
                  ),
                  FluentButton.icon(
                    semanticLabel: 'Close panel',
                    appearance: FluentButtonAppearance.subtle,
                    icon: const Icon(FluentIcons.dismiss_24_regular),
                    onPressed: () => setState(() => _isOpen = false),
                  ),
                ],
              ),
            ],
          ),
          const Text('Title goes here'),
        ],
        child: const Text('Drawer content'),
      ),
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () => setState(() => _isOpen = true),
        child: const Text('Open Drawer'),
      ),
    ],
  );
}
// #enddocregion components-drawer--with-navigation

// #docregion components-drawer--with-scroll
// The drawer's body slot fills whatever height is left between header and
// footer, so scrolling is a matter of what you put in it: a plain Text
// overflows, a SingleChildScrollView scrolls.
Widget _withScroll(BuildContext context) => const Wrap(
  spacing: 32,
  runSpacing: 32,
  children: <Widget>[
    _ScrollDrawerExample(),
    _ScrollDrawerExample(header: true),
    _ScrollDrawerExample(footer: true),
    _ScrollDrawerExample(header: true, footer: true),
  ],
);

class _ScrollDrawerExample extends StatelessWidget {
  const _ScrollDrawerExample({this.header = false, this.footer = false});

  final bool header;
  final bool footer;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 400,
    child: FluentDrawer(
      type: FluentDrawerType.inline,
      open: true,
      header: <Widget>[if (header) const Text('Title goes here')],
      footer: <Widget>[
        // The footer is a Row, and a 320-wide drawer is not much room for two
        // labelled buttons — Flexible on each keeps them inside the panel
        // instead of overflowing it.
        if (footer) ...<Widget>[
          Flexible(
            child: FluentButton(
              appearance: FluentButtonAppearance.primary,
              onPressed: () {},
              child: const Flexible(child: Text('Primary')),
            ),
          ),
          Flexible(
            child: FluentButton(
              onPressed: () {},
              child: const Flexible(child: Text('Secondary')),
            ),
          ),
        ],
      ],
      child: Semantics(
        container: true,
        label: 'Example scrolling content',
        child: const SingleChildScrollView(
          child: Text(
            'Lorem ipsum dolor sit amet consectetur, adipisicing elit. '
            'Doloribus nam aut amet similique, iure vel voluptates cum cumque '
            'repellendus perferendis maiores officia unde in? Autem neque '
            'sequi maiores eum omnis. Lorem ipsum, dolor sit amet consectetur '
            'adipisicing elit. Perspiciatis ipsam explicabo tempora ipsum '
            'saepe nam. Eum aliquid aperiam, laborum labore excepturi nisi '
            'odio deserunt facilis error. Mollitia dolor quidem a. Lorem '
            'ipsum, dolor sit amet consectetur adipisicing elit. Eius soluta '
            'ea repellendus voluptatum provident ad aut unde accusantium sed. '
            'Officia qui praesentium repudiandae maxime molestias, non '
            'mollitia animi laboriosam quis. Lorem, ipsum dolor sit amet '
            'consectetur adipisicing elit. Inventore, architecto eligendi '
            'earum dolor voluptas hic minima nihil porro odio suscipit quaerat '
            'accusantium, aperiam, neque beatae ipsa explicabo consequatur cum '
            'quam?',
          ),
        ),
      ),
    ),
  );
}
// #enddocregion components-drawer--with-scroll

// #docregion components-drawer--motion-custom
// FluentDrawer has no `surfaceMotion` slot: its transition is size-keyed and
// fixed — 250ms at small through 500ms at full, entering on curveDecelerateMid
// and leaving on curveAccelerateMin. The demo is otherwise upstream's, with
// the drawer's own motion in place of the custom keyframes.
Widget _motionCustom(BuildContext context) => const _MotionCustom();

class _MotionCustom extends StatefulWidget {
  const _MotionCustom();

  @override
  State<_MotionCustom> createState() => _MotionCustomState();
}

class _MotionCustomState extends State<_MotionCustom> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) => Container(
    height: 480,
    decoration: const BoxDecoration(
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xFFCCCCCC), width: 2),
      ),
    ),
    child: Row(
      children: <Widget>[
        FluentDrawer(
          type: FluentDrawerType.inline,
          separator: true,
          open: _isOpen,
          header: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(child: Text('Default Drawer')),
                FluentButton.icon(
                  appearance: FluentButtonAppearance.subtle,
                  semanticLabel: 'Close',
                  icon: const Icon(FluentIcons.dismiss_24_regular),
                  onPressed: () => setState(() => _isOpen = false),
                ),
              ],
            ),
          ],
          child: const Text('Drawer content'),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  onPressed: () => setState(() => _isOpen = !_isOpen),
                  child: const Text('Toggle Drawer'),
                ),
                const SizedBox(height: 12),
                const Text('Drawer content'),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
// #enddocregion components-drawer--motion-custom

// #docregion components-drawer--motion-disabled
// FluentDrawer has no `surfaceMotion`/`backdropMotion` slots to null out. It
// reads `MediaQuery.disableAnimationsOf` instead and jumps straight to the end
// state, scheduling no frames at all — so overriding that flag for the subtree
// is the same instruction said in Flutter's vocabulary, and it is the one users
// who ask for reduced motion get for free.
Widget _motionDisabled(BuildContext context) => MediaQuery(
  data: MediaQuery.of(context).copyWith(disableAnimations: true),
  child: const _MotionDisabled(),
);

class _MotionDisabled extends StatefulWidget {
  const _MotionDisabled();

  @override
  State<_MotionDisabled> createState() => _MotionDisabledState();
}

class _MotionDisabledState extends State<_MotionDisabled> {
  bool _isOpen = false;
  FluentDrawerType _type = FluentDrawerType.overlay;

  @override
  Widget build(BuildContext context) => Container(
    height: 480,
    decoration: const BoxDecoration(
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xFFCCCCCC), width: 2),
      ),
    ),
    child: Row(
      children: <Widget>[
        FluentDrawer(
          type: _type,
          separator: true,
          open: _isOpen,
          onDismiss: () => setState(() => _isOpen = false),
          header: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(child: Text('Default Drawer')),
                FluentButton.icon(
                  appearance: FluentButtonAppearance.subtle,
                  semanticLabel: 'Close',
                  icon: const Icon(FluentIcons.dismiss_24_regular),
                  onPressed: () => setState(() => _isOpen = false),
                ),
              ],
            ),
          ],
          child: const Text('Drawer content'),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  onPressed: () => setState(() => _isOpen = !_isOpen),
                  child: Text(
                    _type == FluentDrawerType.inline ? 'Toggle' : 'Open',
                  ),
                ),
                const SizedBox(height: 24),
                FluentField(
                  label: const Text('Type'),
                  child: FluentRadioGroup<FluentDrawerType>(
                    value: _type,
                    onChanged: (FluentDrawerType value) =>
                        setState(() => _type = value),
                    children: const <Widget>[
                      FluentRadio<FluentDrawerType>(
                        value: FluentDrawerType.overlay,
                        label: Text('Overlay (Default)'),
                      ),
                      FluentRadio<FluentDrawerType>(
                        value: FluentDrawerType.inline,
                        label: Text('Inline'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
// #enddocregion components-drawer--motion-disabled

// #docregion components-drawer--multiple-levels
// Upstream animates the two levels with the Motion APIs. AnimatedSwitcher is
// the Flutter equivalent for "one child at a time, cross-faded"; the slide half
// of upstream's fade+slide pair is left off rather than hand-rolled.
Widget _multipleLevels(BuildContext context) => const _MultipleLevels();

class _MultipleLevels extends StatefulWidget {
  const _MultipleLevels();

  @override
  State<_MultipleLevels> createState() => _MultipleLevelsState();
}

class _MultipleLevelsState extends State<_MultipleLevels> {
  bool _isOpen = false;
  int _level = 1;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentDrawer(
        position: FluentDrawerPosition.start,
        open: _isOpen,
        onDismiss: () => setState(() => _isOpen = false),
        header: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FluentToolbar(
                items: <Widget>[
                  if (_level == 2)
                    FluentButton.icon(
                      semanticLabel: 'Back',
                      appearance: FluentButtonAppearance.subtle,
                      icon: const Icon(FluentIcons.arrow_left_24_regular),
                      onPressed: () => setState(() => _level = 1),
                    ),
                ],
              ),
              FluentToolbar(
                items: <Widget>[
                  if (_level == 1)
                    FluentButton.icon(
                      semanticLabel: 'Go to calendar',
                      appearance: FluentButtonAppearance.subtle,
                      icon: const Icon(FluentIcons.calendar_24_regular),
                      onPressed: () => setState(() => _level = 2),
                    ),
                  FluentButton.icon(
                    semanticLabel: 'Settings',
                    appearance: FluentButtonAppearance.subtle,
                    icon: const Icon(FluentIcons.settings_24_regular),
                    onPressed: () {},
                  ),
                  FluentButton.icon(
                    semanticLabel: 'Close panel',
                    appearance: FluentButtonAppearance.subtle,
                    icon: const Icon(FluentIcons.dismiss_24_regular),
                    onPressed: () => setState(() => _isOpen = false),
                  ),
                ],
              ),
            ],
          ),
        ],
        footer: <Widget>[
          FluentButton(
            appearance: FluentButtonAppearance.subtle,
            onPressed: _level == 1 ? null : () => setState(() => _level = 1),
            child: const Text('Previous'),
          ),
          const Spacer(),
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: _level == 2 ? null : () => setState(() => _level = 2),
            child: const Text('Next'),
          ),
        ],
        child: AnimatedSwitcher(
          duration: FluentDuration.normal,
          switchInCurve: FluentCurve.easyEase,
          switchOutCurve: FluentCurve.easyEase,
          child: _level == 1
              ? const Column(
                  key: ValueKey<int>(1),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Level 1 title'),
                    SizedBox(height: 8),
                    Text('Level 1 content'),
                  ],
                )
              : const Column(
                  key: ValueKey<int>(2),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Level 2 title'),
                    SizedBox(height: 8),
                    Text('Level 2 content'),
                  ],
                ),
        ),
      ),
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () => setState(() => _isOpen = true),
        child: const Text('Open Drawer'),
      ),
    ],
  );
}
// #enddocregion components-drawer--multiple-levels

// #docregion components-drawer--keep-rendered-in-the-dom
// FluentDrawer has no `unmountOnClose`: a closed drawer is never in the tree,
// which is deliberate — no panel, no scrim intercepting pointers, no focus
// scope, and nothing for a screen reader to walk past. The demo is otherwise
// upstream's, long body included, so the scroll position resets on each open
// rather than being kept.
Widget _keepRenderedInTheDom(BuildContext context) => const _KeepRendered();

const String _keepRenderedParagraph1 =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod '
    'tempor incididunt ut labore et dolore magna aliqua. Nisl pretium fusce id '
    'velit ut tortor. Leo vel fringilla est ullamcorper. Eget est lorem ipsum '
    'dolor sit amet consectetur adipiscing elit. In mollis nunc sed id semper '
    'risus in hendrerit gravida. Ullamcorper sit amet risus nullam eget felis '
    'eget. Dolor sed viverra ipsum nunc aliquet bibendum. Facilisi morbi '
    'tempus iaculis urna id volutpat. Porta non pulvinar neque laoreet '
    'suspendisse. Nunc id cursus metus aliquam eleifend mi in. A iaculis at '
    'erat pellentesque adipiscing commodo. Proin nibh nisl condimentum id. In '
    'hac habitasse platea dictumst vestibulum rhoncus est. Non tellus orci ac '
    'auctor augue mauris augue neque. Enim nulla aliquet porttitor lacus '
    'luctus accumsan tortor. Nascetur ridiculus mus mauris vitae ultricies leo '
    'integer. Ullamcorper eget nulla facilisi etiam dignissim. Leo in vitae '
    'turpis massa sed elementum tempus egestas sed.';

const String _keepRenderedParagraph2 =
    'Ut enim blandit volutpat maecenas volutpat. Venenatis urna cursus eget '
    'nunc scelerisque viverra mauris. Neque aliquam vestibulum morbi blandit. '
    'Porttitor eget dolor morbi non. Nisi quis eleifend quam adipiscing vitae. '
    'Aliquam ultrices sagittis orci a scelerisque purus semper. Interdum '
    'varius sit amet mattis vulputate enim nulla aliquet. Ut sem viverra '
    'aliquet eget sit amet tellus cras. Sit amet tellus cras adipiscing enim '
    'eu turpis egestas. Amet cursus sit amet dictum sit amet justo donec enim. '
    'Neque gravida in fermentum et sollicitudin ac. Arcu cursus euismod quis '
    'viverra nibh cras pulvinar mattis nunc. Ultrices eros in cursus turpis '
    'massa tincidunt dui. Nisl rhoncus mattis rhoncus urna neque viverra '
    'justo. Odio pellentesque diam volutpat commodo sed egestas. Nunc mi ipsum '
    'faucibus vitae aliquet nec ullamcorper. Ipsum nunc aliquet bibendum enim. '
    'Faucibus ornare suspendisse sed nisi lacus sed. Sapien nec sagittis '
    'aliquam malesuada bibendum arcu vitae elementum. Metus vulputate eu '
    'scelerisque felis imperdiet.';

const String _keepRenderedParagraph3 =
    'Consequat interdum varius sit amet mattis vulputate enim. Amet cursus sit '
    'amet dictum sit amet justo. Eget aliquet nibh praesent tristique magna '
    'sit. Ut consequat semper viverra nam libero justo. Pharetra massa massa '
    'ultricies mi. Sem viverra aliquet eget sit amet. Pulvinar mattis nunc sed '
    'blandit libero volutpat sed. Pharetra diam sit amet nisl suscipit '
    'adipiscing bibendum. Consectetur adipiscing elit ut aliquam. Volutpat '
    'diam ut venenatis tellus in metus vulputate. Scelerisque in dictum non '
    'consectetur a erat. Venenatis lectus magna fringilla urna porttitor '
    'rhoncus. Vitae congue mauris rhoncus aenean vel elit. Neque laoreet '
    'suspendisse interdum consectetur. Ultrices gravida dictum fusce ut '
    'placerat orci. Bibendum ut tristique et egestas quis ipsum suspendisse. '
    'Mattis rhoncus urna neque viverra justo nec ultrices dui. Elit duis '
    'tristique sollicitudin nibh sit amet.';

const String _keepRenderedParagraph4 =
    'At risus viverra adipiscing at. Interdum posuere lorem ipsum dolor sit '
    'amet consectetur adipiscing elit. Nunc vel risus commodo viverra '
    'maecenas. Sit amet est placerat in egestas erat imperdiet sed euismod. '
    'Turpis egestas maecenas pharetra convallis posuere. Egestas tellus rutrum '
    'tellus pellentesque eu tincidunt tortor aliquam. Dolor sit amet '
    'consectetur adipiscing elit. Aliquam purus sit amet luctus venenatis '
    'lectus magna fringilla. Scelerisque fermentum dui faucibus in ornare quam '
    'viverra. Egestas maecenas pharetra convallis posuere morbi leo urna. A '
    'diam sollicitudin tempor id eu nisl nunc. Lectus sit amet est placerat.';

const String _keepRenderedParagraph5 =
    'Mattis ullamcorper velit sed ullamcorper morbi tincidunt ornare massa '
    'eget. At tellus at urna condimentum mattis pellentesque id nibh. Dui '
    'faucibus in ornare quam. Tincidunt id aliquet risus feugiat in ante metus '
    'dictum. Adipiscing commodo elit at imperdiet dui. Dolor sed viverra ipsum '
    'nunc. Sodales neque sodales ut etiam sit amet nisl. Hendrerit dolor magna '
    'eget est lorem ipsum dolor sit amet. Mattis molestie a iaculis at erat '
    'pellentesque adipiscing. Adipiscing elit duis tristique sollicitudin nibh '
    'sit amet commodo nulla. Fringilla urna porttitor rhoncus dolor purus.';

class _KeepRendered extends StatefulWidget {
  const _KeepRendered();

  @override
  State<_KeepRendered> createState() => _KeepRenderedState();
}

class _KeepRenderedState extends State<_KeepRendered> {
  static const List<String> _paragraphs = <String>[
    _keepRenderedParagraph1,
    _keepRenderedParagraph2,
    _keepRenderedParagraph3,
    _keepRenderedParagraph4,
    _keepRenderedParagraph5,
    _keepRenderedParagraph1,
    _keepRenderedParagraph2,
    _keepRenderedParagraph3,
  ];

  bool _isOpen = false;
  FluentDrawerType _type = FluentDrawerType.overlay;

  @override
  Widget build(BuildContext context) => Container(
    height: 480,
    decoration: const BoxDecoration(
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xFFCCCCCC), width: 2),
      ),
    ),
    child: Row(
      children: <Widget>[
        FluentDrawer(
          type: _type,
          separator: true,
          open: _isOpen,
          onDismiss: () => setState(() => _isOpen = false),
          header: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(child: Text('Default Drawer')),
                FluentButton.icon(
                  appearance: FluentButtonAppearance.subtle,
                  semanticLabel: 'Close',
                  icon: const Icon(FluentIcons.dismiss_24_regular),
                  onPressed: () => setState(() => _isOpen = false),
                ),
              ],
            ),
          ],
          child: ListView.builder(
            itemCount: _paragraphs.length,
            itemBuilder: (BuildContext context, int index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_paragraphs[index]),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  onPressed: () => setState(() => _isOpen = !_isOpen),
                  child: Text(
                    _type == FluentDrawerType.inline ? 'Toggle' : 'Open',
                  ),
                ),
                const SizedBox(height: 24),
                FluentField(
                  label: const Text('Type'),
                  child: FluentRadioGroup<FluentDrawerType>(
                    value: _type,
                    onChanged: (FluentDrawerType value) =>
                        setState(() => _type = value),
                    children: const <Widget>[
                      FluentRadio<FluentDrawerType>(
                        value: FluentDrawerType.overlay,
                        label: Text('Overlay (Default)'),
                      ),
                      FluentRadio<FluentDrawerType>(
                        value: FluentDrawerType.inline,
                        label: Text('Inline'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
// #enddocregion components-drawer--keep-rendered-in-the-dom

// #docregion components-drawer--always-open
// An inline drawer with no onDismiss cannot be closed: `open` is the caller's
// state and nothing here ever sets it to false.
Widget _alwaysOpen(BuildContext context) => Container(
  height: 480,
  decoration: const BoxDecoration(
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFFCCCCCC), width: 2),
    ),
  ),
  child: const Row(
    children: <Widget>[
      FluentDrawer(
        type: FluentDrawerType.inline,
        separator: true,
        open: true,
        header: <Widget>[Text('Always open')],
        child: Text('Drawer content'),
      ),
      Expanded(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topCenter,
            child: Text('This is the page content'),
          ),
        ),
      ),
    ],
  ),
);
// #enddocregion components-drawer--always-open

// #docregion components-drawer--prevent-close
// Upstream's `modalType="alert"` with no onOpenChange handler is our
// `onDismiss: null`: Escape and a tap on the scrim are both routed through it,
// so leaving it off inerts them and only the header button closes the drawer.
Widget _preventClose(BuildContext context) => const _PreventClose();

class _PreventClose extends StatefulWidget {
  const _PreventClose();

  @override
  State<_PreventClose> createState() => _PreventCloseState();
}

class _PreventCloseState extends State<_PreventClose> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentDrawer(
        position: FluentDrawerPosition.end,
        open: _open,
        header: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text('Prevent close with Esc or outside click'),
              ),
              FluentButton.icon(
                appearance: FluentButtonAppearance.subtle,
                semanticLabel: 'Close',
                icon: const Icon(FluentIcons.dismiss_24_regular),
                onPressed: () => setState(() => _open = false),
              ),
            ],
          ),
        ],
        child: const Text(
          'This drawer cannot be closed when clicking outside nor using the '
          '"ESC" key',
        ),
      ),
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () => setState(() => _open = true),
        child: const Text('Open Drawer'),
      ),
    ],
  );
}
// #enddocregion components-drawer--prevent-close

// #docregion components-drawer--responsive
// Upstream listens to a `(max-width: 720px)` media query. MediaQuery.sizeOf is
// the same reading, and it already rebuilds when the window changes.
Widget _responsive(BuildContext context) => const _Responsive();

class _Responsive extends StatefulWidget {
  const _Responsive();

  @override
  State<_Responsive> createState() => _ResponsiveState();
}

class _ResponsiveState extends State<_Responsive> {
  bool _isOpen = true;

  @override
  Widget build(BuildContext context) {
    final type = MediaQuery.sizeOf(context).width < 720
        ? FluentDrawerType.overlay
        : FluentDrawerType.inline;

    return Container(
      height: 480,
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFFCCCCCC), width: 2),
        ),
      ),
      child: Row(
        children: <Widget>[
          FluentDrawer(
            type: type,
            separator: true,
            position: FluentDrawerPosition.start,
            open: _isOpen,
            onDismiss: () => setState(() => _isOpen = false),
            header: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(child: Text('Responsive Drawer')),
                  FluentButton.icon(
                    appearance: FluentButtonAppearance.subtle,
                    semanticLabel: 'Close',
                    icon: const Icon(FluentIcons.dismiss_24_regular),
                    onPressed: () => setState(() => _isOpen = false),
                  ),
                ],
              ),
            ],
            child: const Text('Drawer content'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FluentButton(
                    appearance: FluentButtonAppearance.primary,
                    onPressed: () => setState(() => _isOpen = !_isOpen),
                    child: const Text('Toggle'),
                  ),
                  const SizedBox(height: 24),
                  const Text('Resize the window to see the change'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// #enddocregion components-drawer--responsive

// #docregion components-drawer--resizable
// The drawer's width is a style token, so resizing it is a matter of feeding a
// new one: drag the rule for a live resize, click it to type an exact width.
// Upstream tracks the pointer against the sidebar's bounding rect; a horizontal
// drag delta says the same thing without reading back layout.
Widget _resizable(BuildContext context) => const _Resizable();

const double _minSidebarWidth = 240;

class _Resizable extends StatefulWidget {
  const _Resizable();

  @override
  State<_Resizable> createState() => _ResizableState();
}

class _ResizableState extends State<_Resizable> {
  final TextEditingController _resizeInput = TextEditingController(text: '320');

  double _sidebarWidth = 320;
  bool _isDialogOpen = false;
  bool _showMessage = false;

  @override
  void dispose() {
    _resizeInput.dispose();
    super.dispose();
  }

  void _setWidth(double width) => setState(() {
    _sidebarWidth = width;
    _resizeInput.text = width.round().toString();
  });

  void _submitWidth() {
    final parsed = int.tryParse(_resizeInput.text);
    if (parsed != null && parsed >= _minSidebarWidth) {
      setState(() {
        _sidebarWidth = parsed.toDouble();
        _showMessage = false;
        _isDialogOpen = false;
      });
      return;
    }
    setState(() => _showMessage = true);
  }

  @override
  Widget build(BuildContext context) => Container(
    height: 480,
    decoration: const BoxDecoration(
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xFFCCCCCC), width: 2),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FluentDrawer(
          type: FluentDrawerType.inline,
          open: true,
          style: FluentDrawerStyle(
            width: WidgetStatePropertyAll<double?>(_sidebarWidth),
          ),
          header: const <Widget>[Text('Default Drawer')],
          child: const Text('Resizable content'),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _isDialogOpen = true),
            onHorizontalDragUpdate: (DragUpdateDetails details) => _setWidth(
              (_sidebarWidth + details.delta.dx).clamp(_minSidebarWidth, 940),
            ),
            child: Semantics(
              label: 'Resize drawer',
              container: true,
              child: SizedBox(
                width: 24,
                child: Center(
                  child: SizedBox(
                    width: 1,
                    height: double.infinity,
                    child: ColoredBox(
                      color: FluentTheme.of(context).colors.neutralBackground5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Resize the drawer to see the change'),
                // Upstream puts the type-a-width form in a Dialog opened from
                // the resizer. It is rendered in place here instead: a closed
                // FluentDialog throws on dispose, and a docs page that mounts
                // every section is exactly where that shows up.
                if (_isDialogOpen) ...<Widget>[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 320,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Expanded(child: Text('Resize drawer')),
                            FluentButton.icon(
                              appearance: FluentButtonAppearance.subtle,
                              semanticLabel: 'close',
                              icon: const Icon(FluentIcons.dismiss_20_regular),
                              onPressed: () =>
                                  setState(() => _isDialogOpen = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FluentField(
                          label: const Text(
                            'Enter desired drawer width pixels:',
                          ),
                          validationState: _showMessage
                              ? FluentFieldValidationState.error
                              : FluentFieldValidationState.none,
                          validationMessage: _showMessage
                              ? const Text(
                                  'Recommended minimum width of the drawer '
                                  'should be greater than or equal to `240px`.',
                                )
                              : null,
                          child: FluentInput(
                            controller: _resizeInput,
                            keyboardType: TextInputType.number,
                            onSubmitted: (String value) => _submitWidth(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            FluentButton(
                              appearance: FluentButtonAppearance.primary,
                              onPressed: _submitWidth,
                              child: const Text('Resize'),
                            ),
                            const SizedBox(width: 8),
                            FluentButton(
                              onPressed: () =>
                                  setState(() => _isDialogOpen = false),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// #enddocregion components-drawer--resizable
