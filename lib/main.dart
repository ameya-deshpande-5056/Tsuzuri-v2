import 'dart:io';
import 'package:flutter/material.dart';
import 'src/theme/app_theme.dart';
import 'src/ui/app_shell.dart';
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
    return MaterialApp(
      title: 'Tsuzuri',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [ModalOverlayTracker.instance],
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.amoledDarkTheme,
      home: AppShell(
        currentThemeMode: _themeMode,
        onThemeChanged: _setThemeMode,
        initialFilePath: widget.initialFilePath,
        initialContent: widget.initialContent,
      ),
    );
  }
}
