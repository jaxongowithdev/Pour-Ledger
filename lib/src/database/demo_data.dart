import 'package:sqflite/sqflite.dart';

class DemoData {
  static Future<void> seed(Database db) async {
    final batch = db.batch();

    // Insert demo ingredients
    final ingredientIds = <String, int>{};
    final ingredients = [
      {'name': 'Feldspar', 'category': 'Base'},
      {'name': 'Silica', 'category': 'Base'},
      {'name': 'Whiting', 'category': 'Flux'},
      {'name': 'Kaolin', 'category': 'Stabilizer'},
      {'name': 'Wood Ash', 'category': 'Flux'},
      {'name': 'Copper Oxide', 'category': 'Colorant'},
      {'name': 'Cobalt Oxide', 'category': 'Colorant'},
    ];

    for (var i = 0; i < ingredients.length; i++) {
      batch.insert('ingredients', {
        'name': ingredients[i]['name'],
        'category': ingredients[i]['category'],
        'defaultUnit': 'g',
      });
    }

    await batch.commit(noResult: true);

    // Get ingredient IDs
    for (var ing in ingredients) {
      final result = await db.query('ingredients', where: 'name = ?', whereArgs: [ing['name']]);
      if (result.isNotEmpty) {
        ingredientIds[ing['name'] as String] = result.first['id'] as int;
      }
    }

    // Create Blue Ash glaze
    final glazeId = await db.insert('glazes', {
      'name': 'Blue Ash',
      'description': 'Rich blue glaze with ash',
      'favorite': 1,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Create V3 version
    final versionId = await db.insert('formula_versions', {
      'glazeId': glazeId,
      'version': 'V3',
      'notes': 'Adjusted copper oxide ratio for deeper blue',
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Add formula components for Blue Ash V3
    final components = [
      {'ingredient': 'Feldspar', 'weight': 450.0, 'percentage': 45.0},
      {'ingredient': 'Silica', 'weight': 250.0, 'percentage': 25.0},
      {'ingredient': 'Whiting', 'weight': 150.0, 'percentage': 15.0},
      {'ingredient': 'Kaolin', 'weight': 100.0, 'percentage': 10.0},
      {'ingredient': 'Wood Ash', 'weight': 50.0, 'percentage': 5.0},
      {'ingredient': 'Copper Oxide', 'weight': 30.0, 'percentage': 3.0},
      {'ingredient': 'Cobalt Oxide', 'weight': 10.0, 'percentage': 1.0},
    ];

    final batch2 = db.batch();
    for (var comp in components) {
      final ingredientId = ingredientIds[comp['ingredient']];
      if (ingredientId != null) {
        batch2.insert('formula_components', {
          'versionId': versionId,
          'ingredientId': ingredientId,
          'weight': comp['weight'],
          'percentage': comp['percentage'],
        });
      }
    }
    await batch2.commit(noResult: true);

    // Add version change record
    await db.insert('version_changes', {
      'versionId': versionId,
      'description': 'Reduced copper oxide by 2%, increased cobalt by 0.5%',
    });

    // Create test record
    final testId = await db.insert('experiment_records', {
      'versionId': versionId,
      'name': 'Blue Ash V3 - Cone 6',
      'testDate': DateTime.now().toIso8601String(),
      'targetCone': '6',
      'kilnId': 'Kiln A',
      'status': 'completed',
      'notes': 'Testing improved formula with adjusted colorant ratio',
    });

    // Create sample tiles
    final tiles = [
      {'number': 1, 'layerCount': 2, 'result': 'Good', 'rating': 4},
      {'number': 2, 'layerCount': 2, 'result': 'Excellent', 'rating': 5},
      {'number': 3, 'layerCount': 3, 'result': 'Good', 'rating': 4},
      {'number': 4, 'layerCount': 2, 'result': 'Excellent', 'rating': 5},
      {'number': 5, 'layerCount': 3, 'result': 'Good', 'rating': 4},
      {'number': 6, 'layerCount': 2, 'result': 'Excellent', 'rating': 5},
    ];

    for (var tile in tiles) {
      final tileId = await db.insert('sample_tiles', {
        'testId': testId,
        'number': tile['number'],
        'clayBody': 'Stoneware',
        'applicationMethod': 'dip',
        'layerCount': tile['layerCount'],
        'thickness': 'medium',
        'notes': '',
      });

      // Add evaluation result
      await db.insert('evaluation_results', {
        'tileId': tileId,
        'color': 'Deep Blue',
        'surface': 'Glossy',
        'texture': 'Smooth',
        'gloss': 'High',
        'opacity': 'Opaque',
        'coverage': 'Excellent',
        'adhesion': 'Strong',
        'rating': tile['rating'],
        'notes': '',
        'isBest': tile['rating'] == 5 ? 1 : 0,
      });
    }

    // Create kiln session
    await db.insert('kiln_sessions', {
      'testId': testId,
      'kilnId': 'Kiln A',
      'targetTemperature': 1220,
      'peakTemperature': 1222,
      'holdMinutes': 10,
      'atmosphere': 'oxidation',
      'startedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'completedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    });

    // Add timeline entries
    final timelineEntries = [
      {'action': 'created', 'description': 'Test created: Blue Ash V3 - Cone 6'},
      {'action': 'formula', 'description': 'Formula completed (1040g total)'},
      {'action': 'tiles', 'description': '6 tiles prepared'},
      {'action': 'firing', 'description': 'Firing completed at 1222°C'},
      {'action': 'results', 'description': 'Results evaluated - 3 excellent, 3 good'},
      {'action': 'best', 'description': 'Marked 3 tiles as best results'},
    ];

    final batch3 = db.batch();
    for (var i = 0; i < timelineEntries.length; i++) {
      batch3.insert('timeline_entries', {
        'testId': testId,
        'action': timelineEntries[i]['action'],
        'description': timelineEntries[i]['description'],
        'createdAt': DateTime.now().subtract(Duration(days: 6 - i)).toIso8601String(),
      });
    }
    await batch3.commit(noResult: true);
  }
}
