import 'package:flutter/material.dart';
import 'about_dialog.dart';

/// Actions menu/sheet inspired by Tsuzuri v1 layout.
///
/// On desktop and tablet viewports (>= 681px), renders as an anchored
/// dropdown popover in the top-right below the More Actions button,
/// matching Chrome, Firefox, and Tauri-based Tsuzuri v1.
/// On mobile viewports (< 681px), renders as a bottom sheet with a grab handle.
class ActionsSheet extends StatefulWidget {
  final bool isLibraryMode;
  final bool isEditorMode;
  final bool wordWrap;
  final ThemeMode currentThemeMode;
  final VoidCallback? onToggleMode;
  final VoidCallback? onOpenFile;
  final VoidCallback? onSaveFile;
  final VoidCallback? onSaveAsFile;
  final VoidCallback? onToggleFindReplace;
  final VoidCallback? onToggleWordWrap;
  final VoidCallback? onOpenToc;
  final VoidCallback? onAddFolder;
  final VoidCallback? onRescanLibrary;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback? onOpenAbout;

  const ActionsSheet({
    super.key,
    this.isLibraryMode = false,
    this.isEditorMode = false,
    this.wordWrap = true,
    required this.currentThemeMode,
    this.onToggleMode,
    this.onOpenFile,
    this.onSaveFile,
    this.onSaveAsFile,
    this.onToggleFindReplace,
    this.onToggleWordWrap,
    this.onOpenToc,
    this.onAddFolder,
    this.onRescanLibrary,
    required this.onThemeChanged,
    this.onOpenAbout,
  });

  /// Displays the actions sheet adaptively:
  /// - If width >= 681px: Anchored dropdown popover in top-right corner.
  /// - If width < 681px: Modal bottom sheet with grab handle.
  static Future<void> show(BuildContext context, ActionsSheet sheet) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= 681) {
      return showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss Actions Menu',
        barrierColor: Colors.black.withAlpha(20),
        pageBuilder: (dialogContext, anim1, anim2) {
          return SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 48, right: 12),
                child: Material(
                  type: MaterialType.transparency,
                  child: SizedBox(
                    width: 290,
                    child: sheet,
                  ),
                ),
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 150),
        transitionBuilder: (dialogContext, anim1, anim2, child) {
          return FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
              ),
              alignment: Alignment.topRight,
              child: child,
            ),
          );
        },
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => sheet,
      );
    }
  }

  @override
  State<ActionsSheet> createState() => _ActionsSheetState();
}

