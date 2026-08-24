import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Card docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage cardPage = DocsPage(
  id: 'components-card-card',
  folder: 'Card',
  title: 'Card',
  description:
      'A card is a container that holds information and actions related to a '
      'single concept or object, like a document or a contact. Cards can give '
      "information prominence and create predictable patterns. While they're "
      "very flexible, it's important to use them consistently for particular "
      'use cases across experiences.',
  source: 'lib/pages/components_card_card.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-card-card--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-card-card--orientation',
      title: 'Orientation',
      description:
          'Cards can have a different anatomy and be displayed either '
          'vertically (by default) or horizontally.',
      builder: _orientation,
    ),
    DocsSection(
      id: 'components-card-card--size',
      title: 'Size',
      description:
          'Size options are mainly to provide variety, and consistency when '
          'using cards for different usages.It relates to padding and '
          'border-radius and not so much the actual dimensions of the card.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-card-card--appearance',
      title: 'Appearance',
      description:
          'Cards can have different styles depending on the situation and '
          'where it is placed.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-card-card--selectable',
      title: 'Selectable',
      description:
          'Cards can be selectable and clicking the card surface can toggle '
          'its state to selected.',
      builder: _selectable,
    ),
    DocsSection(
      id: 'components-card-card--selectable-indicator',
      title: 'Selectable Indicator',
      description:
          'By default, selectable cards do not include any element to '
          'represent its selection state. For example, checkboxes can be '
          'composed together as an additional element by using the '
          "floatingAction property. When doing so, ensure the checkbox's "
          "accessible name matches the card's title.",
      builder: _selectableIndicator,
    ),
    DocsSection(
      id: 'components-card-card--disabled',
      title: 'Disabled',
      description:
          'A card can be disabled, which prevents interaction and shows a '
          'visual disabled state. Key behaviors: Interactive disabled cards do '
          'not respond to click events. Selectable disabled cards cannot '
          'change their selection state. The internal checkbox in selectable '
          'cards is also disabled. Focus is not applied to disabled cards (no '
          'tabindex). Accessibility: Disabled cards have aria-disabled="true". '
          'Screen readers announce the disabled state. Cards do not receive '
          'focus when disabled, maintaining proper tab order. Make sure to '
          'explicitly disable interactive child elements as well, like buttons '
          'and fields, as they are not disabled by default due to limited '
          'control over slot contents.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-card-card--with-action',
      title: 'With Action',
      description:
          "When giving a card a top-level click handler, it's important to "
          'ensure the same action can be done by a button or link within the '
          'Card. This ensures the action is accesible to screen reader, touch '
          'screen reader, keyboard, and voice control users.',
      builder: _withAction,
    ),
    DocsSection(
      id: 'components-card-card--focus-mode',
      title: 'Focus Mode',
      description:
          'Cards can be focusable and manage the focus of their contents in '
          'several different strategies. Using the focusMode prop, we can '
          'achieve the following:',
      builder: _focusMode,
    ),
    DocsSection(
      id: 'components-card-card--templates',
      title: 'Templates',
      description:
          'Cards can be composed with other components to build rich elements '
          'for a page.',
      builder: _templates,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'child',
      type: 'Widget?',
      defaultValue: 'null',
      description: "The body slot, inset by the card's padding.",
    ),
    PropRow(
      name: 'preview',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          "Media that bleeds to the card's edge, before every other slot.",
    ),
    PropRow(
      name: 'header',
      type: 'Widget?',
      defaultValue: 'null',
      description: "The header slot, inset by the card's padding.",
    ),
    PropRow(
      name: 'footer',
      type: 'Widget?',
      defaultValue: 'null',
      description: "The footer slot, inset by the card's padding.",
    ),
    PropRow(
      name: 'onPressed',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description: 'Invoked on tap and on Space or Enter.',
    ),
    PropRow(
      name: 'selected',
      type: 'bool',
      defaultValue: 'false',
      description:
          "Whether the card is selected, which selects Fluent's real *Selected "
          'tokens and outranks hover, as it does upstream.',
    ),
    PropRow(
      name: 'disabled',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the card is disabled.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentCardAppearance',
      defaultValue: 'FluentCardAppearance.filled',
      description: 'Fill, outline and elevation treatment.',
    ),
    PropRow(
      name: 'orientation',
      type: 'FluentCardOrientation',
      defaultValue: 'FluentCardOrientation.vertical',
      description: 'Which axis the slots are laid out along.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentCardSize',
      defaultValue: 'FluentCardSize.medium',
      description: 'Inset, gap and corner radius.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentCardStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'focusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description:
          'Focus node to use. One is created internally when omitted. Ignored '
          'by an inert card, which takes no focus.',
    ),
    PropRow(
      name: 'autofocus',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether to take focus on mount.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Announced by assistive technology.',
    ),
  ],
);

