import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/library_entry.dart';
import '../services/library_service.dart';
import '../theme/app_theme.dart';

/// The Library screen — Tsuzuri v2's primary entry point.
///
/// Displays a browsable, searchable, sortable list of Markdown documents
/// that the user has added or opened. Provides actions to add new documents,
/// open documents from the file system, and manage library entries.
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
      _entries = await LibraryService.refreshEntries(_entries);
      _updateDisplayedEntries();
    } catch (e) {
      _showToast('Error refreshing library: $e', isError: true);
    }
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _openDocument(LibraryEntry entry) async {
    if (!entry.isAccessible) {
      final retry = await _showInaccessibleDialog(entry);
      if (retry != true) return;
    }

    // Mark as opened
    _entries = await LibraryService.markOpened(_entries, entry.filePath);
    _updateDisplayedEntries();

    if (mounted) {
      Navigator.of(context).pushNamed(
        '/document',
        arguments: entry.filePath,
      );
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
      // Toggle direction
      _sortDirection = _sortDirection == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
    } else {
      _sortMode = mode;
      // Default direction for each mode
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
              color: theme.colorScheme.outline.withAlpha(60),
            ),
            if (_isLoading && _entries.isEmpty)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Expanded(child: _buildErrorState(theme))
            else if (_entries.isEmpty)
              Expanded(child: _buildEmptyState(theme, isDark))
            else
              Expanded(child: _buildDocumentList(theme, isDark, isDesktop)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Brand + actions
          Row(
            children: [
              // Brand
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '綴り',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Library',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppTheme.amoledTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Actions
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
                  onPressed: _handleRefresh,
                ),
              if (isDesktop) ...[
                const SizedBox(width: 4),
                _buildAddMenu(theme, isDark),
              ] else ...[
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: _handleAddFile,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Open'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Search and sort row
          Row(
            children: [
              Expanded(child: _buildSearchField(theme, isDark)),
              const SizedBox(width: 8),
              _buildSortButton(theme, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddMenu(ThemeData theme, bool isDark) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.description_outlined, size: 18),
          child: const Text('Open File...'),
          onPressed: _handleAddFile,
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.folder_open_outlined, size: 18),
          child: const Text('Add Folder...'),
          onPressed: _handleAddFolder,
        ),
      ],
      builder: (context, controller, child) {
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

  Widget _buildSortButton(ThemeData theme, bool isDark) {
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
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
          color: isDark ? AppTheme.amoledSurface : AppTheme.lightSurface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 16, color: isDark ? AppTheme.amoledTextSecondary : AppTheme.lightTextSecondary),
            const SizedBox(width: 6),
            Text(
              sortLabel,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.amoledTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
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

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 56,
              color: isDark ? AppTheme.amoledTextMuted : AppTheme.lightTextMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Your Library is Empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Markdown documents to your library to get started.\nSupported formats: .md, .markdown, .mdown, .mkdn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.amoledTextSecondary : AppTheme.lightTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _handleAddFile,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Open Markdown File'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _handleAddFolder,
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: const Text('Add Folder'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
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

  Widget _buildDocumentList(ThemeData theme, bool isDark, bool isDesktop) {
    if (_displayedEntries.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsState(theme, isDark);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 12,
        vertical: 8,
      ),
      itemCount: _displayedEntries.length,
      itemBuilder: (context, index) {
        return _buildDocumentTile(
          _displayedEntries[index],
          theme,
          isDark,
          isDesktop,
        );
      },
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

  Widget _buildDocumentTile(
    LibraryEntry entry,
    ThemeData theme,
    bool isDark,
    bool isDesktop,
  ) {
    final isMissing = !entry.isAccessible;
    final mutedColor = isDark ? AppTheme.amoledTextMuted : AppTheme.lightTextMuted;
    final secondaryColor = isDark ? AppTheme.amoledTextSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openDocument(entry),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 12 : 10,
              vertical: isDesktop ? 10 : 12,
            ),
            child: Row(
              children: [
                // Document icon
                Icon(
                  isMissing
                      ? Icons.warning_amber_outlined
                      : Icons.description_outlined,
                  size: 20,
                  color: isMissing ? Colors.orange[600] : mutedColor,
                ),
                const SizedBox(width: 12),
                // Document info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.filename,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isMissing
                              ? mutedColor
                              : theme.colorScheme.onSurface,
                          decoration: isMissing ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (entry.parentDir != null) ...[
                            Flexible(
                              child: Text(
                                _shortenPath(entry.parentDir!),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryColor,
                                ),
                              ),
                            ),
                          ],
                          if (entry.parentDir != null && entry.lastModifiedMs != null)
                            Text(
                              '  ·  ',
                              style: TextStyle(fontSize: 11, color: secondaryColor),
                            ),
                          if (entry.lastModifiedMs != null)
                            Text(
                              _formatTimestamp(entry.lastModifiedMs!),
                              style: TextStyle(
                                fontSize: 11,
                                color: secondaryColor,
                              ),
                            ),
                          if (isMissing) ...[
                            Text(
                              '  ·  ',
                              style: TextStyle(fontSize: 11, color: secondaryColor),
                            ),
                            Text(
                              'Missing',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Context menu
                PopupMenuButton<String>(
                  tooltip: 'Document actions',
                  icon: Icon(Icons.more_vert, size: 18, color: mutedColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onSelected: (action) async {
                    switch (action) {
                      case 'open_reader':
                        _openDocument(entry);
                        break;
                      case 'remove':
                        await _handleRemoveEntry(entry);
                        break;
                      case 'recheck':
                        setState(() => _isRefreshing = true);
                        _entries = await LibraryService.refreshEntries(_entries);
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
                          Text('Open'),
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
        ),
      ),
    );
  }

  /// Shortens a directory path for display.
  String _shortenPath(String dirPath) {
    if (kIsWeb) return dirPath;
    // Replace home directory with ~
    try {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      if (home.isNotEmpty && dirPath.startsWith(home)) {
        return '~${dirPath.substring(home.length)}';
      }
    } catch (_) {}
    return dirPath;
  }

  /// Formats a timestamp to a human-readable relative or absolute date.
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

