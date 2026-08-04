import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentDialog].
final StorySection dialogStories = StorySection(
  component: 'Dialog',
  description:
      'A surface that interrupts the page to ask for something: a decision, a '
      'confirmation, or a short form. Openness is controlled — the widget '
      'never flips it on its own, so every story here owns a bool and hands it '
      'back through onOpenChange.',
  stories: [
    const Story(
      name: 'Default',
      description:
          'Every axis at once. Press the trigger, then close with the header '
          'button, with Escape, or by clicking the scrim.',
      knobs: [
        OptionKnob<FluentDialogSize>(
          label: 'Size',
          id: 'size',
          initial: FluentDialogSize.medium,
          options: FluentDialogSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentDialogModalType>(
          label: 'Modal type',
          id: 'modalType',
          initial: FluentDialogModalType.modal,
          options: FluentDialogModalType.values,
          labelOf: _modalTypeLabel,
        ),
        BoolKnob(label: 'Close button', id: 'closeButton', initial: true),
        BoolKnob(label: 'Dismissible', id: 'dismissible', initial: true),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'Medium is 600 wide with its actions in a row; small is 320 and '
          'stacks them full width, secondary first — the same two renderings '
          'upstream reaches through a viewport breakpoint.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Modal types',
      description:
          'Modal blocks the page and closes on a scrim click, alert keeps the '
          'scrim but demands an answer, and non-modal leaves the page behind '
          'live and never takes focus. Escape closes all three.',
      builder: _modalTypesBuilder,
    ),
    const Story(
      name: 'Actions',
      description:
          'Primary actions sit at the end of the footer, secondary ones at the '
          'start — a destructive pair with a Help affordance pushed away from '
          'it.',
      knobs: [
        BoolKnob(label: 'Secondary action', id: 'secondary', initial: true),
      ],
      builder: _actionsBuilder,
    ),
    const Story(
      name: 'Confirmation',
      description:
          'The everyday case: a question, two answers, and a result the page '
          'keeps after the surface has gone.',
      builder: _confirmationBuilder,
    ),
    const Story(
      name: 'Non-dismissible',
      description:
          'A null onOpenChange is a real state, not a visual one: the close '
          'button is genuinely disabled, Escape and the scrim are inert, and '
          'only the action inside can end it.',
      builder: _blockingBuilder,
    ),
    const Story(
      name: 'Controlling open and close',
      description:
          'Openness is a value you own. Nothing needs to press the trigger — '
          'flip the switch and the dialog arrives and leaves with the same '
          'motion.',
      builder: _controlledBuilder,
    ),
    const Story(
      name: 'Triggers',
      description:
          'The trigger is whatever you pass as child, and it can be nothing at '
          'all: an empty child leaves the dialog owned by a control elsewhere '
          'on the page.',
      builder: _triggersBuilder,
    ),
    const Story(
      name: 'Title',
      description:
          'The title is a slot, so it can carry an action of its own; the '
          'header close button is separate and can be dropped entirely.',
      builder: _titleBuilder,
    ),
    const Story(
      name: 'With a form',
      description:
          'A field and its control inside the body. The input autofocuses, so '
          'focus lands on it rather than on the surface when the dialog opens, '
          'and Tab stays inside.',
      builder: _formBuilder,
    ),
    const Story(
      name: 'Scrolling long content',
      description:
          'The surface hugs its content, so a long body is the body\'s problem '
          'to bound: constrain it and scroll inside, leaving the title and the '
          'actions pinned.',
      knobs: [
        NumberKnob(
          label: 'Paragraphs',
          id: 'paragraphs',
          initial: 8,
          min: 1,
          max: 20,
        ),
      ],
      builder: _scrollingBuilder,
    ),
    const Story(
      name: 'Nested dialogs',
      description:
          'A dialog opened from inside another. The inner surface stacks on '
          'top, takes the focus trap with it, and Escape closes only the '
          'innermost one.',
      builder: _nestedBuilder,
    ),
    const Story(
      name: 'No focusable content',
      description:
          'Nothing inside can hold focus — no close button, no actions. The '
          'dialog focuses its own scope instead, so Tab has nowhere to escape '
          'to and Escape still closes it.',
      builder: _noFocusBuilder,
    ),
    const Story(
      name: 'Custom style',
      description:
          'Three rungs: the defaults, a FluentDialogTheme over a subtree, and '
          'the widget style merged last. The scrim is a style property like '
          'any other, so the backdrop is restyled here rather than replaced.',
      builder: _styledBuilder,
    ),
  ],
);

String _sizeLabel(FluentDialogSize value) => switch (value) {
  FluentDialogSize.small => 'small (320)',
  FluentDialogSize.medium => 'medium (600)',
};

String _modalTypeLabel(FluentDialogModalType value) => switch (value) {
  FluentDialogModalType.modal => 'modal',
  FluentDialogModalType.alert => 'alert',
  FluentDialogModalType.nonModal => 'non-modal',
};

const String _body =
    'Deleting this workspace removes every board, file and comment in it for '
    'all of its members. There is no undo.';

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final dismissible = knobs.get<bool>('dismissible', true);
  return _Open(
    builder: (context, open, setOpen) => FluentDialog(
      open: open,
      // Null is what makes the dialog non-dismissible, so the knob drives the
      // callback itself rather than a flag beside it.
      onOpenChange: dismissible ? setOpen : null,
      size: knobs.get<FluentDialogSize>('size', FluentDialogSize.medium),
      modalType: knobs.get<FluentDialogModalType>(
        'modalType',
        FluentDialogModalType.modal,
      ),
      showCloseButton: knobs.get<bool>('closeButton', true),
      semanticLabel: 'Delete workspace',
      title: const Text('Delete workspace?'),
      content: const Text(_body),
      secondaryActions: <Widget>[
        FluentButton(
          onPressed: () => setOpen(false),
          child: const Text('Cancel'),
        ),
      ],
      actions: <Widget>[
        FluentButton(
          appearance: FluentButtonAppearance.primary,
          onPressed: () => setOpen(false),
          child: const Text('Delete'),
        ),
      ],
      child: FluentButton(
        onPressed: () => setOpen(true),
        child: const Text('Delete workspace'),
      ),
    ),
  );
}

Widget _sizesBuilder(BuildContext context) => _Cases(
  children: <(String, Widget)>[
    for (final size in FluentDialogSize.values)
      (
        _sizeLabel(size),
        _Open(
          builder: (context, open, setOpen) => FluentDialog(
            open: open,
            onOpenChange: setOpen,
            size: size,
            semanticLabel: 'Delete workspace',
            title: const Text('Delete workspace?'),
            content: const Text(_body),
            secondaryActions: <Widget>[
              FluentButton(
                onPressed: () => setOpen(false),
                child: const Text('Cancel'),
              ),
            ],
            actions: <Widget>[
              FluentButton(
                appearance: FluentButtonAppearance.primary,
                onPressed: () => setOpen(false),
                child: const Text('Delete'),
              ),
            ],
            child: FluentButton(
              onPressed: () => setOpen(true),
              child: Text('Open ${_sizeLabel(size)}'),
            ),
          ),
        ),
      ),
  ],
);

Widget _modalTypesBuilder(BuildContext context) => _Cases(
  children: <(String, Widget)>[
    for (final type in FluentDialogModalType.values)
      (
        _modalTypeLabel(type),
        _Open(
          builder: (context, open, setOpen) => FluentDialog(
            open: open,
            onOpenChange: setOpen,
            modalType: type,
            semanticLabel: 'Sync status',
            title: Text('${_modalTypeLabel(type)} dialog'),
            content: Text(switch (type) {
              FluentDialogModalType.modal =>
                'A scrim covers the page, Tab is trapped, and a click outside '
                    'closes this.',
              FluentDialogModalType.alert =>
                'The scrim is there, but clicking it does nothing — this one '
                    'wants an answer.',
              FluentDialogModalType.nonModal =>
                'No scrim and no focus trap: the page behind stays live, so '
                    'try pressing the other triggers while this is open.',
            }),
            actions: <Widget>[
              FluentButton(
                appearance: FluentButtonAppearance.primary,
                onPressed: () => setOpen(false),
                child: const Text('Got it'),
              ),
            ],
            child: FluentButton(
              onPressed: () => setOpen(true),
              child: Text('Open ${_modalTypeLabel(type)}'),
            ),
          ),
        ),
      ),
  ],
);

Widget _actionsBuilder(BuildContext context) {
  final secondary = KnobsScope.of(context).get<bool>('secondary', true);
  return _Open(
    builder: (context, open, setOpen) => FluentDialog(
      open: open,
      onOpenChange: setOpen,
      semanticLabel: 'Leave the beta',
      title: const Text('Leave the beta?'),
      content: const Text(
        'You keep your data, but the preview features go away until the next '
        'release.',
      ),
      secondaryActions: <Widget>[
        if (secondary)
          FluentButton(
            appearance: FluentButtonAppearance.subtle,
            icon: const Icon(FluentIcons.question_circle_20_regular),
            onPressed: () {},
            child: const Text('Help'),
          ),
      ],
      actions: <Widget>[
        FluentButton(
          onPressed: () => setOpen(false),
          child: const Text('Stay'),
        ),
        FluentButton(
          appearance: FluentButtonAppearance.primary,
          onPressed: () => setOpen(false),
          child: const Text('Leave'),
        ),
      ],
      child: FluentButton(
        onPressed: () => setOpen(true),
        child: const Text('Leave the beta'),
      ),
    ),
  );
}

Widget _confirmationBuilder(BuildContext context) => const _Confirmation();

Widget _blockingBuilder(BuildContext context) => const _Blocking();

Widget _controlledBuilder(BuildContext context) => const _Controlled();

Widget _triggersBuilder(BuildContext context) => const _Triggers();

Widget _formBuilder(BuildContext context) => const _Form();

Widget _titleBuilder(BuildContext context) => _Cases(
  children: <(String, Widget)>[
    (
      'Custom action',
      _Open(
        builder: (context, open, setOpen) => FluentDialog(
          open: open,
          onOpenChange: setOpen,
          // The header's own close button is dropped, and the title slot
          // carries the affordances instead.
          showCloseButton: false,
          semanticLabel: 'Release notes',
          title: Row(
            children: <Widget>[
              const Expanded(child: Text('Release notes')),
              FluentButton.icon(
                icon: const Icon(FluentIcons.open_20_regular),
                semanticLabel: 'Open in a new window',
                appearance: FluentButtonAppearance.subtle,
                onPressed: () {},
              ),
              FluentButton.icon(
                icon: const Icon(fluentDialogCloseIcon),
                semanticLabel: 'Close',
                appearance: FluentButtonAppearance.subtle,
                onPressed: () => setOpen(false),
              ),
            ],
          ),
          content: const Text(
            'Version 2.4 adds workspace templates and fixes the drag handle on '
            'touch screens.',
          ),
          child: FluentButton(
            onPressed: () => setOpen(true),
            child: const Text("What's new"),
          ),
        ),
      ),
    ),
    (
      'No action',
      _Open(
        builder: (context, open, setOpen) => FluentDialog(
          open: open,
          onOpenChange: setOpen,
          showCloseButton: false,
          semanticLabel: 'Release notes',
          title: const Text('Release notes'),
          content: const Text(
            'With no close button the actions are the only way out — and '
            'Escape, which never goes away.',
          ),
          actions: <Widget>[
            FluentButton(
              appearance: FluentButtonAppearance.primary,
              onPressed: () => setOpen(false),
              child: const Text('Close'),
            ),
          ],
          child: FluentButton(
            onPressed: () => setOpen(true),
            child: const Text("What's new"),
          ),
        ),
      ),
    ),
  ],
);

Widget _scrollingBuilder(BuildContext context) {
  final count = KnobsScope.of(context).get<double>('paragraphs', 8).round();
  return _Open(
    builder: (context, open, setOpen) => FluentDialog(
      open: open,
      onOpenChange: setOpen,
      semanticLabel: 'Terms of service',
      title: const Text('Terms of service'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: count,
          padding: EdgeInsets.zero,
          separatorBuilder: (context, index) =>
              const SizedBox(height: FluentSpacing.m),
          itemBuilder: (context, index) =>
              Text('${index + 1}. $_body Clause ${index + 1} of $count.'),
        ),
      ),
      actions: <Widget>[
        FluentButton(
          appearance: FluentButtonAppearance.primary,
          onPressed: () => setOpen(false),
          child: const Text('Accept'),
        ),
      ],
      child: FluentButton(
        onPressed: () => setOpen(true),
        child: const Text('Read the terms'),
      ),
    ),
  );
}

