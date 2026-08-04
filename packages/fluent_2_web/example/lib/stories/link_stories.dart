import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentLink].
final StorySection linkStories = StorySection(
  component: 'Link',
  description:
      'Text that takes you somewhere or does something. A link is ink rather '
      'than a surface — it paints no fill and no border — and its focus '
      'indicator is a doubled, recoloured underline instead of a ring.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every axis the widget exposes, live. There is no href: onPressed is '
          'a plain callback, so routing, scrolling and opening a dialog are all '
          'equally legitimate destinations.',
      knobs: const [
        TextKnob(label: 'Text', id: 'text', initial: 'Fluent 2 documentation'),
        OptionKnob<FluentLinkAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentLinkAppearance.standard,
          options: FluentLinkAppearance.values,
          labelOf: _appearanceLabel,
        ),
        BoolKnob(label: 'Inline', id: 'inline'),
        BoolKnob(label: 'Trailing icon', id: 'icon'),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _CountingLink(
          text: knobs.get<String>('text', 'Fluent 2 documentation'),
          appearance: knobs.get<FluentLinkAppearance>(
            'appearance',
            FluentLinkAppearance.standard,
          ),
          inline: knobs.get<bool>('inline', false),
          showIcon: knobs.get<bool>('icon', false),
          enabled: !knobs.get<bool>('disabled', false),
        );
      },
    ),
    const Story(
      name: 'Appearance',
      description:
          'Three colour treatments: brand ink by default, neutral ink for '
          'dense or already-coloured content, and inverted ink for a link '
          'sitting on a brand-filled surface.',
      builder: _appearanceBuilder,
    ),
    Story(
      name: 'Inline',
      description:
          'A link inside a paragraph underlines at rest, because colour alone '
          'does not separate it from the prose around it. Toggle the knob to '
          'see how little a standalone link would offer here.',
      knobs: const [BoolKnob(label: 'Inline', id: 'inline', initial: true)],
      builder: (context) =>
          _Paragraph(inline: KnobsScope.of(context).get<bool>('inline', true)),
    ),
    const Story(
      name: 'Trailing icon',
      description:
          'The icon slot follows the label in reading order and inherits the '
          'link ink, so it recolours with hover, press and disabled without '
          'being told to.',
      builder: _iconBuilder,
    ),
    const Story(
      name: 'Disabled',
      description:
          'Passing a null onPressed disables the link for real: it takes the '
          'disabled ink, refuses keyboard focus, ignores the pointer, and '
          'never reports hover.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Announced label',
      description:
          'When the visible text is "read more", semanticLabel gives assistive '
          'technology the destination instead — and suppresses the visible '
          'text so it is not announced twice.',
      builder: _semanticsBuilder,
    ),
  ],
);

String _appearanceLabel(FluentLinkAppearance appearance) =>
    switch (appearance) {
      FluentLinkAppearance.standard => 'Standard',
      FluentLinkAppearance.subtle => 'Subtle',
      FluentLinkAppearance.overBrand => 'Over brand',
    };

/// The stories below demonstrate rendering, not navigation, so activation has
/// nothing to do. Only `Default` reports its presses.
void _noop() {}

Widget _appearanceBuilder(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: FluentSpacing.l,
  children: <Widget>[
    _Captioned(
      caption: 'Standard — brand ink, for a link on a neutral surface',
      child: FluentLink(onPressed: _noop, child: Text('Release notes')),
    ),
    _Captioned(
      caption: 'Subtle — neutral ink, for a link inside dense content',
      child: FluentLink(
        appearance: FluentLinkAppearance.subtle,
        onPressed: _noop,
        child: Text('Release notes'),
      ),
    ),
    _Captioned(
      caption: 'Over brand — inverted ink, on a brand-filled surface',
      child: _BrandSurface(
        child: FluentLink(
          appearance: FluentLinkAppearance.overBrand,
          onPressed: _noop,
          child: Text('Release notes'),
        ),
      ),
    ),
  ],
);

Widget _iconBuilder(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: FluentSpacing.l,
  children: <Widget>[
    _Captioned(
      caption: 'Enabled — hover to watch the glyph follow the label ink',
      child: FluentLink(
        icon: _OpenGlyph(),
        onPressed: _noop,
        child: Text('Open in a new window'),
      ),
    ),
    _Captioned(
      caption: 'Disabled — the glyph greys with the label, not on its own',
      child: FluentLink(
        icon: _OpenGlyph(),
        child: Text('Open in a new window'),
      ),
    ),
    _Captioned(
      caption: 'Inline — the underline runs under the label only',
      child: FluentLink(
        inline: true,
        icon: _OpenGlyph(),
        onPressed: _noop,
        child: Text('Open in a new window'),
      ),
    ),
  ],
);

Widget _disabledBuilder(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: FluentSpacing.l,
  children: <Widget>[
    _Captioned(
      caption: 'Enabled — tab to it, and the focus underline doubles',
      child: FluentLink(onPressed: _noop, child: Text('Terms of service')),
    ),
    _Captioned(
      caption: 'Disabled — tab past it; focus never lands here',
      child: FluentLink(child: Text('Terms of service')),
    ),
    _Captioned(
      caption: 'Disabled and subtle — one disabled ink serves every appearance',
      child: FluentLink(
        appearance: FluentLinkAppearance.subtle,
        child: Text('Terms of service'),
      ),
    ),
  ],
);