// #docregion components-card-card--default
// `FluentCard` has no `CardHeader`, `CardPreview` or `CardFooter` widget: the
// four slots take any widget, so the header row is composed here. Upstream's
// story assets (`avatar_elvia.svg`, `docx.png`, `doc_template.png`) are not
// vendored, so the avatar falls back to initials, the document logo to a Fluent
// icon, and the preview to the showroom's own sample image.
Widget _default(BuildContext context) {
  final FluentTypography type = FluentTheme.of(context).typography;

  return SizedBox(
    width: 720,
    child: FluentCard(
      header: Row(
        spacing: 12,
        children: <Widget>[
          const FluentAvatar(name: 'Elvia Atkins', initials: 'EA'),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(text: 'Elvia Atkins', style: type.body1Strong),
                      const TextSpan(text: ' mentioned you'),
                    ],
                  ),
                  style: type.body1,
                ),
                Text('5h ago · About us - Overview', style: type.caption1),
              ],
            ),
          ),
        ],
      ),
      preview: const Stack(
        children: <Widget>[
          Image(
            image: AssetImage('assets/storybook/image.png'),
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Icon(FluentIcons.document_20_regular, size: 32),
          ),
        ],
      ),
      footer: Row(
        spacing: 8,
        children: <Widget>[
          FluentButton(
            icon: const Icon(FluentIcons.arrow_reply_20_regular, size: 16),
            onPressed: () {},
            child: const Text('Reply'),
          ),
          FluentButton(
            icon: const Icon(FluentIcons.share_20_regular, size: 16),
            onPressed: () {},
            child: const Text('Share'),
          ),
        ],
      ),
    ),
  );
}
// #enddocregion components-card-card--default

// #docregion components-card-card--orientation
// Upstream's `app_logo.svg` is not vendored, so the app logo is a Fluent icon
// on a neutral tile.
Widget _orientation(BuildContext context) {
  final FluentThemeData theme = FluentTheme.of(context);
  final FluentTypography type = theme.typography;
  final FluentColors colors = theme.colors;

  Widget logo(double size) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: colors.neutralBackground3,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Icon(FluentIcons.apps_20_regular, size: size / 2),
  );

  Widget titles() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text('App Name', style: type.body1Strong),
      Text(
        'Developer',
        style: type.caption1.copyWith(color: colors.neutralForeground3),
      ),
    ],
  );

  Widget moreOptions() => FluentButton.icon(
    icon: const Icon(FluentIcons.more_horizontal_20_regular),
    semanticLabel: 'More options',
    appearance: FluentButtonAppearance.transparent,
    onPressed: () {},
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 36,
    children: <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: <Widget>[
          Text("'vertical' (Default)", style: type.subtitle1),
          Text('With image as part of header', style: type.body1),
          SizedBox(
            width: 360,
            child: FluentCard(
              header: Row(
                spacing: 12,
                children: <Widget>[
                  logo(44),
                  Expanded(child: titles()),
                  moreOptions(),
                ],
              ),
              child: Text(
                'Donut chocolate bar oat cake. Dragée tiramisu lollipop bear '
                'claw. Marshmallow pastry jujubes toffee sugar plum.',
                style: type.body1,
              ),
            ),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: <Widget>[
          Text("'horizontal'", style: type.subtitle1),
          Text('With image as part of preview', style: type.body1),
          FluentCard(
            orientation: FluentCardOrientation.horizontal,
            preview: logo(64),
            header: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: <Widget>[titles(), moreOptions()],
            ),
          ),
        ],
      ),
    ],
  );
}
// #enddocregion components-card-card--orientation

