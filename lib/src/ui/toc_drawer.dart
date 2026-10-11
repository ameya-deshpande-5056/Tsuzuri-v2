import 'package:flutter/material.dart';
import '../parser/toc_parser.dart';

/// Table of Contents drawer displaying the document's heading hierarchy.
class TocDrawer extends StatelessWidget {
  final List<TocItem> items;
  final ValueChanged<TocItem> onSelectHeading;

  const TocDrawer({
    super.key,
    required this.items,
    required this.onSelectHeading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Contents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close Contents',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Heading List
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'No headings found in document.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final indent = (item.level - 1) * 14.0;

                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            onSelectHeading(item);
                          },
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16.0 + indent, 8, 16, 8),
                            child: Row(
                              children: [
                                Text(
                                  'H${item.level}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.text,
                                    style: TextStyle(
                                      fontSize: item.level == 1 ? 14 : 13,
                                      fontWeight: item.level <= 2 ? FontWeight.w600 : FontWeight.normal,
                                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

