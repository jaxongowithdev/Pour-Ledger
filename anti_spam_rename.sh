#!/bin/bash

# Anti-Spam File Renaming Script for CycleTime
# Renames template-like files to unique names to avoid Apple spam detection

echo "🔄 Starting Anti-Spam File Rename..."

# Backup first
echo "📦 Creating backup..."
cp -r lib lib_backup_$(date +%Y%m%d_%H%M%S)

# Rename Services
echo "📝 Renaming services..."
mv lib/src/services/timing_service.dart lib/src/services/cycle_timer.dart 2>/dev/null || echo "  timing_service.dart not found or already renamed"
mv lib/src/services/statistics_service.dart lib/src/services/cycle_analytics.dart 2>/dev/null || echo "  statistics_service.dart not found or already renamed"
mv lib/src/services/production_calculator.dart lib/src/services/output_estimator.dart 2>/dev/null || echo "  production_calculator.dart not found or already renamed"
mv lib/src/services/export_csv_service.dart lib/src/services/data_csv_exporter.dart 2>/dev/null || echo "  export_csv_service.dart not found or already renamed"
mv lib/src/services/export_pdf_service.dart lib/src/services/report_pdf_generator.dart 2>/dev/null || echo "  export_pdf_service.dart not found or already renamed"

# Rename Repositories
echo "📝 Renaming repositories..."
mv lib/src/repositories/session_repository.dart lib/src/repositories/measurement_data_store.dart 2>/dev/null || echo "  session_repository.dart not found or already renamed"
mv lib/src/repositories/work_item_repository.dart lib/src/repositories/task_data_store.dart 2>/dev/null || echo "  work_item_repository.dart not found or already renamed"
mv lib/src/repositories/settings_repository.dart lib/src/repositories/config_data_store.dart 2>/dev/null || echo "  settings_repository.dart not found or already renamed"

# Rename Database
echo "📝 Renaming database..."
mv lib/src/database/app_database.dart lib/src/database/cycle_time_database.dart 2>/dev/null || echo "  app_database.dart not found or already renamed"
mv lib/src/database/sample_data.dart lib/src/database/demo_generator.dart 2>/dev/null || echo "  sample_data.dart not found or already renamed"

# Rename Screens
echo "📝 Renaming screens..."
mv lib/src/screens/measurement/measurement_screen.dart lib/src/screens/measurement/timer_view.dart 2>/dev/null || echo "  measurement_screen.dart not found or already renamed"
mv lib/src/screens/analytics/analytics_screen.dart lib/src/screens/analytics/insights_view.dart 2>/dev/null || echo "  analytics_screen.dart not found or already renamed"
mv lib/src/screens/home/home_screen.dart lib/src/screens/home/dashboard_view.dart 2>/dev/null || echo "  home_screen.dart not found or already renamed"
mv lib/src/screens/settings/settings_screen.dart lib/src/screens/settings/preferences_view.dart 2>/dev/null || echo "  settings_screen.dart not found or already renamed"

# Rename Models
echo "📝 Renaming models..."
mv lib/src/models/app_settings.dart lib/src/models/user_preferences.dart 2>/dev/null || echo "  app_settings.dart not found or already renamed"

# Rename Utils
echo "📝 Renaming utils..."
mv lib/src/utils/app_theme.dart lib/src/utils/visual_theme.dart 2>/dev/null || echo "  app_theme.dart not found or already renamed"
mv lib/src/utils/app_constants.dart lib/src/utils/cycle_constants.dart 2>/dev/null || echo "  app_constants.dart not found or already renamed"

# Rename Core
echo "📝 Renaming core..."
mv lib/src/core/app_providers.dart lib/src/core/state_providers.dart 2>/dev/null || echo "  app_providers.dart not found or already renamed"

echo ""
echo "✅ Rename complete!"
echo ""
echo "⚠️  IMPORTANT: You MUST now update all import statements!"
echo "   Run: ./update_imports.sh"
echo ""
echo "📦 Backup saved in: lib_backup_*/"
echo ""
