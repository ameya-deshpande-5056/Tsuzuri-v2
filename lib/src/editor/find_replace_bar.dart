import 'package:flutter/material.dart';

/// Floating inline Find and Replace toolbar for the Markdown Editor.
class FindReplaceBar extends StatefulWidget {
  final int currentMatchIndex;
  final int totalMatches;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onFindNext;
  final VoidCallback onFindPrev;
  final ValueChanged<String> onReplace;
  final ValueChanged<String> onReplaceAll;
  final VoidCallback onClose;

  const FindReplaceBar({
    super.key,
    required this.currentMatchIndex,
    required this.totalMatches,
    required this.onQueryChanged,
    required this.onFindNext,
    required this.onFindPrev,
    required this.onReplace,
    required this.onReplaceAll,
    required this.onClose,
  });

  @override
  State<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends State<FindReplaceBar> {
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  bool _showReplace = true;

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final matchDisplay = widget.totalMatches > 0
        ? '${widget.currentMatchIndex + 1} of ${widget.totalMatches}'
        : '0 of 0';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0F) : const Color(0xFFF4F4F5),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withAlpha(60),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 20),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Find Row
          Row(
            children: [
              IconButton(
                tooltip: _showReplace ? 'Hide Replace' : 'Show Replace',
                icon: Icon(
                  _showReplace ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () => setState(() => _showReplace = !_showReplace),
              ),
              const SizedBox(width: 6),

              // Find Input
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _findController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Find...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF040404) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(60)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.2),
                      ),
                    ),
                    onChanged: widget.onQueryChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Match Count Display
              Text(
                matchDisplay,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: widget.totalMatches > 0
                      ? (isDark ? Colors.grey[300] : Colors.grey[700])
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 6),

              // Prev & Next Buttons
              IconButton(
                tooltip: 'Previous match (Shift+Enter)',
                icon: const Icon(Icons.arrow_upward, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: widget.totalMatches > 0 ? widget.onFindPrev : null,
              ),
              IconButton(
                tooltip: 'Next match (Enter)',
                icon: const Icon(Icons.arrow_downward, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: widget.totalMatches > 0 ? widget.onFindNext : null,
              ),
              IconButton(
                tooltip: 'Close (Escape)',
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: widget.onClose,
              ),
            ],
          ),

          // Replace Row
          if (_showReplace) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 30), // Indent to align with Find textfield
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: TextField(
                      controller: _replaceController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Replace with...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF040404) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(60)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                OutlinedButton(
                  onPressed: widget.totalMatches > 0
                      ? () => widget.onReplace(_replaceController.text)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text('Replace', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: widget.totalMatches > 0
                      ? () => widget.onReplaceAll(_replaceController.text)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text('All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

