import 'package:flutter/material.dart';

/// Responsive Tsuzuri Application Header.
///
/// Adaptively scales for viewports from 320px phones to 1920px desktops:
/// - Brand mark "綴り"
/// - Document title and dirty unsaved indicator `•`
/// - Table of Contents trigger button
/// - Save button
/// - Mode switch button (Reader vs Editor)
/// - More actions button (`...`)
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String documentTitle;
  final bool isDirty;
  final bool isEditorMode;
  final VoidCallback onToggleMode;
  final VoidCallback onOpenToc;
  final VoidCallback onSave;
  final VoidCallback onMoreActions;
  final void Function(String text, double rightOffset)? onShowTooltip;
  final VoidCallback? onHideTooltip;
  final Widget? leading;

  const AppHeader({
    super.key,
    required this.documentTitle,
    required this.isDirty,
    required this.isEditorMode,
    required this.onToggleMode,
    required this.onOpenToc,
    required this.onSave,
    required this.onMoreActions,
    this.onShowTooltip,
    this.onHideTooltip,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final isVeryCompact = screenWidth < 360;
    final isCompact = screenWidth < 480;

    return AppBar(
      toolbarHeight: 48,
      titleSpacing: isVeryCompact ? 8 : (leading != null ? 4 : 16),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leading,
      automaticallyImplyLeading: false,
      leadingWidth: leading != null ? 40 : 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Japanese Brand Title
          const Text(
            '綴り',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(width: isVeryCompact ? 8 : 12),

          // Document Title with Dirty Indicator
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    documentTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isVeryCompact ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ),
                if (isDirty) ...[
                  const SizedBox(width: 4),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // View Mode Badge (Hidden on very compact viewports to avoid title truncation)
          if (!isVeryCompact) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline, width: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isEditorMode ? 'Editor' : 'Reader',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        // TOC Button (shown on width >= 360)
        if (!isVeryCompact)
          _buildActionButton(
            tooltip: 'Table of Contents',
            icon: const Icon(Icons.toc_outlined, size: 21),
            isCompact: isCompact,
            rightOffset: 138,
            onPressed: onOpenToc,
          ),

        // Save Button (shown on width >= 480; accessible via More menu on smaller screens)
        if (!isCompact)
          _buildActionButton(
            tooltip: 'Save Document (Ctrl+S)',
            icon: const Icon(Icons.save_outlined, size: 20),
            isCompact: isCompact,
            rightOffset: 96,
            onPressed: onSave,
          ),

        // Toggle View Mode Button
        _buildActionButton(
          tooltip: isEditorMode ? 'Switch to Reader (Ctrl+E)' : 'Switch to Editor (Ctrl+E)',
          icon: Icon(
            isEditorMode ? Icons.auto_stories_outlined : Icons.edit_note_outlined,
            size: 21,
          ),
          isCompact: isCompact,
          rightOffset: 54,
          onPressed: onToggleMode,
        ),

        // More Actions Button
        _buildActionButton(
          tooltip: 'More Actions',
          icon: const Icon(Icons.more_horiz, size: 21),
          isCompact: isCompact,
          rightOffset: 12,
          onPressed: onMoreActions,
        ),
        SizedBox(width: isVeryCompact ? 2 : 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: theme.colorScheme.outline.withAlpha(60),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String tooltip,
    required Widget icon,
    required VoidCallback onPressed,
    required double rightOffset,
    bool isCompact = false,
  }) {
    Widget button = IconButton(
      tooltip: tooltip,
      icon: icon,
      padding: isCompact ? const EdgeInsets.all(4) : null,
      constraints: isCompact ? const BoxConstraints(minWidth: 32, minHeight: 32) : null,
      onPressed: onPressed,
    );

    if (onShowTooltip != null) {
      button = MouseRegion(
        onEnter: (_) => onShowTooltip!(tooltip, rightOffset),
        onExit: (_) => onHideTooltip?.call(),
        child: button,
      );
    }
    return button;
  }
}

