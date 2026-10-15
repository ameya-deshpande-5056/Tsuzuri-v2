import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/library_entry.dart';
import '../services/file_service.dart';
import '../services/library_service.dart';
import '../services/thumbnail_service.dart';
import '../theme/app_theme.dart';
import 'document_thumbnail.dart';

/// The Library screen — Tsuzuri v2's primary entry point.
///
/// Displays a visual document gallery of Markdown documents formatted as
/// miniature paper previews (similar to note galleries like Mi Canvas).
///
/// Features:
/// - First tile is always a dedicated "New Document" tile initiating creation.
/// - Responsive grid of miniature paper document tiles.
/// - Fast, lightweight Markdown thumbnail generation with LRU caching.
/// - Search by filename and directory path.
/// - Sorting by Name, Last Modified, and Recently Opened.
/// - Full context menu per document (Open in Reader, Open in Editor, Remove).
/// - Safe file access, offline operation, and true AMOLED dark theme support.
class LibraryScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const LibraryScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<LibraryEntry> _entries = [];
  List<LibraryEntry> _displayedEntries = [];
  LibrarySortMode _sortMode = LibrarySortMode.name;
  SortDirection _sortDirection = SortDirection.ascending;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    try {
      final entries = await LibraryService.loadEntries();
      final sortMode = await LibraryService.loadSortMode();
      final sortDir = await LibraryService.loadSortDirection();
      if (mounted) {
        setState(() {
          _entries = entries;
          _sortMode = sortMode;
          _sortDirection = sortDir;
          _isLoading = false;
          _errorMessage = null;
        });
        _updateDisplayedEntries();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load library: $e';
        });
      }
    }
  }

  void _updateDisplayedEntries() {
    var filtered = LibraryService.searchEntries(_entries, _searchQuery);
    filtered = LibraryService.sortEntries(filtered, _sortMode, _sortDirection);
    setState(() {
      _displayedEntries = filtered;
    });
  }

  /// Initiates the document creation workflow.
  Future<void> _handleCreateDocument() async {
    final nameController = TextEditingController(text: 'Untitled.md');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          title: const Text('New Document'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter a name for your new Markdown document:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Document Name',
                    hintText: 'e.g. Notes.md',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Filename cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Supported extensions: .md, .markdown, .mdown, .mkdn',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.amoledTextMuted : AppTheme.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Choose Location & Create'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    var fileName = nameController.text.trim();
    if (!LibraryService.isSupportedFile(fileName)) {
      fileName = '$fileName.md';
    }

    try {
      final title = p.basenameWithoutExtension(fileName);
      final initialContent = '# $title\n\n';

      final savedPath = await FileService.pickSavePathAndSave(
        defaultFileName: fileName,
        content: initialContent,
      );

      if (savedPath != null) {
        // Register in library
        _entries = await LibraryService.addFile(_entries, savedPath, markAsOpened: true);
        _updateDisplayedEntries();

        if (mounted) {
          _showToast('Created $fileName');
          // Open directly in Editor mode
          Navigator.of(context).pushNamed(
            '/document',
            arguments: {
              'filePath': savedPath,
              'isEditor': true,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showToast('Error creating document: $e', isError: true);
      }
    }
  }

  Future<void> _handleAddFile() async {
    try {
      final filePath = await LibraryService.pickMarkdownFile();
      if (filePath != null) {
        if (!LibraryService.isSupportedFile(filePath)) {
          _showToast('Unsupported file type. Please select a Markdown file (.md, .markdown, .mdown, .mkdn).', isError: true);
          return;
        }
        setState(() => _isLoading = true);
        _entries = await LibraryService.addFile(_entries, filePath);
        setState(() => _isLoading = false);
        _updateDisplayedEntries();
        if (mounted) {
          _openDocument(_entries.firstWhere(
            (e) => e.filePath == filePath || e.filePath.endsWith(filePath.split('/').last),
            orElse: () => _entries.last,
          ));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast('Error adding file: $e', isError: true);
    }
  }

  Future<void> _handleAddFolder() async {
    try {
      setState(() => _isLoading = true);
      final discovered = await LibraryService.pickFolderAndDiscover();
      if (discovered.isEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          _showToast('No Markdown files found in the selected folder.');
        }
        return;
      }

      for (final path in discovered) {
        _entries = await LibraryService.addFile(_entries, path);
      }
      setState(() => _isLoading = false);
      _updateDisplayedEntries();
      _showToast('Added ${discovered.length} document${discovered.length == 1 ? '' : 's'} to Library.');
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast('Error scanning folder: $e', isError: true);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      ThumbnailService.clearCache();
      _entries = await LibraryService.refreshEntries(_entries);
      _updateDisplayedEntries();
    } catch (e) {
      _showToast('Error refreshing library: $e', isError: true);
    }
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _openDocument(LibraryEntry entry, {bool isEditor = false}) async {
    if (!entry.isAccessible) {
      final retry = await _showInaccessibleDialog(entry);
      if (retry != true) return;
    }

    // Mark as opened
    _entries = await LibraryService.markOpened(_entries, entry.filePath);
    _updateDisplayedEntries();

    if (mounted) {
      await Navigator.of(context).pushNamed(
        '/document',
        arguments: {
          'filePath': entry.filePath,
          'isEditor': isEditor,
        },
      );
      // When returning to library, refresh entries while preserving search/scroll state
      if (mounted) {
        _loadLibrary();
      }
    }
  }

  Future<bool?> _showInaccessibleDialog(LibraryEntry entry) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Inaccessible'),
        content: Text(
          'The file "${entry.filename}" could not be found or accessed at:\n\n'
          '${entry.filePath}\n\n'
          'It may have been moved, deleted, or its permissions may have changed.\n\n'
          'Would you like to try opening it anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Try Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRemoveEntry(LibraryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Library'),
        content: Text(
          'Remove "${entry.filename}" from the Library?\n\n'
          'This will not delete the file from your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _entries = await LibraryService.removeEntry(_entries, entry.filePath);
      ThumbnailService.invalidate(entry.filePath);
      _updateDisplayedEntries();
      _showToast('Removed "${entry.filename}" from Library.');
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _updateDisplayedEntries();
  }

  void _onSortChanged(LibrarySortMode mode) {
    if (_sortMode == mode) {
      _sortDirection = _sortDirection == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
    } else {
      _sortMode = mode;
      _sortDirection = mode == LibrarySortMode.name
          ? SortDirection.ascending
          : SortDirection.descending;
    }
    LibraryService.saveSortMode(_sortMode);
    LibraryService.saveSortDirection(_sortDirection);
    _updateDisplayedEntries();
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[800] : null,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 768;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme, isDark, isDesktop),
            Container(
              height: 1,
              color: theme.colorScheme.outline.withAlpha(50),
            ),
            if (_isLoading && _entries.isEmpty)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Expanded(child: _buildErrorState(theme))
            else
              Expanded(child: _buildGallery(theme, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, bool isDesktop) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isVeryCompact = screenWidth < 360;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : (isVeryCompact ? 10 : 16),
        vertical: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Brand + actions
          Row(
            children: [
              Text(
                '綴り',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isVeryCompact ? 18 : 20,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(width: isVeryCompact ? 6 : 10),
              Text(
                'Library',
                style: TextStyle(
                  fontSize: isVeryCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.amoledTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const Spacer(),
              if (_isRefreshing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Refresh Library',
                  icon: const Icon(Icons.refresh, size: 20),
                  padding: isVeryCompact ? const EdgeInsets.all(4) : null,
                  constraints: isVeryCompact ? const BoxConstraints(minWidth: 32, minHeight: 32) : null,
                  onPressed: _handleRefresh,
                ),
              SizedBox(width: isVeryCompact ? 2 : 4),
              _buildAddMenu(theme, isDark, isVeryCompact: isVeryCompact),
            ],
          ),
          const SizedBox(height: 10),
          // Search and sort row
          Row(
            children: [
              Expanded(child: _buildSearchField(theme, isDark)),
              const SizedBox(width: 8),
              _buildSortButton(theme, isDark, isVeryCompact: isVeryCompact),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddMenu(ThemeData theme, bool isDark, {bool isVeryCompact = false}) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.note_add_outlined, size: 18),
          onPressed: _handleCreateDocument,
          child: const Text('New Document...'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.description_outlined, size: 18),
          onPressed: _handleAddFile,
          child: const Text('Open File...'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.folder_open_outlined, size: 18),
          onPressed: _handleAddFolder,
          child: const Text('Add Folder...'),
        ),
      ],
      builder: (context, controller, child) {
        if (isVeryCompact) {
          return IconButton.filled(
            tooltip: 'Add / Create Document',
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: const Icon(Icons.add, size: 18),
            style: IconButton.styleFrom(
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
            ),
          );
        }

        return FilledButton.icon(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }

  Widget _buildSearchField(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search documents...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.amoledTextMuted : AppTheme.lightTextMuted,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: isDark ? AppTheme.amoledTextMuted : AppTheme.lightTextMuted,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: isDark ? AppTheme.amoledSurface : AppTheme.lightSurface,
        ),
      ),
    );
  }

  Widget _buildSortButton(ThemeData theme, bool isDark, {bool isVeryCompact = false}) {
    final sortLabel = switch (_sortMode) {
      LibrarySortMode.name => 'Name',
      LibrarySortMode.lastModified => 'Modified',
      LibrarySortMode.recentlyOpened => 'Opened',
    };
    final directionIcon = _sortDirection == SortDirection.ascending
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    return PopupMenuButton<LibrarySortMode>(
      tooltip: 'Sort by',
      onSelected: _onSortChanged,
      itemBuilder: (context) => [
        _buildSortMenuItem(LibrarySortMode.name, 'Name', theme),
        _buildSortMenuItem(LibrarySortMode.lastModified, 'Last Modified', theme),
        _buildSortMenuItem(LibrarySortMode.recentlyOpened, 'Recently Opened', theme),
      ],
      child: Container(
        height: 38,
        padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 8 : 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
          color: isDark ? AppTheme.amoledSurface : AppTheme.lightSurface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 16, color: isDark ? AppTheme.amoledTextSecondary : AppTheme.lightTextSecondary),
            if (!isVeryCompact) ...[
              const SizedBox(width: 6),
              Text(
                sortLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.amoledTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(directionIcon, size: 14, color: isDark ? AppTheme.amoledTextSecondary : AppTheme.lightTextSecondary),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<LibrarySortMode> _buildSortMenuItem(
    LibrarySortMode mode,
    String label,
    ThemeData theme,
  ) {
    final isActive = _sortMode == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          if (isActive)
            Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(label),
          if (isActive) ...[
            const Spacer(),
            Icon(
              _sortDirection == SortDirection.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGallery(ThemeData theme, bool isDark) {
    if (_displayedEntries.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsState(theme, isDark);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Compute responsive column count
        final int crossAxisCount;
        if (width < 360) {
          crossAxisCount = 2;
        } else if (width < 600) {
          crossAxisCount = 2;
        } else if (width < 900) {
          crossAxisCount = 3;
        } else if (width < 1200) {
          crossAxisCount = 4;
        } else if (width < 1600) {
          crossAxisCount = 5;
        } else {
          crossAxisCount = 6;
        }

        final padding = width < 480 ? 12.0 : 20.0;
        final spacing = width < 480 ? 12.0 : 16.0;

        // Compute tile width and aspect ratio
        final totalSpacing = spacing * (crossAxisCount - 1);
        final totalPadding = padding * 2;
        final tileWidth = (width - totalPadding - totalSpacing) / crossAxisCount;

        // Paper aspect ratio is ~1:1.3 + ~44px for text area below
        final childAspectRatio = (tileWidth / (tileWidth * 1.28 + 44)).clamp(0.60, 0.72);

        // Total tiles = 1 (New Document tile) + document entries
        final totalItems = 1 + _displayedEntries.length;

        return GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
          ),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            // First tile is always "New Document"
            if (index == 0) {
              return _buildNewDocumentTile(theme, isDark);
            }
            final entry = _displayedEntries[index - 1];
            return _buildDocumentTile(entry, theme, isDark);
          },
        );
      },
    );
  }

  /// The dedicated "New Document" tile — always at index 0.
  Widget _buildNewDocumentTile(ThemeData theme, bool isDark) {
    final borderColor = isDark
        ? AppTheme.amoledBorderStrong
        : theme.colorScheme.outline;
    final surfaceColor = isDark
        ? const Color(0xFF09090C)
        : const Color(0xFFF9F9FB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleCreateDocument,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Miniature paper area for New Document
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: borderColor,
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF16161A) : const Color(0xFFECECEF),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 28,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New document',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create Markdown',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppTheme.amoledTextMuted
                              : AppTheme.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Bottom label aligning with other tile labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'New Document',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24), // reserve space matching context menu icon
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Individual document gallery tile with miniature paper preview.
  Widget _buildDocumentTile(LibraryEntry entry, ThemeData theme, bool isDark) {
    final isMissing = !entry.isAccessible;
    final secondaryColor = isDark ? AppTheme.amoledTextSecondary : AppTheme.lightTextSecondary;
    final mutedColor = isDark ? AppTheme.amoledTextMuted : AppTheme.lightTextMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDocument(entry),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Miniature Paper Preview
            Expanded(
              child: DocumentThumbnail(
                filePath: entry.filePath,
                lastModifiedMs: entry.lastModifiedMs,
                isAccessible: entry.isAccessible,
              ),
            ),
            const SizedBox(height: 6),
            // Info row below paper: Filename & context menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: '${entry.filename}\n${entry.filePath}',
                      waitDuration: const Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.filename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isMissing ? mutedColor : theme.colorScheme.onSurface,
                              decoration: isMissing ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              if (entry.lastModifiedMs != null)
                                Flexible(
                                  child: Text(
                                    _formatTimestamp(entry.lastModifiedMs!),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ),
                              if (isMissing) ...[
                                if (entry.lastModifiedMs != null)
                                  Text(' · ', style: TextStyle(fontSize: 10, color: secondaryColor)),
                                Text(
                                  'Missing',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Document Context Menu Button
                  PopupMenuButton<String>(
                    tooltip: 'Document actions',
                    icon: Icon(Icons.more_vert, size: 16, color: mutedColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onSelected: (action) async {
                      switch (action) {
                        case 'open_reader':
                          _openDocument(entry, isEditor: false);
                          break;
                        case 'open_editor':
                          _openDocument(entry, isEditor: true);
                          break;
                        case 'remove':
                          await _handleRemoveEntry(entry);
                          break;
                        case 'recheck':
                          setState(() => _isRefreshing = true);
                          _entries = await LibraryService.refreshEntries(_entries);
                          ThumbnailService.invalidate(entry.filePath);
                          _updateDisplayedEntries();
                          setState(() => _isRefreshing = false);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open_reader',
                        child: Row(
                          children: [
                            Icon(Icons.auto_stories_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Open in Reader'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'open_editor',
                        child: Row(
                          children: [
                            Icon(Icons.edit_note_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Open in Editor'),
                          ],
                        ),
                      ),
                      if (isMissing)
                        const PopupMenuItem(
                          value: 'recheck',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, size: 18),
                              SizedBox(width: 8),
                              Text('Recheck Access'),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle_outline, size: 18, color: Colors.red[400]),
                            const SizedBox(width: 8),
                            Text('Remove from Library', style: TextStyle(color: Colors.red[400])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: isDark ? AppTheme.amoledTextMuted : AppTheme.lightTextMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No documents match "$_searchQuery"',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.amoledTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
            },
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadLibrary();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a timestamp to a human-readable relative date.
  String _formatTimestamp(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 365) {
      return '${dt.month}/${dt.day}';
    }
    return '${dt.year}/${dt.month}/${dt.day}';
  }
}