Widget _nestedBuilder(BuildContext context) => _Open(
  builder: (context, open, setOpen) => FluentDialog(
    open: open,
    onOpenChange: setOpen,
    semanticLabel: 'Publish',
    title: const Text('Publish this board?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: <Widget>[
        const Text('Everyone with the link will be able to read it.'),
        _Open(
          builder: (context, innerOpen, setInnerOpen) => FluentDialog(
            open: innerOpen,
            onOpenChange: setInnerOpen,
            size: FluentDialogSize.small,
            modalType: FluentDialogModalType.alert,
            semanticLabel: 'Who can see this',
            title: const Text('Who can see this?'),
            content: const Text(
              'Anyone with the link, signed in or not. Escape closes this one '
              'and leaves the dialog behind it open.',
            ),
            actions: <Widget>[
              FluentButton(
                appearance: FluentButtonAppearance.primary,
                onPressed: () => setInnerOpen(false),
                child: const Text('Back'),
              ),
            ],
            child: FluentLink(
              onPressed: () => setInnerOpen(true),
              child: const Text('Who can see this?'),
            ),
          ),
        ),
      ],
    ),
    secondaryActions: <Widget>[
      FluentButton(
        onPressed: () => setOpen(false),
        child: const Text('Cancel'),
      ),
    ],
    actions: <Widget>[
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () => setOpen(false),
        child: const Text('Publish'),
      ),
    ],
    child: FluentButton(
      onPressed: () => setOpen(true),
      child: const Text('Publish'),
    ),
  ),
);

