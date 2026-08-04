import 'package:flutter/widgets.dart';

/// A single live example of one component.
///
/// The Dart counterpart of one exported story in a `*.stories.tsx` file: a
/// named, self-contained demonstration of one capability. Stories are grouped
/// into a [StorySection] per component, and the section names mirror upstream's
/// so a reader can move between the two galleries without translating.
@immutable
class Story {
  /// Creates a story.
  const Story({
    required this.name,
    required this.builder,
    this.description,
    this.knobs = const [],
  });

  /// Shown in the sidebar and the URL. Mirrors the upstream story export name,
  /// spaced — `ButtonIconOnly` becomes `Icon only`.
  final String name;

  /// Builds the example. [knobs] values are read through `KnobsScope.of`.
  final WidgetBuilder builder;

  /// One line under the title explaining what the story demonstrates.
  final String? description;

  /// Live controls for this story, rendered in the side panel.
  final List<Knob<Object?>> knobs;

  /// The stable id used in the URL fragment.
  String get slug => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}

/// Every story for one component.
@immutable
class StorySection {
  /// Creates a section.
  const StorySection({
    required this.component,
    required this.stories,
    this.category = 'Components',
    this.description,
  });

  /// The component's display name, e.g. `Button`.
  final String component;

  /// The stories, in the order upstream lists them — `Default` first.
  final List<Story> stories;

  /// Sidebar grouping.
  final String category;

  /// One paragraph shown above the first story.
  final String? description;

  /// The stable id used in the URL fragment.
  String get slug =>
      component.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}

/// A live control bound to one property of a story.
///
/// Knobs are what make the gallery a workbench rather than a screenshot: the
/// same affordance as Storybook's Controls panel.
@immutable
sealed class Knob<T> {
  const Knob({required this.label, required this.id, required this.initial});

  /// Shown beside the control.
  final String label;

  /// Unique within its story.
  final String id;

  /// Starting value.
  final T initial;
}

/// A checkbox knob.
final class BoolKnob extends Knob<bool> {
  /// Creates a boolean knob.
  const BoolKnob({
    required super.label,
    required super.id,
    super.initial = false,
  });
}

/// A free-text knob.
final class TextKnob extends Knob<String> {
  /// Creates a text knob.
  const TextKnob({required super.label, required super.id, super.initial = ''});
}

/// A one-of-many knob, rendered as a segmented control or dropdown.
final class OptionKnob<T> extends Knob<T> {
  /// Creates an option knob over [options].
  const OptionKnob({
    required super.label,
    required super.id,
    required super.initial,
    required this.options,
    required this.labelOf,
  });

  /// The selectable values.
  final List<T> options;

  /// Renders one option for display.
  final String Function(T value) labelOf;
}

/// A numeric knob, rendered as a slider.
final class NumberKnob extends Knob<double> {
  /// Creates a numeric knob over [min]..[max].
  const NumberKnob({
    required super.label,
    required super.id,
    required super.initial,
    this.min = 0,
    this.max = 100,
    this.step = 1,
  });

  /// Lowest selectable value.
  final double min;

  /// Highest selectable value.
  final double max;

  /// Granularity.
  final double step;
}

/// Supplies the live knob values to a story's builder.
class KnobsScope extends InheritedWidget {
  /// Provides [values] to [child].
  const KnobsScope({super.key, required this.values, required super.child});

  /// Current value per knob id.
  final Map<String, Object?> values;

  /// The nearest knob values, or an empty map outside the gallery — so a story
  /// widget stays renderable in a test without the shell around it.
  static KnobsScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KnobsScope>() ??
      const KnobsScope(values: {}, child: SizedBox());

  /// Reads knob [id], falling back to [fallback] when the gallery is absent.
  T get<T>(String id, T fallback) {
    final v = values[id];
    return v is T ? v : fallback;
  }

  @override
  bool updateShouldNotify(KnobsScope oldWidget) => values != oldWidget.values;
}
