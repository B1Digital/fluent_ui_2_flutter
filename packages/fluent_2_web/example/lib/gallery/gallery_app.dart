import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import 'story.dart';

/// The themes the gallery can switch between.
///
/// Every one is a real `FluentThemeData` constructor rather than a recoloured
/// copy, so switching here exercises the same code path a consumer would.
enum GalleryTheme {
  /// `FluentThemeData.light()`.
  webLight('Web light'),

  /// `FluentThemeData.dark()`.
  webDark('Web dark'),

  /// `FluentThemeData.light()` with the Teams brand ramp.
  teamsLight('Teams light'),

  /// `FluentThemeData.teamsDark()` — a separate table upstream, not dark + Teams.
  teamsDark('Teams dark'),

  /// `FluentThemeData.highContrast()`.
  highContrast('High contrast');

  const GalleryTheme(this.label);

  /// Shown in the theme picker.
  final String label;

  /// Builds the theme, optionally rebranded by a custom key colour.
  FluentThemeData resolve(Color? brandKey) {
    final ramp = brandKey == null
        ? null
        : FluentBrandRamp.fromKeyColor(brandKey);
    return switch (this) {
      GalleryTheme.webLight => FluentThemeData.light(
        brand: ramp ?? FluentBrandRamp.web,
        fontPlatform: FluentFontPlatform.web,
      ),
      GalleryTheme.webDark => FluentThemeData.dark(
        brand: ramp ?? FluentBrandRamp.web,
        fontPlatform: FluentFontPlatform.web,
      ),
      GalleryTheme.teamsLight => FluentThemeData.light(
        brand: ramp ?? FluentBrandRamp.teams,
        fontPlatform: FluentFontPlatform.web,
      ),
      GalleryTheme.teamsDark => FluentThemeData.teamsDark(
        brand: ramp ?? FluentBrandRamp.teams,
        fontPlatform: FluentFontPlatform.web,
      ),
      // High contrast ignores any brand ramp by design.
      GalleryTheme.highContrast => FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      ),
    };
  }
}

/// The gallery: a browsable catalogue of every component and its stories.
///
/// Structured like the Fluent React storybook — a component tree on the left, a
/// live canvas in the middle, and a controls panel on the right — because that
/// is the layout the design system's own documentation uses, and matching it
/// makes the two directly comparable.
class GalleryApp extends StatefulWidget {
  /// Creates the gallery over [sections].
  const GalleryApp({super.key, required this.sections});

  /// Every component's stories.
  final List<StorySection> sections;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  GalleryTheme _theme = GalleryTheme.webLight;
  bool _rtl = false;
  bool _reducedMotion = false;
  Color? _brandKey;
  late StorySection _section = widget.sections.first;
  late Story _story = _section.stories.first;
  final Map<String, Object?> _knobs = {};

  void _select(StorySection section, Story story) => setState(() {
    _section = section;
    _story = story;
    _knobs
      ..clear()
      ..addEntries(story.knobs.map((k) => MapEntry(k.id, k.initial)));
  });

  @override
  void initState() {
    super.initState();
    _knobs.addEntries(_story.knobs.map((k) => MapEntry(k.id, k.initial)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme.resolve(_brandKey);
    return FluentApp(
      title: 'Fluent 2 for Flutter',
      theme: theme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: _reducedMotion),
        child: Directionality(
          textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),
      ),
      home: _GalleryShell(
        sections: widget.sections,
        section: _section,
        story: _story,
        onSelect: _select,
        theme: _theme,
        onThemeChanged: (t) => setState(() => _theme = t),
        rtl: _rtl,
        onRtlChanged: (v) => setState(() => _rtl = v),
        reducedMotion: _reducedMotion,
        onReducedMotionChanged: (v) => setState(() => _reducedMotion = v),
        brandKey: _brandKey,
        onBrandKeyChanged: (c) => setState(() => _brandKey = c),
        knobs: _knobs,
        onKnobChanged: (id, v) => setState(() => _knobs[id] = v),
      ),
    );
  }
}

class _GalleryShell extends StatelessWidget {
  const _GalleryShell({
    required this.sections,
    required this.section,
    required this.story,
    required this.onSelect,
    required this.theme,
    required this.onThemeChanged,
    required this.rtl,
    required this.onRtlChanged,
    required this.reducedMotion,
    required this.onReducedMotionChanged,
    required this.brandKey,
    required this.onBrandKeyChanged,
    required this.knobs,
    required this.onKnobChanged,
  });

