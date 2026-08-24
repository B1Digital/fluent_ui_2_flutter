import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The SearchBox docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Upstream wraps almost every story in a `Field`, so the labels below are
/// [FluentField] labels rather than decoration. Two React slots have no Dart
/// counterpart — `contentAfter`, and a `contentBefore` holding text rather
/// than a glyph — because [FluentSearchBox] exposes one leading slot sized to
/// a 20px icon; those sections say so in a comment and put the content beside
/// the box instead.
const DocsPage searchBoxPage = DocsPage(
  id: 'components-searchbox',
  title: 'SearchBox',
  description:
      'The SearchBox component allows the users to access information with '
      'ease, providing flexibility and the ability to clear and filter the '
      'search.',
  source: 'lib/pages/components_searchbox.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-searchbox--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-searchbox--appearance',
      title: 'Appearance',
      description:
          'A SearchBox can have different appearances. The colors adjacent to '
          'the SearchBox should have a sufficient contrast. Particularly, the '
          'color of SearchBox with filled darker and lighter styles needs to '
          'provide greater than 3 to 1 contrast ratio against the immediate '
          'surrounding color to pass accessibility requirements.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-searchbox--content-before-after',
      title: 'Content before/after',
      description:
          'A SearchBox supports a custom element such as an icon or a button '
          'before the input text. Additionally, a SearchBox supports an custom '
          'element that appears on focus, following the input text and before '
          'the dismiss button. These elements are displayed inside the '
          'SearchBox border.',
      builder: _contentBeforeAfter,
    ),
    DocsSection(
      id: 'components-searchbox--disabled',
      title: 'Disabled',
      description: 'A SearchBox can be disabled.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-searchbox--placeholder',
      title: 'Placeholder',
      description:
          'A SearchBox can have placeholder text. If using the placeholder as '
          'a label (which is not recommended for usability), be sure to '
          'provide an aria-label for screen reader users.',
      builder: _placeholder,
    ),
    DocsSection(
      id: 'components-searchbox--size',
      title: 'Size',
      description: 'A SearchBox can have different sizes.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-searchbox--controlled',
      title: 'Controlled',
      description:
          "A SearchBox can be controlled: the consuming component tracks the "
          "SearchBox's value in its state and manually handles all updates.",
      builder: _controlled,
    ),
    DocsSection(
      id: 'components-searchbox--typeahead',
      title: 'Typeahead',
      description:
          'A SearchBox can be combined with a results dropdown to create a '
          'typeahead (autocomplete) pattern. This example demonstrates: '
          'Debounced async search: results are fetched asynchronously after a '
          '300ms debounce to avoid firing on every keystroke. In-flight '
          'requests are cancelled when the query changes. Loading state: a '
          'Spinner is shown inside the dropdown while results are loading. '
          'Keyboard navigation: use ArrowDown/ArrowUp to move through results, '
          'Enter to select, and Escape to close the dropdown. Accessibility: '
          'the input uses role="combobox", aria-autocomplete="list", '
          'aria-expanded, aria-controls, and aria-activedescendant to '
          'communicate state to assistive technologies. The useTypingAnnounce '
          'hook announces loading state, result count, and "no results" to '
          "screen readers — waiting until the user pauses typing so "
          "announcements don't interfere with keyboard echo. Note: This "
          'pattern is intentionally left as a composable building block rather '
          'than a single sealed component, allowing you to integrate your own '
          'data-fetching solution (e.g. TanStack Query, SWR, or a custom hook) '
          'and to customise the appearance of each result item.',
      builder: _typeahead,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'controller',
      type: 'TextEditingController?',
      defaultValue: 'null',
      description:
          'The controller. One is created and disposed internally when '
          'omitted.',
    ),
    PropRow(
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true',
      description:
          'Whether the search box accepts input. False is a real disabled '
          'state.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentSearchBoxAppearance',
      defaultValue: 'FluentSearchBoxAppearance.outline',
      description: 'Fill and outline treatment.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentSearchBoxSize',
      defaultValue: 'FluentSearchBoxSize.medium',
      description: 'Height and type ramp.',
    ),
    PropRow(
      name: 'placeholder',
      type: 'String?',
      defaultValue: 'null',
      description: 'Hint shown while the value is empty.',
    ),
    PropRow(
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The leading glyph. Defaults to a painted Search20Regular; pass an '
          'empty SizedBox to drop the slot entirely.',
    ),
    PropRow(
      name: 'clearIcon',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The trailing clear glyph. Defaults to a painted Dismiss20Regular.',
    ),
    PropRow(
      name: 'onChanged',
      type: 'ValueChanged<String>?',
      defaultValue: 'null',
      description: 'Called on every edit, including a clear.',
    ),
    PropRow(
      name: 'onSubmitted',
      type: 'ValueChanged<String>?',
      defaultValue: 'null',
      description: 'Called when the user commits with Enter.',
    ),
    PropRow(
      name: 'onClear',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          'Called after the value is cleared, by the button or by Escape.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: "Announced by assistive technology as the field's name.",
    ),
    PropRow(
      name: 'clearSemanticLabel',
      type: 'String',
      defaultValue: "'Clear'",
      description: 'Announced by assistive technology for the clear button.',
    ),
  ],
);

