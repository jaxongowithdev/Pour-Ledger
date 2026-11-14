import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_providers.dart';
import '../../database/storage_manager.dart';
import '../../models/user_preferences.dart';
import '../ingredients/ingredients_screen.dart';
import '../calendar/calendar_screen.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: prefsAsync.when(
        data: (prefs) {
          return ListView(
            children: [
              const SizedBox(height: 8),

              // Appearance section
              _SectionHeader(title: 'Appearance'),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Theme'),
                subtitle: Text(_getThemeLabel(prefs.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, ref, prefs),
              ),

              const Divider(height: 32),

              // Units section
              _SectionHeader(title: 'Units'),
              ListTile(
                leading: const Icon(Icons.thermostat),
                title: const Text('Temperature'),
                subtitle: Text(prefs.temperatureUnit == 'celsius' ? 'Celsius (°C)' : 'Fahrenheit (°F)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showTemperatureDialog(context, ref, prefs),
              ),
              ListTile(
                leading: const Icon(Icons.scale),
                title: const Text('Weight'),
                subtitle: Text(prefs.weightUnit == 'g' ? 'Grams (g)' : 'Ounces (oz)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showWeightDialog(context, ref, prefs),
              ),

              const Divider(height: 32),

              // Content section
              _SectionHeader(title: 'Content'),
              ListTile(
                leading: const Icon(Icons.science),
                title: const Text('Ingredients Library'),
                subtitle: const Text('Manage ingredients'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IngredientsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Calendar'),
                subtitle: const Text('View test schedule'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarScreen(),
                    ),
                  );
                },
              ),

              const Divider(height: 32),

              // Language section
              _SectionHeader(title: 'Language'),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: Text(prefs.language == 'en' ? 'English' : 'Tiếng Việt'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, ref, prefs),
              ),

              const Divider(height: 32),

              // Data section
              _SectionHeader(title: 'Data'),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Export Data'),
                subtitle: const Text('Export all data as JSON'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export - Coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Import Data'),
                subtitle: const Text('Import data from backup'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Import - Coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup'),
                subtitle: const Text('Create backup of all data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup - Coming soon')),
                  );
                },
              ),

              const Divider(height: 32),

              // About section
              _SectionHeader(title: 'About'),
              const ListTile(
                leading: Icon(Icons.info),
                title: Text('Version'),
                subtitle: Text('1.0.0+1'),
              ),
              const ListTile(
                leading: Icon(Icons.science),
                title: Text('CycleTime'),
                subtitle: Text('Professional ceramic glaze testing workspace'),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
      default:
        return 'System';
    }
  }

  Future<void> _showThemeDialog(BuildContext context, WidgetRef ref, UserPreferences prefs) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Theme'),
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: prefs.themeMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: prefs.themeMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('System'),
              value: 'system',
              groupValue: prefs.themeMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final updated = prefs.copyWith(themeMode: result);
      await StorageManager.instance.updateUserPreferences(updated);
      ref.invalidate(preferencesProvider);
    }
  }

  Future<void> _showTemperatureDialog(BuildContext context, WidgetRef ref, UserPreferences prefs) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Temperature Unit'),
          children: [
            RadioListTile<String>(
              title: const Text('Celsius (°C)'),
              value: 'celsius',
              groupValue: prefs.temperatureUnit,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Fahrenheit (°F)'),
              value: 'fahrenheit',
              groupValue: prefs.temperatureUnit,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final updated = prefs.copyWith(temperatureUnit: result);
      await StorageManager.instance.updateUserPreferences(updated);
      ref.invalidate(preferencesProvider);
    }
  }

  Future<void> _showWeightDialog(BuildContext context, WidgetRef ref, UserPreferences prefs) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Weight Unit'),
          children: [
            RadioListTile<String>(
              title: const Text('Grams (g)'),
              value: 'g',
              groupValue: prefs.weightUnit,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Ounces (oz)'),
              value: 'oz',
              groupValue: prefs.weightUnit,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final updated = prefs.copyWith(weightUnit: result);
      await StorageManager.instance.updateUserPreferences(updated);
      ref.invalidate(preferencesProvider);
    }
  }

  Future<void> _showLanguageDialog(BuildContext context, WidgetRef ref, UserPreferences prefs) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Language'),
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: prefs.language,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              value: 'vi',
              groupValue: prefs.language,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final updated = prefs.copyWith(language: result);
      await StorageManager.instance.updateUserPreferences(updated);
      ref.invalidate(preferencesProvider);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