Widget _noFocusBuilder(BuildContext context) => _Open(
  builder: (context, open, setOpen) => FluentDialog(
    open: open,
    onOpenChange: setOpen,
    showCloseButton: false,
    semanticLabel: 'Saving',
    title: const Text('Saving your changes'),
    content: const Text(
      'Nothing here can take focus, so the dialog holds it on its own scope. '
      'Press Escape to close.',
    ),
    child: FluentButton(
      onPressed: () => setOpen(true),
      child: const Text('Save'),
    ),
  ),
);

Widget _styledBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return _Cases(
    children: <(String, Widget)>[
      (
        'Defaults',
        _Open(
          builder: (context, open, setOpen) => _styledDialog(
            open: open,
            setOpen: setOpen,
            label: 'Defaults',
            body:
                'neutralBackground1 on a backgroundOverlay scrim, 8px corners, '
                'shadow64.',
          ),
        ),
      ),
      (
        'Subtree theme',
        FluentDialogTheme(
          style: FluentDialogStyle.from(
            backgroundColor: theme.colors.neutralBackground2,
            titleTextStyle: theme.typography.title3,
            // Derived from a token rather than picked: a scrim has to stay
            // translucent, and no alias token is both branded and see-through.
            scrimColor: theme.colors.brandBackground.withValues(alpha: 0.4),
          ),
          child: _Open(
            builder: (context, open, setOpen) => _styledDialog(
              open: open,
              setOpen: setOpen,
              label: 'Subtree theme',
              body:
                  'A FluentDialogTheme restyles the surface and the backdrop '
                  'for everything under it.',
            ),
          ),
        ),
      ),
      (
        'Widget style',
        _Open(
          builder: (context, open, setOpen) => _styledDialog(
            open: open,
            setOpen: setOpen,
            label: 'Widget style',
            body:
                'Merged last, and per property: overriding the width and the '
                'corners keeps every resolved colour.',
            style: FluentDialogStyle.from(
              maxWidth: 400,
              borderRadius: FluentRadius.allSmall,
              padding: const EdgeInsets.all(FluentSpacing.xxxl),
            ),
          ),
        ),
      ),
    ],
  );
}

