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

  const TsuzuriApp({
    super.key,
    this.initialFilePath,
    this.initialContent,
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
    // If launched with a file argument, go directly to AppShell
    final hasInitialFile = widget.initialFilePath != null;

    return MaterialApp(
      title: 'Tsuzuri',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [ModalOverlayTracker.instance],
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.amoledDarkTheme,
      initialRoute: hasInitialFile ? '/document' : '/',
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
            // Accept file path from either navigation arguments or initial launch
            final filePath = settings.arguments as String? ?? widget.initialFilePath;
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
