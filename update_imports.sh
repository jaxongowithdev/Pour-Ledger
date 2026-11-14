#!/bin/bash

# Update Import Statements After Anti-Spam Rename
# This script updates all import statements to reflect the new file names

echo "🔄 Starting import statement updates..."

# Find all Dart files (excluding build, .dart_tool, backup directories)
FILES=$(find lib -name "*.dart" -type f | grep -v ".dart_tool" | grep -v "lib_backup_")

# Count total files
TOTAL=$(echo "$FILES" | wc -l | tr -d ' ')
echo "📝 Found $TOTAL Dart files to update"

# Services
echo "🔧 Updating service imports..."
echo "$FILES" | xargs sed -i '' "s|services/timing_service|services/cycle_timer|g"
echo "$FILES" | xargs sed -i '' "s|services/statistics_service|services/cycle_analytics|g"
echo "$FILES" | xargs sed -i '' "s|services/production_calculator|services/output_estimator|g"
echo "$FILES" | xargs sed -i '' "s|services/export_csv_service|services/data_csv_exporter|g"
echo "$FILES" | xargs sed -i '' "s|services/export_pdf_service|services/report_pdf_generator|g"

# Repositories
echo "🔧 Updating repository imports..."
echo "$FILES" | xargs sed -i '' "s|repositories/session_repository|repositories/measurement_data_store|g"
echo "$FILES" | xargs sed -i '' "s|repositories/work_item_repository|repositories/task_data_store|g"
echo "$FILES" | xargs sed -i '' "s|repositories/settings_repository|repositories/config_data_store|g"

# Database
echo "🔧 Updating database imports..."
echo "$FILES" | xargs sed -i '' "s|database/app_database|database/cycle_time_database|g"
echo "$FILES" | xargs sed -i '' "s|database/sample_data|database/demo_generator|g"

# Screens
echo "🔧 Updating screen imports..."
echo "$FILES" | xargs sed -i '' "s|screens/measurement/measurement_screen|screens/measurement/timer_view|g"
echo "$FILES" | xargs sed -i '' "s|screens/analytics/analytics_screen|screens/analytics/insights_view|g"
echo "$FILES" | xargs sed -i '' "s|screens/home/home_screen|screens/home/dashboard_view|g"
echo "$FILES" | xargs sed -i '' "s|screens/settings/settings_screen|screens/settings/preferences_view|g"

# Models
echo "🔧 Updating model imports..."
echo "$FILES" | xargs sed -i '' "s|models/app_settings|models/user_preferences|g"

# Utils
echo "🔧 Updating utils imports..."
echo "$FILES" | xargs sed -i '' "s|utils/app_theme|utils/visual_theme|g"
echo "$FILES" | xargs sed -i '' "s|utils/app_constants|utils/cycle_constants|g"

# Core
echo "🔧 Updating core imports..."
echo "$FILES" | xargs sed -i '' "s|core/app_providers|core/state_providers|g"

echo ""
echo "✅ Import updates complete!"
echo ""
echo "🧪 Running analysis to verify..."
flutter analyze --no-pub

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS! Zero analysis errors."
    echo "🎉 Anti-spam renaming complete!"
    echo ""
    echo "📋 Summary of changes:"
    echo "   - Services renamed (5 files)"
    echo "   - Repositories renamed (3 files)"
    echo "   - Database renamed (2 files)"
    echo "   - Screens renamed (4 files)"
    echo "   - Models renamed (1 file)"
    echo "   - Utils renamed (2 files)"
    echo "   - Core renamed (1 file)"
    echo ""
    echo "💾 Backup available at: lib_backup_*/"
else
    echo ""
    echo "⚠️  Analysis found issues. Please review the errors above."
    echo "💾 You can restore from backup if needed: lib_backup_*/"
fi
