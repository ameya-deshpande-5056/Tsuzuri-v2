import 'dart:io';
import 'package:flutter/material.dart';
import 'src/services/library_service.dart';
import 'src/theme/app_theme.dart';
import 'src/ui/app_shell.dart';
import 'src/ui/library_screen.dart';
import 'src/ui/modal_overlay_tracker.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initialFilePath;
  String? initialContent;

  if (args.isNotEmpty) {
    final candidatePath = args.first;
    try {
      final file = File(candidatePath);
      if (await file.exists()) {
        initialFilePath = file.path;
        initialContent = await file.readAsString();
        // Register in library when opened via command line / file association
        final entries = await LibraryService.loadEntries();
        await LibraryService.addFile(entries, initialFilePath, markAsOpened: true);
      }
    } catch (_) {}
  }

  runApp(TsuzuriApp(
    initialFilePath: initialFilePath,
    initialContent: initialContent,
  ));
}

/// The root application widget for Tsuzuri v2.
class TsuzuriApp extends StatefulWidget {
  final String? initialFilePath;
  final String? initialContent;
  final String? initialRoute;

  const TsuzuriApp({
    super.key,
    this.initialFilePath,
    this.initialContent,
    this.initialRoute,
  });

  @override
  State<TsuzuriApp> createState() => _TsuzuriAppState();
}

class _TsuzuriAppState extends State<TsuzuriApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveInitialRoute = widget.initialRoute ??
        (widget.initialFilePath != null ? '/document' : '/');

    return MaterialApp(
      title: 'Tsuzuri',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [ModalOverlayTracker.instance],
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.amoledDarkTheme,
      initialRoute: effectiveInitialRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => LibraryScreen(
                currentThemeMode: _themeMode,
                onThemeChanged: _setThemeMode,
              ),
            );
          case '/document':
            final args = settings.arguments;
            String? filePath;
            bool isEditor = false;
            if (args is String) {
              filePath = args;
            } else if (args is Map) {
              filePath = args['filePath'] as String?;
              isEditor = args['isEditor'] as bool? ?? false;
            } else {
              filePath = widget.initialFilePath;
            }

            return MaterialPageRoute(
              settings: settings,
              builder: (_) => AppShell(
                currentThemeMode: _themeMode,
                onThemeChanged: _setThemeMode,
                initialFilePath: filePath,
                initialContent: filePath == widget.initialFilePath
                    ? widget.initialContent
                    : null,
                showBackToLibrary: true,
                initialIsEditorMode: isEditor,
              ),
            );
          default:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => LibraryScreen(
                currentThemeMode: _themeMode,
                onThemeChanged: _setThemeMode,
              ),
            );
        }
      },
    );
  }
}
