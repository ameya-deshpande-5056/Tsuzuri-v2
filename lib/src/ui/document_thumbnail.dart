import 'package:flutter/material.dart';
import '../services/thumbnail_service.dart';
import '../theme/app_theme.dart';

/// A miniature sheet-of-paper preview of a Markdown document.
///
/// Accurately renders the opening structures (headings, paragraphs, lists,
/// code snippets, math formulas, and diagram placeholders) in a clean,
/// clipped miniature paper card with true theme contrast.
class DocumentThumbnail extends StatelessWidget {
  final String filePath;
  final int? lastModifiedMs;
  final bool isAccessible;

  const DocumentThumbnail({
    super.key,
    required this.filePath,
    this.lastModifiedMs,
    this.isAccessible = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Check fast synchronous cache first
    final cached = ThumbnailService.getCached(filePath, lastModifiedMs);
    if (cached != null) {
      return _buildPaper(context, cached, isDark);
    }

    if (!isAccessible) {
      return _buildPaper(context, ThumbnailData.inaccessible, isDark);
    }

    return FutureBuilder<ThumbnailData>(
      future: ThumbnailService.getThumbnail(filePath),
      builder: (context, snapshot) {
        final data = snapshot.data ?? ThumbnailData.empty;
        return _buildPaper(context, data, isDark);
      },
    );
  }

  Widget _buildPaper(BuildContext context, ThumbnailData data, bool isDark) {
    // Paper surface colors
    final paperColor = isDark ? const Color(0xFF0F0F12) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF222228) : const Color(0xFFE4E4E8);
    final shadowColor = isDark
        ? Colors.black.withAlpha(80)
        : Colors.black.withAlpha(16);

    return Container(
      decoration: BoxDecoration(
        color: paperColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Paper content with bounded padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: _buildContent(context, data, isDark),
            ),
            // Bottom fade overlay to ensure clean clipping
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 18,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        paperColor.withAlpha(0),
                        paperColor,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThumbnailData data, bool isDark) {
    if (!data.isAccessible) {
      return _buildMissingState(isDark);
    }

    if (data.isEmpty || data.blocks.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return IgnorePointer(
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.blocks.map((b) => _buildBlock(b, isDark)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(ThumbnailBlock block, bool isDark) {
    final textPrimary = isDark ? AppTheme.amoledTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.amoledTextSecondary : AppTheme.lightTextSecondary;
    final mutedText = isDark ? AppTheme.amoledTextMuted : AppTheme.lightTextMuted;

    switch (block.type) {
      case ThumbnailBlockType.heading1:
        return Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 1),
          child: Text(
            block.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.2,
            ),
          ),
        );

      case ThumbnailBlockType.heading2:
        return Padding(
          padding: const EdgeInsets.only(bottom: 3, top: 2),
          child: Text(
            block.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.0,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              height: 1.2,
            ),
          ),
        );

      case ThumbnailBlockType.heading3:
        return Padding(
          padding: const EdgeInsets.only(bottom: 2, top: 1),
          child: Text(
            block.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              height: 1.2,
            ),
          ),
        );

      case ThumbnailBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            block.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 7.5,
              color: textSecondary,
              height: 1.3,
            ),
          ),
        );

      case ThumbnailBlockType.bulletItem:
        return Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block.extra ?? '• ',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                  color: mutedText,
                ),
              ),
              Expanded(
                child: Text(
                  block.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 7.5,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );

      case ThumbnailBlockType.codeBlock:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16161B) : const Color(0xFFF1F1F4),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isDark ? const Color(0xFF282830) : const Color(0xFFE2E2E6),
              width: 0.6,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (block.extra != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    block.extra!,
                    style: TextStyle(
                      fontSize: 6.0,
                      fontWeight: FontWeight.bold,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              Text(
                block.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 6.5,
                  fontFamily: 'monospace',
                  color: isDark ? const Color(0xFFE0E0E8) : const Color(0xFF2E2E32),
                  height: 1.25,
                ),
              ),
            ],
          ),
        );

      case ThumbnailBlockType.mathBlock:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14171F) : const Color(0xFFF0F4FA),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isDark ? const Color(0xFF242C3A) : const Color(0xFFD6E2F0),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '∑ ',
                style: TextStyle(
                  fontSize: 7.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.amoledLink : AppTheme.lightLink,
                ),
              ),
              Flexible(
                child: Text(
                  block.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 7.0,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppTheme.amoledLink : AppTheme.lightLink,
                  ),
                ),
              ),
            ],
          ),
        );

      case ThumbnailBlockType.mermaidBlock:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141E1A) : const Color(0xFFEEF7F2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isDark ? const Color(0xFF22352B) : const Color(0xFFCEE8D8),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schema_outlined,
                size: 8,
                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
              ),
              const SizedBox(width: 3),
              Text(
                'Mermaid Diagram',
                style: TextStyle(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        );

      case ThumbnailBlockType.blockquote:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: mutedText.withAlpha(120),
                width: 1.5,
              ),
            ),
          ),
          child: Text(
            block.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 7.0,
              fontStyle: FontStyle.italic,
              color: textSecondary,
              height: 1.25,
            ),
          ),
        );

      case ThumbnailBlockType.table:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: mutedText.withAlpha(60), width: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            block.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 6.5,
              fontFamily: 'monospace',
              color: mutedText,
            ),
          ),
        );

      case ThumbnailBlockType.divider:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Divider(
            height: 1,
            thickness: 0.6,
            color: mutedText.withAlpha(60),
          ),
        );
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notes_outlined,
            size: 16,
            color: isDark ? AppTheme.amoledTextMuted : AppTheme.lightTextMuted,
          ),
          const SizedBox(height: 3),
          Text(
            'Empty document',
            style: TextStyle(
              fontSize: 7.5,
              fontStyle: FontStyle.italic,
              color: isDark ? AppTheme.amoledTextMuted : AppTheme.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Colors.orange[400],
          ),
          const SizedBox(height: 3),
          Text(
            'File inaccessible',
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w500,
              color: Colors.orange[400],
            ),
          ),
        ],
      ),
    );
  }
}
