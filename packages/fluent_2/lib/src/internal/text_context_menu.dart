import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

/// The cut / copy / paste menu for Fluent text controls.
///
/// Flutter's ready-made toolbars (`AdaptiveTextSelectionToolbar`,
/// `materialTextSelectionControls`) live in Material, so a Material-free design
/// system has to supply its own. The machinery it is built on —
/// [ContextMenuButtonItem], `EditableTextState.contextMenuAnchors`,
/// [TextSelectionToolbarLayoutDelegate] — is all in the widgets layer.
///
/// Pass it to `EditableText.contextMenuBuilder`:
///
/// ```dart
/// EditableText(contextMenuBuilder: fluentTextContextMenuBuilder, ...)
/// ```
///
/// Without a builder the control still selects, drags and responds to the
/// keyboard shortcuts — [EditableText] handles those itself — but right-click
/// and long-press produce nothing at all, which is easy to miss.
///
/// The themes are captured here rather than left to the framework.
/// `ContextMenuController.show` does call [InheritedTheme.capture], but from
/// inside its own `OverlayEntry.builder`, where the `context` parameter shadows
/// the one passed to `show` — so `from:` and `to:` are both already below the
/// [Navigator] and the capture comes back empty. A `FluentThemeOverride`
/// wrapping the field would otherwise be dropped and the menu would paint in
/// the app theme. Capturing from [EditableTextState.context] is correct on
/// every Flutter version, including ones where the framework's own capture
/// works, because the second capture then simply finds nothing left to lift.
Widget fluentTextContextMenuBuilder(
  BuildContext context,
  EditableTextState state,
) =>
    InheritedTheme.capture(
      from: state.context,
      to: Navigator.maybeOf(state.context)?.context,
    ).wrap(
      FluentTextContextMenu(
        anchor: state.contextMenuAnchors.primaryAnchor,
        items: state.contextMenuButtonItems,
      ),
    );

/// A Fluent-styled text selection toolbar.
class FluentTextContextMenu extends StatelessWidget {
  /// Creates a menu anchored at [anchor] offering [items].
  const FluentTextContextMenu({
    super.key,
    required this.anchor,
    required this.items,
  });

  /// Where the menu points, in global coordinates.
  final Offset anchor;

  /// The actions to offer. Supplied by `EditableTextState`.
  final List<ContextMenuButtonItem> items;

  /// Localized label for [item].
  ///
  /// [ContextMenuButtonItem.label] wins when the caller set one. Otherwise the
  /// label comes from [WidgetsLocalizations], which — unlike most text
  /// affordances — does carry cut/copy/paste/selectAll, so this needs no
  /// Material dependency and no hardcoded English.
  static String labelFor(BuildContext context, ContextMenuButtonItem item) {
    if (item.label != null) return item.label!;
    final l = WidgetsLocalizations.of(context);
    return switch (item.type) {
      ContextMenuButtonType.cut => l.cutButtonLabel,
      ContextMenuButtonType.copy => l.copyButtonLabel,
      ContextMenuButtonType.paste => l.pasteButtonLabel,
      ContextMenuButtonType.selectAll => l.selectAllButtonLabel,
      ContextMenuButtonType.lookUp => l.lookUpButtonLabel,
      ContextMenuButtonType.searchWeb => l.searchWebButtonLabel,
      ContextMenuButtonType.share => l.shareButtonLabel,
      // WidgetsLocalizations carries no label for these; the caller supplies
      // one through ContextMenuButtonItem.label, and an empty string is more
      // honest than a hardcoded English guess.
      ContextMenuButtonType.delete ||
      ContextMenuButtonType.liveTextInput ||
      ContextMenuButtonType.custom => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = FluentTheme.of(context);
    final c = theme.colors;
    final padding = MediaQuery.paddingOf(context);

    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: anchor - const Offset(0, _menuGap),
        anchorBelow: anchor + const Offset(0, _menuGap),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: padding.left + FluentSpacing.m,
          right: padding.right + FluentSpacing.m,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.neutralBackground1,
            borderRadius: FluentRadius.allMedium,
            border: Border.all(color: c.neutralStroke1),
            boxShadow: theme.shadow(FluentElevation.shadow16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(FluentSpacing.xxs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in items)
                  _MenuButton(
                    label: labelFor(context, item),
                    onPressed: item.onPressed,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Gap between the selection and the menu, so it never covers the caret.
  static const double _menuGap = 8;
}

class _MenuButton extends StatefulWidget {
  const _MenuButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final c = theme.colors;
    // No `label:` here — the child Text already contributes one, and setting
    // both merges them into a doubled announcement.
    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _hovered ? c.subtleBackgroundHover : c.subtleBackground,
              borderRadius: FluentRadius.allSmall,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FluentSpacing.m,
                vertical: FluentSpacing.sNudge,
              ),
              child: Text(
                widget.label,
                style: theme.typography.body1.copyWith(
                  color: c.neutralForeground1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
