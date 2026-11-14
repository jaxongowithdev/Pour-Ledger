import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_providers.dart';
import '../../models/app_settings.dart';
import '../../repositories/settings_repository.dart';
import '../../services/backup_service.dart';
import '../../utils/app_constants.dart';
import '../../database/sample_data.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            const SizedBox(height: 8),
            _buildSection(
              context,
              title: 'Appearance',
              children: [
                _buildThemeTile(context, ref, settings),
              ],
            ),
            _buildSection(
              context,
              title: 'Measurement',
              children: [
                _buildTimeUnitTile(context, ref, settings),
                _buildDecimalPlacesTile(context, ref, settings),
                _buildVibrationTile(context, ref, settings),
                _buildPauseHandlingTile(context, ref, settings),
              ],
            ),
            _buildSection(
              context,
              title: 'Data',
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Export CSV'),
                  subtitle: const Text('Export all data as CSV'),
                  onTap: () {
                    // Export CSV functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('CSV export feature coming soon')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Export PDF'),
                  subtitle: const Text('Generate PDF report'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('PDF export feature coming soon')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Create Backup'),
                  subtitle: const Text('Backup all data as JSON'),
                  onTap: () async {
                    try {
                      await BackupService.createBackup();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Backup created successfully')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore Backup'),
                  subtitle: const Text('Import data from JSON'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Restore feature coming soon')),
                    );
                  },
                ),
              ],
            ),
            _buildSection(
              context,
              title: 'Demo Data',
              children: [
                ListTile(
                  leading: const Icon(Icons.science),
                  title: const Text('Use Sample Data'),
                  subtitle: const Text('Add 3 demo tasks with measurement data'),
                  onTap: () async {
                    try {
                      await SampleData.createSampleData();
                      refreshWorkItems(ref);
                      refreshSessions(ref);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Sample data created successfully')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep),
                  title: const Text('Delete Sample Data'),
                  subtitle: const Text('Remove all demo data'),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Sample Data?'),
                        content: const Text(
                            'This will remove all demo tasks and measurements.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await SampleData.deleteSampleData();
                        refreshWorkItems(ref);
                        refreshSessions(ref);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Sample data deleted')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
            _buildSection(
              context,
              title: 'About',
              children: [
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('100% offline, no data collection'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Privacy Policy'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'CycleTime is designed with privacy in mind:\n\n'
                            '• All data is stored locally on your device\n'
                            '• No internet connection required\n'
                            '• No data collection or tracking\n'
                            '• No user accounts or cloud sync\n'
                            '• Complete offline functionality\n\n'
                            'Your measurement data never leaves your device.',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildThemeTile(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('Theme'),
      subtitle: Text(_getThemeLabel(settings.themeMode)),
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Select Theme'),
            children: [
              _buildThemeOption(context, 'System', AppConstants.themeSystem),
              _buildThemeOption(context, 'Light', AppConstants.themeLight),
              _buildThemeOption(context, 'Dark', AppConstants.themeDark),
            ],
          ),
        );

        if (result != null) {
          final newSettings = settings.copyWith(themeMode: result);
          await ref
              .read(settingsRepoProvider)
              .updateSettings(newSettings);
          refreshSettings(ref);
        }
      },
    );
  }

  Widget _buildThemeOption(BuildContext context, String label, String value) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Text(label),
    );
  }

  Widget _buildTimeUnitTile(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.schedule),
      title: const Text('Time Unit'),
      subtitle: Text(settings.timeUnit),
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Select Time Unit'),
            children: [
              _buildSimpleOption(
                  context, 'Seconds', AppConstants.unitSeconds),
              _buildSimpleOption(
                  context, 'Minutes', AppConstants.unitMinutes),
              _buildSimpleOption(context, 'Hours', AppConstants.unitHours),
            ],
          ),
        );

        if (result != null) {
          final newSettings = settings.copyWith(timeUnit: result);
          await ref
              .read(settingsRepoProvider)
              .updateSettings(newSettings);
          refreshSettings(ref);
        }
      },
    );
  }

  Widget _buildDecimalPlacesTile(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.filter_9_plus),
      title: const Text('Decimal Places'),
      subtitle: Text('${settings.decimalPlaces}'),
      onTap: () async {
        final result = await showDialog<int>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Select Decimal Places'),
            children: [0, 1, 2, 3].map((places) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, places),
                child: Text('$places'),
              );
            }).toList(),
          ),
        );

        if (result != null) {
          final newSettings = settings.copyWith(decimalPlaces: result);
          await ref
              .read(settingsRepoProvider)
              .updateSettings(newSettings);
          refreshSettings(ref);
        }
      },
    );
  }

  Widget _buildVibrationTile(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.vibration),
      title: const Text('Vibration'),
      subtitle: const Text('Haptic feedback on cycle record'),
      value: settings.enableVibration,
      onChanged: (value) async {
        final newSettings = settings.copyWith(enableVibration: value);
        await ref.read(settingsRepoProvider).updateSettings(newSettings);
        refreshSettings(ref);
      },
    );
  }

  Widget _buildPauseHandlingTile(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.pause),
      title: const Text('Pause Handling'),
      subtitle: Text(settings.pauseHandling == AppConstants.pauseExclude
          ? 'Exclude from active time'
          : 'Include in total time'),
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Pause Handling'),
            children: [
              _buildSimpleOption(context, 'Exclude from active time',
                  AppConstants.pauseExclude),
              _buildSimpleOption(context, 'Include in total time',
                  AppConstants.pauseInclude),
            ],
          ),
        );

        if (result != null) {
          final newSettings = settings.copyWith(pauseHandling: result);
          await ref
              .read(settingsRepoProvider)
              .updateSettings(newSettings);
          refreshSettings(ref);
        }
      },
    );
  }

  Widget _buildSimpleOption(BuildContext context, String label, String value) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Text(label),
    );
  }

  String _getThemeLabel(String mode) {
    switch (mode) {
      case AppConstants.themeLight:
        return 'Light';
      case AppConstants.themeDark:
        return 'Dark';
      default:
        return 'System';
    }
  }
}