Widget _semanticsBuilder(BuildContext context) => const _Prose(
  children: <InlineSpan>[
    TextSpan(text: 'Version 2.4 changes how theming is resolved. '),
    WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: FluentLink(
        inline: true,
        semanticLabel: 'Read the 2.4 release notes',
        onPressed: _noop,
        child: Text('Read more'),
      ),
    ),
    TextSpan(text: '.'),
  ],
);

/// A link that reports its own activations, so `Default` shows a live control
/// rather than a frozen picture of one.
class _CountingLink extends StatefulWidget {
  const _CountingLink({
    required this.text,
    required this.appearance,
    required this.inline,
    required this.showIcon,
    required this.enabled,
  });

  final String text;
  final FluentLinkAppearance appearance;
  final bool inline;
  final bool showIcon;
  final bool enabled;

  @override
  State<_CountingLink> createState() => _CountingLinkState();
}

class _CountingLinkState extends State<_CountingLink> {
  int _presses = 0;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final link = FluentLink(
      appearance: widget.appearance,
      inline: widget.inline,
      icon: widget.showIcon ? const _OpenGlyph() : null,
      onPressed: widget.enabled ? () => setState(() => _presses++) : null,
      child: Text(widget.text),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: <Widget>[
        // Over-brand ink is invisible on a neutral canvas, so this one story
        // puts the brand fill behind it rather than pretending otherwise.
        if (widget.appearance == FluentLinkAppearance.overBrand)
          _BrandSurface(child: link)
        else
          link,
        Text(
          switch (_presses) {
            0 => 'Not activated yet — click it, or tab to it and press Enter.',
            1 => 'Activated once.',
            _ => 'Activated $_presses times.',
          },
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
      ],
    );
  }
}

/// A sentence with a link in the middle of it, which is the only place the
/// `inline` underline earns its keep.
class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.inline});

  final bool inline;

  @override
  Widget build(BuildContext context) => _Prose(
    children: <InlineSpan>[
      const TextSpan(
        text:
            'Components read their colours from the nearest theme. Anything '
            'you override lands on top of the defaults — see ',
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: FluentLink(
          inline: inline,
          onPressed: _noop,
          child: const Text('the theming guide'),
        ),
      ),
      const TextSpan(
        text: ' for the full resolution order, which is worth reading once.',
      ),
    ],
  );
}

/// A column of body text at a realistic measure, so the link inside it wraps
/// the way it would in a real paragraph.
class _Prose extends StatelessWidget {
  const _Prose({required this.children});

  final List<InlineSpan> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return SizedBox(
      width: 420,
      child: Text.rich(
        TextSpan(children: children),
        style: theme.typography.body1.copyWith(
          color: theme.colors.neutralForeground1,
        ),
      ),
    );
  }
}

/// A brand-filled patch, the only surface `overBrand` is meant to sit on.
class _BrandSurface extends StatelessWidget {
  const _BrandSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.brandBackground,
        borderRadius: FluentRadius.allMedium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.m),
        child: child,
      ),
    );
  }
}

/// One example under a small label naming what it shows.
class _Captioned extends StatelessWidget {
  const _Captioned({required this.caption, required this.child});

  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.xs,
    children: <Widget>[
      FluentLabel(size: FluentLabelSize.small, child: Text(caption)),
      child,
    ],
  );
}

/// An `Open20Regular`-shaped glyph, painted here because this repository ships
/// no icon set — a link's trailing slot takes any widget, and the colour and
/// size arrive through the [IconTheme] `buildFluentLink` wraps it in.
class _OpenGlyph extends StatelessWidget {
  const _OpenGlyph();

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    final size = icon.size ?? FluentSize.size200;
    return CustomPaint(
      size: Size.square(size),
      painter: _OpenGlyphPainter(color: icon.color ?? const Color(0xFF000000)),
    );
  }
}

class _OpenGlyphPainter extends CustomPainter {
  const _OpenGlyphPainter({required this.color});

  final Color color;

  /// The glyph is authored on the 20x20 grid Fluent icons use, then scaled.
  static const double _grid = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _grid;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      // Set before the canvas is scaled, so the stroke scales with the glyph.
      ..strokeWidth = FluentStroke.thicker
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // An open box whose top-right corner is left out, plus the arrow leaving
    // through the gap.
    final box = Path()
      ..moveTo(11.5, 3.5)
      ..lineTo(4.5, 3.5)
      ..lineTo(4.5, 15.5)
      ..lineTo(16.5, 15.5)
      ..lineTo(16.5, 8.5);
    final arrow = Path()
      ..moveTo(9.5, 10.5)
      ..lineTo(16.5, 3.5)
      ..moveTo(11.5, 3.5)
      ..lineTo(16.5, 3.5)
      ..lineTo(16.5, 8.5);

    canvas
      ..save()
      ..scale(scale)
      ..drawPath(box, paint)
      ..drawPath(arrow, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(_OpenGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