class _ActionsSheetState extends State<ActionsSheet> {
  late ThemeMode _selectedThemeMode;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.currentThemeMode;
  }

  @override
  void didUpdateWidget(covariant ActionsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentThemeMode != widget.currentThemeMode) {
      _selectedThemeMode = widget.currentThemeMode;
    }
  }

  void _onSelectTheme(ThemeMode mode) {
    setState(() {
      _selectedThemeMode = mode;
    });
    widget.onThemeChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.sizeOf(context).width >= 681;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: isDesktop
            ? BorderRadius.circular(10)
            : const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(60)),
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 160 : 70),
                  blurRadius: 36,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      padding: isDesktop
          ? const EdgeInsets.fromLTRB(14, 10, 14, 16)
          : const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        bottom: !isDesktop,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar (mobile only)
              if (!isDesktop)
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.isLibraryMode ? 'Library Actions' : 'Document Actions',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: isDesktop ? 18 : 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action Items
              if (widget.isLibraryMode) ...[
                if (widget.onOpenFile != null)
                  _buildActionItem(
                    context,
                    icon: Icons.description_outlined,
                    label: 'Open Document...',
                    shortcut: 'Ctrl+O',
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onOpenFile!();
                    },
                  ),
                if (widget.onAddFolder != null)
                  _buildActionItem(
                    context,
                    icon: Icons.create_new_folder_outlined,
                    label: 'Add Folder to Library...',
                    shortcut: null,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onAddFolder!();
                    },
                  ),
                if (widget.onRescanLibrary != null)
                  _buildActionItem(
                    context,
                    icon: Icons.sync,
                    label: 'Rescan Library Folders',
                    shortcut: null,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onRescanLibrary!();
                    },
                  ),
              ] else ...[
                if (widget.onToggleMode != null)
                  _buildActionItem(
                    context,
                    icon: widget.isEditorMode ? Icons.auto_stories_outlined : Icons.edit_note_outlined,
                    label: widget.isEditorMode ? 'Switch to Reader' : 'Switch to Editor',
                    shortcut: 'Ctrl+E',
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onToggleMode!();
                    },
                  ),

                if (widget.onOpenToc != null)
                  _buildActionItem(
                    context,
                    icon: Icons.toc_outlined,
                    label: 'Table of Contents',
                    shortcut: null,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onOpenToc!();
                    },
                  ),

                if (widget.onOpenFile != null)
                  _buildActionItem(
                    context,
                    icon: Icons.folder_open_outlined,
                    label: 'Open Document...',
                    shortcut: 'Ctrl+O',
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onOpenFile!();
                    },
                  ),

                if (widget.onSaveFile != null)
                  _buildActionItem(
                    context,
                    icon: Icons.save_outlined,
                    label: 'Save Document',
                    shortcut: 'Ctrl+S',
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSaveFile!();
                    },
                  ),

                if (widget.onSaveAsFile != null)
                  _buildActionItem(
                    context,
                    icon: Icons.save_as_outlined,
                    label: 'Save As...',
                    shortcut: 'Ctrl+Shift+S',
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSaveAsFile!();
                    },
                  ),

                if (widget.isEditorMode) ...[
                  if (widget.onToggleFindReplace != null)
                    _buildActionItem(
                      context,
                      icon: Icons.search_outlined,
                      label: 'Find & Replace',
                      shortcut: 'Ctrl+F',
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onToggleFindReplace!();
                      },
                    ),
                  if (widget.onToggleWordWrap != null)
                    _buildActionItem(
                      context,
                      icon: Icons.wrap_text_outlined,
                      label: 'Word Wrap: ${widget.wordWrap ? "On" : "Off"}',
                      shortcut: 'Alt+Z',
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onToggleWordWrap!();
                      },
                    ),
                ],
              ],

              _buildActionItem(
                context,
                icon: Icons.info_outline,
                label: 'About Tsuzuri',
                shortcut: null,
                onTap: () {
                  Navigator.of(context).pop();
                  if (widget.onOpenAbout != null) {
                    widget.onOpenAbout!();
                  } else {
                    TsuzuriAboutDialog.show(context);
                  }
                },
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Theme Switcher Section
              Text(
                'Theme',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  _buildThemeButton(
                    context,
                    title: 'System',
                    icon: Icons.brightness_auto_outlined,
                    isSelected: _selectedThemeMode == ThemeMode.system,
                    onTap: () => _onSelectTheme(ThemeMode.system),
                  ),
                  const SizedBox(width: 8),
                  _buildThemeButton(
                    context,
                    title: 'Light',
                    icon: Icons.light_mode_outlined,
                    isSelected: _selectedThemeMode == ThemeMode.light,
                    onTap: () => _onSelectTheme(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _buildThemeButton(
                    context,
                    title: 'AMOLED Dark',
                    icon: Icons.dark_mode_outlined,
                    isSelected: _selectedThemeMode == ThemeMode.dark,
                    onTap: () => _onSelectTheme(ThemeMode.dark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? shortcut,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 19, color: isDark ? Colors.grey[300] : Colors.grey[800]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[200] : Colors.grey[900],
                ),
              ),
            ),
            if (shortcut != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
                ),
                child: Text(
                  shortcut,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          backgroundColor: isSelected
              ? (isDark ? Colors.grey[900] : Colors.grey[200])
              : Colors.transparent,
          side: BorderSide(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : theme.colorScheme.outline.withAlpha(60),
            width: isSelected ? 1.4 : 1.0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