/// One dialog per rung of the customisation ladder, so the three cases differ
/// only in what is styling them.
Widget _styledDialog({
  required bool open,
  required ValueChanged<bool> setOpen,
  required String label,
  required String body,
  FluentDialogStyle? style,
}) => FluentDialog(
  open: open,
  onOpenChange: setOpen,
  style: style,
  semanticLabel: label,
  title: Text(label),
  content: Text(body),
  actions: <Widget>[
    FluentButton(
      appearance: FluentButtonAppearance.primary,
      onPressed: () => setOpen(false),
      child: const Text('Close'),
    ),
  ],
  child: FluentButton(
    onPressed: () => setOpen(true),
    child: Text('Open $label'),
  ),
);

/// Owns the one bool a controlled dialog needs.
///
/// Every story here is stateful for the same reason — [FluentDialog.open] is
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

/// A confirmation whose answer outlives the surface.
class _Confirmation extends StatefulWidget {
  const _Confirmation();

  @override
  State<_Confirmation> createState() => _ConfirmationState();
}

class _ConfirmationState extends State<_Confirmation> {
  bool _open = false;
  bool? _confirmed;

  void _answer({required bool confirmed}) => setState(() {
    _confirmed = confirmed;
    _open = false;
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.l,
    children: <Widget>[
      FluentDialog(
        open: _open,
        onOpenChange: (value) => setState(() => _open = value),
        modalType: FluentDialogModalType.alert,
        semanticLabel: 'Discard draft',
        title: const Text('Discard this draft?'),
        content: const Text(
          'The draft has unsaved edits. Discarding them cannot be undone.',
        ),
        secondaryActions: <Widget>[
          FluentButton(
            onPressed: () => _answer(confirmed: false),
            child: const Text('Keep editing'),
          ),
        ],
        actions: <Widget>[
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: () => _answer(confirmed: true),
            child: const Text('Discard'),
          ),
        ],
        child: FluentButton(
          onPressed: () => setState(() => _open = true),
          child: const Text('Discard draft'),
        ),
      ),
      if (_confirmed != null)
        FluentMessageBar(
          intent: _confirmed!
              ? FluentMessageBarIntent.warning
              : FluentMessageBarIntent.success,
          child: Text(_confirmed! ? 'Draft discarded.' : 'Still editing.'),
        ),
    ],
  );
}