// #docregion components-searchbox--default
Widget _default(BuildContext context) => const FluentField(
  label: Text('Sample SearchBox'),
  child: FluentSearchBox(),
);
// #enddocregion components-searchbox--default

// #docregion components-searchbox--appearance
// Upstream's `underline` appearance is this port's
// `FluentSearchBoxAppearance.transparent` — the same thing under Figma's name:
// no fill, a bottom rule only.
//
// The last two fields sit on `neutralBackgroundInverted` because a filled
// search box only reaches its 3:1 contrast requirement against a surrounding
// colour that differs from its own fill; that is upstream's point here, and
// the inverted label colour comes with it.
Widget _appearance(BuildContext context) {
  final FluentColors colors = FluentTheme.of(context).colors;
  const EdgeInsets fieldWrapper = EdgeInsets.symmetric(
    vertical: FluentSpacing.mNudge,
    horizontal: FluentSpacing.mNudge,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const Padding(
        padding: fieldWrapper,
        child: FluentField(
          label: Text('Outline appearance (default)'),
          child: FluentSearchBox(appearance: FluentSearchBoxAppearance.outline),
        ),
      ),
      const Padding(
        padding: fieldWrapper,
        child: FluentField(
          label: Text('Underline appearance'),
          child: FluentSearchBox(
            appearance: FluentSearchBoxAppearance.transparent,
          ),
        ),
      ),
      ColoredBox(
        color: colors.neutralBackgroundInverted,
        child: Padding(
          padding: fieldWrapper,
          child: FluentField(
            label: Text(
              'Filled lighter appearance',
              style: TextStyle(color: colors.neutralForegroundInverted2),
            ),
            child: const FluentSearchBox(
              appearance: FluentSearchBoxAppearance.filledLighter,
            ),
          ),
        ),
      ),
      ColoredBox(
        color: colors.neutralBackgroundInverted,
        child: Padding(
          padding: fieldWrapper,
          child: FluentField(
            label: Text(
              'Filled darker appearance',
              style: TextStyle(color: colors.neutralForegroundInverted2),
            ),
            child: const FluentSearchBox(
              appearance: FluentSearchBoxAppearance.filledDarker,
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-searchbox--appearance

// #docregion components-searchbox--content-before-after
// `FluentSearchBox` has one leading slot, `icon`, and it is laid out as a
// 20x20 box for a glyph. So the first field is a faithful `contentBefore`, and
// the other two are not: there is no `contentAfter` slot at all, and a text
// value does not fit the icon slot. Both therefore sit BESIDE the box rather
// than inside its border.
Widget _contentBeforeAfter(BuildContext context) {
  const EdgeInsets fieldWrapper = EdgeInsets.symmetric(
    vertical: FluentSpacing.mNudge,
    horizontal: FluentSpacing.mNudge,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const Padding(
        padding: fieldWrapper,
        child: FluentField(
          label: Text('Search by name'),
          hint: Text(
            'A SearchBox with a custom icon in the contentBefore slot.',
          ),
          child: FluentSearchBox(icon: Icon(FluentIcons.person_20_regular)),
        ),
      ),
      Padding(
        padding: fieldWrapper,
        child: FluentField(
          label: const Text('Search by voice'),
          hint: const Text(
            'A SearchBox with a button in the contentAfter slot.',
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Flexible(child: FluentSearchBox()),
              const SizedBox(width: FluentSpacing.xs),
              FluentButton.icon(
                icon: const Icon(FluentIcons.mic_20_regular),
                semanticLabel: 'Search by voice',
                appearance: FluentButtonAppearance.transparent,
                size: FluentButtonSize.small,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      const Padding(
        padding: fieldWrapper,
        child: FluentField(
          label: Text('Search with filter'),
          hint: Text(
            'A SearchBox with a presentational value in the contentBefore slot '
            'and another presentational value in the contentAfter slot.',
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Search:'),
              SizedBox(width: FluentSpacing.xs),
              Flexible(child: FluentSearchBox(icon: SizedBox.shrink())),
              SizedBox(width: FluentSpacing.xs),
              Text('Filter'),
            ],
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-searchbox--content-before-after

// #docregion components-searchbox--disabled
Widget _disabled(BuildContext context) => const _Disabled();

class _Disabled extends StatefulWidget {
  const _Disabled();

  @override
  State<_Disabled> createState() => _DisabledState();
}

class _DisabledState extends State<_Disabled> {
  // React's `defaultValue`: the starting text of an uncontrolled field, which
  // in Flutter is a controller seeded once.
  final TextEditingController _controller = TextEditingController(
    text: 'disabled value',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FluentField(
    label: const Text('Disabled SearchBox'),
    child: FluentSearchBox(enabled: false, controller: _controller),
  );
}
// #enddocregion components-searchbox--disabled

// #docregion components-searchbox--placeholder
Widget _placeholder(BuildContext context) => const FluentField(
  label: Text('SearchBox with a placeholder'),
  child: FluentSearchBox(placeholder: 'This is a placeholder'),
);
// #enddocregion components-searchbox--placeholder

// #docregion components-searchbox--size
Widget _size(BuildContext context) {
  const EdgeInsets fieldWrapper = EdgeInsets.symmetric(
    vertical: FluentSpacing.mNudge,
    horizontal: FluentSpacing.mNudge,
  );

  return const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Padding(
        padding: fieldWrapper,
        child: FluentField(
          label: Text('Small SearchBox'),
          child: FluentSearchBox(size: FluentSearchBoxSize.small),
        ),
      ),
      Padding(
        padding: fieldWrapper,
        child: FluentField(
          label: Text('Medium SearchBox'),
          child: FluentSearchBox(size: FluentSearchBoxSize.medium),
        ),
      ),
      Padding(
        padding: fieldWrapper,
        child: FluentField(
          label: Text('Large SearchBox'),
          child: FluentSearchBox(size: FluentSearchBoxSize.large),
        ),
      ),
    ],
  );
}
// #enddocregion components-searchbox--size

// #docregion components-searchbox--controlled
Widget _controlled(BuildContext context) => const _Controlled();

class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  final TextEditingController _controller = TextEditingController(
    text: 'initial value',
  );
  String _value = 'initial value';
  bool _valid = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String next) {
    if (next.length <= 20) {
      setState(() {
        _value = next;
        _valid = true;
      });
      return;
    }
    // React refuses the update and the input simply never shows the 21st
    // character. A TextEditingController has already applied the edit by the
    // time this runs, so refusing means putting the accepted value back.
    _controller.value = TextEditingValue(
      text: _value,
      selection: TextSelection.collapsed(offset: _value.length),
    );
    setState(() => _valid = false);
  }

  @override
  Widget build(BuildContext context) => FluentField(
    label: const Text(
      'Controlled SearchBox limiting the value to 20 characters',
    ),
    validationState: _valid
        ? FluentFieldValidationState.none
        : FluentFieldValidationState.warning,
    validationMessage: _valid
        ? null
        : const Text('Input is limited to 20 characters.'),
    // Upstream's Field picks `Warning12Filled` for the warning state itself;
    // FluentField takes the glyph from the caller.
    validationMessageIcon: _valid
        ? null
        : const Icon(FluentIcons.warning_12_filled),
    child: FluentSearchBox(controller: _controller, onChanged: _onChanged),
  );
}
// #enddocregion components-searchbox--controlled

// #docregion components-searchbox--typeahead
Widget _typeahead(BuildContext context) => const _Typeahead();

const int _debounceMs = 300;

class _SearchResult {
  const _SearchResult(this.id, this.label);

  final String id;
  final String label;
}

const List<_SearchResult> _allResults = <_SearchResult>[
  _SearchResult('1', 'Accessibility in Fluent UI'),
  _SearchResult('2', 'Button component'),
  _SearchResult('3', 'Combobox with filtering'),
  _SearchResult('4', 'Dark mode theming'),
  _SearchResult('5', 'Fluent UI v9 migration guide'),
  _SearchResult('6', 'Form validation patterns'),
  _SearchResult('7', 'Grid layout examples'),
  _SearchResult('8', 'High contrast support'),
  _SearchResult('9', 'Icon library overview'),
  _SearchResult('10', 'Jest testing utilities'),
];

// Simulated async search function
Future<List<_SearchResult>> _fetchResults(String query) =>
    Future<List<_SearchResult>>.delayed(
      const Duration(milliseconds: 500),
      () => _allResults
          .where(
            (_SearchResult r) =>
                r.label.toLowerCase().contains(query.toLowerCase()),
          )
          .toList(),
    );

class _Typeahead extends StatefulWidget {
  const _Typeahead();

  @override
  State<_Typeahead> createState() => _TypeaheadState();
}

class _TypeaheadState extends State<_Typeahead> {
  final TextEditingController _controller = TextEditingController();

  List<_SearchResult> _results = const <_SearchResult>[];
  bool _loading = false;
  bool _open = false;
  int _hovered = -1;

  // One counter stands in for both of upstream's cancellations: the debounce
  // timer and the in-flight request. Anything that started under an older
  // sequence number drops its result on the floor.
  int _sequence = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onChanged(String query) async {
    final int sequence = ++_sequence;
    if (query.isEmpty) {
      setState(() {
        _results = const <_SearchResult>[];
        _open = false;
        _loading = false;
      });
      return;
    }

    setState(() {
      _open = true;
      _loading = true;
      _hovered = -1;
    });

    await Future<void>.delayed(const Duration(milliseconds: _debounceMs));
    if (!mounted || sequence != _sequence) return;

    final List<_SearchResult> data = await _fetchResults(query);
    if (!mounted || sequence != _sequence) return;

    setState(() {
      _results = data;
      _loading = false;
    });
  }

  void _select(_SearchResult result) {
    _sequence++;
    _controller.value = TextEditingValue(
      text: result.label,
      selection: TextSelection.collapsed(offset: result.label.length),
    );
    setState(() {
      _open = false;
      _loading = false;
      _hovered = -1;
    });
  }

  void _close() {
    _sequence++;
    setState(() {
      _results = const <_SearchResult>[];
      _open = false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final FluentColors colors = FluentTheme.of(context).colors;
    final bool showDropdown = _open && (_loading || _results.isNotEmpty);
    final bool noResults =
        _open && !_loading && _controller.text.isNotEmpty && _results.isEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FluentSearchBox(
            controller: _controller,
            placeholder: 'Search...',
            onChanged: _onChanged,
            // Arrow-key traversal of the list is upstream's; matching keys here
            // would need LogicalKeyboardKey from package:flutter/services.dart,
            // which this example may not import. Enter takes the first result
            // and Escape clears the box, which is what FluentSearchBox already
            // binds.
            onSubmitted: (String _) {
              if (_results.isNotEmpty) _select(_results.first);
            },
            onClear: _close,
          ),
          // Upstream absolutely positions the listbox over the page. Rendered
          // in flow here: a docs demo has room below it, and an overlay would
          // add a layer link and a route observer to a list of ten strings.
          if (showDropdown || noResults)
            Semantics(
              container: true,
              label: 'Search results',
              child: Container(
                margin: const EdgeInsets.only(top: FluentSpacing.xs),
                padding: const EdgeInsets.symmetric(vertical: FluentSpacing.xs),
                decoration: BoxDecoration(
                  color: colors.neutralBackground1,
                  border: Border.all(color: colors.neutralStroke1),
                  borderRadius: FluentRadius.allMedium,
                  boxShadow: FluentElevation.shadow16.shadows(
                    ambient: colors.neutralShadowAmbient,
                    key: colors.neutralShadowKey,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: FluentSpacing.s,
                          horizontal: FluentSpacing.m,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FluentSpinner(
                            size: FluentSpinnerSize.tiny,
                            label: Text('Loading results…'),
                          ),
                        ),
                      )
                    else if (_results.isNotEmpty)
                      for (final (int index, _SearchResult result)
                          in _results.indexed)
                        MouseRegion(
                          key: ValueKey<String>(result.id),
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => setState(() => _hovered = index),
                          onExit: (_) => setState(() => _hovered = -1),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _select(result),
                            child: ColoredBox(
                              color: _hovered == index
                                  ? colors.neutralBackground1Hover
                                  : colors.neutralBackground1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: FluentSpacing.s,
                                  horizontal: FluentSpacing.m,
                                ),
                                child: Text(result.label),
                              ),
                            ),
                          ),
                        )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: FluentSpacing.s,
                          horizontal: FluentSpacing.m,
                        ),
                        child: Text(
                          'No results found',
                          style: TextStyle(color: colors.neutralForeground3),
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
}

// #enddocregion components-searchbox--typeahead
