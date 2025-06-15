import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yallashoot/settings_provider.dart';
import 'package:yallashoot/strings/languages.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final lang = settings.locale.languageCode;
    final strings = appStrings[lang]!;

    final List<DropdownMenuItem<int>> timezoneItems = [];
    for (int i = 12; i >= -12; i--) {
      final int offsetValue = i * 60;
      final String displayName = i > 0 ? 'UTC +$i' : 'UTC $i';
      timezoneItems.add(
        DropdownMenuItem(
          value: offsetValue,
          child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(strings['settings']!),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          // Dark Mode toggle
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 16, right: 8),
              title: Text(strings['dark_mode']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              secondary: Icon(
                settings.themeMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: theme.colorScheme.primary,
              ),
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (isDark) {
                final newTheme = isDark ? ThemeMode.dark : ThemeMode.light;
                context.read<SettingsProvider>().updateThemeMode(newTheme);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Language Selection Card
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12, top: 4, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 16),
                      Text(strings['language']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<Locale>(
                      value: settings.locale,
                      icon: Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurfaceVariant),
                      items: const [
                        DropdownMenuItem(value: Locale('en'), child: Text('English', style: TextStyle(fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: Locale('ar'), child: Text('العربية', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      onChanged: (newLocale) {
                        if (newLocale != null) {
                          context.read<SettingsProvider>().updateLanguage(newLocale);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12, top: 4, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 16),
                      Text(strings['timezone']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: settings.timeZoneOffset,
                      items: timezoneItems,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          context.read<SettingsProvider>().updateTimeZoneOffset(newValue);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}