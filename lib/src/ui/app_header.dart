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

  const AppHeader({
    super.key,
    required this.documentTitle,
    required this.isDirty,
    required this.isEditorMode,
    required this.onToggleMode,
    required this.onOpenToc,
    required this.onSave,
    required this.onMoreActions,
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
      titleSpacing: isVeryCompact ? 8 : 16,
      elevation: 0,
      scrolledUnderElevation: 0,
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
          IconButton(
            tooltip: 'Table of Contents',
            icon: const Icon(Icons.toc_outlined, size: 21),
            padding: isCompact ? const EdgeInsets.all(4) : null,
            constraints: isCompact ? const BoxConstraints(minWidth: 32, minHeight: 32) : null,
            onPressed: onOpenToc,
          ),

        // Save Button (shown on width >= 480; accessible via More menu on smaller screens)
        if (!isCompact)
          IconButton(
            tooltip: 'Save Document (Ctrl+S)',
            icon: const Icon(Icons.save_outlined, size: 20),
            onPressed: onSave,
          ),

        // Toggle View Mode Button
        IconButton(
          tooltip: isEditorMode ? 'Switch to Reader (Ctrl+E)' : 'Switch to Editor (Ctrl+E)',
          icon: Icon(
            isEditorMode ? Icons.auto_stories_outlined : Icons.edit_note_outlined,
            size: 21,
          ),
          padding: isCompact ? const EdgeInsets.all(4) : null,
          constraints: isCompact ? const BoxConstraints(minWidth: 32, minHeight: 32) : null,
          onPressed: onToggleMode,
        ),

        // More Actions Button
        IconButton(
          tooltip: 'More Actions',
          icon: const Icon(Icons.more_horiz, size: 21),
          padding: isCompact ? const EdgeInsets.all(4) : null,
          constraints: isCompact ? const BoxConstraints(minWidth: 32, minHeight: 32) : null,
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
}

