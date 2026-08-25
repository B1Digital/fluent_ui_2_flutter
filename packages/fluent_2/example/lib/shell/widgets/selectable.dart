import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

/// Makes everything inside it selectable with the mouse or keyboard.
///
/// `SelectionArea` would be the one-liner, but it lives in Material and this app
/// does not depend on Material. [SelectableRegion] is the same machinery from
/// `package:flutter/widgets.dart`; it just wants to be told what the drag
/// handles look like, and `fluent_2` already ships those for its text
/// fields.
class Selectable extends StatefulWidget {
  /// Wraps [child] in a selection region.
  const Selectable({super.key, required this.child});

  /// The subtree whose text becomes selectable.
  final Widget child;

  @override
  State<Selectable> createState() => _SelectableState();
}

class _SelectableState extends State<Selectable> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectableRegion(
      focusNode: _focusNode,
      selectionControls: fluentTextSelectionControls,
      child: widget.child,
    );
  }
}
