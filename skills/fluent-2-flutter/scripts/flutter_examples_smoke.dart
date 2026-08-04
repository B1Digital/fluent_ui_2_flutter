// ignore_for_file: depend_on_referenced_packages

// Compile-only fixture for the Dart examples in references/flutter-foundations.md.
// Run: dart analyze skills/fluent-2-flutter/scripts/flutter-examples-smoke.dart
import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

void main() {}

Widget appExample() => FluentApp(
  theme: FluentThemeData.light(),
  darkTheme: FluentThemeData.dark(),
  home: const Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: Text('Fluent 2')),
  ),
);

Widget buildSurface(BuildContext context, Widget child) {
  final theme = FluentTheme.of(context);
  return DecoratedBox(
    decoration: BoxDecoration(
      color: theme.colors.neutralBackground1,
      borderRadius: FluentRadius.allMedium,
    ),
    child: DefaultTextStyle(
      style: theme.typography.body1.copyWith(
        color: theme.colors.neutralForeground1,
      ),
      child: child,
    ),
  );
}

Widget actionExample(VoidCallback save) => FluentButton(
  appearance: FluentButtonAppearance.primary,
  onPressed: save,
  child: const Text('Save'),
);

Widget fieldExample() => const FluentField(
  label: Text('Display name'),
  child: FluentInput(
    placeholder: Text('Ada Lovelace'),
    semanticLabel: 'Display name',
  ),
);

Color sharedColorExample() =>
    FluentSharedRamp.all[FluentSharedColor.blue]!.primary;

List<BoxShadow> coloredElevationExample(Color surface) =>
    FluentShadowLuminosity.shadowsOn(surface, FluentElevation.shadow16);

FluentBreakpoint breakpointExample(double width) => FluentBreakpoint.of(width);

TextStyle typographyExample() => FluentTypography.web().title2;

Widget iconExample() => const SizedBox.square(
  dimension: FluentTouchTarget.web,
  child: Icon(FluentIcons.settings_20_regular, size: 20),
);

Widget acrylicExample(Widget child) => FluentAcrylicSurface(
  style: FluentAcrylicSurfaceStyle.from(borderRadius: FluentRadius.allXLarge),
  child: child,
);

Duration motionDurationExample(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : FluentDuration.normal;

Widget shortWaitExample() => const FluentSpinner(
  label: Text('Loading\u00A0…'),
  semanticLabel: 'Loading',
);

Widget measuredWaitExample(double progress) =>
    FluentProgressBar(value: progress, semanticLabel: 'Uploading file');

Widget contentWaitExample() => Semantics(
  liveRegion: true,
  label: 'Loading account overview',
  child: const FluentSkeleton(height: FluentSize.size200),
);

/// The controlled-state example. Every Fluent selection control is
/// controlled-only, so the value has to live somewhere the caller rebuilds.
class ControlledCheckboxExample extends StatefulWidget {
  const ControlledCheckboxExample({super.key});

  @override
  State<ControlledCheckboxExample> createState() =>
      _ControlledCheckboxExampleState();
}

class _ControlledCheckboxExampleState extends State<ControlledCheckboxExample> {
  bool? _accepted;

  @override
  Widget build(BuildContext context) => FluentCheckbox(
    checked: _accepted,
    onChanged: (value) => setState(() => _accepted = value),
    label: const Text('Accept the terms'),
  );
}
