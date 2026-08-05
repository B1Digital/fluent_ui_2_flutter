import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

/// A titled group of example variants, laid out with a horizontal wrap.
///
/// Used inside story builders so each component demo reads as a labelled
/// "section" with a few representative instances side by side.
class DemoRail extends StatelessWidget {
  const DemoRail({super.key, required this.title, this.children = const []});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluentLabel(size: FluentLabelSize.large, child: Text(title)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        ),
      ],
    );
  }
}

/// A vertical stack of demo sections, with comfortable gaps between them.
class DemoColumn extends StatelessWidget {
  const DemoColumn({super.key, this.children = const []});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final child in this.children) {
      children.add(child);
      children.add(const SizedBox(height: 28));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// Constrains a demo to a consistent nested horizontal row for compact cases.
class DemoRow extends StatelessWidget {
  const DemoRow({super.key, this.children = const []});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