/// A dialog with no dismissal path but its own action.
class _Blocking extends StatefulWidget {
  const _Blocking();

  @override
  State<_Blocking> createState() => _BlockingState();
}

class _BlockingState extends State<_Blocking> {
  bool _open = false;
  bool _accepted = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.l,
    children: <Widget>[
      FluentDialog(
        open: _open,
        // Null, so nothing the dialog offers can close it. The action below
        // reaches this state directly instead.
        semanticLabel: 'Terms update',
        title: const Text('We updated the terms'),
        content: const Text(
          'Escape does nothing, the scrim does nothing, and the header button '
          'is disabled rather than merely greyed. Accepting is the only way '
          'out.',
        ),
        actions: <Widget>[
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: () => setState(() {
              _accepted = true;
              _open = false;
            }),
            child: const Text('Accept'),
          ),
        ],
        child: FluentButton(
          onPressed: () => setState(() => _open = true),
          child: const Text('Show the terms'),
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

/// Openness driven from a control that is not the trigger.
class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.l,
    children: <Widget>[
      FluentSwitch(
        checked: _open,
        onChanged: (value) => setState(() => _open = value),
        label: const Text('Dialog open'),
      ),
      FluentDialog(
        open: _open,
        onOpenChange: (value) => setState(() => _open = value),
        modalType: FluentDialogModalType.nonModal,
        semanticLabel: 'Live region',
        title: const Text('Driven from outside'),
        content: const Text(
          'Non-modal, so the switch behind stays reachable — flip it off to '
          'watch the same exit the close button gives you.',
        ),
        child: const SizedBox.shrink(),
      ),
    ],
  );
}

/// A card trigger, and a dialog with no trigger of its own.
class _Triggers extends StatefulWidget {
  const _Triggers();

