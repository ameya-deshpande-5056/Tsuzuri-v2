import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// About Tsuzuri modal dialog matching the original Tsuzuri application layout.
class TsuzuriAboutDialog extends StatefulWidget {
  const TsuzuriAboutDialog({super.key});

  /// Retrieves the clean app version (without build number) from pubspec.yaml.
  static Future<String> getCleanVersion() async {
    if (_TsuzuriAboutDialogState._cachedVersion != null) {
      return _TsuzuriAboutDialogState._cachedVersion!;
    }
    try {
      final yamlContent = await rootBundle.loadString('pubspec.yaml');
      for (final line in yamlContent.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('version:')) {
          final parsed = trimmed.substring('version:'.length).trim();
          final clean = parsed.split('+').first.trim();
          if (clean.isNotEmpty) {
            _TsuzuriAboutDialogState._cachedVersion = clean;
            return clean;
          }
        }
      }
    } catch (_) {}
    return '2.0.0';
  }

  static Future<void> show(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close About Dialog',
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.65)
          : Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: const Center(
            child: TsuzuriAboutDialog(),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutCubic.transform(animation.value);
        return Transform.scale(
          scale: 0.96 + (0.04 * curvedValue),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<TsuzuriAboutDialog> createState() => _TsuzuriAboutDialogState();
}

class _TsuzuriAboutDialogState extends State<TsuzuriAboutDialog> {
  static String? _cachedVersion;
  String _version = _cachedVersion ?? '2.0.0';
  static const String _buildTime = '2026-10-11T12:00:00Z';
  static const String _projectUrl =
      'https://github.com/ameya-deshpande-5056/Tsuzuri-v2';

  @override
  void initState() {
    super.initState();
    if (_cachedVersion == null) {
      _loadVersionFromPubspec();
    }
  }

  Future<void> _loadVersionFromPubspec() async {
    try {
      final yamlContent = await rootBundle.loadString('pubspec.yaml');
      for (final line in yamlContent.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('version:')) {
          final parsed = trimmed.substring('version:'.length).trim();
          final clean = parsed.split('+').first.trim();
          if (clean.isNotEmpty && mounted) {
            setState(() {
              _version = clean;
              _cachedVersion = clean;
            });
            return;
          }
        }
      }
    } catch (_) {
      // Fallback to default version if pubspec asset is unavailable
    }
  }

  void _copyProjectUrl(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _projectUrl));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Project URL copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha(50),
          width: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: "About Tsuzuri" with Close 'X' button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withAlpha(40),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'About Tsuzuri',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body: App Icon, Heading, Description, Meta Grid
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 380;
                  final iconWidget = Image.asset(
                    'assets/icon/icon-128.png',
                    width: 76,
                    height: 76,
                    fit: BoxFit.contain,
                  );

                  final detailsWidget = Column(
                    crossAxisAlignment: isNarrow
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tsuzuri $_version',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'A quiet, lightweight, and offline Markdown document reader and editor.',
                        textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMetaGrid(theme, isDark),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        iconWidget,
                        const SizedBox(height: 16),
                        detailsWidget,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      iconWidget,
                      const SizedBox(width: 20),
                      Expanded(child: detailsWidget),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaGrid(ThemeData theme, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetaItem(
          label: 'Version:',
          valueWidget: Text(
            _version,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface,
            ),
          ),
          isDark: isDark,
        ),
        const SizedBox(height: 7),
        _buildMetaItem(
          label: 'Build time:',
          valueWidget: Text(
            _buildTime,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface,
            ),
          ),
          isDark: isDark,
        ),
        const SizedBox(height: 7),
        _buildMetaItem(
          label: 'Project:',
          valueWidget: InkWell(
            onTap: () => _copyProjectUrl(context),
            child: Text(
              _projectUrl,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF58A6FF) : const Color(0xFF0969DA),
                decoration: TextDecoration.underline,
                decorationColor:
                    isDark ? const Color(0xFF58A6FF) : const Color(0xFF0969DA),
              ),
            ),
          ),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildMetaItem({
    required String label,
    required Widget valueWidget,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ),
        Expanded(child: valueWidget),
      ],
    );
  }
}
