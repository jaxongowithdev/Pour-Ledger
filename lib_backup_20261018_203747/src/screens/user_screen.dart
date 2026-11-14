import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../core/app_providers.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import 'main_navigator.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('Starting CycleTime initialization...');

      // Initialize database
      final db = AppDatabase.instance;
      await db.database;

      debugPrint('CycleTime initialized successfully');

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error initializing app: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final settingsAsync = ref.watch(settingsProvider);

          return settingsAsync.when(
            data: (settings) {
              ThemeMode themeMode;
              switch (settings.themeMode.toLowerCase()) {
                case AppConstants.themeLight:
                  themeMode = ThemeMode.light;
                  break;
                case AppConstants.themeDark:
                  themeMode = ThemeMode.dark;
                  break;
                case AppConstants.themeSystem:
                default:
                  themeMode = ThemeMode.system;
                  break;
              }

              return MaterialApp(
                title: 'CycleTime',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                home: !_isInitialized
                    ? Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Loading CycleTime...',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    : const MainNavigator(),
              );
            },
            loading: () => MaterialApp(
              title: 'CycleTime',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading CycleTime...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            error: (error, stack) => MaterialApp(
              title: 'CycleTime',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: Scaffold(
                body: Center(
                  child: Text('Error initializing app: $error'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