// #docregion components-card-card--size
// Upstream's `logo.svg` and `logo2.svg` are not vendored, so the two app logos
// are Fluent icons on neutral tiles.
Widget _size(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: 36,
  children: <Widget>[
    _sizeExample(context, "'small'", FluentCardSize.small),
    _sizeExample(context, "'medium' (Default)", FluentCardSize.medium),
    _sizeExample(context, "'large'", FluentCardSize.large),
  ],
);

Widget _sizeExample(BuildContext context, String title, FluentCardSize size) {
  final FluentThemeData theme = FluentTheme.of(context);
  final FluentTypography type = theme.typography;
  final FluentColors colors = theme.colors;

  Widget logo(IconData icon) => Container(
    width: 32,
    height: 32,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: colors.neutralBackground3,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Icon(icon, size: 16),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: <Widget>[
      Text(title, style: type.subtitle1),
      SizedBox(
        width: 300,
        child: FluentCard(
          size: size,
          header: Row(
            spacing: 4,
            children: <Widget>[
              logo(FluentIcons.apps_20_regular),
              logo(FluentIcons.board_20_regular),
            ],
          ),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Automated', style: type.body1),
              Text('3290', style: type.body1),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Alert in Teams when a new document is uploaded in channel',
                style: type.body1Strong,
              ),
              Text(
                'By Microsoft',
                style: type.caption1.copyWith(color: colors.neutralForeground3),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-card-card--size

// #docregion components-card-card--appearance
Widget _appearance(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: 36,
  children: <Widget>[
    _appearanceExample(
      context,
      'Filled (Default)',
      'This is the default style to use for cards. Use this style variant for '
          'most of your card designs.',
      FluentCardAppearance.filled,
    ),
    _appearanceExample(
      context,
      'Filled Alternative',
      'Use if your card is being displayed on a lighter gray or white surface. '
          'This ensures that you have adequate contrast between the card '
          'surface and the background of the application.',
      FluentCardAppearance.filledAlternative,
    ),
    _appearanceExample(
      context,
      'Outline',
      "Use when you don't want a filled background color but a discernable "
          'outline (border) on the card.',
      FluentCardAppearance.outline,
    ),
    _appearanceExample(
      context,
      'Subtle',
      "This variant doesn't have a background or border for the card "
          'container. However, it does include interaction states that display '
          'a visible footprint when interacting with the card item.',
      FluentCardAppearance.subtle,
    ),
  ],
);

Widget _appearanceExample(
  BuildContext context,
  String title,
  String description,
  FluentCardAppearance appearance,
) {
  final FluentThemeData theme = FluentTheme.of(context);
  final FluentTypography type = theme.typography;
  final FluentColors colors = theme.colors;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: <Widget>[
      Text(title, style: type.subtitle1),
      SizedBox(width: 480, child: Text(description, style: type.body1)),
      SizedBox(
        width: 480,
        child: FluentCard(
          appearance: appearance,
          onPressed: () {},
          header: Row(
            spacing: 12,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.neutralBackground3,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(FluentIcons.apps_20_regular),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('App Name', style: type.body1Strong),
                    Text(
                      'Developer',
                      style: type.caption1.copyWith(
                        color: colors.neutralForeground3,
                      ),
                    ),
                  ],
                ),
              ),
              FluentButton.icon(
                icon: const Icon(FluentIcons.more_horizontal_20_regular),
                semanticLabel: 'More options',
                appearance: FluentButtonAppearance.transparent,
                onPressed: () {},
              ),
            ],
          ),
          child: Text(
            'Donut chocolate bar oat cake. Dragée tiramisu lollipop bear claw. '
            'Marshmallow pastry jujubes toffee sugar plum.',
            style: type.body1,
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-card-card--appearance

// #docregion components-card-card--selectable
Widget _selectable(BuildContext context) => const _Selectable();

class _Selectable extends StatefulWidget {
  const _Selectable();

  @override
  State<_Selectable> createState() => _SelectableState();
}

class _SelectableState extends State<_Selectable> {
  bool _selected1 = false;
  bool _selected2 = false;

  // `FluentCard` reports selection through `onPressed` rather than a separate
  // `onSelectionChange`: the whole surface is the toggle, as it is upstream.
  Widget _card(bool selected, VoidCallback onPressed) {
    final FluentThemeData theme = FluentTheme.of(context);
    final FluentTypography type = theme.typography;
    final FluentColors colors = theme.colors;

    return SizedBox(
      width: 400,
      child: FluentCard(
        selected: selected,
        onPressed: onPressed,
        preview: ColoredBox(
          color: colors.neutralBackground3,
          child: Stack(
            children: <Widget>[
              const Image(
                image: AssetImage('assets/storybook/image.png'),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    FluentIcons.board_20_regular,
                    size: 24,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ],
          ),
        ),
        header: Row(
          spacing: 12,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('iOS App Prototype', style: type.body1Strong),
                  Text(
                    'You created 53m ago',
                    style: type.caption1.copyWith(
                      color: colors.neutralForeground3,
                    ),
                  ),
                ],
              ),
            ),
            FluentButton.icon(
              icon: const Icon(FluentIcons.more_horizontal_20_regular),
              semanticLabel: 'More actions',
              appearance: FluentButtonAppearance.transparent,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 16,
    children: <Widget>[
      _card(_selected1, () => setState(() => _selected1 = !_selected1)),
      _card(_selected2, () => setState(() => _selected2 = !_selected2)),
    ],
  );
}
// #enddocregion components-card-card--selectable

// #docregion components-card-card--selectable-indicator
Widget _selectableIndicator(BuildContext context) =>
    const _SelectableIndicator();

class _SelectableIndicator extends StatefulWidget {
  const _SelectableIndicator();

  @override
  State<_SelectableIndicator> createState() => _SelectableIndicatorState();
}

class _SelectableIndicatorState extends State<_SelectableIndicator> {
  bool _selected1 = false;
  bool _selected2 = false;
  bool _selected3 = false;
  bool _selected4 = false;

  // `FluentCard` has no `floatingAction` slot, so the checkbox is stacked over
  // the card's top-right corner — the position upstream's slot renders it in.
  Widget _floating({
    required bool selected,
    required ValueChanged<bool?> onChanged,
    required String semanticLabel,
    required Widget card,
  }) => Stack(
    children: <Widget>[
      card,
      Positioned(
        top: 8,
        right: 8,
        child: FluentCheckbox(
          checked: selected,
          onChanged: onChanged,
          semanticLabel: semanticLabel,
        ),
      ),
    ],
  );

  Widget _previewCard({
    required bool selected,
    required VoidCallback onPressed,
  }) {
    final FluentThemeData theme = FluentTheme.of(context);
    final FluentTypography type = theme.typography;
    final FluentColors colors = theme.colors;

    return SizedBox(
      width: 400,
      child: FluentCard(
        selected: selected,
        onPressed: onPressed,
        preview: ColoredBox(
          color: colors.neutralBackground3,
          child: const Image(
            image: AssetImage('assets/storybook/image.png'),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        header: Row(
          spacing: 12,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('iOS App Prototype', style: type.body1Strong),
                  Text(
                    'You created 53m ago',
                    style: type.caption1.copyWith(
                      color: colors.neutralForeground3,
                    ),
                  ),
                ],
              ),
            ),
            FluentButton.icon(
              icon: const Icon(FluentIcons.more_horizontal_20_regular),
              semanticLabel: 'More actions',
              appearance: FluentButtonAppearance.transparent,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentCard({
    required bool selected,
    required VoidCallback onPressed,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final FluentThemeData theme = FluentTheme.of(context);
    final FluentTypography type = theme.typography;
    final FluentColors colors = theme.colors;

    return SizedBox(
      width: 400,
      child: FluentCard(
        selected: selected,
        onPressed: onPressed,
        header: Row(
          spacing: 12,
          children: <Widget>[
            Icon(icon, size: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(title, style: type.body1Strong),
                  Text(
                    description,
                    style: type.caption1.copyWith(
                      color: colors.neutralForeground3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: <Widget>[
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          _floating(
            selected: _selected1,
            onChanged: (bool? value) =>
                setState(() => _selected1 = value ?? false),
            semanticLabel: 'iOS App Prototype',
            card: _previewCard(
              selected: _selected1,
              onPressed: () => setState(() => _selected1 = !_selected1),
            ),
          ),
          _floating(
            selected: _selected2,
            onChanged: (bool? value) =>
                setState(() => _selected2 = value ?? false),
            semanticLabel: 'iOS App Prototype',
            card: _previewCard(
              selected: _selected2,
              onPressed: () => setState(() => _selected2 = !_selected2),
            ),
          ),
        ],
      ),
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          _floating(
            selected: _selected3,
            onChanged: (bool? value) =>
                setState(() => _selected3 = value ?? false),
            semanticLabel: 'Secret Project Briefing',
            card: _documentCard(
              selected: _selected3,
              onPressed: () => setState(() => _selected3 = !_selected3),
              icon: FluentIcons.document_20_regular,
              title: 'Secret Project Briefing',
              description: 'OneDrive > Documents',
            ),
          ),
          _floating(
            selected: _selected4,
            onChanged: (bool? value) =>
                setState(() => _selected4 = value ?? false),
            semanticLabel: 'Team Budget',
            card: _documentCard(
              selected: _selected4,
              onPressed: () => setState(() => _selected4 = !_selected4),
              icon: FluentIcons.table_20_regular,
              title: 'Team Budget',
              description: 'OneDrive > Spreadsheets',
            ),
          ),
        ],
      ),
    ],
  );
}
// #enddocregion components-card-card--selectable-indicator

// #docregion components-card-card--disabled
Widget _disabled(BuildContext context) => const _Disabled();

class _Disabled extends StatefulWidget {
  const _Disabled();

  @override
  State<_Disabled> createState() => _DisabledState();
}

class _DisabledState extends State<_Disabled> {
  bool _isSelected1 = false;
  bool _isSelected2 = false;

  Widget _card({
    bool disabled = false,
    bool selected = false,
    VoidCallback? onPressed,
    FluentCardAppearance appearance = FluentCardAppearance.filled,
    Widget? floatingAction,
  }) {
    final FluentTypography type = FluentTheme.of(context).typography;

    final Widget card = SizedBox(
      width: 400,
      child: FluentCard(
        disabled: disabled,
        selected: selected,
        appearance: appearance,
        onPressed: onPressed,
        header: Row(
          spacing: 12,
          children: <Widget>[
            const FluentAvatar(name: 'Elvia Atkins', initials: 'EA'),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(text: 'Elvia Atkins', style: type.body1Strong),
                        const TextSpan(text: ' mentioned you'),
                      ],
                    ),
                    style: type.body1,
                  ),
                  Text('5h ago · About us - Overview', style: type.caption1),
                ],
              ),
            ),
          ],
        ),
        preview: const Stack(
          children: <Widget>[
            Image(
              image: AssetImage('assets/storybook/image.png'),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Icon(FluentIcons.document_20_regular, size: 32),
            ),
          ],
        ),
        footer: Row(
          spacing: 8,
          children: <Widget>[
            FluentButton(
              icon: const Icon(FluentIcons.arrow_reply_20_regular, size: 16),
              // Upstream disables the slot's buttons explicitly, because a
              // card's disabled state is not propagated to its contents.
              onPressed: disabled ? null : () {},
              child: const Text('Reply'),
            ),
            FluentButton(
              icon: const Icon(FluentIcons.share_20_regular, size: 16),
              onPressed: disabled ? null : () {},
              child: const Text('Share'),
            ),
          ],
        ),
      ),
    );

    if (floatingAction == null) {
      return card;
    }
    return Stack(
      children: <Widget>[
        card,
        Positioned(top: 8, right: 8, child: floatingAction),
      ],
    );
  }

  Widget _group(String title, List<Widget> cards) {
    final FluentTypography type = FluentTheme.of(context).typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: <Widget>[
        Text(title, style: type.subtitle2),
        Wrap(spacing: 16, runSpacing: 16, children: cards),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: <Widget>[
      _group('Default Card', <Widget>[_card(), _card(disabled: true)]),
      _group('Interactive Card', <Widget>[
        _card(onPressed: () {}),
        _card(disabled: true, onPressed: () {}),
      ]),
      _group('Selectable Card', <Widget>[
        _card(
          selected: _isSelected1,
          onPressed: () => setState(() => _isSelected1 = !_isSelected1),
        ),
        _card(disabled: true, onPressed: () {}),
        _card(
          selected: _isSelected2,
          onPressed: () => setState(() => _isSelected2 = !_isSelected2),
          floatingAction: FluentCheckbox(
            checked: _isSelected2,
            onChanged: (bool? value) =>
                setState(() => _isSelected2 = value ?? false),
            semanticLabel: 'Elvia Atkins mentioned you',
          ),
        ),
        _card(
          disabled: true,
          onPressed: () {},
          floatingAction: const FluentCheckbox(
            semanticLabel: 'Elvia Atkins mentioned you',
          ),
        ),
      ]),
      _group('Outline Card', <Widget>[
        _card(appearance: FluentCardAppearance.outline),
        _card(appearance: FluentCardAppearance.outline, disabled: true),
      ]),
    ],
  );
}
// #enddocregion components-card-card--disabled

// #docregion components-card-card--with-action
Widget _withAction(BuildContext context) => const _WithAction();

class _WithAction extends StatefulWidget {
  const _WithAction();

  @override
  State<_WithAction> createState() => _WithActionState();
}

class _WithActionState extends State<_WithAction> {
  // Upstream calls `alert()` and follows the linked card's `<a href>`. Neither
  // exists here, so the action is reported in place instead.
  String? _message;

  void _report(String message) => setState(() => _message = message);

  Widget _header({required Widget title}) {
    final FluentThemeData theme = FluentTheme.of(context);
    final FluentTypography type = theme.typography;

    return Row(
      spacing: 12,
      children: <Widget>[
        const Icon(FluentIcons.slide_layout_20_regular, size: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              title,
              Text('Developer', style: type.caption1),
            ],
          ),
        ),
        FluentButton.icon(
          icon: const Icon(FluentIcons.more_horizontal_20_regular),
          semanticLabel: 'More options',
          appearance: FluentButtonAppearance.transparent,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _section(String title, String description, Widget card) {
    final FluentTypography type = FluentTheme.of(context).typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: <Widget>[
        Text(title, style: type.subtitle1),
        SizedBox(width: 400, child: Text(description, style: type.body1)),
        card,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final FluentTypography type = FluentTheme.of(context).typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 36,
      children: <Widget>[
        if (_message != null) Text(_message!, style: type.body1Strong),
        _section(
          'Card with click event',
          'This card has both a root click event and an Open button that '
              'performs the same action. Adding enter key handling to the card '
              'root is optional since the Open button also provides keyboard '
              'access.',
          SizedBox(
            width: 400,
            child: FluentCard(
              onPressed: () => _report('Opened Classroom Collaboration app'),
              preview: const Image(
                image: AssetImage('assets/storybook/image.png'),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              header: _header(title: Text('App Name', style: type.body1Strong)),
              footer: Row(
                children: <Widget>[
                  FluentButton(
                    appearance: FluentButtonAppearance.primary,
                    icon: const Icon(FluentIcons.open_16_regular, size: 16),
                    onPressed: () =>
                        _report('Opened Classroom Collaboration app'),
                    child: const Text('Open'),
                  ),
                ],
              ),
              child: Text(
                'Donut chocolate bar oat cake. Dragée tiramisu lollipop bear '
                'claw. Marshmallow pastry jujubes toffee sugar plum.',
                style: type.body1,
              ),
            ),
          ),
        ),
        _section(
          'Linked Card',
          "When a card doesn't have a separate button within its contents, it "
              'usually makes the most sense for the title text of the card to '
              'become the additional interactive element (a link in this '
              'example).',
          SizedBox(
            width: 400,
            child: FluentCard(
              onPressed: () => _report('https://www.microsoft.com/'),
              preview: const Image(
                image: AssetImage('assets/storybook/image.png'),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              header: _header(
                title: FluentLink(
                  onPressed: () => _report('https://www.microsoft.com/'),
                  child: Text('App Name', style: type.body1Strong),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion components-card-card--with-action

// #docregion components-card-card--focus-mode
// `FluentCard` has no `focusMode`: Flutter's focus traversal has no equivalent
// of upstream's four trapping strategies, and the widget exposes `focusNode`
// and `autofocus` instead. Every section keeps its title and its card, and each
// card is focusable — the four behaviours differ only in how Tab and Esc leave
// the card, which is why they all render the same demo here.
Widget _focusMode(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: 36,
  children: <Widget>[
    _focusModeExample(
      context,
      "'off' (Default)",
      "The contents might still be focusable, but the Card won't manage the "
          'focus of its contents or be focusable.',
    ),
    _focusModeExample(
      context,
      "'no-tab'",
      'The Card will be focusable and trap the focus. You can use Tab to '
          'navigate between the contents and escaping focus only by pressing '
          'the Esc key.',
    ),
    _focusModeExample(
      context,
      "'tab-exit'",
      'The Card will be focusable and trap the focus, but release it on an Esc '
          'or Tab key press.',
    ),
    _focusModeExample(
      context,
      "'tab-only'",
      'The Card will not trap focus but will still be focusable and allow Tab '
          'navigation of its contents.',
    ),
  ],
);

Widget _focusModeExample(
  BuildContext context,
  String title,
  String description,
) {
  final FluentTypography type = FluentTheme.of(context).typography;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: <Widget>[
      Text(title, style: type.subtitle1),
      SizedBox(width: 400, child: Text(description, style: type.body1)),
      SizedBox(
        width: 400,
        child: FluentCard(
          onPressed: () {},
          preview: const Image(
            image: AssetImage('assets/storybook/image.png'),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          header: Row(
            spacing: 12,
            children: <Widget>[
              const Icon(FluentIcons.slide_layout_20_regular, size: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('App Name', style: type.body1Strong),
                    Text('Developer', style: type.caption1),
                  ],
                ),
              ),
              FluentButton.icon(
                icon: const Icon(FluentIcons.more_horizontal_20_regular),
                semanticLabel: 'More options',
                appearance: FluentButtonAppearance.transparent,
                onPressed: () {},
              ),
            ],
          ),
          footer: Row(
            spacing: 8,
            children: <Widget>[
              FluentButton(
                appearance: FluentButtonAppearance.primary,
                icon: const Icon(FluentIcons.open_16_regular, size: 16),
                onPressed: () {},
                child: const Text('Open'),
              ),
              FluentButton(
                icon: const Icon(FluentIcons.share_16_regular, size: 16),
                onPressed: () {},
                child: const Text('Share'),
              ),
            ],
          ),
          child: Text(
            'Donut chocolate bar oat cake. Dragée tiramisu lollipop bear claw. '
            'Marshmallow pastry jujubes toffee sugar plum.',
            style: type.body1,
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-card-card--focus-mode

// #docregion components-card-card--templates
Widget _templates(BuildContext context) => const _Templates();

class _Templates extends StatefulWidget {
  const _Templates();

  @override
  State<_Templates> createState() => _TemplatesState();
}

class _TemplatesState extends State<_Templates> {
  bool _task1 = false;
  bool _task2 = false;

  Widget _task(String title, bool checked, ValueChanged<bool?> onChanged) {
    final FluentThemeData theme = FluentTheme.of(context);
    final FluentTypography type = theme.typography;
    final FluentColors colors = theme.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        FluentCheckbox(
          checked: checked,
          onChanged: onChanged,
          semanticLabel: title,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title, style: type.body1Strong),
              Text(
                'Donut chocolate bar oat cake. Dragée tiramisu lollipop bear '
                'claw. Marshmallow pastry jujubes toffee sugar plum.',
                style: type.caption1.copyWith(color: colors.neutralForeground3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _listCard(IconData icon, String title, String description) {
    final FluentThemeData theme = FluentTheme.of(context);
    final FluentTypography type = theme.typography;
    final FluentColors colors = theme.colors;

    return SizedBox(
      width: 280,
      child: FluentCard(
        size: FluentCardSize.small,
        header: Row(
          spacing: 12,
          children: <Widget>[
            Icon(icon, size: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(title, style: type.body1Strong),
                  Text(
                    description,
                    style: type.caption1.copyWith(
                      color: colors.neutralForeground3,
                    ),
                  ),
                ],
              ),
            ),
            FluentButton.icon(
              icon: const Icon(FluentIcons.more_horizontal_20_regular),
              semanticLabel: 'More actions',
              appearance: FluentButtonAppearance.transparent,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FluentTypography type = FluentTheme.of(context).typography;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: <Widget>[
        SizedBox(
          width: 280,
          child: FluentCard(
            // `FluentBadge` has no `shape`, and upstream's `severe` colour is
            // not in `FluentBadgeColor` — `danger` is the nearest red.
            header: const Row(
              spacing: 6,
              children: <Widget>[
                FluentBadge(
                  color: FluentBadgeColor.danger,
                  appearance: FluentBadgeAppearance.tint,
                  child: Text('Red'),
                ),
                FluentBadge(
                  color: FluentBadgeColor.success,
                  appearance: FluentBadgeAppearance.tint,
                  child: Text('Green'),
                ),
                FluentBadge(
                  appearance: FluentBadgeAppearance.tint,
                  child: Text('Blue'),
                ),
              ],
            ),
            footer: Row(
              spacing: 12,
              children: <Widget>[
                const Icon(
                  FluentIcons.alert_urgent_16_filled,
                  size: 16,
                  color: Color(0xFFC4314B),
                ),
                const Icon(
                  FluentIcons.circle_half_fill_16_regular,
                  size: 16,
                  color: Color(0xFF0078DB),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: <Widget>[
                    const Icon(FluentIcons.attach_16_regular, size: 16),
                    Text('4', style: type.body1),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: <Widget>[
                    const Icon(
                      FluentIcons.checkmark_circle_16_regular,
                      size: 16,
                    ),
                    Text('2/12', style: type.body1),
                  ],
                ),
                const Icon(FluentIcons.comment_16_regular, size: 16),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: <Widget>[
                _task(
                  'Task title',
                  _task1,
                  (bool? value) => setState(() => _task1 = value ?? false),
                ),
                _task(
                  'Task title',
                  _task2,
                  (bool? value) => setState(() => _task2 = value ?? false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          width: 280,
          child: FluentCard(
            preview: Image(
              image: AssetImage('assets/storybook/image.png'),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: <Widget>[
            _listCard(
              FluentIcons.slide_layout_20_regular,
              'Team Offsite 2020',
              'OneDrive > Presentations',
            ),
            _listCard(
              FluentIcons.table_20_regular,
              'Team Budget',
              'OneDrive > Spreadsheets',
            ),
            _listCard(
              FluentIcons.document_20_regular,
              'Secret Project Briefing',
              'OneDrive > Documents',
            ),
          ],
        ),
      ],
    );
  }
}

// #enddocregion components-card-card--templates
