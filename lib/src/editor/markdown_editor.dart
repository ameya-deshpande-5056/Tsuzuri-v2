import 'package:flutter/material.dart';
import 'editor_statusbar.dart';
import 'find_replace_bar.dart';

/// Full-featured raw Markdown source editor.
///
/// Features:
/// - Line numbers gutter with synchronized scrolling
/// - Monospace typography with restrained styling
/// - Word wrap toggle (soft wrapping vs horizontal scrolling)
/// - Inline Find & Replace bar with match cycling
/// - Editor status bar with Ln/Col and word/char count
class MarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool showFindReplace;
  final VoidCallback? onCloseFindReplace;

  const MarkdownEditor({
    super.key,
    required this.controller,
    this.onChanged,
    this.showFindReplace = false,
    this.onCloseFindReplace,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  final ScrollController _textScrollController = ScrollController();
  final ScrollController _gutterScrollController = ScrollController();

  bool _wordWrap = true;
  int _cursorLine = 1;
  int _cursorColumn = 1;

  // Find & Replace state
  String _searchQuery = '';
  List<int> _matchIndices = [];
  int _currentMatchIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextSelectionChange);
    _textScrollController.addListener(_syncScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextSelectionChange);
    _textScrollController.removeListener(_syncScroll);
    _textScrollController.dispose();
    _gutterScrollController.dispose();
    super.dispose();
  }

  void _syncScroll() {
    if (_gutterScrollController.hasClients && _textScrollController.hasClients) {
      if (_gutterScrollController.offset != _textScrollController.offset) {
        _gutterScrollController.jumpTo(_textScrollController.offset);
      }
    }
  }

  void _handleTextSelectionChange() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (selection.isValid && selection.baseOffset >= 0 && selection.baseOffset <= text.length) {
      final textBeforeCursor = text.substring(0, selection.baseOffset);
      final lines = textBeforeCursor.split('\n');
      final line = lines.length;
      final column = lines.isEmpty ? 1 : lines.last.length + 1;

      if (mounted && (_cursorLine != line || _cursorColumn != column)) {
        setState(() {
          _cursorLine = line;
          _cursorColumn = column;
        });
      }
    }
  }

  void _toggleWordWrap() {
    setState(() {
      _wordWrap = !_wordWrap;
    });
  }

  void _onFindQueryChanged(String query) {
    setState(() {
      _searchQuery = query;
      _matchIndices = [];
      _currentMatchIndex = 0;

      if (query.isNotEmpty) {
        final text = widget.controller.text.toLowerCase();
        final q = query.toLowerCase();
        int startIndex = 0;
        while (startIndex < text.length) {
          final index = text.indexOf(q, startIndex);
          if (index == -1) break;
          _matchIndices.add(index);
          startIndex = index + q.length;
        }

        if (_matchIndices.isNotEmpty) {
          _selectMatch(0);
        }
      }
    });
  }

  void _selectMatch(int index) {
    if (_matchIndices.isEmpty) return;
    _currentMatchIndex = index;
    final matchPos = _matchIndices[index];
    widget.controller.selection = TextSelection(
      baseOffset: matchPos,
      extentOffset: matchPos + _searchQuery.length,
    );
  }

  void _findNext() {
    if (_matchIndices.isEmpty) return;
    final next = (_currentMatchIndex + 1) % _matchIndices.length;
    setState(() {
      _selectMatch(next);
    });
  }

  void _findPrev() {
    if (_matchIndices.isEmpty) return;
    final prev = (_currentMatchIndex - 1 + _matchIndices.length) % _matchIndices.length;
    setState(() {
      _selectMatch(prev);
    });
  }

  void _replace(String replacement) {
    if (_matchIndices.isEmpty || _searchQuery.isEmpty) return;
    final matchPos = _matchIndices[_currentMatchIndex];
    final text = widget.controller.text;

    final newText = text.replaceRange(matchPos, matchPos + _searchQuery.length, replacement);
    widget.controller.text = newText;
    widget.onChanged?.call(newText);

    _onFindQueryChanged(_searchQuery);
  }

  void _replaceAll(String replacement) {
    if (_searchQuery.isEmpty) return;
    final text = widget.controller.text;
    final newText = text.replaceAll(_searchQuery, replacement);
    widget.controller.text = newText;
    widget.onChanged?.call(newText);

    _onFindQueryChanged(_searchQuery);
  }

  int get _wordCount {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  int get _charCount => widget.controller.text.length;

  int get _lineCount {
    final text = widget.controller.text;
    if (text.isEmpty) return 1;
    return text.split('\n').length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final editorBg = isDark ? const Color(0xFF000000) : const Color(0xFFFCFCFC);
    final gutterBg = isDark ? const Color(0xFF040404) : const Color(0xFFF4F4F5);
    final gutterTextColor = isDark ? Colors.grey[700] : Colors.grey[400];
    final editorTextColor = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B);

    final lineCount = _lineCount;
    final gutterWidth = (lineCount.toString().length * 10.0 + 24.0).clamp(36.0, 60.0);

    return Container(
      color: editorBg,
      child: Column(
        children: [
          // Optional Find & Replace Floating Bar
          if (widget.showFindReplace)
            FindReplaceBar(
              currentMatchIndex: _currentMatchIndex,
              totalMatches: _matchIndices.length,
              onQueryChanged: _onFindQueryChanged,
              onFindNext: _findNext,
              onFindPrev: _findPrev,
              onReplace: _replace,
              onReplaceAll: _replaceAll,
              onClose: () => widget.onCloseFindReplace?.call(),
            ),

          // Main Editor Surface with Gutter
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Line Numbers Gutter
                Container(
                  width: gutterWidth,
                  color: gutterBg,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    child: ListView.builder(
                      controller: _gutterScrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      itemCount: lineCount,
                      itemBuilder: (context, index) {
                        final isCurrentLine = (index + 1) == _cursorLine;
                        return Container(
                          height: 22,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                              color: isCurrentLine
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : gutterTextColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  color: theme.colorScheme.outline.withAlpha(40),
                ),

                // Editable Text Area
                Expanded(
                  child: _wordWrap
                      ? TextField(
                          controller: widget.controller,
                          scrollController: _textScrollController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13.5,
                            height: 22 / 13.5, // Matches gutter line height exactly!
                            color: editorTextColor,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            isDense: true,
                          ),
                          onChanged: widget.onChanged,
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: IntrinsicWidth(
                            child: TextField(
                              controller: widget.controller,
                              scrollController: _textScrollController,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13.5,
                                height: 22 / 13.5,
                                color: editorTextColor,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                isDense: true,
                              ),
                              onChanged: widget.onChanged,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Editor Status Bar
          EditorStatusBar(
            cursorLine: _cursorLine,
            cursorColumn: _cursorColumn,
            wordWrap: _wordWrap,
            wordCount: _wordCount,
            charCount: _charCount,
            onToggleWordWrap: _toggleWordWrap,
          ),
        ],
      ),
    );
  }
}
