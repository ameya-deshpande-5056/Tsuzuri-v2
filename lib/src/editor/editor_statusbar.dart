import 'package:flutter/material.dart';

/// Minimalist, responsive editor status bar displaying cursor position, word wrap, and document stats.
class EditorStatusBar extends StatelessWidget {
  final int cursorLine;
  final int cursorColumn;
  final bool wordWrap;
  final int wordCount;
  final int charCount;
  final VoidCallback onToggleWordWrap;

  const EditorStatusBar({
    super.key,
    required this.cursorLine,
    required this.cursorColumn,
    required this.wordWrap,
    required this.wordCount,
    required this.charCount,
    required this.onToggleWordWrap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final isVeryCompact = screenWidth < 360;
    final isCompact = screenWidth < 480;
    final textColor = isDark ? Colors.grey[400] : Colors.grey[700];

    final cursorText = isVeryCompact ? 'L$cursorLine:C$cursorColumn' : 'Ln $cursorLine, Col $cursorColumn';

    String statsText;
    if (isVeryCompact) {
      statsText = '$wordCount w';
    } else if (isCompact) {
      statsText = '$wordCount words';
    } else {
      statsText = '$wordCount words · $charCount chars';
    }

    return Container(
      height: 28,
      padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 8 : 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF040404) : const Color(0xFFF4F4F5),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withAlpha(50),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Cursor position and Word wrap toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cursorText,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: textColor,
                ),
              ),
              SizedBox(width: isVeryCompact ? 8 : 14),
              InkWell(
                onTap: onToggleWordWrap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    isVeryCompact ? (wordWrap ? 'Wrap' : 'NoWrap') : 'Wrap: ${wordWrap ? "On" : "Off"}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Right: Document stats
          Flexible(
            child: Text(
              statsText,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