  @override
  State<_Triggers> createState() => _TriggersState();
}

class _TriggersState extends State<_Triggers> {
  bool _card = false;
  bool _remote = false;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.xxl,
      children: <Widget>[
        SizedBox(
          width: 280,
          child: FluentDialog(
            open: _card,
            onOpenChange: (value) => setState(() => _card = value),
            semanticLabel: 'Workspace details',
            title: const Text('Design system'),
            content: const Text(
              'Anything can be the trigger: the child is placed where you put '
              'it and keeps its own behaviour.',
            ),
            child: FluentCard(
              onPressed: () => setState(() => _card = true),
              header: Text('Design system', style: theme.typography.subtitle2),
              child: const Text('12 boards · updated yesterday'),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.s,
          children: <Widget>[
            // The dialog itself has an empty child; these two buttons are
            // ordinary page furniture that happen to own its state.
            FluentButton(
              onPressed: () => setState(() => _remote = true),
              child: const Text('Open from here'),
            ),
            FluentButton(
              appearance: FluentButtonAppearance.subtle,
              onPressed: () => setState(() => _remote = true),
              child: const Text('…or from here'),
            ),
          ],
        ),
        FluentDialog(
          open: _remote,
          onOpenChange: (value) => setState(() => _remote = value),
          semanticLabel: 'Opened remotely',
          title: const Text('No trigger at all'),
          content: const Text(
            'This dialog was declared with an empty child, so both buttons '
            'above are equally its trigger.',
          ),
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// A short form inside a dialog, submitted from the footer.
class _Form extends StatefulWidget {
  const _Form();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final TextEditingController _name = TextEditingController();
  bool _open = false;
  String? _created;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    setState(() {
      _created = _name.text.trim();
      _open = false;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.l,
    children: <Widget>[
      FluentDialog(
        open: _open,
        onOpenChange: (value) => setState(() => _open = value),
        semanticLabel: 'New workspace',
        title: const Text('New workspace'),
        content: FluentField(
          label: const Text('Name'),
          hint: const Text('Visible to everyone you invite.'),
          required: true,
          child: FluentInput(
            controller: _name,
            // Focus lands here instead of on the surface, because the dialog's
            // scope has nothing focused when it opens.
            autofocus: true,
            placeholder: const Text('Marketing site'),
            semanticLabel: 'Workspace name',
            onSubmitted: (_) => _submit(),
          ),
        ),
        secondaryActions: <Widget>[
          FluentButton(
            onPressed: () => setState(() => _open = false),
            child: const Text('Cancel'),
          ),
        ],
        actions: <Widget>[
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: _submit,
            child: const Text('Create'),
          ),
        ],
        child: FluentButton(
          onPressed: () => setState(() {
            _name.clear();
            _open = true;
          }),
          child: const Text('New workspace'),
        ),
      ),
      if (_created != null)
        FluentMessageBar(
          intent: FluentMessageBarIntent.success,
          child: Text('Created “$_created”.'),
        ),
    ],
  );
}

/// Side-by-side cases under a caption.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.xxl,
      runSpacing: FluentSpacing.xxl,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: <Widget>[
        for (final (caption, child) in children)
          Column(
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
          ),
      ],
    );
  }
}
