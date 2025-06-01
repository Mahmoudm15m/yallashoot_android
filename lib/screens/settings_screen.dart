import 'package:flutter/material.dart';
import 'package:yallashoot/screens/lives_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        children: [
          // Dark Mode toggle
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text('Dark Mode', style: TextStyle(fontSize: 16)),
              secondary: Icon(
                widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              value: widget.isDarkMode,
              onChanged: widget.onThemeChanged,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