  final List<StorySection> sections;
  final StorySection section;
  final Story story;
  final void Function(StorySection, Story) onSelect;
  final GalleryTheme theme;
  final ValueChanged<GalleryTheme> onThemeChanged;
  final bool rtl;
  final ValueChanged<bool> onRtlChanged;
  final bool reducedMotion;
  final ValueChanged<bool> onReducedMotionChanged;
  final Color? brandKey;
  final ValueChanged<Color?> onBrandKeyChanged;
  final Map<String, Object?> knobs;
  final void Function(String, Object?) onKnobChanged;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    return DecoratedBox(
      decoration: BoxDecoration(color: t.colors.neutralBackground3),
      child: Column(
        children: [
          _Toolbar(
            theme: theme,
            onThemeChanged: onThemeChanged,
            rtl: rtl,
            onRtlChanged: onRtlChanged,
            reducedMotion: reducedMotion,
            onReducedMotionChanged: onReducedMotionChanged,
            brandKey: brandKey,
            onBrandKeyChanged: onBrandKeyChanged,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 260,
                  child: _Sidebar(
                    sections: sections,
                    current: story,
                    onSelect: onSelect,
                  ),
                ),
                Expanded(
                  child: _Canvas(section: section, story: story, knobs: knobs),
                ),
                if (wide && story.knobs.isNotEmpty)
                  SizedBox(
                    width: 280,
                    child: _Controls(
                      story: story,
                      values: knobs,
                      onChanged: onKnobChanged,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.theme,
    required this.onThemeChanged,
    required this.rtl,
    required this.onRtlChanged,
    required this.reducedMotion,
    required this.onReducedMotionChanged,
    required this.brandKey,
    required this.onBrandKeyChanged,
  });

  final GalleryTheme theme;
  final ValueChanged<GalleryTheme> onThemeChanged;
  final bool rtl;
  final ValueChanged<bool> onRtlChanged;
  final bool reducedMotion;
  final ValueChanged<bool> onReducedMotionChanged;
  final Color? brandKey;
  final ValueChanged<Color?> onBrandKeyChanged;

  static const _brandKeys = <String, Color?>{
    'Default': null,
    'Cranberry': Color(0xFFC50F1F),
    'Forest': Color(0xFF107C10),
    'Grape': Color(0xFF881798),
    'Marigold': Color(0xFFEAA300),
  };

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.colors.neutralBackground1,
        border: Border(bottom: BorderSide(color: t.colors.neutralStroke2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FluentSpacing.l,
          vertical: FluentSpacing.s,
        ),
        child: Row(
          spacing: FluentSpacing.l,
          children: [
            Text('Fluent 2 for Flutter', style: t.typography.subtitle2),
            const Spacer(),
            _Picker<GalleryTheme>(
              label: 'Theme',
              value: theme,
              options: GalleryTheme.values,
              labelOf: (v) => v.label,
              onChanged: onThemeChanged,
            ),
            _Picker<String>(
              label: 'Brand',
              value: _brandKeys.entries
                  .firstWhere(
                    (e) => e.value == brandKey,
                    orElse: () => _brandKeys.entries.first,
                  )
                  .key,
              options: _brandKeys.keys.toList(),
              labelOf: (v) => v,
              onChanged: (k) => onBrandKeyChanged(_brandKeys[k]),
            ),
            _Toggle(label: 'RTL', value: rtl, onChanged: onRtlChanged),
            _Toggle(
              label: 'Reduced motion',
              value: reducedMotion,
              onChanged: onReducedMotionChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _Picker<T> extends StatelessWidget {
  const _Picker({
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.sNudge,
      children: [
        Text(
          label,
          style: t.typography.caption1.copyWith(
            color: t.colors.neutralForeground3,
          ),
        ),
        SizedBox(
          width: 150,
          child: FluentDropdown<T>(
            value: value,
            options: [
              for (final o in options)
                FluentDropdownOption<T>(value: o, label: Text(labelOf(o))),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) =>
      FluentSwitch(checked: value, onChanged: onChanged, label: Text(label));
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.sections,
    required this.current,
    required this.onSelect,
  });

  final List<StorySection> sections;
  final Story current;
  final void Function(StorySection, Story) onSelect;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final byCategory = <String, List<StorySection>>{};
    for (final s in sections) {
      byCategory.putIfAbsent(s.category, () => []).add(s);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.colors.neutralBackground1,
        border: Border(right: BorderSide(color: t.colors.neutralStroke2)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: FluentSpacing.s),
        children: [
          for (final entry in byCategory.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FluentSpacing.l,
                FluentSpacing.m,
                FluentSpacing.l,
                FluentSpacing.xs,
              ),
              child: Text(
                entry.key.toUpperCase(),
                style: t.typography.caption1Strong.copyWith(
                  color: t.colors.neutralForeground3,
                ),
              ),
            ),
            for (final section in entry.value)
              _SidebarSection(
                section: section,
                current: current,
                onSelect: onSelect,
              ),
          ],
        ],
      ),
    );
  }
}

class _SidebarSection extends StatefulWidget {
  const _SidebarSection({
    required this.section,
    required this.current,
    required this.onSelect,
  });

  final StorySection section;
  final Story current;
  final void Function(StorySection, Story) onSelect;

  @override
  State<_SidebarSection> createState() => _SidebarSectionState();
}

class _SidebarSectionState extends State<_SidebarSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final owns = widget.section.stories.contains(widget.current);
    final open = _open || owns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluentButton(
          appearance: FluentButtonAppearance.subtle,
          size: FluentButtonSize.small,
          onPressed: () => setState(() => _open = !open),
          child: Text(widget.section.component),
        ),
        if (open)
          for (final story in widget.section.stories)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: FluentSpacing.l),
              child: FluentButton(
                appearance: story == widget.current
                    ? FluentButtonAppearance.secondary
                    : FluentButtonAppearance.transparent,
                size: FluentButtonSize.small,
                onPressed: () => widget.onSelect(widget.section, story),
                child: Text(story.name, style: t.typography.caption1),
              ),
            ),
      ],
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({
    required this.section,
    required this.story,
    required this.knobs,
  });

  final StorySection section;
  final Story story;
  final Map<String, Object?> knobs;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    return ListView(
      padding: const EdgeInsets.all(FluentSpacing.xxl),
      children: [
        Text(section.component, style: t.typography.title3),
        const SizedBox(height: FluentSpacing.xs),
        Text(story.name, style: t.typography.subtitle2),
        if (story.description != null) ...[
          const SizedBox(height: FluentSpacing.s),
          Text(
            story.description!,
            style: t.typography.body1.copyWith(
              color: t.colors.neutralForeground2,
            ),
          ),
        ],
        const SizedBox(height: FluentSpacing.xl),
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.colors.neutralBackground1,
            borderRadius: FluentRadius.allMedium,
            border: Border.all(color: t.colors.neutralStroke2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(FluentSpacing.xxl),
            child: KnobsScope(
              values: knobs,
              child: Builder(builder: story.builder),
            ),
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.story,
    required this.values,
    required this.onChanged,
  });

  final Story story;
  final Map<String, Object?> values;
  final void Function(String, Object?) onChanged;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.colors.neutralBackground1,
        border: Border(left: BorderSide(color: t.colors.neutralStroke2)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(FluentSpacing.l),
        children: [
          Text('Controls', style: t.typography.subtitle2),
          const SizedBox(height: FluentSpacing.m),
          for (final knob in story.knobs) ...[
            _KnobField(
              knob: knob,
              value: values[knob.id],
              onChanged: onChanged,
            ),
            const SizedBox(height: FluentSpacing.m),
          ],
        ],
      ),
    );
  }
}

class _KnobField extends StatelessWidget {
  const _KnobField({
    required this.knob,
    required this.value,
    required this.onChanged,
  });

  final Knob<Object?> knob;
  final Object? value;
  final void Function(String, Object?) onChanged;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.xs,
      children: [
        Text(
          knob.label,
          style: t.typography.caption1.copyWith(
            color: t.colors.neutralForeground3,
          ),
        ),
        switch (knob) {
          BoolKnob() => FluentSwitch(
            checked: value as bool? ?? false,
            onChanged: (v) => onChanged(knob.id, v),
          ),
          TextKnob() => FluentInput(
            controller: TextEditingController(text: value as String? ?? ''),
            onChanged: (v) => onChanged(knob.id, v),
          ),
          NumberKnob(:final min, :final max, :final step) => FluentSlider(
            value: (value as double?) ?? min,
            min: min,
            max: max,
            step: step,
            onChanged: (v) => onChanged(knob.id, v),
          ),
          OptionKnob<Object?>(:final options, :final labelOf) =>
            FluentDropdown<Object?>(
              value: value,
              options: [
                for (final o in options)
                  FluentDropdownOption<Object?>(
                    value: o,
                    label: Text(labelOf(o)),
                  ),
              ],
              onChanged: (v) => onChanged(knob.id, v),
            ),
        },
      ],
    );
  }
}
